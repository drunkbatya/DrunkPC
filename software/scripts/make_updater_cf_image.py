#!/usr/bin/env python3

import argparse

# Update CF card structute:
#   // sector 0
#   const char[16] header,
#   uint16_t update_size,
#   const char[12] version,
#   const char[20] git_branch,
#   const char[8] git_hash_short,
#   const char[11] build_date,
#   uint8_t[512 - 69] reserved,  // to fill sector 0
#   // sector 1 - sector N
#   uint8_t[update_size] data,


class UpdaterStructElem:
    def __init__(self):
        pass


class UpdaterCFImageCreator:
    UPDATE_HEADER = "DRUNKOSUPDATERR"
    UPDATE_HEADER_SIZE = 16
    UPDATE_SIZE_SIZE = 2
    UPDATE_VERSION_SIZE = 12
    UPDATE_GIT_BRANCH_SIZE = 20
    UPDATE_GIT_HASH_SHORT_SIZE = 8
    UPDATE_BUILD_DATE_SIZE = 11

    def __init__(
        self,
        firmware_file: str,
        output_file: str,
        git_tag: str,
        git_branch: str,
        git_hash: str,
        build_date: str,
    ):
        self.firmware_file = firmware_file
        self.output_file = output_file
        self.git_tag = git_tag
        self.git_branch = git_branch
        self.git_hash = git_hash
        self.build_date = build_date

    @staticmethod
    def get_firmware_bytes(filename: str) -> bytes:
        with open(filename, "rb") as f:
            firmware = f.read()
        return firmware

    @staticmethod
    def write_output(filename: str, data: bytes):
        with open(filename, "wb") as f:
            f.write(data)

    @staticmethod
    # return a null terminated bytes from string trimmed (or filled) for exact size
    def get_sized_bytes_from_str(data: str, size: int) -> bytes:
        return data[: (size - 1)].encode("utf-8").ljust(size, b"\x00")

    def run(self):
        firmware = self.get_firmware_bytes(self.firmware_file)
        firmware_size = len(firmware)
        assert firmware_size > 0 and firmware_size <= 0xFFFF
        update_header = self.get_sized_bytes_from_str(
            self.UPDATE_HEADER, self.UPDATE_HEADER_SIZE
        )
        firmware_size_bytes = firmware_size.to_bytes(2, "little")
        git_tag = self.get_sized_bytes_from_str(self.git_tag, self.UPDATE_VERSION_SIZE)
        git_branch = self.get_sized_bytes_from_str(
            self.git_branch, self.UPDATE_GIT_BRANCH_SIZE
        )
        git_hash = self.get_sized_bytes_from_str(
            self.git_hash, self.UPDATE_GIT_HASH_SHORT_SIZE
        )
        build_date = self.get_sized_bytes_from_str(
            self.build_date, self.UPDATE_BUILD_DATE_SIZE
        )
        first_sector_data = b"".join(
            [
                update_header,
                firmware_size_bytes,
                git_tag,
                git_branch,
                git_hash,
                build_date,
            ]
        ).ljust(512, b"\x00")
        output = b"".join([first_sector_data, firmware])
        self.write_output(self.output_file, output)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Creating updater CF image for DrunkPC"
    )
    parser.add_argument("--firmware_file", help="Firmware bin file", required=True)
    parser.add_argument("--output_file", help="Output img file", required=True)
    parser.add_argument("--git_tag", help="Firmware git tag", required=True)
    parser.add_argument("--git_branch", help="Firmware git branch", required=True)
    parser.add_argument("--git_hash", help="Firmware git hash", required=True)
    parser.add_argument("--build_date", help="Firmware build date", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    imgC = UpdaterCFImageCreator(
        firmware_file=args.firmware_file,
        output_file=args.output_file,
        git_tag=args.git_tag,
        git_branch=args.git_branch,
        git_hash=args.git_hash,
        build_date=args.build_date,
    )
    imgC.run()


if __name__ == "__main__":
    main()
