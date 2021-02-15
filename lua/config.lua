-- Return a function that will populate the config
return function()
	return {
		tab_symbol = vim.g.registers_tab_symbol or "\\t",
		return_symbol = vim.g.registers_return_symbol or "⏎",
		register_key_sleep = vim.g.registers_register_key_sleep or 1,
	}
end
