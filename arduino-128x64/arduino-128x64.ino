// Copyright [2022] <drunkbatya>

#include "SystemFont5x7.h"

// LCD pins
#define D0        8
#define D1        9
#define D2        10
#define D3        11
#define D4        4
#define D5        5
#define D6        6
#define D7        7
#define CE1       14    // A0
#define CE2       15    // A1
#define RW        16    // A2
#define DI        17    // A3
#define E         18    // A4

// defines
#define CHIP1     0x01
#define CHIP2     0x02
#define WRITE     0
#define READ      0x01
#define CMD       0
#define DATA      0x01

uint8_t dataPins[8] = {
  D0, D1, D2, D3,
  D4, D5, D6, D7
};

void strob(void) {
  delayMicroseconds(1);
  digitalWrite(E, HIGH);
  delayMicroseconds(1);
  digitalWrite(E, LOW);
  delayMicroseconds(1);
}

void writeByte(uint8_t data, uint8_t chip, uint8_t type) {
  digitalWrite(RW, WRITE);
  digitalWrite(DI, type);  // Data or Command
  if (chip == CHIP1)
    digitalWrite(CE1, HIGH);
  else
    digitalWrite(CE2, HIGH);
  for (int i = 0; i < 8; i++) {
    digitalWrite(dataPins[i], (data >> i) & 0x01);
  }
  strob();
  digitalWrite(CE1, LOW);
  digitalWrite(CE2, LOW);
}

void setRamPage(uint8_t page) {
  page = page + B10111000;
  writeByte(page, CHIP1, CMD);
  writeByte(page, CHIP2, CMD);
}

void setRamAddress(uint8_t address) {
  address = address + B01000000;
  writeByte(B01000000, CHIP1, CMD);
  writeByte(B01000000, CHIP2, CMD);
}

void shiftRamPage(void) {
  static uint8_t page = 1;
  if (page > 7) {
    writeByte((B11000000 + 8), CHIP1, CMD);
    writeByte((B11000000 + 8), CHIP2, CMD);
    page = 0;
  }
  setRamAddress(0);
  setRamPage(page);
  page++;
}

void clearScreen(void) {
  for (uint8_t page = B10111000; page < B11000000; page++) {
    writeByte(page, CHIP1, CMD);
    writeByte(page, CHIP2, CMD);
    for (uint8_t i = 0; i < 64; i++) {
      writeByte(B00000000, CHIP1, DATA);
      writeByte(B00000000, CHIP2, DATA);
    }
  }
  setRamAddress(0);  // set vram address to 0
  setRamPage(0);  // set vram page to 0
}

void newLine(uint8_t *charPosition) {
  setRamAddress(0);
  shiftRamPage();
  *charPosition = 0;
}

void writeChar(char c) {
  static uint8_t charPosition = 0;
  uint8_t chip;
  int offset = (c - ' ') * SYSTEM5x7_WIDTH;  // (space) is a first char in font
  if (charPosition > (127 - SYSTEM5x7_WIDTH))
    newLine(&charPosition);
  if (c == '\n' || c == '\r') {
    newLine(&charPosition);
    return;
  }
  for (int i = 0; i < SYSTEM5x7_WIDTH; i++) {
    if (charPosition > 63)
      chip = CHIP2;
    else
      chip = CHIP1;
    writeByte(System5x7[offset + i], chip, DATA);
    charPosition++;
  }
  writeByte(0, chip, DATA);  // empty 1dot space after char
  charPosition++;
}

void writeStr(char *str) {
  while (*str != '\0') {
    writeChar(*str);
    str++;
  }
}

void dispInit(void) {
  writeByte(B11000000, CHIP1, CMD);  // set start line as 0
  writeByte(B11000000, CHIP2, CMD);
  writeByte(B00111111, CHIP1, CMD);  // power on display
  writeByte(B00111111, CHIP2, CMD);
  setRamAddress(0);
  clearScreen();
}

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < 8; i++) {
    pinMode(dataPins[i], OUTPUT);
  }
  pinMode(CE1, OUTPUT);
  pinMode(CE2, OUTPUT);
  pinMode(RW, OUTPUT);
  pinMode(DI, OUTPUT);
  pinMode(E, OUTPUT);
  dispInit();
  writeStr("#!/bin/bash");
}
void loop() {
  if (Serial.available()) {
    writeChar(Serial.read());
  }
}
