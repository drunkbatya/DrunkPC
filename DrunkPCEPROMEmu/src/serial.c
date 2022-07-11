#include "stm32f4xx_hal.h"
#include "usbd_cdc_if.h"

void DrunkSerialWrite(uint8_t *buf, uint16_t len)
{
    while (CDC_Transmit_FS(buf, len) == USBD_BUSY)
        ;;
}

void DrunkSerialInterrupt(void)
{
    GPIOC->ODR = 0;
    return;
}

void DrunkSerialRead(uint8_t *buf, uint32_t len)
{
    GPIOC->ODR = 0xFFFF;
    return;
}
