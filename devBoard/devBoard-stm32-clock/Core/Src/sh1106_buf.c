#include <string.h>
#include "stm32f4xx_hal.h"
#include "SystemFont5x7.h"
#include "sh1106_buf.h"

static GPIO_TypeDef *sh1106_port;
static uint16_t sh1106_dc_pin;
static uint16_t sh1106_res_pin;
static SPI_HandleTypeDef *sh1106_spi;

uint8_t sh1106_buf[SH1106_WIDTH * SH1106_HEIGHT];

static void sh1106_write(uint8_t data, uint8_t cmd_or_data)
{
    HAL_GPIO_WritePin(sh1106_port, sh1106_dc_pin, cmd_or_data);
    HAL_SPI_Transmit(sh1106_spi, &data, 1, 1);
}

static inline void sh1106_set_ram_page(uint8_t page)
{
    sh1106_write(SH1106_SET_RAM_PAGE + page, SH1106_CMD);
}

static inline void sh1106_set_column_address(uint8_t address)
{
    sh1106_write(SH1106_SET_LOWER_COLUMN_BITS + (address & 0x0F), SH1106_CMD);
    sh1106_write(SH1106_SET_HIGHER_COLUMN_BITS + ((address & 0xF0) >> 4), SH1106_CMD);
}

static char *sh1106_strrev(char *str) {
    uint32_t end;
    uint32_t start;
    char temp;

    start = 0;
    end = strlen(str) - 1;
    while (start < end) {
        temp = str[end];
        str[end] = str[start];
        str[start] = temp;
        end--;
        start++;
    }
    return (str);
}

static char *sh1106_itoa(int32_t num) {
    static char str[12];  // int32_t max + sign + '\0'
    char *str_ptr;
    uint8_t minus;

    minus = 0;
    str_ptr = str;
    if (num < 0)
    {
        num = -num;
        minus = 1;
    }
    while (num / 10) {
        *str_ptr = '0' + (num % 10);
        num /= 10;
        str_ptr++;
    }
    *str_ptr = '0' + num;
    if (minus)
    {
        str_ptr++;
        *str_ptr = '-';
    }
    str_ptr++;
    *str_ptr = '\0';
    return (sh1106_strrev(str));
}

void sh1106_write_buffer(void)
{
    uint8_t *buf_ptr;

    buf_ptr = sh1106_buf;
    for (uint8_t count_page = 0; count_page < SH1106_PAGES; count_page++)
    {
        sh1106_set_ram_page(count_page);
        sh1106_set_column_address(0);
        HAL_GPIO_WritePin(sh1106_port, sh1106_dc_pin, SH1106_DATA);
        HAL_SPI_Transmit(sh1106_spi, buf_ptr, SH1106_WIDTH, 1);
        buf_ptr += SH1106_WIDTH;
        while (HAL_SPI_GetState(sh1106_spi) != HAL_SPI_STATE_READY)
        {
            ;;
        }
    }
}

static inline void sh1106_new_line(uint8_t *column, uint8_t *page)
{
    ++*page;
    *column = 0;
}

static void sh1106_write_char(char c, uint8_t column, uint8_t page)
{
    uint8_t *buf_ptr;

    buf_ptr = sh1106_buf + (page * SH1106_WIDTH) + column;
    memcpy(buf_ptr, System5x7 + ((c - ' ') * SYSTEM5x7_WIDTH), SYSTEM5x7_WIDTH);
}

void sh1106_write_str(char *str, uint8_t column, uint8_t page)
{
    while (*str != '\0')
    {
        if (*str == '\n')
        {
            sh1106_new_line(&column, &page);
            str++;
        }
        sh1106_write_char(*str, column, page);
        str++;
        column += SYSTEM5x7_WIDTH;
        if ((column + SYSTEM5x7_WIDTH) >= SH1106_WIDTH)
            sh1106_new_line(&column, &page);
    }
}

void sh1106_write_num(int32_t num, uint8_t column, uint8_t page)
{
    sh1106_write_str(sh1106_itoa(num), column, page);
}

void sh1106_clear_screen(void)
{
    memset(sh1106_buf, 0, (SH1106_WIDTH * SH1106_HEIGHT));
}

static inline void sh1106_reset(void)
{
    HAL_GPIO_WritePin(sh1106_port, sh1106_res_pin, GPIO_PIN_RESET);
    HAL_Delay(1);
    HAL_GPIO_WritePin(sh1106_port, sh1106_res_pin, GPIO_PIN_SET);
    HAL_Delay(1);
}

static void sh1106_set_default(uint8_t contrast, uint8_t bright)
{
    sh1106_reset();
    sh1106_write(SH1106_DISP_OFF, SH1106_CMD);
    sh1106_write(0xD5, SH1106_CMD);  // set oscilator freq
    sh1106_write(0xDC, SH1106_CMD);
    sh1106_write(0xA8, SH1106_CMD);  // --set multiplex ratio(1 to 64)
    sh1106_write(0x3F, SH1106_CMD);
    sh1106_write(0x81, SH1106_CMD);  // --set contrast control register
    sh1106_write(contrast, SH1106_CMD);
    sh1106_write(0xA1, SH1106_CMD);
    sh1106_write(0xC8, SH1106_CMD);
    sh1106_write(0xDA, SH1106_CMD);
    sh1106_write(0x12, SH1106_CMD);
    sh1106_write(0xD3, SH1106_CMD);
    sh1106_write(0x00, SH1106_CMD);
    sh1106_write(0x40, SH1106_CMD);
    sh1106_write(0xD9, SH1106_CMD);  // --set pre-charge period
    sh1106_write(bright, SH1106_CMD);
    sh1106_write(SH1106_DISP_ON, SH1106_CMD);
    sh1106_set_column_address(0);
    sh1106_set_ram_page(0);
}

void sh1106_init(GPIO_TypeDef *port, SPI_HandleTypeDef *spi, uint16_t dc_pin, uint16_t res_pin)
{
    sh1106_port = port;
    sh1106_dc_pin = dc_pin;
    sh1106_res_pin = res_pin;
    sh1106_spi = spi;
    sh1106_set_default(40, 0xFF);
}
