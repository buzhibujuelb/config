
call plug#begin('~/.vim/plugged')
  Plug 'hzchirs/vim-material'
  Plug 'yianwillis/vimcdoc'
call plug#end()

let g:material_style='palenight'
se background=dark
colorscheme vim-material

"source $VIMRUNTIME/mswin.vim

se tgc

se nu
se cuc
se cul
se hls
se is
se udf
se noswf
se mouse=a
syntax on 

se expandtab
se sw=2
se ts=2
se bs=2
se cin
se si
se et
se nowrap

se history=10000

if has('win32')
  se mp=g++\ %<.cpp\ -o\ %<.exe\ -Wall\ -Wextra\ -Wno-parentheses\ -Wl,--stack=1000000000
else 
  se mp=g++\ %<.cpp\ -o\ %<\ -Wall\ -Wextra\ -Wno-parentheses
endif

function! SwitchRunPrg()
  if &filetype == 'cpp'
    if has('win32') 
      nmap<F10> :!start cmd /c "%<.exe&echo.&echo.______&size -d %<.exe&echo.&pause"<Enter><cr>
    else
      nmap<F10> :!time ./%<<Enter>
    endif
  elseif &filetype == 'python'
    nmap<F10> :!python %<Enter>
  endif
endfunction

autocmd BufNewFile,BufRead *.py,*.cpp :call SwitchRunPrg() 

if has('win32')
  nmap<F4> :!start explorer .<Enter>
else
  nmap<F4> :!xdg-open .<Enter>
endif
  
nmap<F5> :e!<Enter>
nmap<F9> :w<Enter>:lmake<Enter>
imap<F9> <Esc><F9>
imap<F10> <Esc><F10>
nmap<F11> <F9><F10>
imap<F11> <Esc><F11>

se fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
se fileencoding=utf-8
se termencoding=utf-8
se encoding=utf-8

se ar
se aw
se acd

let g:netrw_banner = 0

"se gfn=Fira\ Code:h13
se gfn=Consolas:h15

se foldlevel=1000
se clipboard=unnamed,unnamedplus,autoselect
se foldmethod=syntax

se sidescroll=1
se sidescrolloff=20

if has('gui_running')
  se go=""
endif


