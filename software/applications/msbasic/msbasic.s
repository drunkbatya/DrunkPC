; Test application, to check arguments parsing
; reciving int main(uint8_t argc, const char **argv)

.include "applications/msbasic/msbasic.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "string/string.inc"

.section .text

msbasic_main:
    push af  ; storing af
    push de  ; storing ix
    push bc  ; storing bc
    push hl  ; storing hl


    pop hl  ; restoring hl
    pop bc  ; restoring bc
    pop de  ; restoring ix
    pop af  ; restoring af

    ret

.section .rodata

msbasic_name:
    .asciz "msbasic"
