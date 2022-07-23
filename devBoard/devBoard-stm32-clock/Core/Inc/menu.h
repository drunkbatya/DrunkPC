#ifndef _MENU_H_
#define _MENU_H

#include "stm32f4xx_hal.h"

typedef struct s_menu_item {
    uint8_t prev_id;
    void (*render)(void);
    uint8_t next_id;
} t_menu_item;

void menu_show_view(void);
void menu_prev(void);
void menu_next(void);

#endif  // _MENU_H_
