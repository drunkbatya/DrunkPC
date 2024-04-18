TERMINAL_CHAR_WIDTH = 6
TERMINAL_CHAR_HEIGHT = 8

TERMINAL_DISPLAY_WIDTH = 240
TERMINAL_DISPLAY_HEIGHT = 64

TERMINAL_WIDTH = TERMINAL_DISPLAY_WIDTH / TERMINAL_CHAR_WIDTH
TERMINAL_HEIGHT = TERMINAL_DISPLAY_HEIGHT / TERMINAL_CHAR_HEIGHT

; functions
.global terminal_init
.global terminal_reset
.global terminal_cursor_right
.global terminal_cursor_newline
.global terminal_view_area_scroll_down

; variables
.global terminal_cursor_coordinates
.global terminal_view_area_address

; vim: set ft=asm:
