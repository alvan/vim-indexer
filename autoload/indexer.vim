if exists('s:name') | fini | el | let s:name = 'indexer' | en

let s:prjs = {}
let s:mods = {}

let s:logs = {'logs': []}
func! s:logs.log(...)
    call add(self.logs, [localtime(), a:000])
    if len(self.logs) > 20
        call remove(self.logs, 0)
    en
endf
func! indexer#logging()
    return s:logs
endf

func! indexer#declare(var, def)
    if !exists(a:var)
        let {a:var} = a:def
    en
endf

func! indexer#require(mod)
    if !has_key(s:mods, a:mod)
        let s:mods[a:mod] = indexer#{a:mod}#profile()
        if !s:mods[a:mod]
            let s:mods[a:mod] = {'name': a:mod, 'deps': []}
        en

        for l:dep in s:mods[a:mod].deps
            call indexer#require(l:dep)
        endfor
        call add(filter(indexer#modules(), 'v:val != a:mod'), a:mod)
    en
endf

func! indexer#initial()
    call indexer#declare('g:indexer_root_folders', [$HOME])
    call indexer#declare('g:indexer_root_markers', ['.git'])
    call indexer#declare('g:indexer_root_setting', 'indexer.json')
    call indexer#declare('g:indexer_user_modules', ['log', 'tag'])

    for l:mod in indexer#modules()
        call indexer#require(l:mod)
    endfor
endf

func! indexer#startup()
    if exists('#User#IndexerStartup')
        doautocmd <nomodeline> User IndexerStartup
    en

    for l:mod in indexer#modules()
        call indexer#{l:mod}#startup()
    endfor

    if exists('#User#IndexerStarted')
        doautocmd <nomodeline> User IndexerStarted
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
    let l:req.mod = get(a:000, 0, '')
    let l:req.act = get(a:000, 1, '')
    let l:req.opt = a:000[2:]

    return l:req
endf

func! indexer#process(req)
    if a:req.mod == ''
        echon "Indexer modules: " indexer#modules() "\n"

        let l:prj = indexer#project(expand('%:p'))
        if !empty(l:prj)
            echon "\n"
            echon "Current project: " l:prj.dir "\n"
            echon '> ' l:prj.dir g:indexer_root_setting "\n"
            echon '  ' l:prj.etc "\n"
            echon "\n"
        en
        return
    en

    call indexer#execute(a:req, indexer#{a:req.mod}#resolve(a:req))
endf

func! indexer#execute(req, cxt)
    if empty(a:req)
        call indexer#logging().log('None request.')
        return
    en

    if type(a:cxt) != v:t_dict
        call indexer#logging().log('None context.')
        return
    en

    if index(indexer#actions(a:req.mod), a:req.act) < 0
        call indexer#logging().log(printf('Miss action "%s" in module "%s"', a:req.act, a:req.mod))
        return
    en

    call call(s:name . '#' . a:req.mod . '#_' . a:req.act, [a:req], a:cxt)
endf

func! indexer#modules()
    return g:indexer_user_modules
endf

func! indexer#actions(mod)
    let l:res = []
    let l:pre = s:name . '#' . a:mod . '#_'

    redi => l:ret
    sil! exec 'fu /^' . l:pre
    redi END

    if l:ret != ''
        for l:def in split(l:ret, "\n")
            let l:fun = strpart(l:def, stridx(l:def, l:pre) + strlen(l:pre))
            let l:fun = strpart(l:fun, 0, stridx(l:fun, '('))
            call add(l:res, l:fun)
        endfor
    en

    return l:res
endf

func! indexer#folders(pth, ...)
    let l:res = []
    if !empty(g:indexer_root_folders)
        let l:max = get(a:000, 0, 0)
        let l:pth = fnamemodify(a:pth, ':p')
        for l:dir in g:indexer_root_folders
            let l:dir = fnamemodify(l:dir, ':p')

            if strpart(l:pth, 0, strlen(l:dir)) == l:dir
                call add(l:res, l:dir)
                if l:max > 0 && len(l:res) >= l:max
                    return l:res
                en
            en
        endfor
    en

    return l:res
endf

func! indexer#parents(pth, ...)
    let l:res = []
    let l:max = get(a:000, 0, 0)

    if !empty(a:pth) && !empty(g:indexer_root_markers)
        let l:dir = fnamemodify(isdirectory(a:pth) ? a:pth : fnamemodify(a:pth, ':p:h'), ':p')
        let l:num = len(split(l:dir, '[\\\\/]'))
        while l:num > 0 && strlen(l:dir) > 1 && isdirectory(l:dir)
            let l:num -= 1

            if empty(indexer#folders(l:dir, 1))
                break
            en

            for l:fnm in g:indexer_root_markers
                if getftype(l:dir . l:fnm) != ''
                    call add(l:res, l:dir)
                    if l:max > 0 && len(l:res) >= l:max
                        return l:res
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

    return l:res
endf

func! indexer#project(pth)
    let l:dir = get(indexer#parents(a:pth, 1), 0, '')
    if l:dir != '' && !empty(indexer#folders(l:dir, 1))
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

"
" Initial
"
call indexer#initial()
