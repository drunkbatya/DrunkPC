.include "string/string.inc"

.section .text

; About:
;   Gets a ptr of last occurance of char c in string str, not more than n bytes
; Args:
;   const void* str - string ptr, null-terminator isn't required
;   char c - char to find
;   uint16_t size - intterate not more than n bytes of string
; Return:
;   const char* pos - ptr to the last occurance of char in str,
;       NULL if not found
; C Prototype:
;   const void* memrchr(unsigned char* str, char c, uint16_t size);
memrchr:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; str ptr low byte
    ld h, (ix + 1)  ; str ptr high byte

    ld e, (ix + 2)  ; char to find

    ld c, (ix + 4)  ; size low byte
    ld b, (ix + 5)  ; size high byte

    add hl, bc  ; adding size to the string ptr, to find from the end

    memrchr_loop:
        ld a, c  ; loading size low byte
        or b  ; checking if size is zero
        jr z, memrchr_loop_char_not_found  ; not found if we'r here and size == 0

        ld a, (hl)  ; loading src string byte
        cp e  ; comparing a char with current str char (in e)
        jr z, memrchr_loop_char_found  ; return ptr to current char if found

        dec bc  ; decrementing size
        dec hl  ; incrementing str ptr
        jr memrchr_loop

    memrchr_loop_char_not_found:
    ld (ix + 4), 0  ; pos ptr low byte, NULL ptr
    ld (ix + 5), 0  ; pos ptr high byte, NULL ptr
    jr memrchr_loop_end

    memrchr_loop_char_found:
    ld (ix + 4), l  ; pos ptr low byte
    ld (ix + 5), h  ; pos ptr high byte

    memrchr_loop_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers

    ret
