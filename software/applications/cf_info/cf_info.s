; Print CompactFlash info

.include "applications/cf_info/cf_info.inc"
.include "terminal/terminal.inc"
.include "system/drivers/compactflash/compactflash.inc"
.include "lib/stdlib/core/core.inc"

.section .text

cf_info_main:
    push hl  ; storing hl

    ld a, (compactflash_init_done)  ; checking if init already completed
    or a
    jr nz, ckip_cf_init

    call compactflash_init
    pop hl
ckip_cf_init:

    ld hl, 0x0001
    push hl  ; arg2 of compactflash_set_lba_addr
    ld hl, 0x2345
    push hl  ; arg1 of compactflash_set_lba_addr
    call compactflash_set_lba_addr
    call compactflash_read_id
    pop hl  ; compactflash_read_id return value
    ld a, l  ; cheking success
    or a
    jp z, cf_read_fail  ; exiting immidiately if no success

    ; printing Model
    ld hl, cf_read_model_string
    push hl  ; arg1 of putstr
    call putstr

    ld hl, compactflash_sector_buf
    ld de, 54  ; serial start address is 54
    add hl, de
    ld de, 40  ; model number is 40 bytes long
    push de  ; arg2 of memswap function
    push hl  ; arg1 of memswap function
    call memswap
    push hl  ; arg1 of putstr function
    ld de, 30  ; setting \0 to str, limmiting 30 bytes
    add hl, de
    ld (hl), 0
    call putstr

    ld l, 0x0A
    push hl
    call terminal_putchar

    ; Printing serial
    ld hl, cf_read_serial_string
    push hl  ; arg1 of putstr
    call putstr

    ld hl, compactflash_sector_buf
    ld de, 20  ; serial start address in 20
    add hl, de
    ld de, 20  ; model number is 20 bytes long
    push de  ; arg2 of memswap function
    push hl  ; arg1 of memswap function
    call memswap
    push hl  ; arg1 of putstr function
    ld de, 20  ; setting \0 to str, limmiting 20 bytes
    add hl, de
    ld (hl), 0
    call putstr

    ld l, 0x0A
    push hl
    call terminal_putchar

    ; Printing size
    ld hl, cf_read_size_string
    push hl  ; arg1 of putstr
    call putstr

    ld hl, compactflash_sector_buf
    ld de, 120  ; serial start address is 114
    add hl, de
    ;ld de, 4  ; model number is 4 bytes long
    ;push de  ; arg2 of memswap function
    ;push hl  ; arg1 of memswap function
    ;call memswap
    ; printing msw first
    inc hl
    inc hl
    ld de, 10  ; arg2 of putnbr function, base
    push de  ; arg2 of putnbr function, base
    push hl  ; arg1 of dereference_uint16 function, return value in stack - arg1 of putnbr
    call dereference_uint16
    call putnbr
    dec hl
    dec hl
    ld de, 10  ; arg2 of putnbr function, base
    push de  ; arg2 of putnbr function, base
    push hl  ; arg1 of dereference_uint16 function, return value in stack - arg1 of putnbr
    call dereference_uint16
    call putnbr

    ld l, 0x0A
    push hl
    call terminal_putchar

    jr cf_info_end

    cf_read_fail:
    ld hl, cf_read_fail_string
    push hl
    call putstr

    cf_info_end:
    pop hl  ; restoring hl
    ret

.section .rodata

cf_info_name:
    .asciz "cf_info"

cf_read_fail_string:
    .asciz "Compact Flash sector 0 read fail!\n"

cf_read_model_string:
    .asciz "Model: "

cf_read_serial_string:
    .asciz "Serial: "

cf_read_size_string:
    .asciz "Size: "
