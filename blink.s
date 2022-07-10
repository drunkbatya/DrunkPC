    .org 0
start:
    out (0FFh),a
    ld b,020h
    djnz $
    cpl
    out (0FFh),a
    ld b,020h
    djnz $
    jr start
