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

    ;ld hl, system_test_str
    ;push hl
    ;call strrev
    ;push hl
    ;call putstr

    ld hl, 10
    push hl
    ld hl, itoa_buffer_temp
    push hl
    ld hl, 0x1234
    push hl
    call itoa

    ld hl, itoa_buffer_temp
    push hl
    call putstr

    ld hl, 0x0A
    push hl
    call putchar

    ld hl, 16
    push hl
    ld hl, itoa_buffer_temp
    push hl
    ld hl, 0x1234
    push hl
    call itoa

    ld hl, itoa_buffer_temp
    push hl
    call putstr

    ld hl, 0x0A
    push hl
    call putchar

    ld hl, 16
    push hl
    ld hl, itoa_buffer_temp
    push hl
    ld hl, 0
    push hl
    call itoa

    ld hl, itoa_buffer_temp
    push hl
    call putstr

    ld hl, 0x0A
    push hl
    call putchar

    ld hl, itoa_buffer_temp
    push hl

    call kutakbash_main

    halt

.section .rodata

system_welcome_str:
    .asciz "Welcome to DrunkOS!\n\n"

system_test_str:
    .asciz "Test.\nTest..\nTest...\nTest....\nTest.....\n"

.section .bss

itoa_buffer_temp:
    .skip 20
