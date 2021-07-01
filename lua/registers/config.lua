-- Get the global variable
-- For neovim 0.4.4 compatibility
local function global_var_or(var_name, default)
	-- Wrap it in a pcall because it will throw an error when it's not found
	local ok, var = pcall(function()
		return vim.api.nvim_get_var(var_name)
	end)

	-- Return the var if found or the default value if not
	return ok and var or default
end

-- Return a function that will populate the config
return function()
	return {
		tab_symbol = global_var_or("registers_tab_symbol", "·"),
		space_symbol = global_var_or("registers_space_symbol", " "),
		return_symbol = global_var_or("registers_return_symbol", "⏎"),
		register_key_sleep = global_var_or("registers_register_key_sleep", 0),
		show_empty_registers = global_var_or("registers_show_empty_registers", 1),
		trim_whitespace = global_var_or("registers_trim_whitespace", 0),
		window_border = global_var_or("registers_window_border", "none"),
	}
end
