.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

.section .text

; sets pixel in specified coordinates (y, x)
; Args:
;   x - 8 bit (ix + 0) c
;   y - 8 bit (ix + 1) b
ra6963_set_pixel:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld hl, RA6963_GRAPHIC_RAM_START_ADDR  ; display address pointer
    ld b, (ix + 1)  ; loading 'y' to a
    ld a, b  ; loading y to a
    or a  ; check if 'y' is 0
    jr z, ra6963_set_pixel_multiply_loop_end  ; skip multiplying if 'y' is 0
    ld de, RA6963_DISPLAY_WIDTH_BYTES  ; how many bytes in one 'y'?
    ra6963_set_pixel_multiply_loop:
        add hl, de
        djnz ra6963_set_pixel_multiply_loop  ; adding display width in bytes to addr 'y' times
    ra6963_set_pixel_multiply_loop_end:  ; now we have calculated 'y' offset in hl
    ld a, (ix + 0)  ; loading 'x' in a
    ld b, 6  ; we don't need 'y' value anymore
    ra6963_set_pixel_divide_loop:
        cp b  ; compairing 'x' in a with 8 (bits in byte) in b
        jr c, ra6963_set_pixel_divide_loop_end ; if x < 8, reminder in a, division ended
        inc hl  ; add one more byte to address
        sub b  ; subtracting 8 bits from 'x' (in a), keep going
        jr ra6963_set_pixel_divide_loop
    ra6963_set_pixel_divide_loop_end:
    push hl  ; setting integer part of address to display
    call ra6963_set_address_pointer

    call ra6963_await_cmd_or_data
    ld b, a  ; we need to invert the reminder
    ld a, 5  ; invert = 5 (max reminder value) - reminder
    sub b  ; 5 (in a) - reminder -> a
    add a, RA6963_SET_BIT  ; setting target bit (division reminder)
    out (IO_LCD_CMD_ADDR), a  ; executing SET BIT lcd instruction

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; arg1
    push hl  ; return address
    exx  ; restoring registers
    ret  ; fuf, going home
