; ============================================================================
; MS BASIC port to DrunkPC
;
; BASIC's contract for the glued symbols (TXA/RXA/RXA_CHK):
;   A         = input (TXA char to output) or output (RXA returns char)
;   F         = clobbered
;   BC,DE,HL  = preserved
;   IX,IY     = preserved
;   Shadow regs not used by BASIC, so no need to preserve.
;
; terminal_putchar saves AF/IX/HL but its inner calls (ra6963_*) can clobber
; BC, DE, IY - so TXA wraps the call with explicit save/restore of those.
; ============================================================================

.include "applications/msbasic/msbasic.inc"
.include "applications/kutakbash/kutakbash.inc"
.include "terminal/terminal.inc"

; BASIC line buffer lives at WRKSPC+0x58 (mirrors .equ BUFFER inside bas32k.s).
.equ BUFFER, WRKSPC + 0x58

.section .text

; -- App entry point --------------------------------------------------------
; Called by kutakbash. BASIC takes over the system and never returns until
; reset. (Adding an EXIT command is a follow-up.)
.global msbasic_main
msbasic_main:
    jp      CSTART          ; cold-start BASIC

; -- TXA: output char in A to terminal -------------------------------------
; CR (0x0D) is already filtered out of BASIC's output strings and PRNTCRLF,
; so we don't need to drop it here. BS (0x08) needs special handling because
; terminal_putchar drops control chars.
.global TXA
TXA:
    push    bc                ; save caller-visible regs that terminal_putchar
    push    de                ; / its inner calls may clobber
    push    iy
    cp      0x08              ; BS?
    jr      z, TXA_bs
    ld      c, a              ; arg low = char (high byte ignored by callee)
    ld      b, 0
    push    bc                ; stack arg for terminal_putchar (callee cleans)
    call    terminal_putchar
    jr      TXA_done
TXA_bs:
    call    terminal_cursor_left
TXA_done:
    pop     iy
    pop     de
    pop     bc
    ret

; RXA: blocking read of one char into A
.global RXA
RXA:
    push    hl  ; storing hl
    call    keyboard_get_key_block  ; blocking until keypress
    pop     hl  ; HL.L = returned char
    ld      a, l  ; A = char (RXA's contract)
    pop     hl  ; restoring hl
    ret

; RXA_CHK: non-blocking probe is key pressed?
.global RXA_CHK
RXA_CHK:
    xor a  ; mock
    ret

; UFERR is defined inside bas32k.s as the real "?UF Error" handler - no
; stub needed here.

; -- TTYLIN_drunkpc: line-editor replacement for BASIC's TTYLIN -------------
; INITAB's RINPUT slot redirects here. We delegate to kutakbash's editor
; (arrows, mid-line insert/delete, redraw) and copy the result into BASIC's
; BUFFER. Contract on return:
;   HL = BUFFER - 1   (so caller's GETCHR does INC HL then read first char)
;   CY clear          on success - BUFFER null-terminated, up to 71 chars
;   CY set            on Ctrl-C - BASIC's GETCMD loop re-enters RINPUT
; All other registers may be clobbered (original TTYLIN clobbers too).
.global TTYLIN_drunkpc
TTYLIN_drunkpc:
    ; kutakbash_get_input_string allocates its own return slot via the
    ; exx-pop-push-push-exx prologue - caller MUST NOT pre-push.
    call    kutakbash_get_input_string
    pop     hl                ; L = 1 on success, 0 on Ctrl-C
    ld      a, l
    or      a
    jr      z, TTYLIN_drunkpc_break

    ; Copy null-terminated string from kutakbash buffer into BASIC's BUFFER.
    ; BASIC's buffer is 72 bytes; truncate at 71 chars + null terminator.
    ld      hl, kutakbash_input_string_buffer
    ld      de, BUFFER
    ld      b, 71
TTYLIN_drunkpc_copy:
    ld      a, (hl)
    ld      (de), a
    or      a                 ; null? also clears carry
    jr      z, TTYLIN_drunkpc_done
    inc     hl
    inc     de
    djnz    TTYLIN_drunkpc_copy
    xor     a                 ; ran out of room - force null at byte 72
    ld      (de), a
TTYLIN_drunkpc_done:
    ld      hl, BUFFER - 1    ; matches original ENDINP post-condition
    ret                       ; carry already clear

TTYLIN_drunkpc_break:
    scf                       ; signal break to GETCMD
    ret

; ============================================================================
; .bss layout for BASIC workspace
; ============================================================================
; STACK = WRKSPC+0x5D grows DOWNWARD from inside WRKSPC, into the 0x100-byte
; safety pad we reserve below WRKSPC. BASIC's stack depth is shallow; 256
; bytes of margin is comfortable.
;
; _basic_ram_end is the EXCLUSIVE upper bound. BASIC's SETTOP does DEC HL
; on it to get the last usable byte. STLOOK = WRKSPC+0x154 must be below it.
; ============================================================================

.section .bss

    .skip 0x100               ; stack growth safety pad below WRKSPC

.global WRKSPC
WRKSPC:
    .skip 0x2000              ; workspace + program/string area (8 KB)

.global _basic_ram_end
_basic_ram_end:

.section .rodata

msbasic_name:
    .asciz "msbasic"

; vim: ft=asm
