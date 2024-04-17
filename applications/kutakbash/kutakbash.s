.include "applications/kutakbash/kutakbash.inc"
.include "terminal/terminal.inc"
.include "keyboard/keyboard.inc"

.section .text

kutakbash_main:
    push hl
    push de
    push af

    kutakbash_main_loop:
        ld hl, kutakbash_prompt  ; printing prompt first
        push hl
        call terminal_putstr

        call terminal_get_input_string  ; awaiting input string
        pop hl  ; return value
        ld a, (hl)  ; loading first char
        or a  ; ; if empty string?
        jr z, kutakbash_main_loop  ; skipping

        ; check signals?

        ; strtok?

        ; parse command

        ; if unknown command
        ld de, kutakbash_no_such_file_header  ; printing error header
        push de
        call terminal_putstr

        push hl  ; printing user input buffer value
        call terminal_putstr

        ld de, kutakbash_no_such_file_msg  ; printing error
        push de
        call terminal_putstr

        jr kutakbash_main_loop  ; loop

    pop af
    pop de
    pop hl
    ret

.section .rodata

kutakbash_prompt:
    .asciz ":-> "
kutakbash_no_such_file_header:
    .asciz "KutakBash: '"
kutakbash_no_such_file_msg:
    .asciz "': unknown instruction\n"
