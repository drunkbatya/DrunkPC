.include "terminal/terminal.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "string/string.inc"
.include "keyboard/keyboard_codes.inc"
.include "drivers/ra6963/ra6963.inc"

.section .text

kutakbash_get_input_string:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push bc  ; add one more arg cause functions recives none and returns 1 arg
    push hl  ; pushing return pointer back
    exx  ; restroing register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld hl, kutakbash_local_cursor_position  ; resseting cursor position
    ld (hl), 0  ; resseting cursor position

    ld hl, kutakbash_input_string_buffer  ; resseting input buffer
    ld (hl), 0  ; setting null-terminator to position 0

    ld de, (ra6963_address_pointer)  ; remembering current display ptr
    ld (kutakbash_display_ptr_at_start), de  ; loading ptr to mem to store it

    ld de, kutakbash_input_string_buffer  ; buffer add to

    kutakbash_get_input_string_loop:
        call keyboard_get_key  ; reading keyboard
        pop hl  ; return char code
        ld a, l  ; loading byte
        or a  ; if it zero?
        jr z, kutakbash_get_input_string_loop
        ; not zero char
        ; check new line
        ld h, 0x0A  ; new line char
        cp h  ; if current char (in a) is a new line?
        jr z, kutakbash_get_input_string_new_line
        ; check backspace
        ld h, 0x08  ; backspace char
        cp h  ; if current char (in a) is a backspace?
        jr z, kutakbash_get_input_string_backspace
        ; check left arrow
        ld h, KBD_LEFT  ; left arrow key
        cp h  ; if current char (in a) is a left arrow key?
        jr z, kutakbash_get_input_string_left_arrow
        ; check right arrow
        ld h, KBD_RIGHT  ; right arrow key
        cp h  ; if current char (in a) is a right arrow key?
        jr z, kutakbash_get_input_string_right_arrow
        ; check SIGINT
        ld h, KBD_CTRL_C  ; Control+C
        cp h  ; if current char (in a) is a Control+C?
        jr z, kutakbash_get_input_string_control_c
        ; another printable char, adding to the input buffer
        push hl  ; storing hl

        ; preparing position to send to the strappend
        ld hl, (kutakbash_local_cursor_position)
        push hl  ; ld bc, hl
        pop bc  ; ld bc, hl

        pop hl  ; restoring hl

        push hl  ; arg3 of the append_to_string function, printable char in l
        push bc  ; arg2 of the strappend function, position to append
        push de  ; arg1 of the append_to_string function, pointer to the dst string
        call strappend  ; appending char to a null-terminated string
        push hl  ; new line char in l
        call terminal_putchar  ; print appended char directly

        ld hl, kutakbash_local_cursor_position  ; inc cursor position
        inc (hl)  ; inc cursor position

        ; Clear screen..
        ; redraw string
        jr kutakbash_get_input_string_loop
    kutakbash_get_input_string_backspace:
    call kutakbash_process_backspace
    jr kutakbash_get_input_string_loop  ; going back to loop
    kutakbash_get_input_string_left_arrow:
    call kutakbash_process_left
    jr kutakbash_get_input_string_loop  ; going back to loop
    kutakbash_get_input_string_right_arrow:
    call kutakbash_process_right
    jr kutakbash_get_input_string_loop  ; going back to loop
    kutakbash_get_input_string_control_c:
    ld hl, kutakbash_input_control_c_str  ; loading ctr+c mark str
    push hl  ; 1arg of putstr function
    call putstr
    jr kutakbash_get_input_string_return_false
    kutakbash_get_input_string_new_line:
    ld l, 0x0A  ; new line char
    push hl  ; new line char in l
    call terminal_putchar  ; print new line character directly without adding it to the buffer

    kutakbash_get_input_string_return_true:
    ld (ix + 0), 1  ; true
    jr kutakbash_get_input_string_end

    kutakbash_get_input_string_return_false:
    ld (ix + 0), 0  ; false

    kutakbash_get_input_string_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

