#$(ASSETSBUILDDIR)/$(ASSETSTARGET): $(ASSETS_SOURCES) $(ASSETS_COMPILER) $(MAKE_FILES)
#	@echo "\tASSETS\t" $@
#	@$(ASSETS_COMPILER) $(ASSETSSRCDIR) $(ASSETSBUILDDIR)

$(BUILDDIR):
	@mkdir -p $@

$(BUILDDIR)/$(TARGET)_updater_cf_image.img: $(BUILDDIR)/$(TARGET).bin
	@echo "\tMKIMG\t" $@
	@mkdir -p $(@D)
	@$(UPDATE_IMAGE_GEN) \
		--firmware_file "$<" \
		--output_file "$@" \
		--git_tag "$(VERSION)" \
		--git_branch "$(GIT_BRANCH)" \
		--git_hash "$(GIT_COMMIT)" \
		--build_date "$(BUILD_DATE)"

$(BUILDDIR)/%.s: %.tmpl $(TMPL_SOURCES) $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tTMPL\t" $<
	@mkdir -p $(@D)
	@$(TMPL_ENVS) $(ENVSUBST) < $< > $@

#$(BUILDDIR)/%.o: %.s $(ASSETSBUILDDIR)/$(ASSETSTARGET) $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
$(BUILDDIR)/%.o: %.s $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tASM\t" $<
	@mkdir -p $(@D)
	@$(AS) $(ASMFLAGS) $< -o $@

$(TMPL_OBJS): $(BUILDDIR)/%.o : $(BUILDDIR)/%.s $(ASM_INCLUDES) $(MAKE_FILES) | $(BUILDDIR)
	@echo "\tASM\t" $<
	@mkdir -p $(@D)
	@$(AS) $(ASMFLAGS) $< -o $@

#$(BUILDDIR)/$(TARGET).elf: $(TEMPLATES) $(OBJECTS) $(MAKE_FILES)
$(BUILDDIR)/$(TARGET).elf: $(OBJECTS) $(MAKE_FILES) | $(BUILDDIR)
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

$(BUILDDIR)/%.js: $(BUILDDIR)/%.img
	@echo "\tXXD\t" $@
	@echo "const $(basename $(notdir $<)) = [" > $@
	@xxd -i $< | tail -n +2 | sed '$$d' | sed '$$d' >> $@
	@echo "];" >> $@
