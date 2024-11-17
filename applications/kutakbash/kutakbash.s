.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard.inc"
.include "string/string.inc"
.include "version/version.inc"

.section .text

kutakbash_main:
    push hl
    push de
    push af

    ; temp
    ld hl, test1
    push hl
    call putstr
    ld hl, version_git_hash
    push hl
    call putstr
    ld l, 0x0A
    push hl
    call putchar
    ; temp

    kutakbash_main_loop:
        ld hl, kutakbash_prompt  ; printing prompt first
        push hl
        call putstr

        call kutakbash_get_input_string  ; awaiting input string
        pop de  ; return value (0 - false, if error; 1 - true, if success)
        ld a, e  ; loading kutakbash_get_input_string return value
        or a  ; if any error (or SIGINT)?
        jr z, kutakbash_main_loop  ; skipping if false

        ld hl, kutakbash_input_string_buffer  ; filled input buffer

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
    .asciz "': unknown command\n"

test1:
    .asciz "Git hash: "

