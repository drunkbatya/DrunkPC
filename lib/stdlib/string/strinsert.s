.include "string/string.inc"

.section .text

; About:
;   Insert char c to the specified position of the string pointed by dst
; Args:
;   unsigned char* dst - destination string ptr
;   uint16_t - position
;   unsigned char c - char
; Return:
;   None
; C Prototype:
;   void strinsert(unsigned char* dst, uint16_t position, unsigned char c);
strinsert:
    push af  ; storing af
    push hl  ; storing hl
    push bc  ; storing bc
    push ix  ; storing ix
    push de  ; storing de

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; str ptr low byte
    ld h, (ix + 1)  ; str ptr high byte

    ; getting str length
    push hl  ; arg1 of strlen
    call strlen
    pop bc  ; string length

    ; loading string start pointer + position to de
    ld e, (ix + 2)  ; position low byte
    ld d, (ix + 3)  ; position high byte
    add hl, de  ; string start + position
    push hl  ; ld de, hl
    pop de  ; ld de, hl

    ; loading string end
    ld l, (ix + 0)  ; str ptr low byte
    ld h, (ix + 1)  ; str ptr high byte
    add hl, bc  ; str base + str len = string end

    ; EOS now in in hl, shiftng all str one byte right
    strinsert_loop:
        ld a, (hl)  ; loading last char
        inc hl  ; going to the next
        ld (hl), a  ; shifting char one right
        dec hl  ; going to current
        or a  ; just clear carry flag
        sbc hl, de  ; comparing current address with start string address
        add hl, de  ; reverting previous command
        jr z, strinsert_loop_end  ; if current address == str start address
        dec hl  ; irrerating counter-clockwise
        jr strinsert_loop
    strinsert_loop_end:
    ; inserting requested char to the position
    push de  ; ld hl, de
    pop hl  ; ld hl, de
    ld a, (ix + 4)  ; loading char c
    ld (hl), a  ;  inserting requested char to the position

    pop de  ; restoring de
    pop ix  ; restoring ix
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    pop bc  ; removing arg3
    push hl  ; return address
    exx  ; restoring registers

    ret
