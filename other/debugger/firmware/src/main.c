#include <avr/io.h>
#include <stdbool.h>

#include "uart.h"

#define BAUD_RATE 115200

int main(void) {
    uart_init(BAUD_RATE);
    uart_putstr("Hello, motherfuckers!\n\r");
    while(true) {
        char c = uart_getchar();
        uart_putchar(c);
    }
    return 0;
}
