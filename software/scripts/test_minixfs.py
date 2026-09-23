#!/usr/bin/env python3

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from random import Random

from create_cf_image import CFImageCreator, CompactFlashEmulator
from minixfs import DiskLayout, MinixFS, dirent, inode, superblock

BLOCK_SIZE: int = 1024
MEGABYTE: int = 1024 * 1024

FIXED_TIMESTAMP: int = 0x5A5A5A5A

LAYOUT_SIZES: list[int] = [
    1 * MEGABYTE,
    1 * MEGABYTE + 513,
    1234567,
    2 * MEGABYTE,
    3 * MEGABYTE,
    4 * MEGABYTE,
    7 * MEGABYTE,
    16 * MEGABYTE,
    33 * MEGABYTE,
    64 * MEGABYTE,
    100 * MEGABYTE,
]

IMAGE_SIZES: list[int] = [
    4 * MEGABYTE,
    64 * MEGABYTE,
]


def find_tool(name: str) -> str | None:
    path = shutil.which(name)
    if path is not None:
        return path

    for prefix in ("/sbin", "/usr/sbin"):
        candidate = Path(prefix) / name
        if candidate.exists():
            return str(candidate)

    return None


MKFS_MINIX = find_tool("mkfs.minix")
FSCK_MINIX = find_tool("fsck.minix")


def make_dirty_image(path: Path, disk_size: int) -> None:
    path.write_bytes(b"\xff" * disk_size)


def make_reference_image(path: Path, disk_size: int) -> None:
    make_dirty_image(path, disk_size)
    subprocess.run(
        [MKFS_MINIX, "-1", "-n", "30", str(path)],
        check=True,
        capture_output=True,
        stdin=subprocess.DEVNULL,
    )


