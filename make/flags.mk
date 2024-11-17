ASMFLAGS += $(INCLUDE)
LDFLAGS += -Map $(BUILDDIR)/$(TARGET).map -T$(LDSCRIPT) -Os
PREPROCFLAGS += -Wno-invalid-pp-token
