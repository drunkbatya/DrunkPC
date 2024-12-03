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

    ; changing file read direction
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the drunkfs_set_rw_direction_backward function
    call drunkfs_set_rw_direction_backward
    pop hl  ; return code

    ; seeking to current fpos
    push bc  ; arg2 of seek function, fpos
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the seek function
    call drunkfs_seek
    pop hl  ; seek return code

    ; reverse searching '\n' char from current pos to file start
    less_find_char_in_file_in_range_loop:
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
        jr nz, less_find_char_in_file_in_range_end  ; if EOF

        ; checking if current byte is a '\n'
        ld a, (less_buffer)  ; loading char from the buffer
        cp 0x0A  ; cheking '\n'
        jr z, less_find_char_in_file_in_range_end

        ; decrementing fpos
        ld a, c  ; checking position == 0
        or b  ; if position == 0
        jr z, less_find_char_in_file_in_range_end
        dec bc
        jr less_find_char_in_file_in_range_loop

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

    ; reverting file read direction
    ld a, (less_file_fd)  ; loading opened file ptr
    ld l, a  ; opened fd
    push hl  ; arg1 of the drunkfs_set_rw_direction_forward function
    call drunkfs_set_rw_direction_forward
    pop hl  ; return code

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af

    ret

