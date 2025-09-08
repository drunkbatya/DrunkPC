; Print current OS version and other build metadata

.include "applications/snake/snake.inc"
.include "version/version.inc"
.include "terminal/terminal.inc"

.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"
.include "keyboard/keyboard_codes.inc"

.section .text

; snake direction
DIRECTION_UP = 0
DIRECTION_RIGHT = 1
DIRECTION_DOWN = 2
DIRECTION_LEFT = 3

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
    jr z, timer_move_snake
    ; check 'q'
    cp 'q'  ; if q pressed
    jr z, snake_await_tick_process_keyboard_end
    cp 'Q'  ; if Q pressed
    jr z, snake_await_tick_process_keyboard_end
    cp KBD_UP  ; if up pressed
    jr z, snake_up
    cp KBD_DOWN  ; if down pressed
    jr z, snake_down
    cp KBD_LEFT  ; if left pressed
    jr z, snake_left
    cp KBD_RIGHT  ; if right pressed
    jr z, snake_right
    jr timer_move_snake

    snake_up:
    ld a, DIRECTION_UP
    ld (snake_direction), a
    jr no_key
    snake_down:
    ld a, DIRECTION_DOWN
    ld (snake_direction), a
    jr no_key
    snake_left:
    ld a, DIRECTION_LEFT
    ld (snake_direction), a
    jr no_key
    snake_right:
    ld a, DIRECTION_RIGHT
    ld (snake_direction), a
    jr no_key

    timer_move_snake:
    call clear_display
    call move_snake
    call draw_snake

    no_key:
    jr snake_await_tick_process_keyboard_await_keyboard  ; keyboard loop
    snake_await_tick_process_keyboard_end:
    ret

move_snake:
    call snake_set_next_step
    call snake_step
    ret

snake_step:
    push hl  ; storing hl
    push de  ; storing de

    ld hl, (snake_len)  ; loading snake len
    add hl, hl  ; sizeof(snakePoint) = x and y = snake_len * 2
    push hl  ; arg3 of memmove - size
    ld hl, snake_dots
    push hl  ; arg2 of memmove - src arr
    ld hl, snake_dots + 2
    push hl  ; arg1 of memmove - dst arr
    call memmove

    ld hl, snake_next_step  ; snake_next_step need to be set by snake_set_next_step function
    ld e, (hl)  ; dereferencing next step
    inc hl
    ld d, (hl)  ; dereferencing next step
    ld (snake_dots), de  ; setting moved snake_dots head with the new dot

    pop de  ; restoring de
    pop hl  ; restoring hl
    ret

snake_set_next_step:
    push af  ; storing af
    push hl  ; storing hl

    ld hl, (snake_dots)  ; loading current last point, h - y, l - x

    ld a, (snake_direction)  ; loading snake direction
    cp DIRECTION_UP
    jr z, snake_set_next_step_direction_up
    cp DIRECTION_RIGHT
    jr z, snake_set_next_step_direction_right
    cp DIRECTION_DOWN
    jr z, snake_set_next_step_direction_down
    cp DIRECTION_LEFT
    jr z, snake_set_next_step_direction_left
    jr snake_set_next_step_end_do_nothing  ; if not any match

    snake_set_next_step_direction_up:
    dec h  ; y--
    jr snake_set_next_step_end

    snake_set_next_step_direction_down:
    inc h  ; y++
    jr snake_set_next_step_end

    snake_set_next_step_direction_right:
    inc l  ; x++
    jr snake_set_next_step_end

    snake_set_next_step_direction_left:
    dec l  ; x--
    jr snake_set_next_step_end

    snake_set_next_step_end:
    ld (snake_next_step), hl  ; storing next step
    snake_set_next_step_end_do_nothing:

    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

draw_snake:
    push af
    push hl
    push de
    push bc

    ld a, (snake_len)
    ld b, a
    ld hl, snake_dots
    draw_snake_loop:
        ld de, 0x0404   ; arg2 of ra6963_draw_box - size_x, size_y
        push de

        ld e, (hl)  ; x
        inc hl  ; going yo y
        ld d, (hl)  ; y

        ; multiplying x by 4(snake size)
        push bc  ; storing bc
        ld b, 3  ; snake size
        ld a, e  ; loading x
        draw_snake_loop_multiply_by_4_loop_x:
            add a, e
            djnz draw_snake_loop_multiply_by_4_loop_x
        ld e, a  ; multiplyed value

        ; multiplying y by 4(snake size)
        ld b, 3  ; snake size
        ld a, d  ; loading y
        draw_snake_loop_multiply_by_4_loop_y:
            add a, d
            djnz draw_snake_loop_multiply_by_4_loop_y
        ld d, a  ; multiplyed value
        pop bc  ; restoring bc

        push de  ; arg1 of ra6963_set_pixel

        call ra6963_draw_box

        inc hl  ; next snake point
        djnz draw_snake_loop
    draw_snake_loop_end:
    pop bc
    pop de
    pop hl
    pop af
    ret

clear_display:
    push hl  ; storing hl
    ld hl, 0  ; arg3 for ra6963_memset - value
    push hl
    ld hl, 2560  ; arg2 for ra6963_memset - size (240/6 * 64)
    push hl
    ld hl, 0  ; arg1 for ra6963_memset - address
    push hl
    call ra6963_memset
    pop hl  ; restoring hl
    ret

init_snake:
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld de, snake_dots  ; dst arr
    ld hl, snake_dots_init  ; src arr
    ld bc, INITIAL_SNAKE_LEN * 2  ; arr size
    ldir  ; repeats 'ld (de), (hl)' then increments de, hl, and decrements bc until bc=0

    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    ret

write_byte:
    call ra6963_await_cmd_or_data
    out (IO_LCD_DATA_ADDR), a  ; writing a char
    ld a, RA6963_DATA_WRITE_AND_INC_ADDR  ; display address pointer will be incremented
    call ra6963_await_cmd_or_data
    out (IO_LCD_CMD_ADDR), a
    ret

snake_main:
    call ra6963_graphic_on
    call clear_display

    call init_snake

    call snake_await_tick_process_keyboard

    call terminal_init
    ret

.section .bss
snake_dots:
    .skip (2 * MAX_SNAKE_LEN)

snake_next_step:
    .skip 2

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

