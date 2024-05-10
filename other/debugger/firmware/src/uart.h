#pragma once

#include <stdint.h>

void uart_init(uint32_t baudrare);
void uart_putchar(uint8_t data);
void uart_putstr(const char* str);
uint8_t uart_getchar(void);
