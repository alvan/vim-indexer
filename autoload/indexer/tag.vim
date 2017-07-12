" -- {{{
"
"          File:  tag.vim
"        Author:  Alvan
"         Usage:  Indexer tag [attach|update]
"   Description:  module that provides painless transparent tags generation.
"
" -- }}}
if exists('s:name') | fini | en

let s:name = 'tag'
let s:acts = ['', 'attach', 'update']

func! indexer#{s:name}#actions()
    return s:acts
endf

func! indexer#{s:name}#initial()
    call indexer#add_log('Init module: ' . s:name)

    call indexer#declare('g:indexer_tags_savedir', '~/.vim_indexer_tags/')
    call indexer#declare('g:indexer_ctag_refresh', 0)
    call indexer#declare('g:indexer_ctag_watches', ['*.c', '*.h', '*.c++', '*.php', '*.py'])
    call indexer#declare('g:indexer_ctag_command', indexer#{s:name}#command())
    call indexer#declare('g:indexer_ctag_options', '-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=vim,c,c++,php,python')
endf

func! indexer#{s:name}#startup()
    if has('job')
        exec 'au BufReadPost,BufWritePost * call indexer#' . s:name . '#refresh(expand("<afile>:p"))'
    en
endf

func! indexer#{s:name}#context(cxt)
    if index(s:acts, a:cxt.act) < 0
        call indexer#add_log(printf('Miss Action "%s" in module %s', a:cxt.act, s:name))
        return
    en

    let l:prj = indexer#project(expand('%:p'))
    if empty(l:prj)
        return
    en

    let a:cxt.prj = l:prj
    let a:cxt.etc.tags_uniform = indexer#{s:name}#uniform(a:cxt.prj.dir)

    let a:cxt.etc.tags_savedir = fnamemodify(get(a:cxt.prj.etc, 'tags_savedir', g:indexer_tags_savedir), ':p')
    let a:cxt.etc.ctag_refresh = get(a:cxt.prj.etc, 'ctag_refresh', g:indexer_ctag_refresh)
    let a:cxt.etc.ctag_watches = get(a:cxt.prj.etc, 'ctag_watches', g:indexer_ctag_watches)
    let a:cxt.etc.ctag_command = get(a:cxt.prj.etc, 'ctag_command', g:indexer_ctag_command)
    let a:cxt.etc.ctag_options = get(a:cxt.prj.etc, 'ctag_options', g:indexer_ctag_options)

    return a:cxt
endf

func! indexer#{s:name}#refresh(fil)
    let l:cxt = indexer#{s:name}#context(indexer#context(s:name, 'update', '0'))
    if !empty(l:cxt) && !empty(l:cxt.etc.ctag_watches)
        for l:pth in l:cxt.etc.ctag_watches
            if a:fil =~ glob2regpat(l:pth)
                let l:cxt.etc.args[2] = string(l:cxt.etc.ctag_refresh - 1)
                call indexer#execute(l:cxt)
                return
            en
        endfor
    en
endf

func! indexer#{s:name}#command()
    let l:bin = ''
    if executable('exuberant-ctags')
        " On Debian Linux
        let l:bin = 'exuberant-ctags'
    elseif executable('exctags')
        " On Free-BSD
        let l:bin = 'exctags'
    elseif executable('ctags')
        let l:bin = 'ctags'
    elseif executable('ctags.exe')
        let l:bin = 'ctags.exe'
    elseif executable('tags')
        let l:bin = 'tags'
    en

    return l:bin
endf

func! indexer#{s:name}#uniform(pth)
    return substitute(a:pth, '[^a-zA-Z0-9_]', '_', 'g')
endf

func! indexer#{s:name}#job_key(act, key)
    return s:name . '#' . a:act . '(' . a:key . ')'
endf

func! indexer#{s:name}#did_tag(cxt)
    if a:cxt.out != a:cxt.tmp
        if filereadable(a:cxt.tmp)
            call rename(a:cxt.tmp, a:cxt.out)
        en
    en
endf

"
" Actions
"
func! indexer#{s:name}#_(cxt)
    echon &tags
endf

func! indexer#{s:name}#_attach(cxt)
    let l:out = get(a:cxt, 'out', a:cxt.etc.tags_savedir . a:cxt.etc.tags_uniform)
    call indexer#add_log('Link tags: ' . l:out)
    exec "set tags+=" . substitute(l:out, ' ', '\\\\\\ ', 'g')
endf

func! indexer#{s:name}#_update(cxt)
    if a:cxt.etc.ctag_command == ''
        call indexer#add_log('Tags command not found!')
        return
    en

    if !isdirectory(a:cxt.etc.tags_savedir)
        if exists("*mkdir")
            call mkdir(a:cxt.etc.tags_savedir, 'p')
        en
    en

    let a:cxt.tmp = tempname()
    let a:cxt.out = a:cxt.etc.tags_savedir . a:cxt.etc.tags_uniform
    let a:cxt.cmd = printf('%s %s -f %s %s', a:cxt.etc.ctag_command, a:cxt.etc.ctag_options, a:cxt.tmp, a:cxt.prj.dir)

    let l:job = {}
    let l:job.cxt = a:cxt
    let l:job.key = indexer#{s:name}#job_key(a:cxt.act, a:cxt.etc.tags_uniform)
    let l:job.ecb = 'indexer#' . s:name . '#did_tag'
    let l:job.sta = str2nr(get(a:cxt.etc.args, 2, '0'))

    call indexer#{s:name}#_attach(a:cxt)
    call indexer#add_log('Make tags: ' . a:cxt.out)

    if has('job') && indexer#has_mod('job')
        call function('indexer#job#run_job', l:job)()
    el
        call system(l:job.cxt.cmd)
        call {l:job.ecb}(l:job.cxt)
    en
endf

"
" Initial
"
call indexer#{s:name}#initial()
