$(BUILDDIR)/%.s: %.tmpl $(TMPL_SOURCES) $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tTMPL\t" $<
	@$(TMPL_ENVS) $(ENVSUBST) < $< > $@

$(BUILDDIR)/%.o: %.s $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tASM\t" $<
	@$(AS) $(ASMFLAGS) $< -o $@

$(BUILDDIR)/$(TARGET).elf: $(TEMPLATES) $(OBJECTS) $(MAKE_FILES)
	@echo "\tLD\t" $@
	@$(LD) $(LDFLAGS) $(OBJECTS) -o $@
	@echo "\tSIZE\t" $@
	@z80-elf-size -A -t $@ | grep -e " "

$(BUILDDIR)/%.bin: $(BUILDDIR)/%.elf | $(BUILDDIR)
	@echo "\tBIN\t" $@
	@$(BIN) $< $@
