; " 关闭 vi 兼容模式
set nocompatible

" 语法高亮
syntax enable

" 允许在有未保存的修改时切换缓冲区，此时的修改由 vim 负责保存
set hidden

" 不自动折行
set nowrap

" 设置编码为 utf8
set encoding=utf-8

" 弹出菜单的高度
set pumheight=10

" 文件写入时的编码
set fileencoding=utf-8

" 显示标尺
set ruler

" 命令行区的高度
set cmdheight=2

" 将 - 分隔的单词作为一个单词文本对象
set iskeyword+=-

" 不使用鼠标
set mouse=""

" 弹窗的位置
set splitbelow
set splitright

" Support 256 colors
set t_Co=256

" So that I can see `` in markdown files
set conceallevel=0

" 根据文件类型自动缩进
filetype plugin indent on

" 开始新行时处理缩进
set autoindent

" 将制表符Tab展开为空格, 这对于Python尤其有用
set expandtab
"
" " 要计算的空格数
set tabstop=4
"
" " 用于自动缩进的空格数
set shiftwidth=4
"
" " 在多数终端上修正退格键Backspace的行为
set backspace=2

" 状态栏
set laststatus=2
set number
set cursorline
set background=dark
set showtabline=2

" 不进行备份设置
set nobackup
set nowritebackup

" 禁止产生交换文件
set noswapfile

" 跨会话撤销，即新打开的文件依然能够撤销之前的 undo
set undofile
set undodir=~/.config/nvim/undodir
if !isdirectory(&undodir)
call mkdir(&undodir, "p", 0700)
endif
"
"
" " 搜索忽略大小写
set ignorecase

" 环境配置
let g:python3_host_prog = expand("/usr/bin/python3")

" 修改配置时，自动加载文件
au! BufWritePost $MYVIMRC source %
