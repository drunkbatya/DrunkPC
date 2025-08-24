.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

.section .text

ra6963_init:
    push af
    push hl

    ;call ra6963_custom_font_init

    ; set text home address
    ld hl, 0
    push hl
    call ra6963_set_text_home_address

    ; set text area
    call ra6963_await_cmd_or_data
    ld a, RA6963_DISPLAY_WIDTH_BYTES
    out (IO_LCD_DATA_ADDR), a
    call ra6963_await_cmd_or_data
    ld a, 0x00
    out (IO_LCD_DATA_ADDR), a
    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_TEXT_AREA
    out (IO_LCD_CMD_ADDR), a

    ; set graphic home addres
    ld hl, 0x2000
    push hl
    call ra6963_set_graphic_home_address

    ; set graphic area
    call ra6963_await_cmd_or_data
    ld a, RA6963_DISPLAY_WIDTH_BYTES  ; TODO: check
    out (IO_LCD_DATA_ADDR), a
    call ra6963_await_cmd_or_data
    ld a, 0x00
    out (IO_LCD_DATA_ADDR), a
    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_GRAPHIC_AREA
    out (IO_LCD_CMD_ADDR), a

    ; set 1 line cursor
    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_8_LINE_CURSOR
    out (IO_LCD_CMD_ADDR), a

    ; mode set
    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_OR_MODE
    out (IO_LCD_CMD_ADDR), a

    ; display mode
    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_TEXT_ON_GRAPHIC_OFF_CURSOR_ON_BLINK_ON
    out (IO_LCD_CMD_ADDR), a

    pop hl
    pop af
    ret
