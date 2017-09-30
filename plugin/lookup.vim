" lookup.vim - :Lookup the word in a dictionary
" Author: Swaroop C H <swaroop@swaroopchNOSPAM.com>
" Author: Robin Schneider <ypid@riseup.net>
" Version: 2
" Uses: Dict protocol (http://www.dict.org)
" Uses: dict://vocabulary.aioe.org server

if &cp || (exists("g:loaded_lookup") && g:loaded_lookup)
    finish
endif
let g:loaded_lookup = 1

let s:python_defs_file = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/lookup.py'

if !exists("g:lookup_databases")
    let g:lookup_databases = []
endif

if !exists("g:lookup_dict_args")
    let g:lookup_dict_args = []
endif

function! s:isPythonInstalled()

    if has("python3") && executable('python3')
        let g:_lookup_python = "python3 "
        let g:_lookup_python_file = "py3file "
    elseif has("python") && executable('python')
        let g:_lookup_python = "python "
        let g:_lookup_python_file = "pyfile "
    endif
    if exists('g:_lookup_python')
        return 1
    else
        echohl WarningMsg
        echom  "lookup.vim requires Vim compiled with +python or +python3 and Python being installed."
        echohl None

        return 0
    endif

endfunction

function! s:DefPython()

    if !s:isPythonInstalled()
        return
    endif

    exec g:_lookup_python_file s:python_defs_file

endfunction

call s:DefPython()

function Lookup(word)
    if !s:isPythonInstalled()
        return
    endif

    let g:lookup_meaning = ''
    exec g:_lookup_python "set_translation_to_vim_var('g:lookup_meaning', '" . a:word . "')"
    echo g:lookup_meaning

    "" Not using that because of unstable Vim pager mode which behaves like
    "" `more` and not the better `less`.
    " exec g:_lookup_python "print(get_translation('" . a:word . "'))"

endfunction

function LookupVisual()
    sil! norm! gv"ty
    let g:lookup_word = @t
    call Lookup(g:lookup_word)
endfunction

function LookupReg()
    let g:lookup_word = @0
    call Lookup(g:lookup_word)
endfunction

function LookupCurWord()
    " let g:lookup_word = expand("<cword>")
    " call Lookup(g:lookup_word)
    call Lookup(expand("<cword>"))
endfunction

command Lookup call LookupCurWord()
command LookupVisual call LookupVisual()
" vmap <Leader>tv :call LookupVisual()<CR>
command LookupReg call LookupReg()