kutakbash_redraw_input_string:
    push af  ; storing af
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld de, (kutakbash_display_ptr_at_start)  ; loading ptr to mem to store it
    ld hl, (ra6963_address_pointer)  ; remembering current display ptr
    or a  ; just clear a carry flag
    sbc hl, de  ; subtracting kutakbash_display_ptr_at_start from ra6963_address_pointer to get size
    jr z, kutakbash_redraw_input_string_end  ; do nothing if size == 0
    jr c, kutakbash_redraw_input_string_end  ; do nothing if size < 0

    ld bc, 0  ; cleared screen value
    push bc  ; third arg of the ra6963_memset
    push hl  ; second  arg of the ra6963_memset
    push de  ; first arg of the ra6963_memset

    call ra6963_memset  ; cleared all printed space

    push de  ; start address pointer
    call ra6963_set_address_pointer  ; resetting address ptr after memset

    ld hl, kutakbash_input_string_buffer  ; loading user string
    kutakbash_redraw_input_string_loop:
        ld a, (hl)  ; loading a char
        or a  ; check null-terminator
        jr z, kutakbash_redraw_input_string_end
        sub RA6963_FONT_OFFSET  ; subtracting font offset from the char code, sets C if borrow
        ld c, a  ; loading char to draw
        push bc  ; arg1 of ra6963_putchar
        call ra6963_putchar
        inc hl  ; str++
        jr kutakbash_redraw_input_string_loop
    kutakbash_redraw_input_string_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop af  ; restoring af

    ret

kutakbash_process_right:
    push hl  ; storing hl
    push bc  ; storing bc

    push de  ; input string ptr
    call strlen
    pop bc  ; string length

    ld hl, (kutakbash_local_cursor_position)  ; loading cursor position

    or a  ; just clear carry flag
    sbc hl, bc  ; comparing base with number
    add hl, bc  ; reverting previous command
    jr nc, kutakbash_process_right_end  ; if cursor position >= str length

    inc hl  ; incrementing position
    ld (kutakbash_local_cursor_position), hl  ; saving new position

    call terminal_cursor_right

    kutakbash_process_right_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl

    ret

kutakbash_process_left:
    push hl  ; storing hl
    push bc  ; storing bc

    push de  ; input string ptr
    call strlen
    pop bc  ; string length

    ld a, c  ; loading string length low byte
    or b  ; check if string length == 0
    jr z, kutakbash_process_left_end  ; do nothing if true

    ld hl, (kutakbash_local_cursor_position)  ; loading cursor position
    ld a, l ; loading position low byte
    or h  ; check if position == 0
    jr z, kutakbash_process_left_end  ; do nothing if true

    dec hl  ; decrementing position
    ld (kutakbash_local_cursor_position), hl  ; saving new position

    call terminal_cursor_left

    kutakbash_process_left_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl

    ret

kutakbash_process_backspace:
    push hl  ; storing hl
    push bc  ; storing bc

    push de  ; input string ptr
    call strlen
    pop bc  ; string length

    ld a, c  ; loading string length low byte
    or b  ; check if string length == 0
    jr z, kutakbash_process_backspace_end  ; do nothing if true

    ld hl, (kutakbash_local_cursor_position)  ; loading cursor position
    ld a, l ; loading position low byte
    or h  ; check if position == 0
    jr z, kutakbash_process_backspace_end  ; do nothing if true

    dec hl  ; decrementing position
    ld (kutakbash_local_cursor_position), hl  ; saving new position

    push hl  ; arg2 of strchardel - position
    push de  ; input string
    call strchardel

    ; check if strlen - current pos > 0
    ; remove a char from string at position
    ; clear whole line
    ; redraw line
    call kutakbash_redraw_input_string
    call terminal_cursor_left
    ; process backspace, remove a char from the input buffer

    kutakbash_process_backspace_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    ret

.section .bss

kutakbash_input_string_buffer:
    .skip KUTAKBASH_INPUT_STRING_SIZE

; used to check if display cursor now in string range
; to allow deleting chars and as string offset when appending
kutakbash_local_cursor_position:
    .skip 2

; used to clear user input line
kutakbash_display_ptr_at_start:
    .skip 2

.section .rodata

kutakbash_input_control_c_str:
    .asciz "^C\n"
