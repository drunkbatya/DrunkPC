.include "main.inc"
.include "terminal/terminal.inc"
.include "string/string.inc"
.include "stdlib/core/core.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "system/drivers/compactflash/compactflash.inc"

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
    call terminal_putchar

    ld hl, hex_str
    push hl
    call putstr

    ld hl, 16
    push hl
    ld hl, ra6963_address_pointer
    ld e, (hl)
    inc hl
    ld d, (hl)
    push de
    call putnbr

    ld hl, 0x0A
    push hl
    call terminal_putchar

    call kutakbash_main

    halt

.section .rodata

system_welcome_str:
    .asciz "Welcome to DrunkOS!\n\n"

system_test_str:
    .asciz "Test.\nTest..\nTest...\nTest....\nTest.....\n"

hex_str:
    .asciz "0x"
