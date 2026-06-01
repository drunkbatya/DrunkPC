.include "applications/less/less_i.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "system/drivers/drunkfs/drunkfs.inc"
.include "string/string.inc"

.section .text

less_render_page:
    ; clearing screen
    call terminal_init
    call ra6963_text_mode_cursor_off

    ; saving a current file position
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the getpos function
    call drunkfs_getpos
    pop hl  ; getpos return value, current pos
    ld (less_file_pos), hl  ; saving a current pos locally

    ; render page
    less_process_file_loop_render_loop:
        ; reading data
        ld hl, less_buffer  ; address of the buffer
        push hl  ; arg2 of the read function, buffer ptr
        ld a, (less_file_fd)  ; loading opened file ptr
        ld l, a  ; opened fd
        push hl  ; arg1 of the read function
        call drunkfs_read_byte
        pop hl  ; read_byte return value, error code

        ; checking EOF
        ld a, l  ; loading error code
        or a  ; checking if error is 0 (success)
        jr nz, less_process_file_loop_render_loop_end  ; if no success

        ; loading a char from the buffer
        ld a, (less_buffer)  ; loading char to draw

        ; checking EOS
        or a  ; cheking null-teminator
        jr z, less_process_file_loop_render_loop_end

        ; checking end of terminal
        ld de, (ra6963_address_pointer)  ; getting current disp ptr
        ld hl, LESS_LAST_BYTE_BEFORE_LAST_DISPLAY_LINE_ADDR
        or a  ; just cleat the carry flag
        sbc hl, de  ; if we're printed to the last line
        jr z, less_process_file_loop_render_loop_end  ; if last addr == disp addr

        ; printing a char
        ld e, a  ; loading char to de
        push de  ; arg1 of terminal_putchar
        call terminal_putchar

        ; going next byte
        jr less_process_file_loop_render_loop
    less_process_file_loop_render_loop_end:
    ; restoring a current file position
    ld hl, 10  ; decimal representation
    push hl  ; arg2 of the putnbr function
    ld hl, (less_file_pos)  ; getting a local current pos
    push hl  ; arg1 of the putnbr function
    call putnbr

    ld hl, (less_file_pos)  ; getting a local current pos
    push hl  ; arg2 of seek
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek error code

    ret

