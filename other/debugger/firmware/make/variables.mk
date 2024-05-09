BUILDDIR = build
TARGET = debugger_firmware

C_SOURCES += $(shell find . -type f -name "*.c")

OBJECTS = $(addprefix $(BUILDDIR)/, $(C_SOURCES:.c=.o))

OBJECT_DIRS = $(sort $(dir $(OBJECTS)))
$(foreach dir, $(OBJECT_DIRS),$(shell mkdir -p $(dir)))

MAKE_FILES = $(shell find make -type f -name "*.mk")

LDSCRIPT = system/drunkpc.ld

CLK = 16000000
CPU = atmega2560
