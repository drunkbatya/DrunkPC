#!/usr/bin/env python3
# This code was taken from the official Flipper Zero firmware repository:
# https://github.com/flipperdevices/flipperzero-firmware
# And distributes under GNU GPL-3.0 license
import io
import os
import argparse
from PIL import Image, ImageOps

ICONS_SUPPORTED_FORMATS = ["png"]

ICONS_TEMPLATE_INC_ICON_NAME = """.global {name}
"""

ICONS_TEMPLATE_INC_FONT_NAME = """{upper_name}_SIZE = {size}
.global {name}_arr
"""

ICONS_TEMPLATE_ASM_HEADER = """.include "assets/build/assets_icons.inc"
.section .rodata

"""
ICONS_TEMPLATE_ASM_ICON = """{name}:
    {name}_width: .byte {width}
    {name}_height: .byte {height}
    {name}_data: .byte {data}
"""

ICONS_TEMPLATE_ASM_FONT_CHAR = "    .byte {data}  ; {name}"
ICONS_TEMPLATE_ASM_SKIP_BYTES = "    .skip {skip} * 8  ; no chars in this range\n"

ICONS_TEMPLATE_ASM_ARR_HEADER = "{name}_arr:\n"
ICONS_TEMPLATE_ASM_ARR_LINE = "    .word {data}\n"


def swap_bits(num):
    num = (num & 0xF0) >> 4 | (num & 0x0F) << 4
    num = (num & 0xCC) >> 2 | (num & 0x33) << 2
    num = (num & 0xAA) >> 1 | (num & 0x55) << 1
    return num


class CImage:
    def __init__(self, width: int, height: int, data: bytes):
        self.width = width
        self.height = height
        self.data = data

    def write(self, filename):
        with open(filename, "wb") as file:
            file.write(self.data)

    def data_as_carray(self):
        return ", ".join(
            "0x{:02x}".format(swap_bits(img_byte)) for img_byte in self.data
        )


def is_file_an_icon(filename):
    extension = filename.lower().split(".")[-1]
    return extension in ICONS_SUPPORTED_FORMATS


def png2xbm(file):
    with Image.open(file) as im:
        with io.BytesIO() as output:
            bw = im.convert("1")
            bw = ImageOps.invert(bw)
            bw.save(output, format="XBM")
            return output.getvalue()


def file2image(file):
    output = png2xbm(file)
    assert output
    f = io.StringIO(output.decode().strip())
    width = int(f.readline().strip().split(" ")[2])
    height = int(f.readline().strip().split(" ")[2])
    data = f.read().strip().replace("\n", "").replace(" ", "").split("=")[1][:-1]
    data_str = data[1:-1].replace(",", " ").replace("0x", "")
    data_bin = bytearray.fromhex(data_str)
    return CImage(width, height, data_bin)


def _icon2header(file):
    image = file2image(file)
    return image.width, image.height, image.data_as_carray()


def _iconIsSupported(filename):
    extension = filename.lower().split(".")[-1]
    return extension in ICONS_SUPPORTED_FORMATS


def icons(args):
    print("ICON: Converting icons")
    os.makedirs(args.output_directory, exist_ok=True)
    icons_c = open(
        os.path.join(args.output_directory, f"{args.filename}.s"),
        "w",
        newline="\n",
    )
    icons = []
    fonts = []
    icons_c.write(ICONS_TEMPLATE_ASM_HEADER)
    # Traverse icons tree, append image data to source file
    for dirpath, dirnames, filenames in os.walk(args.input_directory):
        print(f"ICON: Processing directory {dirpath}")
        dirnames.sort()
        filenames.sort()
        if not filenames:
            continue
        if os.path.basename(dirpath).startswith("font_"):
            print(f"ICON: Folder contains font")
            font_name = os.path.split(dirpath)[1].replace("-", "_")
            icons_c.write(ICONS_TEMPLATE_ASM_ARR_HEADER.format(name=font_name))
            previous_char_code = 0
            size = 0
            for filename in sorted(
                filenames, key=lambda current: int(current.split(".png")[0])
            ):
                fullfilename = os.path.join(dirpath, filename)
                if not _iconIsSupported(filename):
                    continue
                char_code = filename.split(".png")[0]
                current_char_code = int(char_code)
                print(
                    f"ICON: Processing {font_name} character {chr(current_char_code)}"
                )

                if previous_char_code == 0:
                    previous_char_code = current_char_code
                    size += 8
                else:
                    offset = current_char_code - previous_char_code
                    if offset > 1:  # need to insert blank data
                        icons_c.write(
                            ICONS_TEMPLATE_ASM_SKIP_BYTES.format(skip=str(offset - 1))
                        )
                    previous_char_code = current_char_code
                    size += offset * 8

                fullfilename = os.path.join(dirpath, filename)
                width, height, data = _icon2header(fullfilename)
                icons_c.write(
                    ICONS_TEMPLATE_ASM_FONT_CHAR.format(name=char_code, data=data)
                )
                icons_c.write("\n")
                # icons.append((char_code, width, height))
            fonts.append((font_name, size))
        else:
            # process icons
            for filename in filenames:
                if not _iconIsSupported(filename):
                    continue
                print(f"ICON: Processing icon {filename}")
                icon_name = "icon_" + "_".join(filename.split(".")[:-1]).replace(
                    "-", "_"
                )
                fullfilename = os.path.join(dirpath, filename)
                width, height, data = _icon2header(fullfilename)
                frame_name = icon_name
                icons_c.write(
                    ICONS_TEMPLATE_ASM_ICON.format(
                        name=frame_name, width=width, height=height, data=data
                    )
                )
                icons_c.write("\n")
                icons.append((icon_name, width, height))

    icons_c.close()

    # Create Public Header
    print(f"ICON: Creating header")
    icons_h = open(
        os.path.join(args.output_directory, f"{args.filename}.inc"),
        "w",
        newline="\n",
    )
    for name, width, height in icons:
        icons_h.write(ICONS_TEMPLATE_INC_ICON_NAME.format(name=name))
    for name, size in fonts:
        icons_h.write(
            ICONS_TEMPLATE_INC_FONT_NAME.format(
                name=name, upper_name=name.upper(), size=size
            )
        )
    icons_h.close()
    print(f"ICON: Done")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Converting .png icons to asm array")
    parser.add_argument("input_directory", help="Source directory")
    parser.add_argument("output_directory", help="Output directory")
    parser.add_argument(
        "--filename",
        help="Base filename for file with icon data",
        required=False,
        default="assets_icons",
    )
    args = parser.parse_args()
    icons(args)


if __name__ == "__main__":
    main()
