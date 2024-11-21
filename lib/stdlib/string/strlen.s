.include "string/string.inc"

.section .text

; About:
;   Returns a string lenght
; Args:
;   unsigned char* str - string ptr
; Return:
;   uint16_t len - string length
; C Prototype:
;   uint16_t strlen(unsigned char* str);
strlen:
    push af  ; storing af
    push ix  ; storing ix
    push de  ; storing de

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; str ptr low byte
    ld h, (ix + 1)  ; str ptr high byte

    ld de, 0  ; string length

    strlen_loop:
        ld a, (hl)  ; loading src string byte
        or a  ; check if current byte is a null-terminator
        jr z, strlen_loop_end  ; break if yes
        inc hl  ; going to the next dst byte
        inc de  ; counting length
        jr strlen_loop  ; looping
    strlen_loop_end:
    ld (ix + 0), e  ; length low byte
    ld (ix + 1), d  ; length high byte

    pop de  ; restoring de
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret
