" Enable line numbers
set number
" Enable relative line numbers
set relativenumber
" Enable auto-indentation
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
" Enable line wrapping
set wrap
" Enable syntax highlighting
syntax enable
" Show matching parentheses
set showmatch
" Enable line search highlighting
set hlsearch

" Plugin Manager - vim-plug
call plug#begin('~/.vim/plugged')

" Python Development Plugins
Plug 'davidhalter/jedi-vim'               " Autocompletion and code navigation for Python
Plug 'vim-python/python-syntax'           " Better Python syntax highlighting
Plug 'nvie/vim-flake8'                    " Flake8 integration for linting Python code

" Node.js Development Plugins
Plug 'mxw/vim-jsx'                        " Support for JSX syntax in Node.js
Plug 'neoclide/coc.nvim', {'branch': 'release'}  " Autocompletion for Node.js and Python
Plug 'jparise/vim-graphql'                " Syntax highlighting for GraphQL (if you use GraphQL)
Plug 'othree/html5.vim'                   " HTML5 support (if you're working with Node.js and front-end code)

call plug#end()
