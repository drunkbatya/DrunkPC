.include "hardware/io.inc"
.include "drivers/compactflash/compactflash.inc"

.section .text

; About:
;   Sets Logical Block Address
; Args:
;   uint64_t addr - block address
; Return:
;   None
; C Prototype:
;   void compactflash_set_lba_addr(uint64_t addr);
compactflash_set_lba_addr:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl

    ld ix, 8  ; there is no way to set load sp value to ix, skipping pushed 2 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 0)
    ld l, a  ; low bits, low word
    out (COMPACT_FLASH_LBA0), a  ; LBA 0-7 bits
    ld a, (ix + 1)
    ld h, a  ; high bits, low word
    ld (compactflash_lba_lo), hl  ; storing address low word
    out (COMPACT_FLASH_LBA1), a  ; LBA 8-15 bits
    ld a, (ix + 2)
    ld l, a  ;  low bits, high word
    out (COMPACT_FLASH_LBA2), a  ; LBA 16-23 bits
    ld a, (ix + 3)
    and 0b00001111  ; LBA address uses only first 4 bits (0-3), for 24-27 bits, filtering it
    ld h, a  ; high bits, high word
    ld (compactflash_lba_hi), hl  ; storing address hi word
    or COMPACT_FLASH_MASTER_LBA_MODE
    out (COMPACT_FLASH_LBA3), a

    ld hl, 0x0000
    ld (compactflash_read_bytes_sequentially_byte_offset), hl

    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers
    ret

; About:
;   Reads a Compact Flash ID to the compactflash_sector_buf
;   Returns true in case of success
; Args:
;   None
; Return:
;   bool success - if success, false overwise
; C Prototype:
;   bool compactflash_read_id(void);
compactflash_read_id:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; stroing hl
    push de  ; stroing de
    push bc  ; stroing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; check busy?

    ld a, 1  ; attempting to read one sector
    out (COMPACT_FLASH_SECC), a  ; writing to the sector count register

    call compactflash_await_cmd  ; awaiting ready for recive a cmd
    pop hl  ; compactflash_await_cmd success
    ld a, l  ; loading return value to a
    or a  ; check success
    jr z, compactflash_read_id_false  ; returning false if false

    ld a, CMD_READ_INFO  ; loading read sector command
    out (COMPACT_FLASH_CMD), a  ; writing read sector command

    call compactflash_check_error  ; checking error
    pop hl  ; compactflash_check_error success
    ld a, l  ; loading return value to a
    or a  ; check success
    jr z, compactflash_read_id_false  ; returning false if false

    ld hl, compactflash_sector_buf  ; loading buffer ptr
    ld b, 0  ; reading 512 bytes by 256 x 2 operations
    ; TODO use DRQ to indicate EOS?
compactflash_read_id_loop:
    call compactflash_await_data
    pop de  ; compactflash_await_data success
    ld a, e  ; loading return value to a
    or a  ; check success
    ;jr z, compactflash_read_id_false  ; returning false if false
    in a, (COMPACT_FLASH_DATA)  ; reading data register value (first loop byte)
    ld (hl), a  ; storing readed byte to the buffer
    inc hl  ; inc ptr
    call compactflash_await_data
    pop de  ; compactflash_await_data success
    ld a, e  ; loading return value to a
    or a  ; check success
    jr z, compactflash_read_id_false  ; returning false if false
    in a, (COMPACT_FLASH_DATA)  ; reading data register value (next loop byte)
    ld (hl), a  ; storing readed byte to the buffer
    inc hl  ; inc ptr
    djnz compactflash_read_id_loop  ; looping
compactflash_read_id_loop_end:
    ld (ix + 0), 1  ; returning success true
    jr compactflash_read_id_end
compactflash_read_id_false:
    ld (ix + 0), 0  ; returning success false
compactflash_read_id_end:
    pop bc  ; restoring bc
    pop de  ; restroing de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

; About:
;   Reads one sector to from Compact Flash card to the compactflash_sector_buf
;   Address must be set by call compactflash_set_lba_addr
;   Returns true in case of success
; Args:
;   None
; Return:
;   bool success - if success, false overwise
; C Prototype:
;   bool compactflash_read_data(void);
compactflash_read_data:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; stroing hl
    push de  ; stroing de
    push bc  ; stroing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; check busy?

    ld a, 1  ; attempting to read one sector
    out (COMPACT_FLASH_SECC), a  ; writing to the sector count register

    call compactflash_await_cmd  ; awaiting ready for recive a cmd
    pop hl  ; compactflash_await_cmd success
    ld a, l  ; loading return value to a
    or a  ; check success
    jr z, compactflash_read_data_false  ; returning false if false

    ld a, CMD_READ_SECTOR  ; loading read sector command
    out (COMPACT_FLASH_CMD), a  ; writing read sector command

    call compactflash_check_error  ; checking error
    pop hl  ; compactflash_check_error success
    ld a, l  ; loading return value to a
    or a  ; check success
    jr z, compactflash_read_data_false  ; returning false if false

    ld hl, compactflash_sector_buf  ; loading buffer ptr
    ld b, 0  ; reading 512 bytes by 256 x 2 operations
    ; TODO use DRQ to indicate EOS?
