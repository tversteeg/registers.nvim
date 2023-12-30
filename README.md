# registers.nvim

Show register content when you try to access it in Neovim. Written in Lua.

> [!WARNING]
> This plugin is not maintained actively by me anymore. Any pull requests will still be reviewed and merged but I'm not fixing any bugs or adding features myself. If someone is interested in taking over maintainership please contact me!

Requires Neovim 0.7.0+.

## Summary

This plugin adds an interactive and visually pleasing UI for *selecting* what register item to paste or use next. It offers basic syntax highlighting, a preview, and an equally (if not more) efficient experience using Neovim registers. One simply uses <kbd>"</kbd> or <kbd>Ctrl</kbd><kbd>R</kbd> as one would normally, and then enjoys the benefit of seeing the contents of all filled registers *without having to use the `:reg` command beforehand*. It essentially removes an annoying step in using Neovim registers (checking where a specific item is, which register you might have used earlier, etc.), and lets you increase your efficiency while also increasing Neovim’s aesthetic.

## Features

- Non-obtrusive, won't influence your workflow
- Minimal interface, no visual noise
- Configurable, there's a setting for almost all aspects of this plugin

## Use

The pop-up window showing the registers and their values can be opened in one of the following ways:

- Call `:Registers`
- Press <kbd>"</kbd> in _normal_ or _visual_ mode
- Press <kbd>Ctrl</kbd><kbd>R</kbd> in _insert_ mode

![preview](.github/img/preview.png?raw=true)

Empty registers are not shown by default.

### Navigate

Use the <kbd>Up</kbd> and <kbd>Down</kbd> or <kbd>Ctrl</kbd><kbd>P</kbd> and <kbd>Ctrl</kbd><kbd>N</kbd> or <kbd>Ctrl</kbd><kbd>J</kbd> and <kbd>Ctrl</kbd><kbd>K</kbd> keys to select the register you want to use and press <kbd>Enter</kbd> to apply it, or type the register you want to apply, which is one of the following:

<kbd>"</kbd> <kbd>0</kbd>–<kbd>9</kbd> <kbd>a</kbd>–<kbd>z</kbd> <kbd>:</kbd> <kbd>.</kbd> <kbd>%</kbd> <kbd>#</kbd> <kbd>=</kbd> <kbd>\*</kbd> <kbd>+</kbd> <kbd>\_</kbd> <kbd>/</kbd>

## Example Workflow

### With `registers.nvim`:

- Copy item to system clipboard or Neovim register (this can also be achieved using `registers.nvim`);
- In normal mode, type the <kbd>"</kbd> key. The `registers.nvim` pop-up will appear.
- You can now use the arrow keys (or other navigation keys) to move to a specific item (representing an item in the Neovim register, i.e., what you see with `:reg`) in the list being displayed. Pressing enter on this item will ‘select’ it.
- Alternatively, you can just type the highlighted character being displayed in the left margin of the pop-up, next to the register item you want to select. This resembles a workflow without `registers.nvim`, except that you get the visual feedback and confirmation of what is inside the register beforehand. It is also useful for remembering which register you placed something in ;) .
    + I.e., type <kbd>"</kbd><kbd>+</kbd> to select from the system clipboard, **or** use the arrow keys to navigate to <kbd>+</kbd> and hit enter)
- Once you have selected a register item, you can proceed to perform your desired action (e.g., yank, paste, etc.). To do this, simply use the usual keys: <kbd>y</kbd>, <kbd>p</kbd>, etc.

One can also call the `registers.nvim` pop-up through other means, not just <kbd>"</kbd>. For example, in insert mode, one can use <kbd>Ctrl</kbd><kbd>R</kbd> (this is default vim behaviour). If one does not want to use these key-binds (or bind your own keys), one can use the `:Registers` command.

### Without `registers.nvim`:

