.PHONY: all clean

all: crom1.mem crom2.mem crom3.mem crom4.mem

clean:
	rm *.mem

crom1.mem: generate_bitmap_fonts.py
	./generate_bitmap_fonts.py bitmap_fonts/Bm437_IBM_VGA_9x16.FON > crom1.mem

crom2.mem: generate_bitmap_fonts.py
	./generate_bitmap_fonts.py bitmap_fonts/Bm437_PhoenixVGA_9x16.FON > crom2.mem

crom3.mem: generate_bitmap_fonts.py
	./generate_bitmap_fonts.py bitmap_fonts/Bm437_Trident_9x16.FON > crom3.mem

crom4.mem: generate_bitmap_fonts.py
	./generate_bitmap_fonts.py bitmap_fonts/Bm437_ATI_9x16.FON > crom4.mem
