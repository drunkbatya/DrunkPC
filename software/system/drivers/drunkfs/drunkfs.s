.include "system/drivers/drunkfs/drunkfs.inc"

.section .text

; About:
;   Opens a file
; Args:
;   const char* path - file path
; Return:
;   uint8_t fd - file descriptor
; C Prototype:
;   uint8_t drunkfs_open(const char* path);
drunkfs_open:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ;ld l, (ix + 0)  ; str ptr low byte
    ;ld h, (ix + 1)  ; str ptr high byte

    ; file size
    ld hl, test_data_end - test_data
    ld (drunkfs_file_size), hl  ; file size

    ; file ptr, alloc in fd table
    ld hl, 1  ; file ptr, only one file may be opened at once.. now
    ld (ix + 0), l  ; returning fd
    ld (drunkfs_file_current_fd), hl  ; storing fd

    ; current file position
    ld hl, 0  ; file position
    ld (drunkfs_file_current_pos), hl  ; fpos

    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret


; About:
;   Changing a opened file read/write direction to forward (default)
; Args:
;   uint8_t fd - file descriptor
; Return:
;   uint8_t error - error
; C Prototype:
;   uint8_t drunkfs_set_rw_direction_forward(uint8_t fd);
drunkfs_set_rw_direction_forward:
    push af  ; storing af
    push ix  ; storing ix

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; currently fd is ignored

    ld a, DRUNKFS_RW_DIRECTION_FORWARD
    ld (drunkfs_file_current_direction), a

    ; returning error code
    ld (ix + 0), DRUNKFS_ERROR_OK  ; no error

    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

; About:
;   Changing a opened file read/write direction to backward
; Args:
;   uint8_t fd - file descriptor
; Return:
;   uint8_t error - error
; C Prototype:
;   uint8_t drunkfs_set_rw_direction_backward(uint8_t fd);
drunkfs_set_rw_direction_backward:
    push af  ; storing af
    push ix  ; storing ix

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; currently fd is ignored

    ld a, DRUNKFS_RW_DIRECTION_BACKWARD
    ld (drunkfs_file_current_direction), a

    ; returning error code
    ld (ix + 0), DRUNKFS_ERROR_OK  ; no error

    pop ix  ; restoring ix
    pop af  ; restoring af
    ret


; About:
;   Changing a opened file position
; Args:
;   uint8_t fd - file descriptor
;   uint16_t pos - desired position
; Return:
;   uint8_t error - error
; C Prototype:
;   uint8_t drunkfs_seek(uint8_t fd, uint16_t pos);
drunkfs_seek:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; TODO: check file size
    ; TODO: check fd

    ; storing new current file position
    ld l, (ix + 2)  ; position low byte
    ld h, (ix + 3)  ; position high byte
    ld (drunkfs_file_current_pos), hl  ; fpos

    ; error code
    ld (ix + 2), DRUNKFS_ERROR_OK  ; no error

    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    push hl  ; return address
    exx  ; restoring registers
    ret

; About:
;   Reads a bytes from file to buf
; Args:
;   uint8_t fd - file descriptor
;   void* buf_ptr - pointer to the buffer to store a byte
;   uint16_t size - pointer to the buffer to store a byte
; Return:
;   uint8_t error - error code
; C Prototype:
;   uint8_t drunkfs_read(uint8_t fd, uint16_t buf_ptr, uint16_t size);
drunkfs_read:
    push af  ; storing af
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc
    push ix  ; storing ix

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld c, (ix + 4)  ; loading low byte of size
    ld b, (ix + 5)  ; loading high byte of size

    drunkfs_read_loop:
        ; checking size
        ld a, c  ; loading low byte of size
        or b  ; if bc == 0?
        jr z, drunkfs_read_success  ; requested size is reached

        ; checking file end
        ld hl, (drunkfs_file_size)  ; file size
        ld de, (drunkfs_file_current_pos)  ; fpos
        or a  ; just clear the carry flag
        sbc hl, de  ; check if we'r reached EOF
        jr c, drunkfs_read_eof  ; if size < position
        jr z, drunkfs_read_eof  ; if size == position, EOF

        ; reading a byte, current offset in de
        ld hl, test_data  ; temp, buffer
        add hl, de  ; ptr = offset + buf addr
        ld a, (hl)  ; loading a byte
        ;ld l, (ix + 0)  ; fd low byte only, skip for now
        ld l, (ix + 2)  ; target buf low byte
        ld h, (ix + 3)  ; target buf high byte
        ld (hl), a  ; returning a byte

        ; incrementing target buf local arg
        inc hl  ; ++
        ld (ix + 2), l  ; target buf low byte
        ld (ix + 3), h  ; target buf high byte

        ; incrementing position
        ld hl, (drunkfs_file_current_pos)  ; loading current position var ptr
        inc hl  ; incrementing position
        ld (drunkfs_file_current_pos), hl  ; storing position back

        ; decrementing size
        dec bc

        jr drunkfs_read_loop

    ; return
    drunkfs_read_eof:
    ld a, DRUNKFS_ERROR_EOF
    ld (ix + 4), a  ; return
    jr drunkfs_read_end

    drunkfs_read_success:
    ld a, DRUNKFS_ERROR_OK
    ld (ix + 4), a  ; return

    drunkfs_read_end:
    pop ix  ; restoring ix
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers
    ret

