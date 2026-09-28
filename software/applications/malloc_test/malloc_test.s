; Test malloc

.include "applications/malloc_test/malloc_test.inc"
.include "terminal/terminal.inc"
.include "lib/stdlib/malloc/malloc.inc"
.include "lib/stdlib/string/string.inc"

.section .text

malloc_test_main:
    push hl  ; storing hl

    ld hl, 100  ; allocating bytes
    push hl  ; 1st arg of malloc
    call malloc
    pop hl  ; malloc return value
    ld a, h  ; checking NULL
    or l  ; if returned NULL
    jr z, malloc_test_print_err

    jr malloc_test_end
    malloc_test_print_err:
    ld hl, malloc_test_err_str
    push hl  ; str to print
    call putstr
    malloc_test_end:
    pop hl  ; restoring hl
    ret

.section .rodata

malloc_test_name:
    .asciz "mt"
malloc_test_err_str:
    .asciz "malloc failed\n"
