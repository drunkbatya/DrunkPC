.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard.inc"
.include "string/string.inc"

.section .text

kutakbash_main:
    push hl
    push de
    push af

    kutakbash_main_loop:
        ld hl, kutakbash_prompt  ; printing prompt first
        push hl
        call putstr

        call kutakbash_get_input_string  ; awaiting input string
        pop hl  ; return value

        push hl  ; 1st arg of strisspaceorempty func - input string
        call strisspaceorempty
        pop de  ; strisspaceorempty return value
        ld a, e  ; loading strisspaceorempty return value
        or a  ; if empty or only space-d string?
        jr nz, kutakbash_main_loop  ; skipping if true

        ; check signals?

        ;push hl  ; pushing input buffer
        ; strtok?

        ; parse command

        ; if unknown command
        ld de, kutakbash_no_such_file_header  ; printing error header
        push de
        call putstr

        push hl  ; printing user input buffer value
        call putstr

        ld de, kutakbash_no_such_file_msg  ; printing error
        push de
        call putstr

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
