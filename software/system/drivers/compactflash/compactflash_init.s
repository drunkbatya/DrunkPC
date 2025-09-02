.include "hardware/io.inc"
.include "drivers/compactflash/compactflash.inc"

.section .text

; About:
;   Initialize a Compact Flash card
; Args:
;   None
; Return:
;   bool - return true if success, false if timed out
; C Prototype:
; bool compactflash_init(void);
compactflash_init:
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

    call compactflash_await_cmd  ; waiting busy
    pop hl  ; compactflash_await_cmd return value
    ld a, l  ; load return value to a
    or a  ; check if success
    jr z, compactflash_init_fail  ; return false if fail

    ld a, FEATURE_ENABLE_8BIT  ; loading feature byte
    out (COMPACT_FLASH_FEAT), a  ; writing to the features register

    call compactflash_await_cmd  ; waiting busy
    pop hl  ; compactflash_await_cmd return value
    ld a, l  ; load return value to a
    or a  ; check if success
    jr z, compactflash_init_fail  ; return false if fail

    ld a, CMD_SET_FEATURE  ; loading command
    out (COMPACT_FLASH_CMD), a  ; writing command

    call compactflash_await_cmd  ; waiting busy
    pop hl  ; compactflash_await_cmd return value
    ld a, l  ; load return value to a
    or a  ; check if success
    jr z, compactflash_init_fail  ; return false if fail

    ld a, COMPACT_FLASH_MASTER_LBA_MODE  ; setting master dev and LBA mode
    out (COMPACT_FLASH_LBA3), a  ; writing to the LBA3 register

    call compactflash_await_cmd  ; waiting busy
    pop hl  ; compactflash_await_cmd return value
    ld a, l  ; load return value to a
    or a  ; check if success
    jr z, compactflash_init_fail  ; return false if fail

    call compactflash_check_error
    pop hl  ; compactflash_check_error return value
    ld a, l  ; load return value to a
    or a  ; check if success
    jr z, compactflash_init_fail  ; return false if fail
compactflash_init_success:
    ld (ix + 0), 1  ; returning success true
    ld a, 1
    ld (compactflash_init_done), a
    jr compactflash_init_end
compactflash_init_fail:
    ld hl, compactflash_init_fail_msg
    push hl
    call putstr
    ld (ix + 0), 0  ; returning success false
    ld a, 0
    ld (compactflash_init_done), a
compactflash_init_end:
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af
    ret

.section .rodata
compactflash_init_fail_msg:
    .asciz "CF init fail\n"
