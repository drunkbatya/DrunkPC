; Print current OS version and other build metadata

.include "applications/snake/snake.inc"
.include "version/version.inc"
.include "terminal/terminal.inc"

.section .text

; snake direction
DIRECTION_UP = 0
DIRECTION_DOWN = 1
DIRECTION_LEFT = 2
DIRECTION_RIGHT = 3

; constants
MAX_SNAKE_LEN = 253
INITIAL_SNAKE_LEN = 7

snake_await_tick_process_keyboard:
    ; awaiting user input
    snake_await_tick_process_keyboard_await_keyboard:
    call keyboard_get_key  ; reading keyboard
    pop hl  ; return char code
    ld a, l  ; loading byte
    or a  ; if it zero?
    jr z, snake_await_tick_process_keyboard_await_keyboard
    ; check 'q'
    cp 'q'  ; if q pressed
    jr z, snake_await_tick_process_keyboard_end
    cp 'Q'  ; if Q pressed
    jr z, snake_await_tick_process_keyboard_end
    ;cp KBD_UP  ; if up pressed
    ;jr z, less_process_file_keyboard_up
    ;cp KBD_DOWN  ; if down pressed
    ;jr z, less_process_file_keyboard_down
    jr snake_await_tick_process_keyboard_await_keyboard  ; keyboard loop
    snake_await_tick_process_keyboard_end:
    ret

draw_snake:
    push hl
    push de
    push bc

    ld a, (snake_len)
    ld b, a
    ld hl, snake_dots
    draw_snake_loop:
        ld e, (hl)  ; x
        inc hl  ; going yo y
        ld d, (hl)  ; y
        push de  ; arg1 of ra6963_set_pixel
        call ra6963_set_pixel
        inc hl  ; next snake point
        djnz draw_snake_loop
    draw_snake_loop_end:
    pop bc
    pop de
    pop hl
    ret

init_snake:
    push hl
    push de
    push bc

    ld de, snake_dots
    ld hl, snake_dots_init
    ld bc, INITIAL_SNAKE_LEN * 2
    ldir  ; repeats 'ld (de), (hl)' then increments de, hl, and decrements bc until bc=0

    pop bc
    pop de
    pop hl
    ret

snake_main:
    call ra6963_graphic_on
    call ra6963_clear

    call init_snake

    call draw_snake

    call snake_await_tick_process_keyboard

    call terminal_init
    ret

.section .bss
snake_dots:
    .skip (2 * MAX_SNAKE_LEN)

.section .data
snake_direction:
    .byte DIRECTION_RIGHT

snake_len:
    .byte INITIAL_SNAKE_LEN

.section .rodata
snake_name:
    .asciz "snake"

snake_dots_init:
    .byte 8, 6
    .byte 7, 6
    .byte 6, 6
    .byte 5, 6
    .byte 4, 6
    .byte 3, 6
    .byte 2, 6


