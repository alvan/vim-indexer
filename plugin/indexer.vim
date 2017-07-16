" -- {{{
"
"          File:  indexer.vim
"        Author:  Alvan
"   Description:  Indexer project for VIM.
"
" -- }}}

" Exit if already loaded
if exists("g:plugin_indexer") | fini | el | let g:plugin_indexer = "0.7.9" | en

func! s:Indexer(...)
    call indexer#process(call('indexer#request', a:000))
endf

" Use :Indexer to call functions manually.
com! -nargs=* -complete=custom,indexer#express Indexer call s:Indexer(<f-args>)
call indexer#startup()
