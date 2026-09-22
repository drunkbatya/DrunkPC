import struct
from dataclasses import dataclass

SB_MAGIC_SHORT_FN = 0x137F
SB_MAGIC_LONG_FN = 0x138F

SB_MAGIC_NAMES: dict[int, str] = {
    SB_MAGIC_SHORT_FN: "minix v1, 14 char names",
    SB_MAGIC_LONG_FN: "minix v1, 30 char names",
    0x2468: "minix v2, 14 char names",
    0x2478: "minix v2, 30 char names",
    0x4D5A: "minix v3",
}

SB_STATE_VALID_FS = 0x0001
SB_STATE_ERROR_FS = 0x0002

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

TOTAL_SIZE: int = 1024


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

    def pack(self) -> list[int]:
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
        return list(raw) + [0x00] * (TOTAL_SIZE - len(raw))

    @classmethod
    def load(cls, data: list[int]) -> "SuperBlock":
        buf = bytes(data)
        assert len(buf) == TOTAL_SIZE

        fields = SB_STRUCT.unpack_from(buf, 0)
        return cls(*fields)

    def magic_name(self) -> str:
        return SB_MAGIC_NAMES.get(self.s_magic, "unknown")
