# Indexer

A Indexer plugin that provides painless transparent tags generation with project management.

Usage: `:Indexer [module] [action] [params ...]`

## Options

    " JSON formatted configuration file which located in the project directory,
    " makes you could specify different options for each project.
    let g:indexer_root_setting = 'indexer.json'

    " Project root markers, used to identify project root directory.
    let g:indexer_root_markers = ['.git']

    " Enabled user modules
    let g:indexer_user_modules = ['log', 'job', 'tag']

## Options (module)

    " Module: log
    "
    let g:indexer_logs_maxsize = 100

    " Module: job
    "

    " Module: tag
    "
    " This module can also read the configuration of the current project.
    " For example you can have a JSON formatted file in the project directory:
    " > indexer.json:
    " {
    "    "tags_savedir": "~/.vim_indexer_tags/",
    "    "ctag_watches": ["*.php"],
    "    "ctag_command": "ctags",
    "    "ctag_options": "-R --sort=yes --languages=php"
    " }
    "
    " And/Or settings in global:
    "
    let g:indexer_tags_savedir = fnamemodify('~/.vim_indexer_tags/', ':p')
    let g:indexer_ctag_watches = ['*.c', '*.h', '*.c++', '*.php', '*.py']
    let g:indexer_ctag_command = 'ctags'
    let g:indexer_ctag_options = '-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=vim,c,c++,php,python'


