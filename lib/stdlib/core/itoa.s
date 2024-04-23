.include "stdlib/core/core.inc"

.section .text

; About:
;   Writes a character representation of unsigned 16-bit integer to buffer
; Args:
;   uint16_t number - number to convert
;   unsigned char *buffer - buffer to write a character representation, must be less than 5 bytes
;   uint8_t base - base (8, 10, 16, etc)
; Return:
;   None, but number character representation will be written to buffer
; C prototype:
;   void itoa(uint16_t number, unsigned char *buffer, uint8_t base);
itoa:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 0)  ; loading char to draw

    itoa_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    pop bc  ; removing arg3
    push hl  ; return address
    exx  ; restoring registers
    ret

