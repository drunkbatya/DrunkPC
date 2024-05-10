$(BUILDDIR)/%.o: %.c $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tCC\t" $<
	@$(CC) $(CFLAGS) $< -o $@

$(BUILDDIR)/$(TARGET).elf: $(OBJECTS) $(MAKE_FILES)
	@echo "\tLD\t" $@
	@$(LD) $(LDFLAGS) $(OBJECTS) -o $@
	@echo "\tSIZE\t" $@
	@avr-size -A -t $@ | grep -e " "

$(BUILDDIR)/%.bin: $(BUILDDIR)/%.elf | $(BUILDDIR)
	@echo "\tBIN\t" $@
	@$(BIN) $< $@

$(BUILDDIR)/%.hex: $(BUILDDIR)/%.elf | $(BUILDDIR)
	@echo "\tHEX\t" $@
	@$(HEX) $< $@