- Copy item to system clipboard or vim register;
- Use the `:reg` command to view registers. Make sure to remember the `Name` of the register item you want to use for future reference.
- In normal mode, type <kbd>"</kbd>. You will get no visual feedback.
- Now type the `Name` of the register item you want to select, as listed in the output of `:reg`.
- Now perform the desired action (usually either yanking, <kbd>y</kbd>, or pasting, <kbd>p</kbd>)

### Using `registers.nvim` is definitely more aesthetically pleasing and probably makes registers easier for beginners to understand—but is it actually better for experienced Neovim users, too?

[Well, users say ;)](https://github.com/tversteeg/registers.nvim/issues/102#issuecomment-1870503908)…

> I definitely think so. I use registers (and tmux buffers) extensively, and remembering a register’s name that I arbitrarily chose half an hour ago is not always the easiest for me. This means that I usually end up typing <kbd>"</kbd>, then realizing that I don’t know what to type next, opening `:reg`, finding the register I want (usually a quite difficult task), *trying* to remember its name, typing <kbd>"</kbd> *again*, forgetting the register’s name *again*, going back to `:reg`, and finally: typing <kbd>"</kbd><kbd>\<register name\></kbd>. This costs an excessive amount of time. `registers.nvim` has solved this problem for me because it previews the contents of a register, removing the need to remember arbitrary register names. In other words, I love the plugin :)

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

### Lazy.nvim

This configuration lazy-loads the plugin only when it’s invoked.

```lua
{
	"tversteeg/registers.nvim",
	cmd = "Registers",
	config = true,
	keys = {
		{ "\"",    mode = { "n", "v" } },
		{ "<C-R>", mode = "i" }
	},
	name = "registers",
}
```

## Configuration

This plugin can be configured by passing a table to `require("registers").setup({})`.
Configuration options can be found in Neovim’s documentation after installing with: [`:h registers`](doc/registers.txt).

### Default Values

```lua
use {
    "tversteeg/registers.nvim",
    config = function()
        local registers = require("registers")
        registers.setup({
```

<!-- MARKDOWN-AUTO-DOCS:START (CODE:src=./lua/registers.lua&lines=140-227) -->
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
            normal    = registers.show_window({ mode = "motion" }),
            -- Show the window when pressing " in visual mode, applying the selected register as part of a motion, which is the default behavior of Neovim
            visual    = registers.show_window({ mode = "motion" }),
            -- Show the window when pressing <C-R> in insert mode, inserting the selected register, which is the default behavior of Neovim
            insert    = registers.show_window({ mode = "insert" }),

            -- When pressing the key of a register, apply it with a very small delay, which will also highlight the selected register
            registers = registers.apply_register({ delay = 0.1 }),
            -- Immediately apply the selected register line when pressing the return key
            ["<CR>"]  = registers.apply_register(),
            -- Close the registers window when pressing the Esc key
            ["<Esc>"] = registers.close_window(),

            -- Move the cursor in the registers window down when pressing <C-n>
            ["<C-n>"] = registers.move_cursor_down(),
            -- Move the cursor in the registers window up when pressing <C-p>
            ["<C-p>"] = registers.move_cursor_up(),
            -- Move the cursor in the registers window down when pressing <C-j>
            ["<C-j>"] = registers.move_cursor_down(),
            -- Move the cursor in the registers window up when pressing <C-k>
            ["<C-k>"] = registers.move_cursor_up(),
            -- Clear the register of the highlighted line when pressing <DeL>
            ["<Del>"] = registers.clear_highlighted_register(),
            -- Clear the register of the highlighted line when pressing <BS>
            ["<BS>"]  = registers.clear_highlighted_register(),
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
            cursorlinesign = "CursorLine",
            signcolumn = "SignColumn",
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
<!-- The below code snippet is automatically added from ./lua/registers.lua -->
<!-- MARKDOWN-AUTO-DOCS:END -->

```lua
        })
    end,
}
```
