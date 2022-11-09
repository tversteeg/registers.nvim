# registers.nvim

Show register content when you try to access it in Neovim. Written in Lua.

Requires Neovim 0.7.0+.

## Features

- Non-obtrusive, won't influence your workflow
- Minimal interface, no visual noise
- Configurable, there's a setting for almost all aspects of this plugin

## Use

The popup window showing the registers and their values can be opened in one of the following ways:

- Call `:Registers`
- Press <kbd>"</kbd> in _normal_ or _visual_ mode
- Press <kbd>Ctrl</kbd><kbd>R</kbd> in _insert_ mode

![preview](.github/img/preview.png?raw=true)

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

### Default Values

```lua
use {
    "tversteeg/registers.nvim",
    config = function()
        local registers = require("registers")
        registers.setup({
```

<!-- MARKDOWN-AUTO-DOCS:START (CODE:src=./lua/registers.lua&lines=139-229) -->
<!-- The below code snippet is automatically added from ./lua/registers.lua -->
```lua
        -- Show these registers in the order of the string
        show = "*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:",
        -- Show a line at the bottom with registers that aren't filled
        show_empty = true,
        -- Expose the :Registers user command
        register_user_command = true,
        -- Always transfer all selected registers to the system clipboard
        system_clipboard = true,
        -- Don't show whitespace at the begin and end of the register's content
        trim_whitespace = true,
        -- Don't show registers which are exclusively filled with whitespace
        hide_only_whitespace = true,
        -- Show a character next to the register name indicating how the register will be applied
        show_register_types = true,

        bind_keys = {
            -- Show the window when pressing " in normal mode, applying the selected register as part of a motion, which is the default behavior of Neovim
            normal = registers.show_window({ mode = "motion" }),
            -- Show the window when pressing " in visual mode, applying the selected register as part of a motion, which is the default behavior of Neovim
            visual = registers.show_window({ mode = "motion" }),
            -- Show the window when pressing <C-R> in insert mode, inserting the selected register, which is the default behavior of Neovim
            insert = registers.show_window({ mode = "insert" }),

            -- When pressing the key of a register, apply it with a very small delay, which will also highlight the selected register
            registers = registers.apply_register({ delay = 0.1 }),
            -- Immediately apply the selected register line when pressing the return key
            return_key = registers.apply_register(),
            -- Close the registers window when pressing the Esc key
            escape = registers.close_window(),

            -- Move the cursor in the registers window down when pressing <C-N>
            ctrl_n = registers.move_cursor_down(),
            -- Move the cursor in the registers window up when pressing <C-P>
            ctrl_p = registers.move_cursor_up(),
            -- Move the cursor in the registers window down when pressing <C-J>
            ctrl_j = registers.move_cursor_down(),
            -- Move the cursor in the registers window up when pressing <C-K>
            ctrl_k = registers.move_cursor_up(),
            -- Clear the register of the highlighted line when pressing <DEL>
            delete = registers.clear_highlighted_register(),
            -- Clear the register of the highlighted line when pressing <BS>
            backspace = registers.clear_highlighted_register(),
        },

        events = {
            -- When a register line is highlighted, show a preview in the main buffer with how the register will be applied, but only if the register will be inserted or pasted
            on_register_highlighted = registers.preview_highlighted_register({ if_mode = { "insert", "paste" } }),
        },

        symbols = {
            -- Show a special character for line breaks
            newline = "⏎",
            -- Show space characters without changes
            space = " ",
            -- Show a special character for tabs
            tab = "·",
            -- The character to show when a register will be applied in a char-wise fashion
            register_type_charwise = "ᶜ",
            -- The character to show when a register will be applied in a line-wise fashion
            register_type_linewise = "ˡ",
            -- The character to show when a register will be applied in a block-wise fashion
            register_type_blockwise = "ᵇ",
        },

        window = {
            -- The window can't be wider than 100 characters
            max_width = 100,
            -- Show a small highlight in the sign column for the line the cursor is on
            highlight_cursorline = true,
            -- Don't draw a border around the registers window
            border = "none",
            -- Apply a tiny bit of transparency to the the window, letting some characters behind it bleed through
            transparency = 10,
        },

        -- Highlight the sign registers as regular Neovim highlights
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
```
<!-- MARKDOWN-AUTO-DOCS:END -->

```lua
        })
    end,
}
```
