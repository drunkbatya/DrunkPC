BUILDDIR = build
TARGET = firmware

INCLUDE = -Isystem -Ilib/stdlib -Ilib

TMPL_SOURCES += $(shell find . -not -path '*/.*' -type f -name "*.tmpl")

ASM_SOURCES += $(shell find . -not -path '*/.*' -type f -name "*.s")
ASM_INCLUDES += $(shell find . -not -path '*/.*' -type f -name "*.inc")

TEMPLATES += $(addprefix $(BUILDDIR)/, $(TMPL_SOURCES:.tmpl=.s))

OBJECTS += $(addprefix $(BUILDDIR)/, $(ASM_SOURCES:.s=.o))
#OBJECTS += $(addprefix $(BUILDDIR)/, $(TMPL_SOURCES:.tmpl=.o))

OBJECT_DIRS = $(sort $(dir $(OBJECTS)))
$(foreach dir, $(OBJECT_DIRS),$(shell mkdir -p $(dir)))

TMPL_DIRS = $(sort $(dir $(TEMPLATES)))
$(foreach dir, $(TMPL_DIRS),$(shell mkdir -p $(dir)))

MAKE_FILES = $(shell find make -not -path '*/.*' -type f -name "*.mk")

LDSCRIPT = system/drunkpc.ld
