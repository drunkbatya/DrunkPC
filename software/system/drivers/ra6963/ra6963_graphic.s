.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

.section .text

ra6963_graphic_on:
    push af  ; storing af

    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_TEXT_OFF_GRAPHIC_ON_CURSOR_OFF_BLINK_OFF
    out (IO_LCD_CMD_ADDR), a

    pop af  ; restoring af
    ret
