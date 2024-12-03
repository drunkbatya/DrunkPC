.include "applications/less/less_i.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "system/drivers/drunkfs/drunkfs.inc"
.include "string/string.inc"

.section .text

less_process_scroll_up:
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; loading fd to hl

    ; getting current position
    push hl  ; arg1 of getpos
    call drunkfs_getpos
    pop hl  ; current position

    ; checking if cur pos == 0
    ld a, l  ; loading low byte to a
    or h  ; checking if == 0
    jp z, less_process_scroll_up_end

    ex de, hl  ; store position in de

    ; if current position isn't zero, checking if previous char in file is a '\n'
    dec de  ; decrementing current position by 1, going to the previous char
    push de  ; arg2 of seek, position
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek error code

    ld hl, less_buffer  ; address of the buffer
    push hl  ; arg2 of the read function, buffer ptr
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the read function
    call drunkfs_read_byte
    pop hl  ; read_byte return value, error code

    ld a, (less_buffer)  ; checking readen byte
    cp 0x0A  ; checking new line
    jr nz, less_process_scroll_up_next_char_is_not_nl  ; if not a new line

    ; if next char is a new line, skipping it
    dec de  ; decrementing current position by 1 again, to skip '\n' char

    less_process_scroll_up_next_char_is_not_nl:
    ; if next char isn't new line, lets go over whole file to find last '\n' from current to start
    push de  ; arg1 of less_find_char_in_file_in_range func, position to search till
    call less_find_char_in_file_in_range
    pop hl  ; return value

    ld a, l  ; loading return value
    or h  ; check zero
    jr z, less_process_scroll_up_skip_last_nl

    inc hl  ; skipping '\n' char itself

    less_process_scroll_up_skip_last_nl:

    ; if we found a '\n' char itterating from that pos to current
    ; untill ((last '\n' pos) + (TERMINAL_WIDTH * i)) < (current pos - TERMINAL_WIDTH)

    ld bc, TERMINAL_WIDTH
    less_process_scroll_up_next_char_loop:
        or a  ; just clear the carry flag
        sbc hl, de  ; is found pos (in hl) < current pos (in de)?
        add hl, de  ; reverting back
        jr z, less_process_scroll_up_sub_term_width  ; if found pos (in hl) == current pos (in de)
        jr nc, less_process_scroll_up_sub_term_width  ; if found pos (in hl) > current pos (in de)
        add hl, bc  ; adding TERMINAL_WIDTH to found pos
        jr less_process_scroll_up_next_char_loop

    less_process_scroll_up_sub_term_width:
    or a  ; just clear the carry flag
    sbc hl, bc  ; subtracting TERMINAL_WIDTH from current pos
    jr c, less_process_scroll_up_seek_cur_pos_lt_term
    jr less_process_scroll_up_seek

    less_process_scroll_up_seek_cur_pos_lt_term:
    add hl, bc  ; reverting back
    push hl  ; storing hl
    ld hl, TERMINAL_WIDTH  ; loading to hl
    pop de  ; loading current pos to de
    or a  ; just clear the carry flag
    sbc hl, de  ; subtracting current pos from TERMINAL_WIDTH

    less_process_scroll_up_seek:
    push hl  ; arg2 of seek, position
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek error code

    less_process_scroll_up_end:
    ret

    ;ld bc, 10
    ;push bc  ; arg2 of putnbr
    ;push hl  ; found in
    ;call putnbr
    ;push bc  ; arg2 of putnbr
    ;push de  ; found in
    ;call putnbr
    ;halt


