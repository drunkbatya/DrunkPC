## Description
It's an Arduino sketch, to test Samsung KS0108-based 128x64 dot LCD without any library.

## Shematic
![shematic](https://raw.githubusercontent.com/drunkbatya/DrunkPC/master/assets/img/128x64_bb.png | width=600)

## Usage
U may send chars to display via UART like:
```bash
minicom -D /dev/cu.usbserial-14220 -b 115200
```
