ASMFLAGS = $(INCLUDE)
ASMCFLAGS = -sdcc -march=z80
LDFLAGS = -Map $(BUILDDIR)/$(TARGET).map -T$(LDSCRIPT) -Os
#CFLAGS = +z80 -clib=classic -compiler=sdcc -Wall -a --no-crt -Cc -unsigned -Cc --disable-builtins --opt-code-speed -Cs --no-std-crt0 -Cs --nostdlib -Cs --nostdlibcall -SO3 --max-allocs-per-node200000

#CFLAGS = +z80 -compiler=sdcc -clib=classic -Wall -Werror -Wextra -a --no-crt -Cc -unsigned -Cc --disable-builtins -Cs --codeseg=.code -Cs --constseg=.rodata -Cs --dataseg=.data
CFLAGS = +embedded -compiler=sdcc -clib=sdcc_iy -Wall -a --no-crt -Cs --no-std-crt0 -Cs --nostdlib -Cs --nostdlibcall -SO3 --max-allocs-per-node200000 --opt-code-speed
