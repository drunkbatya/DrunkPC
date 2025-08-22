all: $(BUILDDIR)/$(TARGET).elf $(BUILDDIR)/$(TARGET).bin

.PHONY: disasm
disasm: $(BUILDDIR)/$(TARGET).elf
	@echo "\tDISASM\t" $(BUILDDIR)/$(TARGET).elf
	@$(DU) -d build/$(TARGET).elf

.PHONY: xxd
xxd: $(BUILDDIR)/$(TARGET).bin
	@echo "\tXXD\t" $(BUILDDIR)/$(TARGET).bin
	@xxd $(BUILDDIR)/$(TARGET).bin

.PHONY: flash
flash: $(BUILDDIR)/$(TARGET).bin
	@echo "\tFLASH\t" $(BUILDDIR)/$(TARGET).bin
	@minipro --device "AT28C256" --write $(BUILDDIR)/$(TARGET).bin -s -u -P

.PHONY: clean
clean:
	-rm -rf $(BUILDDIR)
	-rm -rf $(ASSETSBUILDDIR)
