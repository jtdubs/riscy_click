#pragma once

#include <stdint.h>
#include <stdbool.h>

// Initialization
void     dsp_init        (void);

// Enable & Disable
void     dsp_enable      (void);
void     dsp_disable     (void);
void     dsp_set_enabled (bool enabled);

// Read & Write
void     dsp_clear       (char c);
uint32_t dsp_read        (void);
void     dsp_write       (uint32_t value);
