; less - opposite of more

.include "applications/less/less_i.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "system/drivers/drunkfs/drunkfs.inc"
.include "string/string.inc"

.section .text

less_process_show_help:
    ret

less_process_scroll_up_1:
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; loading fd to hl

    ; getting current position
    push hl  ; arg1 of getpos
    call drunkfs_getpos
    pop hl  ; current position

    ; checking if already zero
    ld a, l  ; chec
    or h  ; if position == 0?
    jr z, less_process_scroll_up_no_move

    ; now we need to find file position with last '\n' char, it will be to slow.., but IDGTF
    ; seeking reverse from current position to file start, by TERMINAL_WIDTH sized
    ; chunks, the first occurance of '\n' char in that direction will be our start point,
    ; to calculate desired one line offset

    push hl  ; arg1 of the less_find_char_in_file_in_range funtion, current position
    call less_find_char_in_file_in_range
    pop de  ; return value, offset in file, it will be 0 if no char found in that range

    ex de, hl  ; exchanging hl and de, now current pos in de, and last '\n' pos in hl

    ld bc, TERMINAL_WIDTH  ; loading TERMINAL_WIDTH
    less_process_scroll_up_loop:
        add hl, bc  ; adding TERMINAL_WIDTH (in bc) to find last '\n' pos (in hl)
        or a  ; just clear the carry flag
        sbc hl, de  ; cheking if ('\n' pos + TERMINAL_WIDTH)(in hl) < (current file pos)(in de)
        add hl, de  ; reverting prevoius cmd back
        jr c, less_process_scroll_up_loop  ; if ('\n' pos + TERMINAL_WIDTH)(in hl) < (current file pos)(in de)
    or a  ; just clear the carry flag
    sbc hl, bc  ; subtracting TERMINAL_WIDTH (in bc) from ('\n' pos + TERMINAL_WIDTH)
    jr less_process_scroll_up_end

    less_process_scroll_up_to_zero:
    ld hl, 0  ; seek to zero

    less_process_scroll_up_end:
    push hl  ; arg2 of seek function, new position
    ld l, a  ; loading fd to hl
    push hl  ; arg1 of seek, fd
    call drunkfs_seek
    pop hl  ; seek return code

    less_process_scroll_up_no_move:
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
    .skip TERMINAL_WIDTH

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
