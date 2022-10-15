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
---
---Keys can be bound using functions, to make it easier for use I've made all functions except `registers.setup()` return callback functions that can be configured and passed to fields in the `bind_keys` example.
---
---For example, to apply a delay of a second after selecting the register with it's key (for example pressing the '0' key to apply the '0' register when it's open):
---use {
---  "tversteeg/registers.nvim",
---  config = function()
---    local registers = require("registers")
---    registers.setup({
---      bind_keys = {
---        registers = registers.apply_register({ delay = 1 }),
---      },
---    })
---  end
---}
---<
---@brief ]]

---@class registers
---@field options options
---@field private _mode string
---@field private _previous_mode string
---@field private _namespace string
---@field private _operator_count integer
---@field private _window integer?
---@field private _buffer integer?
---@field private _preview_buffer integer?
---@field private _register_values { regcontents: string, line: string, register: string, type_symbol?: string, regtype: string }[]
---@field private _empty_registers string[]
---@field private _mappings table<string, function>
local registers = {}

---@mod setup `registers.setup` configuration options.

---`require("registers").setup({...})`
---@class options
---@field show string Which registers to show and in what order. Default is `"*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:"`.
---@field show_empty boolean Show the registers which aren't filled in a separate line. Default is `true`.
---@field preview boolean Show the how the highlighted register will be applied in the target buffer. Default is `true`.
---@field register_user_command boolean Whether to register the `:Registers` user command. Default is `true`.
---@field system_clipboard boolean Transfer selected register to the system clipboard. Default is `true`.
---@field trim_whitespace boolean Don't show whitespace at the begin and and of the registers, won't change the output from applying the register. Default is `true`.
---@field hide_only_whitespace boolean Treat registers with only whitespace as empty registers. Default is `true`.
---@field show_register_types boolean Show how the register will be applied in the sign bar, the characters can be customized in the `symbols` table. Default is `true`.
---@field bind_keys bind_keys_options|boolean Which keys to bind, `true` maps all keys and `false` maps no keys.
---@field events events_options Functions that will be called when certain events happen.
---@field symbols symbols_options Symbols used to replace text in the previous buffer.
---@field window window_options Floating window
---@field sign_highlights sign_highlights_options Highlights for the sign section of the window

---@alias register_mode
---| '"insert"' # Insert the register's contents like when in insert mode and pressing <C-R>.
---| '"paste"' # Insert the register's contents by pretending a pasting action, similar to pressing "*reg*p, cannot be used in insert mode.
---| '"motion"' # Create a motion from the register, similar to pressing "*reg* (without pasting it yet).

---`require("registers").setup({ bind_keys = {...} })`
---@class bind_keys_options
---@field normal fun()|false Function to map to " in normal mode to display the registers window, `false` to disable the binding. Default is `registers.show_window({ mode = "motion" })`.
---@field visual fun()|false Function to map to " in visual mode to display the registers window, `false` to disable the binding. Default is `registers.show_window({ mode = "motion" })`.
---@field insert fun()|false Function to map to <C-R> in insert mode to display the registers window, `false` to disable the binding. Default is `registers.show_window({ mode = "insert" })`.
---@field registers fun(register:string?,mode:register_mode) Function to map to the register selected by pressing it's key. Default is `registers.apply_register()`.
---@field return_key fun(register:string?,mode:register_mode) Function to map to <CR> in the window. Default is `registers.apply_register()`.
---@field escape fun(register:string?,mode:register_mode) Function to map to <ESC> in the window. Default is `registers.close_window()`.
---@field ctrl_n fun()|false Function to map <C-N> to move down in the registers window. Default is `registers.move_cursor_down()`.
---@field ctrl_p fun()|false Function to map <C-P> to move up in the registers window. Default is `registers.move_cursor_up()`.
---@field ctrl_j fun()|false Function to map <C-J> to move down in the registers window. Default is `registers.move_cursor_down()`.
---@field ctrl_k fun()|false Function to map <C-K> to move up in the registers window. Default is `registers.move_cursor_up()`.
--
---`require("registers").setup({ events = {...} })`
---@class events_options
---@field on_register_highlighted fun()|false Function that's called when a new register is highlighted when the window is open. Default is `registers.preview_highlighted_register({ if_mode = { "insert", "paste" } })`.

---@alias window_border
---| '"none"'
---| '"single"'
---| '"double"'
---| '"rounded"'
---| '"solid"'
---| '"shadow"'
---| 'string[]' # An array of eight strings which each corner and side character.

---`require("registers").setup({ window = {...} })`
---@class window_options
---@field max_width number? Maximum width of the window, normal size will be calculated based on the size of the longest register. Default is `100`.
---@field highlight_cursorline boolean? Whether to create key mappings for the register values inside the window. Default is `true`.
---@field border window_border? Border style of the window. Default is `"none"`.
---@field transparency integer? Transparency of the window, value can be between 0-100, 0 disables it. Default is `10`.

