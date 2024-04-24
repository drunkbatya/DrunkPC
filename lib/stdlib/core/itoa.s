.include "stdlib/core/core.inc"
.include "string/string.inc"

.section .text

; About:
;   Writes a character representation of unsigned 16-bit integer to buffer
; Args:
;   uint16_t number - number to convert
;   unsigned char *buffer - buffer to write a character representation, must be less than 5 bytes
;   uint8_t base - base (8, 10, 16, etc)
; Return:
;   None, but number character representation will be written to buffer
; C prototype:
;   void itoa(uint16_t number, unsigned char *buffer, uint8_t base);
itoa:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 3 reg pairs and return address
    add ix, sp  ; loading sp value to ix

    ld e, (ix + 0)  ; loading low byte of number
    ld d, (ix + 1)  ; loading high byte of number

    ld l, (ix + 2)  ; loading low byte of string ptr
    ld h, (ix + 3)  ; loading high byte of string ptr

    ld c, (ix + 4)  ; loading low byte of base
    ld b, 0  ; base has uint8_t type

    ld a, e  ; loading low byte of number
    or d  ; or'ing with high byte of number to check if zero
    jr z, itoa_zero  ; if number is zero

    itoa_loop:
        ld a, e  ; loading low byte of number
        or d  ; or'ing with high byte of number to check if zero
        jr z, itoa_loop_end  ; looping untill num != 0
        push hl  ; storing string pointer, freeing hl for sbc
        ld hl, 0  ; loading 0 to hl due to ld instruction limitation
        add hl, de  ; (ld hl, de), loading number to hl for sbc instruction
        ld de, 0  ; we don't need original number anymore
        itoa_divide_loop:  ; (number / base) and (number % base) loop
            or a  ; just clear carry flag
            sbc hl, bc  ; comparing base with number
            add hl, bc  ; reverting previous command
            jr c, itoa_divide_loop_end  ; if number < base
            or a  ; just clear carry flag
            sbc hl, bc  ; subtraction base from number
            inc de  ; interger part of division
            jr itoa_divide_loop
        itoa_divide_loop_end:  ; interger part of division in de, reminder in hl
        ld a, l  ; loading reminder (uint8_t)
        cp 9  ; if reminder > 9?
        jr c, itoa_loop_rem_less_or_eq_than_9  ; if reminder < 9
        jr z, itoa_loop_rem_less_or_eq_than_9  ; if reminder == 9
        itoa_loop_rem_more_than_9:
        sub 10  ; subtracting 10 from reminder
        add a, 'A'  ; adding 'A' char code to reminder
        jr itoa_loop_write_char
        itoa_loop_rem_less_or_eq_than_9:
        add a, 48  ; add '0' char code to reminder
        itoa_loop_write_char:
        pop hl  ; restoring string pointer
        ld (hl), a  ; writing string char, current digit
        inc hl
        jr itoa_loop
    itoa_loop_end:
    ld (hl), 0  ; adding null-terminator to string
    ; setting string pointer to beginning
    ld l, (ix + 2)  ; loading low byte of string ptr
    ld h, (ix + 3)  ; loading high byte of string ptr
    push hl  ; pushing our reverted string pointer
    call strrev  ; reverting string to proper format
    jr itoa_end

    itoa_zero:
    ld (hl), 48  ; '0'  loading 0 digit to string
    inc hl
    ld (hl), 0  ; '\0'  null-terminator

    itoa_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    exx  ; exchanging register pairs with they shadow
    pop hl  ; return address
    pop bc  ; removing arg1
    pop bc  ; removing arg2
    pop bc  ; removing arg3
    push hl  ; return address
    exx  ; restoring registers
    ret

