#include "encoder.h"

static TIM_TypeDef *timer;
static uint16_t timer_priv;

uint16_t encoder_value(void)
{
    return (timer->CNT);
}

t_encoder_move encoder_move(void)
{
    uint16_t timer_current;
    t_encoder_move encoder_return;

    timer_current = encoder_value();
    if (timer_current % 2)
        return (ENCODER_NO_MOVE);
    if (timer_current < timer_priv)
        encoder_return = ENCODER_DOWN;
    else if (timer_current > timer_priv)
        encoder_return = ENCODER_UP;
    else
        encoder_return = ENCODER_NO_MOVE;
    timer_priv = timer_current;
    return (encoder_return);
}

void encoder_init(TIM_TypeDef *enc_timer)
{
    timer = enc_timer;
    timer_priv = encoder_value();
}
