.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

ra6963_putchar:
    push af  ; storing af
    push de  ; storing de
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 10  ; there is no way to set load sp value to ix, skipping 2 pushed reg pairs and the return pointer
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 0)  ; loading a char to draw

    ; printing a char
    call ra6963_await_cmd_or_data
    out (IO_LCD_DATA_ADDR), a  ; writing a char
    ld a, RA6963_DATA_WRITE_AND_INC_ADDR  ; display address pointer will be incremented
    call ra6963_await_cmd_or_data
    out (IO_LCD_CMD_ADDR), a

    ; storing display address ptr
    ld hl, ra6963_address_pointer  ; loading ptr variable
    ld e, (hl)  ; loading low address byte first
    inc hl  ; giong to next byte
    ld d, (hl)  ; loading high address byte
    inc de  ; incrementing local display address pointer
    res 7, d  ; ra6963 internal address bus width is 15-bit, limitting our variable
    ld (hl), d  ; writing high byte back, hl is already incremented
    dec hl
    ld (hl), e  ; writing low byte back

    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop de  ; restoring de
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; arg1
    push hl  ; return address
    exx  ; restoring registers
    ret
