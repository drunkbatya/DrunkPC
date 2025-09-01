ENTRY(reset_handler)

_min_stack_size = 5K;

MEMORY {
    FLASH (xrw) : ORIGIN = 0x0000, LENGTH = 16K
    SRAM (xrw) : ORIGIN = 0x4000, LENGTH = 48K
}

_estack = ORIGIN(SRAM) + LENGTH(SRAM);

SECTIONS {
    .reset_handler : {
        KEEP(*(.reset_handler))
    } >FLASH

    .text : {
        *(.text)
        *(.text*)
        _etext = .;
    } >FLASH

    .rodata : {
        *(.rodata)
        *(.rodata*)
    } >FLASH

    _sidata = LOADADDR(.data);
    .data : {
        _sdata = .;
        *(.data)
        *(.data*)
        _edata = .;
    } >SRAM AT> FLASH
    _data_size = SIZEOF(.data);

    .bss : {
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } >SRAM
    _bss_size = SIZEOF(.bss);

    _sheap = .;
    _eheap = ORIGIN(SRAM) + LENGTH(SRAM) - _min_stack_size;
    _heap_size = _eheap - _sheap;

    _sflash = ORIGIN(FLASH);
    _eflash = _sflash + LENGTH(FLASH) - 1;

}
