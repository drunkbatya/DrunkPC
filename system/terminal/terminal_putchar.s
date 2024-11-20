.include "terminal/terminal.inc"
.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

.section .text

; About:
;   Puts a char to the terminal
; Args:
;   unsigned char c - char to draw
; Return:
;   None
; C prototype:
;   void terminal_putchar(unsigned char c);
terminal_putchar:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 0)  ; loading char to draw
    cp 0x0a  ; if new line char, i don't know how to set '\n' char here
    call z, terminal_cursor_newline  ; if char == '\n'
    jr z, terminal_putchar_end  ; if char == '\n'

    ld a, (ix + 0)  ; loading char to draw
    sub RA6963_FONT_OFFSET  ; subtracting font offset from the char code, sets C if borrow
    jr c, terminal_putchar_end  ; returning if char code < RA6963_FONT_OFFSET

    ld l, a  ; loading a prepared char to draw
    push hl
    call ra6963_putchar

    call terminal_cursor_right

    terminal_putchar_end:
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    push hl  ; return address
    exx  ; restoring registers
    ret

