---@meta

---@class registers
---@field options options
---@field private _mode string
---@field private _previous_mode string
---@field private _namespace string
---@field private _operator_count integer
---@field private _window integer?
---@field private _buffer integer?
---@field private _register_values { regcontents: string, line: string, register: string }[]
---@field private _empty_registers string[]
---@field private _mappings table<string, function>
local registers = {}

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

---@mod options `registers.setup` configuration options.
---@class options `require("registers").setup({...})`
---@field show string Which registers to show and in what order. Default is `"*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:"`.
---@field show_empty boolean Show the registers which aren't filled in a separate line. Default is `true`.
---@field delay number How long, in seconds, to wait before opening the window. Default is `0`.
---@field register_user_command boolean Whether to register the `:Registers` user command. Default is `true`.
---@field system_clipboard boolean Transfer selected register to the system clipboard. Default is `true`.
---@field trim_whitespace boolean Don't show whitespace at the begin and and of the registers, won't change the output from applying the register. Default is `true`.
---@field hide_only_whitespace boolean Treat registers with only whitespace as empty registers. Default is `true`.
---@field bind_keys bind_keys_options|boolean Which keys to bind, `true` maps all keys and `false` maps no keys. Default is `true`.
---@field symbols symbols_options Symbols used to replace text in the previous buffer.
---@field window window_options Floating window
---@field sign_highlights sign_highlights_options Highlights for the sign section of the window

---@alias register_mode
---| "insert" # Insert the register's contents like when in insert mode and pressing <C-R>.
---| "paste" # Insert the register's contents by pretending a pasting action, similar to pressing "*reg*p, cannot be used in insert mode.
---| "motion" # Create a motion from the register, similar to pressing "*reg* (without pasting it yet).

---@class bind_keys_options `require("registers").setup({ bind_keys = {...} })`
---@field normal fun()|false Function to map to " in normal mode to display the registers window, `false` to disable the binding. Default is `registers.show_motion_window`.
---@field visual fun()|false Function to map to " in visual mode to display the registers window, `false` to disable the binding. Default is `registers.show_motion_window`.
---@field insert fun()|false Function to map to <C-R> in insert mode to display the registers window, `false` to disable the binding. Default is `registers.show_insert_window`.
---@field registers fun(register:string?,mode:register_mode) Function to map to the register selected by pressing it's key. Default is `registers.apply_register`.
---@field return_key fun(register:string?,mode:register_mode) Function to map to <CR> in the window. Default is `registers.apply_register`.
---@field escape fun(register:string?,mode:register_mode) Function to map to <ESC> in the window. Default is `registers.close_window`.
---@field ctrl_n fun()|false Function to map <C-N> to move down in the registers window. Default is `registers.move_cursor_down`.
---@field ctrl_p fun()|false Function to map <C-P> to move up in the registers window. Default is `registers.move_cursor_up`.
---@field ctrl_j fun()|false Function to map <C-J> to move down in the registers window. Default is `registers.move_cursor_down`.
---@field ctrl_k fun()|false Function to map <C-K> to move up in the registers window. Default is `registers.move_cursor_up`.

---@alias window_border
---| "none"
---| "single"
---| "double"
---| "rounded"
---| "solid"
---| "shadow"
---| string[] # An array of eight strings which each corner and side character.

---@class window_options `require("registers").setup({ window = {...} })`
---@field max_width number? Maximum width of the window, normal size will be calculated based on the size of the longest register. Default is `100`.
---@field highlight_cursorline boolean? Whether to create key mappings for the register values inside the window. Default is `true`.
---@field border window_border? Border style of the window. Default is `"none"`.
---@field transparency integer? Transparency of the window, value can be between 0-100, 0 disables it. Default is `20`.

---@class symbols_options `require("registers").setup({ symbols = {...} })`
---@field newline string? Symbol to show for a line break character, can not be the `"\\n"` symbol, use `"\\\\n"` (two backslashes) instead. Default is `"⏎"`.
---@field space string? Symbol to show for a space character. Default is `" "`.
---@field tab string? Symbol to show for a tab character. Default is `"·"`.

---@class sign_highlights_options `require("registers").setup({ sign_highlights = {...} })`
---@field cursorline string? Highlight group for when the cursor is over the line. Default is `"Visual"`.
---@field selection string? Highlight group for the selection registers, `*+`. Default is `"Constant"`.
---@field default string? Highlight group for the default register, `"`. Default is `"Function"`.
---@field unnamed string? Highlight group for the unnamed register, `\\`. Default is `"Statement"`.
---@field read_only string? Highlight group for the read only registers, `:.%`. Default is `"Type"`.
---@field alternate_buffer string? Highlight group for the alternate buffer register, `#`. Default is `"Type"`.
---@field expression string? Highlight group for the expression register, `=`. Default is `"Exception"`.
---@field black_hole string? Highlight group for the black hole register, `_`. Default is `"Error"`.
---@field last_search string? Highlight group for the last search register, `/`. Default is `"Operator"`.
---@field delete string? Highlight group for the delete register, `-`. Default is `"Special"`.
---@field yank string? Highlight group for the yank register, `0`. Default is `"Delimiter"`.
---@field history string? Highlight group for the history registers, `1-9`. Default is `"Number"`.
---@field named string? Highlight group for the named registers, `a-z`. Default is `"Todo"`.

---Get the default values for all options.
---@return options default values for all options
function registers.default_options()
    return {
        show = "*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
        show_empty = true,
        register_user_command = true,
        system_clipboard = true,
        trim_whitespace = true,
        hide_only_whitespace = true,
        delay = 0,

        bind_keys = {
            normal = registers.show_motion_window,
            visual = registers.show_motion_window,
            insert = registers.show_insert_window,
            registers = registers.apply_register,
            return_key = registers.apply_register,
            escape = registers.close_window,
            ctrl_n = registers.move_cursor_down,
            ctrl_p = registers.move_cursor_up,
            ctrl_j = registers.move_cursor_down,
            ctrl_k = registers.move_cursor_up,
        },

        symbols = {
            newline = "⏎",
            space = " ",
            tab = "·",
        },

        window = {
            max_width = 100,
            highlight_cursorline = true,
            border = "none",
            transparency = 20,
        },

        sign_highlights = {
            cursorline = "Visual",
            selection = "Constant",
            default = "Function",
            unnamed = "Statement",
            read_only = "Type",
            expression = "Exception",
            black_hole = "Error",
            alternate_buffer = "Operator",
            last_search = "Tag",
            delete = "Special",
            yank = "Delimiter",
            history = "Number",
            named = "Todo",
        },
    }
end

---@mod functions Functions

---Let the user configure this plugin.
---
---This will also register the default user commands and key bindings.
---@param options options? Plugin configuration options.
---@usage `require("registers").setup({})`
function registers.setup(options)
    -- Ensure that we have the proper neovim version
    if vim.fn.has("nvim-0.7.0") == 0 then
        vim.api.nvim_err_writeln("registers.nvim requires at least Neovim 0.7.0")
        return
    end

    -- Create the options object with default values
    registers.options = vim.tbl_deep_extend("keep", options or {}, registers.default_options())

    -- Create the user command to manually open the window with :Registers
    if registers.options.register_user_command then
        vim.api.nvim_create_user_command("Registers", registers.show_window, {})
    end

    -- Create a namespace for the highlights and signs
    registers._namespace = vim.api.nvim_create_namespace("registers")

    -- Pre-fill the key mappings
    registers._fill_mappings()

    -- Bind the keys if applicable
    if registers._key_should_be_bound("normal") then
        vim.api.nvim_set_keymap("n", "\"", "", {
            callback = registers.options.bind_keys.normal,
            expr = true
        })
    end
    if registers._key_should_be_bound("visual") then
        vim.api.nvim_set_keymap("v", "\"", "", {
            callback = registers.options.bind_keys.visual,
            expr = true
        })
    end
    if registers._key_should_be_bound("insert") then
        vim.api.nvim_set_keymap("i", "<C-R>", "", {
            callback = registers.options.bind_keys.insert,
            expr = true
        })
    end
