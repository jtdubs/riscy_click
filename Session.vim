let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd /mnt/d/dev/riscy_click
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1 constraints/Nexys-A7-100T.xdc
badd +1 roms/bios/bios.c
badd +1 src/alu.sv
badd +1 src/bios_rom.sv
badd +1 src/board.sv
badd +1 src/character_rom.sv
badd +1 src/chipset.sv
badd +1 src/common.sv
badd +1 src/cpu.sv
badd +1 src/cpu_clk_gen.sv
badd +1 src/cpu_csr.sv
badd +1 src/cpu_ex.sv
badd +1 src/cpu_id.sv
badd +1 src/cpu_if.sv
badd +1 src/cpu_ma.sv
badd +1 src/cpu_wb.sv
badd +1 src/keyboard.sv
badd +1 src/logging.sv
badd +1 src/pixel_clk_gen.sv
badd +1 src/regfile.sv
badd +1 src/segdisplay.sv
badd +1 src/system_ram.sv
badd +1 src/vga_controller.sv
badd +1 src/video_ram.sv
argglobal
%argdel
$argadd constraints/Nexys-A7-100T.xdc
$argadd roms/bios/bios.c
$argadd src/alu.sv
$argadd src/bios_rom.sv
$argadd src/board.sv
$argadd src/character_rom.sv
$argadd src/chipset.sv
$argadd src/common.sv
$argadd src/cpu.sv
$argadd src/cpu_clk_gen.sv
$argadd src/cpu_csr.sv
$argadd src/cpu_ex.sv
$argadd src/cpu_id.sv
$argadd src/cpu_if.sv
$argadd src/cpu_ma.sv
$argadd src/cpu_wb.sv
$argadd src/keyboard.sv
$argadd src/logging.sv
$argadd src/pixel_clk_gen.sv
$argadd src/regfile.sv
$argadd src/segdisplay.sv
$argadd src/system_ram.sv
$argadd src/vga_controller.sv
$argadd src/video_ram.sv
edit constraints/Nexys-A7-100T.xdc
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 1 - ((0 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1
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
