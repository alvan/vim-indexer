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
let s:jobs = {}

func! indexer#{s:name}#initial()
endf

func! indexer#{s:name}#startup()
    call indexer#add_log('Load module: ' . s:name)
endf

func! indexer#{s:name}#prepare(req)
    return {}
endf

func! indexer#{s:name}#run_job() dict
    if !has('job')
        call indexer#add_log('Miss +job feature')
        return
    en

    " Job sta:
    "  -1 => skip saving job if there's an old job exists already
    "   0 => skip saving job if there's an old job running already
    "   1 => stop the old job before saving new job
    "
    if self.key != '' && has_key(s:jobs, self.key)
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

    let l:job = job_start(self.cmd, {"exit_cb": function('indexer#' . s:name . '#end_job', self)})
    if self.key != ''
        let s:jobs[self.key] = l:job
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
func! indexer#{s:name}#_(req) dict
    call indexer#execute(call('indexer#request', [s:name, 'status']), self)
endf

func! indexer#{s:name}#_status(req) dict
    echon "\n"
    for [l:key, l:job] in items(s:jobs)
        echon {l:key: job_status(l:job)} "\n"
    endfor
endf

"
" Initial
"
call indexer#{s:name}#initial()
