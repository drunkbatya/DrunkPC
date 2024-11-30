.include "applications/less/less_i.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "system/drivers/drunkfs/drunkfs.inc"
.include "string/string.inc"

.section .text

less_process_scroll_down:
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; loading fd to hl

    ; getting current position
    push hl  ; arg1 of getpos
    call drunkfs_getpos
    pop de  ; current position

    ; getting offset for scroll down
    ; it may be \n position if this char exists in range
    ;   [(current fpos)-(one line size in bytes)]
    ; if the char '\n' is not exists, the offset will be TERMINAL_WIDTH
    ; trying to read TERMINAL_WIDTH bytes to buffer
    ld hl, TERMINAL_WIDTH  ; (one line size in bytes)
    push hl  ; arg3 of the read function, size in bytes
    ld hl, less_buffer  ; address of the buffer
    push hl  ; arg2 of the read function, buffer ptr
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the read function
    call drunkfs_read
    pop hl  ; read return value, error code

    ld a, l  ; read return code
    cp DRUNKFS_ERROR_EOF
    jr z, less_process_scroll_down_do_nothing  ; if we'r got EOF while reading this line

    ; searching for '\n' in readed one terminal line-sized buffer
    ld hl, TERMINAL_WIDTH  ; one line size in bytes
    push hl  ; arg3 of memchr function, arr size
    ld l, 0x0A  ; searching for the new line char
    push hl  ; arg2 of memchr function, target char to find
    ld hl, less_buffer  ; readed buffer
    push hl  ; arg1 of memchr function, str buffer
    call memchr  ; searching for the char
    pop hl  ; memchr return value

    ld a, l  ; checking return value, low ptr byte
    or h  ; if is a NULL ptr? (means char not found)
    jr z, less_process_scroll_down_seek_one_line

    ; if we found '\n' char in string, seeking that pos + 1 byte more
    ; EOF in that case will be covered by redraw function
    ld bc, less_buffer  ; buf addr
    or a  ; just clear carry flag
    sbc hl, bc  ; subtracting buff addr from the position ptr (in hl) to get offset
    add hl, de  ; adding entrypoint pos + calculated offset
    inc hl  ; going to the next byte after '\n'
    push hl  ; arg2 of fseek function
    jr less_process_scroll_down_seek

    ; no '\n' char in one line, seek TERMINAL_WIDTH bytes
    less_process_scroll_down_seek_one_line:
    ld hl, TERMINAL_WIDTH  ; bytes to seek
    add hl, de  ; seeking entrypoint pos (in de) + TERMINAL_WIDTH
    push hl  ; arg2 of fseek function
    jr less_process_scroll_down_seek

    ; reverting changes back
    less_process_scroll_down_do_nothing:
    push de  ; arg2 of fseek function - fspos on entrypoint

    ; assuming arg2 - size - is already pushed
    less_process_scroll_down_seek:
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek return code

    less_process_scroll_down_end:

    ret

