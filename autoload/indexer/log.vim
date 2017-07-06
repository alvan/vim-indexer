" -- {{{
"
"          File:  log.vim
"        Author:  Alvan
"         Usage:  Indexer log
"   Description:  module that provides logging.
"
" -- }}}
if exists('s:name') | fini | en

let s:name = 'log'
let s:acts = ['']
let s:logs = []

func! indexer#{s:name}#initial()
    call indexer#declare('g:indexer_logs_maxsize', 100)
    call indexer#add_log('Init module: ' . s:name)
endf

func! indexer#{s:name}#startup()
endf

func! indexer#{s:name}#context(cxt)
    if index(s:acts, a:cxt.act) < 0
        call indexer#add_log(printf('Miss Action "%s" in module %s', a:cxt.act, s:name))
        return
    en

    return a:cxt
endf

func! indexer#{s:name}#add_log(...)
    call extend(s:logs, [[localtime(), a:000]])
    if exists('g:indexer_logs_maxsize') && len(s:logs) > g:indexer_logs_maxsize
        call remove(s:logs, 0)
    en
endf

"
" Actions
"
func! indexer#{s:name}#_(cxt)
    let l:sum = len(s:logs)
    if l:sum > 0
        let l:ftm = exists("*strftime")
        let l:len = strlen(string(l:sum))
        let l:num = 0
        while l:num < l:sum
            let l:num += 1

            let l:idx = l:sum - l:num
            let l:log = s:logs[l:idx]

            echon "\n"
            echon printf('%0' . l:len . 'd', l:idx) '. '
            echon '[' . (l:ftm ? strftime('%c', get(l:log, 0)) : l:idx) . ']'
            for l:val in get(l:log, 1, [])
                echon ' ' l:val
            endfor
        endw
    en
    echon "\n"
endf

"
" Initial
"
call indexer#{s:name}#initial()