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

func! indexer#{s:name}#initial()
    call indexer#declare('g:indexer_tags_watches', ['*.c', '*.h', '*.c++', '*.php', '*.py'])
    call indexer#declare('g:indexer_tags_command', indexer#{s:name}#command())
    call indexer#declare('g:indexer_tags_options', '-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=vim,c,c++,php,python')
    call indexer#declare('g:indexer_tags_savedir', '~/.vim_indexer_tags/')
endf

func! indexer#{s:name}#startup()
    call indexer#add_log('Load module: ' . s:name)

    exec 'au BufEnter * call indexer#' . s:name . '#trigger(["attach"], expand("<afile>:p"))'
    if has('job')
        exec 'au BufReadPost * call indexer#' . s:name . '#trigger(["update", "-1"], expand("<afile>:p"))'
    en
endf

func! indexer#{s:name}#context(cxt)
    if !has_key(a:cxt, 'fil')
        let a:cxt.fil = expand('%:p')
    en

    let a:cxt.prj = indexer#project(a:cxt.fil)
    if empty(a:cxt.prj)
        return
    en

    if !has_key(a:cxt, 'etc')
        let a:cxt.etc = {}
    en

    let a:cxt.etc.tags_watches = get(a:cxt.prj.etc, 'tags_watches', g:indexer_tags_watches)
    let a:cxt.etc.tags_command = get(a:cxt.prj.etc, 'tags_command', g:indexer_tags_command)
    let a:cxt.etc.tags_options = get(a:cxt.prj.etc, 'tags_options', g:indexer_tags_options)
    let a:cxt.etc.tags_savedir = fnamemodify(get(a:cxt.prj.etc, 'tags_savedir', g:indexer_tags_savedir), ':p')

    return a:cxt
endf

func! indexer#{s:name}#prepare(req)
    return indexer#{s:name}#context({})
endf

func! indexer#{s:name}#trigger(fun, fil)
    let l:cxt = indexer#{s:name}#context({'fil': a:fil})
    if !empty(l:cxt) && !empty(l:cxt.etc.tags_watches) && !empty(a:fun)
        for l:pat in l:cxt.etc.tags_watches
            if a:fil =~ glob2regpat(l:pat)
                call indexer#execute(call('indexer#request', [s:name] + a:fun), l:cxt)
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
func! indexer#{s:name}#_(req) dict
    echon &tags
endf

func! indexer#{s:name}#_attach(req) dict
    let l:out = self.etc.tags_savedir . indexer#{s:name}#uniform(self.prj.dir)
    if index(tagfiles(), l:out) < 0
        call indexer#add_log('Link tags: ' . l:out)
        exec "setl tags+=" . substitute(l:out, ' ', '\\\\\\ ', 'g')
    en
endf

func! indexer#{s:name}#_update(req) dict
    if self.etc.tags_command == ''
        call indexer#add_log('Tags command not found!')
        return
    en

    if !isdirectory(self.etc.tags_savedir)
        if exists("*mkdir")
            call mkdir(self.etc.tags_savedir, 'p')
        en
    en

    let self.tmp = tempname()
    let self.out = self.etc.tags_savedir . indexer#{s:name}#uniform(self.prj.dir)
    let self.cmd = printf('%s %s -f %s %s', self.etc.tags_command, self.etc.tags_options, self.tmp, self.prj.dir)

    let l:job = {}
    let l:job.cxt = self
    let l:job.cmd = self.cmd
    let l:job.key = indexer#{s:name}#job_key(a:req.act, self.out)
    let l:job.ecb = 'indexer#' . s:name . '#did_tag'
    let l:job.sta = str2nr(get(a:req.etc.args, 2, '0'))

    call indexer#add_log('Make tags: ' . self.out)
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
