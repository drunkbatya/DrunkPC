.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

; About:
;    Fill a ra6963 buffer with a byte value
; Args:
;   uint16_t addr - start address
;   uint16_t size - fill size
;   uint8_t value - value to fill with
; Return:
;   None
; C Prototype:
;   void ra6963_memset(uint16_t addr, uint16_t size, uint8_t value);
ra6963_memset:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push bc  ; storing bc
    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 4 args and return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; address, low byte
    ld h, (ix + 1)  ; address, high byte
    push hl  ; start address
    call ra6963_set_address_pointer

    ld l, (ix + 2)  ; size, low byte
    ld h, (ix + 3)  ; size, high byte
    ld bc, 0  ; to compare hl with
    ld a, (ix + 4)  ; value to fill with
    call ra6963_set_auto_write
    ra6963_memset_loop:
        or a  ; just for clear carry flag
        sbc hl, bc  ; compare with zero (all buffer filled)
        jr z, ra6963_memset_loop_end
        call ra6963_await_data_auto_mode_write
        out (IO_LCD_DATA_ADDR), a
        dec hl  ; going to the next byte
        jr ra6963_memset_loop
    ra6963_memset_loop_end:
    call ra6963_reset_auto_write

    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    pop bc  ; removing arg3
    push hl  ; return address
    exx  ; restoring registers
    ret
