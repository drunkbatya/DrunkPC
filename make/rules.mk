$(BUILDDIR)/%.o: %.s $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tASM\t" $<
	@$(AS) $(ASMFLAGS) $< -o $@

$(BUILDDIR)/%.o: %.c $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tCC\t" $<
	@$(CC) $(CFLAGS) $< -o "$(dirname $@)$(basename $@).asm"
	@$(ZCC_TO_GAS) "$(dirname $@)$(basename $@).asm" "$(dirname $@)$(basename $@)_patched.asm"
	@$(AS) $(ASMFLAGS) "$(dirname $@)$(basename $@)_patched.asm" -o $@

$(BUILDDIR)/$(TARGET).elf: $(OBJECTS) $(MAKE_FILES)
	@echo "\tLD\t" $@
	@$(LD) $(LDFLAGS) $(OBJECTS) -o $@
	@echo "\tSIZE\t" $@
	@z80-elf-size -A -t $@ | grep -e " "

$(BUILDDIR)/%.bin: $(BUILDDIR)/%.elf | $(BUILDDIR)
	@echo "\tBIN\t" $@
	@$(BIN) $< $@

