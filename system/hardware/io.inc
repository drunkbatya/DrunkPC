; IO map:
;   A0-A3 - IO free lines
;   A4 - internal decoder low active
;   A5-A7 - IO device number in binnary
;       0b0000xxxx - device 0
;       0b1110xxxx - device 7
;       0bxxx1xxxx - decoder disabled, other bus lines are yours

IO_LCD_BASE = 0b00000000  ; A5 = 0 - device 0
IO_LCD_DATA_ADDR = IO_LCD_BASE + 0  ; lcd data transfer
IO_LCD_CMD_ADDR = IO_LCD_BASE + 1  ; lcd command transfer

IO_KBD_ADDR = 0b00100000 ; A5 = 1 - device 1

COMPACT_FLASH_BASE = 0b01000000; A6 = 1 - device 2
COMPACT_FLASH_DATA = COMPACT_FLASH_BASE + 0  ; data register, (R/W)
COMPACT_FLASH_ERR = COMPACT_FLASH_BASE + 1  ; error register, (R)
COMPACT_FLASH_FEAT = COMPACT_FLASH_BASE + 1  ; features register, (W)
COMPACT_FLASH_SECC = COMPACT_FLASH_BASE + 2  ; sector count register, (R/W)
COMPACT_FLASH_LBA0 = COMPACT_FLASH_BASE + 3  ; LBA bits 0-7 register, (R/W)
COMPACT_FLASH_LBA1 = COMPACT_FLASH_BASE + 4  ; LBA bits 8-15 register, (R/W)
COMPACT_FLASH_LBA2 = COMPACT_FLASH_BASE + 5  ; LBA bits 16-23 register, (R/W)
COMPACT_FLASH_LBA3 = COMPACT_FLASH_BASE + 6  ; LBA bits 24-27 register (bits 0-3), (R/W), and Drive Head Register, (R/W)
COMPACT_FLASH_STAT = COMPACT_FLASH_BASE + 7  ; status register, (R)
COMPACT_FLASH_CMD = COMPACT_FLASH_BASE + 7  ; command register, (W)

; vim: set ft=asm:
