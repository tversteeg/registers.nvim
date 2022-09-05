---@meta

---@mod intro Introduction
---@brief [[
---Registers.nvim is a minimal but very configurable Neovim plugin.
---
---Almost everything can be configured using the mandatory `registers.setup({})` method.
---
---`packer.nvim` minimal setup:
--->
---use {
---  "tversteeg/registers.nvim",
---  config = function()
---    require("registers").setup()
---  end
---}
---<
---@brief ]]

---@mod options `registers.setup` configuration options
---@class options `require("registers").setup({...})`
---@field show string Which registers to show and in what order
---@field delay number How long, in seconds, to wait before opening the window
---@field register_user_command boolean Whether to register the `:Registers` user command
---@field system_clipboard boolean Transfer selected register to the system clipboard
---@field trim_whitespace boolean Don't show whitespace at the begin and and of the registers, won't change the output from applying the register
---@field bind_keys bind_keys_options|boolean Which keys to bind, `true` maps all keys and `false` maps no keys
---@field symbols symbols_options Symbols used to replace text in the previous buffer.
---@field window window_options Floating window

---@type options default values for all options
local DEFAULT_OPTIONS = {
    show = "*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
    register_user_command = true,
    system_clipboard = true,
    trim_whitespace = true,
    delay = 0,

    ---@class bind_keys_options `require("registers").setup({ bind_keys = {...} })`
    ---@field normal boolean Map " in normal mode to display the registers window
    ---@field insert boolean Map <C-R> in insert mode to display the registers window
    ---@field visual boolean Map " in visual mode to display the registers window
    ---@field registers boolean Map all register keys in the registers window
    ---@field ctrl_n boolean Map <C-N> to move down in the registers window
    ---@field ctrl_p boolean Map <C-P> to move up in the registers window
    ---@field ctrl_j boolean Map <C-J> to move down in the registers window
    ---@field ctrl_k boolean Map <C-K> to move up in the registers window
    bind_keys = {
        normal = true,
        insert = true,
        visual = true,
        registers = true,
        ctrl_n = true,
        ctrl_p = true,
        ctrl_j = true,
        ctrl_k = true,
    },

    ---@class symbols_options `require("registers").setup({ symbols = {...} })`
    ---@field newline string? Symbol to show for a line break character, can not be the `"\\n"` symbol, use `"\\\\n"` (two backslashes) instead
    ---@field space string? Symbol to show for a space character
    ---@field tab string? Symbol to show for a tab character
    symbols = {
        newline = "⏎",
        space = " ",
        tab = "·",
    },

    ---@alias window_border
    ---| "none"
    ---| "single"
    ---| "double"
    ---| "rounded"
    ---| "solid"
    ---| "shadow"
    ---| string[] # An array of eight strings which each corner and side character

    ---@class window_options `require("registers").setup({ window = {...} })`
    ---@field max_width number? Maximum width of the window, normal size will be calculated based on the size of the longest register
    ---@field highlight_cursorline boolean? Whether to create key mappings for the register values inside the window
    ---@field border window_border? Border style of the window
    window = {
        max_width = 100,
        highlight_cursorline = true,
        border = "none",
    },
}

---@mod functions Functions

---@class registers
---@field options options
---@field private _mode string
---@field private _previous_mode string
---@field private _namespace string
---@field private _operator_count integer
---@field private _window integer?
---@field private _buffer integer?
---@field private _register_values { regcontents: string, line: string, register: string }[]
---@field private _mappings table<string, function>
local registers = {}

