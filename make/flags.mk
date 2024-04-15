ASMFLAGS = $(INCLUDE)
LDFLAGS = -Map $(BUILDDIR)/$(TARGET).map -T$(LDSCRIPT) -Os
CFLAGS = +z80 -clib=classic -compiler=sccz80 -Wall -Werror -Wextra -a --no-crt
