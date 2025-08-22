.include "hardware/io.inc"
.include "drivers/compactflash/compactflash.inc"

.section .text

; About:
;   Checks if Compact Flash reports an error status in the status register
;   Return true if Status Register's bits are:
;       CF_STATUS_BIT_ERR = 0
; Args:
;   None
; Return:
;   bool - return true if success, false if timed out
; C Prototype:
; bool compactflash_check_error(void);
compactflash_check_error:
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push hl  ; one more reg for return value
    push hl  ; pushing return pointer back
    exx  ; restoring register pairs

    push af  ; storing af
    push ix  ; storing ix

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    in a, (COMPACT_FLASH_STAT)  ; reading status
    bit CF_STATUS_BIT_ERR, a ; checking ERR - This bit is set when the previous command has ended in some type of error.
    jr nz, compactflash_check_error_false ; check error bit (nz flag is set means bit CF_STATUS_BIT_ERR == 1)
    ld (ix + 0), 1  ; returning success true
    jr compactflash_check_error_end
compactflash_check_error_false:
    ld (ix + 0), 0  ; returning success false
compactflash_check_error_end:
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