---Let the user configure this plugin.
---
---This will also register the default user commands and key bindings.
---@param options options? Plugin configuration options
---@usage `require("registers").setup({})`
function registers.setup(options)
    -- Ensure that we have the proper neovim version
    if vim.fn.has("nvim-0.7.0") == 0 then
        vim.api.nvim_err_writeln("registers.nvim requires at least Neovim 0.7.0")
        return
    end

    -- Create the options object with default values
    registers.options = vim.tbl_deep_extend("keep", options or {}, DEFAULT_OPTIONS)

    -- Create the user command to manually open the window with :Registers
    if registers.options.register_user_command then
        vim.api.nvim_create_user_command("Registers", registers.show, {})
    end

    -- Create a namespace for the signs
    registers._namespace = vim.api.nvim_create_namespace("registers.nvim")

    -- Pre-fill the key mappings
    registers._fill_mappings()

    -- Define the highlights
    registers._define_highlights()

    -- Bind the keys if applicable
    if registers._key_should_be_bound("normal") then
        vim.api.nvim_set_keymap("n", "\"", "", {
            callback = function()
                return registers.show("motion")
            end,
            expr = true
        })
    end
    if registers._key_should_be_bound("insert") then
        vim.api.nvim_set_keymap("i", "<C-R>", "", {
            callback = function()
                return registers.show("insert")
            end,
            expr = true
        })
    end
    if registers._key_should_be_bound("visual") then
        vim.api.nvim_set_keymap("v", "\"", "", {
            callback = function()
                return registers.show("paste")
            end,
            expr = true
        })
    end
end

---@alias register_mode
---| "insert" # Insert the register's contents like when in insert mode and pressing <C-R>
---| "paste" # Insert the register's contents by pretending a pasting action, similar to pressing "*reg*p, cannot be used in insert mode
---| "motion" # Create a motion from the register, similar to pressing "*reg* (without pasting it yet)

---Popup the registers window.
---@param mode register_mode? How the registers window should handle the selection of registers
---@usage [[
----- Disable all key bindings
---require("registers").setup({ bind_keys = false })
---
----- Define a custom for opening the register window when pressing "r"
---vim.api.nvim_set_keymap("n", "r", "", {
---    callback = function()
---        -- The "paste" argument means that when a register is selected it will automatically be pasted
---        return require("registers").show("paste")
---    end,
---    -- This is required for the registers window to function
---    expr = true
---})
---@usage ]]
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

---Close the window.
function registers.close()
    if not registers._window then
        -- There's nothing to close
        return
    end

    vim.api.nvim_win_close(registers._window, true)
    registers._window = nil
end

---Create the window and the buffer.
---@param mode register_mode?
---@private
function registers._create_window(mode)
    registers._mode = mode or "paste"

    -- Mode before opening the popup window
    registers._previous_mode = vim.api.nvim_get_mode().mode

    -- Handle illegal mode combinations
    if registers._mode == "paste" and registers._previous_mode == "i" then
        vim.api.nvim_err_writeln("registers.nvim doesn't support `registers.show('paste')` being invoked from insert mode")
    elseif registers._mode == "insert" and registers._previous_mode ~= "i" then
        vim.api.nvim_err_writeln("registers.nvim doesn't support `registers.show('insert')` being invoked from any mode other than insert mode")
        return
    end

    -- Keep track of the count that's used to invoke the window so it can be applied again
    registers._operator_count = vim.api.nvim_get_vvar("count")

    -- Fill the registers
    registers._read_registers()

    -- Create the buffer the registers will be written to
    registers._buffer = vim.api.nvim_create_buf(false, true)

    -- Apply the key bindings to the buffer
    registers._set_bindings()

    -- Remove the buffer when the window is closed
    vim.api.nvim_buf_set_option(registers._buffer, "bufhidden", "wipe")

    -- Set the filetype
    vim.api.nvim_buf_set_option(registers._buffer, "filetype", "registers")

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

    -- Add the colors
    vim.api.nvim_win_set_option(registers._window, "winhighlight", "NormalFloat:RegistersWindow")

    -- Update the buffer
    registers._fill_window()
end

