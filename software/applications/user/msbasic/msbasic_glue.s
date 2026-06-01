.include "applications/msbasic/msbasic.inc"
.include "system/drivers/compactflash/compactflash.inc"

; BASIC workspace pointers
.equ BASTXT, WRKSPC + 0x055  ; ptr to start of program
.equ PROGND, WRKSPC + 0x0CD  ; ptr to byte after program
.equ VAREND, WRKSPC + 0x0CF  ; ptr to end of variables
.equ ARREND, WRKSPC + 0x0D1  ; ptr to end of arrays

; SAVE/LOAD format constants
.equ BASIC_SAVE_LBA_LO, 0x0800  ; 1 MB / 512 byte sectors
.equ BASIC_SAVE_LBA_HI, 0x0000
.equ BASIC_SAVE_HEADER_SIZE, (save_magic_end - save_magic) + 2  ; magic + 16-bit size
.equ BASIC_SAVE_SECTOR_SIZE, 512
.equ BASIC_SAVE_FIRST_CHUNK, BASIC_SAVE_SECTOR_SIZE - BASIC_SAVE_HEADER_SIZE
.equ BASIC_SAVE_MAX_SIZE, 8192  ; 16 sectors of data, more than in-RAM cap

.section .text

; About:
;   Saves the current BASIC program to the CF save slot. The on-disk image
;   spans as many sectors as needed; the last one is zero-padded.
; Args:
;   None
; Return:
;   No return value; control falls through to BRKRET on success or to a
;   BASIC ERROR handler on failure.
.global SAVE
SAVE:
    ret nz  ; abort if more chars on input line, GETCHR will set nz if any arg is present

    ld hl, (PROGND)  ; HL = end of program
    ld de, (BASTXT)  ; DE = start of program
    or a  ; clear carry for sbc
    sbc hl, de  ; HL = size in bytes
    ld (save_size), hl  ; stash for later steps

    ld de, BASIC_SAVE_MAX_SIZE + 1  ; cap test value
    or a  ; clear carry for sbc
    sbc hl, de  ; HL = size - (MAX + 1)
    jp nc, OMERR  ; size > MAX -> ?OM Error

    call save_ensure_cf_ready  ; init CF if not already done
    or a  ; check success
    jp z, HXERR  ; CF init failure -> ?HX Error

    call relocate_to_offsets  ; convert in-memory links to offsets

    ld hl, (save_size)
    ld (save_remaining), hl  ; bytes still to write
    ld hl, (BASTXT)
    ld (save_ptr), hl  ; current read position
    ld hl, BASIC_SAVE_LBA_LO
    ld (save_lba), hl  ; current sector LBA

    call sector_buf_clear  ; zero tail of partial sector
    ld hl, save_magic  ; copy magic
    ld de, compactflash_sector_buf
    ld bc, save_magic_end - save_magic
    ldir  ; magic at offset 0
    ld hl, (save_size)
    ld (compactflash_sector_buf + (save_magic_end - save_magic)), hl  ; size at offset 4
    call save_chunk_first  ; copy first program chunk -> buf+8

    call cf_write_current_sector  ; write the first sector
    or a  ; check success
    jp z, save_io_failed

    save_loop:
        ld hl, (save_remaining)
        ld a, h  ; check if anything left
        or l
        jp z, save_done

        ld hl, (save_lba)
        inc hl  ; advance to next sector
        ld (save_lba), hl

        call sector_buf_clear  ; zero-pad partial last sector
        call save_chunk_next  ; copy up to 512 bytes -> buf

        call cf_write_current_sector
        or a  ; check success
        jp z, save_io_failed

        jr save_loop

    save_done:
    call relocate_to_absolute  ; restore in-memory links
    jp BRKRET

    save_io_failed:
    call relocate_to_absolute  ; keep BASIC sane before erroring
    jp HXERR


