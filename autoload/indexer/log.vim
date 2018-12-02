" -- {{{
"
"          File:  log.vim
"        Author:  Alvan
"         Usage:  Indexer log
"   Description:  module that provides logging.
"
" -- }}}
if exists('s:name') | fini | el | let s:name = 'log' | en

func! indexer#{s:name}#initial()
    call indexer#declare('g:indexer_logs_maxsize', 100)
endf

func! indexer#{s:name}#startup()
    let l:logs = indexer#logging()
    func! l:logs.log(...) dict
        call add(self.logs, [localtime(), a:000])
        if exists('g:indexer_logs_maxsize') && len(self.logs) > g:indexer_logs_maxsize
            call remove(self.logs, 0)
        en
    endf
    unl l:logs

    call indexer#logging().log('Load module: ' . s:name)
endf

func! indexer#{s:name}#resolve(req)
    return {}
endf

"
" Actions
"
func! indexer#{s:name}#_(req) dict
    let l:lst = indexer#logging().logs
    let l:len = len(l:lst)
    if l:len > 0
        let l:ftm = exists("*strftime")
        let l:pad = strlen(string(l:len))
        let l:num = 0
        while l:num < l:len
            let l:num += 1

            let l:idx = l:len - l:num
            let l:log = l:lst[l:idx]

            echon "\n"
            echon printf('%0' . l:pad . 'd', l:idx + 1) '. '
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
