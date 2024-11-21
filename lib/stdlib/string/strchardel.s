.include "string/string.inc"

.section .text

; About:
;   Remove a char from string at position, shifts string left
; Args:
;   unsigned char* str - string ptr
;   uint16_t position - position of char to remove
; Return:
;   None
; C Prototype:
;   void strchardel(unsigned char* str, uint16_t position);
strchardel:
    push af  ; storing af
    push ix  ; storing ix
    push de  ; storing de

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; str ptr low byte
    ld h, (ix + 1)  ; str ptr high byte
    ld e, (ix + 2)  ; position low byte
    ld d, (ix + 3)  ; position high byte

    strchardel_loop:
        ld a, (hl)  ; loading src string byte
        or a  ; check if current byte is a null-terminator
        jr z, strchardel_loop_end  ; break if yes
        ; check if poisition is a zero
        ld a, e  ; loading low position byte to a
        or d  ; check if zero
        jr z, strchardel_loop_allow_shift
        inc hl  ; going to the next dst byte
        dec de  ; counting position down
        jr strchardel_loop  ; looping
        strchardel_loop_allow_shift:
            ; if we counted for target remove position
            ; shifting all chars left
            inc hl  ; going to next byte
            ld a, (hl)  ; loading it
            dec hl  ; moving ptr byte back
            ld (hl), a  ; loading next byte to current
            inc hl  ; going to next byte
            jr strchardel_loop  ; looping
    strchardel_loop_end:
    pop de  ; restoring de
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers

    ret
