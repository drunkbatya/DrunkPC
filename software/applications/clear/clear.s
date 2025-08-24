; clear screen

.include "applications/clear/clear.inc"
.include "terminal/terminal.inc"

.section .text

clear_main:
    call terminal_reset

    ret

.section .rodata

clear_name:
    .asciz "clear"
