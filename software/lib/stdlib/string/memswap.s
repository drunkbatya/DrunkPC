.include "string/string.inc"

.section .text

; About:
;   Swaps each two bytes in array, useful for endianess converting
; Args:
;   void* arr - array to swap
;   uint16_t size - array size
; Return:
;   None
; C Prototype:
;   void memswap(void* arr, uint16_t size);
memswap:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; arr ptr low byte
    ld h, (ix + 1)  ; arr ptr high byte

    ld c, (ix + 2)  ; size low byte
    ld b, (ix + 3)  ; size high byte

    sra c  ; shift right to divide size by 2
    sra b  ; shift right to divide size by 2

    memswap_loop:
        ld a, c  ; loading size low byte
        or b  ; checking if size is zero
        jr z, memswap_loop_end  ; not found if we'r here and size == 0

        ld a, (hl)  ; loading byte1
        ld e, a  ; storing byte1 to e
        inc hl  ; going to the next arr byte
        ld a, (hl)  ; loading byte2
        ld d, a  ; storing byte2 to d
        ld a, e  ; loading byte1
        ld (hl), a  ; saving byte1 to byte2 pos
        dec hl  ; going to the byte1 pos
        ld a, d  ; loading byte2
        ld (hl), a  ; saving byte2 to byte1 pos

        inc hl  ; incrementing arr ptr
        inc hl  ; incrementing arr ptr againg

        dec bc  ; decrementing size
        jr memswap_loop

    memswap_loop_end:
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
