from .block_device import BlockDevice

# 352 inodes
# 1024 blocks
# Firstdatazone=15 (15)
# Zonesize=1024
# Maxsize=268966912

from . import superblock, bitmap, inode, dirent

from pathlib import Path


class MinixFS:
    def __init__(self, dev: BlockDevice):
        self.dev = dev

        # const
        self.phys_block_size = 512
        self.block_size = 1024

        self.superblock_offset = 1024
        self.superblock_size = self.block_size
        self.imap_offset = self.superblock_offset + self.superblock_size
        self.inode_size = 32

    def store_superblock(self, sb: superblock.SuperBlock):
        sb_bytes = list(sb.pack())

        superblock_offset_lba = self.superblock_offset // self.phys_block_size
        superblock_size_lba = self.superblock_size // self.phys_block_size
        self.dev.write(superblock_offset_lba, sb_bytes, superblock_size_lba)

    def create_superblock(self):
        sb = superblock.SuperBlock(
            s_ninodes=352,
            s_nzones=1024,
            s_imap_blocks=1,
            s_zmap_blocks=1,
            s_firstdatazone=15,
            s_log_zone_size=0,
            s_max_size=268966912,
            s_magic=superblock.SB_MAGIC_LONG_FN,
            s_state=0,
        )
        self.store_superblock(sb)

    def parse_superblock(self):
        superblock_offset_lba = self.superblock_offset // self.phys_block_size
        superblock_size_lba = self.superblock_size // self.phys_block_size
        data = self.dev.read(superblock_offset_lba, superblock_size_lba)

        self.sb = superblock.SuperBlock.load(data)

        self.imap_size = self.sb.s_zmap_blocks * self.block_size
        self.zmap_offset = self.imap_offset + self.imap_size
        self.zmap_size = self.sb.s_zmap_blocks * self.block_size
        self.inodes_offset = self.zmap_offset + self.zmap_size

    def store_inode_bitmap(self, bm: bitmap.BitMap):
        bm_bytes = bm.get_data()
        inode_bitmap_offset_lba = self.imap_offset // self.phys_block_size
        inode_bitmap_size_lba = (
            self.sb.s_imap_blocks * self.block_size
        ) // self.phys_block_size
        self.dev.write(inode_bitmap_offset_lba, bm_bytes, inode_bitmap_size_lba)

    def create_inode_bitmap(self):
        bm = bitmap.BitMap.create(
            self.sb.s_ninodes + 1, self.sb.s_imap_blocks * self.block_size
        )
        self.store_inode_bitmap(bm)

    def parse_inode_bitmap(self):
        inode_bitmap_offset_lba = self.imap_offset // self.phys_block_size
        inode_bitmap_size_lba = (
            self.sb.s_imap_blocks * self.block_size
        ) // self.phys_block_size
        data = self.dev.read(inode_bitmap_offset_lba, inode_bitmap_size_lba)

        self.inode_bitmap = bitmap.BitMap.load(data)

    def store_znode_bitmap(self, bm: bitmap.BitMap):
        bm_bytes = bm.get_data()
        znode_bitmap_offset_lba = self.zmap_offset // self.phys_block_size
        znode_bitmap_size_lba = (
            self.sb.s_zmap_blocks * self.block_size
        ) // self.phys_block_size
        self.dev.write(znode_bitmap_offset_lba, bm_bytes, znode_bitmap_size_lba)

    def create_znode_bitmap(self):
        bm = bitmap.BitMap.create(
            self.sb.s_nzones - 14, self.sb.s_zmap_blocks * self.block_size
        )
        self.store_znode_bitmap(bm)

    def parse_znode_bitmap(self):
        znode_bitmap_offset_lba = self.zmap_offset // self.phys_block_size
        znode_bitmap_size_lba = (
            self.sb.s_zmap_blocks * self.block_size
        ) // self.phys_block_size
        data = self.dev.read(znode_bitmap_offset_lba, znode_bitmap_size_lba)

        self.znode_bitmap = bitmap.BitMap.load(data)

    def store_inode(self, i: inode.Inode, pos: int):
        # calc block no and LBA addr where inode located
        inode_size_lba = 1
        inode_offset = self.inodes_offset + (pos * self.inode_size)
        print(inode_offset)
        inode_offset_lba = inode_offset // self.phys_block_size
        inode_offset_rem = inode_offset % self.phys_block_size

        # read full disk block
        data = self.dev.read(inode_offset_lba, inode_size_lba)

        # read, modify, write
        i_raw = i.pack()
        data[inode_offset_rem : inode_offset_rem + len(i_raw)] = i_raw

        # storing byte back
        self.dev.write(inode_offset_lba, data, inode_size_lba)

    def store_dirent(self, d: dirent.Dirent, dir_num: int, data_block: int):
        # calc block no and LBA addr where dirent located
        dirent_size_lba = 1
        dirent_offset = data_block * self.block_size
        dirent_offset_lba = dirent_offset // self.phys_block_size
        # TODO: fix
        dirent_offset_rem = (dirent_offset % self.phys_block_size) + (
            dir_num * dirent.TOTAL_SIZE
        )

        # read full disk block
        data = self.dev.read(dirent_offset_lba, dirent_size_lba)

        # read, modify, write
        d_raw = d.pack()
        data[dirent_offset_rem : dirent_offset_rem + len(d_raw)] = d_raw

        # storing byte back
        self.dev.write(dirent_offset_lba, data, dirent_size_lba)

    def create_root_directories(self):
        # Reserving inode 0 like original mkfs
        free_inode_num = self.inode_bitmap.get_free_bit()
        self.inode_bitmap.aquire_bit(free_inode_num)

        # this will be a inode 1 - root dir
        free_inode_num = self.inode_bitmap.get_free_bit()
        self.inode_bitmap.aquire_bit(free_inode_num)
        self.store_inode_bitmap(self.inode_bitmap)

        # Reserving inode 0 like original mkfs
        free_znode_num = self.znode_bitmap.get_free_bit()
        self.znode_bitmap.aquire_bit(free_znode_num)

        # this will be a inode 1 - root dir
        free_znode_num = self.znode_bitmap.get_free_bit()
        self.znode_bitmap.aquire_bit(free_znode_num)
        self.store_znode_bitmap(self.znode_bitmap)

        data_block = self.sb.s_firstdatazone

        i = inode.Inode(
            i_mode=int(inode.FileType.S_IFDIR) | 0o755,
            i_uid=0,
            i_size=self.inode_size * 2,  # for "." and ".."
            i_time=0x699F6471,
            i_gid=0,
            i_nlinks=2,  # for "." and ".."
            i_zone=[data_block] + [0 for i in range(0, 8)],
        )
        # need to care about reserved 0 inode, but offet statrs with 0 when disk projection
        self.store_inode(i, free_inode_num - 1)

        d_num = 0
        d = dirent.Dirent.from_str_name(free_inode_num, ".")
        self.store_dirent(d, d_num, data_block)

        d_num = 1
        d = dirent.Dirent.from_str_name(free_inode_num, "..")
        self.store_dirent(d, d_num, data_block)

    def create(self):
        self.create_superblock()
        self.parse_superblock()
        self.create_inode_bitmap()
        self.parse_inode_bitmap()
        self.create_znode_bitmap()
        self.parse_znode_bitmap()
        self.create_root_directories()
        # self.create_directory(Path(".."))
        # self.create_inode()

    def mount(self):
        # self.cf.write(0, [0x1, 0x02, 0x03], 3)
        # print(self.cf.read(0, 1))
        pass