compactflash_read_data_loop:
    call compactflash_await_data
    pop de  ; compactflash_await_data success
    ld a, e  ; loading return value to a
    or a  ; check success
    ;jr z, compactflash_read_data_false  ; returning false if false
    in a, (COMPACT_FLASH_DATA)  ; reading data register value (first loop byte)
    ld (hl), a  ; storing readed byte to the buffer
    inc hl  ; inc ptr
    call compactflash_await_data
    pop de  ; compactflash_await_data success
    ld a, e  ; loading return value to a
    or a  ; check success
    jr z, compactflash_read_data_false  ; returning false if false
    in a, (COMPACT_FLASH_DATA)  ; reading data register value (next loop byte)
    ld (hl), a  ; storing readed byte to the buffer
    inc hl  ; inc ptr
    djnz compactflash_read_data_loop  ; looping
compactflash_read_data_loop_end:
    ld (ix + 0), 1  ; returning success true
    jr compactflash_read_data_end
compactflash_read_data_false:
    ld (ix + 0), 0  ; returning success false
compactflash_read_data_end:
    pop bc  ; restoring bc
    pop de  ; restroing de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret
; About:
;   Writes one sector to Compact Flash card from compactflash_sector_buf
;   Address must be set by call compactflash_set_lba_addr
;   Returns true in case of success
; Args:
;   None
; Return:
;   bool success - if success, false overwise
; C Prototype:
;   bool compactflash_write_data(void);
;compactflash_write_data:
;    exx  ; exchanging register pairs with their shadow
;    pop hl  ; return address
;    push hl  ; one more reg for return value
;    push hl  ; pushing return pointer back
;    exx  ; restoring register pairs
;
;    push af  ; storing af
;    push ix  ; storing ix
;    push hl  ; stroing hl
;    push de  ; stroing de
;    push bc  ; stroing bc
;
;    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and the return address
;    add ix, sp  ; loading sp value to ix
;
;    ; check busy?
;
;    ld a, 1  ; attempting to write one sector
;    out (COMPACT_FLASH_SECC), a  ; writing to the sector count register
;
;    call compactflash_await_cmd  ; awaiting ready for recive a cmd
;    pop hl  ; compactflash_await_cmd success
;    ld a, l  ; loading return value to a
;    or a  ; check success
;    ;jr z, compactflash_write_data_false  ; returning false if false
;
;    ld a, CMD_WRITE_SECTOR  ; loading write sector command
;    out (COMPACT_FLASH_CMD), a  ; writing write sector command
;
;    call compactflash_await_data  ; checking error
;    pop hl  ; compactflash_check_error success
;    ld a, l  ; loading return value to a
;    or a  ; check success
;    ;jr z, compactflash_write_data_false  ; returning false if false
;
;    ld hl, compactflash_sector_buf  ; loading buffer ptr
;    ld b, 0  ; reading 512 bytes by 256 x 2 operations
;    ; TODO use DRQ to indicate EOS?
;compactflash_write_data_loop:
;    ;call compactflash_await_data
;    ;pop de  ; compactflash_await_data success
;    ;ld a, e  ; loading return value to a
;    ;or a  ; check success
;    ;jr z, compactflash_write_data_false  ; returning false if false
;    ld a, (hl)  ; reading byte from the buffer
;    out (COMPACT_FLASH_DATA), a  ; writing data register value (first)
;    inc hl  ; inc ptr
;    ;call compactflash_await_data
;    ;pop de  ; compactflash_await_data success
;    ;ld a, e  ; loading return value to a
;    ;or a  ; check success
;    ;jr z, compactflash_write_data_false  ; returning false if false
;    ld a, (hl)  ; reading byte from the buffer
;    out (COMPACT_FLASH_DATA), a  ; writing data register value (second)
;    inc hl  ; inc ptr
;    djnz compactflash_write_data_loop  ; looping
;compactflash_write_data_loop_end:
;    ld (ix + 0), 1  ; returning success true
;    jr compactflash_write_data_end
;compactflash_write_data_false:
;    ld (ix + 0), 0  ; returning success false
;compactflash_write_data_end:
;    pop bc  ; restoring bc
;    pop de  ; restroing de
;    pop hl  ; restoring hl
;    pop ix  ; restoring ix
;    pop af  ; restoring af
;    ret

