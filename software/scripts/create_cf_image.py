#!/usr/bin/env python3

import argparse
from pathlib import Path

from minixfs import BlockDevice, MinixFS


class CompactFlashEmulator(BlockDevice):
    def __init__(self, disk_path: Path, block_size: int = 1024):
        super().__init__()
        self.disk_path = disk_path
        self.tag = f"{self.__class__.__name__} "

        if not self.disk_path.exists() or not self.disk_path.is_file():
            raise Exception(self.tag + f"failed to open path: `{self.disk_path}`")

        self.disk_size = self.disk_path.stat().st_size
        self.disk_block_size = block_size

    @property
    def block_size(self) -> int:
        return self.disk_block_size

    @property
    def size_in_blocks(self) -> int:
        return self.disk_size // self.disk_block_size

    def read(self, block_index: int, block_count: int) -> list[int]:
        offset = block_index * self.block_size
        size_in_bytes = block_count * self.block_size
        if offset + size_in_bytes > self.disk_size:
            raise Exception(
                self.tag
                + f"requested disk offset: `{offset}` + size: `{size_in_bytes}` is out of range"
            )

        with open(self.disk_path, "rb") as disk:
            disk.seek(offset)
            return list(disk.read(size_in_bytes))

    def write(self, block_index: int, data: list[int], block_count: int) -> None:
        offset = block_index * self.block_size
        size_in_bytes = block_count * self.block_size
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
    def __init__(
        self,
        disk_path: Path,
        disk_size: int,
        force: bool = False,
        timestamp: int | None = None,
    ):
        self.tag = f"{self.__class__.__name__} "

        needs_format = force or not disk_path.exists()
        if needs_format:
            self.__create_image(disk_path, disk_size)

        self.cf = CompactFlashEmulator(disk_path)
        self.minixfs = MinixFS(self.cf, timestamp=timestamp)

        if needs_format:
            self.minixfs.create()

        self.minixfs.mount()

    def copy_tree(self, source_dir: Path, dir_inode_num: int) -> None:
        if not source_dir.is_dir():
            raise Exception(self.tag + f"source is not a directory: `{source_dir}`")

        for entry in sorted(source_dir.iterdir()):
            if entry.is_symlink():
                raise Exception(self.tag + f"symlink is not supported: `{entry}`")

            if entry.is_dir():
                entry_inode_num = self.minixfs.create_directory(
                    dir_inode_num, entry.name
                )
                self.copy_tree(entry, entry_inode_num)
            elif entry.is_file():
                self.minixfs.create_file(dir_inode_num, entry.name, entry.read_bytes())
            else:
                raise Exception(self.tag + f"unsupported source entry: `{entry}`")

    def print_layout(self) -> None:
        layout = self.minixfs.layout
        print(f"{layout.inode_count} inodes")
        print(f"{layout.zone_count} blocks")
        print(f"Firstdatazone={layout.first_data_zone} ({layout.first_data_zone})")
        print(f"Zonesize={layout.block_size}")
        print(f"Maxsize={layout.max_file_size}")

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
    parser.add_argument(
        "-o", "--output_file", help="Output img file", default="disk_minixfs_test.img"
    )
    parser.add_argument(
        "-f",
        "--force",
        help="Recreate and format image even if it already exists",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--source_dir", help="Recursive copy specified directory content to image"
    )
    parser.add_argument("-s", "--size", help="Size of image in MB", type=int, default=1)
    parser.add_argument(
        "-t",
        "--timestamp",
        help="Unix time to stamp all inodes with",
        type=int,
        default=None,
    )
    parser.add_argument(
        "-l",
        "--list",
        help="List image content when done",
        action="store_true",
        default=False,
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    disk_path = Path(args.output_file)
    disk_size = args.size * 1024 * 1024
    c = CFImageCreator(disk_path, disk_size, force=args.force, timestamp=args.timestamp)
    c.print_layout()

    if args.source_dir is not None:
        c.copy_tree(Path(args.source_dir), MinixFS.ROOT_INODE)

    if args.list:
        print()
        c.minixfs.list_directory("/", recursive=True)
