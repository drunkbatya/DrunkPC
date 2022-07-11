#ifndef _MAIN_H_
#define _MAIN_H_

#include "stm32f4xx_hal.h"

// Address bus
#define A0 PB0
#define A1 PB1
#define A2 PB2
#define A3 PB3
#define A4 PB4
#define A5 PB5
#define A6 PB6
#define A7 PB7
#define A8 PB8
#define A9 PB9
#define A10 PB10
#define A11 PB12  // !! pin 11 skipped by manufacturer !!
#define A12 PB13
#define A13 PB14
#define A14 PB15

// Data bus
#define D0 PA0
#define D1 PA1
#define D2 PA2
#define D3 PA3
#define D4 PA4
#define D5 PA5
#define D6 PA6
#define D7 PA7

#define CLK PA8  // clock signal; output
#define CS PA9  // EEPROM CS; input

#endif  // _MAIN_H_