end

---Popup the registers window.
---@param mode register_mode? How the registers window should handle the selection of registers.
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
function registers.show_window(mode)
    -- Check whether a key is pressed in between waiting for the window to open
    local interrupted = vim.wait(registers.options.delay * 1000, function()
        return vim.fn.getchar(true) ~= 0
    end, nil, false)

    -- Mode before opening the popup window
    registers._previous_mode = vim.api.nvim_get_mode().mode

    -- Open the window when another key hasn't been pressed in the meantime
    if not interrupted then
        -- Keep track of the count that's used to invoke the window so it can be applied again
        registers._operator_count = vim.api.nvim_get_vvar("count")

        -- Store the mode which defaults to paste
        registers._mode = mode or "paste"

        -- The timeout was not interrupted by a key press, open a buffer
        -- Must be scheduled so the window can be created at the right moment
        vim.schedule(function() registers._create_window() end)
    else
        -- While in a motion mode is shown simulate the pressing of the key depending on the mode
        if registers._previous_mode == 'n' or registers._previous_mode == 'v' then
            return "\""
        else
            return vim.api.nvim_replace_termcodes("<C-R>", true, true, true)
        end
    end
end

---Popup the registers window which will create a motion from the selected register.
---
---Simple wrapper around `registers.show_window("motion")` so it can be easily used in configurations.
function registers.show_motion_window()
    return registers.show_window("motion")
end

---Popup the registers window which will create a paste from the selected register.
---
---Simple wrapper around `registers.show_window("paste")` so it can be easily used in configurations.
function registers.show_paste_window()
    return registers.show_window("paste")
end

---Popup the registers window which will create a insert from the selected register.
---
---Simple wrapper around `registers.show_window("insert")` so it can be easily used in configurations.
function registers.show_insert_window()
    return registers.show_window("insert")
end

---Close the window.
function registers.close_window()
    if not registers._window then
        -- There's nothing to close
        return
    end

    vim.api.nvim_win_close(registers._window, true)
    registers._window = nil
end

---Apply the specified register.
---@param register string? Which register to apply, when `nil` is used the current line of the window is used, with the prerequisite that the window is opened.
---@param mode register_mode? How the register should be applied.
function registers.apply_register(register, mode)
    -- When the current line needs to be selected a window also needs to be open
    if register == nil and registers._window == nil then
        vim.api.nvim_err_writeln("registers window isn't open, can't apply register")
        return
    end

    -- Overwrite the mode
    if mode then
        registers._mode = mode
    end

    registers._apply_register(register)
end

---Paste the specified register.
---
---Simple wrapper around `registers.apply_register(.., "paste")` so it can be easily used in configurations.
---@param register string? Which register to apply, when `nil` is used the current line of the window is used, with the prerequisite that the window is opened.
function registers.paste_register(register)
    registers.apply_register(register, "paste")
end

---Create a motion from the specified register.
---
---Simple wrapper around `registers.apply_register(.., "motion")` so it can be easily used in configurations.
---@param register string? Which register to apply, when `nil` is used the current line of the window is used, with the prerequisite that the window is opened.
function registers.motion_register(register)
    registers.apply_register(register, "motion")
end

