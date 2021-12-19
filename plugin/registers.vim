" Maintainer:   Thomas Versteeg <thomas@versteeg.email>
" License:      GNU General Public License v3.0

" Prevent loading file twice
if exists('g:registers_loaded') | finish | endif

" Save user coptions
let s:save_cpo = &cpo
" Reset them to defaults
set cpo&vim

" Get the configuration
let g:registers_visual_mode = get(g:, 'registers_visual_mode', 1)
let g:registers_normal_mode = get(g:, 'registers_normal_mode', 1)
let g:registers_insert_mode = get(g:, 'registers_insert_mode', 1)

" Plugin calls to open the register window
nnoremap <silent> <Plug>(registers) :<c-u>lua require'registers'.registers('n')<cr>
xnoremap <silent> <Plug>(registers) :<c-u>lua require'registers'.registers('v')<cr>
inoremap <silent> <Plug>(registers) <c-\><c-o>:<c-u>lua require'registers'.registers('i')<cr>

" Custom :Registers command
command! Registers lua require'registers'.registers()

" Returns true if timed out
" From: https://github.com/junegunn/vim-peekaboo/blob/master/autoload/peekaboo.vim#L37
function! s:wait_with_timeout(timeout)
	let timeout = a:timeout
	while timeout >= 0
		if getchar(1)
			return 0
		endif

		if timeout > 0
			sleep 20m
		endif

		let timeout -= 20
	endwhile

	return 1
endfunction

" Peek function inspired by junegunn's peekaboo
function! registers#peek(mode)
	" First check if we should open the window, if not just return the mode key
	let timeout = get(g:, 'registers_delay', 0)
	if !s:wait_with_timeout(timeout)
		return a:mode
	endif

	" Call the registers function when no key is pressed in the mean time
	return "\<Plug>(registers)"
endfunction

augroup Registers
	au!

	if g:registers_insert_mode
		" Open the popup window when pressing <C-R> in insert mode
		au BufEnter * imap <buffer> <expr> <C-R> registers#peek('<C-R>')
	endif

	if g:registers_normal_mode
		" Open the popup window when pressing " in regular mode
		au BufEnter * nmap <buffer> <expr> " registers#peek('"')
	endif

	if g:registers_visual_mode
		" Open the popup window when pressing " in visual mode
		au BufEnter * xmap <buffer> <expr> " registers#peek('"')
	endif
augroup END

" Ensure the mapping is set, because sometimes the BufEnter doesn't trigger
if g:registers_insert_mode | imap <buffer> <expr> <C-R> registers#peek('<C-R>') | endif
if g:registers_normal_mode | nmap <buffer> <expr> " registers#peek('"') | endif
if g:registers_visual_mode | xmap <buffer> <expr> " registers#peek('"') | endif

" Restore after
let &cpo = s:save_cpo
unlet s:save_cpo

let g:registers_loaded = 1
