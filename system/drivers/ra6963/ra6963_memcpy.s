.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

; About:
;    Copy an array pointed by src to ra6963 buffer
; Args:
;   uint16_t addr - start address
;   uint16_t src - start address
;   uint16_t size - src array size
; Return:
;   None
; C Prototype:
;   void ra6963_memcpy(uint16_t addr, uint16_t src, uint16_t size);
ra6963_memcpy:
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

    ld l, (ix + 2)  ; src ptr, low byte
    ld h, (ix + 3)  ; src ptr, high byte
    ld c, (ix + 4)  ; size, low byte
    ld b, (ix + 5)  ; size, high byte
    call ra6963_set_auto_write
    ra6963_memcpy_loop:
        ld a, c  ; loading low byte of size
        or b  ; checking if size == 0
        jr z, ra6963_memcpy_loop_end
        ld a, (hl)  ; loading a byte from array
        call ra6963_await_data_auto_mode_write
        out (IO_LCD_DATA_ADDR), a
        dec bc  ; counting counter-clockwise
        inc hl  ; going to the next byte
        jr ra6963_memcpy_loop
    ra6963_memcpy_loop_end:
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
