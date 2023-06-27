" 关闭vim的兼容模式
set nocompatible

" 开启文件类型检查，并且载入与该类型对应的缩进规则。比如，如果编辑的是.py文件，Vim 就是会找 Python 的缩进规则~/.vim/indent/python.vim。
" filetype indent on

" ------十字光标
" 光标所在的当前行高亮
set cursorline
" 高亮光标所在列
set cursorcolumn

" ------光标移动配置
" 解决光标不能移动问题
set term=builtin_ansi
" 垂直滚动时，光标距离顶部/底部的位置（单位：行）
set scrolloff=7

" ------查找配置
" 高亮查找
set hlsearch
" 输入搜索内容时就显示搜索结果
set incsearch

" ---- 自动缩进及语法高亮配置
" 自动退格对齐缩进
set autoindent
" C和JAVA风格自动缩进
set cindent
" 经典缩进
set smartindent
" tab缩进2格
set tabstop=2
" 退格2个空格
set shiftwidth=2 
" 软制表位2个空格
set softtabstop=2
" 自动将 Tab 转为空格
set expandtab
" 当输入一个左括号时自动匹配右括号
set showmatch
" 自动折行，即太长的行分成几行显示
set wrap
" 打开语法高亮。自动识别代码，使用多种颜色显示。
syntax on
" 启用256色
set t_Co=256
" highlight主要是用来配色的,包括语法高亮等个性化的配置
highlight CursorLine cterm=none ctermbg=DarkMagenta ctermfg=White
highlight CursorColumn cterm=none ctermbg=DarkMagenta ctermfg=White
highlight Search cterm=reverse ctermbg=none ctermfg=none

" ------退格键配置
" 设置退格键功能。为2时可以删任意字符。为0或1时仅可以删除刚才输入的字符。
set backspace=2

" ------自动备份配置
" 自动备份文件
set backup 
" 设置自动保存内容
set autowrite
" 设置确认，在处理未保存或只读文件的时候，弹出确认
set confirm

" ------状态栏显示配置
" 在状态栏显示光标的当前位置（位于哪一行哪一列）
set ruler
" 在底部显示，当前处于命令模式还是插入模式
set showmode
" 标尺的右边显示未完成的命令
set showcmd
" 显示行号
set nu
" 防止粘贴乱码
set paste

" ------编码配置
" 使用utf-8编码
set encoding=utf-8 

" 显示目前所有的环境参数值,开启后每次启动vim都会提示
"set all
