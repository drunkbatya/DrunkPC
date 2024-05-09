all: $(BUILDDIR)/$(TARGET).elf $(BUILDDIR)/$(TARGET).bin

.PHONY: flash
flash: all
	false

.PHONY: lint
lint:
	clang-format --Werror --style=file -i --dry-run *.cpp *.h *.ino

.PHONY: format
format:
	clang-format --Werror --style=file -i *.cpp *.h *.ino
