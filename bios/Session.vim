let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd /mnt/d/dev/riscy_click/bios
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +25 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/alu.sv
badd +99 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/board.sv
badd +16 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/consts.sv
badd +236 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/cpu.sv
badd +5 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/ctl.sv
badd +46 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/regfile.sv
badd +137 /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/segdisplay.sv
badd +43 /mnt/d/dev/riscy_click/riscy_click.srcs/sim_1/new/cpu_tb.sv
badd +1 /mnt/d/dev/riscy_click/riscy_click.srcs/constrs_1/new/Nexys-A7-100T.xdc
badd +9 /mnt/d/dev/riscy_click/TODO
badd +15 bios.dis
badd +8 bios.c
badd +21 Makefile
argglobal
%argdel
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/alu.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/board.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/consts.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/cpu.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/ctl.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/regfile.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sources_1/new/segdisplay.sv
$argadd /mnt/d/dev/riscy_click/riscy_click.srcs/sim_1/new/cpu_tb.sv
edit bios.dis
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
if bufexists("bios.dis") | buffer bios.dis | else | edit bios.dis | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 15 - ((14 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
15
normal! 0
tabnext 1
if exists('s:wipebuf') && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 winminheight=1 winminwidth=1 shortmess=atIc
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
