; functions
.global keyboard_scan
.global keyboard_get_char
.global keyboard_get_key

; variables
.global keyboard_matrix_map
.global keyboard_matrix_map_shift
.global keyboard_matrix_map_control

.include "keyboard/keyboard_codes.inc"

; vim: ft=asm
