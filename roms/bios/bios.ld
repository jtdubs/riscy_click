OUTPUT_ARCH(riscv)
ENTRY(_start)

ROM_ADDRESS  = 0x00000000;
ROM_SIZE     = 0x1000;

RAM_ADDRESS  = 0x10000000;
RAM_SIZE     = 0x1000;

STACK_SIZE   = 0x200;

MEMORY
{
    rom   (rx) : ORIGIN = ROM_ADDRESS, LENGTH = ROM_SIZE
    ram   (rw) : ORIGIN = RAM_ADDRESS, LENGTH = RAM_SIZE
}

SECTIONS
{
    . = ROM_ADDRESS;

    .text : {
        . = ALIGN(4);
        PROVIDE(__text_start = .);
        start.o (.text);
        *       (.text);
        *       (.srodata);
        *       (.rodata);
        . = ALIGN(4);
        PROVIDE(__text_end = .);
    } > rom

    . = RAM_ADDRESS;

    PROVIDE(__global_pointer = .);

    .data : {
        . = ALIGN(4);
        PROVIDE(__copy_start = .);
        * (.sdata);
        * (.data);
        . = ALIGN(4);
        PROVIDE(__copy_end = .);
    } > ram AT > rom

    PROVIDE(__copy_source = LOADADDR(.data));

    .bss (NOLOAD) : {
        . = ALIGN(4);
        PROVIDE(__zero_start = .);
        * (.sbss);
        * (.bss);
        . = ALIGN(4);
        PROVIDE(__zero_end = .);
    } > ram

    .stack (NOLOAD) : {
        . = ALIGN(8);
        PROVIDE(__stack_start = .);
        . = . + STACK_SIZE;
        . = ALIGN(8);
        PROVIDE(__stack_end = .);
    } > ram

    PROVIDE(__heap_start = .);
    . = RAM_ADDRESS + RAM_SIZE;
    PROVIDE(__heap_end = .);
}
