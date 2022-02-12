# registers.nvim

Show register content when you try to access it in Neovim. Written in Lua.

Requires Neovim 0.4.4+.

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

## Configuration

### `return_symbol`

Symbol shown for newline characters.

#### Default

`"⏎"`

#### Example

```vim
let g:registers_return_symbol = "\n"
```

### `tab_symbol`

Symbol shown for tab characters.

#### Default

`"·"`

#### Example

```vim
let g:registers_tab_symbol = "\t"
```

### `space_symbol`

Symbol shown for space characters.

#### Default

`" "`

#### Example

```vim
let g:registers_space_symbol = "."
```

### `delay`

Milliseconds to wait before opening the popup window.

#### Default

`0`

#### Example

```vim
let g:registers_delay = 500
```

### `register_key_sleep`

Seconds to wait before closing the window when a register key is pressed.

#### Default

`0`

#### Example

```vim
let g:registers_register_key_sleep = 1
```

### `show_empty_registers`

An additional line with the registers without content.

#### Default

`1`

#### Example

```vim
let g:registers_show_empty_registers = 0
```

### `trim_whitespace`

Don't show whitespace at the begin and end of the registers.

#### Default

`1`

#### Example

```vim
let g:registers_trim_whitespace = 0
```

### `hide_only_whitespace`

Don't show registers filled exclusively with whitespace.

#### Default

`0`

#### Example

```vim
let g:registers_hide_only_whitespace = 1
```

### `window_border`

Requires Neovim 0.5.0+.

Can be `"none"`, `"single"`, `"double"`, `"rounded"`, `"solid"`, or `"shadow"`.

#### Default

`"none"`

#### Example

```vim
let g:registers_window_border = "single"
```

### `window_min_height`

Minimum height of the window when there is the cursor at the bottom.

#### Default

`3`

#### Example

```vim
let g:registers_window_min_height = 10
```

### `window_max_width`

Maximum width of the window.

#### Default

`100`

#### Example

```vim
let g:registers_window_max_width = 20
```

### `normal_mode`

Open the window in normal mode.

#### Default

`1`

#### Example

```vim
let g:registers_normal_mode = 0
```

### `paste_in_normal_mode`

Automatically perform a paste action when selecting a register through any means in normal mode.

#### Default

`0`

#### Options

- `0` - Default Neovim behavior.
- `1` - Paste when selecting a register with the register key and <kbd>Return</kbd>.
- `2` - Paste when selecting a register only with <kbd>Return</kbd>.

#### Example

```vim
let g:registers_paste_in_normal_mode = 1
```

### `visual_mode`

Open the window in visual mode.

#### Default

`1`

#### Example

```vim
let g:registers_visual_mode = 0
```

### `insert_mode`

Open the window in insert mode.

#### Default

`1`

#### Example

```vim
let g:registers_insert_mode = 0
```

### `show`

Which registers to show and in what order.

#### Default

`"*+\"-/_=#%.0123456789abcdefghijklmnopqrstuvwxyz:"`

#### Example

```vim
let g:registers_show = "*+\""
```
