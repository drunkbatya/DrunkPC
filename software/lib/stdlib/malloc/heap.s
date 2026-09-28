.include "lib/stdlib/malloc/heap_i.inc"

; typedef struct Block {
;     struct Block* next;
;     uint16_t size;
; } Block;
;
; typedef struct {
;     size_t total_size;
;     size_t heap_size;
;     Block* first;
;     Block* last;
; } Heap;
;
; Block* heap_find_fit(const Heap* heap, size_t size) {
;    for(Block* block = heap->first; block != NULL; block = block->next) {
;        if(block_is_free(block) && block_size(block) >= size) {
;            return block;
;        }
;    }
;    return NULL;
;}

; where:
;   block_is_free() is checing block struct->size last bit
;   block_size() is checing block struct->size without last bit


; About:
;   Internal!
;   finding a prevoiusly allocated and fried block size >= requested
; Args:
;   uint16_t size - size
; Return:
;   Block* block - ptr to found block or NULL
; C Prototype:
;    Block* heap_find_fit(uint16_t size);
heap_find_fit:
    push ix  ; storing ix
    push af  ; storing af
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ld hl, (heap_first_block)  ; addr first byte
    heap_find_fit_loop:
        ; checking NULL ptr
        ld a, l  ; if NULL
        or h  ; if NULL
        jr z, heap_find_fit_return_null  ; if current block ptr is NULL

        ; at this point we have some already allocated Block addr in hl
        ; dereferencing Block addr
        ld c, (hl)  ; adrr low byte
        inc hl
        ld b, (hl)  ; addr high byte
        push bc  ; ld hl, bc
        pop hl  ; ld hl, bc
        ; next Block addr saved in hl, crucial for next loop iter, also backed up in bc

        ; checking if current Block is free
        ; see Block struct, first 2 byte is next addr ptr, the second 2 byte is a size (with a free bit)
        inc hl  ; going to the size word
        inc hl;  ; going to the size word
        ld e, (hl)  ; dereferencing low size byte
        inc hl;
        ld d, (hl)  ; dereferencing high size byte
        dec hl  ; going back to the next Block ptr, in case of block taken
        dec hl  ; going back to the next Block ptr
        dec hl  ; going back to the next Block ptr
        bit 7, d  ; check last bit (free block mark, if 1 == block is free)
        jr z, heap_find_fit_loop  ; block is taken, continue searching

        ; current block is free
        ; checking size >= requested_size
        res 7, d  ; resetting block taken bit (without write) to compare size
        ld l, (ix + 0)  ; loading low byte of size
        ld h, (ix + 1)  ; loading high byte of size
        or a  ; sbc needs carry flag clear
        sbc hl, de  ; checking block_size (de) >= requested_size (in hl)
        add hl, de  ; reverting previous command
        jr c, heap_find_fit_block_found ;  if hl < de, if current alocated and fried block size is mode than needed
        jr z, heap_find_fit_block_found ;  if hl == de, if current alocated and fried block size is equal to needed
        jr heap_find_fit_loop  ; continue searching

        heap_find_fit_block_found:
        ; at the current moment we've got a sutable free block, blocksize >= requested_size
        ; returning that addr
        ld (ix + 0), c  ; found block low byte
        ld (ix + 1), b  ; found block high byte
        jr heap_find_fit_end

    heap_find_fit_return_null:  ; address range from 0 to 0x4000 in use by FLASH in this case, so we can return address 0
        ld (ix + 0), 0
        ld (ix + 1), 0

    heap_find_fit_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop af  ; restoring af
    pop ix  ; restoring ix
    ret

; Block* heap_extend(size_t size) {
;     uint8_t* top = sbrk(0);
;     if(top == NULL) {
;         log_err("sbrk(0) failed");
;         return NULL;
;     }
;
;     Block* last = heap_last_block;
;     if(last != NULL && block_is_free(last) && block_end(last) == top) {
;         return heap_grow_last(heap, size);
;     }
;     return heap_append(top, size);
; }
;
; where:
;   block_is_free() is checing block struct->size last bit
;   block_end() is block start + header (4) + size

