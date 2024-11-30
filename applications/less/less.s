; less - opposite of more

.include "applications/less/less_i.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "system/drivers/drunkfs/drunkfs.inc"
.include "string/string.inc"

.section .text

less_process_show_help:
    ret


; About: Finds the first occurance of '\n' char in file, seeking reverse
;   from current position to file start, by TERMINAL_WIDTH sized chunks
; Args:
;   uint16_t pos - current position
; Return:
;   uint16_t ret_pos - ptr to the firs occurance of '\n' char in in file,
;       from the [current position] to [file start], and [file start](NULL) if not found
; C Prototype:
;   uint16_t less_find_char_in_file_in_range(uint16_t pos);
less_find_char_in_file_in_range:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld c, (ix + 0)  ; position low byte
    ld b, (ix + 1)  ; position high byte

    ; reverse searching '\n' char from current pos to file start
    less_find_char_in_file_in_range_loop:
        ; checking file pos == 0
        ld a, c  ; loading position low byte
        or b  ; checking if pos == 0
        jr z, less_find_char_in_file_in_range_end

        ; seeking to current fpos
        push bc  ; arg2 of seek function, fpos
        ld a, (less_file_fd)  ; loading opened file ptr
        ld l, a  ; opened fd
        push hl  ; arg1 of the seek function
        call drunkfs_seek
        pop hl  ; seek return code

        ; reading TERMINAL_WIDTH sized chunk to find '\n' char
        ld hl, TERMINAL_WIDTH  ; (one line size in bytes)
        push hl  ; arg3 of the read function, size in bytes
        ld hl, less_buffer  ; address of the buffer
        push hl  ; arg2 of the read function, buffer ptr
        ld a, (less_file_fd)  ; loading opened file ptr
        ld l, a  ; opened fd
        push hl  ; arg1 of the read function
        call drunkfs_read
        pop hl  ; read return value, error code

        ; searching for '\n' in readed one terminal line-sized buffer
        ld hl, TERMINAL_WIDTH  ; one line size in bytes
        push hl  ; arg3 of memrchr function, arr size
        ld l, 0x0A  ; searching for the new line char
        push hl  ; arg2 of memrchr function, target char to find
        ld hl, less_buffer  ; readed buffer
        push hl  ; arg1 of memrchr function, str buffer
        call memrchr  ; searching for the char  ; TODO: memrchr
        pop hl  ; memrchr return value

        ; finding '\n' char in readen buffer
        ld a, l  ; checking return value, low ptr byte
        or h  ; if is a NULL ptr? (means char not found)
        jr nz, less_find_char_in_file_in_range_char_found

        ; if in current readen block no '\n' bound
        push bc  ; ld hl, bc
        pop hl  ; ld hl, bc
        ld de, TERMINAL_WIDTH
        or a  ; just clear carry flag
        sbc hl, de  ; subtracting less_buffer size from current fpos
        jr c, less_find_char_in_file_in_range_end  ; if (current pos - TERMINAL_WIDTH) < 0
        push hl  ; ld bc, hl
        pop bc  ; ld bc, hl
        jr less_find_char_in_file_in_range_loop

    less_find_char_in_file_in_range_char_found:
    ; if we found '\n' char in string (offset in hl), seeking that pos + 1 byte more
    ld de, less_buffer  ; buf addr
    or a  ; just clear carry flag
    sbc hl, de  ; subtracting buff addr from the position ptr (in hl) to get offset
    add hl, bc  ; adding entrypoint pos + calculated offset
    inc hl  ; going to the next byte after '\n'
    push hl  ; ld bc, hl
    pop bc  ; ld bc, hl
    jr less_find_char_in_file_in_range_end

    less_find_char_in_file_in_range_end:
    ; seeking back to entrypoint position
    ld l, (ix + 0)  ; position low byte
    ld h, (ix + 1)  ; position high byte
    push hl  ; arg2 of seek function, fpos
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek return code

     ; returning found fpos
    ld (ix + 0), c  ; position low byte
    ld (ix + 1), b  ; position high byte

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af

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
