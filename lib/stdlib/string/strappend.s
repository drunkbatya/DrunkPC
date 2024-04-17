.include "string/string.inc"

.section .text

; About:
;   Append char c to the end of the string pointed by dst
; Args:
;   unsigned char* dst - destination string ptr
;   unsigned char c - char
; Return:
;   None
; C Prototype:
;   void strappend(unsigned char* dst, unsigned char c);
strappend:
    push af  ; storing af
    push ix  ; storing ix
    push de  ; storing de

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld e, (ix + 0)  ; dst ptr low byte
    ld d, (ix + 1)  ; dst ptr high byte
    ld l, (ix + 2)  ; src ptr low byte
    ld h, (ix + 3)  ; src ptr high byte

    append_to_string_loop:
        ld a, (de)  ; loading src string byte
        or a  ; check if current byte is a null-terminator
        jr z, append_to_string_loop_end  ; break if yes
        inc de  ; going to the next dst byte
        jr append_to_string_loop  ; looping
    append_to_string_loop_end:
    ld a, (ix + 2)  ; loading char c
    ld (de), a  ; appending to the dst string
    inc de  ; going to the next dst byte to set a null-terminator
    ld a, 0  ; null-terminator
    ld (de), a  ; setting a null-terminator

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
