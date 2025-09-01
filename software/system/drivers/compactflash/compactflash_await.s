.include "hardware/io.inc"
.include "drivers/compactflash/compactflash.inc"

COMPACT_FLASH_AWAIT_TIMEOUT = 512

; About:
;   Waits n iterations until CF is busy for recive (transfer) a data, returns false in case of time out
;   Return true if Status Register's bits:
;       CF_STATUS_BIT_BSY = 0
;       CF_STATUS_BIT_DRQ = 1
; Args:
;   None
; Return:
;   bool - return true if success, false if timed out
; C Prototype:
; bool compactflash_await_data(void);
compactflash_await_data:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push bc  ; storing bc

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld hl, COMPACT_FLASH_AWAIT_TIMEOUT  ; waiting n iterations
compactflash_await_data_loop:
    dec hl  ; decrementing timeout counter
    ld a, l  ; if if zero?
    or h  ; oring low and high bytes to check if zero
    jr z, compactflash_await_data_loop_timeout  ; timeout
    in a, (COMPACT_FLASH_STAT)  ; reading status
    bit CF_STATUS_BIT_BSY, a ; checking BUSY - This bit is set when the card internal operation is executing
    jr nz, compactflash_await_data_loop ; if no (nz flag is set means bit CF_STATUS_BIT_BSY == 1) loop again
    bit CF_STATUS_BIT_DRQ, a ; checking if the information can be transferred between the host and Data register.
    jr z, compactflash_await_data_loop ; if no (z flag is set means bit CF_STATUS_BIT_DRQ == 0) loop again
    ld (ix + 0), 1  ; returning success true
    jr compactflash_await_data_loop_end
compactflash_await_data_loop_timeout:
    ld (ix + 0), 0  ; returning success false
compactflash_await_data_loop_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

; About:
;   Waits n iterations until CF is busy for recive a command, returns false in case of time out
;   Return true if Status Register's bits are:
;       CF_STATUS_BIT_BSY = 0
;       CF_STATUS_BIT_DRDY = 1
;       CF_STATUS_BIT_DSC = 1
; Args:
;   None
; Return:
;   bool - return true if success, false if timed out
; C Prototype:
; bool compactflash_await_cmd(void);
compactflash_await_cmd:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push bc  ; storing bc

    ld ix, 10  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld hl, COMPACT_FLASH_AWAIT_TIMEOUT  ; waiting n iterations
compactflash_await_cmd_loop:
    dec hl  ; decrementing timeout counter
    ld a, l  ; if if zero?
    or h  ; oring low and high bytes to check if zero
    jr z, compactflash_await_cmd_loop_timeout  ; timeout
    in a, (COMPACT_FLASH_STAT)  ; reading status
    bit CF_STATUS_BIT_BSY, a ; checking BUSY - This bit is set when the card internal operation is executing
    jr nz, compactflash_await_cmd_loop ; if no (nz flag is set means bit CF_STATUS_BIT_BSY == 1) loop again
    bit CF_STATUS_BIT_DRDY, a ; checking drive ready - If this bit and CF_STATUS_BIT_DSC bit are set to “1”, the card is capable of receiving the read or write or seek requests
    jr z, compactflash_await_cmd_loop ; if no (z flag is set means bit CF_STATUS_BIT_DRDY == 0) loop again
    bit CF_STATUS_BIT_DSC, a  ; checking drive seek complete
    jr z, compactflash_await_cmd_loop ; if no (z flag is set means bit CF_STATUS_BIT_DSC == 0) loop again
    ld (ix + 0), 1  ; returning success true
    jr compactflash_await_cmd_loop_end
compactflash_await_cmd_loop_timeout:
    ld (ix + 0), 0  ; returning success false
compactflash_await_cmd_loop_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

