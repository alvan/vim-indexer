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
    for l:mod in g:indexer_user_modules
        call indexer#{l:mod}#startup()
    endfor
endf

func! indexer#context(...)
    let l:cxt = {}
    let l:cxt.mod = get(a:000, 0, '')
    let l:cxt.act = get(a:000, 1, '')
    let l:cxt.etc = {'args': a:000}

    return l:cxt
endf

func! indexer#default(cxt)
    echon "Indexer modules: " g:indexer_user_modules "\n"

    let l:prj = indexer#project(expand('%:p'))
    if !empty(l:prj)
        echon "\n"
        echon "Current project: " l:prj.dir "\n"
        echon '> ' l:prj.dir g:indexer_root_setting "\n"
        echon '  ' l:prj.etc "\n"
        echon "\n"
    en
endf

func! indexer#process(cxt)
    if a:cxt.mod == ''
        call indexer#default(a:cxt)
        return
    en

    if indexer#has_mod(a:cxt.mod)
        let l:cxt = indexer#{a:cxt.mod}#context(a:cxt)
        if !empty(l:cxt)
            call indexer#execute(l:cxt)
            return
        en
    en

    echon 'Failed to call Indexer module "' a:cxt.mod '"'
endf

func! indexer#execute(cxt)
    call indexer#{a:cxt.mod}#_{a:cxt.act}(a:cxt)
endf

func! indexer#project(pth)
    if empty(g:indexer_root_markers)
        return
    en

    let l:dir = isdirectory(a:pth) ? a:pth : fnamemodify(a:pth, ':p:h')
    let l:num = len(split(l:dir, '[\\\\/]'))
    while l:num > 0 && strlen(l:dir) > 1 && isdirectory(l:dir)
        let l:num -= 1

        for l:fnm in g:indexer_root_markers
            let l:fil = l:dir . '/' . l:fnm
            if getftype(l:fil) != ''
                let l:dir = l:dir . '/'

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
        endfor

        let l:nxt = fnamemodify(l:dir, ':h')
        if l:dir == l:nxt
            break
        en

        let l:dir = l:nxt
    endwhile
endf

func! indexer#has_mod(mod)
    return index(g:indexer_user_modules, a:mod) >= 0
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
