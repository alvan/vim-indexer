if exists("g:autoload_indexer") | fini | el | let g:autoload_indexer = 1 | en

let s:prjs = {}

func! indexer#declare(var, def)
    if !exists(a:var)
        let {a:var} = a:def
    en
endf

func! indexer#initial()
    call indexer#declare('g:indexer_root_setting', 'indexer.json')
    call indexer#declare('g:indexer_root_markers', ['.git'])
    call indexer#declare('g:indexer_user_modules', ['log', 'job', 'tag'])
endf

func! indexer#startup()
    for l:mod in indexer#modules()
        call indexer#{l:mod}#startup()
    endfor
endf

func! indexer#default()
    echon "Indexer modules: " indexer#modules() "\n"

    let l:prj = indexer#project(expand('%:p'))
    if !empty(l:prj)
        echon "\n"
        echon "Current project: " l:prj.dir "\n"
        echon '> ' l:prj.dir g:indexer_root_setting "\n"
        echon '  ' l:prj.etc "\n"
        echon "\n"
    en
endf

func! indexer#express(...)
    let l:cmd = get(a:000, 1, '')
    let l:pos = get(a:000, 2)
    let l:pre = substitute(
                \ substitute(strpart(l:cmd, stridx(l:cmd, ' '), l:pos), '^\s\+', '', '')
                \ , '\s\+', ' ', 'g')
    let l:len = strlen(l:pre)

    let l:res = []

    for l:mod in indexer#modules()
        if strpart(l:mod, 0, l:len) == l:pre
            call add(l:res, l:mod)
        en
    endfor

    for l:mod in indexer#modules()
        for l:act in indexer#actions(l:mod)
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

func! indexer#request(...)
    let l:req = {}
    let l:req.lst = a:000
    let l:req.mod = get(a:000, 0, '')
    let l:req.act = get(a:000, 1, '')

    return l:req
endf

func! indexer#process(req)
    if a:req.mod == ''
        call indexer#default()
        return
    en

    if !indexer#has_mod(a:req.mod)
        call indexer#add_log('Miss module: ' . a:req.mod)
        return
    en

    call indexer#execute(a:req, indexer#{a:req.mod}#prepare(a:req))
endf

func! indexer#execute(req, cxt)
    if empty(a:req)
        call indexer#add_log('None request.')
        return
    en

    if type(a:cxt) != v:t_dict
        call indexer#add_log('None context.')
        return
    en

    if index(indexer#actions(a:req.mod), a:req.act) < 0
        call indexer#add_log(printf('Miss action "%s" in module "%s"', a:req.act, a:req.mod))
        return
    en

    call call('indexer#' . a:req.mod . '#_' . a:req.act, [a:req], a:cxt)
endf

func! indexer#modules()
    return g:indexer_user_modules
endf

func! indexer#actions(mod)
    let l:lst = []
    let l:pre = 'indexer#' . a:mod . '#_'

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

func! indexer#parents(pth, ...)
    let l:lst = []
    let l:max = get(a:000, 0, 0)

    if !empty(g:indexer_root_markers)
        let l:dir = fnamemodify(isdirectory(a:pth) ? a:pth : fnamemodify(a:pth, ':p:h'), ':p')
        let l:num = len(split(l:dir, '[\\\\/]'))
        while l:num > 0 && strlen(l:dir) > 1 && isdirectory(l:dir)
            let l:num -= 1

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

func! indexer#project(pth)
    let l:dir = get(indexer#parents(a:pth, 1), 0, '')
    if l:dir != ''
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

func! indexer#has_mod(mod)
    return index(indexer#modules(), a:mod) >= 0
endf

func! indexer#add_log(...)
    if indexer#has_mod('log')
        call call('indexer#log#add_log', a:000)
    en
endf

"
" Initial
"
call indexer#initial()
