" Prevent loading file twice
if exists("b:registers_syntax_loaded") | finish | endif

" The left part of the buffer
syntax match RegistersPrefixSeparator ".:" contained

syntax keyword RegistersPrefixSelection * + contained
syntax keyword RegistersPrefixDefault " contained
syntax keyword RegistersPrefixUnnamed \ contained
syntax keyword RegistersPrefixReadOnly : . % contained
syntax keyword RegistersPrefixLastSearch / contained
syntax keyword RegistersPrefixEmpty Empty contained
syntax keyword RegistersPrefixYank 0 contained
syntax keyword RegistersPrefixHistory 1 2 3 4 5 6 7 8 9 contained
syntax match RegistersPrefixNamed "[a-z]" contained

" The empty line content
syntax region RegistersPrefixRegion start="^" end=" " oneline contains=RegistersPrefix.* nextgroup=RegistersContentRegion
syntax region RegistersEmptyLine start="^Empty: " end="$" transparent contains=RegistersPrefix.*

" The clipboard content
syntax match RegistersContentNumber "\d\+" contained
syntax match RegistersContentNumber "[-+]\d\+\.\d\+" contained
syntax match RegistersContentEscaped "^\w" contained
syntax keyword RegistersContentEscaped \. contained
syntax match RegistersContentString "\"[^\"]*\"" contained
syntax match RegistersContentString "'[^']*'" contained
syntax match RegistersContentWhitespace " " contained
syntax keyword RegistersContentWhitespace ␉ · ⎵ \n \t ⏎ contained

syntax region RegistersContentRegion start=" " end="$" oneline contains=RegistersContent.*

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
hi def link RegistersPrefixEmpty Comment

hi def link RegistersContentNumber Number
hi def link RegistersContentEscaped Special
hi def link RegistersContentWhitespace Comment
hi def link RegistersContentString String

let b:registers_syntax_loaded = 1
