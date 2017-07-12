" -- {{{
"
"          File:  job.vim
"        Author:  Alvan
"         Usage:  Indexer job [status]
"   Description:  module that provides starting and stopping jobs.
"
" -- }}}
if exists('s:name') | fini | en

let s:name = 'job'
let s:acts = ['', 'status']
let s:jobs = {}

func! indexer#{s:name}#actions()
    return s:acts
endf

func! indexer#{s:name}#initial()
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

func! indexer#{s:name}#has_job(key)
    return has_key(s:jobs, a:key)
endf

func! indexer#{s:name}#run_job() dict
    if !has('job')
        return
    en

    " Job sta:
    "  -1 => skip saving job if there's an old job exists already
    "   0 => skip saving job if there's an old job running already
    "   1 => stop the old job before saving new job
    "
    if self.key != ''
        if has_key(s:jobs, self.key)
            if self.sta < 0
                call indexer#add_log('Skip job: ' . self.key)
                return
            en

            let l:job = get(s:jobs, self.key)
            if job_status(l:job) == 'run'
                if self.sta > 0
                    call indexer#add_log('Stop job: ' . self.key)
                    call job_stop(l:job)
                el
                    call indexer#add_log('Skip job: ' . self.key)
                    return
                en
            en
        en

        call indexer#add_log('Save job: ' . self.key)
        let s:jobs[self.key] = job_start(self.cxt.cmd, {"exit_cb": function('indexer#' . s:name . '#end_job', self)})
    en
endf

func! indexer#{s:name}#end_job(job, err) dict
    if !a:err
        call indexer#add_log('Done job: ' . self.key, [a:job, a:err])
        if has_key(self, 'ecb')
            call {self.ecb}(self.cxt)
        en
    el
        call indexer#add_log('Exit job: ' . self.key, [a:job, a:err])
    en
endf

"
" Actions
"
func! indexer#{s:name}#_(cxt)
    call indexer#{s:name}#_status(a:cxt)
endf

func! indexer#{s:name}#_status(cxt)
    echon "\n"
    for [l:key, l:job] in items(s:jobs)
        echon {l:key: job_status(l:job)} "\n"
    endfor
endf

"
" Initial
"
call indexer#{s:name}#initial()
