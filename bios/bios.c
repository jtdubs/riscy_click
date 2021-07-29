volatile unsigned int* DISPLAY_BASE = (volatile unsigned int*)0xFF000000;
volatile unsigned int* SWITCH_BASE  = (volatile unsigned int*)0xFF000004;

void _start() {
    for (;;) {
        *DISPLAY_BASE = ~(*SWITCH_BASE);
    }
}
