#include <string.h>
#include "menu.h"
#include "sh1106_buf.h"
#include "encoder.h"

static uint8_t current_view_id = 0;

static void disp0(void)
{
    sh1106_write_str_inv("FREQ", 1 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("STEP  BRGT  CONT", 7 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("Encoder: ", 0, 2);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 2);
}

static void disp1(void)
{
    sh1106_write_str("FREQ", 1 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str_inv("STEP", 7 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("BRGT  CONT", 13 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("Encoder: ", 0, 2);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 2);
}

static void disp2(void)
{
    sh1106_write_str("FREQ  STEP", 1 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str_inv("BRGT", 13 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("CONT", 19 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("Encoder: ", 0, 2);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 2);
}

static void disp3(void)
{
    sh1106_write_str("FREQ  STEP  BRGT", 1 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str_inv("CONT", 19 * SH1106_CHAR_WIDTH, 7);
    sh1106_write_str("Encoder: ", 0, 2);
    sh1106_write_num(encoder_value(), (strlen("Encoder: ") * 5), 2);
}

static const t_menu_item views[4] = {
    { 0, &disp0, 1 },
    { 0, &disp1, 2 },
    { 1, &disp2, 3 },
    { 2, &disp3, 3 }
};

void menu_show_view(void)
{
    views[current_view_id].render();
}

void menu_prev(void)
{
    current_view_id = views[current_view_id].prev_id;
}

void menu_next(void)
{
    current_view_id = views[current_view_id].next_id;
}
