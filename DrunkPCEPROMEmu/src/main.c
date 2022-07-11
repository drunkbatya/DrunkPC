#include "usb_device.h"
#include "main.h"
#include "sys_config.h"
#include "eeprom.h"

static void MX_GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_GPIOC_CLK_ENABLE();
    __HAL_RCC_GPIOH_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOA_CLK_ENABLE();

    // whole PortB as address bus input
    GPIO_InitStruct.Pin = GPIO_PIN_All;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_PULLDOWN;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // PA0-PA7 as data bus output
    GPIO_InitStruct.Pin = 0x00FF;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_PULLDOWN;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    /*Configure GPIO pin : PC13 */
    GPIO_InitStruct.Pin = GPIO_PIN_13;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
}

void add_hello_world(void)
{
    uint8_t data[] = { 0xD3, 0xFF, 0x06, 0x20, 0x10, 0xFE, 0x2F, 0xD3, 0xFF, 0x06, 0x20, 0x10, 0xFE, 0x18, 0xF1 };
    memcpy(eeprom_data, data, 15);
}

void emulate(void)
{
    uint16_t address;

    address = GPIOB->IDR;
    // Pin PB11 skiped by manufacturer..
    address = (address & 0x7FF) | ((address & 0xF000) >> 1);
    GPIOA->ODR = eeprom_data[address];
}

int main(void)
{
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_USB_DEVICE_Init();
    add_hello_world();
    while (1)
    {
        emulate();  // GPIOA->ODR |= eeprom_data[(GPIOB->IDR & 0x7FF) | ((GPIOB->IDR & 0xF000) >> 1)];
        GPIOC->ODR = 0xFFFF;
        HAL_Delay(500);
        GPIOC->ODR = 0;
        HAL_Delay(500);
    }
    return (0);
}