; About:
;   Restores a BASIC program from the CF save slot, overwriting whatever
;   is currently in memory and clearing variables/arrays/strings.
; Args:
;   None
; Return:
;   No return value; falls through to BRKRET on success or to a BASIC
;   ERROR handler on failure.
.global LOAD
LOAD:
    ret nz  ; abort if more chars on input line

    call save_ensure_cf_ready  ; init CF if not already done
    or a  ; check success
    jp z, HXERR  ; CF init failure -> ?HX Error

    ld hl, BASIC_SAVE_LBA_LO
    ld (save_lba), hl  ; LBA for the first sector
    call cf_read_current_sector
    or a  ; check success
    jp z, HXERR

    ld hl, compactflash_sector_buf  ; verify header
    ld de, save_magic
    ld b, save_magic_end - save_magic
    load_magic_check:
        ld a, (de)
        cp (hl)
        jp nz, UFERR  ; no save here / corrupt -> ?UF Error
        inc hl
        inc de
        djnz load_magic_check

    ld hl, (compactflash_sector_buf + (save_magic_end - save_magic))  ; pull size from header
    ld (save_size), hl
    ld (save_remaining), hl

    ld de, BASIC_SAVE_MAX_SIZE + 1  ; cap test value
    or a  ; clear carry for sbc
    sbc hl, de  ; HL = size - (MAX + 1)
    jp nc, OMERR  ; size > MAX -> corrupt or too big

    ld hl, (BASTXT)
    ld (save_ptr), hl  ; current write position
    call load_chunk_first  ; copy buf+8 -> BASTXT

    load_loop:
        ld hl, (save_remaining)
        ld a, h  ; check if anything left
        or l
        jp z, load_done

        ld hl, (save_lba)
        inc hl
        ld (save_lba), hl  ; advance to next sector

        call cf_read_current_sector
        or a  ; check success
        jp z, HXERR

        call load_chunk_next  ; copy buf -> save_ptr

        jr load_loop

    load_done:
    ld hl, (BASTXT)  ; PROGND = BASTXT + size
    ld de, (save_size)
    add hl, de  ; add doesn't need cf clear
    ld (PROGND), hl

    call relocate_to_absolute  ; offset -> absolute for current BASTXT

    ld hl, (PROGND)  ; clear variables/arrays from any state before LOAD
    ld (VAREND), hl
    ld (ARREND), hl

    jp BRKRET


; About:
;   Copies min(save_remaining, 504) bytes from save_ptr into the sector
;   buffer at offset BASIC_SAVE_HEADER_SIZE, then decrements save_remaining
;   and advances save_ptr past the copied bytes.
; Args:
;   None (reads save_remaining, save_ptr).
; Return:
;   None. Clobbers AF, BC, DE, HL.
save_chunk_first:
    call save_chunk_compute_first  ; BC = chunk size
    ld de, compactflash_sector_buf + BASIC_SAVE_HEADER_SIZE  ; copy destination
    jr save_chunk_do_copy

; About:
;   Same as save_chunk_first but for a full 512-byte sector (no header offset).
save_chunk_next:
    call save_chunk_compute_full  ; BC = chunk size
    ld de, compactflash_sector_buf  ; copy destination

save_chunk_do_copy:
    ; BC = chunk, DE = destination, save_ptr = source
    ld a, b
    or c  ; check if chunk == 0
    ret z  ; nothing to do
    push bc  ; remember chunk count for the decrement
    ld hl, (save_ptr)
    ldir  ; HL and DE advance by BC bytes
    ld (save_ptr), hl
    pop bc
    ld hl, (save_remaining)
    or a  ; clear carry for sbc
    sbc hl, bc  ; remaining -= chunk
    ld (save_remaining), hl
    ret


; About:
;   Returns in BC the number of bytes to copy this sector:
;   min(save_remaining, BASIC_SAVE_FIRST_CHUNK) for the first sector
;   or min(save_remaining, BASIC_SAVE_SECTOR_SIZE) for subsequent ones.
; Args:
;   None (reads save_remaining).
; Return:
;   BC = chunk size. Clobbers AF, DE, HL.
save_chunk_compute_first:
    ld bc, BASIC_SAVE_FIRST_CHUNK  ; default cap
    ld de, BASIC_SAVE_FIRST_CHUNK
    jr save_chunk_compute_common

save_chunk_compute_full:
    ld bc, BASIC_SAVE_SECTOR_SIZE  ; default cap
    ld de, BASIC_SAVE_SECTOR_SIZE

save_chunk_compute_common:
    ld hl, (save_remaining)
    or a  ; clear carry for sbc
    sbc hl, de  ; HL = remaining - cap
    ret nc  ; remaining >= cap -> BC keeps cap
    add hl, de  ; restore HL = remaining (< cap)
    ld c, l  ; BC = remaining
    ld b, h
    ret


; About:
;   Mirror of save_chunk_first: copies min(save_remaining, 504) bytes from
;   the sector buffer at offset BASIC_SAVE_HEADER_SIZE into save_ptr, then
;   decrements save_remaining and advances save_ptr.
; Args:
;   None.
; Return:
;   None. Clobbers AF, BC, DE, HL.
load_chunk_first:
    call save_chunk_compute_first  ; BC = chunk size
    ld hl, compactflash_sector_buf + BASIC_SAVE_HEADER_SIZE  ; copy source
    jr load_chunk_do_copy

; About:
;   Same as load_chunk_first but for a full 512-byte sector (no header).
load_chunk_next:
    call save_chunk_compute_full  ; BC = chunk size
    ld hl, compactflash_sector_buf

load_chunk_do_copy:
    ; BC = chunk, HL = sector-buffer source, save_ptr = destination
    ld a, b
    or c  ; check if chunk == 0
    ret z  ; nothing to do
    push bc
    ld de, (save_ptr)
    ldir  ; HL and DE advance by BC bytes
    ld (save_ptr), de
    pop bc
    ld hl, (save_remaining)
    or a  ; clear carry for sbc
    sbc hl, bc  ; remaining -= chunk
    ld (save_remaining), hl
    ret


