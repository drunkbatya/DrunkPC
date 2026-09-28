.include "lib/stdlib/malloc/malloc.inc"
.include "lib/stdlib/malloc/heap_i.inc"

.include "system/memory/memory.inc"
.global malloc_total_mem_size

.section .text

; About:
;   Memory allocation
; Args:
;   uint16_t size - size of memmory to allocate.
; Return:
;   void* ptr - pointer to the allocated memmory if allocation success,
;       pointer with value 0 (NULL) if allocation failed.
; C Prototype:
;   void* malloc(uint16_t size);
malloc:
    push ix  ; storing ix
    push af  ; storing af
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld e, (ix + 0)  ; loading low byte of size
    ld d, (ix + 1)  ; loading high byte of size

    ; catch malloc(0)
    ld a, e  ; check size == 0
    or d  ; check size == 0
    jr z, malloc_return_null  ; return NULL if malloc(0)

    ; align up size in de?
    ; searching already allocated free block
    push de  ; arg of heap_find_fit - requested size
    call heap_find_fit
    pop bc  ; found block addr
    ld a, c  ; check addr == 0
    or b  ; check addr == 0
    jr z, malloc_extend_heap

    malloc_split_heap:
    push de  ; requested size
    push bc  ; previously found block addr
    ;call heap_split  ; splitting found block
    pop bc  ; splitted block addr
    jr malloc_check_block

    ; if we have no already allocated free blocks
    malloc_extend_heap:
    push de  ; requested size
    call heap_extend
    pop bc  ; extended or new block

    ; now we have splitted or extended or matched block, check it, addr in bc
    malloc_check_block:
    ld a, c  ; check addr == 0
    or b  ; check addr == 0
    jr z, malloc_return_null

    ; set block is taken, block addr in bc, see Block struct to understand
    inc bc  ; going to size word
    inc bc  ; going to size word
    inc bc  ; going to last size byte
    push bc  ; ld hl, bc
    pop hl  ; ld hl, bc
    set 7, (hl)  ; setting taken bit
    inc bc  ; going to first data byte addr in block
    inc hl  ; going to first data byte addr in block in HL too for next op, bc == hl here

    ; memset(0), first data addr in bc and hl, size in DE, keeping bc clear to return
    malloc_memset_loop:
        ld a, e  ; checking size == 0
        or d  ; checking size == 0
        jr z, malloc_memset_loop_end  ; memset done when size == 0
        ld (hl), 0  ; memset value
        inc hl  ; going to next data byte
        jr malloc_memset_loop
     malloc_memset_loop_end:

    ; return block with the Block header struct offset
    ld (ix + 0), c
    ld (ix + 1), b
    jr malloc_end

    malloc_return_null:  ; address range from 0 to 0x4000 in use by FLASH in this case, so we can return address 0
    ld (ix + 0), 0
    ld (ix + 1), 0

    malloc_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop af  ; restoring af
    pop ix  ; restoring ix
    ret

.section .rodata
malloc_total_mem_size:
    .word _heap_size
