.include "keyboard/keyboard.inc"

.section .rodata

keyboard_matrix_map:
    ; [ESC] [1] [2] [3] [4] [5] [6] [7]
    .byte 0,  '1', '2', '3', '4', '5', '6', '7'
    ; [8] [9] [0] [-] [=] [backspace] [`] [q]
    .byte '8', '9', '0', '-', '=', KBD_BACKSPACE , '`', 'q'
    ; [w] [e] [r] [t] [y] [u] [i] [o]
    .byte 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o'
    ; [p] [[] []] [\] [TAB] [a] [s] [d]
    .byte 'p', '[', ']', 92 , 0  , 'a', 's', 'd'
    ; [f] [g] [h] [j] [k] [l] [;] [']
    .byte 'f', 'g', 'h', 'j', 'k', 'l', ';', 39
    ; [return] [shift] [z] [x] [c] [v] [b] [n]
    .byte 10 , 0 , 'z', 'x', 'c', 'v', 'b', 'n'
    ; [m] [,] [.] [/] [UP] [CONTROL] [OPTION] [SPACE]
    .byte 'm', ',', '.', '/', KBD_UP  , 0  , 0  , ' '
    ; [LEFT] [DOWN] [RIGHT] and 5 dummy bytes
    .byte KBD_LEFT , KBD_DOWN , KBD_RIGHT  , 0  , 0  , 0  , 0  , 0

keyboard_matrix_map_shift:
    ; [ESC] [!] [@] [#] [$] [%] [^] [&]
    .byte 0,  '!', '@', '#', '$', '%', '^', '&'
    ; [*] [(] [)] [_] [+] [backspace] [~] [Q]
    .byte '*', '(', ')', '_', '+', KBD_BACKSPACE, '~', 'Q'
    ; [W] [E] [R] [T] [Y] [U] [I] [O]
    .byte 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O'
    ; [P] [{] [}] [|] [TAB] [A] [S] [D]
    .byte 'P', '{', '}', '|', 0  , 'A', 'S', 'D'
    ; [F] [G] [H] [J] [K] [L] [:] ["]
    .byte 'F', 'G', 'H', 'J', 'K', 'L', ':', '"'
    ; [return] [SHIFT] [Z] [X] [C] [V] [B] [N]
    .byte 10 , 0 , 'Z', 'X', 'C', 'V', 'B', 'N'
    ; [M] [<] [>] [?] [UP] [CONTROL] [OPTION] [SPACE]
    .byte 'M', '<', '>', '?', 0  , 0  , 0  , ' '
    ; [LEFT] [DOWN] [RIGHT] and 5 dummy bytes
    .byte 0  , 0  , 0  , 0  , 0  , 0  , 0  , 0

keyboard_matrix_map_control:
    ; [ESC] [1] [2] [3] [4] [5] [6] [7]
    .byte 0,  0,  0,  0,  0,  0,  0,  0
    ; [8] [9] [0] [-] [=] [backspace] [`] [q]
    .byte 0,  0,  0,  0,  0,  KBD_BACKSPACE,  0,  0
    ; [w] [e] [r] [t] [y] [u] [i] [o]
    .byte 0,  0,  0,  0,  0,  0,  0,  0
    ; [p] [[] []] [\] [TAB] [a] [s] [d]
    .byte 0,  0,  0,  0,  0,  0,  0,  0
    ; [f] [g] [h] [j] [k] [l] [;] [']
    .byte 0,  0,  0,  0,  0,  0,  0,  0
    ; [return] [shift] [z] [x] [c] [v] [b] [n]
    .byte   10,      0,  0,  0, KBD_CTRL_C,  0,  0,  0
    ; [m] [,] [.] [/] [UP] [CONTROL] [OPTION] [SPACE]
    .byte 0,  0,  0,  0,  0,  0,  0,  0
    ; [LEFT] [DOWN] [RIGHT] and 5 dummy bytes
    .byte 0,  0,  0,  0,  0,  0,  0,  0
