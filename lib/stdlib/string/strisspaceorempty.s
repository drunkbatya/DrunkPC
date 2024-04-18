.include "string/string.inc"

; About:
;   Return true if given string only cosists of space or empty
; Args:
;   const char* str - a null-terminated string
; Return:
;   bool - return true if given string only cosists of space or empty
; C Prototype:
; bool strisspaceorempty(const char* str);
strisspaceorempty:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push bc  ; storing bc

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix + 0)  ; loading string pointer
    ld h, (ix + 1)  ; loading string pointer
    strisspaceorempty_loop:
        ld a, (hl)  ; loading byte to draw
        or a  ; check if zero (null-terminator)
        jr z, strisspaceorempty_loop_end_true  ; if we reached EOS before catch any char

        ld c, ' '  ; space
        or a  ; char is a space?
        jr nz, strisspaceorempty_loop_end_false  ; if current char not a space and not null-terminator, returning false

        inc hl
        jr strisspaceorempty_loop
    strisspaceorempty_loop_end_true:
    ld (ix + 0), 1
    jr strisspaceorempty_end

    strisspaceorempty_loop_end_false:
    ld (ix + 0), 0

    strisspaceorempty_end:
    ld (ix + 1), 0  ; dummy byte
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret
