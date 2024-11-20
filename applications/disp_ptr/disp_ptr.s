; Print current value of display address pointer

.include "applications/disp_ptr/disp_ptr.inc"
.include "terminal/terminal.inc"

.section .text

disp_ptr_main:
    ld hl, 16  ; print in hex
    push hl  ; arg2 of putnbr
    ; direferencing display ptr address
    ld hl, ra6963_address_pointer
    ld e, (hl)
    inc hl
    ld d, (hl)

    push de  ; arg1 of putnbr
    call putnbr

    ld hl, 0x0A  ; new line
    push hl
    call terminal_putchar

    ret

.section .rodata

disp_ptr_name:
    .asciz "disp_ptr"
