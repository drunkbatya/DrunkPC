function RA6963() {
    // font
    const FONT_OFFSET = 32;
    const FONT_WIDTH = 6;
    const FONT_HEIGHT = 8;

    // custom font
    const CUSTOM_FONT_START_ADDR = 0x7800;
    const OFFSET_REGISTER_VALUE = CUSTOM_FONT_START_ADDR / 2048;

    // info
    const DISPLAY_WIDTH = 240;
    const DISPLAY_HEIGHT = 64;
    const DISPLAY_WIDTH_BYTES = DISPLAY_WIDTH / FONT_WIDTH;
    const DISPLAY_HEIGHT_BYTES = DISPLAY_HEIGHT / FONT_HEIGHT;

    // main
    const SET_TEXT_HOME_ADDRESS = 0x40;
    const SET_TEXT_AREA = 0x41;
    const SET_GRAPHIC_HOME_ADDRESS = 0x42;
    const SET_GRAPHIC_AREA = 0x43;
    const SET_ADDRESS_POINTER = 0x24;
    const GRAPHIC_RAM_START_ADDR = 0x0000;
    const SET_BIT = 0xF8;
    const SET_OFFSET_REGISTER = 0x22;

    // cursor
    const SET_1_LINE_CURSOR = 0xA0;
    const SET_8_LINE_CURSOR = 0xA7;
    const SET_CURSOR_POSITION = 0x21;

    // modes
    const SET_OR_MODE = 0x80;
    const SET_EXOR_MODE = 0x81;
    const SET_AND_MODE = 0x83;
    const SET_TEXT_ATTRIBUTE_MODE = 0x84;

    // display modes
    const SET_DISPLAY_OFF = 0x90;
    const SET_CURSOR_ON_BLINK_OFF = 0x92;
    const SET_CURSOR_ON_BLINK_ON = 0x93;
    const SET_TEXT_ON_GRAPHIC_OFF = 0x94;
    const SET_TEXT_OFF_GRAPHIC_ON = 0x98;
    const SET_TEXT_ON_GRAPHIC_ON = 0x9C;
    const SET_TEXT_ON_GRAPHIC_OFF_CURSOR_ON_BLINK_ON = 0x97;
    const SET_TEXT_OFF_GRAPHIC_ON_CURSOR_ON_BLINK_ON = 0x9B;
    const SET_TEXT_ON_GRAPHIC_ON_CURSOR_ON_BLINK_ON = 0x9F;

    // read/write
    const SET_AUTO_WRITE = 0xB0;
    const RESET_AUTO_WRITE = 0xB2;
    const DATA_WRITE_AND_INC_ADDR = 0xC0;
    const DATA_READ_AND_INC_ADDR = 0xC1;
    const DATA_WRITE = 0xC4;
    const DATA_READ = 0xC5;

    let vram = new Uint8Array(0x8000);

    let canvas = document.getElementById("video");
    let ctx = canvas.getContext("2d");
    let canvasData = ctx.getImageData(0, 0, canvas.width, canvas.height);

    // two bytes of data
    let prevData1 = 0;
    let prevData2 = 0;
    // internal regsters
    let addressPtr = 0x0000;
    let textHomeAddressPtr = 0x0000;
    let graphicHomeAddressPtr = 0x0000;
    let graphicMode = false;
    let textMode = true;
    let cursorBlink = true;
    let cursorX = 0;
    let cursorY = 0;
    let autoWrite = false;
    let cursorHeight = 1;
    let offsetRegister = 0;

    function getCharCodeFromCurrentChar() {
        let num = prevData1;
        num += FONT_OFFSET;
        return num;
    }

    function setAddressPtr(value) {
        addressPtr = value & 0xFFFF;
    }

    function canvasSetPixelState(x, y) {
        if (x < 0 || x > (canvas.width - 1) || y < 0 || y > (canvas.height - 1)) {
            return;
        }
        const canvasBytesPerPixel = 4;
        let arrStart = (x * canvasBytesPerPixel) + (y * (canvas.width * canvasBytesPerPixel));
        canvasData.data[arrStart + 0] = 255; // R
        canvasData.data[arrStart + 1] = 0;   // G
        canvasData.data[arrStart + 2] = 0;   // B
        canvasData.data[arrStart + 3] = 255; // A
    }

    function canvasDrawChar(startX, startY, charCode) {
        let x = startX;
        let y = startY;
        for(let charHeight = 0; charHeight < 8; charHeight++) {
            let byte_column = font[charCode][charHeight];
            for(let bit = 1; bit < 7; bit++) {
                if ((byte_column >> bit) & 0x01) {
                    canvasSetPixelState(x, y);
                }
                x++;
            }
            x = startX;
            y++;
        }
    }

    function drawCursor(charX, charY) {
        const canvasBytesPerPixel = 4;
        const cursorWidth = 6;
        if (charX < 0 || charX > ((canvas.width * cursorWidth) - 1)
            || charY < 0 || charY > ((canvas.height * cursorHeight) - 1))  {
            return;
        }
        let x = charX * cursorWidth;
        let y = charY * cursorHeight;
        for (let canvasY = 0; canvasY < cursorHeight; canvasY++) {
            for (let canvasX = 0; canvasX < cursorWidth; canvasX++) {
                canvasSetPixelState(x + canvasX, y + canvasY, true);
            }
        }
    }

    this.writeData = function (value) {
        if (autoWrite) {
            value += FONT_OFFSET;
            vram[addressPtr] = value & 0xFF;
            addressPtr = (addressPtr + 1) & 0xFFFF;
        } else {
            prevData2 = prevData1;
            prevData1 = value & 0xFF;
        }
    }

    this.writeCmd = function(value) {
        switch (value) {
            case DATA_WRITE_AND_INC_ADDR:
                vram[addressPtr] = getCharCodeFromCurrentChar();;
                addressPtr = (addressPtr + 1) & 0xFFFF;
                break;
            case DATA_WRITE:
                vram[addressPtr] = getCharCodeFromCurrentChar();;
                break;
            case SET_ADDRESS_POINTER:
                addressPtr = (prevData1 << 8 | (prevData2 & 0xFF)) & 0xFFFF;
                break;
            case SET_CURSOR_POSITION:
                cursorX = prevData2 & 0xFF;
                cursorY = prevData1 & 0xFF;
                break;
            case SET_TEXT_HOME_ADDRESS:
                textHomeAddressPtr = (prevData1 << 8 | (prevData2 & 0xFF)) & 0xFFFF;
                break;
            case SET_GRAPHIC_HOME_ADDRESS:
                graphicHomeAddressPtr = (prevData1 << 8 | (prevData2 & 0xFF)) & 0xFFFF;
                break;
            case SET_AUTO_WRITE:
                autoWrite = true;
                break;
            case RESET_AUTO_WRITE:
                autoWrite = false;
                break;
            case SET_OFFSET_REGISTER:
                offsetRegister = prevData2 & 0xFF;
                break;
            case SET_TEXT_AREA:
                console.log(`RA6963: set text area command isn't implemented yet`);
                break;
            case SET_GRAPHIC_AREA:
                console.log(`RA6963: set graphic area command isn't implemented yet`);
                break;
            default:
                if ((value >> 4) == 0x09) {  // set mode command
                    cursorOn = (value & (0x01 << 0));
                    cursorBlink = (value & (0x01 << 1));
                    textMode = (value & (0x01 << 2));
                    graphicMode = (value & (0x01 << 3));
                } else if ((value >> 3) == 0x14) {  // set cursor pattern command
                    cursorHeight = (value & 0x07) + 1;
                } else if ((value >> 4) == 0x08) {  // mode set command
                    console.log(`RA6963: mode set command isn't implemented yet`);
                } else {
                    console.log(`RA6963: unknown cmd 0x${toHexStr(value, 2)}`);
                }
        }
    }
    this.readData = function() {
        return 0xFF;
    }
    this.readCmd = function() {
        return 0xFF;
    }
    this.redraw = function() {
        canvasData.data.fill(0);
        if (textMode) {
            for (let displayTextY = 0; displayTextY < DISPLAY_HEIGHT_BYTES; displayTextY++) {
                for (let displayTextX = 0; displayTextX < DISPLAY_WIDTH_BYTES; displayTextX++) {
                    const charCode = vram[textHomeAddressPtr + (displayTextY * DISPLAY_WIDTH_BYTES) + displayTextX];
                    if (charCode >= 0x20 && charCode <= 0x7E) {
                        canvasDrawChar(displayTextX * FONT_WIDTH, displayTextY * FONT_HEIGHT, charCode);
                    }
                }
            }
        }
        if (graphicMode) {
            for (let canvasY = 0; canvasY < canvas.height; canvasY++) {
                for (let canvasX = 0; canvasX < canvas.width; canvasX++) {
                    canvasSetPixelState(canvasX, canvasY, true);
                }
            }
        }
        if (cursorBlink) {
            drawCursor(cursorX, cursorY);
        }
        ctx.putImageData(canvasData, 0, 0);
    }
}
