.include "terminal/terminal.inc"
.include "drivers/ra6963/ra6963.inc"

_terminal_init:
    push hl  ; storing hl

    call ra6963_init
    call ra6963_clear
terminal_reset:
    ld hl, 0
    push hl
    call ra6963_set_address_pointer

    ld hl, 0  ; ; setting cursor to 0
    ld (terminal_cursor_coordinates), hl

    pop hl  ; restoring hl
    ret
