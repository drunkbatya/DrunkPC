.include "applications/cf_test/cf_test.inc"
.include "system/drivers/compactflash/compactflash.inc"
.include "terminal/terminal.inc"

.section .text

cf_test_main:
    push hl  ; storing hl

    ld a, (compactflash_init_done)  ; checking if init already completed
    or a
    jr nz, ckip_cf_init

    call compactflash_init
    pop hl
ckip_cf_init:

    ld hl, 0
    push hl  ; arg2 of compactflash_set_lba_addr
    ld hl, 0
    push hl  ; arg1 of compactflash_set_lba_addr
    call compactflash_set_lba_addr
    call compactflash_read_id
    pop hl  ; compactflash_read_data return value
    ld a, l  ; cheking success
    or a
    jr z, cf_read_fail  ; exiting immidiately if no success

    ld hl, 0x0004
    push hl  ; arg2 of compactflash_set_lba_addr
    ld hl, 0x5678
    push hl  ; arg1 of compactflash_set_lba_addr
    call compactflash_set_lba_addr ; set to 0x10000
    call compactflash_write_data
    ;pop hl  ; compactflash_write_data return value
    ;ld a, l  ; cheking success
    ;or a
    ;jr z, cf_write_fail  ; exiting immidiately if no success
    jr cf_test_end

    cf_read_fail:
    ld hl, cf_read_fail_string
    push hl
    call putstr
    jr cf_test_end

    cf_write_fail:
    ld hl, cf_write_fail_string
    push hl
    call putstr

    cf_test_end:
    pop hl  ; restoring hl
    ret


.section .rodata
cf_test_name:
    .asciz "cf_test"
cf_read_fail_string:
    .asciz "Compact Flash sector 0 read fail!\n"
cf_write_fail_string:
    .asciz "Compact Flash LBA 0x10000 write fail!\n"
