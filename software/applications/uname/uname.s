; Print current OS version and other build metadata

.include "applications/uname/uname.inc"
.include "version/version.inc"
.include "terminal/terminal.inc"

.section .text

; -- for internal use in uname_main_arg_loop!
uname_main_arg_loop_process_args:
uname_main_arg_loop_process_minus_a:
    ld bc, uname_arg_all  ; if we wanna full output?
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr z, uname_main_arg_loop_process_minus_o
    ld a, 1  ; enable
    ld (uname_os_name_output), a
    ld (uname_os_hostname_output), a
    ld (uname_os_release_output), a
    ld (uname_os_version_output), a
    ld (uname_arch_output), a
    jp uname_main_arg_loop_go_next  ; other args?

uname_main_arg_loop_process_minus_o:
    ld bc, uname_arg_o  ; if we wanna os name
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr z, uname_main_arg_loop_process_minus_n
    ld a, 1  ; enable
    ld (uname_os_name_output), a  ; setting os name output
    jp uname_main_arg_loop_go_next  ; other args?

uname_main_arg_loop_process_minus_n:
    ld bc, uname_arg_n  ; if we wanna os hostname
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr z, uname_main_arg_loop_process_minus_r
    ld a, 1  ; enable
    ld (uname_os_hostname_output), a  ; setting hostname output
    jp uname_main_arg_loop_go_next  ; other args?

uname_main_arg_loop_process_minus_r:
    ld bc, uname_arg_r  ; if we wanna os release
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr z, uname_main_arg_loop_process_minus_v
    ld a, 1  ; enable
    ld (uname_os_release_output), a  ; setting hostname output
    jp uname_main_arg_loop_go_next  ; other args?

uname_main_arg_loop_process_minus_v:
    ld bc, uname_arg_v  ; if we wanna os version
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr z, uname_main_arg_loop_process_minus_m
    ld a, 1  ; enable
    ld (uname_os_version_output), a  ; setting hostname output
    jp uname_main_arg_loop_go_next  ; other args?

uname_main_arg_loop_process_minus_m:
    ld bc, uname_arg_m  ; if we wanna arch
    push hl  ; arg2 of strcmp
    push bc  ; arg1 of strcmp
    call strcmp
    pop bc  ; strcmp result

    ld a, c  ; checking strcmp result
    or a  ; if result == true
    jr z, uname_main_arg_loop_process_other_args
    ld a, 1  ; enable
    ld (uname_arch_output), a  ; setting hostname output
    jp uname_main_arg_loop_go_next  ; other args?
uname_main_arg_loop_process_other_args:
    ; wrong arg
    pop bc  ; restoring bc
    jp uname_wrong_arg
; -- for internal use in uname_main_arg_loop! -- end

uname_main:
    push af  ; storing af
    push de  ; storing ix
    push bc  ; storing bc
    push hl  ; storing hl

    ; temp workaround before launching apps will be performed via relocations..
    ; and dynamic memmory..
    ld a, 0  ; resetting state
    ld (uname_os_name_output), a
    ld (uname_os_hostname_output), a
    ld (uname_os_release_output), a
    ld (uname_os_version_output), a
    ld (uname_arch_output), a

    ld a, (kutakbash_argc)  ; loading argc
    dec a  ; argv[0] will always present - command name
    or a  ; check if argc is 0
    jp z, uname_print_os_name_only

    ld de, kutakbash_argv  ; loading ptr ot argv
    inc de  ; argv[0] will always present - command name
    inc de  ; argv[0] will always present - command name
    ld b, a  ; loading arguments count to b reg for djnz instruction
    uname_main_arg_loop:
        push bc  ; storing bc
        ld a, (de)  ; with no offset it will be address! of argv[0]
        ld l, a  ; loading first address byte to l
        inc de
        ld a, (de)  ; getting a second address byte
        ld h, a  ; loading second address byte to h

        jp uname_main_arg_loop_process_args

        uname_main_arg_loop_go_next:
        inc de  ; going to the next arg ptr in argv
        pop bc  ; restoring bc
        djnz uname_main_arg_loop  ; itterating over arguments
    uname_main_arg_loop_end:
    jr uname_print

    uname_print_os_name_only:
    ld a, 1  ; enable
    ld (uname_os_name_output), a  ; setting os name output

    uname_print:
    uname_print_os_name:
    ld a, (uname_os_name_output)  ; check uname -o
    or a
    jr z, uname_print_os_hostname
    ld hl, os_name
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    uname_print_os_hostname:
    ld a, (uname_os_hostname_output)  ; check uname -n
    or a
    jr z, uname_print_os_release
    ld hl, os_hostname
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    uname_print_os_release:
    ld a, (uname_os_release_output)  ; check uname -r
    or a
    jr z, uname_print_os_version
    ld hl, version_git_tag
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    uname_print_os_version:
    ld a, (uname_os_version_output)  ; check uname -v
    or a
    jr z, uname_print_arch
    ld hl, version_git_branch
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    ld l, '('
    push hl
    call terminal_putchar
    ld hl, version_git_hash
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    ld hl, uname_build_on_str
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    ld hl, version_git_build_date
    push hl
    call putstr
    ld l, ')'
    push hl
    call terminal_putchar
    ld l, ' '
    push hl
    call terminal_putchar
    uname_print_arch:
    ld a, (uname_arch_output)  ; check uname -m
    or a
    jr z, uname_main_end
    ld hl, hardware_arch
    push hl
    call putstr
    jr uname_main_end

    uname_wrong_arg:
    ld bc, uname_name
    push bc
    call putstr
    ld bc, uname_semicolon
    push bc
    call putstr
    ld bc, uname_wrong_arg_str
    push bc
    call putstr
    push hl
    call putstr

    uname_main_end:
    ld hl, 0x0A  ; new line
    push hl
    call terminal_putchar

    pop hl  ; restoring hl
    pop bc  ; restoring bc
    pop de  ; restoring ix
    pop af  ; restoring af

    ret

.section .bss
uname_os_name_output:
    .skip 1
uname_os_hostname_output:
    .skip 1
uname_os_release_output:
    .skip 1
uname_os_version_output:
    .skip 1
uname_arch_output:
    .skip 1

.section .rodata
uname_name:
    .asciz "uname"

uname_semicolon:
    .asciz ": "

uname_build_on_str:
    .asciz "built on"

uname_wrong_arg_str:
    .asciz "illegal option: "

os_name:
    .asciz "DrunkOS"

; TODO: move to os variable
os_hostname:
    .asciz "localhost"

hardware_arch:
    .asciz "Z80"

uname_arg_all:
    .asciz "-a"

uname_arg_o:
    .asciz "-o"

uname_arg_n:
    .asciz "-n"

uname_arg_r:
    .asciz "-r"

uname_arg_v:
    .asciz "-v"

uname_arg_m:
    .asciz "-m"
