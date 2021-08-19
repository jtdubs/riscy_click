#!/usr/bin/python3

import sys
import glob
import freetype

def main(font, *args):
    for font in glob.glob("bitmap_fonts/*.FON"):
        face = freetype.Face(font)

        face.load_char('A')
        if face.glyph.bitmap.width != 8 or face.glyph.bitmap.rows != 16 or face.num_glyphs != 257:
            continue

        with open(font + ".mem", "w") as mem:
            print("@0000", file=mem)
            for c in range(0x01, 0x101):
                face.load_char(chr(c))
                bitmap = face.glyph.bitmap.buffer
                for row in bitmap:
                    bits = "".join(reversed([str(((row >> x) & 1)) for x in range(0, 8)]))
                    bits = bits.replace("1", "F")
                    print(bits, file=mem)

if __name__ == "__main__":
    main(sys.argv[1:])
