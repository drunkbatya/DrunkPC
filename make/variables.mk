BUILDDIR = build
TARGET = firmware

INCLUDE = -Isystem -Ilib/stdlib

ASM_SOURCES += $(shell find system -type f -name "*.s")
ASM_SOURCES += $(shell find applications -type f -name "*.s")
ASM_SOURCES += $(shell find lib -type f -name "*.s")

OBJECTS = $(addprefix $(BUILDDIR)/, $(ASM_SOURCES:.s=.o))

OBJECT_DIRS = $(sort $(dir $(OBJECTS)))
$(foreach dir, $(OBJECT_DIRS),$(shell mkdir -p $(dir)))

MAKE_FILES = $(shell find make -type f -name "*.mk")

LDSCRIPT = system/drunkpc.ld
