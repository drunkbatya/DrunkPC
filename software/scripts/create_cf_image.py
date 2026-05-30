#!/usr/bin/env python3

from minixfs import MinixFS, BlockDevice

from pathlib import Path
import argparse


class CompactFlashEmulator(BlockDevice):
    def __init__(self, disk_path: Path, block_size: int = 1024):
        super().__init__()
        self.disk_path = disk_path
        self.tag = f"{self.__class__.__name__} "

        if not self.disk_path.exists() or not self.disk_path.is_file():
            raise Exception(self.tag + f"failed to open path: `{self.disk_path}`")

        self.disk_size = self.disk_path.stat().st_size
        self.block_size = block_size

    def read(self, lba_addr: int, size_in_lba: int) -> list[int]:
        offset = lba_addr * self.block_size
        size_in_bytes = size_in_lba * self.block_size
        if offset + size_in_bytes > self.disk_size:
            raise Exception(
                self.tag
                + f"requested disk offset: `{offset}` + size: `{size_in_bytes}` is out of range"
            )

        with open(self.disk_path, "rb") as disk:
            disk.seek(offset)
            return list(disk.read(size_in_bytes))

    def write(self, lba_addr: int, data: list[int], size_in_lba: int) -> None:
        offset = lba_addr * self.block_size
        size_in_bytes = size_in_lba * self.block_size
        if size_in_bytes != len(data):
            raise Exception(
                self.tag
                + f"internal: size mismatch, `{size_in_bytes}` vs `{len(data)}`"
            )

        if offset + size_in_bytes > self.disk_size:
            raise Exception(
                self.tag
                + f"requested disk offset: `{offset}` + size: `{size_in_bytes}` is out of range"
            )

        with open(self.disk_path, "r+b") as disk:
            disk.seek(offset)
            disk.write(bytes(data))


class CFImageCreator:
    def __init__(self, disk_path: Path, disk_size: int, recreate: bool = False):
        if recreate is True:
            self.__create_image(disk_path, disk_size)

        self.cf = CompactFlashEmulator(disk_path)
        self.minixfs = MinixFS(self.cf)

        if recreate is True:
            self.minixfs.create()

        self.minixfs.mount()

    @staticmethod
    def __create_image(path: Path, disk_size: int) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)

        if path.exists():
            path.unlink()

        with open(path, "wb") as f:
            f.truncate(disk_size)

def parse_args():
    parser = argparse.ArgumentParser(
        description="Creating CF image with MinixFS for DrunkPC"
    )
    parser.add_argument("-o", "--output_file", help="Output img file", default="disk_minixfs_test.img")
    parser.add_argument("-f", "--force", help="Create image even it already exists", action="store_true", default=False)
    parser.add_argument("--source_dir", help="Recoursive copy specified directory content to image")
    parser.add_argument("-s", "--size", help="Size of image in MB", type=int, default=1)
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    disk_path = Path(args.output_file)
    disk_size = args.size * 1024 * 1024
    c = CFImageCreator(disk_path, disk_size, recreate=args.force)
    c.minixfs.list_directory()
