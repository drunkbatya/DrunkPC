.include "terminal/terminal.inc"

.section .text

terminal_view_area_scroll_down:
    push hl  ; storing hl
    push de  ; storing de

    ld hl, (terminal_view_area_address)
    ld de, TERMINAL_WIDTH
    add hl, de
    res 7, h  ; ra6963 internal address bus width is 15-bit, limitting our variable
    ld (terminal_view_area_address), hl
    push hl  ; pushing 1st arg of the ra6963_set_text_home_address function
    call ra6963_set_text_home_address  ; set new text home address

    ld de, TERMINAL_WIDTH * (TERMINAL_HEIGHT - 1)
    add hl, de  ; adding one view page to terminal view area address
    res 7, h  ; ra6963 internal address bus width is 15-bit, limitting our variable

    ld de, 0  ; cleared screen value
    push de  ; third arg of the ra6963_memset
    ld de, TERMINAL_WIDTH  ; one line
    push de  ; second arg of the ra6963_memset
    push hl  ; first arg of the ra6963_memset, start address
    call ra6963_memset

    push hl
    call ra6963_set_address_pointer

    pop de  ; restoring de
    pop hl  ; restoring hl
    ret

.section .bss

terminal_view_area_address:
    .skip 2