; About:
;   Reads a byte from file
; Args:
;   uint8_t fd - file descriptor
;   uint16_t buf_ptr - pointer to the buffer to store a byte
; Return:
;   uint8_t error - error code
; C Prototype:
;   uint8_t drunkfs_read_byte(uint8_t fd, uint16_t buf_ptr);
drunkfs_read_byte:
    push af  ; storing af
    push hl  ; storing hl
    push de  ; storing de
    push ix  ; storing ix

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; checking file end
    ld hl, (drunkfs_file_size)  ; file size
    ld de, (drunkfs_file_current_pos)  ; fpos
    sbc hl, de  ; check if we'r reached EOF
    add hl, de  ; reverting previous command
    jr c, drunkfs_read_byte_eof  ; if size < position
    jr z, drunkfs_read_byte_eof  ; EOF

    ; reading a byte, current offset in de, TODO: do not write if dec and pos  == 0
    ld hl, test_data  ; temp, buffer
    add hl, de  ; ptr = offset + buf addr
    ld a, (hl)  ; loading a byte
    ;ld l, (ix + 0)  ; fd low byte only, skip for now
    ld l, (ix + 2)  ; target buf low byte
    ld h, (ix + 3)  ; target buf high byte
    ld (hl), a  ; returning a byte

    ; preparing fpos to modify
    ld hl, (drunkfs_file_current_pos)  ; loading current position var ptr

    ; checking seek direction
    ld a, (drunkfs_file_current_direction)
    cp DRUNKFS_RW_DIRECTION_BACKWARD
    jr z, drunkfs_read_byte_decrement_fpos

    ; incrementing position
    inc hl  ; incrementing position
    jr drunkfs_read_byte_save_fpos

    ; or decrementing position
    drunkfs_read_byte_decrement_fpos:
    ; in first checking we'r already not seeked to the file start
    ld a, l  ; loading low position byte
    or h  ; checking zero
    jr z, drunkfs_read_byte_eof  ; raising error, nothing to decrement
    dec hl  ; decrementing position

    drunkfs_read_byte_save_fpos:
    ld (drunkfs_file_current_pos), hl  ; storing position back

    jr drunkfs_read_byte_success

    ; return
    drunkfs_read_byte_eof:
    ld a, DRUNKFS_ERROR_EOF
    ld (ix + 2), a  ; return
    jr drunkfs_read_byte_end

    drunkfs_read_byte_success:
    ld a, DRUNKFS_ERROR_OK
    ld (ix + 2), a  ; return

    drunkfs_read_byte_end:
    pop ix  ; restoring ix
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    push hl  ; return address
    exx  ; restoring registers
    ret

; About:
;   Gets a file size
; Args:
;   uint8_t fd - file descriptor
; Return:
;   uint16_t size - file size
; C Prototype:
;   uint16_t drunkfs_getsize(uint8_t fd);
drunkfs_getsize:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; current fd
    ;ld l, (ix + 0)  ; fd low byte only, skip for now

    ; getting current size
    ld hl, (drunkfs_file_size)  ; file size
    ld (ix + 0), l  ; file size low byte
    ld (ix + 1), h  ; file size high byte

    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

; About:
;   Gets a current position from file starts
; Args:
;   uint8_t fd - file descriptor
; Return:
;   uint16_t size - current position
; C Prototype:
;   uint16_t drunkfs_getpos(uint8_t fd);
drunkfs_getpos:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; current fd
    ;ld l, (ix + 0)  ; fd low byte only, skip for now

    ; getting current pos
    ld hl, (drunkfs_file_current_pos)  ; file size
    ld (ix + 0), l  ; pos low byte
    ld (ix + 1), h  ; pos  high byte

    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

