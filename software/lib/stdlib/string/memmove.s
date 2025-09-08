.include "string/string.inc"

.section .text

; About:
;   The memmove() function copies byte array arr1 to byte array arr2.
;   Both arrays are assumed to be n bytes long.
; Args:
;   uint8_t* arr1 - first array ptr
;   uint8_t* arr2 - second array ptr
;   uint16_t size - arrays size
; Return:
;   uint8_t res - 0 if both arrays are equal
; C Prototype:
;   uint8_t memmove(uint8_t* arr1, uint8_t* arr2, uint16_t size);
memmove:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 2)  ; arr2 ptr low byte
    ld h, (ix + 3)  ; arr3 ptr high byte
    ld c, (ix + 4)  ; arrs size low byte
    ld b, (ix + 5)  ; arrs size high byte
    ld de, memmove_buffer

    ldir  ; repeats 'ld (de), (hl)' then increments de, hl, and decrements bc until bc=0

    ld e, (ix + 0)  ; arr1 ptr low byte
    ld d, (ix + 1)  ; arr1 ptr high byte
    ld c, (ix + 4)  ; arrs size low byte
    ld b, (ix + 5)  ; arrs size high byte
    ld hl, memmove_buffer

    ldir  ; repeats 'ld (de), (hl)' then increments de, hl, and decrements bc until bc=0

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    pop bc  ; removing arg3
    push hl  ; return address
    exx  ; restoring registers

    ret


.section .bss
; temp workaround before malloc function will exists..
memmove_buffer:
    .skip 256
