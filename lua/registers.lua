local registers = {}

-- Create the options object with defaults if the values are not set
local function options_with_defaults(options)
    return vim.tbl_deep_extend("keep", options, {
        -- Which registers to show and in what order
        show = "*+a\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
        -- Symbols used to replace text in the preview buffer
        symbols = {
            newline = "",
            space = " ",
        },
        -- Whether to register the :Registers user command by default
        register_user_command = true,
        -- Floating window options
        window = {
            -- Maxmium width of the window, normal size will be calculated based on the size of the longest register
            max_width = 100,
            -- Whether to highlight the line the cursor is on
            highlight_cursorline = true,
            -- Whether to create key mappings for the register values inside the window
            map_register_keys = true,
            -- Whether to map <c-k> and <c-j> for moving in the window
            map_ctrl_k_and_j_movement = true,
            -- Whether to map <c-p> and <c-n> for moving in the window
            map_ctrl_p_and_n_movement = true,
        },
    })
end

-- Let the user configure this plugin
--
-- This will also register the default user commands and key bindings
function registers.setup(options)
    -- Ensure that we have the proper neovim version
    if vim.fn.has("nvim-0.7.0") == 0 then
        vim.api.nvim_err_writeln("registers.nvim requires at least neovim 0.7.0")
        return
    end

    -- Create the options object
    registers.options = options_with_defaults(options)
    vim.pretty_print(registers.options)

    -- Create the user command to manually open the window with :Registers
    if registers.options.register_user_command then
        vim.api.nvim_create_user_command("Registers", registers.show, {})
    end
end

-- The function to popup the registers window
function registers.show()
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
        window_width = registers._longest_register_length()
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
    }
    registers._window = vim.api.nvim_open_win(registers._buffer, true, window_options)

    -- Register an autocommand to close the window if focus is lost
    vim.api.nvim_create_autocmd("BufLeave", {
        group = vim.api.nvim_create_augroup("RegistersWindow", {}),
        pattern = "<buffer>",
        callback = registers.close,
    })

    -- Highlight the cursor line
    if registers.options.window.highlight_cursorline then
        vim.api.nvim_win_set_option(registers._window, "cursorline", true)
    end

    -- Update the buffer
    registers._fill_window()

    -- Put the focus on the window
    vim.api.nvim_set_current_win(registers._window)
end

-- Close the window
function registers.close()
    if not registers._window then
        -- There's nothing to close
        return
    end

    vim.api.nvim_win_close(registers._window, true)
    registers._window = nil
end

-- Fill the arrays with the register values
function registers._read_registers()
    registers._register_values = {}

    -- Read all register information
    local show = registers.options.show
    for i = 1, #show do
        -- Get the register character from the array
        local register = show:sub(i, i)

        -- Get the register information
        local register_info = vim.api.nvim_call_function("getreginfo", { register })

        -- Ignore empty registers
        if register_info.regcontents and type(register_info.regcontents) == "table" and #register_info.regcontents[1] > 0 then
            register_info.register = register

            -- The register contents as a single line
            local line = table.concat(register_info.regcontents, registers.options.symbols.newline)
            register_info.line = ("%s: %s"):format(register, line)

            registers._register_values[#registers._register_values + 1] = register_info
        end
    end
end

-- Fill the window's buffer
function registers._fill_window()
    -- Get the width of the window to truncate the strings
    local max_width = vim.api.nvim_win_get_width(registers._window) - 2

    -- Create an array of lines for all the registers
    local lines = {}
    for i = 1, #registers._register_values do
        local register = registers._register_values[i]

        lines[i] = register.line:sub(1, max_width)
    end

    -- Write the lines to the buffer
    vim.api.nvim_buf_set_lines(registers._buffer, 0, -1, false, lines)

    -- Don't allow the buffer to be modified
    vim.api.nvim_buf_set_option(registers._buffer, "modifiable", false)
end

-- Set the key bindings for the window
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

-- Apply the register and close the window
--
-- When no argument is passed the current line is assumed to be the target
function registers._apply_register(register)
    -- Close the window
    registers.close()

    print(register)
end

-- Get the length of the longest register
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

-- All available registers
registers._all_registers = { "*", "+", "\"", "-", "/", "_", "=", "#", "%", ".", "0", "1", "2", "3", "4", "5", "6", "7",
    "8",
    "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
    "w", "x", "y", "z", ":" }

return registers
