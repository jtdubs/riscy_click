#include "interrupt.h"

#define IRQ_BASE 0xFFFF0000

#define PORT_PENDING ((volatile interrupt_t * const)(IRQ_BASE+0x00))
#define PORT_ENABLED ((volatile interrupt_t * const)(IRQ_BASE+0x04))
#define PORT_ACTIVE  ((volatile interrupt_t * const)(IRQ_BASE+0x08))

//
// Interrupt Handlers
//

extern void on_uart_interrupt     (void);
extern void on_keyboard_interrupt (void);
extern void on_switch_interrupt   (void);


//
// Initialization
//

void irq_init(void) {
}


//
// Read & Write
//

interrupt_t irq_get_pending(void) {
    return *PORT_PENDING;
}

interrupt_t irq_get_enabled(void) {
    return *PORT_ENABLED;
}

void irq_set_enabled(interrupt_t mask) {
    *PORT_ENABLED = mask;
}

void irq_enable(interrupt_t i) {
    interrupt_t enabled = *PORT_ENABLED;
    enabled |= i;
    *PORT_ENABLED = enabled;
}

void irq_disable(interrupt_t i) {
    interrupt_t enabled = *PORT_ENABLED;
    enabled &= (~i);
    *PORT_ENABLED = enabled;
}


//
// Wait for Interrupts
//

extern void _global_enable_interrupts  (void);
extern void _global_disable_interrupts (void);

void irq_wait(void) {
    _global_enable_interrupts();
    __asm__ volatile ("wfi");
    _global_disable_interrupts();
}


//
// Interrupt Handler
//

void on_interrupt(void) {
    for (interrupt_t active = *PORT_ACTIVE; active != 0; active = *PORT_ACTIVE) {
        // if ((active & IRQ_UART) == IRQ_UART)
        //     on_uart_interrupt();

        if ((active & IRQ_KEYBOARD) == IRQ_KEYBOARD)
            on_keyboard_interrupt();

        if ((active & IRQ_SWITCHES) == IRQ_SWITCHES)
            on_switch_interrupt();
    }
}
