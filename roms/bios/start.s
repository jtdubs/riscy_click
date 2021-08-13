.file "bios.s"

.include "mmap_defs.s"

.text
.align 4

.globl _start
_start:
    # point all traps at _trap_handler
    la t0, _trap_handler
    csrw mtvec, t0

    # stack starts at top of RAM
    li sp, RAM_TOP

    # main(0, 0)
    li a0, 0
    li a1, 0
    j main

csr_setup:
    ret

.globl _trap_handler
_trap_handler:
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    mret
