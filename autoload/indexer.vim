if exists('s:name') | fini | el | let s:name = 'indexer' | en

let s:prjs = {}

func! {s:name}#declare(var, def)
    if !exists(a:var)
        let {a:var} = a:def
    en
endf

func! {s:name}#initial()
    call {s:name}#declare('g:indexer_root_folders', [$HOME])
    call {s:name}#declare('g:indexer_root_markers', ['.git'])
    call {s:name}#declare('g:indexer_root_setting', 'indexer.json')
    call {s:name}#declare('g:indexer_user_modules', ['log', 'job', 'tag'])
endf

func! {s:name}#startup()
    for l:mod in {s:name}#modules()
        call {s:name}#{l:mod}#startup()
    endfor

    if exists('#User#IndexerStarted')
        if v:version > 703 || v:version == 703 && has('patch442')
            doautocmd <nomodeline> User IndexerStarted
        el
            doautocmd User IndexerStarted
        en
    en
endf

func! {s:name}#default()
    echon "Indexer modules: " {s:name}#modules() "\n"

    let l:prj = {s:name}#project(expand('%:p'))
    if !empty(l:prj)
        echon "\n"
        echon "Current project: " l:prj.dir "\n"
        echon '> ' l:prj.dir g:indexer_root_setting "\n"
        echon '  ' l:prj.etc "\n"
        echon "\n"
    en
endf

func! {s:name}#express(...)
    let l:cmd = get(a:000, 1, '')
    let l:pos = get(a:000, 2)
    let l:pre = substitute(
                \ substitute(strpart(l:cmd, stridx(l:cmd, ' '), l:pos), '^\s\+', '', '')
                \ , '\s\+', ' ', 'g')
    let l:len = strlen(l:pre)

    let l:res = []

    for l:mod in {s:name}#modules()
        if strpart(l:mod, 0, l:len) == l:pre
            call add(l:res, l:mod)
        en
    endfor

    for l:mod in {s:name}#modules()
        for l:act in {s:name}#actions(l:mod)
            if l:act != ''
                let l:key = l:mod . ' ' . l:act
                if strpart(l:key, 0, l:len) == l:pre
                    call add(l:res, stridx(strpart(l:key, l:len), ' ') < 0 ? l:act : l:key)
                en
            en
        endfor
    endfor

    return join(l:res, "\n")
endf

func! {s:name}#request(...)
    let l:req = {}
    let l:req.mod = get(a:000, 0, '')
    let l:req.act = get(a:000, 1, '')
    let l:req.lst = a:000

    return l:req
endf

func! {s:name}#process(req)
    if a:req.mod == ''
        call {s:name}#default()
        return
    en

    if !{s:name}#has_mod(a:req.mod)
        call {s:name}#add_log('Miss module: ' . a:req.mod)
        return
    en

    call {s:name}#execute(a:req, {s:name}#{a:req.mod}#resolve(a:req))
endf

func! {s:name}#execute(req, cxt)
    if empty(a:req)
        call {s:name}#add_log('None request.')
        return
    en

    if type(a:cxt) != v:t_dict
        call {s:name}#add_log('None context.')
        return
    en

    if index({s:name}#actions(a:req.mod), a:req.act) < 0
        call {s:name}#add_log(printf('Miss action "%s" in module "%s"', a:req.act, a:req.mod))
        return
    en

    call call(s:name . '#' . a:req.mod . '#_' . a:req.act, [a:req], a:cxt)
endf

func! {s:name}#modules()
    return g:indexer_user_modules
endf

func! {s:name}#actions(mod)
    let l:lst = []
    let l:pre = s:name . '#' . a:mod . '#_'

    redi => l:ret
    sil! exec 'fu /^' . l:pre
    redi END

    if l:ret != ''
        let l:res = split(l:ret, "\n")
        if !empty(l:res)
            for l:def in l:res
                let l:fun = strpart(l:def, stridx(l:def, l:pre) + strlen(l:pre))
                let l:fun = strpart(l:fun, 0, stridx(l:fun, '('))
                call add(l:lst, l:fun)
            endfor
        en
    en

    return l:lst
endf

func! {s:name}#folders(pth, ...)
    let l:lst = []
    if !empty(g:indexer_root_folders)
        let l:max = get(a:000, 0, 0)
        let l:pth = fnamemodify(a:pth, ':p')
        for l:dir in g:indexer_root_folders
            let l:dir = fnamemodify(l:dir, ':p')

            if strpart(l:pth, 0, strlen(l:dir)) == l:dir
                call add(l:lst, l:dir)
                if l:max > 0 && len(l:lst) >= l:max
                    return l:lst
                en
            en
        endfor
    en

    return l:lst
endf

func! {s:name}#parents(pth, ...)
    let l:lst = []
    let l:max = get(a:000, 0, 0)

    if !empty(a:pth) && !empty(g:indexer_root_markers)
        let l:dir = fnamemodify(isdirectory(a:pth) ? a:pth : fnamemodify(a:pth, ':p:h'), ':p')
        let l:num = len(split(l:dir, '[\\\\/]'))
        while l:num > 0 && strlen(l:dir) > 1 && isdirectory(l:dir)
            let l:num -= 1

            if empty({s:name}#folders(l:dir, 1))
                break
            en

            for l:fnm in g:indexer_root_markers
                let l:fil = l:dir . l:fnm
                if getftype(l:fil) != ''
                    call add(l:lst, l:dir)
                    if l:max > 0 && len(l:lst) >= l:max
                        return l:lst
                    en

                    break
                en
            endfor

            let l:nxt = fnamemodify(fnamemodify(l:dir, ':h:h'), ':p')
            if l:dir == l:nxt
                break
            en

            let l:dir = l:nxt
        endwhile
    en

    return l:lst
endf

func! {s:name}#project(pth)
    let l:dir = get({s:name}#parents(a:pth, 1), 0, '')
    if l:dir != '' && !empty({s:name}#folders(l:dir, 1))
        let l:prj = get(s:prjs, l:dir)
        if empty(l:prj)
            let l:prj = {'dir': l:dir}

            " Load project setting file
            let l:prj.etc = {}
            let l:cfg = l:dir . g:indexer_root_setting
            if filereadable(l:cfg)
                let l:etc = json_decode(join(readfile(l:cfg), "\n"))
                if !empty(l:etc)
                    call extend(l:prj.etc, l:etc)
                en
            en

            let s:prjs[l:dir] = l:prj
        en

        return l:prj
    en
endf

func! {s:name}#has_mod(mod)
    return index({s:name}#modules(), a:mod) >= 0
endf

func! {s:name}#add_log(...)
    if {s:name}#has_mod('log')
        call call(s:name . '#log#add_log', a:000)
    en
endf

"
" Initial
"
call {s:name}#initial()
