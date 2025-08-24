#$(ASSETSBUILDDIR)/$(ASSETSTARGET): $(ASSETS_SOURCES) $(ASSETS_COMPILER) $(MAKE_FILES)
#	@echo "\tASSETS\t" $@
#	@$(ASSETS_COMPILER) $(ASSETSSRCDIR) $(ASSETSBUILDDIR)

$(BUILDDIR)/%.s: %.tmpl $(TMPL_SOURCES) $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tTMPL\t" $<
	@$(TMPL_ENVS) $(ENVSUBST) < $< > $@

#$(BUILDDIR)/%.o: %.s $(ASSETSBUILDDIR)/$(ASSETSTARGET) $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
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

$(BUILDDIR)/%.js: $(BUILDDIR)/%.bin
	@echo "\tXXD\t" $@
	@echo "const $(basename $(notdir $<)) = [" > $@
	@xxd -i $< | tail -n +2 | sed '$$d' | sed '$$d' >> $@
	@echo "];" >> $@
