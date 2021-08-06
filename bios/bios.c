volatile unsigned int*  BIOS_BASE  = (volatile unsigned int* )0x00000000;
volatile unsigned int*  RAM_BASE   = (volatile unsigned int* )0x10000000;
volatile unsigned char* VRAM_BASE  = (volatile unsigned char*)0x20000000;
volatile unsigned int*  DISPLAY    = (volatile unsigned int* )0xFF000000;
volatile unsigned int*  SWITCH     = (volatile unsigned int* )0xFF000004;

void _start() {
    *DISPLAY = *SWITCH;

    unsigned short ret_before = 0;
    asm volatile ("rdinstret %0" : "=r" (ret_before) );

    for (unsigned short y=0; y<30; y++) {
        for (unsigned short x=0; x<80; x++) {
            VRAM_BASE[(y << 7) | x] = (unsigned char)(x + (y*80));
        }
    }

    unsigned short ret_after = 0;
    asm volatile ("rdinstret %0" : "=r" (ret_after) );

    RAM_BASE[0] = ret_after - ret_before;

    for (;;) {
        *DISPLAY = *SWITCH;
    }
}
