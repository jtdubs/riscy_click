volatile unsigned int* DISPLAY_BASE = (volatile unsigned int*)0xFF000000;

void _start() {
    *DISPLAY_BASE = 0x2A;
}
