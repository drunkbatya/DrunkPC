KUTAKBASH_INPUT_STRING_SIZE = 101 ; bytes
KUTAKBASH_MAX_ARGS = 5 ; arguments
KUTAKBASH_ARGS_SEPARATOR = ' '

; functions
.global kutakbash_main
.global kutakbash_get_input_string
.global terminal_input_string
.global kutakbash_parse_args
.global kutakbash_parse_command_exec

; variables
.global kutakbash_input_string_buffer
.global kutakbash_argc
.global kutakbash_argv

; vim: set ft=asm:
