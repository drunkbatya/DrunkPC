function CompactFlash() {
    const COMPACT_FLASH_DATA = 0  // data register, (R/W)
    const COMPACT_FLASH_ERR = 1  // error register, (R)
    const COMPACT_FLASH_FEAT = 1  // features register, (W)
    const COMPACT_FLASH_SECC = 2  // sector count register, (R/W)
    const COMPACT_FLASH_LBA0 = 3  // LBA bits 0-7 register, (R/W)
    const COMPACT_FLASH_LBA1 = 4  // LBA bits 8-15 register, (R/W)
    const COMPACT_FLASH_LBA2 = 5  // LBA bits 16-23 register, (R/W)
    const COMPACT_FLASH_LBA3 = 6  // LBA bits 24-27 register (bits 0-3), (R/W), and Drive Head Register, (R/W)
    const COMPACT_FLASH_STAT = 7  // status register, (R)
    const COMPACT_FLASH_CMD = 7  // command register, (W)

    this.write = function(addr, value) {
        // console.log(`CF: write, addr: 0x${toHexStr(addr, 2)}, value 0x${toHexStr(value, 2)}`);
        switch (addr) {
            case COMPACT_FLASH_DATA:
                break;
            case COMPACT_FLASH_ERR:
                break;
            case COMPACT_FLASH_FEAT:
                break;
            case COMPACT_FLASH_SECC:
                break;
            case COMPACT_FLASH_LBA0:
                break;
            case COMPACT_FLASH_LBA1:
                break;
            case COMPACT_FLASH_LBA2:
                break;
            case COMPACT_FLASH_LBA3:
                break;
            case COMPACT_FLASH_STAT:
            case COMPACT_FLASH_CMD:
                break;
            default:
                console.log(`CF: writing to unknown addr: 0x${toHexStr(addr, 2)}, value 0x${toHexStr(value, 2)}`);
        }
    }

    this.read = function(addr) {
        // console.log(`CF: read, addr: 0x${toHexStr(addr, 2)}`);
        switch (addr) {
            case COMPACT_FLASH_DATA:
                break;
            case COMPACT_FLASH_ERR:
                break;
            case COMPACT_FLASH_FEAT:
                break;
            case COMPACT_FLASH_SECC:
                break;
            case COMPACT_FLASH_LBA0:
                break;
            case COMPACT_FLASH_LBA1:
                break;
            case COMPACT_FLASH_LBA2:
                break;
            case COMPACT_FLASH_LBA3:
                break;
            case COMPACT_FLASH_STAT:
            case COMPACT_FLASH_CMD:
                break;
            default:
                console.log(`CF: reading unknown addr: 0x${toHexStr(addr, 2)}`);
        }
        return 0;
    }
}
