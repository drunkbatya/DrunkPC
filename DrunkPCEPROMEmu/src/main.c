#include "usb_device.h"
#include "main.h"
#include "sys_config.h"

static void MX_GPIO_Init2(void)
{
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;  // allow PortC Clock
    GPIOC->MODER &= GPIO_MODER_MODER0_1;  // Output
    GPIOC->OTYPER &= ~GPIO_OTYPER_OT_0;  // push-pull
    GPIOC->PUPDR &= ~GPIO_PUPDR_PUPDR0;  // without pull resistor
    GPIOA->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR0;  // 50MHz
}

static void MX_GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    __HAL_RCC_GPIOC_CLK_ENABLE();
    __HAL_RCC_GPIOH_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOA_CLK_ENABLE();

    /*Configure GPIO pin : PC13 */
    GPIO_InitStruct.Pin = GPIO_PIN_13;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
}

int main(void)
{
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_USB_DEVICE_Init();
    while (1)
    {
        GPIOC->ODR = 0xFFFF;
        HAL_Delay(500);
        GPIOC->ODR = 0;
        HAL_Delay(500);
    }
    return (0);
}
