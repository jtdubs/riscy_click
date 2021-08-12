.file "bios.s"

.equ BIOS_BASE, 0x00000000
.equ RAM_BASE,  0x10000000
.equ VRAM_BASE, 0x20000000
.equ DISPLAY,   0xFF000000
.equ SWITCH,    0xFF000004

.text
.align 4

.globl _start
_start:
    jal csr_test

    # set up constants
    li s1, SWITCH
    li s2, DISPLAY
    li s3, VRAM_BASE
    li s4, RAM_BASE
    li s5, 80
    li s6, 30

    # update display from switch
    lw t0, 0(s1)
    sw t0, 0(s2)

    li s10, 0 # y=0
    li s11, 0 # x=0

vram_loop:
    # char = (y * 80) + x
    slli t1, s10, 6
    slli t3, s10, 4
    add t1, t1, t3
    add t1, t1, s11

    # addr = (y << 7) + x
    slli t2, s10, 7
    add t2, t2, s11
    add t2, t2, s3

    # VRAM[addr] = char
    sb t1, (t2)

    # horizontal loop
    addi s11, s11, 1
    bne  s11, s5, vram_loop

    # vertial loop
    li s11, 0
    addi s10, s10, 1
    bne s10, s6, vram_loop

seg_loop:
    # update display from switch
    lw t0, 0(s1)
    sw t0, 0(s2)
    j seg_loop

csr_test:
    la t0, _trap_handler
    csrw mtvec, t0
    nop
    ebreak
    nop
    ret

.globl _trap_handler
_trap_handler:
    nop
    nop
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    nop
    nop
    mret
