.file "start.s"

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
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    la sp, __stack_end

    # enable interrupts
enable_interrupts:
    li t0, 0x800
    csrw mie, t0
    li t0, 0x8
    csrw mstatus, t0

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
    sw zero, (t0)
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
    addi sp, sp, -64

    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw t3, 16(sp)
    sw t4, 20(sp)
    sw t5, 24(sp)
    sw t6, 28(sp)
    sw a0, 32(sp)
    sw a1, 36(sp)
    sw a2, 40(sp)
    sw a3, 44(sp)
    sw a4, 48(sp)
    sw a5, 52(sp)
    sw a6, 56(sp)
    sw a7, 60(sp)

    jal on_key

    lw a7, 60(sp)
    lw a6, 56(sp)
    lw a5, 52(sp)
    lw a4, 48(sp)
    lw a3, 44(sp)
    lw a2, 40(sp)
    lw a1, 36(sp)
    lw a0, 32(sp)
    lw t6, 28(sp)
    lw t5, 24(sp)
    lw t4, 20(sp)
    lw t3, 16(sp)
    lw t2, 12(sp)
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)

    addi sp, sp, 64
    mret
