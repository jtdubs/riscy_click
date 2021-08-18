#pragma once

#include <stdint.h>

static const uint8_t FrameBufferHeight = 30;
static const uint8_t FrameBufferWidth  = 80;

// Initialization
void fb_init  (void);

// Read & Write
void fb_clear (char c);
char fb_read  (uint8_t x, uint8_t y);
void fb_write (uint8_t x, uint8_t y, char c);
