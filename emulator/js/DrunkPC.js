// Memmory layout
//  ROM: 0x0000 - 0x3FFF;
//  RAM: 0x4000 - 0xFFFF;
// IO layout:
//  A0-A3 - IO free lines
//  A4 - internal decoder low active
//  A5-A7 - IO device number in binnary
//      0b0000xxxx - device 0
//      0b1110xxxx - device 7
//      0bxxx1xxxx - decoder disabled, other bus lines are yours

const IO_LCD_BASE = 0b00000000  // A5 = 0 - device 0
const IO_LCD_DATA_ADDR = IO_LCD_BASE + 0  // lcd data transfer
const IO_LCD_CMD_ADDR = IO_LCD_BASE + 1  // lcd command transfer

const IO_KBD_ADDR = 0b00100000 // A5 = 1 - device 1

const COMPACT_FLASH_BASE = 0b01000000  // A6 = 1 - device 2

let ram = new Uint8Array(0xFFFF + 1);
let romLocked = true;
let video = new RA6963();
let keyboard = new Keyboard();
let cf = new CompactFlash();

function readMemmory(addr) {
    if (addr >= 0x4000) {
        return ram[addr];
    } else {
        return firmware[addr];
    }
};

function writeMemmory(addr, value) {
    if (addr >= 0x4000) {
        ram[addr] = value;
    } else {
        if (romLocked) {
            console.log(
                "Failed write to ROM because it locked! " +
                `Address: ${toHexStr(addr)}, ` +
                `value: ${toHexStr(value)}}`
            );
        } else {
            firmware[addr] = value;
        }
    }
};

function readIO(addr) {
    addr = addr & 0xFF;
    switch (addr) {
        case IO_LCD_DATA_ADDR:
            return video.readData();
        case IO_LCD_CMD_ADDR:
            return video.readCmd();
        case IO_KBD_ADDR:
            return keyboard.read();
        default:
            if ((addr >> 4) == (COMPACT_FLASH_BASE >> 4)) {
                return cf.read(addr & 0x0F);
            } else {
                console.log(`Reading from unknown IO: 0x${toHexStr(addr, 2)}`);
            }
    }
    return 0;
};

function writeIO(addr, value) {
    addr = addr & 0xFF;
    switch (addr) {
        case IO_LCD_DATA_ADDR:
            video.writeData(value);
            break;
        case IO_LCD_CMD_ADDR:
            video.writeCmd(value);
            break;
        case IO_KBD_ADDR:
            keyboard.write(value);
            break;
        default:
            if ((addr >> 4) == (COMPACT_FLASH_BASE >> 4)) {
                cf.write((addr & 0x0F), value);
            } else {
                console.log(`Writing to unknown IO: 0x${toHexStr(addr, 2)}, value: 0x${toHexStr(value, 2)}`);
            }
    }
};

let z80 = new Z80({
    mem_read: readMemmory,
    mem_write: writeMemmory,
    io_read: readIO,
    io_write: writeIO
});

const cpuSpeedKhz = 4000;
let lastTimeMs = 0;
let ticks = 0;
let stop = false;

function idle(timeMs) {
    timeMs = Math.round(timeMs);
    const deltaTimeMs = timeMs - lastTimeMs;
    lastTimeMs = timeMs;

    ticks += Math.min(deltaTimeMs, 500) * cpuSpeedKhz;

    while (ticks > 0)
        ticks -= z80.run_instruction();

    video.redraw();

    if (!stop) {
        requestAnimationFrame(idle);
    }
}

requestAnimationFrame(idle);

//for (let i = 0; i < 100000; i++)
//    z80.run_instruction();
//video.redraw();
