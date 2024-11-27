; less - opposite of more

.include "applications/less/less.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "string/string.inc"

.section .text

less_process_show_help:
    ret

less_process_scroll_down:
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l , a  ; loading fd to hl

    ; getting current position
    push hl  ; arg1 of getpos
    call drunkfs_getpos
    pop de  ; current position

    ; getting current size
    push hl  ; arg1 of getsize
    call drunkfs_getsize
    pop bc  ; file size

    ; checking if (size >= (pos + one line in bytes))
    push de  ; ld hl, de
    pop hl  ; ld hl, de
    ld de, TERMINAL_WIDTH  ; terminal width in bytes
    add hl, de  ; pos + terminal width
    or a  ; just clear the carry flag
    sbc hl, bc  ; if (pos + one line in bytes) < size
    add hl, bc  ; reverting back
    jr z, less_process_scroll_down_continue  ; if (pos + one line in bytes) == size, ok
    jr nc, less_process_scroll_down_end  ; if (pos + one line in bytes) > size

    less_process_scroll_down_continue:
    push hl  ; arg2 of seek function, new position
    ld l, 1  ; loading fd to hl
    push hl  ; arg1 of seek, fd
    call drunkfs_seek
    pop hl  ; seek return code

    less_process_scroll_down_end:

    ret

less_process_scroll_up:
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l , a  ; loading fd to hl

    ; getting current position
    push hl  ; arg1 of getpos
    call drunkfs_getpos
    pop de  ; current position

    ld a, e  ; chec

    ; checking if ((pos - one line in bytes) >= 0)
    push de  ; ld hl, de
    pop hl  ; ld hl, de
    ld de, TERMINAL_WIDTH  ; terminal width in bytes
    or a  ; just clear the carry flag
    sbc hl, de  ; pos - terminal width

    jr c, less_process_scroll_up_to_zero  ; if TERMINAL_WIDTH > position

    jr less_process_scroll_up_end  ; seeking to the calculated offset

    less_process_scroll_up_to_zero:
    ld hl, 0  ; seek to zero

    less_process_scroll_up_end:
    push hl  ; arg2 of seek function, new position
    ld l, a  ; loading fd to hl
    push hl  ; arg1 of seek, fd
    call drunkfs_seek
    pop hl  ; seek return code

    ret

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
        pop hl  ; read_byte return value, size of readen data

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
        push hl  ; storing hl
        ld de, (ra6963_address_pointer)  ; getting current disp ptr
        ld hl, LESS_LAST_BYTE_BEFORE_LAST_DISPLAY_LINE_ADDR
        or a  ; just cleat the carry flag
        sbc hl, de  ; if we're printed to the last line
        pop hl  ; restoring hl
        jr z, less_process_file_loop_render_loop_end  ; if last addr == disp addr

        ; printing a char
        ld e, a  ; loading char to de
        push de  ; arg1 of terminal_putchar
        call terminal_putchar

        ; going next byte
        inc hl  ; going to next buffer byte
        dec bc  ; counting counter-clockwise
        jr less_process_file_loop_render_loop
    less_process_file_loop_render_loop_end:
    ; restoring a current file position
    ld hl, 10
    push hl
    ld hl, (less_file_pos)  ; getting a local current pos
    push hl  ; arg2 of the seek function
    call putnbr

    ld hl, (less_file_pos)  ; getting a local current pos
    push hl  ; arg2 of seek
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek error code

    ret

less_process_file:
    pop hl  ; return address
    pop de  ; file path
    push hl  ; storing return address back

    ; opening file
    push de  ; arg1 of open
    call drunkfs_open  ; trying to open a file
    pop hl  ; return fd

    ; cheking success
    ld a, l  ; loading fd
    or a  ; cheking fd == 0 (error)
    jr z, less_process_file_exit_fail

    ; if success open
    ld (less_file_fd), a

    ; render single page
    less_process_file_loop_render_page:
    call less_render_page

    ; awaiting user input
    less_process_file_loop_await_keyboard:
    call keyboard_get_key  ; reading keyboard
    pop hl  ; return char code
    ld a, l  ; loading byte
    or a  ; if it zero?
    jr z, less_process_file_loop_await_keyboard
    ; check 'q'
    cp 'q'  ; if q pressed
    jr z, less_process_file_exit_success
    cp 'Q'  ; if Q pressed
    jr z, less_process_file_exit_success
    cp KBD_UP  ; if up pressed
    jr z, less_process_file_keyboard_up
    cp KBD_DOWN  ; if down pressed
    jr z, less_process_file_keyboard_down
    jr less_process_file_loop_await_keyboard  ; keyboard loop

    less_process_file_keyboard_up:
    call less_process_scroll_up
    jr less_process_file_loop_render_page

    less_process_file_keyboard_down:
    call less_process_scroll_down
    jr less_process_file_loop_render_page

    less_process_file_exit_fail:

    less_process_file_exit_success:
    ; exiting after success open file
    call terminal_init
    ;call ra6963_text_mode_cursor_on

    less_process_file_exit_close_file:
    ld a, (less_file_fd)  ; loading fd
    ld l, a  ; loading fd
    push hl  ; arg1 of close
    call drunkfs_close

    ret

; one chain --------------------------|
less_process_many_args_error:
    ld bc, less_many_args_msg
    jr less_exit_with_error

less_process_empty_args_error:
    ld bc, less_empty_args_msg

less_exit_with_error:
    ld hl, less_msg_header
    push hl
    call putstr

    push bc  ; error message in bc
    call putstr
    ret

less_main:
    push af  ; storing af
    push de  ; storing ix
    push bc  ; storing bc
    push hl  ; storing hl

    ld a, (kutakbash_argc)  ; loading argc
    cp 2  ; check if no args passed
    jr c, less_empty_args_error  ; if argc < 2
    jr nz, less_many_args_error  ; if argc > 2

    ld b, a  ; loading arguments count to b reg for djnz instruction
    ld de, kutakbash_argv  ; loading ptr ot argv

    ; dereferencing 1st arg
    ld a, (de)  ; with no offset it will be address! of argv[0]
    ld l, a  ; loading first address byte to l
    inc de
    ld a, (de)  ; getting a second address byte
    ld h, a  ; loading second address byte to h
    inc de
    ; now first arg in hl

    ld bc, less_arg_help_str  ; if we asking for help?
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr nz, less_show_help  ; if arg1 == '--help'

    push hl  ; filename
    call less_process_file  ; all right, let's open file

    jr less_end

    less_show_help:
    call less_process_show_help
    jr less_end

    less_empty_args_error:
    call less_process_empty_args_error
    jr less_end

    less_many_args_error:
    call less_process_many_args_error

    less_end:

    pop hl  ; restoring hl
    pop bc  ; restoring bc
    pop de  ; restoring ix
    pop af  ; restoring af

    ret

.section .bss

less_file_fd:
    .skip 1

less_buffer:
    .skip 1

less_file_pos:
    .skip 2

.section .rodata

less_name:
    .asciz "less"

less_msg_header:
    .asciz "less: "

less_arg_help_str:
    .asciz "--help"

less_empty_args_msg:
    .asciz "Missing filename (try 'less --help')\n"

less_many_args_msg:
    .asciz "Wrong arguments (try 'less --help')\n"
