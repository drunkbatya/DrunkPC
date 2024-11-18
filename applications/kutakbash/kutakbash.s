.include "applications/kutakbash/kutakbash.inc"
.include "keyboard/keyboard.inc"
.include "string/string.inc"
.include "version/version.inc"

.include "applications/test_app/test_app.inc"

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

        call kutakbash_parse_args  ; assuming input string isn't empty
        ld a, (kutakbash_argc)  ; checking error (argc setted to 0 means parse error)
        or a  ; check error
        jr z, kutakbash_main_loop  ; lopping again if error

        ; parse command
        call test_app_main  ; temp

        ; if unknown command
        ;ld de, kutakbash_no_such_file_header  ; printing error header
        ;push de
        ;call putstr

        ;ld a, (kutakbash_argv)  ; with no offset it will be address! of argv[0]
        ;ld l, a  ; loading first address byte to l
        ;ld a, (kutakbash_argv + 1)  ; getting a second address byte
        ;ld h, a  ; loading second address byte to h
        ;push hl  ; printing command
        ;call putstr

        ;ld de, kutakbash_no_such_file_msg  ; printing error
        ;push de
        ;call putstr

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

