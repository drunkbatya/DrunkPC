.include "terminal/terminal.inc"
.include "keyboard/keyboard.inc"

.section .bss

terminal_input_string:
    .skip TERMINAL_INPUT_STRING_SIZE
