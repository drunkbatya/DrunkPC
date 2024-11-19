; Test application, to check arguments parsing
; reciving int main(uint8_t argc, const char **argv)

.include "applications/test_app/test_app.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "string/string.inc"

.section .text

test_app_main:
    push af  ; storing af
    push de  ; storing ix
    push bc  ; storing bc
    push hl  ; storing hl

    ld a, (kutakbash_argc)  ; loading argc
    or a  ; check if argc is 0
    jr z, test_app_main_arg_loop_end

    ld b, a  ; loading arguments count to b reg for djnz instruction
    ld de, kutakbash_argv  ; loading ptr ot argv

    test_app_main_arg_loop:
        ld hl, test_app_main_msg_recieved_arg
        push hl
        call putstr

        ld a, (de)  ; with no offset it will be address! of argv[0]
        ld l, a  ; loading first address byte to l
        inc de
        ld a, (de)  ; getting a second address byte
        ld h, a  ; loading second address byte to h
        inc de
        push hl  ; printing arg
        call putstr
        ; print

        ld l, 0x0A
        push hl
        call putchar

        djnz test_app_main_arg_loop  ; itterating over arguments
    test_app_main_arg_loop_end:

    pop hl  ; restoring hl
    pop bc  ; restoring bc
    pop de  ; restoring ix
    pop af  ; restoring af

    ret

.section .rodata

test_app_name:
    .asciz "test_app"

test_app_main_msg_recieved_arg:
    .asciz "Recieved arg: "
