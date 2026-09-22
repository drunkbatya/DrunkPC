import time

from . import bitmap, dirent, helpers, inode, layout, superblock
from .block_device import BlockDevice

# 352 inodes
# 1024 blocks
# Firstdatazone=15 (15)
# Zonesize=1024
# Maxsize=268966912


class MinixFS:
    BLOCK_SIZE: int = 1024
    ROOT_INODE: int = 1

    DIRECTORY_PERMISSIONS: int = 0o755
    FILE_PERMISSIONS: int = 0o644

    def __init__(self, dev: BlockDevice, timestamp: int | None = None):
        self.dev = dev
        self.tag = f"{self.__class__.__name__} "

        if self.dev.block_size != self.BLOCK_SIZE:
            raise Exception(
                self.tag
                + f"unsupported device block size: `{self.dev.block_size}`, need `{self.BLOCK_SIZE}`"
            )

        # const
        self.block_size = self.BLOCK_SIZE

        self.inode_size = inode.TOTAL_SIZE
        self.timestamp = int(time.time()) if timestamp is None else timestamp

        self.sb: superblock.SuperBlock | None = None
        self.layout: layout.DiskLayout | None = None
        self.inode_bitmap: bitmap.BitMap | None = None
        self.zone_bitmap: bitmap.BitMap | None = None

    def store_superblock(self, sb: superblock.SuperBlock):
        sb_bytes = list(sb.pack())

        superblock_offset_lba = self.layout.superblock_offset // self.block_size
        superblock_size_lba = layout.SUPERBLOCK_BLOCK_COUNT
        self.dev.write(superblock_offset_lba, sb_bytes, superblock_size_lba)

    def create_superblock(self):
        self.store_superblock(self.layout.to_superblock())

    def parse_superblock(self):
        superblock_offset_lba = layout.BOOT_BLOCK_COUNT
        superblock_size_lba = layout.SUPERBLOCK_BLOCK_COUNT
        data = self.dev.read(superblock_offset_lba, superblock_size_lba)

        self.sb = superblock.SuperBlock.load(data)

        if self.sb.s_magic != superblock.SB_MAGIC_LONG_FN:
            raise Exception(
                self.tag
                + f"unsupported filesystem magic: `0x{self.sb.s_magic:04X}` ({self.sb.magic_name()})"
            )

        if self.sb.s_log_zone_size != layout.LOG_ZONE_SIZE:
            raise Exception(
                self.tag
                + f"unsupported zone size shift: `{self.sb.s_log_zone_size}`, need `{layout.LOG_ZONE_SIZE}`"
            )

        self.layout = layout.DiskLayout.from_superblock(self.sb, self.block_size)
        self.layout.validate(self.dev.size_in_blocks)

    def store_inode_bitmap(self, bm: bitmap.BitMap):
        bm_bytes = bm.get_data()
        inode_bitmap_offset_lba = self.layout.imap_offset // self.block_size
        inode_bitmap_size_lba = self.layout.imap_blocks
        self.dev.write(inode_bitmap_offset_lba, bm_bytes, inode_bitmap_size_lba)

    def store_inode_bitmap_bit(self, bit_num: int):
        self.__store_bitmap_block(self.layout.imap_offset, self.inode_bitmap, bit_num)

    def create_inode_bitmap(self):
        bm = bitmap.BitMap.create(
            self.layout.imap_bit_count, self.layout.imap_blocks * self.block_size
        )
        self.store_inode_bitmap(bm)

    def parse_inode_bitmap(self):
        inode_bitmap_offset_lba = self.layout.imap_offset // self.block_size
        inode_bitmap_size_lba = self.layout.imap_blocks
        data = self.dev.read(inode_bitmap_offset_lba, inode_bitmap_size_lba)

        self.inode_bitmap = bitmap.BitMap.load(data)

    def store_zone_bitmap(self, bm: bitmap.BitMap):
        bm_bytes = bm.get_data()
        zone_bitmap_offset_lba = self.layout.zmap_offset // self.block_size
        zone_bitmap_size_lba = self.layout.zmap_blocks
        self.dev.write(zone_bitmap_offset_lba, bm_bytes, zone_bitmap_size_lba)

    def store_zone_bitmap_bit(self, bit_num: int):
        self.__store_bitmap_block(self.layout.zmap_offset, self.zone_bitmap, bit_num)

    def create_zone_bitmap(self):
        bm = bitmap.BitMap.create(
            self.layout.zmap_bit_count, self.layout.zmap_blocks * self.block_size
        )
        self.store_zone_bitmap(bm)

    def parse_zone_bitmap(self):
        zone_bitmap_offset_lba = self.layout.zmap_offset // self.block_size
        zone_bitmap_size_lba = self.layout.zmap_blocks
        data = self.dev.read(zone_bitmap_offset_lba, zone_bitmap_size_lba)

        self.zone_bitmap = bitmap.BitMap.load(data)

    def store_inode(self, i: inode.Inode, pos: int):
        self.__check_inode_num(pos)

        # need to care about reserved 0 inode, but offet statrs with 0 when disk projection
        pos -= 1

        # calc block no and LBA addr where inode located
        inode_size_lba = 1
        inode_offset = self.layout.inodes_offset + (pos * self.inode_size)
        inode_offset_lba = inode_offset // self.block_size
        inode_offset_rem = inode_offset % self.block_size

        # read full disk block
        data = self.dev.read(inode_offset_lba, inode_size_lba)

        # read, modify, write
        i_raw = i.pack()
        data[inode_offset_rem : inode_offset_rem + len(i_raw)] = i_raw

        # storing byte back
        self.dev.write(inode_offset_lba, data, inode_size_lba)

    def load_inode(self, pos: int) -> inode.Inode:
        self.__check_inode_num(pos)

        # need to care about reserved 0 inode, but offet statrs with 0 when disk projection
        pos -= 1

        # calc block no and LBA addr where inode located
        inode_size_lba = 1
        inode_offset = self.layout.inodes_offset + (pos * self.inode_size)
        inode_offset_lba = inode_offset // self.block_size
        inode_offset_rem = inode_offset % self.block_size

        # read full disk block
        data = self.dev.read(inode_offset_lba, inode_size_lba)

        # read
        i_data = data[inode_offset_rem : inode_offset_rem + inode.TOTAL_SIZE]

        return inode.Inode.load(i_data)

    def store_dirent(self, d: dirent.Dirent, dir_inode: inode.Inode, entry_num: int):
        # calc block no and LBA addr where dirent located
        dirent_size_lba = 1
        dirent_offset = entry_num * dirent.TOTAL_SIZE
        dirent_offset_lba = self.zone_for_offset(
            dir_inode, dirent_offset, allocate=True
        )
        dirent_offset_rem = dirent_offset % self.block_size

        # read full disk block
        data = self.dev.read(dirent_offset_lba, dirent_size_lba)

        # read, modify, write
        d_raw = d.pack()
        data[dirent_offset_rem : dirent_offset_rem + len(d_raw)] = d_raw

        # storing byte back
        self.dev.write(dirent_offset_lba, data, dirent_size_lba)

    def load_dirent(self, dir_inode: inode.Inode, entry_num: int) -> dirent.Dirent:
        # calc block no and LBA addr where dirent located
        dirent_size_lba = 1
        dirent_offset = entry_num * dirent.TOTAL_SIZE
        dirent_offset_lba = self.zone_for_offset(
            dir_inode, dirent_offset, allocate=False
        )
        dirent_offset_rem = dirent_offset % self.block_size

        if dirent_offset_lba == 0:
            return dirent.Dirent.empty()

        # read full disk block
        data = self.dev.read(dirent_offset_lba, dirent_size_lba)

        d_data = data[dirent_offset_rem : dirent_offset_rem + dirent.TOTAL_SIZE]
        return dirent.Dirent.load(d_data)

    def allocate_inode(self) -> int:
        free_inode_num = self.inode_bitmap.get_free_bit()
        if free_inode_num is None or free_inode_num > self.layout.inode_count:
            raise Exception(
                self.tag + f"no free inode left of `{self.layout.inode_count}`"
            )

        self.inode_bitmap.acquire_bit(free_inode_num)
        self.store_inode_bitmap_bit(free_inode_num)

        return free_inode_num

    def allocate_zone(self) -> int:
        free_zone_bit = self.zone_bitmap.get_free_bit()
        if free_zone_bit is None:
            raise Exception(
                self.tag + f"no free zone left of `{self.layout.data_zone_count}`"
            )

        zone = self.__zone_from_map_bit(free_zone_bit)
        self.__check_zone_num(zone)

        self.zone_bitmap.acquire_bit(free_zone_bit)
        self.store_zone_bitmap_bit(free_zone_bit)

        self.dev.write(zone, [0x00] * self.block_size, 1)

        return zone

    def zone_for_offset(self, i: inode.Inode, offset: int, allocate: bool) -> int:
        if offset >= self.layout.max_file_size:
            raise Exception(
                self.tag
                + f"offset `{offset}` exceeds max file size `{self.layout.max_file_size}`"
            )

        zone_index = offset // self.block_size
        indirect = self.layout.zones_per_indirect

        if zone_index < inode.DIRECT_ZONE_COUNT:
            return self.__inode_zone_slot(i, zone_index, allocate)

        zone_index -= inode.DIRECT_ZONE_COUNT
        if zone_index < indirect:
            table_zone = self.__inode_zone_slot(i, inode.INDIRECT_ZONE_INDEX, allocate)
            return self.__table_zone_slot(table_zone, zone_index, allocate)

        zone_index -= indirect
        top_table_zone = self.__inode_zone_slot(
            i, inode.DOUBLE_INDIRECT_ZONE_INDEX, allocate
        )
        table_zone = self.__table_zone_slot(
            top_table_zone, zone_index // indirect, allocate
        )
        return self.__table_zone_slot(table_zone, zone_index % indirect, allocate)

    def read_file(self, inode_num: int) -> bytes:
        i = self.load_inode(inode_num)

        file_data = bytearray()
        for offset in range(0, i.i_size, self.block_size):
            chunk_size = min(self.block_size, i.i_size - offset)
            zone = self.zone_for_offset(i, offset, allocate=False)

            if zone == 0:
                file_data += bytes(chunk_size)
                continue

            file_data += bytes(self.dev.read(zone, 1)[:chunk_size])

        return bytes(file_data)

    def write_file(self, inode_num: int, file_data: bytes):
        if len(file_data) > self.layout.max_file_size:
            raise Exception(
                self.tag
                + f"file size `{len(file_data)}` exceeds max file size `{self.layout.max_file_size}`"
            )

        i = self.load_inode(inode_num)

        for offset in range(0, len(file_data), self.block_size):
            zone = self.zone_for_offset(i, offset, allocate=True)
            chunk = list(file_data[offset : offset + self.block_size])
            chunk += [0x00] * (self.block_size - len(chunk))
            self.dev.write(zone, chunk, 1)

        i.i_size = len(file_data)
        self.store_inode(i, inode_num)

    def read_directory(self, inode_num: int) -> list[dirent.Dirent]:
        dir_inode = self.load_inode(inode_num)
        if not dir_inode.is_directory():
            raise Exception(
                self.tag
                + f"inode `{inode_num}` is not a directory, mode `0o{dir_inode.i_mode:o}`"
            )

        entries = []
        for entry_num in range(0, dir_inode.i_size // dirent.TOTAL_SIZE):
            i_dirent = self.load_dirent(dir_inode, entry_num)
            if i_dirent.inode == 0:
                continue

            entries.append(i_dirent)

        return entries

    def add_directory_entry(self, dir_inode_num: int, name: str, entry_inode_num: int):
        self.__check_inode_num(entry_inode_num)

        dir_inode = self.load_inode(dir_inode_num)
        if not dir_inode.is_directory():
            raise Exception(
                self.tag
                + f"inode `{dir_inode_num}` is not a directory, mode `0o{dir_inode.i_mode:o}`"
            )

        entry_num = dir_inode.i_size // dirent.TOTAL_SIZE
        self.store_dirent(
            dirent.Dirent.from_str_name(entry_inode_num, name), dir_inode, entry_num
        )

        dir_inode.i_size += dirent.TOTAL_SIZE
        self.store_inode(dir_inode, dir_inode_num)

    def create_file(self, parent_inode_num: int, name: str, file_data: bytes) -> int:
        file_inode_num = self.allocate_inode()

        i = inode.Inode.create(
            inode.FileType.S_IFREG, self.FILE_PERMISSIONS, self.timestamp
        )
        i.i_nlinks = 1
        self.store_inode(i, file_inode_num)

        self.write_file(file_inode_num, file_data)
        self.add_directory_entry(parent_inode_num, name, file_inode_num)

        return file_inode_num

    def create_directory(self, parent_inode_num: int, name: str) -> int:
        dir_inode_num = self.allocate_inode()

        i = inode.Inode.create(
            inode.FileType.S_IFDIR, self.DIRECTORY_PERMISSIONS, self.timestamp
        )
        self.store_inode(i, dir_inode_num)

        self.add_directory_entry(dir_inode_num, dirent.SELF_NAME, dir_inode_num)
        self.add_directory_entry(dir_inode_num, dirent.PARENT_NAME, parent_inode_num)

        i = self.load_inode(dir_inode_num)
        i.i_nlinks = 2  # for "." and ".."
        self.store_inode(i, dir_inode_num)

        self.add_directory_entry(parent_inode_num, name, dir_inode_num)
        self.__add_inode_link(parent_inode_num)

        return dir_inode_num

    def create_root_directory(self):
        # this will be a inode 1 - root dir
        root_inode_num = self.allocate_inode()
        if root_inode_num != self.ROOT_INODE:
            raise Exception(
                self.tag
                + f"root inode number is `{root_inode_num}`, need `{self.ROOT_INODE}`"
            )

        i = inode.Inode.create(
            inode.FileType.S_IFDIR, self.DIRECTORY_PERMISSIONS, self.timestamp
        )
        self.store_inode(i, root_inode_num)

        self.add_directory_entry(root_inode_num, dirent.SELF_NAME, root_inode_num)
        self.add_directory_entry(root_inode_num, dirent.PARENT_NAME, root_inode_num)

        i = self.load_inode(root_inode_num)
        i.i_nlinks = 2  # for "." and ".."
        self.store_inode(i, root_inode_num)

    def create(self, disk_size: int | None = None):
        if disk_size is None:
            disk_size = self.dev.size_in_blocks * self.block_size

        self.layout = layout.DiskLayout.for_disk_size(disk_size, self.block_size)
        self.layout.validate(self.dev.size_in_blocks)

        self.clear_boot_block()
        self.clear_inode_table()

        self.create_superblock()
        self.parse_superblock()
        self.create_inode_bitmap()
        self.parse_inode_bitmap()
        self.create_zone_bitmap()
        self.parse_zone_bitmap()
        self.create_root_directory()

    def clear_boot_block(self):
        data = self.dev.read(0, layout.BOOT_BLOCK_COUNT)
        data[0 : layout.BOOT_BLOCK_CLEAR_SIZE] = [0x00] * layout.BOOT_BLOCK_CLEAR_SIZE
        self.dev.write(0, data, layout.BOOT_BLOCK_COUNT)

    def clear_inode_table(self):
        inodes_offset_lba = self.layout.inodes_offset // self.block_size
        for block_index in range(0, self.layout.inode_blocks):
            self.dev.write(inodes_offset_lba + block_index, [0x00] * self.block_size, 1)

    def mount(self):
        self.parse_superblock()
        self.parse_inode_bitmap()
        self.parse_zone_bitmap()

    def lookup(self, path: str) -> int | None:
        inode_num = self.ROOT_INODE

        for name in path.split("/"):
            if name == "":
                continue

            entry_inode_num = None
            for i_dirent in self.read_directory(inode_num):
                if i_dirent.get_str_name() == name:
                    entry_inode_num = i_dirent.inode
                    break

            if entry_inode_num is None:
                return None

            inode_num = entry_inode_num

        return inode_num

    def list_directory(self, path: str = "/", recursive: bool = False):
        dir_inode_num = self.lookup(path)
        if dir_inode_num is None:
            raise Exception(self.tag + f"path not found: `{path}`")

        entries = self.read_directory(dir_inode_num)

        print(f"Path: {path}")
        print(f"Total: {len(entries)} entries")
        for i_dirent in entries:
            cur_inode = self.load_inode(i_dirent.inode)
            mode_str = helpers.mode_to_str(cur_inode.i_mode)
            links = cur_inode.i_nlinks
            user_id = cur_inode.i_uid
            group_id = cur_inode.i_gid
            size = cur_inode.i_size
            name = i_dirent.get_str_name()
            print(f"{mode_str}\t{links}\t{user_id}\t{group_id}\t{size}\t{name}")
            # print(i_dirent)
            # print(cur_inode)

        # find root dir inode
        # get size and data blocks
        # go to datablock

        if not recursive:
            return

        for i_dirent in entries:
            name = i_dirent.get_str_name()
            if name in (dirent.SELF_NAME, dirent.PARENT_NAME):
                continue

            if not self.load_inode(i_dirent.inode).is_directory():
                continue

            print()
            self.list_directory(path.rstrip("/") + "/" + name, recursive=True)

    def __check_inode_num(self, pos: int):
        if pos < self.ROOT_INODE or pos > self.layout.inode_count:
            raise Exception(
                self.tag
                + f"inode number `{pos}` is out of range `{self.ROOT_INODE}`..`{self.layout.inode_count}`"
            )

    def __check_zone_num(self, zone: int):
        if zone < self.layout.first_data_zone or zone >= self.layout.zone_count:
            raise Exception(
                self.tag
                + f"zone number `{zone}` is out of range `{self.layout.first_data_zone}`..`{self.layout.zone_count - 1}`"
            )

    def __store_bitmap_block(self, bitmap_offset: int, bm: bitmap.BitMap, bit_num: int):
        bitmap_block = bit_num // self.layout.bits_per_block
        block_offset = bitmap_block * self.block_size
        self.dev.write(
            bitmap_offset // self.block_size + bitmap_block,
            bm.get_data()[block_offset : block_offset + self.block_size],
            1,
        )

    def __zone_from_map_bit(self, map_bit: int) -> int:
        return map_bit + self.layout.first_data_zone - 1

    def __inode_zone_slot(self, i: inode.Inode, slot: int, allocate: bool) -> int:
        zone = i.i_zone[slot]
        if zone == 0 and allocate:
            zone = self.allocate_zone()
            i.i_zone[slot] = zone

        return zone

    def __table_zone_slot(self, table_zone: int, entry: int, allocate: bool) -> int:
        if table_zone == 0:
            return 0

        self.__check_zone_num(table_zone)

        entry_offset = entry * layout.ZONE_ENTRY_SIZE
        data = self.dev.read(table_zone, 1)
        zone = int.from_bytes(
            bytes(data[entry_offset : entry_offset + layout.ZONE_ENTRY_SIZE]), "little"
        )

        if zone == 0 and allocate:
            zone = self.allocate_zone()
            data[entry_offset : entry_offset + layout.ZONE_ENTRY_SIZE] = list(
                zone.to_bytes(layout.ZONE_ENTRY_SIZE, "little")
            )
            self.dev.write(table_zone, data, 1)

        return zone

    def __add_inode_link(self, inode_num: int):
        i = self.load_inode(inode_num)
        if i.i_nlinks >= inode.MAX_LINKS:
            raise Exception(
                self.tag + f"inode `{inode_num}` reached link limit `{inode.MAX_LINKS}`"
            )

        i.i_nlinks += 1
        self.store_inode(i, inode_num)
