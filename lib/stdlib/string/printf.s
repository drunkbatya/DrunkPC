.include "string/string.inc"
.include "stdlib/core/core.inc"

.section .text

printf_write_char_terminal:
    push bc  ; storing bc
    ld c, a  ; loading char to a
    ld b, 0  ; dummy byte
    push bc  ; 1st arg of putchar function
    call putchar
    pop bc  ; restoring bc
    ret

printf_write_char:
    push hl  ; storing hl
    ld hl, printf_write_char_ret  ; loading return address, cause we can't `call (hl)`
    push hl  ; pushing return address
    ld hl, (printf_write_char_function)  ; loading currently selected print function
    jp (hl)  ; calling print functions
printf_write_char_ret:
    pop hl  ; restoring hl
    ret

; About:
;   Writes a formatted string to the terminal
; Args:
;   const char* format - string with format
;   ... - any variables, mentioned in the format string
; Return:
;   None
; C prototype:
;   void printf(const char* format, ...);
printf:
    push hl  ; storing hl
    ld hl, printf_write_char_terminal  ; if we'r here from `printf` call, we want to print directly to the terminal
    ld (printf_write_char_function), hl  ; storing print function address
    pop hl  ; restoring hl
    jp printf_core  ; jumping to core function


; About:
;   Writes a formatted string to the terminal
; Args:
;   const char* format - string with format
;   ... - any variables, mentioned in the format string
; Return:
;   None
; C prototype:
;   void printf(const char* format, ...);
printf_core:
    push ix  ; storing ix
    push hl  ; storing hl

    ld ix, 6  ; there is no way to set load sp value to ix, skipping pushed 2 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld l, (ix)  ; loading low byte of format
    inc ix
    ld h, (ix)  ; loading high byte of format
    inc ix
    ; next ix offset is not known untill reading format specifiers from string
    printf_format_loop:
        ld a, (hl)  ; loading format byte
        or a  ; is current byte a null terminator?
        jr z, printf_format_loop_end  ; if end of string
        cp '%'  ; is current byte is a format specifier
        jr z, printf_format_loop_parse_format
        call printf_write_char
        inc hl
        jr printf_format_loop
        printf_format_loop_parse_format:
        inc hl
        jr printf_format_loop
    printf_format_loop_end:

    pop hl  ; restoring hl
    pop ix  ; restoring ix

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    push hl  ; return address
    exx  ; restoring registers
    ret

.section .bss

printf_write_char_function:
    .skip 2
