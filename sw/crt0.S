.section .text.crt, "ax", @progbits
.global _start

_start:
    la sp, __stack_top

    la a0, __bss_start
    la a1, __bss_end
    bge a0, a1, 2f
1:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, 1b
2:
    call main

halt:
    wfi
    j halt