---Create the window and the buffer.
---@private
function registers._create_window()
    -- Handle illegal mode combinations
    if registers._mode == "paste" and registers._previous_mode == "i" then
        vim.api.nvim_err_writeln("registers.nvim doesn't support `registers.show_window('paste')` being invoked from insert mode")
    elseif registers._mode == "insert" and registers._previous_mode ~= "i" and registers._previous_mode ~= "c" then
        vim.api.nvim_err_writeln("registers.nvim doesn't support `registers.show_window('insert')` being invoked from any mode other than insert mode")
        return
    end

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

    -- Height is based on the amount of available registers
    local window_height = #registers._register_values
    if registers.options.show_empty then
        -- Add an extra line for the Empty: line
        window_height = window_height + 1
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
        height = window_height,
        -- Place the new window just under the cursor
        row = 1,
        col = 0,
        -- How the edges are rendered
        border = registers.options.window.border,
    }
    -- Make the window active when the window is not a preview
    registers._window = vim.api.nvim_open_win(registers._buffer, true, window_options)

    -- Register an autocommand to close the window if focus is lost
    vim.api.nvim_create_autocmd("BufLeave", {
        group = vim.api.nvim_create_augroup("RegistersWindow", {}),
        pattern = "<buffer>",
        callback = registers.close_window,
    })

    -- Make the buffer content cut-off instead of starting on new line
    vim.api.nvim_win_set_option(registers._window, "wrap", false)

    -- Show a column on the left for the register names
    vim.api.nvim_win_set_option(registers._window, "signcolumn", "yes")

    -- Highlight the cursor line
    if registers.options.window.highlight_cursorline then
        vim.api.nvim_win_set_option(registers._window, "cursorline", true)
    end

    -- Make the window transparent
    if registers.options.window.transparency then
        vim.api.nvim_win_set_option(registers._window, "winblend", registers.options.window.transparency)
    end

    -- Add the colors
    registers._define_highlights()

    -- Update the buffer
    registers._fill_window()

    -- Ensure the window shows up
    vim.cmd("redraw!")

    -- Put the window in normal mode when using a visual selection
    if registers._previous_mode == 'v' or registers._previous_mode == '^V' or registers._previous_mode == 'V' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "n", true)
    end
end

---Move the cursor up in the window.
function registers.move_cursor_up()
    if registers._window == nil then
        vim.api.nvim_err_writeln("registers window isn't open, can't move cursor")
        return
    end

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Up>", true, true, true), "n", true)
end

---Move the cursor down in the window.
function registers.move_cursor_down()
    if registers._window == nil then
        vim.api.nvim_err_writeln("registers window isn't open, can't move cursor")
        return
    end

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Down>", true, true, true), "n", true)
end

