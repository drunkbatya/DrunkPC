.global drunkfs_open
.global drunkfs_close
.global drunkfs_seek
.global drunkfs_rewind
.global drunkfs_read_byte
.global drunkfs_read
.global drunkfs_getpos
.global drunkfs_getsize
.global drunkfs_set_rw_direction_forward
.global drunkfs_set_rw_direction_backward

; error codes
DRUNKFS_ERROR_OK = 0  ; no error
DRUNKFS_ERROR_EOF = 1  ; End Of File
DRUNKFS_ERROR_IO = 2  ; I/O error

; read direction
DRUNKFS_RW_DIRECTION_FORWARD = 0  ; default
DRUNKFS_RW_DIRECTION_BACKWARD = 1

; vim: ft=asm