drunkfs_rewind:
    push hl  ; storing hl

    ld hl, 0
    ld (drunkfs_file_current_pos), hl

    pop hl  ; restoring hl
    ret

; About:
;   Close a opened file
; Args:
;   uint8_t fd - file descriptor
; Return:
;   None
; C Prototype:
;   void drunkfs_close(uint8_t fd);
drunkfs_close:
    push af  ; storing af
    push hl  ; storing hl
    push ix  ; storing ix

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; zeroing everything
    ld hl, 0

    ; file size
    ld (drunkfs_file_size), hl  ; file size

    ; file ptr, alloc in fd table
    ld (drunkfs_file_current_fd), hl  ; storing fd

    ; current file position
    ld (drunkfs_file_current_pos), hl  ; fpos

    pop ix  ; restoring ix
    pop hl  ; restoring hl
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    push hl  ; return address
    exx  ; restoring registers
    ret

.section .bss

drunkfs_file_current_fd:
    .skip 2

drunkfs_file_size:
    .skip 2

drunkfs_file_current_pos:
    .skip 2

drunkfs_file_current_direction:
    .skip 1

.section .rodata

test_data:
    .byte 0x54, 0x68, 0x69, 0x73, 0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x74, 0x65, 0x78, 0x74, 0x20, 0x74, 0x65, 0x78, 0x74, 0x20, 0x66, 0x69, 0x6c, 0x65, 0x2c, 0x20, 0x62, 0x6c, 0x61, 0x2c, 0x20, 0x62, 0x6c, 0x61, 0xa, 0xee, 0xc5, 0x20, 0xda, 0xce, 0xc1, 0xc0, 0x2c, 0x20, 0xde, 0xd4, 0xcf, 0x20, 0xd4, 0xd5, 0xd4, 0x20, 0xce, 0xc1, 0xd0, 0xc9, 0xd3, 0xc1, 0xd4, 0xd8, 0x2c, 0x20, 0xce, 0xc1, 0xd0, 0xc9, 0xdb, 0xd5, 0x20, 0xcb, 0xc1, 0xcb, 0xd5, 0xc0, 0x2d, 0xce, 0xc9, 0xc2, 0xd5, 0xc4, 0xd8, 0x20, 0xc5, 0xc2, 0xd5, 0xde, 0xd5, 0xc0, 0x20, 0xc8, 0xd5, 0xc5, 0xd4, 0xd5, 0x2c, 0x20, 0xce, 0xc1, 0xc4, 0xcf, 0x20, 0xcb, 0xc1, 0xcb, 0x2d, 0xd4, 0xcf, 0x20, 0xda, 0xc1, 0xd0, 0xcf, 0xcc, 0xce, 0xc9, 0xd4, 0xd8, 0x20, 0xdc, 0xd4, 0xcf, 0x20, 0xd0, 0xd2, 0xcf, 0xd3, 0xd4, 0xd2, 0xc1, 0xce, 0xd3, 0xd4, 0xd7, 0xcf, 0xa, 0x41, 0x6e, 0x64, 0x20, 0x73, 0x6f, 0x2c, 0x20, 0x69, 0x20, 0x64, 0x6f, 0x6e, 0x27, 0x74, 0x20, 0x6b, 0x6e, 0x6f, 0x77, 0x20, 0x68, 0x6f, 0x77, 0x20, 0x74, 0x68, 0x69, 0x73, 0x20, 0x73, 0x68, 0x69, 0x74, 0x20, 0x77, 0x69, 0x6c, 0x6c, 0x20, 0x62, 0x65, 0x20, 0x64, 0x69, 0x73, 0x70, 0x6c, 0x61, 0x79, 0x65, 0x64, 0x2c, 0x20, 0xce, 0xcf, 0x20, 0xd0, 0xcf, 0xc8, 0xd5, 0xca, 0x20, 0xd7, 0xcf, 0xcf, 0xc2, 0xdd, 0xc5, 0x20, 0xcb, 0xc1, 0xcb, 0x2d, 0xd4, 0xcf, 0x2e, 0xa, 0x54, 0x65, 0x73, 0x74, 0x2c, 0x20, 0x74, 0x65, 0x73, 0x74, 0x2c, 0x20, 0x74, 0x65, 0x73, 0x74, 0x2c, 0x20, 0xd4, 0xc5, 0xd3, 0xd4, 0x2c, 0x20, 0xf4, 0xc5, 0xf3, 0xd4, 0x2c, 0x20, 0x74, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x65, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x2e, 0xa, 0x0
test_data_end:
