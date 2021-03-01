" Prevent loading file twice
if exists("b:registers_syntax_loaded") | finish | endif

" The left part of the buffer
syntax match RegistersPrefixSeparator "^.:"
syntax match RegistersPrefixYank "^0" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixHistory "^[1-9]" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixSelection "^[*+]" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixDefault "^\"" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixUnnamed "^\\" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixReadOnly "^[:.%]" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixLastSearch "^/" contained containedin=RegistersPrefixSeparator
syntax match RegistersPrefixNamed "^[a-z]" contained containedin=RegistersPrefixSeparator

" The clipboard content
syntax region RegistersContent start=" " end="$"
syntax match RegistersContentNumber "\d\+" contained containedin=RegistersContent
syntax match RegistersContentNumber "[-+]\d\+\.\d\+" contained containedin=RegistersContent
syntax match RegistersContentEscaped "\\." contained containedin=RegistersContent
syntax match RegistersContentEscaped "^\w" contained containedin=RegistersContent
syntax match RegistersContentWhitespace "\\t" contained containedin=RegistersContent
syntax match RegistersContentWhitespace "␉" contained containedin=RegistersContent
syntax match RegistersContentWhitespace "·" contained containedin=RegistersContent
syntax match RegistersContentWhitespace " " contained containedin=RegistersContent
syntax match RegistersContentWhitespace "⎵" contained containedin=RegistersContent
syntax match RegistersContentWhitespace "\\n" contained containedin=RegistersContent
syntax match RegistersContentWhitespace "⏎" contained containedin=RegistersContent
syntax match RegistersContentString "\"[^\"]*\"" contained containedin=RegistersContent
syntax match RegistersContentString "'[^']*'" contained containedin=RegistersContent

" Set the theme variables
hi def link RegistersPrefixSeparator Comment
hi def link RegistersPrefixYank Delimiter
hi def link RegistersPrefixHistory Number
hi def link RegistersPrefixSelection Constant
hi def link RegistersPrefixDefault Function
hi def link RegistersPrefixUnnamed Statement
hi def link RegistersPrefixReadOnly Type
hi def link RegistersPrefixLastSearch Tag
hi def link RegistersPrefixNamed Todo

hi def link RegistersContentNumber Number
hi def link RegistersContentEscaped Special
hi def link RegistersContentWhitespace Comment
hi def link RegistersContentString String
let b:registers_syntax_loaded = 1
