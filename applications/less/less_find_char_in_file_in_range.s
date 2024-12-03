.include "applications/less/less_i.inc"
.include "system/drivers/drunkfs/drunkfs.inc"

.section .text

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

