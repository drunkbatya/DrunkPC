#include "stm32f4xx_hal.h"
#include "sh1106.h"
#include "SystemFont5x7.h"

static GPIO_TypeDef *sh1106_port;
static uint16_t sh1106_dc_pin;
static uint16_t sh1106_res_pin;
static SPI_HandleTypeDef *sh1106_spi;

static void sh1106_write_arr(const uint8_t *data, uint8_t count, uint8_t cmd_or_data)
{
    HAL_GPIO_WritePin(sh1106_port, sh1106_dc_pin, cmd_or_data);
    HAL_SPI_Transmit(sh1106_spi, (uint8_t *)data, count, 1);
}

static void sh1106_write(uint8_t data, uint8_t cmd_or_data)
{
    sh1106_write_arr(&data, 1, cmd_or_data);
}

static void sh1106_set_ram_page(uint8_t page)
{
    sh1106_write(SH1106_SET_RAM_PAGE + page, SH1106_CMD);
}

static void sh1106_set_column_address(uint8_t address)
{
    sh1106_write(SH1106_SET_LOWER_COLUMN_BITS + (address & 0x0F), SH1106_CMD);
    sh1106_write(SH1106_SET_HIGHER_COLUMN_BITS + ((address & 0xF0) >> 4), SH1106_CMD);
}

static void sh1106_write_array(const uint8_t *arr, uint16_t arr_size, uint8_t column, uint8_t page, uint8_t max_column, uint8_t max_page)
{
    uint16_t arr_count = 0;
    for (uint8_t count_page = page; count_page < max_page; count_page++)
    {
        sh1106_set_ram_page(count_page);
        sh1106_set_column_address(column);
        for (uint8_t count_column = column; count_column < max_column; count_column++)
        {
            if (arr == NULL)
            {
                sh1106_write(0, SH1106_DATA);
                continue;
            }
            sh1106_write(arr[arr_count], SH1106_DATA);
            arr_count++;
            if (arr_count >= arr_size)
                return;
        }
    }
}

static void sh1106_write_char(char ch, uint8_t column, uint8_t page)
{
    sh1106_set_ram_page(page);
    sh1106_set_column_address(column);
    sh1106_write_arr(&System5x7[(ch - ' ') * SYSTEM5x7_WIDTH], SYSTEM5x7_WIDTH, SH1106_DATA);
}

void sh1106_write_str(char *str, uint8_t column, uint8_t page)
{
    while (*str != '\0')
    {
        if (column > SH1106_WIDTH)
        {
            column = 0;
            page++;
        }
        sh1106_write_char(*str, column, page);
        str++;
        column += SYSTEM5x7_WIDTH;
    }
    sh1106_write(0, SH1106_DATA);
}

static void sh1106_reset(void)
{
    HAL_GPIO_WritePin(sh1106_port, sh1106_res_pin, GPIO_PIN_RESET);
    HAL_Delay(1);
    HAL_GPIO_WritePin(sh1106_port, sh1106_res_pin, GPIO_PIN_SET);
    HAL_Delay(1);
}

void sh1106_dirty_clear_screen(void)
{
    sh1106_write_array(NULL, 0, 11, 1, SH1106_WIDTH - 8, 7);
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
