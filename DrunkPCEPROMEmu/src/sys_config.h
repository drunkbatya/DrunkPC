#ifndef _SYS_CONFIG_H_
#define _SYS_CONFIG_H_

#include "stm32f4xx_hal.h"

void Error_Handler(void);
void SystemClock_Config(void);
void assert_failed(uint8_t *file, uint32_t line);

#endif  // _SYS_CONFIG_H_
