.include "drivers/ra6963/ra6963.inc"
.include "assets/build/assets_icons.inc"
.include "hardware/io.inc"

.section .text

; This LCD has an external 32K of RAM
; Also it has an abillity to use an arbitrary 2k block
; for custom characters.
; We need to shrink whole display RAM for separate parts.
; I wanna do this:
;  ___________
; |   0x00A   |
; |           |
; | Text RAM  |
; |           |
; |           |
; |  0x77FF   |
; |-----------|
; |  0x7800   |
; | Ext chars |
; |  0x7FFF   |
;  -----------

ra6963_custom_font_init:
    push af  ; storing af
    push hl  ; storing hl

    ; setting offset register value
    call ra6963_await_cmd_or_data
    ld a, RA6963_OFFSET_REGISTER_VALUE
    out (IO_LCD_DATA_ADDR), a
    call ra6963_await_cmd_or_data
    ld a, 0x00  ; must be a zero according the datasheet
    out (IO_LCD_DATA_ADDR), a
    call ra6963_await_cmd_or_data
    ld a, RA6963_SET_OFFSET_REGISTER
    out (IO_LCD_CMD_ADDR), a

    ; uploading custom font
    ld hl, FONT_WEB_HP_100LX_6X8_SIZE  ; array size
    push hl  ; arg3 of ra6963_memcpy, size
    ld hl, font_web_hp_100lx_6x8_arr  ; array ptr
    push hl  ; arg2 of ra6963_memcpy, src arr
    ; 0x80 - first char of alternate char set, but 0xA3 is a first char of the our font
    ; 8 - each char is 8x8 matrix
    ; in-short, this value should be calculated by formula:
    ; (min font char code - 0x20(display font offset) * 8 (byte per char)) + font start addr
    ld hl, (0x83 * 8) + RA6963_CUSTOM_FONT_START_ADDR  ; disp address
    push hl  ; arg1 of ra6963_memcpy
    call ra6963_memcpy  ; filling

    pop hl  ; restoring hl
    pop af  ; restoring af
    ret
