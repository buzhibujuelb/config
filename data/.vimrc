call plug#begin('~/.vim/plugged')
  Plug 'jayli/vim-easycomplete'
  Plug 'L3MON4D3/LuaSnip'
  Plug 'hzchirs/vim-material'
  Plug 'yianwillis/vimcdoc'
  Plug 'ojroques/vim-oscyank', {'branch': 'main'}
call plug#end()

let g:material_style='palenight'
se background=dark
colorscheme vim-material

"source $VIMRUNTIME/mswin.vim

se undodir=~/.vim/undo
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

se ignorecase    
se scs

se expandtab
se sw=2
se ts=2
se bs=2
se cin
se si
se et
se nowrap

se history=10000

function! SwitchRunPrg()
  if &filetype == 'c'
    if has('win32') 
      nmap<F10> :!start cmd /c "%<.exe&echo.&echo.______&size -d %<.exe&echo.&pause"<Enter><cr>
      se mp=gcc\ %<.c\ -o\ %<.exe\ -Wall\ -Wextra\ -Wno-parentheses\ -Wl,--stack=1000000000
    else
      nnoremap <silent> <F10> :call RunWithDivider('./%<')<CR>
      se mp=gcc\ %<.c\ -o\ %<\ -Wall\ -Wextra\ -Wno-parentheses
    endif
   endif
  if &filetype == 'cpp'
    if has('win32') 
      nmap<F10> :!start cmd /c "%<.exe&echo.&echo.______&size -d %<.exe&echo.&pause"<Enter><cr>
      se mp=g++\ %<.cpp\ -o\ %<.exe\ -Wall\ -Wextra\ -Wno-parentheses\ -Wl,--stack=1000000000
    else
      nnoremap <silent> <F10> :call RunWithDivider('./%<')<CR>
      se mp=g++\ %<.cpp\ -o\ %<\ -Wall\ -Wextra\ -Wno-parentheses
    endif
   endif
  if &filetype == 'python'
    nmap<F10> :!python %<Enter>
  endif
  if &filetype == 'dosbatch'
    nmap<F10> :!start %<Enter><cr>
  endif
  if &filetype == 'asm'
    se ft =masm
    se ts=4
    se sts=4
  endif
  if &filetype == 'java'
    se mp=javac\ %
    if has('win32') 
      nmap<F10> :!start cmd /c java %< &echo.&echo.______&echo.&pause<Enter>
    else
      nnoremap <silent> <F10> :call RunWithDivider('java %<')<CR>
    endif
   endif
endfunction

function! RunWithDivider(cmd)
  execute '!/usr/bin/time sh -c ' . shellescape(a:cmd . '; printf "\\n----\\n"')
endfunction

autocmd BufNewFile,BufRead,BufEnter *.java,*.py,*.cpp,*.c,*.cmd,*.asm :call SwitchRunPrg() 

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

se gfn=JetBrainsMonoNF-Regular:h16

se foldlevel=1000
se clipboard=unnamed,unnamedplus,autoselect
se foldmethod=syntax

se sidescroll=1
se sidescrolloff=20

if has('gui_running')
  se go=""
  se macligatures
endif

nmap <leader>c <Plug>OSCYankOperator
nmap <leader>cc <leader>c_
vmap <leader>c <Plug>OSCYankVisual

let g:easycomplete_tabnine_enable = 1
let g:easycomplete_lsp_server = {'cpp': '/usr/bin/clangd'}
" Tabnine 行内提醒，默认值 0
let g:easycomplete_tabnine_suggestion = 0
" Using nerdfont for lsp icons, default is 0
" 使用 Nerdfont，默认值 0
let g:easycomplete_nerd_font = 1
" 窗口边框，默认值 1，（只支持 nvim 0.11 及更高版本）
let g:easycomplete_winborder = 1
" 避免和终端/默认补全的 Ctrl-N 冲突
let g:easycomplete_diagnostics_next = ']d'
let g:easycomplete_diagnostics_prev = '[d'
" 匹配项格式，默认值 ["abbr", "kind", "menu"]
let g:easycomplete_pum_format = ["kind", "abbr", "menu"]
" 最常用的 keymap 配置
noremap gr :EasyCompleteReference<CR>
noremap gd :EasyCompleteGotoDefinition<CR>
noremap rn :EasyCompleteRename<CR>
" 插件默认绑定 shift-k 至 `:EasyCompleteHover`
" noremap gh :EasyCompleteHover<CR>
noremap gb :BackToOriginalBuffer<CR>

" cmdline 补全
let g:easycomplete_cmdline = 1

" 关闭 pum 菜单
" inoremap <C-M> <Plug>EasycompleteClosePum

" 选择上一个和下一个的快捷键
let g:easycomplete_tab_trigger = "<C-J>"
let g:easycomplete_shift_tab_trigger = "<C-K>"

" 重新定义回车键
" let g:easycomplete_use_default_cr = 0
" inoremap <C-L> <Plug>EasycompleteCR
