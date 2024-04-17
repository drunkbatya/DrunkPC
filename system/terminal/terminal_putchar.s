.include "terminal/terminal.inc"
.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

.section .text

; About:
;   Private function: processing new line
terminal_newline:
    
#    push af  ; storing a
#
#    ld a, d  ; loading y to a (due to add instruction limmitations)
#    add a, TERMINAL_LINE_HEIGHT  ; max char height
#    ld e, 0  ; loading init x value
#    ld d, a  ; loading new y to d back (due to add instruction limmitations)
#
#    ld a, d  ; loading y to a
#    ;cp TERMINAL_DISPLAY_HEIGHT - TERMINAL_LINE_HEIGHT  ; comparing 'y' + one line with the visible area
#    jr z, terminal_newline_end  ; if y + one line == max visible area line, skipping
#    jr c, terminal_newline_end  ; if y + one line < visible area, skipping
#
#    push de  ; pushing current coordinates
#    call terminal_process_newline
#    pop de  ; returning new ccordinates
#
#    terminal_newline_end:
#    pop af  ; restoring a
    ret

; About:
;   Puts a char to the terminal
; Args:
;   unsigned char c - char to draw
; Return:
;   None
; C prototype:
;   void terminal_putchar(unsigned char c);
_terminal_putchar:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 0)  ; loading char to draw
    cp 0x0a  ; if new line char, i don't know how to set '\n' char here
    call z, terminal_cursor_newline  ; if char == '\n'
    jr z, terminal_putchar_end  ; if char == '\n'

    ld a, (ix + 0)  ; loading char to draw
    sub RA6963_FONT_OFFSET  ; subtracting font offset from the char code, sets C if borrow
    jr c, terminal_putchar_end  ; returning if char code < RA6963_FONT_OFFSET

    call ra6963_await_cmd_or_data
    out (IO_LCD_DATA_ADDR), a  ; writing a char
    ld a, RA6963_DATA_WRITE_AND_INC_ADDR  ; display address pointer will be incremented
    call ra6963_await_cmd_or_data
    out (IO_LCD_CMD_ADDR), a

    call terminal_cursor_right

    terminal_putchar_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret

