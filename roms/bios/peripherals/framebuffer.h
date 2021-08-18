#pragma once

#include <stdint.h>
#include <stdbool.h>

static const uint8_t FrameBufferHeight = 30;
static const uint8_t FrameBufferWidth  = 80;

// Initialization
void      fb_init          (void);

// Character Control
void      fb_set_blink     (bool enable);
void      fb_set_underline (bool enable);
void      fb_set_bg_color  (uint8_t r, uint8_t g, uint8_t b);
void      fb_set_fg_color  (uint8_t r, uint8_t g, uint8_t b);

// Read & Write
void      fb_clear         (char c);
char      fb_read          (uint8_t x, uint8_t y);
void      fb_write         (uint8_t x, uint8_t y, char c);
