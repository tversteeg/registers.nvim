-- Return a function that will populate the config
return function()
	return {
		tab_symbol = vim.g.registers_tab_symbol or "·",
		space_symbol = vim.g.registers_space_symbol or " ",
		return_symbol = vim.g.registers_return_symbol or "⏎",
		register_key_sleep = vim.g.registers_register_key_sleep or 0,
	}
end
