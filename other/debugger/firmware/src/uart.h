#pragma once

void uart_init(void);
void uart_putchar(char c);
void uart_putstr(const char* str);
char uart_getchar(void);
