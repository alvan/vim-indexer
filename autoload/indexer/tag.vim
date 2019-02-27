" -- {{{
"
"          File:  tag.vim
"        Author:  Alvan
"         Usage:  Indexer tag [locate|reload|status|update]
"   Description:  module that provides painless transparent tags generation.
"
" -- }}}
if exists('s:name') | fini | el | let s:name = 'tag' | en

let s:jobs = {}
let s:tags = {}
let s:tmps = {}

func! indexer#{s:name}#initial()
    call indexer#declare('g:indexer_tags_watches', ['*.c', '*.h', '*.c++', '*.cpp', '*.php', '*.py'])
    call indexer#declare('g:indexer_tags_command', indexer#{s:name}#command())
    call indexer#declare('g:indexer_tags_options', '-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=c,c++,php,python')
    call indexer#declare('g:indexer_tags_savedir', '~/.vim_indexer_tags/')

    call indexer#declare('g:indexer_tags_handler_locate', ['locate'])
    call indexer#declare('g:indexer_tags_handler_reload', ['reload', '-1'])
    call indexer#declare('g:indexer_tags_handler_update', ['update'])
endf

func! indexer#{s:name}#profile()
endf

func! indexer#{s:name}#startup()
    call indexer#logging().log('Load module: ' . s:name)

    let l:res = join(g:indexer_tags_watches, ',')
    if !empty(l:res)
        exec 'au BufReadPost ' . l:res . ' call indexer#' . s:name . '#trigger("reload", expand("<afile>:p"))'
        exec 'au BufWritePost ' . l:res . ' call indexer#' . s:name . '#trigger("update", expand("<afile>:p"))'
        exec 'au BufEnter ' . l:res . ' call indexer#' . s:name . '#trigger("locate", expand("<afile>:p"))'
    en
endf

