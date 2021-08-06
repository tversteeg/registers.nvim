# registers.nvim

Show register content when you try to access it in NeoVim. Written in Lua.

Requires NeoVim 0.4.4+.

## Features

- No configuration required, automatically maps to <kbd>"</kbd> and <kbd>Ctrl</kbd><kbd>R</kbd>
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

<kbd>"</kbd> <kbd>0</kbd>-<kbd>9</kbd> <kbd>a</kbd>-<kbd>z</kbd> <kbd>:</kbd> <kbd>.</kbd> <kbd>%</kbd> <kbd>#</kbd> <kbd>=</kbd> <kbd>*</kbd> <kbd>+</kbd> <kbd>_</kbd> <kbd>/</kbd>

## Install

### Packer

```lua
use "tversteeg/registers.nvim"
```

### Paq

```lua
paq "tversteeg/registers.nvim"
```

### Plug

```vim
Plug 'tversteeg/registers.nvim', { 'branch': 'main' }
```

### Dein

```vim
call dein#add('tversteeg/registers.nvim')
```

## Setup

```vim
let g:registers_return_symbol = "\n" "'⏎' by default
let g:registers_tab_symbol = "\t" "'·' by default
let g:registers_space_symbol = "." "' ' by default
let g:registers_delay = 500 "0 by default, milliseconds to wait before opening the popup window
let g:registers_register_key_sleep = 1 "0 by default, seconds to wait before closing the window when a register key is pressed
let g:registers_show_empty_registers = 0 "1 by default, an additional line with the registers without content
let g:registers_trim_whitespace = 0 "1 by default, don't show whitespace at the begin and end of the registers
let g:registers_hide_only_whitespace = 1 "0 by default, don't show registers filled exclusively with whitespace
let g:registers_window_border = "single" "'none' by default, can be 'none', 'single','double', 'rounded', 'solid', or 'shadow' (requires Neovim 0.5.0+)
let g:registers_window_min_height = 10 "3 by default, minimum height of the window when there is the cursor at the bottom
let g:registers_window_max_width = 20 "100 by default, maximum width of the window
```
