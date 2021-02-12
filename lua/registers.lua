local register_map = {
	{
		type = "unnamed",
		registers = {"\""},
	},
	{
		type = "numbered",
		registers = {"0", "1", "2", "3", "4", "5", "7", "8", "9"},
	},
	{
		type = "delete",
		registers = {"-"},
	},
	{
		type = "named",
		registers = {
			"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
			"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		},
	},
	{
		type = "read-only",
		registers = {":", ".", "%"},
	},
	{
		type = "alternate buffer",
		registers = {"#"},
	},
	{
		type = "expression",
		registers = {"="},
	},
	{
		type = "selection",
		registers = {"*", "+"},
	},
	{
		type = "black hole",
		registers = {"_"},
	},
	{
		type = "last search pattern",
		registers = {"/"},
	},
}

local buf, win, register_lines

-- Get the contents of the register
local function register_contents(register_name)
	return vim.api.nvim_exec(("echo getreg(%q)"):format(register_name), true)
end

-- Build a map of all the lines
local function read_registers()
	register_lines = {}

	-- Loop through all the types
	for _, reg_type in ipairs(register_map) do
		-- Loop through the separate registers of the type
		for _, reg in ipairs(reg_type.registers) do
			-- The contents of a register
			local contents = register_contents(reg)

			-- Skip empty registers
			if #contents > 0 then
				-- Display the whitespace of the line as whitespace
				contents = contents:gsub("\t", "\\t")
				-- Newlines have to be replaced
				:gsub("[\n\r]", "⏎")

				-- Get the line with all the information
				local line = string.format("%s: %s", reg, contents)

				-- Truncate the line
				register_lines[#register_lines + 1] = {
					register = reg,
					line = line,
				}
			end
		end
	end
end

-- Spawn a popup window
local function open_window()
	-- Read all the registers
	read_registers()

	-- Create empty buffer
	buf = vim.api.nvim_create_buf(false, true)

	-- Remove the buffer when the window is closed
	vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

	-- Get dimensions
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- Calculate the floating window size
	local win_height = math.min(#register_lines, math.ceil(height * 0.8 - 4))
	local win_width = math.ceil(width * 0.8)

	-- Set some options
	local opts = {
		style = "minimal",
		relative = "cursor",
		width = win_width,
		height = win_height,
		-- Position it next to the cursor
		row = 1,
		col = 0
	}

	-- Finally create it with buffer attached
	win = vim.api.nvim_open_win(buf, true, opts)

	-- Highlight the cursor line
	vim.api.nvim_win_set_option(win, "cursorline", true)
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

	-- Add the highlights
	for i = 1, #register_lines do
		vim.api.nvim_buf_add_highlight(buf, -1, "RegistersRegisterChar", i - 1, 0, 1)
		vim.api.nvim_buf_add_highlight(buf, -1, "RegistersString", i - 1, 3, -1)
	end

	-- Don't allow the buffer to be modified
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Close the window
local function close_window()
	vim.api.nvim_win_close(win, true)
end

-- Apply a register
local function apply_register(register)
	local sleep = true

	local line

	-- Try to find the line of the register
	if not register then
		-- If no register is passed use the currently selected line

		-- Get the currently selected line
		line = unpack(vim.api.nvim_win_get_cursor(win))

		-- Don't sleep when we select it
		if line <= #register_lines then
			sleep = false
		end
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
	if line then
		-- Move the cursor
		vim.api.nvim_win_set_cursor(win, {line, 0})

		-- Redraw so the line get's highlighted
		vim.api.nvim_exec("silent! redraw", true)

		if sleep then
			-- Wait for some time before closing the window
			vim.api.nvim_exec(("silent! sleep %d"):format(1), true)
		end
	end

	-- Close the window
	close_window()

	-- Apply the register
	vim.api.nvim_exec(("norm! \"%sP"):format(register), true)
end

-- Set the buffer keyboard mapping for the window
local function set_mappings()
	local mappings = {
		-- Apply the currently selected register
		["<CR>"] = "apply_register()",
		["<ESC>"] = "close_window()",
	}

	-- Create a mapping for all the registers
	for _, reg_type in ipairs(register_map) do
		for _, reg in ipairs(reg_type.registers) do
			mappings[reg] = ("apply_register(%q)"):format(reg)
		end
	end

	-- Map all the keys
	local map_options = {
		nowait = true,
		noremap = true,
		silent = true,
	}
	for key, func in pairs(mappings) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, (":lua require\"registers\".%s<cr>"):format(func), map_options)
	end
end

-- Spawn the window
local function registers()
	open_window()
	set_mappings()
	update_view()
end

-- Public functions
return {
	registers = registers,
	apply_register = apply_register,
	close_window = close_window,
}
