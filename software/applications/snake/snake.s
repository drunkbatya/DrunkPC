; Print current OS version and other build metadata

.include "applications/snake/snake.inc"
.include "version/version.inc"
.include "terminal/terminal.inc"

.include "drivers/ra6963/ra6963.inc"
.include "hardware/io.inc"

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

clear_display:
    push hl  ; storing hl
    ld hl, 0  ; arg3 for ra6963_memset - value
    push hl
    ld hl, 1920  ; arg2 for ra6963_memset - size
    push hl
    ld hl, 0  ; arg1 for ra6963_memset - address
    push hl
    call ra6963_memset
    pop hl  ; restoring hl

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

    ld hl, 0x0000
    push hl
    call ra6963_set_address_pointer

    ld a, 0x3F
    call write_byte
    ld a, 0
    call write_byte
    ld a, 0xF0
    call write_byte
    ld a, 0x0F
    call write_byte

    ;ld hl, 0x00EF
    ;push hl
    ;call ra6963_set_pixel

    ;ld hl, 0x3FEF
    ;push hl
    ;call ra6963_set_pixel

    ;ld hl, 0x3F00
    ;push hl
    ;call ra6963_set_pixel

    ;call init_snake

    ;call draw_snake

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


