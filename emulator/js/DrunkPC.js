// Memmory layout
// ROM: 0x0000 - 0x3FFF;
// RAM: 0x4000 - 0xFFFF;

let ram = new Uint8Array(0xFFFF + 1);
let romLocked = true;
let video = new RA6963();
const videoAddr = 0x00;
const videoAddrData = videoAddr + 0x00;
const videoAddrCmd = videoAddr + 0x01;
const kbdAddr = 0x20;

function readMemmory(addr) {
    if (addr >= 0x4000) {
        //console.log(`CPU: reading RAM: ${toHexStr(addr)}`);
        return ram[addr];
    } else {
        //console.log(`CPU: reading ROM: ${toHexStr(addr)}`);
        return rom[addr];
    }
};

function writeMemmory(addr, value) {
    if (addr >= 0x4000) {
        //console.log(`CPU: writing RAM: ${toHexStr(addr)} with ${toHexStr(value)}`);
        ram[addr] = value;
        //console.log(`Writing RAM: ${toHexStr(addr)} with ${toHexStr(value)}`)
    } else {
        if (romLocked) {
            console.log(
                "Failed write to ROM because it locked! " +
                `Address: ${toHexStr(addr)}, ` +
                `value: ${toHexStr(value)}}`
            );
        } else {
            //console.log(`CPU: writing ROM: ${toHexStr(addr)} with ${toHexStr(value)}`);
            rom[addr] = value;
        }
    }
};

function readIO(addr) {
    addr = addr & 0xFF;
    switch (addr) {
        case videoAddrData:
            //console.log(`Reading video data: ${toHexStr(addr)}`);
            return video.readData();
        case videoAddrCmd:
            let out = video.readCmd();
            //console.log(`Reading video cmd: ${toHexStr(addr)}, ${out}`);
            return out;
        case kbdAddr:
            //console.log(`Reading keyboard`);
            break;
        default:
            console.log(`Reading from unknown IO: 0x${toHexStr(addr, 2)}`);
    }
    return 0;
};

function writeIO(addr, value) {
    addr = addr & 0xFF;
    switch (addr) {
        case videoAddrData:
            video.writeData(value);
            break;
        case videoAddrCmd:
            video.writeCmd(value);
            break;
        case kbdAddr:
            //console.log(`Writing keyboard: 0x${toHexStr(value)}`);
            break;
        default:
            console.log(`Writing to unknown IO: 0x${toHexStr(addr, 2)}, value: 0x${toHexStr(value, 2)}`);
    }
};

let z80 = new Z80({mem_read: readMemmory, mem_write: writeMemmory, io_read: readIO, io_write: writeIO});

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

//requestAnimationFrame(idle);

for (let i = 0; i < 100000; i++)
    z80.run_instruction();
video.redraw();
