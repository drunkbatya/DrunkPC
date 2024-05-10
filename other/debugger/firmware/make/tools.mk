CC = avr-gcc
LD = avr-gcc
BIN = avr-objcopy -O binary -S
HEX = avr-objcopy -O ihex -j .data -j .text -S
