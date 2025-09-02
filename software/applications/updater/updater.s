; Update DrunkOS from CF card

.include "applications/updater/updater.inc"
.include "terminal/terminal.inc"
.include "system/drivers/compactflash/compactflash.inc"
.include "lib/stdlib/core/core.inc"
.include "system/memory/memory.inc"
.include "drivers/at28c256/at28c256.inc"

.section .text

; Update CF card structute:
;   // sector 0
;   const char[16] header,
;   uint16_t update_size,
;   const char[12] version,
;   const char[20] git_branch,
;   const char[8] git_hash_short,
;   const char[11] build_date,
;   uint8_t[512 - 69] reserved,  // to fill sector 0
;   // sector 1 - sector N
;   uint8_t[update_size] data,

UPDATE_HEADER_OFFSET = 0
UPDATE_HEADER_SIZE = 16
UPDATE_SIZE_OFFSET = (UPDATE_HEADER_OFFSET + UPDATE_HEADER_SIZE)
UPDATE_SIZE_SIZE = 2
UPDATE_VERSION_OFFSET = (UPDATE_SIZE_OFFSET + UPDATE_SIZE_SIZE)
UPDATE_VERSION_SIZE = 12
UPDATE_GIT_BRANCH_OFFSET = (UPDATE_VERSION_OFFSET + UPDATE_VERSION_SIZE)
UPDATE_GIT_BRANCH_SIZE = 20
UPDATE_GIT_HASH_SHORT_OFFSET = (UPDATE_GIT_BRANCH_OFFSET + UPDATE_GIT_BRANCH_SIZE)
UPDATE_GIT_HASH_SHORT_SIZE = 8
UPDATE_BUILD_DATE_OFFSET = (UPDATE_GIT_HASH_SHORT_OFFSET + UPDATE_GIT_HASH_SHORT_SIZE)
UPDATE_BUILD_DATE_SIZE = 11

updater_main:
    push af  ; storing af
    push hl  ; storing hl

    ld a, (compactflash_init_done)  ; checking if init already completed
    or a
    jr nz, ckip_cf_init

    call compactflash_init
    pop hl
    ld a, l  ; cheking success
    or a
    jp z, updater_end  ; exiting immidiately if no success
