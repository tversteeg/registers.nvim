local config = require "registers.config"

-- All available registers
local ALL_REGISTERS = { "*", "+", "\"", "-", "/", "_", "=", "#", "%", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }

local buf, win, register_lines, invocation_mode, operator_count, cursor_is_last

-- Convert a 0 to false and a 1 to true
local function toboolean(val)
	if val == 0 then
		return false
	else
		return true
	end
end

-- Get the contents of the register
local function register_contents(register_name)
	return vim.api.nvim_call_function("getreg", {register_name, 1})
end

-- Build a map of all the lines
local function read_registers()
	-- Get the configuration
	local cfg = config()

	-- Keep track of all the registers without any content
	local empty_registers = {}

	-- Reset the filled data
	register_lines = {}

	-- Loop through all the registers to show
	for i = 1, #cfg.show do
        -- Get the register character
        local reg = cfg.show:sub(i, i)

        -- The contents of a register
        local raw = register_contents(reg)

        -- Skip empty registers
        local is_empty = #raw > 0

        -- Mark the register as empty if there's only whitespace
        if is_empty and cfg.hide_only_whitespace == 1 then
            is_empty = #(raw:match("^%s*(.-)%s*$")) > 0
        end

        if is_empty then
            if cfg.trim_whitespace == 1 then
                -- Trim the whitespace at the start and end
                raw = raw:match("^%s*(.-)%s*$")
            end

            -- Display the whitespace of the line as whitespace
            local contents = raw:gsub("\t", cfg.tab_symbol)
                -- Replace spaces
                :gsub(" ", cfg.space_symbol)
                -- Replace newlines
                :gsub("[\n\r]", cfg.return_symbol)

            -- Get the line with all the information
            local line = string.format("%s: %s", reg, contents)

            register_lines[#register_lines + 1] = {
                register = reg,
                line = line,
                data = raw,
            }
        elseif cfg.show_empty_registers == 1 then
            -- Keep track of the empty registers
            empty_registers[#empty_registers + 1] = reg
        end
	end

	-- Add another line with the empty registers if the option is set
	if #empty_registers > 0 then
		local line = "Empty:"
		for _, reg in ipairs(empty_registers) do
			line = ("%s %s"):format(line, reg)
		end

		register_lines[#register_lines + 1] = {
			line = line,
			ignore = true,
		}
	end
end

-- Spawn a popup window
local function open_window()
	-- Read all the registers
	read_registers()

	-- Create empty buffer
	buf = vim.api.nvim_create_buf(false, true)

	-- Remove the buffer when the window is closed
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	-- Highlight special characters
	vim.api.nvim_buf_set_option(buf, "filetype", "registers")
	-- Disable automatic completion throwing an error in coc.nvim
	vim.api.nvim_buf_set_option(buf, "omnifunc", "")

	-- Get dimensions
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- Get the relative cursor line
	local win_line = vim.api.nvim_call_function("winline", {})

	-- Calculate the floating window size
	local win_height = math.min(#register_lines,
		-- If the whole buffer doesn't fit, use the size from the current line to the height
		math.min(height - win_line, math.ceil(height * 0.8 - 4)))
	-- Cap the window width to a maximum size
	local win_width = math.min(width, config().window_max_width)

	-- Set window at cursor position, unless the cursor is too close the bottom of the window
	-- Too close is what the user set as scrolloff
	local user_scrolloff = vim.api.nvim_get_option('scrolloff');

	-- When the user picks a high number they want to center the mouse, which will stretch the
	-- window (#20), so we pick an arbitrary number for that
	if user_scrolloff >= 30 then
		user_scrolloff = 0
	end

	local opts_row = 1
	if win_height < user_scrolloff then
		win_height = user_scrolloff
		opts_row = win_line - user_scrolloff
	end

	-- Set a minimum window height when the configuration is set
	local min_height = config().window_min_height
	if win_height < min_height then
		win_height = min_height
		opts_row = win_line - min_height
	end

	-- Set some options
	local opts = {
		style = "minimal",
		-- When in command mode use the whole editor for the relative position
		-- Otherwise make the window relative to the cursor
		relative = invocation_mode == "c" and "editor" or "cursor",
		width = win_width,
		height = win_height,
		-- Position it next to the cursor
		row = opts_row,
		col = 0,
	}
   	if vim.api.nvim_call_function("has", {"nvim-0.5"}) == 1 then
   		opts.border = config().window_border
   	end

	-- Finally create it with buffer attached
	win = vim.api.nvim_open_win(buf, true, opts)

	-- Register an autocommand to close window if focus is lost
	vim.api.nvim_command([[augroup registers_focus_lost]])
	vim.api.nvim_command([[autocmd! registers_focus_lost BufLeave <buffer> lua require('registers').close_window()]])
	vim.api.nvim_command([[augroup END]])

	-- Highlight the cursor line
	vim.api.nvim_win_set_option(win, "cursorline", true)
	-- Allow configuration of colors
	vim.api.nvim_win_set_option(win, "winhighlight", "NormalFloat:RegistersWindow")
end

-- Update the popup window
local function update_view()
	-- Get the width of the window to truncate the strings
	local max_width = vim.api.nvim_win_get_width(win) - 2

	-- Create a array of lines from all the registers
	local lines = {}
	for i = 1, #register_lines do
		local line = register_lines[i].line

		-- Truncate the line to the width of the window
		lines[i] = line:sub(1, max_width)
	end

	-- Write the lines to the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Don't allow the buffer to be modified
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Close the window
local function close_window()
	-- Do nothing when there's no window
	if not win then
		return
	end

	vim.api.nvim_win_close(win, true)
	win = nil
end

-- Apply a register
local function apply_register(register)
	local sleep = true

    -- Keep track of how we select the register
    local register_selected_with_return = register == nil

	-- Try to find the line of the register
	local line
	if not register then
		-- If no register is passed use the currently selected line

		-- Get the currently selected line
		line = unpack(vim.api.nvim_win_get_cursor(win))

		-- Don't sleep when we select it
		sleep = false

		-- Find the line matching the cursor
		local register_line = register_lines[line]

		-- If a non-register line is selected just close the window and do nothing
		if register_line.ignore then
			-- Close the window
			close_window()

			return
		end

		-- Set the register from the line selected
		register = register_line.register
	else
		-- Find the matching register line and get the line number
		for i, register_line in ipairs(register_lines) do
			if register_line.register == register then
				line = i
				break
			end
		end
	end

	-- Move the cursor to the register selected if applicable
	if sleep and line and config().register_key_sleep then
		-- Move the cursor
		vim.api.nvim_win_set_cursor(win, {line, 0})

		-- Redraw so the line get's highlighted
		vim.api.nvim_command("silent! redraw")

		-- Wait for some time before closing the window
		vim.api.nvim_command(("silent! sleep %d"):format(config().register_key_sleep))
	end

	-- Close the window
	close_window()

	-- Handle insert mode differently
	if invocation_mode == "i" then
		-- Get the proper keycode for <C-R>
		local key = vim.api.nvim_replace_termcodes("<c-r>", true, true, true)

		if register == "=" then
			-- Apply <c-r>= again in input mode so the user can enter their query
			vim.api.nvim_feedkeys(key .. "=", "n", true)
		else
			-- Capture the contents of the "=" register so it can be reset later
			local old_expr_content = register_contents("=", 1)

			local submit = vim.api.nvim_replace_termcodes("<CR>", true, true, true)
			-- Let execute the selected register content using `=` register and insert the result
			vim.api.nvim_feedkeys(key .. "=@" .. register .. submit, "n", true)

			-- Recover the "=" register
			-- This only works in neovim >= 0.5
			-- TODO: support 0.4
			if vim.api.nvim_call_function("has", {"nvim-0.5"}) == 1 then
				vim.defer_fn(function()
					vim.api.nvim_call_function("setreg", {"=", old_expr_content})
				end, 100)
			end
		end
	else
        local paste_in_normal_mode = config().paste_in_normal_mode
        local should_paste_in_normal_mode = paste_in_normal_mode == 1 or (paste_in_normal_mode == 2 and register_selected_with_return)

		-- Define the keys pressed based on the mode
		local keys
		if invocation_mode == "n" and not should_paste_in_normal_mode then
			-- When the popup is opened with the " key in normal mode
			if operator_count > 0 then
				-- Allow 10".. using the stored operator count
				keys = operator_count .. "\"" .. register
			else
				-- Don't prepend the count if it's not set, because that will
				-- influence the behavior of the operator following
				keys = "\"" .. register
			end
		elseif invocation_mode == "v" then
			-- When the popup is opened with the " key in visual mode
			-- Reset the visual selection
			keys = "gv\"" .. register
		else
			-- When the popup is opened without any mode passed, i.e. directly from the
			-- function call, or if "registers_paste_in_normal_mode" is set, automatically paste it
			keys = "\"" .. register .. "p"
		end

		-- Get the current mode in the window
		local current_mode = vim.api.nvim_get_mode().mode

		-- "Press" the key with the register key and paste it if applicable
		vim.api.nvim_feedkeys(keys, current_mode, true)
	end
end

-- Set the buffer keyboard mapping for the window
local function set_mappings()
	local mappings = {
		-- Apply the currently selected register
		["<CR>"] = "apply_register()",
		["<ESC>"] = "close_window()",
	}

	-- Create a mapping for all the registers
    for _, reg in ipairs(ALL_REGISTERS) do
        mappings[reg] = ("apply_register(%q)"):format(reg)

        -- Also map upper case characters if applicable
        local reg_upper_case = reg:upper()
        if reg_upper_case ~= reg then
            mappings[reg_upper_case] = ("apply_register(%q)"):format(reg_upper_case)
        end
    end

	-- Map all the keys
	local map_options = {
		nowait = true,
		noremap = true,
		silent = true,
	}
	for key, func in pairs(mappings) do
		local call = ("<cmd>lua require\"registers\".%s<cr>"):format(func)
		-- Map to both normal mode and insert mode for <C-R>
		vim.api.nvim_buf_set_keymap(buf, "n", key, call, map_options)
		vim.api.nvim_buf_set_keymap(buf, "i", key, call, map_options)
		vim.api.nvim_buf_set_keymap(buf, "v", key, call, map_options)
	end

	-- Map <c-k> & <c-j> for moving up and down
	vim.api.nvim_buf_set_keymap(buf, "n", "<c-k>", "<up>", map_options)
	vim.api.nvim_buf_set_keymap(buf, "i", "<c-k>", "<up>", map_options)
	vim.api.nvim_buf_set_keymap(buf, "n", "<c-j>", "<down>", map_options)
	vim.api.nvim_buf_set_keymap(buf, "i", "<c-j>", "<down>", map_options)

	-- Map <c-p> & <c-n> for moving up and down
	vim.api.nvim_buf_set_keymap(buf, "n", "<c-p>", "<up>", map_options)
	vim.api.nvim_buf_set_keymap(buf, "i", "<c-p>", "<up>", map_options)
	vim.api.nvim_buf_set_keymap(buf, "n", "<c-n>", "<down>", map_options)
	vim.api.nvim_buf_set_keymap(buf, "i", "<c-n>", "<down>", map_options)
end

-- Invoke the timer for creating a window
local function registers(mode)
	-- Keep track of the count that's used to invoke the window so it can be applied again
	operator_count = vim.api.nvim_get_vvar("count")
	-- Keep track of the mode that's used to open the popup
	invocation_mode = mode

    -- Close the old window if it's still open
    close_window()

    -- Check if the current buffer is modifiable, otherwise don't open it
    local current_buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_option(current_buf, "modifiable") then
        open_window()
        set_mappings()
        update_view()
    end
end

-- Public functions
return {
	registers = registers,
	apply_register = apply_register,
	open_window = open_window,
	close_window = close_window,
}
