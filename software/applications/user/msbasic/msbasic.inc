; ============================================================================
; MS BASIC port to DrunkPC - public symbols
; ============================================================================

; App entry point (called by the shell)
.global msbasic_main
.global msbasic_name

; BASIC -> OS API (implemented in msbasic.s)
.global TXA
.global RXA
.global RXA_CHK
.global UFERR

; BASIC code-side symbols visible externally
.global COLD
.global CSTART
.global WARMST
.global WRKSPC
.global _basic_ram_end

; Mock OS functions (until DrunkOS provides them in system/keyboard/)
.global keyboard_available

; BASIC command stubs (in msbasic_glue.s) - SAVE/LOAD repurposed from MEEK/MOKE
.global SAVE
.global LOAD

; vim: ft=asm