ckip_cf_init:
    ; cheking is a CF card attached
    ld hl, cf_checking_cf_card
    push hl
    call putstr

    ld hl, 0x0000
    push hl  ; arg2 of compactflash_set_lba_addr
    ld hl, 0x0000
    push hl  ; arg1 of compactflash_set_lba_addr
    call compactflash_set_lba_addr
    call compactflash_read_data
    pop hl  ; compactflash_read_data return value
    ld a, l  ; cheking success
    or a
    jp z, cf_print_fail  ; exiting immidiately if no success
    ld hl, done
    push hl
    call putstr

    ; checking is attached CF card is a update card
    ld hl, cf_checking_update_header
    push hl
    call putstr

    ld hl, UPDATE_HEADER_SIZE  ; length of header
    push hl  ; arg3 of memcmp
    ld hl, updater_cf_header
    push hl  ; arg2 of memcmp
    ld hl, compactflash_sector_buf
    push hl  ; arg1 of memcmp
    call memcmp  ; checking if updater header present in CF block 0
    pop hl
    ld a, l
    or a
    jp nz, cf_print_fail  ; 0 - means mem is equal
    ld hl, done
    push hl
    call putstr

    ; printing update info
    print_update_info:
    ld hl, found_str
    push hl
    call putstr
    ld hl, compactflash_sector_buf + UPDATE_VERSION_OFFSET
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    ld hl, compactflash_sector_buf + UPDATE_GIT_BRANCH_OFFSET
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    ld hl, compactflash_sector_buf + UPDATE_GIT_HASH_SHORT_OFFSET
    push hl
    call putstr
    ld l, ' '
    push hl
    call terminal_putchar
    ld hl, compactflash_sector_buf + UPDATE_BUILD_DATE_OFFSET
    push hl
    call putstr
    ld l, 0x0A
    push hl
    call terminal_putchar

    ; trying to write flash using a different patterns to ensure this writable
    ld hl, cf_checking_flash_write
    push hl
    call putstr

    call at28c256_check_is_writable
    pop hl  ; return byte
    ld a, l;  ; return status
    or a  ; check error
    jp z, cf_print_fail  ; exit if error

    ld hl, done
    push hl
    call putstr

    ; loading update size, and allocting memmory
    ld hl, cf_checking_avaliable_ram
    push hl
    call putstr

    ld hl, (compactflash_sector_buf + UPDATE_SIZE_OFFSET)
    ld (update_size), hl  ; storing new firmware size
    push hl  ; arg1 of sbrk - size
    call sbrk  ; allocating memory, this is not a malloc, so we can't free allocated ram until reboot!
    pop hl  ; return memmory address
    ld a, h  ; checking null ptr
    or l  ; if null
    jr z, cf_print_fail
    ld (new_firmware_in_ram_address), hl  ; storing allocated ram address
    ld hl, done
    push hl
    call putstr

    ; copyting new firmware from CF to allocated RAM
    ld hl, cf_copying_firmware_from_cf
    push hl
    call putstr

    ld hl, 0x0000
    push hl  ; arg2 of compactflash_set_lba_addr
    ld hl, 0x0001
    push hl  ; arg1 of compactflash_set_lba_addr
    call compactflash_set_lba_addr

    ld bc, (update_size)  ; loading update size
    ld de, (new_firmware_in_ram_address)
    ld a, c  ; check bc==0
    or b  ; check bc==0
    jp z, cf_print_fail  ; update size 0 is not allowed
    copy_update_from_cf_size_loop:
        call compactflash_read_bytes_sequentially
        pop hl  ; return byte
        ld a, h  ; return status
        or a  ; check error
        jr z, cf_print_fail  ; exit if error
        ld a, l  ; loading byte from CF
        ld (de), a  ; storing byte to RAM
        inc de  ; going to the next ram address
        dec bc  ; bc--
        ld a, c  ; check bc==0
        or b  ; check bc==0
        jr nz, copy_update_from_cf_size_loop
    copy_update_from_cf_size_loop_end:
    ld hl, done
    push hl
    call putstr

    ; asking a user for continue
    ld hl, cf_update_dialog
    push hl
    call putstr
    updater_get_input_key_loop:
        call keyboard_get_key  ; reading keyboard
        pop hl  ; return char code
        ld a, l  ; loading byte
        or a  ; if it zero?
        jr z, updater_get_input_key_loop
        ; not zero char
        ld h, 'Y'
        cp h  ; if current char (in a) is a 'Y'?
        jr z, updater_get_input_key_loop_end  ; continue the update process
        ld h, 'y'
        cp h  ; if current char (in a) is a 'y'?
        jr z, updater_get_input_key_loop_end  ; continue the update process
        jp _sflash  ; if user typed any other key, rebooting to free out memory, temp workaround before malloc function will exist
    updater_get_input_key_loop_end:

    ld hl, cf_update_wait_msg
    push hl
    call putstr

    jp update_system  ; jumping to core updater code in RAM, bye bye flash data..

    cf_print_fail:
    ld hl, fail
    push hl
    call putstr
    ld hl, cf_update_print_github
    push hl
    call putstr
    updater_end:
    pop hl  ; restoring hl
    pop af  ; restoring af
    ret

.section .bss
update_size:
    .skip 2
new_firmware_in_ram_address:
    .skip 2

; we're planing to erase(re-write) flash, so we can't execute a code from flash, but from ram we can
.section .data
update_system:
    ; erasing the flash
    ;call at28c256_erase
    ; flashing the new firmware
    ld hl, (update_size)  ; reading update size
    push hl  ; arg3 of at28c256_write_bytes
    ld hl, (new_firmware_in_ram_address)  ; reading address in ram with the new firmware
    push hl  ; arg2 of at28c256_write_bytes
    ld hl, _sflash  ; target flash addr
    push hl  ; arg1 of at28c256_write_bytes
    call at28c256_write_bytes  ; fire!
    jp _sflash  ; booting new firmware

.section .rodata
updater_name:
    .asciz "update"

done:
    .asciz "done\n"
fail:
    .asciz "fail\n"

found_str:
    .asciz "DrunkOS "

cf_checking_cf_card:
    .asciz "checking CF card..."

cf_checking_update_header:
    .asciz "checking update header..."

cf_checking_flash_write:
    .asciz "checking write to flash..."

cf_checking_avaliable_ram:
    .asciz "checking avaliable ram..."

cf_copying_firmware_from_cf:
    .asciz "copying firmware from CF..."

cf_update_dialog:
    .asciz "ready to install, proceed? (N/y)"

cf_update_wait_msg:
    .asciz "\nupdate in progress, wait.."

cf_update_print_github:
    .asciz "Please follow update instructions on:   https://github.com/drunkbatya/DrunkPC\n"

updater_cf_header:
    .byte 0x44,0x52,0x55,0x4e,0x4b,0x4f,0x53,0x55,0x50,0x44,0x41,0x54,0x45,0x52,0x52,0x00
