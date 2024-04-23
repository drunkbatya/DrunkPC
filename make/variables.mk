BUILDDIR = build
TARGET = firmware

INCLUDE = -Isystem -Ilib/stdlib -Ilib

ASM_SOURCES += $(shell find . -type f -name "*.s")
ASM_INCLUDES += $(shell find . -type f -name "*.inc")

OBJECTS = $(addprefix $(BUILDDIR)/, $(ASM_SOURCES:.s=.o))

OBJECT_DIRS = $(sort $(dir $(OBJECTS)))
$(foreach dir, $(OBJECT_DIRS),$(shell mkdir -p $(dir)))

MAKE_FILES = $(shell find make -type f -name "*.mk")

LDSCRIPT = system/drunkpc.ld