---Fill the arrays with the register values.
---@private
function registers._read_registers()
    registers._register_values = {}
    registers._empty_registers = {}

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
            local hide = false
            -- Check whether the register should be hidden due to being empty
            if line and registers.options.hide_only_whitespace then
                hide = #(line:match("^%s*(.-)%s*$")) == 0

                -- Place it in the empty registers
                registers._empty_registers[#registers._empty_registers + 1] = register
            end

            if not hide and line and type(line) == "string" then
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
        else
            -- Place it in the empty registers
            registers._empty_registers[#registers._empty_registers + 1] = register
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

    -- Add the empty line
    if registers.options.show_empty then
        lines[#lines + 1] = "Empty: " .. table.concat(registers._empty_registers, " ")
    end

    -- Write the lines to the buffer
    vim.api.nvim_buf_set_lines(registers._buffer, 0, -1, false, lines)

    -- Don't allow the buffer to be modified
    vim.api.nvim_buf_set_option(registers._buffer, "modifiable", false)

    -- Create signs and highlights for the register itself
    for i = 1, #registers._register_values do
        local register = registers._register_values[i]

        -- Create signs for the register itself, and highlight the line
        vim.api.nvim_buf_set_extmark(registers._buffer, registers._namespace, i - 1, 0, {
            id = i,
            sign_text = register.register,
            sign_hl_group = registers._highlight_for_sign(register.register),
            cursorline_hl_group = registers.options.sign_highlights.cursorline,
        })
    end
end

---Pre-fill the key mappings.
---@private
function registers._fill_mappings()
    -- Create the mappings to call the function specified in the options
    registers._mappings = {
        ["<CR>"] = function() registers.options.bind_keys.return_key(nil, registers._mode) end,
        ["<ESC>"] = function() registers.options.bind_keys.escape(nil, registers._mode) end,
    }

    -- Create mappings for the register keys if applicable
    if registers.options.bind_keys then
        for _, register in ipairs(registers._all_registers) do
            local register_func = function() registers.options.bind_keys.registers(register, registers._mode) end

            -- Pressing the character of a register will also apply it
            registers._mappings[register] = register_func

            -- Also map uppercase registers if applicable
            if register:upper() ~= register then
                registers._mappings[register:upper()] = register_func
            end
        end
    end
end

---Set the key bindings for the window.
---@private
function registers._set_bindings()
    -- Helper function for setting the keymap for all buffer modes
    local set_keymap_all_modes = function(key, callback)
        local map_options = {
            nowait = true,
            noremap = true,
            silent = true,
            callback = callback
        }

        vim.api.nvim_buf_set_keymap(registers._buffer, "n", key, '', map_options)
        vim.api.nvim_buf_set_keymap(registers._buffer, "i", key, '', map_options)
        vim.api.nvim_buf_set_keymap(registers._buffer, "v", key, '', map_options)
    end

    -- Map all keys
    if registers._key_should_be_bound("registers") then
        for key, callback in pairs(registers._mappings) do
            set_keymap_all_modes(key, callback)
        end
    end

    -- Map the keys for moving up and down
    if registers._key_should_be_bound("ctrl_k") then
        set_keymap_all_modes("<c-k>", registers.options.bind_keys.ctrl_k)
    end
    if registers._key_should_be_bound("ctrl_j") then
        set_keymap_all_modes("<c-j>", registers.options.bind_keys.ctrl_j)
    end
    if registers._key_should_be_bound("ctrl_p") then
        set_keymap_all_modes("<c-p>", registers.options.bind_keys.ctrl_p)
    end
    if registers._key_should_be_bound("ctrl_n") then
        set_keymap_all_modes("<c-n>", registers.options.bind_keys.ctrl_n)
    end
end

---Apply the register and close the window.
---@param register string? Which register to apply or the current line
---@private
function registers._apply_register(register)
    -- Get the register symbol also when selecting it manually
    register = registers._register_symbol(register)

    -- Do nothing if no valid register is chosen
    if not register then
        return
    end

    -- Close the window
    registers.close_window()

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
    elseif registers._previous_mode == "n"
        or registers._previous_mode == "v" or registers._previous_mode == "V" or registers._previous_mode == "^V" then
        -- Simulate the keypresses require to perform the next actions
        vim.schedule(function()
            local keys = ""

            -- Go to previous visual selection if applicable
            if registers._previous_mode == "v" or registers._previous_mode == "V" or registers._previous_mode == "^V" then
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
            vim.cmd("let @+=@" .. register)
        else
            vim.api.nvim_err_writeln("No clipboard available")
        end
    end
end

---Register the highlights.
---@private
function registers._define_highlights()
    -- Set the namespace for the highlights on the window, if we're running an older neovim version make it global
    ---@type integer|string
    local namespace = 0
    if vim.fn.has("nvim-0.8.0") == 1 then
        namespace = registers._namespace
        vim.api.nvim_win_set_hl_ns(registers._window, namespace)
    end

    -- Define the matches and link them
    vim.cmd([[syntax match RegistersNumber "\d\+"]])
    vim.cmd([[syntax match RegistersNumber "[-+]\d\+\.\d\+"]])
    vim.api.nvim_set_hl(namespace, "RegistersNumber", { link = "Number" })

    vim.cmd([[syntax region RegistersString start=+"+ skip=+\\"+ end=+"+]])
    vim.cmd([[syntax region RegistersString start=+'+ skip=+\\'+ end=+'+]])
    vim.api.nvim_set_hl(namespace, "RegistersString", { link = "String" })

    -- ⏎
    vim.cmd([[syntax match RegistersWhitespace "\%u23CE"]])
    -- ⎵
    vim.cmd([[syntax match RegistersWhitespace "\%u23B5"]])
    -- ·
    vim.cmd([[syntax match RegistersWhitespace "\%u00B7"]])
    vim.cmd([[syntax match RegistersWhitespace " "]])
    vim.api.nvim_set_hl(namespace, "RegistersWhitespace", { link = "Comment" })

    vim.cmd([[syntax match RegistersEscaped "\\\w"]])
    vim.cmd([[syntax keyword RegistersEscaped \.]])
    vim.api.nvim_set_hl(namespace, "RegistersEscaped", { link = "Special" })

    -- Empty region
    function hl_symbol(type, symbols, group)
        local name = "RegistersSymbol_" .. group
        if type == "match" then
            vim.cmd(("syntax match %s %q contained"):format(name, symbols))
        else
            vim.cmd(("syntax %s %s %s contained"):format(type, name, symbols))
        end
        vim.api.nvim_set_hl(namespace, name, { link = registers.options.sign_highlights[group] })
    end

    hl_symbol("match", "[*+]", "selection")
    hl_symbol("match", "\\\"", "default")
    hl_symbol("match", "\\\\", "unnamed")
    hl_symbol("match", "[:.%]", "read_only")
    hl_symbol("match", "_", "black_hole")
    hl_symbol("match", "=", "expression")
    hl_symbol("match", "#", "alternate_buffer")
    hl_symbol("match", "\\/", "last_search")
    hl_symbol("match", "-", "delete")
    hl_symbol("keyword", "0", "yank")
    hl_symbol("keyword", "1 2 3 4 5 6 7 8 9", "history")
    hl_symbol("keyword", "a b c d e f g h i j k l m n o p q r s t u v w x y z", "named")

    vim.cmd([[syntax match RegistersEmptyString "Empty: " contained]])

    vim.cmd([[syntax region RegistersEmpty start="^Empty: " end="$" contains=RegistersSymbol.*,RegistersEmptyString]])
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
---@return string? The register or the current line, if applicable
---@nodiscard
---@private
function registers._register_symbol(register)
    if register == nil then
        -- A register is selected by the cursor, get it based on the current line
        local cursor = unpack(vim.api.nvim_win_get_cursor(registers._window))

        if #registers._register_values < cursor then
            -- The empty section has been chosen, it doesn't select anything
            return nil
        end

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

    return nil
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

---The highlight group from the options for the sign.
---@param register string Which register to get the highlight group for
---@return string Highlight group
---@nodiscard
---@private
function registers._highlight_for_sign(register)
    local hl = registers.options.sign_highlights

    return ({
        ["*"] = hl.selection, ["+"] = hl.selection,
        ["\""] = hl.default,
        ["\\"] = hl.unnamed,
        [":"] = hl.read_only, ["."] = hl.read_only, ["%"] = hl.read_only,
        ["/"] = hl.last_search,
        ["-"] = hl.delete,
        ["_"] = hl.black_hole,
        ["="] = hl.expression,
        ["#"] = hl.alternate_buffer,
        ["0"] = hl.yank,
        ["1"] = hl.history, ["2"] = hl.history, ["3"] = hl.history, ["4"] = hl.history, ["5"] = hl.history,
        ["6"] = hl.history, ["7"] = hl.history, ["8"] = hl.history, ["9"] = hl.history,
        a = hl.named, b = hl.named, c = hl.named, d = hl.named, e = hl.named, f = hl.named, g = hl.named, h = hl.named,
        i = hl.named, j = hl.named, k = hl.named, l = hl.named, m = hl.named, n = hl.named, o = hl.named, p = hl.named,
        q = hl.named, r = hl.named, s = hl.named, t = hl.named, u = hl.named, v = hl.named, w = hl.named, x = hl.named,
        y = hl.named, z = hl.named,
    })[register]
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
