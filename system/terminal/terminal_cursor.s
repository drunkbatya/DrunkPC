.include "terminal/terminal.inc"

.section .text

terminal_cursor_newline:
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc
    push af  ; storing a

    ld hl, (terminal_view_area_address)  ; loading loading current view area address
    ld de, TERMINAL_WIDTH
    ld a, (terminal_cursor_coordinates_y)  ; loading y
    inc a  ; adding TERMINAL_WIDTH to terminal_view_area_address one or more times
    ld b, a  ; loading y+1 to b
    terminal_cursor_newline_addr_loop:
        add hl, de
        djnz terminal_cursor_newline_addr_loop
    res 7, h  ; ra6963 internal address bus width is 15-bit, limitting our variable
    push hl
    call ra6963_set_address_pointer

    ld hl, (terminal_cursor_coordinates)  ; loading y, x
    ld l, 0  ; setting x to 0
    inc h  ; incrementing y
    ld a, h  ; loading y to a
    cp TERMINAL_HEIGHT  ; if y < TERMINAL_HEIGHT
    jr c, terminal_cursor_newline_end ; if y < TERMINAL_HEIGHT
    dec h  ; decrementing y (setting to the function entry value)
    call terminal_view_area_scroll_down
terminal_cursor_newline_end:
    ld (terminal_cursor_coordinates), hl  ; writing modified coordinates back
    push hl  ; 1st arg of the ra6963_set_cursor_pointer
    call ra6963_set_cursor_pointer

    pop af  ; restoring af
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    ret

terminal_cursor_right:
    push af  ; storing af
    push hl  ; storing hl

    ld hl, (terminal_cursor_coordinates)  ; loading y, x
    inc l  ; incrementing x
    ld a, l  ; loading x to a
    cp TERMINAL_WIDTH  ; cmparing x (in a) with a TERMINAL_WIDTH
    jr c, terminal_cursor_right_end  ; if x < TERMINAL_WIDTH
terminal_cursor_right_newline:
    ld l, 0  ; setting x to 0
    inc h  ; incrementing y
    ld a, h  ; loading y to a
    cp TERMINAL_HEIGHT  ; if y < TERMINAL_HEIGHT
    jr c, terminal_cursor_right_end ; if y < TERMINAL_HEIGHT
    dec h  ; decrementing y (setting to the function entry value)
    call terminal_view_area_scroll_down
terminal_cursor_right_end:
    ld (terminal_cursor_coordinates), hl  ; writing modified coordinates back
    push hl  ; 1st arg of the ra6963_set_cursor_pointer
    call ra6963_set_cursor_pointer

    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

terminal_cursor_left:
    push af  ; storing af
    push hl  ; storing hl

    ld hl, (terminal_cursor_coordinates)  ; loading y, x
    ld a, l  ; loading x to a
    or a  ; is it zero
    jr z, terminal_cursor_left_line_up  ; if x=0 and we need to jump line up
    dec l  ; decrementing x
    jr terminal_cursor_left_end  ; all done

    terminal_cursor_left_line_up:
    ld a, h  ; loading y to a
    or a  ; is it zero
    jr z, terminal_cursor_left_end_do_nothing  ; if we'r now in zero position, do nothing
    dec h  ; going one line up
    ld a, -1  ; loading (TERMINAL_WIDTH - 1) to x
    add a, TERMINAL_WIDTH  ; loading (TERMINAL_WIDTH - 1) to x
    ld l, a  ; loading x back to l

    terminal_cursor_left_end:
    ld (terminal_cursor_coordinates), hl  ; writing modified coordinates back
    push hl  ; 1st arg of the ra6963_set_cursor_pointer
    call ra6963_set_cursor_pointer

    terminal_cursor_left_end_do_nothing:
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

.section .bss

terminal_cursor_coordinates:
    terminal_cursor_coordinates_x: .skip 1  ; x
    terminal_cursor_coordinates_y: .skip 1  ; y
