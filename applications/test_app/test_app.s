; Test application, to check arguments parsing
; reciving int main(uint8_t argc, const char **argv)

.include "applications/test_app/test_app.inc"
.include "string/string.inc"

.section .text

test_app_main:
    push ix  ; storing ix
    push hl  ; storing hl

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 2 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld a, (ix + 0)  ; loading arguments count (argc) to a to check zero
    or a  ; oring a with a to check if no cmd line arguments passed
    jr z, test_app_main_arg_loop_end  ; if no arguments, do nothing
    ld b, a  ; loading arguments count to b reg for djnz instruction

    test_app_main_arg_loop:
        ld l, (ix + 0)  ; ptr to arg, low byte
        ld h, (ix + 1)  ; ptr to arg, high byte
        ;ld hl, 

        ld hl, test_app_main_msg_recieved_arg
        push hl
        call putstr

        ; print

        ld l, 0x0A
        push hl
        call putchar

        djnz test_app_main_arg_loop  ; itterating over arguments
    test_app_main_arg_loop_end:

    pop hl  ; restoring hl
    pop ix  ; restoring ix

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers
    ret

.section .rodata

test_app_main_msg_recieved_arg:
    .asciz "Recieved arg: "
