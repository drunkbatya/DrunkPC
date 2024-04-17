#include <stdint.h>
#include <stdio.h>
#include "main.h"

void terminal_init(void);
void terminal_putchar(char c);
extern void kutakbash(void);


static void terminal_putstr(const char* str) {
    while(*str != '\0') {
        terminal_putchar(*str);
        str++;
    }
}
uint8_t main(void) {
    terminal_init();
    terminal_putstr("Welcome to DrunkOS!\n\n");
    //terminal_putstr("Test.\nTest..\nTest...\nTest....\nTest.....\n");
    kutakbash();
    //asm("halt");
    return 0;
}
