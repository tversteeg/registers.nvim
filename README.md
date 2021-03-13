# registers.nvim

Show register content when you try to access it in NeoVim. Written in Lua.

Requires NeoVim 0.5+.

## Features

- No configuration required, automatically maps to <kbd>"</kbd> and <kbd>Ctrl</kbd><kbd>R</kbd>
- Non-obtrusive, won't influence you're workflow
- Minimal interface, no visual noise

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
Plug 'tversteeg/registers.nvim'
```

### Dein

```vim
call dein#add('tversteeg/registers.nvim')
```

## Use

Open the window with `:Registers` or press <kbd>"</kbd> in normal mode or <kbd>Ctrl</kbd><kbd>R</kbd> in insert mode to show a popup window with the registers and their values.
Empty registers are not shown by default.

![insert](docs/insert.png?raw=true)
![normal](docs/normal.png?raw=true)

### Navigate

Use the <kbd>Up</kbd> and <kbd>Down</kbd> keys to select the register you want to use and press <kbd>Enter</kbd> to apply it, or type the register you want to apply, which is one of the following:

<kbd>"</kbd> <kbd>0</kbd>-<kbd>9</kbd> <kbd>a</kbd>-<kbd>z</kbd> <kbd>:</kbd> <kbd>.</kbd> <kbd>%</kbd> <kbd>#</kbd> <kbd>=</kbd> <kbd>*</kbd> <kbd>+</kbd> <kbd>_</kbd> <kbd>/</kbd> 

## Setup

```vim
let g:registers_return_symbol = "\n" "'⏎' by default
let g:registers_tab_symbol = "\t" "'·' by default
let g:registers_space_symbol = "." "' ' by default
let g:registers_register_key_sleep = 1 "0 by default, seconds to wait before closing the window when a register key is pressed
let g:registers_show_empty_registers = 0 "1 by default, an additional line with the registers without content
```
