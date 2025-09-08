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


; About:
;   Draw box of width, height at x,y
; Args:
;   uint8_t x - x coordinate
;   uint8_t y - y coordinate
;   uint8_t width - frame width
;   uint8_t height - frame width
; Return:
;   None
; C Prototype:
;   void ra6963_draw_box(uint8_t x, uint8_t y, uint8_t width, uint8_t height);

ra6963_draw_box:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push bc  ; storing bc

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 4 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 2)  ; loading 'size_x' to a
    or a  ; ix a==0?
    jr z, ra6963_draw_box_size_y_loop_end
    ld b, (ix + 3)  ; loading 'size_y' to b
    ld a, b  ; if b==0?
    or a  ; if b==0?
    jr z, ra6963_draw_box_size_y_loop_end

    ld h, (ix + 1)  ; loading 'y' to h
    ra6963_draw_box_size_y_loop:
        push bc  ; storing bc
        ld b, (ix + 2)  ; loading 'size_x' to b
        ld l, (ix + 0)  ; loading 'x' to l
        ra6963_draw_box_size_x_loop:
            push hl
            call ra6963_set_pixel
            inc l  ; incrementing x
            djnz ra6963_draw_box_size_x_loop
        pop bc  ; restoring bc
        inc h  ; incrementing y
        djnz ra6963_draw_box_size_y_loop
    ra6963_draw_box_size_y_loop_end:

    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; arg1
    pop bc  ; arg2
    push hl  ; return address
    exx  ; restoring registers
    ret
