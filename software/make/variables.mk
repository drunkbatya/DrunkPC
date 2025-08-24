BUILDDIR = build
TARGET = firmware

ASSETSDIR = assets
ASSETSSRCDIR = $(ASSETSDIR)/src
ASSETSBUILDDIR = $(ASSETSDIR)/build
ASSETSTARGET = assets_icons.s

INCLUDE = -Isystem -Ilib/stdlib -Ilib

TMPL_SOURCES += $(shell find . -not -path '*/sandbox/*' -not -path '*/.*' -type f -name "*.tmpl")

#ASM_SOURCES += $(ASSETSBUILDDIR)/$(ASSETSTARGET)
ASM_SOURCES += $(shell find . -not -path '*/assets/*' -not -path '*/sandbox/*' -not -path '*/.*' -type f -name "*.s")
ASM_INCLUDES += $(shell find . -not -path '*/assets/*' -not -path '*/sandbox/*' -not -path '*/.*' -type f -name "*.inc")

#ASSETS_SOURCES = $(shell find ${ASSETSSRCDIR} -type f -name "*.png")

TEMPLATES += $(addprefix $(BUILDDIR)/, $(TMPL_SOURCES:.tmpl=.s))

OBJECTS += $(addprefix $(BUILDDIR)/, $(ASM_SOURCES:.s=.o))
#OBJECTS += $(addprefix $(BUILDDIR)/, $(TMPL_SOURCES:.tmpl=.o))

OBJECT_DIRS = $(sort $(dir $(OBJECTS)))
$(foreach dir, $(OBJECT_DIRS),$(shell mkdir -p $(dir)))

TMPL_DIRS = $(sort $(dir $(TEMPLATES)))
$(foreach dir, $(TMPL_DIRS),$(shell mkdir -p $(dir)))

MAKE_FILES = $(shell find make -not -path '*/sandbox/*' -not -path '*/.*' -type f -name "*.mk")

LDSCRIPT = system/drunkpc.ld
