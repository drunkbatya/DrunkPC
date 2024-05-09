#include <avr/io.h>
#include <avr/interrupt.h>

#include "uart.h"

#define BAUD_RATE 115200L

void uart_init(void) {
    UBRR0L = (uint8_t)(F_CPU / (BAUD_RATE * 16L) - 1);  // uart baud low byte
	UBRR0H = (uint8_t)(F_CPU / (BAUD_RATE * 16L) - 1) >> 8;  // uart baud high byte
    UCSR0A = 0;  // clear uart status flags
    UCSR0C = (1 << UCSZ00) | (1 << UCSZ01);  // sync uart, 8n1
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);  // enable RX and TX, disable interrupts etc.
}

void uart_putchar(char c) {
    while(!(UCSR0A & (1 >> UDRE0)));  // wait for transmit buffer to be empty
    UDR0 = (uint8_t)c;
}

void uart_putstr(const char* str) {
    while(*str) {
        uart_putchar(*str);
        str++;
    }
}

char uart_getchar(void) {
    while(!(UCSR0A & (1 << RXC0)));  // wait for data in the recive buffer
    return (unsigned char)UDR0;
}
