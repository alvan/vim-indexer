# Indexer

Vim Indexer plugin that provides async tags generation with project management.

Usage: `:Indexer [module] [action] [params ...]`

## Options

    " Project root folders, used to identify ancestor path of project root directory.
    let g:indexer_root_folders = [$HOME]

    " Project root markers, used to identify project root directory.
    let g:indexer_root_markers = ['.git']

    " JSON formatted configuration file which located in the project root directory,
    " makes you could specify different options for each project.
    let g:indexer_root_setting = 'indexer.json'

    " Enabled user modules.
    let g:indexer_user_modules = ['log', 'tag']

## Modules

### log
Module that provides logging, usually used for debugging modules themselves.

Usage: `:Indexer log`

#### Options

    " Module: log
    "
    let g:indexer_logs_maxsize = 100


### tag
Module that provides painless transparent tags generation (Vim8 with +job feature required).

Usage: `:Indexer tag [locate|reload|status|update]`

Press <kbd>CTRL-]</kbd> to jump anywhere.

Notes:
* When using the `ctags` command to generate tags, you need to ensure that the corresponding command line tools are installed on the system.
* When opening a project for the first time, indexing can take a long time, depending on the size of the project.
You can view the progress by using the command `:Indexer tag status`

#### Options

    " Module: tag
    "
    " This module can also read the configuration of the current project.
    " For example you can have a JSON formatted file in the project directory:
    "
    " > indexer.json:
    " {
    "    "tags_watches": ["*.php"],
    "    "tags_command": "ctags",
    "    "tags_options": "-R --sort=yes --languages=php",
    "    "tags_savedir": "~/.vim_indexer_tags/",
    "    "tags_handler_locate": ["locate"],
    "    "tags_handler_reload": ["reload", "-1"],
    "    "tags_handler_update": ["update"],
    " }
    "
    " And/Or settings in global:
    "
    let g:indexer_tags_watches = ["*.c", "*.h", "*.c++", "*.cpp", "*.php", "*.py"]
    let g:indexer_tags_command = "ctags"
    let g:indexer_tags_options = "-R --sort=yes --c++-kinds=+p+l --fields=+iaS --extra=+q --languages=c,c++,php,python"
    let g:indexer_tags_savedir = "~/.vim_indexer_tags/"
    let g:indexer_tags_handler_locate = ["locate"]
    let g:indexer_tags_handler_reload = ["reload", "-1"]
    let g:indexer_tags_handler_update = ["update"]


