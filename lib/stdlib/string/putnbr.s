.include "string/string.inc"
.include "stdlib/core/core.inc"

.section .text

; About:
;   Writes a character representation of unsigned 16-bit integer to terminal
; Args:
;   uint16_t number - number to write
;   uint8_t base - number base
; Return:
;   None
; C prototype:
;   void putnbr(uint16_t number, uint8_t base);
putnbr:
    push ix  ; storing ix
    push hl  ; storing hl

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 2 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 2)  ; loading base
    ld h, 0  ; base type uint8_t
    push hl  ; 3rd arg of itoa - base
    ld hl, putnbr_buffer
    push hl  ; 2nd arg of itoa - buffer
    ld l, (ix + 0)  ; loading string pointer
    ld h, (ix + 1)  ; loading string pointer
    push hl  ; 1st arg of itoa - number
    call itoa

    ld hl, putnbr_buffer
    call putstr

    pop hl  ; restoring hl
    pop ix  ; restoring ix

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers
    ret


.section .bss

putnbr_buffer:
    .skip 6  ; max len 65536 + '\0'