class MinixImageReader:
    DIRECT_ZONES: int = 7
    INDIRECT_SLOT: int = 7
    DOUBLE_INDIRECT_SLOT: int = 8
    ZONE_ENTRY_SIZE: int = 2

    def __init__(self, image: bytes):
        self.image = image

        sb = superblock.SuperBlock.load(list(self.block(1)))
        self.inodes_offset = (2 + sb.s_imap_blocks + sb.s_zmap_blocks) * BLOCK_SIZE
        self.zones_per_table = BLOCK_SIZE // self.ZONE_ENTRY_SIZE

    def block(self, index: int) -> bytes:
        return self.image[index * BLOCK_SIZE : (index + 1) * BLOCK_SIZE]

    def load_inode(self, num: int) -> inode.Inode:
        offset = self.inodes_offset + (num - 1) * inode.TOTAL_SIZE
        return inode.Inode.load(list(self.image[offset : offset + inode.TOTAL_SIZE]))

    def table_entry(self, table_zone: int, entry: int) -> int:
        offset = entry * self.ZONE_ENTRY_SIZE
        raw = self.block(table_zone)[offset : offset + self.ZONE_ENTRY_SIZE]
        return int.from_bytes(raw, "little")

    def zone_at(self, i: inode.Inode, zone_index: int) -> int:
        if zone_index < self.DIRECT_ZONES:
            return i.i_zone[zone_index]

        zone_index -= self.DIRECT_ZONES
        if zone_index < self.zones_per_table:
            return self.table_entry(i.i_zone[self.INDIRECT_SLOT], zone_index)

        zone_index -= self.zones_per_table
        table_zone = self.table_entry(
            i.i_zone[self.DOUBLE_INDIRECT_SLOT], zone_index // self.zones_per_table
        )
        return self.table_entry(table_zone, zone_index % self.zones_per_table)

    def file_data(self, num: int) -> bytes:
        i = self.load_inode(num)

        file_data = bytearray()
        zone_count = -(-i.i_size // BLOCK_SIZE)
        for zone_index in range(0, zone_count):
            file_data += self.block(self.zone_at(i, zone_index))

        return bytes(file_data[: i.i_size])

    def entries(self, num: int) -> dict[str, int]:
        i = self.load_inode(num)

        found = {}
        for entry_num in range(0, i.i_size // dirent.TOTAL_SIZE):
            offset = entry_num * dirent.TOTAL_SIZE
            zone = self.zone_at(i, offset // BLOCK_SIZE)
            block_offset = offset % BLOCK_SIZE
            raw = self.block(zone)[block_offset : block_offset + dirent.TOTAL_SIZE]

            i_dirent = dirent.Dirent.load(list(raw))
            if i_dirent.inode == 0:
                continue

            found[i_dirent.get_str_name()] = i_dirent.inode

        return found

    def lookup(self, path: str) -> int | None:
        num = MinixFS.ROOT_INODE

        for name in path.split("/"):
            if name == "":
                continue

            entries = self.entries(num)
            if name not in entries:
                return None

            num = entries[name]

        return num


class TestLayoutAgainstMkfs(unittest.TestCase):
    @unittest.skipUnless(MKFS_MINIX, "mkfs.minix is not available")
    def test_superblock_matches_mkfs(self):
        with tempfile.TemporaryDirectory() as work_dir:
            reference_path = Path(work_dir) / "reference.img"

            for disk_size in LAYOUT_SIZES:
                with self.subTest(disk_size=disk_size):
                    make_reference_image(reference_path, disk_size)

                    with open(reference_path, "rb") as image:
                        image.seek(BLOCK_SIZE)
                        reference_superblock = image.read(BLOCK_SIZE)

                    layout = DiskLayout.for_disk_size(disk_size, BLOCK_SIZE)
                    self.assertEqual(
                        bytes(layout.to_superblock().pack()), reference_superblock
                    )


class TestFreshImageAgainstMkfs(unittest.TestCase):
    @unittest.skipUnless(MKFS_MINIX, "mkfs.minix is not available")
    def test_fresh_image_matches_mkfs(self):
        for disk_size in IMAGE_SIZES:
            with self.subTest(disk_size=disk_size):
                self.check_fresh_image(disk_size)

    def check_fresh_image(self, disk_size: int):
        with tempfile.TemporaryDirectory() as work_dir:
            reference_path = Path(work_dir) / "reference.img"
            created_path = Path(work_dir) / "created.img"

            make_reference_image(reference_path, disk_size)

            make_dirty_image(created_path, disk_size)
            minixfs = MinixFS(
                CompactFlashEmulator(created_path), timestamp=FIXED_TIMESTAMP
            )
            minixfs.create()

            reference_image = reference_path.read_bytes()
            created_image = created_path.read_bytes()
            self.assertEqual(len(reference_image), len(created_image))

            root_inode_offset = minixfs.layout.inodes_offset
            root_inode_end = root_inode_offset + inode.TOTAL_SIZE

            self.assertEqual(
                reference_image[:root_inode_offset], created_image[:root_inode_offset]
            )
            self.assertEqual(
                reference_image[root_inode_end:], created_image[root_inode_end:]
            )

            reference_root = inode.Inode.load(
                list(reference_image[root_inode_offset:root_inode_end])
            )
            created_root = inode.Inode.load(
                list(created_image[root_inode_offset:root_inode_end])
            )

            for field in ("i_uid", "i_time", "i_gid"):
                setattr(reference_root, field, 0)
                setattr(created_root, field, 0)

            self.assertEqual(reference_root, created_root)


class TestWrittenTree(unittest.TestCase):
    LONG_NAME = "a" * (dirent.NAME_SIZE - 4) + ".bin"
    MANY_ENTRIES_COUNT = 40

    def test_tree_survives_fsck_and_read_back(self):
        for disk_size in IMAGE_SIZES:
            with self.subTest(disk_size=disk_size):
                self.check_written_tree(disk_size)

    def check_written_tree(self, disk_size: int):
        with tempfile.TemporaryDirectory() as work_dir:
            source_dir = Path(work_dir) / "source"
            source_dir.mkdir()
            image_path = Path(work_dir) / "tree.img"

            layout = DiskLayout.for_disk_size(disk_size, BLOCK_SIZE)
            files = self.build_source_tree(source_dir, layout)

            creator = CFImageCreator(
                image_path, disk_size, force=True, timestamp=FIXED_TIMESTAMP
            )
            creator.copy_tree(source_dir, MinixFS.ROOT_INODE)

            self.assert_double_indirect_spans_tables(creator.minixfs)
            self.assert_directory_spans_zones(creator.minixfs)

            if FSCK_MINIX is not None:
                self.assert_fsck_is_clean(image_path)

            self.assert_bitmap_span(image_path, layout)
            self.assert_reader_sees_tree(image_path, files, layout)

    def test_format_over_dirty_image(self):
        disk_size = 4 * MEGABYTE

        with tempfile.TemporaryDirectory() as work_dir:
            image_path = Path(work_dir) / "dirty.img"
            make_dirty_image(image_path, disk_size)

            minixfs = MinixFS(
                CompactFlashEmulator(image_path), timestamp=FIXED_TIMESTAMP
            )
            minixfs.create()

            random_data = Random(4242)
            files = {
                "indirect.bin": random_data.randbytes(
                    inode.DIRECT_ZONE_COUNT * BLOCK_SIZE + 5
                ),
                "double.bin": random_data.randbytes(
                    self.double_indirect_size(minixfs.layout)
                ),
            }
            for name, file_data in files.items():
                minixfs.create_file(MinixFS.ROOT_INODE, name, file_data)

            if FSCK_MINIX is not None:
                self.assert_fsck_is_clean(image_path)

            reader = MinixImageReader(image_path.read_bytes())
            self.assertEqual(
                set(reader.entries(MinixFS.ROOT_INODE)),
                {".", ".."} | set(files),
            )
            for name, file_data in files.items():
                with self.subTest(name=name):
                    self.assertEqual(
                        reader.file_data(reader.lookup("/" + name)), file_data
                    )

    @staticmethod
    def double_indirect_size(layout: DiskLayout) -> int:
        zones = inode.DIRECT_ZONE_COUNT + 2 * layout.zones_per_indirect + 3
        return zones * BLOCK_SIZE + 777

    @staticmethod
    def spans_zone_bitmap_blocks(layout: DiskLayout) -> bool:
        return (
            layout.zmap_blocks > 1
            and layout.data_zone_count > layout.bits_per_block + 64
        )

    def build_source_tree(
        self, source_dir: Path, layout: DiskLayout
    ) -> dict[str, bytes]:
        random_data = Random(1337)

        files = {
            "hello.txt": b"hello drunkos\n",
            "empty.bin": b"",
            self.LONG_NAME: b"long name\n",
            "indirect.bin": random_data.randbytes(
                inode.DIRECT_ZONE_COUNT * BLOCK_SIZE + 1234
            ),
            "double.bin": random_data.randbytes(self.double_indirect_size(layout)),
            "nested/a/b/deep.txt": b"deep\n",
        }
        for entry_num in range(0, self.MANY_ENTRIES_COUNT):
            files[f"many/file_{entry_num:02d}.txt"] = f"entry {entry_num}\n".encode()

        if self.spans_zone_bitmap_blocks(layout):
            files["bitmap_span.bin"] = random_data.randbytes(
                (layout.bits_per_block + 8) * BLOCK_SIZE
            )

        for name, file_data in files.items():
            file_path = source_dir / name
            file_path.parent.mkdir(parents=True, exist_ok=True)
            file_path.write_bytes(file_data)

        return files

    def assert_double_indirect_spans_tables(self, minixfs: MinixFS):
        indirect_inode = minixfs.load_inode(minixfs.lookup("/indirect.bin"))
        self.assertNotEqual(indirect_inode.i_zone[inode.INDIRECT_ZONE_INDEX], 0)
        self.assertEqual(indirect_inode.i_zone[inode.DOUBLE_INDIRECT_ZONE_INDEX], 0)

        double_inode = minixfs.load_inode(minixfs.lookup("/double.bin"))
        top_table_zone = double_inode.i_zone[inode.DOUBLE_INDIRECT_ZONE_INDEX]
        self.assertNotEqual(top_table_zone, 0)

        top_table = minixfs.dev.read(top_table_zone, 1)
        used_entries = sum(
            1
            for entry in range(0, minixfs.layout.zones_per_indirect)
            if int.from_bytes(bytes(top_table[entry * 2 : entry * 2 + 2]), "little")
            != 0
        )
        self.assertGreater(used_entries, 1)

    def assert_directory_spans_zones(self, minixfs: MinixFS):
        many_inode = minixfs.load_inode(minixfs.lookup("/many"))
        self.assertGreater(many_inode.i_size, BLOCK_SIZE)
        self.assertNotEqual(many_inode.i_zone[1], 0)

    def assert_fsck_is_clean(self, image_path: Path):
        fsck = subprocess.run(
            [FSCK_MINIX, "-f", str(image_path)],
            capture_output=True,
            stdin=subprocess.DEVNULL,
            text=True,
        )
        self.assertEqual(fsck.returncode, 0, msg=f"{fsck.stdout}\n{fsck.stderr}")

    def assert_bitmap_span(self, image_path: Path, layout: DiskLayout):
        if not self.spans_zone_bitmap_blocks(layout):
            return

        minixfs = MinixFS(CompactFlashEmulator(image_path))
        minixfs.mount()
        self.assertTrue(minixfs.zone_bitmap.is_bit_set(layout.bits_per_block))

    def assert_reader_sees_tree(
        self, image_path: Path, files: dict[str, bytes], layout: DiskLayout
    ):
        reader = MinixImageReader(image_path.read_bytes())

        for name, file_data in files.items():
            with self.subTest(name=name):
                inode_num = reader.lookup("/" + name)
                self.assertIsNotNone(inode_num)
                self.assertEqual(reader.file_data(inode_num), file_data)

        expected_root = {
            ".",
            "..",
            "hello.txt",
            "empty.bin",
            self.LONG_NAME,
            "indirect.bin",
            "double.bin",
            "many",
            "nested",
        }
        if self.spans_zone_bitmap_blocks(layout):
            expected_root.add("bitmap_span.bin")

        self.assertEqual(set(reader.entries(MinixFS.ROOT_INODE)), expected_root)
        self.assertEqual(
            len(reader.entries(reader.lookup("/many"))), self.MANY_ENTRIES_COUNT + 2
        )
        self.assertEqual(reader.load_inode(reader.lookup("/nested")).i_nlinks, 3)
        self.assertEqual(reader.lookup("/nested/a/b/.."), reader.lookup("/nested/a"))


if __name__ == "__main__":
    unittest.main()
