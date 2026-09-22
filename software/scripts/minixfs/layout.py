from dataclasses import dataclass

from . import helpers, inode, superblock

BOOT_BLOCK_COUNT: int = 1
BOOT_BLOCK_CLEAR_SIZE: int = 512
SUPERBLOCK_BLOCK_COUNT: int = 1

LOG_ZONE_SIZE: int = 0
ZONE_ENTRY_SIZE: int = 2

BLOCKS_PER_INODE: int = 3

MAX_INODES: int = 0xFFFF
MAX_ZONES: int = 0xFFFF


@dataclass
class DiskLayout:
    block_size: int
    inode_count: int
    zone_count: int
    imap_blocks: int
    zmap_blocks: int
    first_data_zone: int

    @property
    def tag(self) -> str:
        return f"{self.__class__.__name__} "

    @property
    def bits_per_block(self) -> int:
        return self.block_size * 8

    @property
    def inodes_per_block(self) -> int:
        return self.block_size // inode.TOTAL_SIZE

    @property
    def inode_blocks(self) -> int:
        return helpers.round_up_div(self.inode_count, self.inodes_per_block)

    @property
    def zones_per_indirect(self) -> int:
        return self.block_size // ZONE_ENTRY_SIZE

    @property
    def imap_bit_count(self) -> int:
        # i think we need to add one more inode here, because inode 0 is reserved
        # that would explane why mkfs.minix creates +1 here
        return self.inode_count + 1

    @property
    def zmap_bit_count(self) -> int:
        # i don't know why, but mkfs.minix creates layout with s_nzones - 14 number of zones
        # for s_firstdatazone=15, so magic formula is s_firstdatazone - 1..
        return self.zone_count - (self.first_data_zone - 1)

    @property
    def superblock_offset(self) -> int:
        return BOOT_BLOCK_COUNT * self.block_size

    @property
    def imap_offset(self) -> int:
        return self.superblock_offset + SUPERBLOCK_BLOCK_COUNT * self.block_size

    @property
    def zmap_offset(self) -> int:
        return self.imap_offset + self.imap_blocks * self.block_size

    @property
    def inodes_offset(self) -> int:
        return self.zmap_offset + self.zmap_blocks * self.block_size

    @property
    def first_data_offset(self) -> int:
        return self.first_data_zone * self.block_size

    @property
    def data_zone_count(self) -> int:
        return self.zone_count - self.first_data_zone

    @property
    def max_file_size(self) -> int:
        indirect = self.zones_per_indirect
        zones = inode.DIRECT_ZONE_COUNT + indirect + indirect * indirect
        return zones * self.block_size

    @classmethod
    def for_disk_size(cls, disk_size: int, block_size: int) -> "DiskLayout":
        zone_count = min(disk_size // block_size, MAX_ZONES)
        bits_per_block = block_size * 8
        inodes_per_block = block_size // inode.TOTAL_SIZE

        inode_count = helpers.round_up(zone_count // BLOCKS_PER_INODE, inodes_per_block)
        inode_count = min(inode_count, MAX_INODES)

        imap_blocks = helpers.round_up_div(inode_count + 1, bits_per_block)
        inode_blocks = helpers.round_up_div(inode_count, inodes_per_block)

        zmap_blocks, first_data_zone = cls.__fit_zone_map(
            zone_count, imap_blocks, inode_blocks, bits_per_block
        )

        return cls(
            block_size=block_size,
            inode_count=inode_count,
            zone_count=zone_count,
            imap_blocks=imap_blocks,
            zmap_blocks=zmap_blocks,
            first_data_zone=first_data_zone,
        )

    @staticmethod
    def __fit_zone_map(
        zone_count: int, imap_blocks: int, inode_blocks: int, bits_per_block: int
    ) -> tuple[int, int]:
        zmap_blocks = 1
        while True:
            first_data_zone = (
                BOOT_BLOCK_COUNT
                + SUPERBLOCK_BLOCK_COUNT
                + imap_blocks
                + zmap_blocks
                + inode_blocks
            )
            mapped_zones = max(zone_count - (first_data_zone - 1), 1)
            fitted_zmap_blocks = helpers.round_up_div(mapped_zones, bits_per_block)

            if fitted_zmap_blocks <= zmap_blocks:
                return zmap_blocks, first_data_zone

            zmap_blocks = fitted_zmap_blocks

    @classmethod
    def from_superblock(
        cls, sb: superblock.SuperBlock, block_size: int
    ) -> "DiskLayout":
        return cls(
            block_size=block_size,
            inode_count=sb.s_ninodes,
            zone_count=sb.s_nzones,
            imap_blocks=sb.s_imap_blocks,
            zmap_blocks=sb.s_zmap_blocks,
            first_data_zone=sb.s_firstdatazone,
        )

    def to_superblock(self) -> superblock.SuperBlock:
        return superblock.SuperBlock(
            s_ninodes=self.inode_count,
            s_nzones=self.zone_count,
            s_imap_blocks=self.imap_blocks,
            s_zmap_blocks=self.zmap_blocks,
            s_firstdatazone=self.first_data_zone,
            s_log_zone_size=LOG_ZONE_SIZE,
            s_max_size=self.max_file_size,
            s_magic=superblock.SB_MAGIC_LONG_FN,
            s_state=superblock.SB_STATE_VALID_FS,
        )

    def validate(self, device_size_in_blocks: int) -> None:
        if self.inode_count == 0:
            raise Exception(self.tag + "inode count is zero")

        if self.zone_count > device_size_in_blocks:
            raise Exception(
                self.tag
                + f"zone count `{self.zone_count}` exceeds device size `{device_size_in_blocks}` blocks"
            )

        metadata_zones = (
            BOOT_BLOCK_COUNT
            + SUPERBLOCK_BLOCK_COUNT
            + self.imap_blocks
            + self.zmap_blocks
            + self.inode_blocks
        )
        if self.first_data_zone < metadata_zones:
            raise Exception(
                self.tag
                + f"first data zone `{self.first_data_zone}` overlaps metadata of `{metadata_zones}` zones"
            )

        if self.data_zone_count <= 0:
            raise Exception(
                self.tag
                + f"no data zones left: zone count `{self.zone_count}`, first data zone `{self.first_data_zone}`"
            )

        if self.imap_blocks * self.bits_per_block < self.imap_bit_count:
            raise Exception(
                self.tag
                + f"inode bitmap of `{self.imap_blocks}` blocks cannot map `{self.imap_bit_count}` bits"
            )

        if self.zmap_blocks * self.bits_per_block < self.zmap_bit_count:
            raise Exception(
                self.tag
                + f"zone bitmap of `{self.zmap_blocks}` blocks cannot map `{self.zmap_bit_count}` bits"
            )
