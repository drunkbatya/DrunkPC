#include <stdint.h>

extern void terminal_putchar(char c);
extern char keyboard_get_key(void);

typedef uint8_t bool;
#define true 1
#define false 0

char str_buf[100];

static inline bool is_print(char c) {
    return (((c >= ' ' && c <= '~') || (c == '\n')) ? 1 : 0);
}

static void terminal_putstr(const char* str) {
    while(*str != '\0') {
        terminal_putchar(*str);
        str++;
    }
}

static bool str_is_empty(const char* str) {
    while(*str != '\0') {
        if(*str > 32) return false;
        str++;
    }
    return true;
}

void strappend(char* str, char c) {
    while(*str != '\0') {
        str++;
    }
    *str = c;
    str++;
    *str = '\0';
}

static void kutakbash_parse_command(const char* buf) {
    if(str_is_empty(buf) == false) {
        terminal_putstr("Error: ");
        terminal_putstr(buf);
        terminal_putstr(" not found\n");
    }
}

void kutakbash(void) {
    while(1) {
        terminal_putstr("KutakBash :-) ");
        *(str_buf) = '\0';
        char c = keyboard_get_key();
        while(c != '\n') {
            if(is_print(c)) {
                strappend(str_buf, c);
                terminal_putchar(c);
            }
            c = keyboard_get_key();
        }
        terminal_putchar(c);
        kutakbash_parse_command(str_buf);
    }
}
