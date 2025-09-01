.include "string/string.inc"

.section .text

; About:
;   The memcmp() function compares byte array arr1 against byte array arr2.
;   Both arrays are assumed to be n bytes long.
; Args:
;   uint8_t* arr1 - first array ptr
;   uint8_t* arr2 - second array ptr
;   uint16_t size - arrays size
; Return:
;   uint8_t res - 0 if both arrays are equal
; C Prototype:
;   uint8_t memcmp(uint8_t* arr1, uint8_t* arr2, uint16_t size);
memcmp:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld e, (ix + 0)  ; arr1 ptr low byte
    ld d, (ix + 1)  ; arr1 ptr high byte
    ld l, (ix + 2)  ; arr2 ptr low byte
    ld h, (ix + 3)  ; arr3 ptr high byte
    ld c, (ix + 4)  ; arrs size low byte
    ld b, (ix + 5)  ; arrs size high byte

    memcmp_loop:
        ld a, b  ; loading one of the size bytes to a to check if bc==0
        or c  ; check if bc==0
        jr z, memcmp_end_equal  ; if bc==0 assuming both arrays are equal
        ld a, (de)  ; loading arr1 byte
        cpi  ; Multiple instructions combined into one: cp (hl), inc hl, dec bc
        jr nz, memcmp_end_not_equal  ; if bytes are not equal
        inc de  ; incrementing arr1 ptr. arr2 ptr already incremented by cpi
        jr memcmp_loop  ; loop
    memcmp_end_equal:
    ld (ix + 4), 0  ; rewriting stack arg!, returning 0 if both arrays are equal
    jr memcmp_end
    memcmp_end_not_equal:
    dec hl  ; arr2 ptr already incremented by cpi, decrementing it back to compare with arr1 ptr
    sub (hl)  ; a already contains the (de) value, subtracting arr2 byte from the arr1 byte to returm the differance
    ld (ix + 4), a  ; rewriting stack arg!, returning the difference between the first two differing bytes

    memcmp_end:
    ld (ix + 5), 0  ; rewriting stack arg!, dummy byte

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers

    ret
