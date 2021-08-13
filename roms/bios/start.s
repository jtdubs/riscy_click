.file "bios.s"

# externs from the linker
.extern __text_start
.extern __text_end
.extern __copy_start
.extern __copy_end
.extern __copy_source
.extern __zero_start
.extern __zero_end
.extern __stack_start
.extern __stack_end
.extern __heap_start
.extern __heap_end

.text
.align 4

.globl _start
_start:

setup_traps:
    # point all traps at _trap_handler
    la t0, _trap_handler
    csrw mtvec, t0

    # set pointers
set_pointers:
    la sp, __stack_end
    la gp, __global_pointer

    # copy r/w data to RAM
copy_start:
    la t0, __copy_start
    la t1, __copy_end
    la t2, __copy_source
copy_loop:
    beq t0, t1, zero_start
    lw t3, (t2)
    sw t3, (t0)
    addi t0, t0, 4
    addi t2, t2, 4
    j copy_loop

    # zero reserved portion of RAM
zero_start:
    la t0, __zero_start
    la t1, __zero_end
zero_loop:
    beq t0, t1, zero_done
    sw zero, (t2)
    addi t0, t0, 4
    j zero_loop
zero_done:

    # call main(0, 0)
call_main:
    li a0, 0
    li a1, 0
    j main

    # main exited... loop forever
exit_loop:
    j exit_loop

.globl _trap_handler
_trap_handler:
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    mret
