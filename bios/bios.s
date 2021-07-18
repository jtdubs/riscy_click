.text
.balign 4
.global _start
.org 0

_start:
    addi x28, x0, 42
    lui x29, 0xFF000
    sw x28, 0(x29)

done:
    j done
