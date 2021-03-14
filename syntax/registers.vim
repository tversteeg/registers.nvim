" Prevent loading file twice
if exists("b:registers_syntax_loaded") | finish | endif

" The left part of the buffer
syntax match RegistersPrefixSelection "[*+]" contained
syntax match RegistersPrefixDefault "\"" contained
syntax match RegistersPrefixUnnamed "\\" contained
syntax match RegistersPrefixReadOnly "[:.%]" contained
syntax match RegistersPrefixLastSearch "\/" contained
syntax match RegistersPrefixDelete "-" contained
syntax keyword RegistersPrefixYank 0 contained
syntax keyword RegistersPrefixHistory 1 2 3 4 5 6 7 8 9 contained
syntax match RegistersPrefixNamed "[a-z]" contained

syntax match RegistersPrefix "^." contains=RegistersPrefix.* nextgroup=RegistersSeparator
syntax match RegistersSeparator ": " contained nextgroup=RegistersContentRegion

" The empty line content
syntax region RegistersEmptyLine matchgroup=RegistersSeparator start="^Empty: " end="$" contains=RegistersPrefix.*

" The clipboard content
syntax match RegistersContentNumber "\d\+" contained
syntax match RegistersContentNumber "[-+]\d\+\.\d\+" contained
syntax match RegistersContentEscaped "^\w" contained
syntax keyword RegistersContentEscaped \. contained
syntax match RegistersContentString "\"[^\"]*\"" contained
syntax match RegistersContentString "'[^']*'" contained
syntax match RegistersContentWhitespace " " contained
syntax keyword RegistersContentWhitespace ␉ · ⎵ \n \t ⏎ contained

syntax match RegistersContentRegion ".*" contains=RegistersContent.* contained

" Set the theme variables
hi def link RegistersSeparator Comment
hi def link RegistersPrefixYank Delimiter
hi def link RegistersPrefixHistory Number
hi def link RegistersPrefixSelection Constant
hi def link RegistersPrefixDefault Function
hi def link RegistersPrefixUnnamed Statement
hi def link RegistersPrefixReadOnly Type
hi def link RegistersPrefixLastSearch Tag
hi def link RegistersPrefixNamed Todo
hi def link RegistersPrefixDelete Special

hi def link RegistersContentNumber Number
hi def link RegistersContentEscaped Special
hi def link RegistersContentWhitespace Comment
hi def link RegistersContentString String

let b:registers_syntax_loaded = 1
