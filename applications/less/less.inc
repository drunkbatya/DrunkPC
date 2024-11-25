.include "terminal/terminal.inc"

LESS_BUFFER_SIZE = ((TERMINAL_WIDTH * TERMINAL_HEIGHT) + 1)

LESS_LAST_BYTE_BEFORE_LAST_DISPLAY_LINE_ADDR = TERMINAL_WIDTH * (TERMINAL_HEIGHT - 1)

.global less_main
.global less_name

; vim: ft=asm
