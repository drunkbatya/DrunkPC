from .block_device import BlockDevice

# 352 inodes
# 1024 blocks
# Firstdatazone=15 (15)
# Zonesize=1024
# Maxsize=268966912

from . import superblock, bitmap


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

        sb_bytes = list(sb.pack())

        superblock_offset_lba = self.superblock_offset // self.phys_block_size
        superblock_size_lba = self.superblock_size // self.phys_block_size
        self.dev.write(superblock_offset_lba, sb_bytes, superblock_size_lba)


    def parse_superblock(self):
        superblock_offset_lba = self.superblock_offset // self.phys_block_size
        superblock_size_lba = self.superblock_size // self.phys_block_size
        data = self.dev.read(superblock_offset_lba, superblock_size_lba)

        self.sb = superblock.SuperBlock.load(data)

        self.imap_size = self.sb.s_zmap_blocks * self.block_size
        self.zmap_offset = self.imap_offset + self.imap_size
        self.zmap_size = self.sb.s_zmap_blocks * self.block_size
        self.inodes_offset = self.zmap_offset + self.zmap_size

    def create_inode_bitmap(self):
        bm = bitmap.BitMap(self.sb.s_ninodes, self.sb.s_imap_blocks * self.block_size)
        bm_bytes = list(bm.get_bytes())
        inode_bitmap_offset_lba = self.imap_offset // self.phys_block_size
        inode_bitmap_size_lba = (self.sb.s_imap_blocks * self.block_size) // self.phys_block_size
        self.dev.write(inode_bitmap_offset_lba, bm_bytes, inode_bitmap_size_lba)

    def create_znode_bitmap(self):
        bm = bitmap.BitMap(self.sb.s_nzones, self.sb.s_zmap_blocks * self.block_size)
        bm_bytes = list(bm.get_bytes())
        znode_bitmap_offset_lba = self.zmap_offset // self.phys_block_size
        znode_bitmap_size_lba = (self.sb.s_zmap_blocks * self.block_size) // self.phys_block_size
        self.dev.write(znode_bitmap_offset_lba, bm_bytes, znode_bitmap_size_lba)

    def create(self):
        self.create_superblock()
        self.parse_superblock()
        self.create_inode_bitmap()
        self.create_znode_bitmap()

    def mount(self):
        # self.cf.write(0, [0x1, 0x02, 0x03], 3)
        # print(self.cf.read(0, 1))
        pass