; About:
;   Internal!
;   Extending heap
; Args:
;   uint16_t size - size
; Return:
;   Block* block - ptr to found block or NULL
; C Prototype:
;    Block* heap_extend(uint16_t size);
heap_extend:
    push ix  ; storing ix
    push af  ; storing af
    push hl  ; storing hl
    push de  ; storing de
    push bc  ; storing bc

    ld ix, 12  ; there is no way to set load sp value to ix, skipping pushed 5 reg pairs and the return address
    add ix, sp  ; loading sp value to ix

    ; checking sbrk(0)
    ld hl, 0  ; sbrk arg - size
    push hl  ; sbrk arg - size
    call sbrk  ; getting current heap head
    pop de  ;  getting current heap head
    ld a, e  ; checking null
    or d  ; checking null\
    jr z, heap_extend_return_null  ; if sbrk(0) returned null

    ; checking last block
    ld hl, (heap_last_block)
    ld a, l  ; addr first byte
    or h  ; addr last byte
    jr z, heap_extend_append

    ; we have last block, checking is it free
    inc hl  ; going to next block ptr last byte of Block struct
    inc hl  ; going to size first byte of Block struct
    ld c, (hl)
    inc hl  ; going to size last byte of Block struct
    ld b, (hl)
    bit 7, b  ; check last bit (free block mark, if 1 == block is free)
    jr z, heap_extend_append  ; if block isn't free

    ; last block is free, checking block_end == sbrk(0)
    ; check overflow?
    ld hl, 4  ; Block struct size
    add hl, bc  ; Block size (in bc) + block struct size
    push bc  ; storing bc
    ld bc, (heap_last_block)
    add hl, bc  ; Block size + block struct size + block addr
    pop bc  ; restoring bc
    or a  ; sbc needs carry flag clear
    sbc hl, de  ; checking block_end == sbrk(0) (in de)
    add hl, de  ; reverting previous cmd
    jr nz, heap_extend_append  ; if no allocating new block

    ; growing last allocated block
    ld l, (ix + 0)  ; loading low byte of size
    ld h, (ix + 1)  ; loading high byte of size
    or a  ; sbc needs carry flag clear
    sbc hl, bc  ; subtracting requested size (in de) from block size (in hl)
    jr heap_extend_return_addr

    ; allocating new block
    heap_extend_append:
    ld c, (ix + 0)  ; loading low byte of size
    ld b, (ix + 1)  ; loading high byte of size
    ; ? padding?
    push bc  ; arg of sbrk, requesting more mem from OS
    call sbrk
    pop de  ; ret addr, will point to new mem region start or NULL
    ld a, e  ; addr first byte
    or d  ; addr last byte
    jr z, heap_extend_return_null  ; if err != nil return err
    ; new block allocated, initializing

    ; updating heap size
    ld hl, (heap_requested_size)
    add hl, bc  ; requested size in bc
    ld (heap_requested_size), hl

    ; init new block, address in de, size in bc
    push de  ; ld hl, de
    pop hl  ; ld hl, de
    ld (hl), 0  ; new block->next ptr
    inc hl  ; goint to block->next 2nd byte
    ld (hl), 0  ; new block->next ptr
    inc hl  ; going to block->size
    ld (hl), c  ; block size first byte
    inc hl  ; going to block->size 2nd byte
    set 7, b  ; setting free bit
    ld (hl), b  ; block size last byte with free bit

    ; updating heap ptrs
    ld hl, (heap_last_block)
    ld a, l  ; if heap_last_block == NULL
    or h  ; if heap_last_block == NULL
    jr z, heap_last_block_null
    ; if heap_last_block != NULL
    ld c, (hl)  ; dereferencing heap_last_block->next
    inc hl  ; dereferencing heap_last_block->next
    ld b, (hl)  ; dereferencing heap_last_block->next
    push bc  ; ld hl, bc
    pop hl  ; ld hl, bc
    ld (hl), e  ; setting heap_last_block->next to new allocated
    inc hl  ; setting heap_last_block->next to new allocated
    ld (hl), d  ; setting heap_last_block->next to new allocated
    jr heap_extend_update_heap_last

    heap_last_block_null:
    ld (heap_first_block), de

    heap_extend_update_heap_last:
    ld (heap_last_block), de

    heap_extend_return_addr:
    ld (ix + 0), e
    ld (ix + 1), d
    jr heap_extend_end

    heap_extend_return_null:  ; address range from 0 to 0x4000 in use by FLASH in this case, so we can return address 0
    ld (ix + 0), 0
    ld (ix + 1), 0

    heap_extend_end:
    pop bc  ; restoring bc
    pop de  ; restoring de
    pop hl  ; restoring hl
    pop af  ; restoring af
    pop ix  ; restoring ix
    ret

.section .bss

heap_first_block:
    .skip 2  ; ptr to first heap block, will be obtained and incremented only by sbrk(n) call
heap_last_block:
    .skip 2  ; ptr to last heap block
heap_size:
    .skip 2

heap_requested_size:
    .skip 2  ; used to share size between internal functions, to avoid using slowly ix+n for etc
