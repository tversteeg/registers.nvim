---@alias options
---| { show: string, symbols: symbols_options, register_user_command: boolean, bind_keys: boolean, delay: number, window: window_options }

---@alias symbols_options
---| { newline: string, space: string }

---@alias window_options
---| { max_width: number, highlight_cursorline: number, map_register_keys: boolean, map_ctrl_k_and_j_movement: boolean, map_ctrl_p_and_n_movement: boolean, border: window_border }

---@alias register_mode
---| '"insert"' # Insert the register's contents like when in insert mode and pressing <C-R>
---| '"paste"' # Insert the register's contents by pretending a pasting action, similar to pressing "*reg*p
---| '"motion"' # Create a motion from the register, similar to pressing "*reg* (without pasting it yet)

---@alias window_border
---| '"none"'
---| '"single"'
---| '"double"'
---| '"rounded"'
---| '"solid"'
---| '"shadow"'
---| string[] # An array of eight strings which each corner and side character

local registers = {}

---Create the options object with defaults if the values are not set
---
---@param options options? list of options
---@return options options with default values
local function options_with_defaults(options)
    return vim.tbl_deep_extend("keep", options or {}, {
        -- Which registers to show and in what order
        show = "*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
        -- Symbols used to replace text in the preview buffer
        symbols = {
            newline = "",
            space = " ",
        },
        -- Whether to register the :Registers user command by default
        register_user_command = true,
        -- Whether to automatically map " in normal mode and <C-R> in insert mode to display the registers window
        bind_keys = true,
        -- How long, in seconds, to wait before opening the window
        delay = 0,
        -- Floating window options
        window = {
            -- Maximum width of the window, normal size will be calculated based on the size of the longest register
            max_width = 100,
            -- Whether to highlight the line the cursor is on
            highlight_cursorline = true,
            -- Whether to create key mappings for the register values inside the window
            map_register_keys = true,
            -- Whether to map <c-k> and <c-j> for moving in the window
            map_ctrl_k_and_j_movement = true,
            -- Whether to map <c-p> and <c-n> for moving in the window
            map_ctrl_p_and_n_movement = true,
            -- Border style of the window, options are "none", "single", "double", "rounded", "solid", "shadow" or an array of eight strings
            border = "none",
        },
    })
end

---Let the user configure this plugin
---
---This will also register the default user commands and key bindings
---
---@param options options? list of options
function registers.setup(options)
    -- Ensure that we have the proper neovim version
    if vim.fn.has("nvim-0.7.0") == 0 then
        vim.api.nvim_err_writeln("registers.nvim requires at least neovim 0.7.0")
        return
    end

    -- Create the options object
    registers.options = options_with_defaults(options)

    -- Create the user command to manually open the window with :Registers
    if registers.options.register_user_command then
        vim.api.nvim_create_user_command("Registers", registers.show, {})
    end

    -- Create a namespace for the signs
    registers._namespace = vim.api.nvim_create_namespace("registers.nvim")

    -- Bind the keys if applicable
    if registers.options.bind_keys then
        vim.api.nvim_set_keymap("n", "\"", "", {
            callback = function()
                return registers.show("motion")
            end,
            expr = true
        })
        vim.api.nvim_set_keymap("i", "<C-R>", "", {
            callback = function()
                return registers.show("insert")
            end,
            expr = true
        })
    end
end

---Popup the registers window
---
---@param mode register_mode? how the registers window should handle the selection of registers
function registers.show(mode)
    -- Check whether a key is pressed in between waiting for the window to open
    local interrupted = vim.wait(registers.options.delay * 1000, function()
        return vim.fn.getchar(true) ~= 0
    end, nil, false)

    if interrupted then
        -- While in a motion mode simulate the pressing of the " key
        return "\""
    else
        -- The timeout was not interrupted by a key press, open a buffer
        -- Must be scheduled so the window can be created at the right moment
        vim.schedule(function() registers._create_window(mode) end)
    end
end

---Create the window and the buffer
---
---@param mode register_mode?
function registers._create_window(mode)
    registers._mode = mode or "paste"

    -- Fill the registers
    registers._read_registers()

    -- Create the buffer the registers will be written to
    registers._buffer = vim.api.nvim_create_buf(false, true)

    -- Apply the key bindings to the buffer
    registers._set_bindings()

    -- Remove the buffer when the window is closed
    vim.api.nvim_buf_set_option(registers._buffer, "bufhidden", "wipe")

    -- The width is based on the longest line, but it will be truncated if the max width is supplied and is longer
    local window_width
    if registers.options.window.max_width > 0 then
        window_width = math.min(registers.options.window.max_width, registers._longest_register_length())

    else
        -- There is no max width supplied so use the longest registers length as the window size
        window_width = math.min(registers._longest_register_length())
    end

    -- Create the floating window
    local window_options = {
        -- Place the window next to the cursor
        relative = "cursor",
        -- Remove all window decorations
        style = "minimal",
        -- Width of the window
        width = window_width,
        -- Height of the window
        height = #registers._register_values,
        -- Place the new window just under the cursor
        row = 1,
        col = 0,
        -- How the edges are rendered
        border = registers.options.window.border,
    }
    registers._window = vim.api.nvim_open_win(registers._buffer, true, window_options)

    -- Register an autocommand to close the window if focus is lost
    vim.api.nvim_create_autocmd("BufLeave", {
        group = vim.api.nvim_create_augroup("RegistersWindow", {}),
        pattern = "<buffer>",
        callback = registers.close,
    })

    -- Make the buffer content cut-off instead of starting on new line
    vim.api.nvim_win_set_option(registers._window, "wrap", false)

    -- Show a column on the left for the register names
    vim.api.nvim_win_set_option(registers._window, "signcolumn", "yes")

    -- Highlight the cursor line
    if registers.options.window.highlight_cursorline then
        vim.api.nvim_win_set_option(registers._window, "cursorline", true)
    end

    -- Update the buffer
    registers._fill_window()
