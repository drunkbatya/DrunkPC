.include "string/string.inc"

.section .text

; About:
;   Compare a null-terminated strings
; Args:
;   const unsigned char* str1 - string 1
;   const unsigned char* str2 - string 2
; Return:
;   bool are_equal - true if strings are equal, false otherwise
; C prototype:
;   bool strcmp(const unsigned char* str1, const unsigned char* str2);
strcmp:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix
    push de  ; storing de

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 4 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld e, (ix + 0)  ; str1 ptr low byte
    ld d, (ix + 1)  ; str1 ptr high byte
    ld l, (ix + 2)  ; str2 ptr low byte
    ld h, (ix + 3)  ; str2 ptr high byte

    strcmp_loop:
        ld a, (de)  ; loading str1 string byte
        cp (hl)  ; comparing current str1 and str2 bytes
        jr nz, strcmp_loop_end_not_eq  ; this means string aren't equal
        ld a, (de)  ; loading str1 string byte
        or a  ; check if current byte is a str1 null-terminator
        jr z, strcmp_loop_end_eq  ; break if yes
        inc de  ; going to the next str1 byte
        inc hl  ; going to the next str2 byte
        jr strcmp_loop  ; looping
    strcmp_loop_end_eq:
    ld (ix + 2), 1  ; reached str1 end, strings are equal
    jr strcmp_loop_end

    strcmp_loop_end_not_eq:
    ld (ix + 2), 0  ; return false

    strcmp_loop_end:
    pop de  ; restoring de
    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    push hl  ; return address
    exx  ; restoring registers

    ret
