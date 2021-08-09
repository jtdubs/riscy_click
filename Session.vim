let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/dev/riscy_click
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +2 src/library/alu.sv
badd +232 src/library/board.sv
badd +1 src/library/common.sv
badd +1 src/library/cpu.sv
badd +1 src/library/cpu_csr.sv
badd +1 src/library/cpu_ex.sv
badd +280 src/library/cpu_id.sv
badd +1 src/library/cpu_if.sv
badd +1 src/library/cpu_ma.sv
badd +1 src/library/cpu_wb.sv
badd +1 src/library/regfile.sv
badd +1 src/library/segdisplay.sv
badd +1 src/library/vga_controller.sv
badd +93 src/synth/bios_rom.sv
badd +82 src/synth/character_rom.sv
badd +1 src/synth/cpu_clk_gen.sv
badd +1 src/synth/logging.sv
badd +1 src/synth/pixel_clk_gen.sv
badd +97 src/synth/system_ram.sv
badd +24 src/synth/video_ram.sv
badd +23 src/sim/bios_rom.sv
badd +19 src/sim/character_rom.sv
badd +6 src/sim/logging.sv
badd +18 src/sim/system_ram.sv
badd +26 src/sim/video_ram.sv
badd +1 src/library/chipset.sv
badd +1 src/sim/pixel_clk_gen.sv
argglobal
%argdel
$argadd src/library/alu.sv
$argadd src/library/board.sv
$argadd src/library/common.sv
$argadd src/library/cpu.sv
$argadd src/library/cpu_csr.sv
$argadd src/library/cpu_ex.sv
$argadd src/library/cpu_id.sv
$argadd src/library/cpu_if.sv
$argadd src/library/cpu_ma.sv
$argadd src/library/cpu_wb.sv
$argadd src/library/regfile.sv
$argadd src/library/segdisplay.sv
$argadd src/library/vga_controller.sv
$argadd src/synth/bios_rom.sv
$argadd src/synth/character_rom.sv
$argadd src/synth/cpu_clk_gen.sv
$argadd src/synth/logging.sv
$argadd src/synth/pixel_clk_gen.sv
$argadd src/synth/system_ram.sv
$argadd src/synth/video_ram.sv
$argadd src/sim/bios_rom.sv
$argadd src/sim/character_rom.sv
$argadd src/sim/cpu_clk_gen.sv
$argadd src/sim/logging.sv
$argadd src/sim/pixel_clk_gen.sv
$argadd src/sim/system_ram.sv
$argadd src/sim/video_ram.sv
edit src/synth/logging.sv
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
if bufexists("src/synth/logging.sv") | buffer src/synth/logging.sv | else | edit src/synth/logging.sv | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 1 - ((0 * winheight(0) + 23) / 46)
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
