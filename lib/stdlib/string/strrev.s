.include "string/string.inc"

.section .text

; About:
;   Reverse a null-terminated string
; Args:
;   unsigned char* str - string to reverse
; Return:
;   None, but string will be reversed
; C prototype:
;   void strrev(unsigned char* str);
strrev:
    push af  ; storing af
    push ix  ; storing ix
    push de  ; storing de
    push hl  ; storing hl
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld c, (ix + 0)  ; loading string pointer
    ld b, (ix + 1)  ; loading string pointer
    ld hl, 0  ; because we can't `ld hl, bc`
    add hl, bc  ; loading string start to hl
    ; finding string lenght
    strrev_strlen_loop:
        ld a, (hl)  ; loading string byte
        or a  ; check if zero (null-terminator)
        jr z, strrev_strlen_loop_end
        inc hl  ; incrementing end string pointer
        jr strrev_strlen_loop
    strrev_strlen_loop_end:  ; now string start in bc, string end in hl
    ; check if string length is zero
    or a  ; just clear carry flag
    sbc hl, bc  ; subtracting string start from string end to check is string lenght is 0
    add hl, bc  ; reverting previous instruction back
    jr z, strrev_end  ; if string start and string end is equal (string length is zero), returning
    dec hl  ; decrementing string end by 1 to drop string null terminator
    strrev_loop:
        ; check if start string ptr less than end
        or a  ; just clear carry flag
        sbc hl, bc  ; subtracting string start from string end
        add hl, bc  ; reverting previous instruction back
        jr c, strrev_end  ; if string start > string end (how?), done
        jr z, strrev_end  ; if string start == string end, done
        ld e, (hl)  ; loading byte from end of string
        ld a, (bc)  ; loading byte from start of string
        ld (hl), a  ;  byte from end of string now taken from start of string
        ld a, e  ; loading byte from end of string to a (due to ld instruction limitations)
        ld (bc), a  ; byte from start of string now taken from end of string
        dec hl  ; decrementing end of string pointer
        inc bc  ; incrementing start of string pointer
        jr strrev_loop
    strrev_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop de  ; restoring de
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    push hl  ; return address
    exx  ; restoring registers
    ret

