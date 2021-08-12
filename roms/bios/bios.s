.file "bios.s"

.equ BIOS_BASE, 0x00000000
.equ RAM_BASE,  0x10000000
.equ VRAM_BASE, 0x20000000
.equ DISPLAY,   0xFF000000
.equ SWITCH,    0xFF000004
.equ KBD,       0xFF000008

.text
.align 4

.globl _start
_start:
    # jal csr_test

    # set up constants
    li s1, SWITCH
    li s2, DISPLAY
    li s3, VRAM_BASE
    li s4, RAM_BASE
    li s5, 80
    li s6, 30

# vram_loop_setup:
#     li s10, 0 # y=0
#     li s11, 0 # x=0
# 
# vram_loop:
#     # char = (y * 80) + x
#     slli t1, s10, 6
#     slli t3, s10, 4
#     add t1, t1, t3
#     add t1, t1, s11
# 
#     # addr = (y << 7) + x
#     slli t2, s10, 7
#     add t2, t2, s11
#     add t2, t2, s3
# 
#     # VRAM[addr] = char
#     sb t1, (t2)
# 
#     # horizontal loop
#     addi s11, s11, 1
#     bne  s11, s5, vram_loop
# 
#     # vertial loop
#     li s11, 0
#     addi s10, s10, 1
#     bne s10, s6, vram_loop

kbd_setup:
    li s1, KBD
    li t2, 0x10000
    li t3, 0x100

    li s5, 0 # cursor x
    li s6, 0 # cursor y

kbd_loop:
    # get possible keystroke
    lw t0, 0(s1)

    # discard if not valid
    and t1, t0, t2
    beqz t1, kbd_loop

    # write to seven segment display
    sw t0, 0(s2)

    # skip if it's a key break
    and t1, t0, t3
    beqz t1, kbd_loop
    andi t0, t0, 0xFF

    # handle arrow keys
    li t2, 103
    sub t1, t0, t2
    beqz t1, kbd_up
    li t2, 105
    sub t1, t0, t2
    beqz t1, kbd_left
    li t2, 106
    sub t1, t0, t2
    beqz t1, kbd_right
    li t2, 108
    sub t1, t0, t2
    beqz t1, kbd_down
    j kbd_loop

kbd_after_dispatch:
    # addr = (y << 7) + x
    slli t0, s6, 7
    add t0, t0, s5
    add t0, t0, s3

    # VRAM[addr] = char
    li t1, 'X'
    sb t1, (t0)

    # loop
    j kbd_loop

# key handlers
kbd_up:
    li t0, 1
    sub s6, s6, t0
    j kbd_after_dispatch
kbd_down:
    addi s6, s6, 1
    j kbd_after_dispatch
kbd_left:
    li t0, 1
    sub s5, s5, t0
    j kbd_after_dispatch
kbd_right:
    addi s5, s5, 1
    j kbd_after_dispatch

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
