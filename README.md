<picture>
    <img
        alt="An animated picture of DrunkPC"
        src="/.github/assets/DrunkPC.png">
</picture>

# DrunkPC

## Emulator
You can try it out on web emulator: [https://drunkbatya.github.io/DrunkPC](https://drunkbatya.github.io/DrunkPC/)
Emulator idea is inspired by [@alemorf](https://github.com/alemorf)


## About

This is a simple Zilog Z80-based portable computer consists of only 7 chips. It was a my childhood's dream - to make my own computer, to get the answer for question "how does it works?".

## Specs
- 240x64 Winstar RA6963-based sunlight-readable graphic display
- Zilog Z80 CPU
- 48k RAM ()
- 16k ROM (AT28C256 flash chip)
- On-board .. key keyboard
- 5 AH Li-Po battery with on-board charger and DC-DC step-up
- No interrupts, memmory banking, context switching, built-in GPIO, timers etc.

This display controller is disigned to be connected directly to the 8080-style data bus (separate R/W pins). The keyboard is conneted to the buses via 74-series logic (line decoder and buffer).

## Building
To build OS for this source you need a binutils compiled for target z80-elf, and other tools like `make` etc. Compiling is tested only on UNIX-like operating systems.

### Compiling binutils
```bash
    git clone ...
```

### Compiling OS
```bash
    make
```
