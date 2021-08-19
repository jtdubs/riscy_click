#!/usr/bin/python3

import sys
import glob
import freetype

def main(font, *args):
    face = freetype.Face(font)

    face.load_char('A')
    if face.glyph.bitmap.width not in [8, 9] or face.glyph.bitmap.rows != 16 or face.num_glyphs != 257:
        return

    print("@0000")
    for c in range(0x01, 0x101):
        face.load_char(chr(c))
        bitmap = face.glyph.bitmap.buffer

        if len(bitmap) == 32:
            bitmap = [(bitmap[n] | (bitmap[n+1] << 8)) for n in range(0, 32, 2)]

        for row in bitmap:
            a = "{0:X}".format((row >> 0) & 0xF)
            b = "{0:X}".format((row >> 4) & 0xF)
            c = "{0:X}".format((row >> 8) & 0xF)
            print(c+b+a)

if __name__ == "__main__":
    main(*sys.argv[1:])
