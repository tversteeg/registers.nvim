# registers.nvim

Show register content when you try to access it in NeoVim. Written in Lua.

Requires NeoVim 0.5+.

## Installation

### Packer

```lua
use "tversteeg/registers.nvim"
```

## Use

Press <kbd>"</kbd> in normal mode or <kbd>Ctrl</kbd><kbd>R</kbd> in insert mode to show a popup window with the registers and their values.
Empty registers are not shown by default.

![insert](docs/insert.png?raw=true)
![normal](docs/normal.png?raw=true)

### Navigate

Use the <kbd>Up</kbd> and <kbd>Down</kbd> keys to select the register you want to use and press <kbd>Enter</kbd> to apply it, or type the register you want to apply, which is one of the following:

<kbd>"</kbd> <kbd>0</kbd>-<kbd>9</kbd> <kbd>a</kbd>-<kbd>z</kbd> <kbd>:</kbd> <kbd>.</kbd> <kbd>%</kbd> <kbd>#</kbd> <kbd>=</kbd> <kbd>*</kbd> <kbd>+</kbd> <kbd>_</kbd> <kbd>/</kbd> 
