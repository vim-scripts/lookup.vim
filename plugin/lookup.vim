" lookup.vim - :Lookup the word in a dictionary
" Author: Swaroop C H <swaroop@swaroopchNOSPAM.com>
" Version: 2
" Uses: Dict protocol (http://www.dict.org)
" Uses: dict://vocabulary.aioe.org server

if &cp || (exists("g:loaded_lookup") && g:loaded_lookup)
    finish
endif
let g:loaded_lookup = 1

if !exists("g:lookup_databases")
    let g:lookup_databases = []
endif

if !exists("g:lookup_dict_para")
    let g:lookup_dict_para = []
endif

function! s:isPythonInstalled()
    if !has('python3')
        echoerr "lookup.vim requires vim compiled with +python3"
    endif

    return has('python3')
endfunction

function! s:DefPython()

    if !s:isPythonInstalled()
        return
    endif

python3 << PYTHONEOF

import vim
import subprocess as sp

not_in_db = []
failed = []
success = []
output = ''

def resetVariable():
    global not_in_db, failed, success, output
    failed = []
    not_in_db = []
    success = []
    output = ''

def safequotes(string):
    return string.replace('"', "'")

def safequotes(string):
    return string.replace('"', "'")

def run_dict(para, db=None):
    user_para = vim.eval('g:lookup_dict_para')
    global not_in_db, failed, success, output
    try:
        dict_out = sp.check_output(['dict'] + para + user_para,
                stderr=sp.STDOUT, shell=False).decode('utf-8')
    except sp.CalledProcessError as pe:
        if (pe.returncode == 20) and db: not_in_db.append(db)
        else: failed.append(pe.returncode)
        return 0
    output += dict_out + '\n'
    if db: success.append(db)
    return 1

def lookup(word):
    global output
    resetVariable()
    db = vim.eval('g:lookup_databases')
    if db:
        for dbname in db:
            if run_dict(['--database', dbname, word], db=dbname):
                output += '\n'
    else:
        run_dict([word])

    newline = '\n' if success else ''
    if not_in_db and db:
        output = "%d database%s had no entry for \'%s\': %s%s%s" % (len(not_in_db),
            '' if len(not_in_db) == 1 else 's', word,
            ', '.join(str(i) for i in not_in_db), newline, output)
    elif failed:
        output = "dict command failed with returncode: %s\n%s" % (failed, output)
    if success and db:
        output = "%d database%s entries for \'%s\': %s\n%s" % (len(success),
            'has' if len(success) == 1 else 's have', word,
            ', '.join(str(i) for i in success), output)

    vim.command('silent let g:lookup_meaning = "%s"' % safequotes(output))

PYTHONEOF
endfunction

call s:DefPython()

function Lookup(word)
    if !s:isPythonInstalled()
        return
    endif

    execute "python3 lookup('" . a:word . "')"
    echo g:lookup_meaning
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
