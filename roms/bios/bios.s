.text

.global _start

_start:
    lw x14, SWITCH
    lw x15, DISPLAY
    lw x14, 0(x14)
    sw x14, 0(x15)
    csrrs x28, instret, x0
    lui x6, 0x1
    slli x28, x28, 0x10
    srli x28, x28, 0x10
    addi x11, x0, 0
    addi x10, x0, 0
    addi x16, x0, 80
    addi x6, x6, -256
    addi x15, x0, 0
    lw x14, VRAM_BASE
    or x12, x10, x15
    add x13, x11, x15
    add x14, x14, x12
    andi x13, x13, 255
    sb x13, 0(x14)
    addi x15, x15, 1
    bne x15, x16, 34
    addi x11, x11, 80
    addi x10, x10, 128
    andi x11, x11, 255
    bne x10, x6, 30
    csrrs x15, instret, x0
    lw x12, RAM_BASE
    slli x15, x15, 0x10
    srli x15, x15, 0x10
    sub x15, x15, x28
    lw x13, SWITCH
    lw x14, DISPLAY
    sw x15, 0(x12)
    lw x15, 0(x13)
    sw x15, 0(x14)
    jal x0, 84

.section .sdata
.align 4

BIOS_BASE:
.dword 0x00000000

RAM_BASE:
.dword 0x10000000

VRAM_BASE:
.dword 0x20000000

DISPLAY:
.dword 0xFF000000

SWITCH:
.dword 0xFF000004
