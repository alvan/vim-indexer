" -- {{{
"
"          File:  tag.vim
"        Author:  Alvan
"         Usage:  Indexer tag [locate|onload|reload|update]
"   Description:  module that provides painless transparent tags generation.
"
" -- }}}
if exists('s:name') | fini | el | let s:name = 'tag' | en

let s:tags = {}
let s:tmps = {}

func! indexer#{s:name}#initial()
    call indexer#declare('g:indexer_tags_watches', ['*.c', '*.h', '*.c++', '*.cpp', '*.php', '*.py'])
    call indexer#declare('g:indexer_tags_command', indexer#{s:name}#command())
    call indexer#declare('g:indexer_tags_options', '-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=c,c++,php,python')
    call indexer#declare('g:indexer_tags_savedir', '~/.vim_indexer_tags/')
endf

func! indexer#{s:name}#startup()
    call indexer#add_log('Load module: ' . s:name)

    let l:lst = join(g:indexer_tags_watches, ',')
    if !empty(l:lst)
        exec 'au BufEnter ' . l:lst . ' call indexer#' . s:name . '#trigger(["locate"], expand("<afile>:p"))'
        if has('job')
            exec 'au BufReadPost ' . l:lst . ' call indexer#' . s:name . '#trigger(["onload", "-1"], expand("<afile>:p"))'
        en
    en
endf

func! indexer#{s:name}#resolve(req)
    let l:cxt = {}
    let l:cxt.fil = has_key(a:req, 'fil') ? a:req.fil : expand('%:p')
    let l:cxt.prj = indexer#project(l:cxt.fil)
    if empty(l:cxt.prj)
        return
    en

    let l:cxt.etc = {}
    let l:cxt.etc.tags_watches = get(l:cxt.prj.etc, 'tags_watches', g:indexer_tags_watches)
    let l:cxt.etc.tags_command = get(l:cxt.prj.etc, 'tags_command', g:indexer_tags_command)
    let l:cxt.etc.tags_options = get(l:cxt.prj.etc, 'tags_options', g:indexer_tags_options)
    let l:cxt.etc.tags_savedir = fnamemodify(get(l:cxt.prj.etc, 'tags_savedir', g:indexer_tags_savedir), ':p')

    if !has_key(s:tags, l:cxt.prj.dir)
        let s:tags[l:cxt.prj.dir] = []
    en
    if !has_key(s:tmps, l:cxt.prj.dir)
        let s:tmps[l:cxt.prj.dir] = {}
    en

    return l:cxt
endf

func! indexer#{s:name}#trigger(fun, fil)
    let l:cxt = indexer#{s:name}#resolve({'fil': a:fil})
    if !empty(l:cxt) && !empty(l:cxt.etc.tags_watches)
        for l:pat in l:cxt.etc.tags_watches
            if a:fil =~ glob2regpat(l:pat)
                call indexer#execute(call('indexer#request', [s:name] + a:fun), l:cxt)
                return
            en
        endfor
    en
endf

func! indexer#{s:name}#command()
    let l:cmd = ''
    if executable('exuberant-ctags')
        " On Debian Linux
        let l:cmd = 'exuberant-ctags'
    elseif executable('exctags')
        " On Free-BSD
        let l:cmd = 'exctags'
    elseif executable('ctags')
        let l:cmd = 'ctags'
    elseif executable('ctags.exe')
        let l:cmd = 'ctags.exe'
    elseif executable('tags')
        let l:cmd = 'tags'
    en

    return l:cmd
endf

func! indexer#{s:name}#uniform(pth)
    return substitute(a:pth, '[^a-zA-Z0-9_]', '_', 'g') . (has('cryptv') ? '#' . strpart(sha256(a:pth), 0, 7) : '')
endf

func! indexer#{s:name}#job_key(act, key)
    return s:name . '#' . a:act . '(' . a:key . ')'
endf

func! indexer#{s:name}#did_tag(job)
    if a:job.dat.out != a:job.dat.tmp
        if filereadable(a:job.dat.tmp)
            call rename(a:job.dat.tmp, a:job.dat.out)
        en
    en
endf

func! indexer#{s:name}#include(cxt, out)
    if !empty(a:out)
        call filter(s:tags[a:cxt.prj.dir], 'v:val != a:out')
        call insert(s:tags[a:cxt.prj.dir], a:out)
    en

    for l:fil in s:tags[a:cxt.prj.dir]
        exec "setl tags-=" . substitute(l:fil, ' ', '\\\\\\ ', 'g')
    endfor
    for l:fil in s:tags[a:cxt.prj.dir]
        exec "setl tags+=" . substitute(l:fil, ' ', '\\\\\\ ', 'g')
    endfor
endf

func! indexer#{s:name}#produce(cxt, src, out, key, sta)
    if a:cxt.etc.tags_command == ''
        call indexer#add_log('Tags command not found!')
        return
    en

    let l:job = {}
    let l:job.dat = {'cxt': a:cxt, 'src': a:src, 'out': a:out, 'tmp': tempname()}
    let l:job.ecb = 'indexer#' . s:name . '#did_tag'
    let l:job.cmd = printf('%s %s -f %s %s', a:cxt.etc.tags_command, a:cxt.etc.tags_options, l:job.dat.tmp, l:job.dat.src)
    let l:job.key = a:key
    let l:job.sta = a:sta

    if has('job') && indexer#has_mod('job')
        return function('indexer#job#run_job', l:job)()
    en
endf

"
" Actions
"
func! indexer#{s:name}#_(req) dict
    echon &tags
endf

func! indexer#{s:name}#_locate(req) dict
    call indexer#{s:name}#include(self, '')
endf

func! indexer#{s:name}#_update(req) dict
    let l:src = self.fil

    if !has_key(s:tmps[self.prj.dir], l:src)
        let s:tmps[self.prj.dir][l:src] = tempname()
    en

    let l:out = s:tmps[self.prj.dir][l:src]

    call indexer#add_log('Make tags: ' . l:out)
    if !empty(indexer#{s:name}#produce(self, l:src, l:out,
                \ indexer#{s:name}#job_key(a:req.act, l:out), str2nr(get(a:req.lst, 2, '0'))))
        call indexer#{s:name}#include(self, l:out)
    en
endf

func! indexer#{s:name}#_onload(req) dict
    let l:src = self.prj.dir

    if !isdirectory(self.etc.tags_savedir)
        if exists("*mkdir")
            call mkdir(self.etc.tags_savedir, 'p')
        en
    en

    let l:out = self.etc.tags_savedir . indexer#{s:name}#uniform(l:src)

    call indexer#add_log('Make tags: ' . l:out)
    if !empty(indexer#{s:name}#produce(self, l:src, l:out,
                \ indexer#{s:name}#job_key(a:req.act, l:out), str2nr(get(a:req.lst, 2, '0'))))
        call indexer#{s:name}#include(self, l:out)
    en
endf

func! indexer#{s:name}#_reload(req) dict
    if !empty(s:tmps[self.prj.dir])
        let l:buf = bufnr('%')
        for l:tmp in values(s:tmps[self.prj.dir])
            call indexer#add_log('Dele tags: ' . l:tmp)

            call delete(l:tmp)
            call filter(s:tags[self.prj.dir], 'v:val != l:tmp')
            exec "bufdo setl tags-=" . substitute(l:tmp, ' ', '\\\\\\ ', 'g')
        endfor
        exec 'buffer ' . l:buf
        let s:tmps[self.prj.dir] = {}
    en

    call call('indexer#' . s:name . '#_onload', [a:req], self)
endf

"
" Initial
"
call indexer#{s:name}#initial()
