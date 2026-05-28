<picture>
    <img
        alt="A picture of DrunkPC"
        src="/.github/assets/DrunkPC.png">
</picture>

# DrunkPC

## Emulator
You can try it out on web emulator: [https://drunkbatya.github.io/DrunkPC](https://drunkbatya.github.io/DrunkPC/)
Emulator idea is inspired by [@alemorf](https://github.com/alemorf)

## About

This is a simple Zilog Z80-based portable computer consists of only 7 chips. It was a my childhood's dream - to make my own computer, to get the answer for question "how does it works?".

## Features
- Self-Updater!! (from CompactFlash card)
- RA6963 driver (both text and graphics mode, incl. custom fonts)
- AT28C526 write driver (page/byte writes, proper end of cycle monitoring)
- CompactFlash (IDE) driver (read/write sectors, LBA)
- Keyboard driver
- Command line arguments parsing (by ' ' sep)
- Text viewer (with scroll down and up!!)
- JS emulator for testing in browser

## Supported commands
### List
  - `msbasic` - a port of [Microsoft Basic 4.7](https://github.com/feilipu/NASCOM_BASIC_4.7)
  - `update` - do a whole firmware update from CF card
  - `uname` - basic Unix `uname` with the full subset of args
  - `less` - simple basic Unix `less`, but now with only one test builtin file
  - `test_app` - for test cmd line args parsing (argc, argv)
  - `cf_info` - prints an identity CompactFlash info
  - `snake` - a raw Sanake Game (work in progress)

## Specs
- 240x64 Winstar RA6963-based sunlight-readable graphic display
- Zilog Z80 CPU
- 48k RAM (AS6C1008)
- 16k ROM (AT28C256 flash chip)
- On-board 59-key keyboard
- 5 AH Li-Po battery with on-board charger and DC-DC step-up
- No interrupts, memmory banking, context switching, built-in GPIO, timers etc.

This display controller is disigned to be connected directly to the 8080-style data bus (separate R/W pins). The keyboard is conneted to the buses via 74-series logic (line decoder and buffer).

Schematics, Gerber, BOM and other PickAndPlace files located in [hardware](https://github.com/drunkbatya/DrunkPC/tree/dev/hardware) directory.

## Building
To build OS for this source you need a binutils compiled for target z80-elf, and other tools like `make` etc. Compiling is tested only on UNIX-like operating systems. I'm using [binutils-z80-elf](https://github.com/drunkbatya/binutils-z80-elf) Docker image in Github CI.

### Compiling binutils
```bash
    wget https://ftp.gnu.org/gnu/binutils/binutils-2.45.tar.xz
    tar -xvf binutils-2.45.tar.xz
    cd binutils-2.45
    ./configure --target=z80-elf
```

### Compiling OS
To compile OS main images (.elf, .hex, .bin) just type:
```bash
    make
```

To compile an update image use:
```bash
    make updater_image
```

To compile both OS and updater images for emulator use:
```bash
    make emulator_dist
```

## Updating
First download updater image from [releases](https://github.com/drunkbatya/DrunkPC/releases), or compile it:
```bash
git checkout 1.0.2
cd software
make updater_image
```

Then flash it to CF card
```bash
dd if=build/firmware_updater_cf_image.img of=CF_CARD_BLOCK_DEVICE_NOT_A_PARTITION
```

Insert a CF card, power on the DrunkPC, ensure CF card is working typing `cf_info`, then type `update` and follow the update process
