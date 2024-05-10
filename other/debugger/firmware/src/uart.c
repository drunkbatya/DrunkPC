#include <avr/io.h>
#include <avr/interrupt.h>

#include "uart.h"

void uart_init(uint32_t baudrare) {
    uint32_t baud = ((F_CPU / 4 / baudrare) - 1) / 2;  // doubling the transmission speed will produce less speed error
    UBRR0H = (uint8_t)(baud >> 8);  // baudrate high byte
    UBRR0L = (uint8_t)(baud & 0xFF);  // baudrate low byte
    UCSR0A = (1 << U2X0);  // double the transmission speed
    UCSR0C = (1 << UCSZ00) | (1 << UCSZ01);  // sync uart, 8n1
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);  // enable RX and TX, disable interrupts etc.
}

void uart_putchar(uint8_t data) {
    while(!(UCSR0A & (1 << UDRE0)));  // wait for transmit buffer to be empty
    UDR0 = data;
}

uint8_t uart_getchar(void) {
    while(!(UCSR0A & (1 << RXC0)));  // wait for data in the recive buffer
    return UDR0;
}

void uart_putstr(const char* str) {
    while(*str) {
        uart_putchar(*str);
        str++;
    }
}

