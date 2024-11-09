.include "main.inc"
.include "terminal/terminal.inc"
.include "string/string.inc"
.include "stdlib/core/core.inc"
.include "applications/kutakbash/kutakbash.inc"

.section .text

main:
    call terminal_init

    ld hl, system_welcome_str
    push hl
    call putstr

    ld hl, 10
    push hl
    ld hl, system_welcome_str
    push hl
    call putnbr

    ld hl, 0x0A
    push hl
    call putchar

    ld hl, hex_str
    push hl
    call putstr

    ld hl, 16
    push hl
    ld hl, system_welcome_str
    push hl
    call putnbr

    ld hl, 0x0A
    push hl
    call putchar

    ;call compactflash_init
    ;pop hl

    ;call compactflash_set_lba_addr
    ;call compactflash_read_data
    ;pop hl
    ;ld a, l
    ;or a
    ;jr z, cf_read_fail
;cf_read_done:
    ;ld hl, test_str1
    ;jr cf_read_report
;cf_read_fail:
    ;ld hl, test_str0
;cf_read_report:
    ;push hl
    ;call putstr

    ;ld hl, compactflash_sector_buf
    ;ld de, 54
    ;add hl, de
    ;push hl  ; storing ptr
    ;ld de, 10
    ;add hl, de
    ;ld (hl), 0
    ;call putstr

    call kutakbash_main

    halt

.section .rodata

system_welcome_str:
    .asciz "Welcome to DrunkOS!\n\n"

system_test_str:
    .asciz "Test.\nTest..\nTest...\nTest....\nTest.....\n"

hex_str:
    .asciz "0x"

test_str0:
    .asciz "Compact Flash sector 0 read fail!!\n"
test_str1:
    .asciz "Compact Flash sector 0 read done!\n"

