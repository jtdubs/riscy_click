volatile unsigned int*  BIOS_BASE  = (volatile unsigned int*)0x00000000;
volatile unsigned int*  RAM_BASE   = (volatile unsigned int*)0x10000000;
volatile unsigned char* VRAM_BASE  = (volatile unsigned char*)0x20000000;
volatile unsigned int*  DISPLAY    = (volatile unsigned int*)0xFF000000;
volatile unsigned int*  SWITCH     = (volatile unsigned int*)0xFF000004;

void _start() {
    for (unsigned short y=0; y<480; y++) {
        for (unsigned short x=0; x<640; x++) {
            VRAM_BASE[(y << 7) | x] = (x ^ y);
        }
    }

    for (;;) {
        *DISPLAY = ~(*SWITCH);
    }
}
