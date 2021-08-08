#!/usr/bin/python3

import sys
import freetype

def main(*args):
    # load the font
    face = freetype.Face("RobotoMono-Regular.ttf")

    # 6pt wide is 1/12" which at 96dpi is  8 pixels
    # 9pt tall is 1/8"  which at 96dpi is 12 pixels
    face.set_char_size(width=10*64, height=10*64, hres=96, vres=96)

    chars = {}

    for c in range(0x00, 0x80):
        # load glyph
        glyph_index = face.get_char_index(c)
        face.load_glyph(glyph_index)

        # get raw pixels
        pixels = face.glyph.bitmap.buffer
        width = face.glyph.bitmap.width
        rows = face.glyph.bitmap.rows
        left = face.glyph.bitmap_left
        top = face.glyph.bitmap_top

        chars[c] = {
            "left": left,
            "width": width,
            "right": (left+width), 
            "top": top,
            "height": rows,
            "bottom": top-rows,
            "bitmap": list(face.glyph.bitmap.buffer)
        }

        chars[c+128] = chars[c]

    top    = max(chars.keys(), key=lambda c: chars[c]["top"])
    bottom = min(chars.keys(), key=lambda c: chars[c]["bottom"])
    left   = min(chars.keys(), key=lambda c: chars[c]["left"])
    right  = max(chars.keys(), key=lambda c: chars[c]["right"])
    width  = max(chars.keys(), key=lambda c: chars[c]["width"])
    height  = max(chars.keys(), key=lambda c: chars[c]["height"])

    # print("Top:    '{0}' ({1}): {2}".format(chr(top), top, chars[top]))
    # print("Bottom: '{0}' ({1}): {2}".format(chr(bottom), bottom, chars[bottom]))
    # print("Left:   '{0}' ({1}): {2}".format(chr(left), left, chars[left]))
    # print("Right:  '{0}' ({1}): {2}".format(chr(right), right, chars[right]))
    # print("Width:  '{0}' ({1}): {2}".format(chr(width), width, chars[width]))
    # print("Height: '{0}' ({1}): {2}".format(chr(height), height, chars[height]))


    left = chars[left]["left"]
    right = chars[right]["right"]
    width = chars[width]["width"]
    if (left < 0 and right > 7) or width > 8:
        raise RuntimeError("chars don't fit horizontally in 8 pixels")
    x_shift = 0
    if left < 0: x_shift = -left
    if right > 7: x_shift = 7-right
    x_shift = -left if left < 0 else 0
    x_shift += int((8 - width) / 2)


    top = chars[top]["top"]
    bottom = chars[bottom]["bottom"]
    height = chars[height]["height"]
    if (bottom - top) > 16:
        raise RuntimeError("chars don't fit vertically in 16 pixels")
    y_shift = 0
    if bottom < 0: y_shift = -bottom
    y_shift += int((16 - height) / 2)

    # print("X shift: ", x_shift)
    # print("Y shift: ", y_shift)


    # print header
    print("@0000")

    for c in chars.keys():
        # print("'{0}' ({1}): {2}".format(chr(c), c, chars[c]))

        ch     = chars[c]
        top    = ch["top"]
        bottom = ch["bottom"]
        left   = ch["left"]
        right  = ch["right"]
        width  = ch["width"]
        height = ch["height"]
        bitmap = ch["bitmap"]

        left_pad = left + x_shift
        right_pad = 8 - (right + x_shift)
        top_pad = 16 - (top + y_shift)
        bottom_pad = bottom + y_shift

        # print("Left pad: ", left_pad)
        # print("Right pad: ", right_pad)
        # print("Top pad: ", top_pad)
        # print("Bottom pad: ", bottom_pad)

        for y in range (0, 16):
            if y < top_pad:
                print("00000000")
            elif y < (top_pad + height):
                for x in range(0, 8):
                    if x < left_pad:
                        print("0", end="")
                    elif x < (left_pad + width):
                        print('{0:1X}'.format(bitmap[(y-top_pad)*width+(x-left_pad)]>>4), end="")
                    else:
                        print("0", end="")
                print()
            else:
                print("00000000")

if __name__ == "__main__":
    main(sys.argv)