; About:
;   Issues a write of the current sector buffer to the LBA in save_lba.
;   LBA high word is always zero - we never go above 16 sectors of data.
; Args:
;   None (reads save_lba, compactflash_sector_buf).
; Return:
;   A = 1 on success, A = 0 on failure.
;   Clobbers AF, BC, DE, HL (the CF stack-return path).
cf_write_current_sector:
    ld hl, BASIC_SAVE_LBA_HI
    push hl  ; arg2 of compactflash_set_lba_addr
    ld hl, (save_lba)
    push hl  ; arg1 of compactflash_set_lba_addr
    call compactflash_set_lba_addr  ; callee cleans both args
    call compactflash_write_data
    pop hl  ; L = success flag from stack-return
    ld a, l
    ret

; About:
;   Mirror of cf_write_current_sector: reads one sector at save_lba into
;   compactflash_sector_buf.
cf_read_current_sector:
    ld hl, BASIC_SAVE_LBA_HI
    push hl
    ld hl, (save_lba)
    push hl
    call compactflash_set_lba_addr
    call compactflash_read_data
    pop hl
    ld a, l
    ret


; About:
;   Zeroes the 512-byte compactflash_sector_buf. Used before filling a write
;   sector so the unused tail of the last (partial) sector is zero-padded
;   instead of leaking whatever was previously there.
; Args:
;   None.
; Return:
;   None. Clobbers AF, BC, DE, HL.
sector_buf_clear:
    ld hl, compactflash_sector_buf
    ld (hl), 0  ; seed first byte
    ld de, compactflash_sector_buf + 1
    ld bc, BASIC_SAVE_SECTOR_SIZE - 1
    ldir  ; propagate the zero across the buffer
    ret


; About:
;   Runs compactflash_init exactly once across the BASIC session by checking
;   the driver's own compactflash_init_done flag first.
; Args:
;   None.
; Return:
;   A = 1 if the card is ready, A = 0 on init failure.
;   Clobbers AF, HL.
save_ensure_cf_ready:
    ld a, (compactflash_init_done)
    or a  ; already initialized?
    ld a, 1  ; pre-load success
    ret nz  ; yes -> return success without touching the card
    call compactflash_init
    pop hl  ; consume stack-return slot
    ld a, l  ; A = init success/fail flag
    ret


; About:
;   Walks the BASIC linked-list program and converts each non-zero forward
;   link from an absolute address into an offset from BASTXT. The terminating
;   link == 0 marks end-of-program and is left untouched.
; Args:
;   None (reads BASTXT).
; Return:
;   None. Clobbers AF, BC, DE, HL.
relocate_to_offsets:
    ld hl, (BASTXT)  ; HL = ptr to current link
    relocate_to_offsets_loop:
        ld e, (hl)  ; DE = current link value
        inc hl
        ld d, (hl)
        dec hl  ; HL back to link low byte
        ld a, d
        or e  ; link == 0?
        ret z  ; end of program -> done

        push de  ; remember absolute link for the walk to the next line
        ex de, hl  ; HL = abs link, DE = ptr-to-link
        ld bc, (BASTXT)
        or a  ; clear carry for sbc
        sbc hl, bc  ; HL = abs - BASTXT = offset
        ex de, hl  ; HL = ptr-to-link, DE = offset
        ld (hl), e  ; write offset low byte
        inc hl
        ld (hl), d  ; write offset high byte

        pop hl  ; HL = saved abs link -> next line
        jr relocate_to_offsets_loop


; About:
;   Inverse of relocate_to_offsets: each non-zero link is treated as an
;   offset from BASTXT and rewritten as an absolute address. After updating
;   a link we follow the NEW absolute value to reach the next line.
; Args:
;   None (reads BASTXT).
; Return:
;   None. Clobbers AF, BC, DE, HL.
relocate_to_absolute:
    ld hl, (BASTXT)  ; HL = ptr to current link
    relocate_to_absolute_loop:
        ld e, (hl)  ; DE = current link value
        inc hl
        ld d, (hl)
        dec hl  ; HL back to link low byte
        ld a, d
        or e  ; link == 0?
        ret z  ; end of program -> done

        ex de, hl  ; HL = offset, DE = ptr-to-link
        ld bc, (BASTXT)
        add hl, bc  ; HL = offset + BASTXT = abs (add doesn't need cf clear)
        ex de, hl  ; HL = ptr-to-link, DE = abs link
        ld (hl), e  ; write abs low byte
        inc hl
        ld (hl), d  ; write abs high byte

        ex de, hl  ; HL = new abs link -> next line
        jr relocate_to_absolute_loop


.section .rodata

save_magic:
    .ascii "MSBS"
save_magic_end:


.section .bss

; Streaming state shared between SAVE and LOAD (only one runs at a time).
save_size:
    .skip 2  ; total program size
save_remaining:
    .skip 2  ; bytes still to transfer
save_ptr:
    .skip 2  ; cursor inside BASIC prog area
save_lba:
    .skip 2  ; current sector LBA (low word)

; vim: ft=asm
