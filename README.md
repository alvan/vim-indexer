# Indexer

Vim Indexer plugin that provides async tags generation with project management.

Usage: `:Indexer [module] [action] [params ...]`

## Modules

### log
Module that provides logging, usually used for debugging modules themselves.

Usage: `:Indexer log`

### job
Module that provides starting and stopping jobs (Vim8 with +job feature required).

Usage: `:Indexer job [status]`

### tag
Module that provides painless transparent tags generation (job module required).

Usage: `:Indexer tag [attach|update]`

## Options

    " JSON formatted configuration file which located in the project directory,
    " makes you could specify different options for each project.
    let g:indexer_root_setting = 'indexer.json'

    " Project root markers, used to identify project root directory.
    let g:indexer_root_markers = ['.git']

    " Enabled user modules.
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
    "
    " > indexer.json:
    " {
    "    "tags_watches": ["*.php"],
    "    "tags_command": "ctags",
    "    "tags_options": "-R --sort=yes --languages=php"
    "    "tags_savedir": "~/.vim_indexer_tags/",
    " }
    "
    " And/Or settings in global:
    "
    let g:indexer_tags_watches = ['*.c', '*.h', '*.c++', '*.php', '*.py']
    let g:indexer_tags_command = 'ctags'
    let g:indexer_tags_options = '-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=vim,c,c++,php,python'
    let g:indexer_tags_savedir = fnamemodify('~/.vim_indexer_tags/', ':p')


