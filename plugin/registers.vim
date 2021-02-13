" Maintainer:   Thomas Versteeg <thomas@versteeg.email>
" License:      GNU General Public License v3.0

" Prevent loading file twice
if exists('g:registers_loaded') | finish | endif

" Save user coptions
let s:save_cpo = &cpo
" Reset them to defaults
set cpo&vim

" Set the theme variables
hi def link RegistersRegisterChar Number
hi def link RegistersString String

" Command to run our plugin
command! Registers lua require'registers'.registers()

" Open the popup window when pressing <C-R> in insert mode
inoremap <silent> <C-R> <C-O><cmd>lua require'registers'.registers("insert")<CR>

" Open the popup window when pressing " in regular mode
noremap <silent> " <cmd>lua require'registers'.registers("normal")<CR>

" Restore after
let &cpo = s:save_cpo
unlet s:save_cpo

let g:registers_loaded = 1
