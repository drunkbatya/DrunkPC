import struct
from dataclasses import dataclass

SB_MAGIC_LONG_FN = 0x138F

# H = uint16, L = uint32
SB_STRUCT = struct.Struct(
    "<"  # little-endian
    "H"  # s_ninodes
    "H"  # s_nzones
    "H"  # s_imap_blocks
    "H"  # s_zmap_blocks
    "H"  # s_firstdatazone
    "H"  # s_log_zone_size
    "L"  # s_max_size
    "H"  # s_magic
    "H"  # s_state
)


@dataclass
class SuperBlock:
    s_ninodes: int
    s_nzones: int
    s_imap_blocks: int
    s_zmap_blocks: int
    s_firstdatazone: int
    s_log_zone_size: int
    s_max_size: int
    s_magic: int
    s_state: int

    def pack(self) -> bytes:
        total_size = 1024
        raw = SB_STRUCT.pack(
            self.s_ninodes,
            self.s_nzones,
            self.s_imap_blocks,
            self.s_zmap_blocks,
            self.s_firstdatazone,
            self.s_log_zone_size,
            self.s_max_size,
            self.s_magic,
            self.s_state,
        )
        return raw + b"\x00" * (total_size - len(raw))

    @classmethod
    def load(cls, data: list[int]) -> "SuperBlock":
        buf = bytes(data)
        fields = SB_STRUCT.unpack_from(buf, 0)
        return cls(*fields)
