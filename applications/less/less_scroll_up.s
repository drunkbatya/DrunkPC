.include "applications/less/less_i.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard_codes.inc"
.include "system/drivers/drunkfs/drunkfs.inc"
.include "string/string.inc"

.section .text

; cur pos - width
; if <= 0: seek to zero
; if no: seek to this
; find '\n' from the end to this
; if exists subtract TERMINAL_WIDTH - offset = new offset, seek
; exit

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
    jr z, less_process_scroll_up_end

    push hl  ; ld ix, hl
    pop ix  ; ld ix, hl

    ; subtracting TERMINAL_WIDTH from the current pos
    ld bc, TERMINAL_WIDTH
    or a  ; just clear the carry flag
    sbc hl, bc  ; subtracting TERMINAL_WIDTH from the current pos
    jr z, less_process_scroll_up_seek_to_zero  ; if current pos - TERMINAL_WIDTH == 0
    jr c, less_process_scroll_up_seek_to_zero  ; if current pos - TERMINAL_WIDTH < 0
    jr less_process_scroll_up_seek_to_offset

    less_process_scroll_up_seek_to_zero:
    ld hl, 0  ; seek to zero
    less_process_scroll_up_seek_to_offset:
    push hl  ; arg2 of seek function, fpos
    ld a, (less_file_fd)  ; loading opened file ptr
    ld e, a  ; opened fd
    push de  ; arg1 of the seek function
    call drunkfs_seek
    pop de  ; seek return code

    ; storing calculated offset to de
    push hl  ; ld de, hl
    pop de  ; ld de, hl

    ; getting offset for scroll up
    ; it may be \n position if this char exists in range
    ;   [(current fpos)-(one line size in bytes (or file start))]
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

    ; searching for '\n' in readed one terminal line-sized buffer
    ld hl, TERMINAL_WIDTH  ; one line size in bytes
    push hl  ; arg3 of memchr function, arr size
    ld l, 0x0A  ; searching for the new line char
    push hl  ; arg2 of memchr function, target char to find
    ld hl, less_buffer  ; readed buffer
    push hl  ; arg1 of memchr function, str buffer
    call memrchr  ; searching for the char
    pop hl  ; memchr return value

    ld a, l  ; checking return value, low ptr byte
    or h  ; if is a NULL ptr? (means char not found)
    jr z, less_process_scroll_up_seek

    ; if we found '\n' char in string, subtracting this position from TERMINAL_WIDTH,
    ; and seeking that pos
    ld bc, less_buffer  ; buf addr
    or a  ; just clear carry flag
    sbc hl, bc  ; subtracting buff addr from the position ptr (in hl) to get offset
    inc hl  ; going to the next byte after '\n'
    push hl  ; ld bc, hl
    pop de  ; ld bc, hl

    ; getting entrypoint position
    push ix  ; ld hl, ix: entrypoint position
    pop hl  ; ld hl, ix: entrypoint position

    or a
    sbc hl, de  ; subtracting entrypoint pos - calculated offset
    push hl  ; ld de, hl
    pop de  ; ld de, hl

    less_process_scroll_up_seek:
    push de  ; arg2 of fseek function - fspos on entrypoint
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek return code

    less_process_scroll_up_end:

    ret
