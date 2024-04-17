all: $(BUILDDIR)/$(TARGET).elf $(BUILDDIR)/$(TARGET).bin

.PHONY: disasm
disasm: $(BUILDDIR)/$(TARGET).elf
	@echo "\tDISASM\t" $(BUILDDIR)/$(TARGET).elf
	@$(DU) -d build/$(TARGET).elf

.PHONY: disasm-data
disasm-data:
	@echo "\tOBJ\t.data\t" $(BUILDDIR)/$(TARGET).elf
	@z80-elf-objdump -j .data -d build/$(TARGET).elf

.PHONY: disasm-bss
disasm-bss:
	@echo "\tOBJ\t.bss\t" $(BUILDDIR)/$(TARGET).elf
	@z80-elf-objdump -j .bss -d build/$(TARGET).elf

.PHONY: disasm-rodata
disasm-rodata:
	@echo "\tOBJ\t.rodata\t" $(BUILDDIR)/$(TARGET).elf
	@z80-elf-objdump -j .rodata -d build/$(TARGET).elf

.PHONY: xxd
xxd: $(BUILDDIR)/$(TARGET).bin
	@echo "\tXXD\t" $(BUILDDIR)/$(TARGET).bin
	@xxd $(BUILDDIR)/$(TARGET).bin

.PHONY: flash
flash: $(BUILDDIR)/$(TARGET).bin
	@echo "\tFLASH\t" $(BUILDDIR)/$(TARGET).bin
	@minipro --device "AT28C256" --write $(BUILDDIR)/$(TARGET).bin -s

.PHONY: lint
lint:
	find . -type f \( -name "*.c" -o -name "*.h" \) \
		\( -path "./lib/*" -o -path "./applications/*" -o -path "./src/*" \) \
		| xargs clang-format --Werror --style=file -i --dry-run

.PHONY: format
format:
	find . -type f \( -name "*.c" -o -name "*.h" \) \
		\( -path "./lib/*" -o -path "./applications/*" -o -path "./src/*" \) \
		| xargs clang-format --Werror --style=file -i

.PHONY: clean
clean:
	-rm -rf $(BUILDDIR)
	-rm -rf $(ASSETSBUILDDIR)