---`require("registers").setup({ symbols = {...} })`
---@class symbols_options
---@field newline string? Symbol to show for a line break character, can not be the `"\\n"` symbol, use `"\\\\n"` (two backslashes) instead. Default is `"⏎"`.
---@field space string? Symbol to show for a space character. Default is `" "`.
---@field tab string? Symbol to show for a tab character. Default is `"·"`.
---@field register_type_charwise string? Symbol to show next to the sign to signify that the register will be applied in a character by character way. Default is `"ᶜ"`.
---@field register_type_linewise string? Symbol to show next to the sign to signify that the register will be applied in a line by line way. Default is `"ˡ"`.
---@field register_type_blockwise string? Symbol to show next to the sign to signify that the register will be applied as a horizontal block, ignoring line endings. Default is `"ᵇ"`.

---`require("registers").setup({ sign_highlights = {...} })`
---@class sign_highlights_options
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
---@return options options Default values for all options.
function registers.default_options()
    return {
        show = "*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
        show_empty = true,
        register_user_command = true,
        system_clipboard = true,
        trim_whitespace = true,
        hide_only_whitespace = true,
        show_register_types = true,

        bind_keys = {
            normal = registers.show_window({ mode = "motion" }),
            visual = registers.show_window({ mode = "motion" }),
            insert = registers.show_window({ mode = "insert" }),

            registers = registers.apply_register({ delay = 0.1 }),
            return_key = registers.apply_register(),
            escape = registers.close_window(),

            ctrl_n = registers.move_cursor_down(),
            ctrl_p = registers.move_cursor_up(),
            ctrl_j = registers.move_cursor_down(),
            ctrl_k = registers.move_cursor_up(),
        },

        events = {
            on_register_highlighted = registers.preview_highlighted_register({ if_mode = { "insert", "paste" } }),
        },

        symbols = {
            newline = "⏎",
            space = " ",
            tab = "·",
            register_type_charwise = "ᶜ",
            register_type_linewise = "ˡ",
            register_type_blockwise = "ᵇ",
        },

        window = {
            max_width = 100,
            highlight_cursorline = true,
            border = "none",
            transparency = 10,
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
        vim.api.nvim_create_user_command("Registers", registers.show_window({ mode = "paste" }), {})
    end

    -- Create a namespace for the highlights and signs
    registers._namespace = vim.api.nvim_create_namespace("registers")

    -- Pre-fill the key mappings
    registers._fill_mappings()

    -- Bind the keys if applicable
    registers._bind_global_key("normal", "\"", "n")
    registers._bind_global_key("visual", "\"", "v")
    registers._bind_global_key("insert", "<C-R>", "i")
end

---@mod callbacks Bindable functions

---`require("registers").show_window({...})`
---@class show_window_options
---@field delay number How long, in seconds, to wait before applying the function. Default is `0`.
---@field mode register_mode? How the registers window should handle the selection of registers. Default is `"motion"`.

---Popup the registers window.
---@param options show_window_options? Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
---@usage [[
----- Disable all key bindings
---require("registers").setup({ bind_keys = false })
---
----- Define a custom for opening the register window when pressing "r"
---vim.api.nvim_set_keymap("n", "r", "", {
---    -- The "paste" argument means that when a register is selected it will automatically be pasted
---    callback = require("registers").show_window({ mode = "paste" }),
---    -- This is required for the registers window to function
---    expr = true
---})
---@usage ]]
function registers.show_window(options)
    options = vim.tbl_deep_extend("keep", options or {}, {
        delay = 0,
        mode = "motion",
    })

    return function()
        -- Check whether a key is pressed in between waiting for the window to open
        local interrupted = vim.wait(options.delay * 1000, function()
            return vim.fn.getchar(true) ~= 0
        end, nil, false)

        -- Mode before opening the popup window
        registers._previous_mode = vim.api.nvim_get_mode().mode

        -- Open the window when another key hasn't been pressed in the meantime
        if not interrupted then
            -- Keep track of the count that's used to invoke the window so it can be applied again
            registers._operator_count = vim.api.nvim_get_vvar("count")

            -- Store the mode which defaults to motion
            registers._mode = options.mode

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
end

---`require("registers")...({...})`
---@class callback_options
---@field delay number How long, in seconds, to wait before applying the function. Default is `0`.
---@field after function? Callback function that can be chained after the current one.
---@field if_mode register_mode|[register_mode] Will only be triggered when the registers mode matches it. Default: `{ "paste", "insert", "motion" }`.

---Close the window.
---@param options callback_options? Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
---@usage [[
---require("registers").setup({
---    bind_keys = {
---        -- Don't apply the register when selecting with Enter but close the window
---        return_key = require("registers").close_window(),
---    }
---})
---@usage ]]
function registers.close_window(options)
    return registers._handle_callback_options(options, registers._close_window)
end

---`require("registers").apply_register({...})`
---@class apply_register_options
---@field mode register_mode? How the register should be applied. If `nil` then the mode in which the window is opened is used.
---@field keep_open_until_keypress boolean? If `true`, keep the window open until another key is pressed, only applicable when the mode is `"motion"`.

---Apply the specified register.
---@param options callback_options|apply_register_options? Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
---@usage [[
---require("registers").setup({
---    bind_keys = {
---        -- Always paste the register when selecting with Enter
---        return_key = require("registers").apply_register({ mode = "paste" }),
---    }
---})
---
---require("registers").setup({
---    bind_keys = {
---        -- When pressing a key of the register, wait for another key press before closing the window
---        registers = require("registers").apply_register({ keep_open_until_keypress = true }),
---    }
---})
---@usage ]]
function registers.apply_register(options)
    return registers._handle_callback_options(options--[[@as callback_options]] , function(register, mode)
        -- When the current line needs to be selected a window also needs to be open
        if register == nil and registers._window == nil then
            vim.api.nvim_err_writeln("registers window isn't open, can't apply register")
            return
        end

        -- Overwrite the mode
        if options and options.mode then
            registers._mode = options.mode --[[@as register_mode]]
        elseif mode then
            registers._mode = mode
        end

        registers._apply_register(register, options and options.keep_open_until_keypress)
    end)
end

---Move the cursor up in the window.
---@param options callback_options? Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
function registers.move_cursor_up(options)
    return registers._handle_callback_options(options, function()
        if registers._window == nil then
            vim.api.nvim_err_writeln("registers window isn't open, can't move cursor")
            return
        end

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Up>", true, true, true), "n", true)
    end)
end

---Move the cursor down in the window.
---@param options callback_options? Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
function registers.move_cursor_down(options)
    return registers._handle_callback_options(options, function()
        if registers._window == nil then
            vim.api.nvim_err_writeln("registers window isn't open, can't move cursor")
            return
        end

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Down>", true, true, true), "n", true)
    end)
end

---`require("registers").move_cursor_to_register({...})`
---@class move_cursor_to_register_options
---@field register string Which register to move the cursor to.

---Move the cursor to the specified register.
---@param options callback_options|move_cursor_to_register_options Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
function registers.move_cursor_to_register(options)
    if not options.register then
        error("a register must be passed to `registers.move_cursor_to_register`")
    end

    return registers._handle_callback_options(options--[[@as callback_options]] , function()
        registers._move_cursor_to_register(options.register--[[@as string]] )
    end)
end

---Show a preview of the highlighted register in the target buffer.
---@param options callback_options Options for firing the callback.
---@return function callback Function that can be used to pass to configuration options with callbacks.
function registers.preview_highlighted_register(options)
    return registers._handle_callback_options(options--[[@as callback_options]] , function()
        vim.api.nvim_err_writeln("bla")
    end)
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

    -- Keep track of the buffer from which the window is called
    registers._preview_buffer = vim.api.nvim_get_current_buf()

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
        callback = registers._close_window,
    })

    -- Make the buffer content cut-off instead of starting on new line
    vim.api.nvim_win_set_option(registers._window, "wrap", false)

    -- Show a column on the left for the register names
    vim.api.nvim_win_set_option(registers._window, "signcolumn",
        -- Add space for the extra symbol in the sign column depending on whether we should show the register types
        registers.options.show_register_types and "yes:2" or "yes")

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

    -- Weird workaround for when using a count, the window won't draw

    -- Put the window in normal mode when using a visual selection
    if registers._previous_mode_is_visual() then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "n", true)
    end
