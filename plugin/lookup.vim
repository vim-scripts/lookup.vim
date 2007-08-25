" lookup.vim - :Lookup the word in a dictionary
" Author: Swaroop C H <swaroop@swaroopchNOSPAM.com>
" Version: 1
" SaluteTo: WordWebOnline.com

if &cp || (exists("g:loaded_lookup") && g:loaded_lookup)
    finish
endif
if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif
let g:loaded_lookup = 1

function! s:DefPython()
python << PYTHONEOF

import vim
import re
from urllib2 import urlopen
from BeautifulSoup import BeautifulSoup

def striptags(text):
    return re.sub(r'<[^>]*>', r'', str(text))

def unhtmlify(text):
    text = text.replace('&nbsp;', ' ')
    text = text.replace('&quot;', ' "')
    return text

def safequotes(string):
    return string.replace('"', '')

def lookup(word):
    output = ''

    try:
        webpage = urlopen('http://www.wordwebonline.com/en/' + word.upper()).read()
        page = BeautifulSoup(webpage)

        head = page.find('span', {'class':'head'})
        output += "%s" % head.contents[0]

        key = page.find('span', {'class':'key'})
        output += "%s\n" % key.contents[0]

        pron = page.find('span', {'class':'pron'})
        output += "Pronounciation: %s\n" % pron.contents[0]

        meanings = pron.nextSibling.findAll('li')

        for index, meaning in enumerate(meanings):
            output += '%s. %s\n' % (index+1, unhtmlify(striptags(meaning)))

    except Exception, e:
        # output += "%s\n" % e
        # output += r'''Looking for word "%s"\n''' % word
        output += "Sorry, can't help you"

    vim.command('silent let g:lookup_meaning = "%s"' % safequotes(output))

PYTHONEOF
endfunction

call s:DefPython()

function! Lookup()

    let word = expand("<cword>")
    execute "python lookup('" . word . "')"
    echohl WarningMsg
    echo g:lookup_meaning
    echohl None

endfunction

command Lookup call Lookup()

