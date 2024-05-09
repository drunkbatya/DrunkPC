#include <avr/io.h>
#include <stdbool.h>

#include "uart.h"

int main(void) {
    uart_init();
    uart_putstr("Hello, motherfuckers!\n\r");
    while(true) {
        char c = uart_getchar();
        uart_putchar(c);
    }
    return 0;
}
