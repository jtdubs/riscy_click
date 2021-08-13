#pragma once

#include <stdint.h>
#include "mmap.h"

inline uint32_t seg_read  (void);
inline void     seg_write (uint32_t);

inline uint32_t seg_read(void) {
    return *PTR_DISPLAY;
}

inline void seg_write(uint32_t v) {
    *PTR_DISPLAY = v;
}