end

---Close the window
function registers.close()
    if not registers._window then
        -- There's nothing to close
        return
    end

    vim.api.nvim_win_close(registers._window, true)
    registers._window = nil
end

---Fill the arrays with the register values
function registers._read_registers()
    registers._register_values = {}

    -- Read all register information
    local show = registers.options.show
    for i = 1, #show do
        -- Get the register character from the array
        local register = show:sub(i, i)

        -- Get the register information
        local register_info = vim.fn.getreginfo(register)

        -- Ignore empty registers
        if register_info.regcontents and type(register_info.regcontents) == "table" and register_info.regcontents[1] and
            #register_info.regcontents[1] > 0 then
            register_info.register = register

            -- The register contents as a single line
            local line = table.concat(register_info.regcontents, registers.options.symbols.newline)
            register_info.line = line

            registers._register_values[#registers._register_values + 1] = register_info
        end
    end
end

---Fill the window's buffer
function registers._fill_window()
    -- Create an array of lines for all the registers
    local lines = {}
    for i = 1, #registers._register_values do
        local register = registers._register_values[i]

        lines[i] = register.line
    end

    -- Write the lines to the buffer
    vim.api.nvim_buf_set_lines(registers._buffer, 0, -1, false, lines)

    -- Don't allow the buffer to be modified
    vim.api.nvim_buf_set_option(registers._buffer, "modifiable", false)

    -- Create signs for the register itself
    for i = 1, #registers._register_values do
        local register = registers._register_values[i]

        -- Create signs for the register itself
        vim.api.nvim_buf_set_extmark(registers._buffer, registers._namespace, i - 1, -1, {
            id = i,
            sign_text = register.register
        })
    end
end

---Set the key bindings for the window
function registers._set_bindings()
    -- Create the mappings
    local mappings = {
        -- Return will apply the current highlighted register
        ["<CR>"] = registers._apply_register,
        -- Escape will close the window
        ["<ESC>"] = registers.close,
    }

    -- Create mappings for the register keys if applicable
    if registers.options.window.map_register_keys then
        for _, register in ipairs(registers._all_registers) do
            -- Pressing the character of a register will also apply it
            mappings[register] = function() registers._apply_register(register) end

            -- Also map uppercase registers if applicable
            if register:upper() ~= register then
                mappings[register:upper()] = function() registers._apply_register(register) end
            end
        end
    end

    -- Helper function for setting the keymap for all buffer modes
    local set_keymap_all_modes = function(key, rhs, callback)
        local map_options = {
            nowait = true,
            noremap = true,
            silent = true,
            callback = callback
        }

        vim.api.nvim_buf_set_keymap(registers._buffer, "n", key, rhs, map_options)
        vim.api.nvim_buf_set_keymap(registers._buffer, "i", key, rhs, map_options)
        vim.api.nvim_buf_set_keymap(registers._buffer, "v", key, rhs, map_options)
    end

    -- Map all keys
    for key, callback in pairs(mappings) do
        set_keymap_all_modes(key, '', callback)
    end

    -- Map <c-k> & <c-j> for moving up and down
    if registers.options.window.map_ctrl_k_and_j_movement then
        set_keymap_all_modes("<c-k>", "<up>")
        set_keymap_all_modes("<c-j>", "<down>")
    end

    -- Map <c-p> & <c-n> for moving up and down
    if registers.options.window.map_ctrl_p_and_n_movement then
        set_keymap_all_modes("<c-p>", "<up>")
        set_keymap_all_modes("<c-n>", "<down>")
    end
end

---Apply the register and close the window
---
---@param register string? which register to apply or the current line
function registers._apply_register(register)
    if register == nil then
        -- A register is selected by the cursor, get it based on the current line
        local cursor = unpack(vim.api.nvim_win_get_cursor(registers._window))
        register = registers._register_values[cursor].register
    end

    -- Close the window
    registers.close()

    print(register)
end

---Get the length of the longest register
function registers._longest_register_length()
    local longest = 0
    for i = 1, #registers._register_values do
        local register = registers._register_values[i]

        if #register.line > longest then
            longest = #register.line
        end
    end

    return longest
end

---All available registers
registers._all_registers = {
    "*", "+", "\"", "-", "/", "_", "=", "#", "%", ".",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
    "x", "y", "z",
    ":"
}

return registers