end

---Close the window.
---@private
function registers._close_window()
    if not registers._window then
        -- There's nothing to close
        return
    end

    vim.api.nvim_win_close(registers._window, true)
    registers._window = nil
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
            end

            if hide then
                -- Place it in the empty registers
                registers._empty_registers[#registers._empty_registers + 1] = register
            elseif line and type(line) == "string" then
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

                -- Convert the sign types
                if registers.options.show_register_types then
                    if register_info.regtype == 'v' then
                        register_info.type_symbol = registers.options.symbols.register_type_charwise
                    elseif register_info.regtype == 'V' then
                        register_info.type_symbol = registers.options.symbols.register_type_linewise
                    else
                        register_info.type_symbol = registers.options.symbols.register_type_blockwise
                    end
                end

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

    -- Create signs and highlights for the register itself
    for i = 1, #registers._register_values do
        local register = registers._register_values[i]

        local sign_text = register.register
        -- Add the register type symbol if applicable
        if registers.options.show_register_types then
            sign_text = sign_text .. register.type_symbol
        end

        -- Create signs for the register itself, and highlight the line
        vim.api.nvim_buf_set_extmark(registers._buffer, registers._namespace, i - 1, 0, {
            id = i,
            sign_text = sign_text,
            sign_hl_group = registers._highlight_for_sign(register.register),
            cursorline_hl_group = registers.options.sign_highlights.cursorline,
        })
    end

    -- Don't allow the buffer to be modified
    vim.api.nvim_buf_set_option(registers._buffer, "modifiable", false)
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
            local register_func = function()
                -- Always move the cursor to the selected line in case there's a delay, unfortunately there's no way to know if that's the case at this time so it's quite inefficient when there's no delay
                registers._move_cursor_to_register(register)


                -- Apply the mapping
                registers.options.bind_keys.registers(register, registers._mode)
            end

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

---Create a map for global key binding with a callback function.
---@param index string Key of the function in the `bind_keys` table.
---@param key string Which key to press.
---@param mode register_mode Which mode to register the key.
---@private
function registers._bind_global_key(index, key, mode)
    if registers._key_should_be_bound(index) then
        vim.api.nvim_set_keymap(mode, key, "", {
            callback = function()
                -- Don't open the registers window in a telescope prompt or in a non-modifiable buffer
                if not vim.bo.modifiable or vim.bo.filetype == "TelescopePrompt" then
                    return vim.api.nvim_replace_termcodes(key, true, true, true)
                else
                    -- Call the callback function passed to the options
                    return registers.options.bind_keys[index]()
                end
            end,
            expr = true
        })
    end
end

---Apply the register and close the window.
---@param register string? Which register to apply or the current line.
---@param keep_open_until_keypress boolean? Keep the window open until a key is pressed.
---@private
function registers._apply_register(register, keep_open_until_keypress)
    -- Get the register symbol also when selecting it manually
    register = registers._register_symbol(register)

    -- Do nothing if no valid register is chosen
    if not register then
        return
    end

    local key_to_press_at_the_end
    if registers._mode == "paste" then
        -- "Press" the 'p' key at the end so the selected register gets pasted
        key_to_press_at_the_end = "p"
    elseif keep_open_until_keypress and registers._mode == "motion" then
        -- Handle the special case when the window needs to be open until a key is pressed
        key_to_press_at_the_end = vim.fn.getcharstr()
    end

    -- Close the window
    registers._close_window()

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
    elseif registers._previous_mode == "n" or registers._previous_mode_is_visual() then
        -- Simulate the keypresses require to perform the next actions
        vim.schedule(function()
            local keys = ""

            -- Go to previous visual selection if applicable
            if registers._previous_mode_is_visual() then
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

            -- Handle the key that might needs to be pressed
            if key_to_press_at_the_end then
                keys = keys .. key_to_press_at_the_end
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

---Move the cursor to the specified register.
---@param register string The register to move to, if it can't be found nothing is done.
---@private
function registers._move_cursor_to_register(register)
    if registers._window == nil then
        vim.api.nvim_err_writeln("registers window isn't open, can't move cursor")
        return
    end

    -- Find the matching register so we know where to put the cursor
    for i = 1, #registers._register_values do
        local register_info = registers._register_values[i]
        if register_info.register == register then
            -- Move the cursor
            vim.api.nvim_win_set_cursor(registers._window, { i, 0 })

            -- Redraw the line so it gets highlighted
            vim.api.nvim_command("silent! redraw")

            return
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

---Handle the calling of the callback function based on the options, so things like delays can be added.
---@param options callback_options? Options to apply to the callback function.
---@param cb function Callback function to trigger.
---@return function callback Wrapped callback function applying the options.
---@nodiscard
---@private
function registers._handle_callback_options(options, cb)
    -- Process the table arguments
    local delay = (options and options.delay) or 0
    local if_mode = (options and options.if_mode) or { "paste", "insert", "motion" }
    -- Ensure it's always a table
    if type(if_mode) ~= "table" then
        if_mode = { if_mode }
    end
    local after = (options and options.after) or function() end

    -- Create the callback that's called with all checks and events
    local full_cb = function()
        -- Do nothing if we are not in the proper mode
        if not vim.tbl_contains(if_mode, registers._mode) then
            return
        end

        -- Call the original callback
        cb()

        -- If we need to call a function after the callback also call that
        after()
    end

    if delay == 0 then
        -- Return the callback so it can be immediately called without any defer
        return full_cb
    else
        return function()
            -- Sleep for delay before calling the function
            vim.defer_fn(full_cb, delay * 1000)
        end
    end
end

---Whether the previous mode is any of the visual selections.
---@return boolean is_visual Whether the previous mode is a visual selection.
---@private
function registers._previous_mode_is_visual()
    return registers._previous_mode == 'v'
        or registers._previous_mode == '^V'
        or registers._previous_mode == 'V'
        or registers._previous_mode == '\22'
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
