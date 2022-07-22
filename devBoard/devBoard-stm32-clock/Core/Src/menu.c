#include <string.h>
#include "menu.h"
#include "sh1106_buf.h"
#include "encoder.h"

static uint8_t current_view_id = 0;

static void disp0(void)
{
    sh1106_write_str("I try to test this display, it's amazing, but it works!! I can just put new line character (\\n)\nand text will be placed to new line!", 0, 0);
    sh1106_write_str("Encoder: ", 0, 6);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 6);
}

static void disp1(void)
{
    sh1106_write_str("Disp1@@!!!fwegwef", 0, 0);
    sh1106_write_str("Encoder: ", 0, 6);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 6);
}

static void disp2(void)
{
    sh1106_write_str("Disp2wgwrbgwrgwgwfwefw", 0, 0);
    sh1106_write_str("Encoder: ", 0, 6);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 6);
}

static void disp3(void)
{
    sh1106_write_str("Disp3@@!!!*&O**^*^*(YHJKKGKUGUIY*(YUOHLHIOUU", 0, 0);
    sh1106_write_str("Encoder: ", 0, 6);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 6);
}

static const t_menu_item views[4] = {
    { 0, &disp0, 1 },
    { 0, &disp1, 2 },
    { 1, &disp2, 3 },
    { 2, &disp3, 3 }
};

static void menu_show_view_wrapper(void (*view)())
{
    view();
}

void menu_show_view(void)
{
    menu_show_view_wrapper(views[current_view_id].render);
}

void menu_prev(void)
{
    current_view_id = views[current_view_id].prev_id;
}

void menu_next(void)
{
    current_view_id = views[current_view_id].next_id;
}
