.include "applications/kutakbash/kutakbash.inc"
.include "string/string.inc"

.include "applications/test_app/test_app.inc"
.include "applications/clear/clear.inc"
.include "applications/disp_ptr/disp_ptr.inc"
.include "applications/less/less.inc"
.include "applications/cf_info/cf_info.inc"
.include "applications/cf_test/cf_test.inc"
.include "applications/updater/updater.inc"
.include "applications/snake/snake.inc"

.section .text

kutakbash_parse_command_exec:  ; TODO: probably, this relates to whole system, not to shell
    exx  ; exchanging register pairs with their shadow
    pop hl  ; return address
    push bc  ; add one more arg cause functions recives none and returns 1 arg
    push hl  ; pushing return pointer back
    exx  ; restroing register pairs

    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld hl, internal_commands
    ld b, (internal_commands_end - internal_commands) / 4  ; sizeof(Command)

    ; getting command name from cmd args
    ld a, (kutakbash_argv)  ; with no offset it will be address! of argv[0]
    ld e, a  ; loading first address byte to e
    ld a, (kutakbash_argv + 1)  ; getting a second address byte
    ld d, a  ; loading second address byte to d
    ; command name now in de

    ; TODO check empty commands array
    kutakbash_parse_command_exec_loop:
        push de  ; storing command name from cmd args

        push de  ; arg2 of strcmp, command name from cmd args
        ; dereferencing current command name ptr
        ld e, (hl)  ; low address byte
        inc hl
        ld d, (hl)  ; getting a high address byte
        inc hl
        push de  ; arg1 of strcmp, current command name
        call strcmp
        pop de  ; strcmp return value

        ld a, e  ; loading strcmp return value
        or a  ; check strcmp return bool value
        jr nz, kutakbash_parse_command_exec_found  ; true if equal

        ; going next
        ld de, 2  ; sizeof(Command) - two inc'es lines up
        add hl, de  ; itterating over commands array, going next

        pop de  ; restoring command name from cmd args
        djnz kutakbash_parse_command_exec_loop
    ld (ix + 0), 0  ; return false, command not found
    jr kutakbash_parse_command_exec_loop_end

    kutakbash_parse_command_exec_found:  ; exec!!!
    ld (ix + 0), 1  ; return true, command is found
    pop de  ; just clearing the stack, de is pushed a couple lines up

    ; why this CPU can't just "call (hl)"?..
    ld de, kutakbash_parse_command_exec_loop_end  ; return address
    push de  ; pushing return address to stack

    ; dereferencing current command entrypoint ptr
    ld e, (hl)  ; low address byte
    inc hl
    ld d, (hl)  ; getting a high address byte
    push de  ; ld hl, de
    pop hl  ; ld hl, de
    jp (hl)  ; i hope we'll be back..

    kutakbash_parse_command_exec_loop_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret

.section .rodata

;   typedef struct {
;       const char* command_name;
;       void* command_entrypoint
;   } Command;

internal_commands:  ; TODO: separate this to compile-time templated file
    ; test_app
    .word test_app_name
    .word test_app_main
    ; test_app
    ; clear
    .word clear_name
    .word clear_main
    ; clear
    ; disp_ptr
    .word disp_ptr_name
    .word disp_ptr_main
    ; disp_ptr
    ; less
    .word less_name
    .word less_main
    ; less
    ; cf_info
    .word cf_info_name
    .word cf_info_main
    ; cf_info
    ; cf_test
    .word cf_test_name
    .word cf_test_main
    ; cf_test
    ; uname
    .word uname_name
    .word uname_main
    ; uname
    ; updater
    .word updater_name
    .word updater_main
    ; updater
    ; snake
    .word snake_name
    .word snake_main
    ; snake
internal_commands_end:  ; just to know the size..
