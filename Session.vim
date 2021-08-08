let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/dev/riscy_click
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1 riscy_click.srcs/sources_1/new/alu.sv
badd +107 riscy_click.srcs/sources_1/new/board.sv
badd +67 riscy_click.srcs/sources_1/new/consts.sv
badd +123 riscy_click.srcs/sources_1/new/cpu.sv
badd +21 riscy_click.srcs/sources_1/new/ctl.sv
badd +50 riscy_click.srcs/sources_1/new/regfile.sv
badd +121 riscy_click.srcs/sources_1/new/segdisplay.sv
badd +1 riscy_click.srcs/sim_1/new/cpu_tb.sv
badd +1 riscy_click.srcs/constrs_1/new/Nexys-A7-100T.xdc
badd +29 TODO
badd +15 bios/bios.dis
badd +8 bios/bios.c
badd +21 bios/Makefile
badd +49 riscy_click.srcs/sources_1/new/cpu_if.sv
badd +275 riscy_click.srcs/sources_1/new/cpu_id.sv
badd +1 riscy_click.srcs/sources_1/new/cpu_ex.sv
badd +13 riscy_click.srcs/sources_1/new/cpu_ma.sv
badd +13 riscy_click.srcs/sources_1/new/cpu_wb.sv
badd +8 bios/bios.coe
badd +32 riscy_click.srcs/sources_1/new/icache.sv
badd +268 riscy_click.srcs/cpu_if_sim/new/cpu_if_tb.sv
badd +85 riscy_click.srcs/sources_1/new/skid_buffer.sv
badd +34 riscy_click.srcs/sources_1/new/register.sv
badd +45 riscy_click.srcs/skid_buffer_sim/new/skid_buffer_tb.sv
argglobal
%argdel
$argadd riscy_click.srcs/sources_1/new/alu.sv
$argadd riscy_click.srcs/sources_1/new/board.sv
$argadd riscy_click.srcs/sources_1/new/consts.sv
$argadd riscy_click.srcs/sources_1/new/cpu.sv
$argadd riscy_click.srcs/sources_1/new/ctl.sv
$argadd riscy_click.srcs/sources_1/new/regfile.sv
$argadd riscy_click.srcs/sources_1/new/segdisplay.sv
$argadd riscy_click.srcs/sim_1/new/cpu_tb.sv
edit TODO
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
if bufexists("TODO") | buffer TODO | else | edit TODO | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 24 - ((23 * winheight(0) + 26) / 53)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
24
normal! 043|
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
