; Display data is PortA
; Display control is PortB

; 8255
PORTA = %00000000
PORTB = %00000001
CONTROL = %00000011

; Display
CE1 = %00000001
CE2 = %00000010
DI = %00000100
E = %00001000

control:
    ld a, %10000000
    out (CONTROL), a

disp_init:
    ld a, %11000000 ; set start line as 0
    out (PORTA), a  ; write cmd to display data line
    ld a, (CE1 | E) ; set writing to Chip1, arming strob
    out (PORTB), a
    ld a, CE1       ; disabling strob, display works on falling edge
    out (PORTB), a
    ld a, 0         ; reseting display bits
    out (PORTB), a

    ld a, %00111111 ; power on display
    out (PORTA), a
    ld a, (CE1 | E) ; set writing to Chip1, arming strob
    out (PORTB), a
    ld a, CE1       ; disabling strob, display works on falling edge
    out (PORTB), a
    ld a, 0         ; reseting display bits
    out (PORTB), a

    ld a, 036h      ; 0x36 data
    out (PORTA), a
    ld a, (CE1 | E | DI) ; set writing to Chip1, arming strob
    out (PORTB), a
    ld a, (CE1 | DI)    ; disabling strob, display works on falling edge
    out (PORTB), a
    ld a, 0         ; reseting display bits
    out (PORTB), a

loop:
    jp loop
