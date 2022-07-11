TARGET = DrunkPCEPROMEmu
DEBUG = 1
OPT = -Og
BUILD_DIR = build
C_SOURCES =  \
src/main.c \
src/sys_config.c \
src/serial.c \
src/eeprom.c \
src/stm32f4xx_it.c \
stm32/stm32f4xx_hal_msp.c \
stm32/USB_DEVICE/App/usb_device.c \
stm32/USB_DEVICE/App/usbd_desc.c \
stm32/USB_DEVICE/App/usbd_cdc_if.c \
stm32/USB_DEVICE/Target/usbd_conf.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pcd.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pcd_ex.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_usb.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim.c \
stm32/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim_ex.c \
stm32/system_stm32f4xx.c \
stm32/Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_core.c \
stm32/Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ctlreq.c \
stm32/Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ioreq.c \
stm32/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Src/usbd_cdc.c  

ASM_SOURCES = stm32/startup_stm32f401xc.s
PREFIX = arm-none-eabi-
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
CPU = -mcpu=cortex-m4
FPU = -mfpu=fpv4-sp-d16
FLOAT-ABI = -mfloat-abi=hard
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)
AS_DEFS = 
C_DEFS =  \
-DUSE_HAL_DRIVER \
-DSTM32F401xC
AS_INCLUDES = 
C_INCLUDES =  \
-Istm32 \
-Istm32/USB_DEVICE/App \
-Istm32/USB_DEVICE/Target \
-Isrc \
-Istm32/Drivers/STM32F4xx_HAL_Driver/Inc \
-Istm32/Drivers/STM32F4xx_HAL_Driver/Inc/Legacy \
-Istm32/Middlewares/ST/STM32_USB_Device_Library/Core/Inc \
-Istm32/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc \
-Istm32/Drivers/CMSIS/Device/ST/STM32F4xx/Include \
-Istm32/Drivers/CMSIS/Include

ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS += $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"

LDSCRIPT = stm32/STM32F401CCUx_FLASH.ld

# libraries
LIBS = -lc -lm -lnosys 
LIBDIR = 
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir $@		
clean:
	-rm -fR $(BUILD_DIR)

flash: all
	@while ! dfu-util --list | grep -q "Internal Flash"; \
		do echo "waiting dfu device.."; \
		sleep 1; \
	done
	dfu-util -a 0 -D $(BUILD_DIR)/$(TARGET).bin -s 0x08000000
-include $(wildcard $(BUILD_DIR)/*.d)
