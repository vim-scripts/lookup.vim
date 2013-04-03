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
    if !has('python')
        echoerr "lookup.vim requires vim compiled with +python"
    endif

    return has('python')
endfunction

function! s:DefPython()

    if !s:isPythonInstalled()
        return
    endif

python << PYTHONEOF

import vim
import subprocess as sp

not_in_db = []
failed = []
success = 0
output = ''

def resetVariable():
    global not_in_db, failed, success, output
    failed = []
    not_in_db = []
    success = 0
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
                stderr=sp.STDOUT, shell=False)
    except sp.CalledProcessError as pe:
        if (pe.returncode == 20) and db: not_in_db.append(db)
        else: failed.append(pe.returncode)
        return 0
    output += dict_out + '\n'
    success += 1
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

    vim.command('silent let g:lookup_meaning = "%s"' % safequotes(output))

PYTHONEOF
endfunction

call s:DefPython()

function! Lookup()

    if !s:isPythonInstalled()
        return
    endif

    let word = expand("<cword>")
    execute "python lookup('" . word . "')"
    echo g:lookup_meaning

endfunction

command Lookup call Lookup()
