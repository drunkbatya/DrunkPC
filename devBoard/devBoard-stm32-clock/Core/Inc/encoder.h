#ifndef _ENCODER_H_
#define _ENCODER_H_

#include "stm32f4xx_hal.h"

typedef enum e_encoder_move {
    ENCODER_DOWN,
    ENCODER_UP,
    ENCODER_NO_MOVE
} t_encoder_move;

t_encoder_move encoder_move(void);
uint16_t encoder_value(void);
void encoder_init(TIM_TypeDef *enc_timer);

#endif  // _ENCODER_H_
