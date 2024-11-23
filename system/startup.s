.include "main.inc"
.global reset_handler
.section .reset_handler,"a",%progbits

reset_handler:
    di  ; disabling interrupts
    ld sp, _estack  ; setting up the stack pointer

    init_data_section:
        ; _sdata, _data_size and _sidata are defined by linker script
        ld bc, _data_size  ; sizeof .data section
        ld a, b  ; loading one of the size bytes to a to check if bc==0
        or c  ; check if bc==0
        jr z, init_data_section_end  ; skipping init .data section if it has zero length
        ld hl, _sidata  ; start address (in FLASH) of .data section
        ld de, _sdata  ; start address (in RAM) of .data section
        ldir  ; repeats 'ld (de), (hl)' then increments de, hl, and decrements bc until bc=0
    init_data_section_end:

    init_bss_section:
        ; _sbss and _bss_size are defined by linker script
        ld bc, _bss_size  ; sizeof .bss section
        ld hl, _sbss  ; start address of .bss section
        init_bss_section_loop:
            ld a, b  ; loading one of the size bytes to a to check if bc==0
            or c  ; check if bc==0
            jr z, init_bss_section_end  ; break if all section filled
            ld (hl), 0  ; filling current byte
            inc hl  ; inrementing .bss ptr
            dec bc  ; decrementing size counter
            jr init_bss_section_loop  ; loop
    init_bss_section_end:

    jp main
