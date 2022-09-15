# registers.nvim

Show register content when you try to access it in Neovim. Written in Lua.

Requires Neovim 0.7.0+.

## Features

- Non-obtrusive, won't influence you're workflow
- Minimal interface, no visual noise

## Use

The popup window showing the registers and their values can be opened in one of the following ways:

- Call `:Registers`
- Press <kbd>"</kbd> in _normal_ or _visual_ mode

![normal](docs/normal.png?raw=true)

- Press <kbd>Ctrl</kbd><kbd>R</kbd> in _insert_ mode

![insert](docs/insert.png?raw=true)

Empty registers are not shown by default.

### Navigate

Use the <kbd>Up</kbd> and <kbd>Down</kbd> or <kbd>Ctrl</kbd><kbd>P</kbd> and <kbd>Ctrl</kbd><kbd>N</kbd> or <kbd>Ctrl</kbd><kbd>J</kbd> and <kbd>Ctrl</kbd><kbd>K</kbd> keys to select the register you want to use and press <kbd>Enter</kbd> to apply it, or type the register you want to apply, which is one of the following:

<kbd>"</kbd> <kbd>0</kbd>-<kbd>9</kbd> <kbd>a</kbd>-<kbd>z</kbd> <kbd>:</kbd> <kbd>.</kbd> <kbd>%</kbd> <kbd>#</kbd> <kbd>=</kbd> <kbd>\*</kbd> <kbd>+</kbd> <kbd>\_</kbd> <kbd>/</kbd>

## Install

### Packer

```lua
use {
	"tversteeg/registers.nvim",
	config = function()
		require("registers").setup()
	end,
}
```

## Configuration

This plugin can be configured by passing a table to `require("registers").setup({})`.
Configuration options can be found in Neovim's documentation after installing with: [`:h registers`](doc/registers.txt).

### Default values

<!-- MARKDOWN-AUTO-DOCS:START (CODE:src=./lua/registers.lua&lines=102-149) -->
<!-- The below code snippet is automatically added from ./lua/registers.lua -->

```lua
{
    show = "*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
    show_empty = true,
    register_user_command = true,
    system_clipboard = true,
    trim_whitespace = true,
    paste_in_normal_mode = false,
    delay = 0,

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

    symbols = {
        newline = "⏎",
        space = " ",
        tab = "·",
    },

    window = {
        max_width = 100,
        highlight_cursorline = true,
        border = "none",
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
```

<!-- MARKDOWN-AUTO-DOCS:END -->