func! indexer#{s:name}#resolve(req)
    let l:cxt = {}
    let l:cxt.pth = has_key(a:req, 'pth') ? a:req.pth : expand('%:p')
    let l:cxt.prj = indexer#project(l:cxt.pth)
    if empty(l:cxt.prj)
        return
    en

    let l:cxt.etc = {}
    let l:cxt.etc.tags_watches = get(l:cxt.prj.etc, 'tags_watches', g:indexer_tags_watches)
    let l:cxt.etc.tags_command = get(l:cxt.prj.etc, 'tags_command', g:indexer_tags_command)
    let l:cxt.etc.tags_options = get(l:cxt.prj.etc, 'tags_options', g:indexer_tags_options)
    let l:cxt.etc.tags_savedir = fnamemodify(get(l:cxt.prj.etc, 'tags_savedir', g:indexer_tags_savedir), ':p')

    let l:cxt.etc.tags_handler_locate = get(l:cxt.prj.etc, 'tags_handler_locate', g:indexer_tags_handler_locate)
    let l:cxt.etc.tags_handler_reload = get(l:cxt.prj.etc, 'tags_handler_reload', g:indexer_tags_handler_reload)
    let l:cxt.etc.tags_handler_update = get(l:cxt.prj.etc, 'tags_handler_update', g:indexer_tags_handler_update)

    if !has_key(s:tags, l:cxt.prj.dir)
        let s:tags[l:cxt.prj.dir] = [l:cxt.etc.tags_savedir . indexer#{s:name}#uniform(l:cxt.prj.dir)]
    en
    if !has_key(s:tmps, l:cxt.prj.dir)
        let s:tmps[l:cxt.prj.dir] = {}
    en

    return l:cxt
endf

func! indexer#{s:name}#trigger(fun, pth)
    let l:key = 'tags_handler_' . a:fun
    let l:cxt = indexer#{s:name}#resolve({'pth': a:pth})
    if !empty(l:cxt) && !empty(l:cxt.etc.tags_watches) && has_key(l:cxt.etc, l:key) && !empty(l:cxt.etc[l:key])
        for l:pat in l:cxt.etc.tags_watches
            if l:cxt.pth =~ glob2regpat(l:pat)
                call indexer#execute(call('indexer#request', [s:name] + l:cxt.etc[l:key]), l:cxt)
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

func! indexer#{s:name}#uniform(str)
    return substitute(a:str, '[^a-zA-Z0-9_]', '_', 'g') . (has('cryptv') ? '#' . strpart(sha256(a:str), 0, 7) : '')
endf

func! indexer#{s:name}#job_key(act, key)
    return s:name . '#' . a:act . '(' . a:key . ')'
endf

func! indexer#{s:name}#run_job() dict
    if !has('job')
        call indexer#logging().log('Miss +job feature')
        return
    en

    " Job sta:
    "  -1 => skip saving job if there's an old job exists already
    "   0 => skip saving job if there's an old job running already
    "   1 => stop the old job before saving new job
    "
    if self.key != '' && has_key(s:jobs, self.key)
        if self.sta < 0
            call indexer#logging().log('Skip job: ' . self.key)
            return
        en

        let l:job = get(s:jobs, self.key)
        if job_status(l:job) == 'run'
            if self.sta > 0
                call indexer#logging().log('Stop job: ' . self.key)
                call job_stop(l:job)
            el
                call indexer#logging().log('Skip job: ' . self.key)
                return
            en
        en
    en

    call indexer#logging().log('Save job: ' . self.key)
    call indexer#logging().log('Exec cmd: ' . self.cmd)

    let l:job = job_start(self.cmd, {"exit_cb": function('indexer#' . s:name . '#end_job', self)})
    if self.key != ''
        let s:jobs[self.key] = l:job
    en

    return l:job
endf

func! indexer#{s:name}#end_job(job, err) dict
    if !a:err
        call indexer#logging().log('Done job: ' . self.key, [a:job, a:err])
        if has_key(self, 'end')
            call {self.end}(self)
        en
    el
        call indexer#logging().log('Exit job: ' . self.key, [a:job, a:err])
    en
endf

func! indexer#{s:name}#did_tag(job)
    if a:job.dat.out != a:job.dat.tmp
        if filereadable(a:job.dat.tmp)
            call rename(a:job.dat.tmp, a:job.dat.out)
        en
    en
endf

func! indexer#{s:name}#arrange(cxt, out)
    if !empty(a:out)
        call filter(s:tags[a:cxt.prj.dir], 'v:val != a:out')
        call insert(s:tags[a:cxt.prj.dir], a:out)
    en

    for l:tmp in values(s:tmps[a:cxt.prj.dir])
        exec "setl tags-=" . substitute(l:tmp, ' ', '\\\\\\ ', 'g')
    endfor

    for l:pth in s:tags[a:cxt.prj.dir]
        exec "setl tags-=" . substitute(l:pth, ' ', '\\\\\\ ', 'g')
    endfor
    for l:pth in s:tags[a:cxt.prj.dir]
        exec "setl tags+=" . substitute(l:pth, ' ', '\\\\\\ ', 'g')
    endfor
endf

func! indexer#{s:name}#produce(cxt, src, out, key, sta)
    if a:cxt.etc.tags_command == ''
        call indexer#logging().log('Tags command not found!')
        return
    en

    let l:job = {}
    let l:job.sta = a:sta
    let l:job.key = a:key
    let l:job.dat = {'cxt': a:cxt, 'src': a:src, 'out': a:out, 'tmp': tempname()}
    let l:job.cmd = printf('%s %s -f "%s" "%s"', a:cxt.etc.tags_command, a:cxt.etc.tags_options, l:job.dat.tmp, l:job.dat.src)
    let l:job.end = 'indexer#' . s:name . '#did_tag'

    return function('indexer#' . s:name . '#run_job', l:job)()
endf

"
" Actions
"
func! indexer#{s:name}#_(req) dict
    echon &tags
endf

func! indexer#{s:name}#_locate(req) dict
    call indexer#{s:name}#arrange(self, '')
endf

func! indexer#{s:name}#_reload(req) dict
    let l:src = self.prj.dir
    let l:out = self.etc.tags_savedir . indexer#{s:name}#uniform(l:src)
    if !isdirectory(self.etc.tags_savedir)
        if exists("*mkdir")
            call mkdir(self.etc.tags_savedir, 'p')
        en
    en

    if !empty(indexer#{s:name}#produce(self, l:src, l:out,
                \ indexer#{s:name}#job_key(a:req.act, l:out), str2nr(get(a:req.opt, 0, '0'))))
        if !empty(s:tmps[self.prj.dir])
            for l:tmp in values(s:tmps[self.prj.dir])
                call filter(s:tags[self.prj.dir], 'v:val != l:tmp')
            endfor
        en

        call indexer#{s:name}#arrange(self, l:out)
    en
endf

func! indexer#{s:name}#_status(req) dict
    echon "\n"
    for [l:key, l:job] in items(s:jobs)
        echon {l:key: job_status(l:job)} "\n"
    endfor
endf

func! indexer#{s:name}#_update(req) dict
    let l:src = self.pth

    if !has_key(s:tmps[self.prj.dir], l:src)
        let s:tmps[self.prj.dir][l:src] = tempname()
    en

    let l:out = s:tmps[self.prj.dir][l:src]

    if !empty(indexer#{s:name}#produce(self, l:src, l:out,
                \ indexer#{s:name}#job_key(a:req.act, l:out), str2nr(get(a:req.opt, 0, '0'))))
        call indexer#{s:name}#arrange(self, l:out)
    en
endf

"
" Initial
"
call indexer#{s:name}#initial()
