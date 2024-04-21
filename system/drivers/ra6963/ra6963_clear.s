.include "drivers/ra6963/ra6963.inc"

.section .text

ra6963_clear:
    push hl

    ld hl, 0  ; cleared screen value
    push hl  ; third arg of the ra6963_memset

    ld hl, RA6963_DISPLAY_WIDTH_BYTES * RA6963_DISPLAY_HEIGHT_BYTES  ; framebuffer size
    push hl  ; second  arg of the ra6963_memset

    ld hl, 0  ; start address
    push hl  ; first arg of the ra6963_memset

    call ra6963_memset

    pop hl
    ret