; About:
;   Reads a bytes from Compact Flash sequentially
;   Does an automatic reading sectors.
;   Initial address must be set by call compactflash_set_lba_addr
; Args:
;   None
; Return:
;   uint8_t data - byte from CF (low byte)
;   bool success - if success, false overwise (high byte)
; C Prototype:
;   uint8_t compactflash_read_bytes_sequentially(void);
compactflash_read_bytes_sequentially:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; stroing hl
    push bc  ; stroing bc

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld bc, (compactflash_read_bytes_sequentially_byte_offset)  ; loading current offset inside a 512 block
    ld a, b  ; check bc==0
    or c  ; check bc==0
    jr nz, compactflash_read_bytes_sequentially_skip_block_read  ; if offset is 0, reading next (or first byte)
    call compactflash_read_data  ; reading current sector to buf
    pop hl  ; compactflash_read_data return value, TODO: proceed
    ld a, l  ; return code
    or a  ; check if error
    jr z, compactflash_read_bytes_sequentially_error
    compactflash_read_bytes_sequentially_skip_block_read:
    ld hl, compactflash_sector_buf  ; loading buffer address
    add hl, bc  ; adding offset
    ld a, (hl)  ; reading current byte
    ld (ix + 0), a  ; returning byte

    inc bc  ; going to the next byte inside a 512 block

    ; check offset >= 512
    bit 1, b  ; >=512 is a 9-th bit set, using high 8 bits from offset - it will be a 1-st (after 0) bit
    jr z, compactflash_read_bytes_sequentially_skip_block_switch
    ld bc, 0x0000
    call compactflash_next_lba

    compactflash_read_bytes_sequentially_skip_block_switch:
    ld (compactflash_read_bytes_sequentially_byte_offset), bc  ; storing offset

compactflash_read_bytes_sequentially_success:
    ld (ix + 1), 1  ; returning true
    jr compactflash_read_bytes_sequentially_end

compactflash_read_bytes_sequentially_error:
    ld (ix + 1), 0  ; returning false

compactflash_read_bytes_sequentially_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret


compactflash_next_lba:
    push af  ; storing af
    push bc  ; storing bc

    ld bc, (compactflash_lba_lo)  ; going to next lba, trying to inc low byte
    inc bc
    ld (compactflash_lba_lo), bc  ; storing modified low byte
    ld a, c  ; checking low byte overflow
    or b  ; checking low byte overflow
    jr nz, compactflash_next_lba_end  ; if no overflow, just exit
    ld bc, (compactflash_lba_lo)  ; if overflow we need to inc high byte
    inc bc
    ld (compactflash_lba_lo), bc  ; storing modified low byte
    compactflash_next_lba_end:
    call compactflash_set_lba_addr_from_local
    pop bc  ; restoring bc
    pop af  ; restoring af
    ret

; About:
;   Sets Logical Block Address from local variable
; Args:
;   Noe
; Return:
;   None
; C Prototype:
;   void compactflash_set_lba_addr_from_local(void);
compactflash_set_lba_addr_from_local:
    push af  ; storing af
    push hl  ; storing hl

    ld hl, (compactflash_lba_lo); storing address low word
    ld a, l  ; low bits, low word
    out (COMPACT_FLASH_LBA0), a  ; LBA 0-7 bits
    ld a, h  ; high bits, low word
    out (COMPACT_FLASH_LBA1), a  ; LBA 8-15 bits
    ld hl, (compactflash_lba_hi)  ; storing address hi word
    ld a, l  ;  low bits, high word
    out (COMPACT_FLASH_LBA2), a  ; LBA 16-23 bits
    ld a, h  ; high bits, high word
    and 0b00001111  ; LBA address uses only first 4 bits (0-3), for 24-27 bits, filtering it
    or COMPACT_FLASH_MASTER_LBA_MODE
    out (COMPACT_FLASH_LBA3), a

    ld hl, 0x0000
    ld (compactflash_read_bytes_sequentially_byte_offset), hl

    pop hl  ; restoring hl
    pop af  ; restoring af

    ret

.section .bss

compactflash_sector_buf:
    .skip 512

compactflash_read_bytes_sequentially_byte_offset:
    .skip 2

compactflash_lba:
compactflash_lba_lo:
    .skip 2
compactflash_lba_hi:
    .skip 2
