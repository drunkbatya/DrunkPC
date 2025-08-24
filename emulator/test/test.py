#!/usr/bin/env python3
"""
make_font6x8.py — rasterize a pixel font (WOFF/WOFF2/TTF) into a 6x8 bitmap table.

Result shape (when --format js):
  export const font = [
    [r0..r7],  # code 0x00 (each rN is 0..63, 6 LSBits = pixels, bit0 = leftmost)
    [r0..r7],  # code 0x01
    ...
    [r0..r7],  # code 0xFF
  ];

Usage examples:
  python make_font6x8.py Px437_HP_100LX_6x8.woff2 -o font6x8.js --format js --ascii
  python make_font6x8.py Px437_HP_100LX_6x8.woff2 -o font6x8.json --format json --full

Notes:
  - We render onto an 8x8 staging canvas at size 8px, then sample/crop columns 0..5.
  - This fits “HP 100LX 6×8” style pixel fonts. For other fonts, adjust thresholds or offsets.
"""

import argparse
import io
import json
import os
import sys
import tempfile
from typing import List

from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont

# ----------------------------- utils -----------------------------

def woff_to_ttf_bytes(path: str) -> bytes:
    """
    Load WOFF/WOFF2/TTF with fontTools and return TTF bytes.
    - If input is already TTF/OTF, returns its bytes unchanged.
    - If WOFF/WOFF2, converts by saving with flavor=None.
    """
    with open(path, "rb") as f:
        raw = f.read()

    # Try to interpret via fontTools
    tt = TTFont(io.BytesIO(raw))
    # If it had a web flavor, drop it to save TTF
    tt.flavor = None
    out = io.BytesIO()
    tt.save(out)
    return out.getvalue()


def load_font_pillow_from_ttf_bytes(ttf_bytes: bytes, size_px: int) -> ImageFont.FreeTypeFont:
    """Create a PIL ImageFont from TTF bytes at the given pixel size."""
    return ImageFont.truetype(io.BytesIO(ttf_bytes), size=size_px)

def reverse_bits(val, width=8):
    res = 0
    for _ in range(width):
        res = (res << 1) | (val & 1)
        val >>= 1
    return res


def rasterize_code_to_6x8_rows(font: ImageFont.FreeTypeFont, code: int, thresh: int = 128) -> List[int]:
    """
    Render character (by Unicode codepoint) to 8x8 staging, sample 6x8, return list[8] of 0..63.
    bit0 = leftmost pixel.
    """
    # Stage: 8x8 grayscale
    stage_w, stage_h = 8, 8
    img = Image.new("L", (stage_w, stage_h), 0)  # black
    drw = ImageDraw.Draw(img)

    ch = chr(code)
    # Draw white glyph at (0,0); pixel fonts at size=8 usually align on grid.
    drw.text((0, 0), ch, font=font, fill=255, anchor=None)

    # Optional: If you find baseline is off for a font, you can nudge:
    # bbox = drw.textbbox((0,0), ch, font=font)
    # dx, dy = 0, 0  # tweak here if needed

    # Threshold and pack 6 cols × 8 rows
    rows = [0] * 8
    px = img.load()
    for y in range(8):
        row_bits = 0
        for x in range(6):  # keep columns 0..5
            # luminance = grayscale already, just compare to thresh
            if px[x, y] > thresh:
                row_bits |= (1 << x)  # bit0 = leftmost pixel
        rows[y] = row_bits & 0x3F
        rows[y] = reverse_bits(rows[y])
    return rows


def build_font_table(ttf_bytes: bytes, ascii_only: bool, full_range: bool, size_px: int = 8) -> List[List[int]]:
    """
    Create 256×8 table (list of 256 lists of 8 ints).
    - ascii_only: fill 0x20..0x7E; others remain zeros
    - full_range: fill 0x00..0xFF (any codepoint supported by the font), else zero for missing glyphs
    If both False -> default to ascii_only=True.
    """
    if not ascii_only and not full_range:
        ascii_only = True

    font = load_font_pillow_from_ttf_bytes(ttf_bytes, size_px)

    table = [[0]*8 for _ in range(256)]

    def do_code(code: int):
        try:
            rows = rasterize_code_to_6x8_rows(font, code)
        except Exception:
            rows = [0]*8
        table[code] = rows

    if full_range:
        for code in range(256):
            do_code(code)
    else:
        for code in range(0x20, 0x7F):  # printable ASCII
            do_code(code)
        # Others left as zeros
    return table


def write_output(table: List[List[int]], out_path: str, fmt: str):
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    if fmt == "json":
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(table, f, ensure_ascii=False, indent=2)
    elif fmt == "js":
        # Emit pretty JS array with export
        with open(out_path, "w", encoding="utf-8") as f:
            f.write("const font = [\n")
            for code in range(256):
                rows = table[code]
                row_str = ", ".join(str(r) for r in rows)
                f.write(f"  /* 0x{code:02X} */ [{row_str}],\n")
            f.write("];\n")
            f.write("// font[code][row] -> 0..63 (6 LSBits)\n")
    else:
        raise ValueError("Unknown format (use 'js' or 'json').")


# ----------------------------- CLI -----------------------------

def main():
    ap = argparse.ArgumentParser(description="Rasterize WOFF/WOFF2/TTF into 6x8 font array.")
    ap.add_argument("input", help="Path to .woff/.woff2/.ttf font (e.g., Px437_HP_100LX_6x8.woff2)")
    ap.add_argument("-o", "--output", required=True, help="Output file (e.g., font6x8.js or font6x8.json)")
    ap.add_argument("--format", choices=["js", "json"], default="js", help="Output format (default: js)")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--ascii", action="store_true", help="Fill ASCII 0x20..0x7E only (default)")
    g.add_argument("--full", action="store_true", help="Fill full 0..255 range")
    ap.add_argument("--size", type=int, default=8, help="Font pixel size for rendering (default: 8)")
    ap.add_argument("--threshold", type=int, default=128, help="B/W threshold (0..255, default 128)")
    args = ap.parse_args()

    # Load/convert to TTF bytes
    try:
        ttf_bytes = woff_to_ttf_bytes(args.input)
    except Exception as e:
        print(f"Error reading font '{args.input}': {e}", file=sys.stderr)
        sys.exit(1)

    # Build table
    table = build_font_table(ttf_bytes, ascii_only=args.ascii or not args.full, full_range=args.full, size_px=args.size)

    # If custom threshold requested, re-run raster with that threshold
    # (kept simple: threshold is used inside rasterize_code_to_6x8_rows; for now it's fixed at 128 in call)
    # For per-run threshold, you can thread it down or just keep default 128.
    # To honor --threshold, re-render here:
    if args.threshold != 128:
        font = load_font_pillow_from_ttf_bytes(ttf_bytes, args.size)
        for code in (range(256) if args.full else range(0x20, 0x7F)):
            try:
                rows = rasterize_code_to_6x8_rows(font, code, thresh=args.threshold)
            except Exception:
                rows = [0]*8
            table[code] = rows

    # Write output
    try:
        write_output(table, args.output, args.format)
    except Exception as e:
        print(f"Error writing output: {e}", file=sys.stderr)
        sys.exit(2)

    print(f"OK: wrote {args.output} ({args.format}), "
          f"{'ASCII 0x20..0x7E' if not args.full else 'full 0..255'} at {args.size}px.")


if __name__ == "__main__":
    main()

