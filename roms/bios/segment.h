#pragma once

#include <stdint.h>
#include "mmap.h"

static inline uint32_t seg_read  (void);
static inline void     seg_write (uint32_t);

static inline uint32_t seg_read(void) {
    return *PTR_DISPLAY;
}

static inline void seg_write(uint32_t v) {
    *PTR_DISPLAY = v;
}
