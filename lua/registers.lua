local api = vim.api
local buf, win

local function get_register_string(register_name)
	local register_string = vim.api.nvim_exec(string.format("echo getreg(%q)", register_name), true)

	return ("Register %s: %q"):format(register_name, register_string)
end

local function open_window()
	-- Create empty buffer
	buf = api.nvim_create_buf(false, true)

	api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

	-- Get dimensions
	local width = api.nvim_get_option("columns")
	local height = api.nvim_get_option("lines")

	-- Calculate our floating window size
	local win_height = math.ceil(height * 0.8 - 4)
	local win_width = math.ceil(width * 0.8)

	-- Its starting position
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	-- Set some options
	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col
	}

	-- Finally create it with buffer attached
	win = api.nvim_open_win(buf, true, opts)
end

local function update_view()
	local result = {}

	result[1] = get_register_string("a")
	result[2] = get_register_string("*")

	api.nvim_buf_set_lines(buf, 0, -1, false, result)
end

local function close_window()
	api.nvim_win_close(win, true)
end

local function registers()
	open_window()
	update_view()
end

return {
	registers = registers,
	update_view = update_view,
	close_window = close_window
}
