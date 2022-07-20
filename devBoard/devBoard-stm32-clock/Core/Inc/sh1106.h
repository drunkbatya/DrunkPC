#ifndef _SH1106_H_
#define _SH1106_H_

#define SH1106_WIDTH 128
#define SH1106_HEIGHT 64

#define SH1106_CMD 0
#define SH1106_DATA 0x01

#define SH1106_DISP_OFF 0xAE
#define SH1106_DISP_ON 0xAF
#define SH1106_SET_RAM_PAGE 0xB0
#define SH1106_SET_LOWER_COLUMN_BITS 0x00
#define SH1106_SET_HIGHER_COLUMN_BITS 0x10

void sh1106_init(GPIO_TypeDef *port, SPI_HandleTypeDef *spi, uint16_t dc_pin, uint16_t res_pin);
void sh1106_write_str(char *str, uint8_t column, uint8_t page);
void sh1106_dirty_clear_screen(void);
#endif  // _SH1106_H_
