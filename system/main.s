.include "main.inc"
.include "terminal/terminal.inc"
.include "string/string.inc"
.include "applications/kutakbash/kutakbash.inc"

.section .text

main:
    call terminal_init

    ld hl, system_welcome_str
    push hl
    call putstr

    ld hl, system_test_str
    push hl
    call putstr

    call kutakbash_main

    halt

.section .rodata

system_welcome_str:
    .asciz "Welcome to DrunkOS!\n\n"

system_test_str:
    .asciz "Test.\nTest..\nTest...\nTest....\nTest.....\n"
