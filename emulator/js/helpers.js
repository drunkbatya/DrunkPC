const toHexStr = (number, w = 4) => number.toString(16).toUpperCase().padStart(w, "0");

const HEX2 = new Array(256);
const ASCII = new Array(256);
for (let i = 0; i < 256; i++) {
  HEX2[i] = (i + 0x100).toString(16).slice(1).toUpperCase(); // "00".."FF"
  ASCII[i] = (i >= 0x20 && i <= 0x7E) ? String.fromCharCode(i) : ".";
}

function hex8(n) {
  n >>>= 0;
  const b0 = (n >>> 24) & 0xFF;
  const b1 = (n >>> 16) & 0xFF;
  const b2 = (n >>> 8) & 0xFF;
  const b3 = n & 0xFF;
  return HEX2[b0] + HEX2[b1] + HEX2[b2] + HEX2[b3];
}

function hexdumpRange(buf, offset = 0, length = buf.length - offset, row = 16, maxLines = 2048) {
  const end = Math.min(buf.length, offset + length);
  const lines = [];
  let skipped = false;
  let lastWasZero = false;
  let printed = 0;

  for (let base = offset; base < end; base += row) {
    if (printed >= maxLines) { lines.push("... (truncated)"); break; }

    let zeroLine = true;
    const upto = Math.min(base + row, end);
    for (let i = base; i < upto; i++) {
      if (buf[i] !== 0) { zeroLine = false; break; }
    }

    if (zeroLine) {
      if (!lastWasZero) {
        let hex = "";
        let ascii = "";
        for (let i = base; i < upto; i++) { hex += "00 "; ascii += "."; }
        for (let k = upto; k < base + row; k++) hex += "   ";
        lines.push(hex8(base) + "  " + hex.slice(0, -1) + "  |" + ascii + "|");
        printed++;
        lastWasZero = true;
        skipped = false;
      } else if (!skipped) {
        lines.push("*");
        printed++;
        skipped = true;
      }
      continue;
    }

    lastWasZero = false;
    skipped = false;

    let hex = "";
    let ascii = "";
    for (let i = base; i < upto; i++) {
      const b = buf[i];
      hex += HEX2[b] + " ";
      ascii += ASCII[b];
    }
    for (let k = upto; k < base + row; k++) hex += "   ";

    lines.push(hex8(base) + "  " + hex.slice(0, -1) + "  |" + ascii + "|");
    printed++;
  }

  console.log(lines.join("\n"));
}

