.include "drivers/at28c256/at28c256.inc"

; We never can write a Flash wile executing code from Flash
; so, all flash write code will be located in RAM
.section .data

; About:
;    Copy an array pointed by src to Flash pointed by dst
; Args:
;   uint16_t addr - dst address in flash
;   uint16_t src - src address
;   uint16_t size - src array size
; Return:
;   None
; C Prototype:
;   void at28c256_write_bytes(uint8_t* dst, uint8_t* src, uint16_t size);
at28c256_write_bytes:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 4 args and return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; dst addr, low byte
    ld h, (ix + 1)  ; dst addr, high byte
    ld e, (ix + 2)  ; src addr, low byte
    ld d, (ix + 3)  ; src addr, high byte
    ld c, (ix + 4)  ; size, low byte
    ld b, (ix + 5)  ; size, high byte
    ld (at28c256_write_bytes_last_addr), hl  ; resetting last address
    ; write start
    at28c256_write_bytes_loop:
        ; check is new adress in the same page with the previous
        call is_at28c256_page_is_same
        jr z, at28c256_write_bytes_loop_page_shift_skip  ; writing next byte if true
        call at28c256_poll_d7  ; waiting write cycle end, address+1 in hl, written byte in a
        at28c256_write_bytes_loop_page_shift_skip:
        ld (at28c256_write_bytes_last_addr), hl  ; resetting last address

        ld a, c  ; loading low byte of size
        or b  ; checking if size == 0
        jr z, at28c256_write_bytes_loop_end
        ld a, (de)  ; loading a byte from array
        ld (hl), a  ; flashing byte

        dec bc  ; counting counter-clockwise
        inc hl  ; going to the next byte
        inc de  ; going to the next byte
        jr at28c256_write_bytes_loop
    at28c256_write_bytes_loop_end:
    call at28c256_poll_d7  ; to wait after the last page write
    pop bc  ; restoring bc
    pop de  ; restoring de
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

at28c256_check_is_writable:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; first test byte
    ld a, 0x55
    ld (flash_write_test_byte), a  ; writing flash
    call delay_10_ms_ram  ; wait, without locking on D7, because we don't want a dead lock if flash is RO
    ld a, (flash_write_test_byte)  ; reading back
    cp 0x55  ; is it the same?
    jr nz, at28c256_check_is_writable_false

    ; second test byte
    ld a, 0xAA
    ld (flash_write_test_byte), a  ; writing flash
    call delay_10_ms_ram  ; wait, without locking on D7, because we don't want a dead lock if flash is RO
    ld a, (flash_write_test_byte)  ; reading back
    cp 0xAA  ; is it the same?
    jr nz, at28c256_check_is_writable_false

    ; third test byte
    ld a, 0
    ld (flash_write_test_byte), a  ; writing flash
    call delay_10_ms_ram  ; wait, without locking on D7, because we don't want a dead lock if flash is RO
    ld a, (flash_write_test_byte)  ; reading back
    cp 0  ; is it the same?
    jr nz, at28c256_check_is_writable_false

    jr at28c256_check_is_writable_true

    at28c256_check_is_writable_false:
    ld (ix + 0), 0  ; returning success false
    jr at28c256_check_is_writable_end
    at28c256_check_is_writable_true:
    ld (ix + 0), 1  ; returning success true
at28c256_check_is_writable_end:
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

; About:
;    Do the flash chip erase
; Args:
;   None
; Return:
;   None
; C Prototype:
;   void at28c256_erase(void);
at28c256_erase:
    push af  ; storing af
    push hl  ; storing hl
    push bc  ; storing bc

    ld bc, _flash_size  ; _eflash (end of flash) is defined by linker script
    ld hl, _sflash  ; _sflash (start of flash) is defined by linker script
    ld (at28c256_write_bytes_last_addr), hl  ; resetting last address
    at28c256_erase_loop:
        ; check is new adress in the same page with the previous
        call is_at28c256_page_is_same
        jr z, at28c256_erase_loop_page_shift_skip  ; writing next byte if true
        ld a, 0  ; written byte
        call at28c256_poll_d7  ; waiting write cycle end
        at28c256_erase_loop_page_shift_skip:
        ld (at28c256_write_bytes_last_addr), hl  ; resetting last address

        ld a, b  ; loading one of the size bytes to a to check if bc==0
        or c  ; check if bc==0
        jr z, at28c256_erase_loop_end  ; break if all flash is wiped
        ld (hl), 0  ; flashing byte
        inc hl  ; inrementing flash ptr
        dec bc  ; decrementing size counter
        jr at28c256_erase_loop  ; loop
    at28c256_erase_loop_end:
    ld a, 0  ; written byte
    call at28c256_poll_d7  ; to wait after the last page write
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

; internal!
; Z80 @ 4 MHz: 1 T-state = 0.25 µs → 10 ms = 40 000 T
; Summary: 7 + 15*(7 + (17*146-5) + 4 + 12) + (7 + (17*146-5) + 4 + 7) = 40 002 T ~= 10.0005 ms
delay_10_ms_ram:
    push bc  ; storing bc
    ld c, 16  ; 7T
delay_10_ms_ram_c_loop:
    ld b, 146  ; 7T
delay_10_ms_ram_b_loop:
    nop ; 4T
    djnz delay_10_ms_ram_b_loop  ; 13T (taken), 8T (final)
    dec c  ; 4T
    jr nz, delay_10_ms_ram_c_loop  ; 12T (taken 15 times), 7T (last)
    pop bc  ; restoring bc
    ret

; internal!
; New address in HL, old address in at28c256_write_bytes_last_addr
is_at28c256_page_is_same:
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld c, a  ; storing a, without f

    ld de, (at28c256_write_bytes_last_addr)  ; loading old address

    ; HL := base(new) = (H:L & 0xFFC0)
    ld a, l  ; applying 0xC0 to lower bytes
    and 0xC0
    ld l, a  ; storing it back

    ; DE := base(last) = (D:E & 0xFFC0)
    ld a, e  ; applying 0xC0 to lower bytes
    and 0xC0
    ld e, a

    ; is the same page?
    xor a  ; just to clear the carry flag
    sbc hl, de  ; comparing addressed, z=1 if true

    ld a, c  ; restoring a, without f

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    ret


; internal!
; waits write cycle end
; Address in HL, value in a
at28c256_poll_d7:
    push af  ; storing af
    push de  ; storing de

    dec hl  ; going to the previous byte
    ld e, a  ; loading last written byte original value from a
at28c256_poll_d7_loop:
    ld a, (hl)  ; loading last written byte in page
    xor e  ; xoring the number with theirself is always should be zero, but not for this chip
    and 0x80  ; looking last bit, should be zero if write completed, and 1 overvise
    jr nz, at28c256_poll_d7_loop  ; looping until success
    inc hl  ; going to the next byte

    pop de  ; restoring de
    pop af  ; restoring af
    ret

.section .rodata
; this section will go to Flash
; we will try to write this byte
; to ensure the flash is writable
flash_write_test_byte:
    .byte 0x00, 0x00

.section .bss
at28c256_write_bytes_last_addr:
    .skip 2