---Fill the arrays with the register values.
---@private
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

            -- Trim the whitespace if applicable
            if registers.options.trim_whitespace then
                line = line:match("^%s*(.-)%s*$")
            end

            -- Replace newline characters
            line = line:gsub("[\n\r]", registers.options.symbols.newline)
                -- Replace tab characters
                :gsub("\t", registers.options.symbols.tab)
                -- Replace space characters
                :gsub(" ", registers.options.symbols.space)

            register_info.line = line

            registers._register_values[#registers._register_values + 1] = register_info
        end
    end
end

---Fill the window's buffer.
---@private
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

---Pre-fill the key mappings.
---@private
function registers._fill_mappings()
    -- Create the mappings
    registers._mappings = {
        -- Return will apply the current highlighted register
        ["<CR>"] = registers._apply_register,
        -- Escape will close the window
        ["<ESC>"] = registers.close,
    }

    -- Create mappings for the register keys if applicable
    if registers._key_should_be_bound("registers") then
        for _, register in ipairs(registers._all_registers) do
            -- Pressing the character of a register will also apply it
            registers._mappings[register] = function() registers._apply_register(register) end

            -- Also map uppercase registers if applicable
            if register:upper() ~= register then
                registers._mappings[register:upper()] = function() registers._apply_register(register) end
            end
        end
    end
end

---Set the key bindings for the window.
---@private
function registers._set_bindings()
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
    for key, callback in pairs(registers._mappings) do
        set_keymap_all_modes(key, '', callback)
    end

    -- Map the keys for moving up and down
    if registers._key_should_be_bound("ctrl_k") then
        set_keymap_all_modes("<c-k>", "<up>")
    end
    if registers._key_should_be_bound("ctrl_j") then
        set_keymap_all_modes("<c-j>", "<down>")
    end
    if registers._key_should_be_bound("ctrl_p") then
        set_keymap_all_modes("<c-p>", "<up>")
    end
    if registers._key_should_be_bound("ctrl_n") then
        set_keymap_all_modes("<c-n>", "<down>")
    end
end

---Apply the register and close the window.
---@param register string? Which register to apply or the current line
---@private
function registers._apply_register(register)
    -- Get the register symbol also when selecting it manually
    register = registers._register_symbol(register)

    -- Close the window
    registers.close()

    -- Handle the different modes
    if registers._mode == "insert" then
        -- Get the proper keycode for <C-R>
        local key = vim.api.nvim_replace_termcodes("<C-R>", true, true, true)

        if register == "=" then
            -- Apply <C-R>= again so the user can enter their query
            vim.api.nvim_feedkeys(key .. "=", "n", true)
        else
            -- Insert the other keys

            -- Capture the contents of the "=" register so it can be reset later
            local old_expr_content = vim.fn.getreg("=", 1)

            -- <CR> key
            local submit = vim.api.nvim_replace_termcodes("<CR>", true, true, true)

            -- Execute the selected register content using "=" register and insert the result
            vim.api.nvim_feedkeys(key .. "=@" .. register .. submit, "n", true)

            -- Recover the "=" register with a delay otherwise it doesn't get applied
            vim.schedule(function() vim.fn.setreg("=", old_expr_content) end)
        end
    elseif registers._previous_mode == "n" or registers._previous_mode == "v" then
        -- Simulate the keypresses require to perform the next actions
        vim.schedule(function()
            local keys = ""

            -- Go to previous visual selection if applicable
            if registers._previous_mode == "v" then
                keys = keys .. "gv"
            end

            -- Select the register if applicable
            if registers._mode == "motion" or registers._mode == "paste" then
                -- Push the operator count back if applicable
                if registers._operator_count > 0 then
                    keys = keys .. registers._operator_count
                end

                keys = keys .. "\"" .. register
            end

            -- Paste the register if applicable
            if registers._mode == "paste" then
                keys = keys .. "p"
            end

            vim.api.nvim_feedkeys(keys, "n", true)
        end)
    end

    -- Copy the selected register to the system clipboard if applicable
    if registers.options.system_clipboard then
        if vim.fn.has("clipboard") == 1 then
            vim.cmd("let @*=@" .. register)
        else
            vim.api.nvim_err_writeln("No clipboard available")
        end
    end
end

---Register the highlights.
function registers._define_highlights()
    -- Helper function to make the definitions cleaner
    function hl(name, link, syntax_type, match, opts)
        -- Wrap match items in quotes so we don't have to
        if syntax_type == "match" then
            match = "\"" .. match .. "\""
        end

        -- Define the syntax for the highlight
        local syntax_command = ("syntax %s Registers%s %s %s"):format(syntax_type, name, match, opts)
        vim.api.nvim_err_writeln(syntax_command)
        vim.api.nvim_exec(syntax_command, false)

        -- Link the highlight
        if link then
            vim.api.nvim_set_hl(registers._namespace, "Registers" .. name, { link = link })
        end
    end

    -- The content of the line
    hl("ContentNumber", "Number", "match", "\\d\\+", "contained")
    hl("ContentNumber", "Number", "match", "[-+]\\d\\+\\.\\d\\+", "contained")
    hl("ContentEscaped", "Special", "match", "^\\w", "contained")
    hl("ContentEscaped", "Special", "keyword", "\\.", "contained")
    hl("ContentString", "String", "match", "\\\"[^\\\"]*\\\"", "contained")
    hl("ContentString", "String", "match", "'[^']*'", "contained")
    hl("ContentWhitespace", "Comment", "match", " ", "contained")
    --hl("ContentWhitespace", "Comment", "keyword", "␉ · ⎵ \n \t ⏎", "contained")
    hl("ContentRegion", nil, "match", ".*", "contains=RegistersContent.* contained")

    hl("PrefixSelection", "Constant", "match", "[*+]", "contained")
    hl("PrefixDefault", "Function", "match", "\"", "contained")
    hl("PrefixUnnamed", "Statement", "match", "\\\\", "contained")
    hl("PrefixReadOnly", "Type", "match", "[:.%]", "contained")
    hl("PrefixLastSearch", "Tag", "match", "\\/", "contained")
    hl("PrefixDelete", "Special", "match", "-", "contained")
    hl("PrefixYank", "Delimiter", "keyword", "0", "contained")
    hl("PrefixHistory", "Number", "keyword", "1 2 3 4 5 6 7 8 9", "contained")
    hl("PrefixNamed", "Todo", "match", "[a-z]", "contained")
    hl("Prefix", nil, "match", "[a-z]", "contains=RegistersPrefix.*")

    vim.api.nvim_set_hl(registers._namespace, "RegistersWindow", { link = "NormalFloat" })
end

---Get the length of the longest register.
---@return integer The length of the longest register
---@nodiscard
---@private
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

---Get the register or when it's `nil` the selected register from the cursor.
---@param register string? Register to look up, if nothing is passed the current line will be used
---@return string The register or the current line
---@nodiscard
---@private
function registers._register_symbol(register)
    if register == nil then
        -- A register is selected by the cursor, get it based on the current line
        local cursor = unpack(vim.api.nvim_win_get_cursor(registers._window))

        return registers._register_values[cursor].register
    else
        -- Use the already set value
        return register
    end
end

---Get the register information matching the register.
---@param register string? Register to look up, if nothing is passed the current line will be used
---@return table? Register information from `registers._register_values`
---@private
function registers._register_info(register)
    if register == nil then
        -- A register is selected by the cursor, get it based on the current line
        local cursor = unpack(vim.api.nvim_win_get_cursor(registers._window))

        return registers._register_values[cursor]
    else
        -- Otherwise find it by looking up the register in the list
        for i = 1, #registers._register_values do
            if registers._register_values[i].register == register then
                return registers._register_values[i]
            end
        end
    end
end

---Whether a key should be bound.
---@param option string Which item from bind_keys should be checked
---@return boolean Whether the key should be bound
---@nodiscard
---@private
function registers._key_should_be_bound(option)
    if type(registers.options.bind_keys) == "boolean" then
        return registers.options.bind_keys --[[@as boolean]]
    else
        return registers.options.bind_keys[option]
    end
end

---All available registers.
---@private
registers._all_registers = {
    "*", "+", "\"", "-", "/", "_", "=", "#", "%", ".",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
    "x", "y", "z",
    ":"
}

return registers
