.include "hardware/io.inc"
.include "keyboard/keyboard.inc"

KEYBOARD_SHIFT_ROW = 0x20  ; row 5
KEYBOARD_CONTROL_ROW = 0x40  ; row 6
KEYBOARD_SHIFT_BIT = 1  ; bit 1
KEYBOARD_CONTROL_BIT = 5  ; bit 5

KEYBOARD_SCAN_READ_DELAY_NOP = 6  ; in 'nop'`s

; Internal!
; reg a not preserved!
; Args:
;   a - row bit mask
; Return:
;   a - column bit mask
keyboard_read_column:
    out (IO_KBD_ADDR), a  ; setting row
    push bc  ; storing b
    ld b, KEYBOARD_SCAN_READ_DELAY_NOP
    keyboard_read_column_nop_loop:
        nop  ; keep calm
        djnz keyboard_read_column_nop_loop
    pop bc  ; restoring b
    in a, (IO_KBD_ADDR)  ; reading column
    ret


; About:
;   Scans keyboard and returns the pressed key (block until keypress)
; Args:
;   None
; Return:
;   unsigned char c - pressed char code
; C Prototype:
; unsigned char keyboard_get_key_block(void);
keyboard_get_key_block:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push bc  ; add one more arg cause functions recives none and returns 1 arg
    push hl  ; pushing return pointer back
    exx  ; restroing register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    keyboard_get_key_block_loop:
        call keyboard_get_key  ; non-block read
        pop hl  ; return
        ld a, l  ; loading return char
        or a  ; if it zero?
        jr z, keyboard_get_key_block_loop  ; looping until non zero

    ld (ix + 0), a  ; returning found byte

    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret


; About:
;   Scans keyboard and returns the pressed key
; Args:
;   None
; Return:
;   unsigned char c - pressed char code
; C Prototype:
; unsigned char keyboard_get_key(void);
keyboard_get_key:
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

    keyboard_get_key_check_shift:
    ld a, KEYBOARD_SHIFT_ROW  ; setting row 5
    call keyboard_read_column  ; arg in a, return in a
    bit KEYBOARD_SHIFT_BIT, a  ; if shift pressed?
    jr nz, keyboard_get_key_shift_pressed

    keyboard_get_key_check_control:
    ld a, KEYBOARD_CONTROL_ROW  ; setting row 5
    call keyboard_read_column  ; arg in a, return in a
    bit KEYBOARD_CONTROL_BIT, a  ; if shift pressed?
    jr nz, keyboard_get_key_control_pressed

    ld hl, keyboard_matrix_map  ; loading keyboard_matrix_map ptr
    jr keyboard_get_key_row_start

    keyboard_get_key_shift_pressed:
    ld hl, keyboard_matrix_map_shift
    jr keyboard_get_key_row_start

    keyboard_get_key_control_pressed:
    ld hl, keyboard_matrix_map_control

    keyboard_get_key_row_start:
    ld b, 1  ; hardware row bitmask
    keyboard_get_key_row_loop:
        ld a, b  ; hardware row bitmask
        call keyboard_read_column  ; arg in a, return in a
        ld e, a  ; storing readed column
        ld c, 1  ; hardware column bitmask
        keyboard_get_key_column_loop:
            ld a, e  ; readed column
            and c  ; if current hardware column bitmask matches pressed key
            jr z, keyboard_get_key_column_loop_skip_col
            ld a, (hl)  ; trying to access the founded char
            or a  ; if it not zero
            jr nz, keyboard_get_key_key_found  ; we found a key, returning the first match
            keyboard_get_key_column_loop_skip_col:
            inc hl  ; increasing the keyboard_matrix_map ptr
            sla c  ; shifting left, going to the next hardware column, (left bit goes to the carry flag)
            jr nc, keyboard_get_key_column_loop  ; looping untill bit 1 not in carry flag
        sla b  ; going to the next hardware row
        jr nc, keyboard_get_key_row_loop  ; looping untill bit 1 not in carry flag
    jr keyboard_get_key_key_found_nothing  ; if nothing found
    keyboard_get_key_key_found:
    ld a, (hl)  ; founded char
    or a  ; if it zero?
    jr z, keyboard_get_key_key_found_previous
    ld d, (hl)  ; found char byte
    ld a, (keyboard_previous_scanned_char)  ; previously found char byte
    cp d  ; if current char == previously found char
    jr z, keyboard_get_key_key_found_previous
    ld a, (hl)  ; found char byte
    ld (keyboard_previous_scanned_char), a  ; writing found char to var
    ld (ix + 0), a  ; returning found byte
    jr keyboard_get_key_end
    keyboard_get_key_key_found_nothing:
    ld a, 0  ; nothing found
    ld (keyboard_previous_scanned_char), a  ; writing found char to var
    keyboard_get_key_key_found_previous:
    ld (ix + 0), 0  ; returning 0 if found char == previously found char
    keyboard_get_key_end:
    ld a, 0  ; resseting hardware row bitmask
    out (IO_KBD_ADDR), a

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret

.section .bss

keyboard_previous_scanned_char:
    .skip 1
