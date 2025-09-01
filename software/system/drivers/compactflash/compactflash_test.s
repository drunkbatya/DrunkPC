.include "hardware/io.inc"
.include "drivers/compactflash/compactflash.inc"

.section .text

COMPACT_FLASH_BASE  = 0b01000000
COMPACT_FLASH_DATA  = COMPACT_FLASH_BASE + 0
COMPACT_FLASH_ERR   = COMPACT_FLASH_BASE + 1
COMPACT_FLASH_FEAT  = COMPACT_FLASH_BASE + 1
COMPACT_FLASH_SECC  = COMPACT_FLASH_BASE + 2
COMPACT_FLASH_LBA0  = COMPACT_FLASH_BASE + 3
COMPACT_FLASH_LBA1  = COMPACT_FLASH_BASE + 4
COMPACT_FLASH_LBA2  = COMPACT_FLASH_BASE + 5
COMPACT_FLASH_LBA3  = COMPACT_FLASH_BASE + 6
COMPACT_FLASH_STAT  = COMPACT_FLASH_BASE + 7
COMPACT_FLASH_CMD   = COMPACT_FLASH_BASE + 7

CMD_READ_SECT       = 0x20
CMD_WRITE_SECT      = 0x30
CMD_IDENTIFY        = 0xEC
CMD_SET_FEATURES    = 0xEF

FEAT_ENABLE_8BIT    = 0x01

STS_BSY             = 0x80
STS_DRQ             = 0x08

DHR_LBA0            = 0xE0

compactflash_write_data:
        call    cf_init_8bit

                ; LBA = 32 (0x00010000)
        ld      hl,0x5678
        ld      (lba_lo),hl
        ld      hl,0x0001
        ld      (lba_hi),hl

        ; Записать буфер на карту
        ld      hl,compactflash_sector_buf          ; HL = адрес данных
        call    cf_write_sector
        ret

; ---------------------------------------------------------------
; Функции CF
; ---------------------------------------------------------------

; Включить 8-битный PIO: SET FEATURES (feat=0x01)
cf_init_8bit:
        call    cf_wait_not_busy
        ld      a,FEAT_ENABLE_8BIT
        out     (COMPACT_FLASH_FEAT),a
        ld      a,CMD_SET_FEATURES
        out     (COMPACT_FLASH_CMD),a
        call    cf_wait_not_busy
        ret

; Ждать пока BSY=0
cf_wait_not_busy:
.wb:    in      a,(COMPACT_FLASH_STAT)
        and     STS_BSY
        jr      nz,.wb
        ret

; Ждать DRQ=1 (и BSY=0)
cf_wait_drq:
.wd:    in      a,(COMPACT_FLASH_STAT)
        and     STS_BSY
        jr      nz,.wd
        in      a,(COMPACT_FLASH_STAT)
        and     STS_DRQ
        jr      z,.wd
        ret

; Записать один сектор (512 байт) из [HL] по LBA из lba_lo/lba_hi
; Вход: HL = адрес буфера
cf_write_sector:
        push    hl                  ; сохранить адрес буфера

        ; Программируем регистры: SECC=1, LBA0..3
        call    cf_wait_not_busy
        ld      a,1
        out     (COMPACT_FLASH_SECC),a

        ld      hl,(lba_lo)
        ld      a,l
        out     (COMPACT_FLASH_LBA0),a
        ld      a,h
        out     (COMPACT_FLASH_LBA1),a

        ld      hl,(lba_hi)
        ld      a,l
        out     (COMPACT_FLASH_LBA2),a
        ld      a,h
        and     0x0F                ; биты 24..27 LBA
        or      DHR_LBA0            ; LBA mode, dev0
        out     (COMPACT_FLASH_LBA3),a

        ; Команда WRITE SECTOR
        ld      a,CMD_WRITE_SECT
        out     (COMPACT_FLASH_CMD),a

        ; Ждём DRQ=1
        call    cf_wait_drq

        ; 512 байт данных
        pop     hl
        ld      bc,512
.ws:    ld      a,(hl)
        out     (COMPACT_FLASH_DATA),a
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz,.ws

        ; Дождаться завершения
        call    cf_wait_not_busy
        ret

; ---------------------------------------------------------------
; Данные/переменные
; ---------------------------------------------------------------
        .section .bss
lba_lo:         .space  2           ; младшие 16 бит LBA
lba_hi:         .space  2           ; старшие 16 бит LBA (биты 16..31, используем 24..27)

buf512:         .space  512         ; буфер для записи
