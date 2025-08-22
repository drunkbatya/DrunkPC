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

    ld a, 0
    out (COMPACT_FLASH_LBA0), a  ; LBA 0-7 bits
    ld a, 0
    out (COMPACT_FLASH_LBA1), a  ; LBA 8-15 bits
    ld a, 0
    out (COMPACT_FLASH_LBA2), a  ; LBA 16-23 bits
    ld a, 0
    and 0b00001111  ; LBA address uses only first 4 bits (0-3), for 24-27 bits, filtering it
    or COMPACT_FLASH_MASTER_LBA_MODE
    out (COMPACT_FLASH_LBA3), a

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

    ld a, CMD_READ_INFO  ; loading read sector command
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

.section .bss

compactflash_sector_buf:
    .skip 512
