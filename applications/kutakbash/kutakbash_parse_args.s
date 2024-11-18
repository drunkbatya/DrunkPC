.include "applications/kutakbash/kutakbash.inc"

.section .text

; About:
;    Parse a user string by separator (now is a space) to array of
;       pointers to substrings.
;       Example:
;           "ls -la /etc/hostname" will be parsed, and returned variables
;           will be:
;               argc: 3,
;               argv[0] = "ls",
;               argv[1] = "-la",
;               argv[2] = "/etc/hostname"
; Args:
;   None (now this function reads kutakbash_input_string_buffer)
; Return:
;   None, but kutakbash_argc value 0 means any parse error (e.g. args overflow)
;       Also in case of success kutakbash_argv will be filled
; C Prototype:
;   void kutakbash_parse_args(void);
kutakbash_parse_args:
    push hl  ; storing hl
    push bc  ; storing bc
    push af  ; storing af

    call kutakbash_parse_args_reset

    ld hl, kutakbash_input_string_buffer  ; loading string to parse
    ld de, kutakbash_argv  ; loading kutakbash_argv addr
    kutakbash_parse_args_loop:
        ld a, (hl)  ; loading a string byte
        or a  ; check if zero (null-terminator)
        jr z, kutakbash_parse_args_loop_end  ; returning if EOS

        cp KUTAKBASH_ARGS_SEPARATOR  ; check if current char is a separator
        jr z, kutakbash_parse_args_separator_found  ; if separator

        ; current char is not a separator
        ld a, (kutakbash_parse_args_separator_mark)  ; loading separator mark
        or a  ; check if separator was already found
        jr z, kutakbash_parse_args_loop_next ; if current char is not a separator and
            ; a separator mark is set, this means now we are at the word start,
            ; otherwise loop next
        ld a, 0  ; resetting a separator mark
        ld (kutakbash_parse_args_separator_mark), a  ; resetting separator mark

        ld a, (kutakbash_argc)  ; loading a current argc value
        cp KUTAKBASH_MAX_ARGS  ; does we have a space for one more arg?
        jr nc, kutakbash_parse_args_overflow  ; if KUTAKBASH_MAX_ARGS =< current argc value, raising an error
        ; if no error
        inc a  ; incrementing argc
        ld (kutakbash_argc), a  ; storing a new argc value

        ; saving current string ptr to current argv position
        push hl  ; storing user string current ptr
        pop bc  ; loading str ptr to bc
        push de  ; ld hl, de
        pop hl  ; loading a current kutakbash_argv addr to hl
        ld (hl), c  ; string low string address to kutakbash_argv
        inc hl  ; goint to next kutakbash_argv byte
        ld (hl), b  ; string high string address to kutakbash_argv
        inc de  ; current kutakbash_argv++
        inc de  ; current kutakbash_argv++ (2 bytes)
        push bc  ; ld hl, bc
        pop hl  ; restoring user string current ptr
        jr kutakbash_parse_args_loop_next

        kutakbash_parse_args_separator_found:
        ; patching original string, replace a separator to null-terminator
        ld a, 1  ; setting a separator mark
        ld (kutakbash_parse_args_separator_mark), a  ; memorizing a current char
        ld (hl), 0  ; replace a separator to null-terminator

        kutakbash_parse_args_loop_next:
        inc hl  ; itterating over the next byte
        jr kutakbash_parse_args_loop  ; looping
    kutakbash_parse_args_overflow:
    ld hl, kutakbash_parse_args_overflow_msg
    push hl
    call putstr
    ld a, 0  ; resetting argc to indicate an error
    ld (kutakbash_argc), a  ; resetting argc to indicate an error
    kutakbash_parse_args_loop_end:

    pop af  ; restoring af
    pop bc  ; restoring bc
    pop hl  ; restoring hl
    ret

kutakbash_parse_args_reset:
    ; resetting previous char
    ld a, 1
    ld (kutakbash_parse_args_separator_mark), a

    ; resetting argc
    ld a, 0
    ld (kutakbash_argc), a  ; setting argc to 0

    ; resetting argv, memset(kutakbash_argv, 0, KUTAKBASH_MAX_ARGS)
    ld bc, KUTAKBASH_MAX_ARGS * 2 ; size of kutakbash_argv
    ld hl, kutakbash_argv  ; address of kutakbash_argv
    kutakbash_parse_args_args_reset_loop:
        ld a, b  ; loading one of the size bytes to a to check if bc==0
        or c  ; check if bc==0
        jr z, kutakbash_parse_args_args_reset_loop_end  ; break if all array is filled
        ld (hl), 0  ; filling current byte
        inc hl  ; inrementing kutakbash_argv ptr
        dec bc  ; decrementing size counter
        jr kutakbash_parse_args_args_reset_loop  ; loop
    kutakbash_parse_args_args_reset_loop_end:
    ret

.section .bss

; number of parsed arguments
kutakbash_argc:
    .skip 1

; arguments may be accessed via address = kutakbash_argv + (argument number * 2)
kutakbash_argv:  ; array with pointers to parsed substrings
    .skip KUTAKBASH_MAX_ARGS * 2 ; pointer size is a "word" (2 bytes)

kutakbash_parse_args_separator_mark:  ; used for check what is current char means
    .skip 1  ; one byte, TODO: replace to flag in stack

.section .rodata

kutakbash_parse_args_overflow_msg:
    .asciz "Parse args failed due overflow!\n"
