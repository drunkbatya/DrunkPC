#ifndef _SERIAL_H_
#define _SERIAL_H_

#define UPLOAD_EEPROM_CMD 0x5D

void DrunkSerialInterrupt(void);
void DrunkSerialRead(uint8_t *buf, uint32_t len);

#endif  // _SERIAL_H_
