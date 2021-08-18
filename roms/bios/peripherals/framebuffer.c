#include "framebuffer.h"

#define FB_BASE 0x20000000

#define FB_DATA ((volatile uint32_t * const)(FB_BASE))

//
// Framebuffer Structure
//

#define FB_GET_CHAR(e)      ((uint8_t)(((e) >>  0) & 0xFF))
#define FB_GET_FG_RED(e)    ((uint8_t)(((e) >>  8) & 0x07))
#define FB_GET_FG_GREEN(e)  ((uint8_t)(((e) >> 11) & 0x0F))
#define FB_GET_FG_BLUE(e)   ((uint8_t)(((e) >> 15) & 0x07))
#define FB_GET_BG_RED(e)    ((uint8_t)(((e) >> 18) & 0x07))
#define FB_GET_BG_GREEN(e)  ((uint8_t)(((e) >> 21) & 0x0F))
#define FB_GET_BG_BLUE(e)   ((uint8_t)(((e) >> 25) & 0x07))
#define FB_GET_UNDERLINE(e) ((uint8_t)(((e) >> 28) & 0x01))
#define FB_GET_BLINK(e)     ((uint8_t)(((e) >> 29) & 0x01))

#define FB_SET_CHAR(e, v)      (((e) & 0xFFFFFF00) | (((v) & 0xFF) <<  0))
#define FB_SET_FG_RED(e, v)    (((e) & 0xFFFFF8FF) | (((v) & 0xE0) <<  3))
#define FB_SET_FG_GREEN(e, v)  (((e) & 0xFFFF87FF) | (((v) & 0xF0) <<  7))
#define FB_SET_FG_BLUE(e, v)   (((e) & 0xFFFC7FFF) | (((v) & 0xE0) << 10))
#define FB_SET_BG_RED(e, v)    (((e) & 0xFFE3FFFF) | (((v) & 0x07) << 13))
#define FB_SET_BG_GREEN(e, v)  (((e) & 0xFE1FFFFF) | (((v) & 0x0F) << 17))
#define FB_SET_BG_BLUE(e, v)   (((e) & 0xF1FFFFFF) | (((v) & 0x07) << 20))
#define FB_SET_UNDERLINE(e, v) (((e) & 0xEFFFFFFF) | (((v) & 0x01) << 28))
#define FB_SET_BLINK(e, v)     (((e) & 0xDFFFFFFF) | (((v) & 0x01) << 29))

#define FB_SET_FG(e, r, g, b) \
    (((e) & 0xFFFC00FF)   | \
     (((r) & 0xE0) <<  3) | \
     (((g) & 0xF0) <<  7) | \
     (((b) & 0xE0) << 10))

#define FB_SET_BG(e, r, g, b) \
    (((e) & 0xF003FFFF)   | \
     (((r) & 0xE0) << 13) | \
     (((g) & 0xF0) << 17) | \
     (((b) & 0xE0) << 20))

#define BUILD_CHAR(c, fr, fg, fb, br, bg, bb, u, b) \
    (((c)  & 0xFF) <<  0) | \
    (((fr) & 0xE0) <<  3) | \
    (((fg) & 0xF0) <<  7) | \
    (((fb) & 0xE0) << 10) | \
    (((br) & 0xE0) << 13) | \
    (((bg) & 0xF0) << 17) | \
    (((bb) & 0xE0) << 20) | \
    (((u)  & 0x01) << 28) | \
    (((b)  & 0x01) << 29)

static uint32_t DefaultMode = BUILD_CHAR(
    0,   // character
    255, // fg red
    255, // fg green
    255, // fg blue
    0,   // bg red
    0,   // bg green
    255, // bg blue
    1,   // underline
    1    // blink
);


//
// Initialization
//

void fb_init(void) {
    fb_clear(' ');
}


//
// Character Control
//

void fb_set_blink(bool enable) {
    DefaultMode = FB_SET_BLINK(DefaultMode, enable ? 1 : 0);
}

void fb_set_underline(bool enable) {
    DefaultMode = FB_SET_UNDERLINE(DefaultMode, enable ? 1 : 0);
}

void fb_set_bg_color(uint8_t r, uint8_t g, uint8_t b) {
    DefaultMode = FB_SET_BG(DefaultMode, r, g, b);
}

void fb_set_fg_color(uint8_t r, uint8_t g, uint8_t b) {
    DefaultMode = FB_SET_FG(DefaultMode, r, g, b);
}


//
// Read & Write
//

void fb_clear(char c) {
    for (uint8_t y = 0; y < FrameBufferHeight; y++)
        for (uint8_t x = 0; x < FrameBufferWidth; x++)
            fb_write(x, y, c);
}

char fb_read(uint8_t x, uint8_t y) {
    return FB_GET_CHAR(FB_DATA[y << 7 | x]);
}

void fb_write(uint8_t x, uint8_t y, char c) {
    FB_DATA[y << 7 | x] = FB_SET_CHAR(DefaultMode, c);
}
