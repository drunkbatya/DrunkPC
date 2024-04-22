.include "string/string.inc"

; About:
;   Return true if given string only cosists of space or empty
; Args:
;   uint16_t size - size of memmory to allocate. Size 0 used to get highest heap address.
; Return:
;   void* ptr - pointer to the allocated memmory if allocation success,
;       pointer to the highest heap address if size == 0,
;       pointer with value 0 (NULL) if allocation failed.
; C Prototype:
;void* sbrk(uint16_t size);
sbrk:
    push af  ; storing af
    push ix  ; storing ix
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld e, (ix + 0)  ; loading low byte of size
    ld d, (ix + 1)  ; loading high byte of size

    ld a, e  ; loading low byte of size to a
    or d  ; oring low and high bytes to check if givven size is zero
    jr z, sbrk_return_highest_heap

    ld hl, (sbrk_highest_heap)  ; loading current highest heap address
    add hl, de  ; adding requested size to current highest heap address

    ; detecting registers overflow
    ld de, (sbrk_highest_heap)  ; loading current highest heap address
    or a  ; just clear carry flag
    sbc hl, de  ; subtracting current highest heap address from (current highest heap address + requested size)
    add hl, de  ; revering previous operation with saving flags
    jr c, sbrk_return_null  ; if current highest heap address > (current highest heap address + requested size)(overflow)
    jr z, sbrk_return_null  ; if current highest heap address == (current highest heap address + requested size)(overflow)

    ; detecting oversize
    ld bc, _eheap  ; loading last possible heap address (define by the linker)
    or a  ; just clear carry flag
    sbc hl, bc  ; subtracting last possible heap address from (current highest heap address + requested size) to set flags
    add hl, bc  ; revering previous operation with saving flags
    jr z, sbrk_return_success_addr  ; it's ok if we want to allocate all allowed space (_eheap == (current heap + size))
    jr nc, sbrk_return_null  ; if last possible heap address < (current highest heap address + requested size)

    sbrk_return_success_addr:
    ; all right, we can go, returning current highest heap address
    ld (ix + 0), e  ; returning low byte of current highest heap address
    ld (ix + 1), d  ; returning high byte of current highest heap address
    ld (sbrk_highest_heap), hl  ; storing new highest heap address (current highest heap address + requested size)
    jr sbrk_end

    sbrk_return_null:  ; address range from 0 to 0x4000 in use by FLASH in this case, so we can return address 0
    ld (ix + 0), 0
    ld (ix + 1), 0
    jr sbrk_end

    sbrk_return_highest_heap:
    ld hl, (sbrk_highest_heap)
    ld (ix + 0), l  ; returning low byte of highest heap
    ld (ix + 1), h  ; returning high byte of highest heap

    sbrk_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop ix  ; restoring ix
    pop af  ; restoring af

    ret


.section .data

sbrk_highest_heap:
    .word _sheap  ; _sheap, _eheap, _heap_size are defined by the linker, initially set highest heap to the heap start
