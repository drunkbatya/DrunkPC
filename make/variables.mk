BUILDDIR = build
TARGET = firmware

INCLUDE = -Isystem

ASM_SOURCES += $(shell find system -type f -name "*.s")
#ASM_SOURCES += $(shell find lib -type f -name "*.s")

C_SOURCES += $(shell find system -type f -name "*.c")
C_SOURCES += $(shell find lib -type f -name "*.c")
C_SOURCES += $(shell find applications -type f -name "*.c")

OBJECTS = $(addprefix $(BUILDDIR)/, $(ASM_SOURCES:.s=.o))
OBJECTS += $(addprefix $(BUILDDIR)/, $(C_SOURCES:.c=.o))

OBJECT_DIRS = $(sort $(dir $(OBJECTS)))
$(foreach dir, $(OBJECT_DIRS),$(shell mkdir -p $(dir)))

MAKE_FILES = $(shell find make -type f -name "*.mk")

LDSCRIPT = system/drunkpc.ld
