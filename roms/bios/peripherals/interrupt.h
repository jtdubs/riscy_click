#pragma once

#include <stdint.h>

// External Interrupts
typedef enum {
    IRQ_UART     = 0x00000001,
    IRQ_KEYBOARD = 0x00000002,
    IRQ_SWITCHES = 0x00000004
} interrupt_t;

// Initialization
void        irq_init        (void);

// Read & Write
interrupt_t irq_get_pending (void);
interrupt_t irq_get_enabled (void);
void        irq_set_enabled (interrupt_t mask);
void        irq_enable      (interrupt_t i);
void        irq_disable     (interrupt_t i);

// Wait for Interrupts
void        irq_wait        (void);

// Primary Interrupt Handler
void        on_interrupt    (void);
