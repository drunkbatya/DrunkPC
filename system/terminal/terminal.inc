TERMINAL_CHAR_WIDTH = 8
TERMINAL_CHAR_HEIGHT = 8

TERMINAL_DISPLAY_WIDTH = 240
TERMINAL_DISPLAY_HEIGHT = 64

TERMINAL_WIDTH = TERMINAL_DISPLAY_WIDTH / TERMINAL_CHAR_WIDTH
TERMINAL_HEIGHT = TERMINAL_DISPLAY_HEIGHT / TERMINAL_CHAR_HEIGHT

TERMINAL_INPUT_STRING_SIZE = 101 ; bytes

; functions
.global terminal_init
.global terminal_reset
.global terminal_putchar
.global terminal_putstr
.global terminal_cursor_right
.global terminal_cursor_newline
.global terminal_view_area_scroll_down
.global terminal_get_input_string

; variables
.global terminal_cursor_coordinates
.global terminal_view_area_address
.global terminal_input_string

; vim: set ft=asm:
