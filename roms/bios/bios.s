.text
.globl  _start

_start:
    # set up constants
    lw x14, SWITCH
    lw x15, DISPLAY
    lw x4,  VRAM_BASE
    lw x5,  RAM_BASE
    addi x6, x0, 80
    addi x7, x0, 30

    # update display from switch
    lw x16, 0(x14)
    sw x16, 0(x15)

    addi x10, x0, 0 # y=0
    addi x11, x0, 0 # x=0

vram_loop:
    # char = (y * 64) + x
    slli x12, x10, 6
    add x12, x12, x10

    # addr = (y << 7) + x
    addi x13, x10, 7
    add x13, x13, x11
    add x13, x13, x4

    # VRAM[addr] = char
    sb x12, (x13)

    # horizontal loop
    addi x11, x11, 1
    bne  x11, x6, vram_loop

    # vertial loop
    addi x11, x0, 0
    addi x10, x10, 1
    bne x10, x7, vram_loop

seg_loop:
    # update display from switch
    lw x16, 0(x14)
    sw x16, 0(x15)
    jal x0, seg_loop


.align 4
.section .sdata

.globl BIOS_BASE
BIOS_BASE:
.word 0x00000000

.globl RAM_BASE
RAM_BASE:
.word 0x10000000

.globl VRAM_BASE
VRAM_BASE:
.word 0x20000000

.globl DISPLAY
DISPLAY:
.word 0xFF000000

.globl SWITCH
SWITCH:
.word 0xFF000004
