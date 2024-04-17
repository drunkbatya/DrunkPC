.include "main.inc"
.include "terminal/terminal.inc"
.include "applications/kutakbash/kutakbash.inc"

.section .text

main:
    call terminal_init

    ld hl, system_welcome_str
    push hl
    call terminal_putstr

    ld hl, system_test_str
    push hl
    call terminal_putstr

    call kutakbash_main

    halt

.section .rodata

system_welcome_str:
    .asciz "Welcome to DrunkOS!\n\n"

system_test_str:
    .asciz "Test.\nTest..\nTest...\nTest....\nTest.....\n"
   ;.asciz "Test.\nTest..\nTest...\nTest....\nTest.....\nTest......\n"
