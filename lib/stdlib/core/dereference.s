.include "core/core.inc"

.section .text

; About:
;   Direfirances uint16_t number in ptr
; Args:
;   void* ptr - ptr to number
; Return:
;   uint16_t number
; C Prototype:
;   uint16_t dereference_uint16(void* ptr);
dereference_uint16:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; ptr low byte
    ld h, (ix + 1)  ; ptr high byte
    ld a, (hl)  ; loading low byte of number
    ld (ix + 0), a  ; pos ptr low byte
    inc hl  ; going to the next byte
    ld a, (hl)  ; loading high byte of number
    ld (ix + 1), a  ; pos ptr high byte

    dereference_uint16_loop_end:
    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret
