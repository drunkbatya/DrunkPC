; status register bits
CF_STATUS_BIT_BSY = 7
CF_STATUS_BIT_DRDY = 6
CF_STATUS_BIT_DWF = 5
CF_STATUS_BIT_DSC = 4
CF_STATUS_BIT_DRQ = 3
CF_STATUS_BIT_CORR = 2
CF_STATUS_BIT_IDX = 1
CF_STATUS_BIT_ERR = 0

; status register
STATUS_ERROR = (1 << CF_STATUS_BIT_ERR)

; features
FEATURE_ENABLE_8BIT = 0x01
FEATURE_DISABLE_8BIT = 0x81
FEATURE_DISABLE_READ_LOOK_AHEAD = 0x55
FEATURE_ENABLE_POR_ON_SOFTRES = 0xCC
FEATURE_DISABLE_POR_ON_SOFTRES = 0x66
FEATURE_4BYTE_RW_LONG = 0xBB

; commands
CMD_SET_FEATURE = 0xEF
CMD_READ_INFO = 0xEC
CMD_READ_SECTOR = 0x20
CMD_WRITE_SECTOR = 0x30

; Drive Head Register values
COMPACT_FLASH_MASTER_LBA_MODE = 0xE0

; functions
.global compactflash_await_cmd
.global compactflash_await_data
.global compactflash_init
.global compactflash_check_error
.global compactflash_set_lba_addr
.global compactflash_set_lba_addr_test
.global compactflash_read_data
.global compactflash_read_id
.global compactflash_write_data
.global compactflash_read_bytes_sequentially

; variables
.global compactflash_sector_buf
.global compactflash_init_done

; vim: set ft=asm:
