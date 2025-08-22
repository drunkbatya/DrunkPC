.include "terminal/terminal.inc"
.include "drivers/ra6963/ra6963.inc"

terminal_reset:
    push hl  ; storing hl

    call ra6963_clear
    ld hl, 0
    push hl
    call ra6963_set_address_pointer

    ld hl, 0  ; setting cursor to 0
    ld (terminal_cursor_coordinates), hl

    ld (terminal_view_area_address), hl

    pop hl  ; restoring hl
    ret


terminal_init:
    call ra6963_init
    call terminal_reset
    ret

