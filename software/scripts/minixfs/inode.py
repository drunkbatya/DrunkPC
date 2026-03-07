import struct
from dataclasses import dataclass
from enum import IntEnum, IntFlag


class FileType(IntEnum):
    S_IFSOCK = 0xC000
    S_IFLNK = 0xA000
    S_IFREG = 0x8000
    S_IFBLK = 0x6000
    S_IFDIR = 0x4000
    S_IFCHR = 0x2000
    S_IFIFO = 0x1000


# B = uint8, H = uint16, L = uint32
I_STRUCT = struct.Struct(
    "<"  # little-endian
    "H"  # i_mode
    "H"  # i_uid
    "L"  # i_size
    "L"  # i_time
    "B"  # i_gid
    "B"  # i_nlinks
    "9H"  # i_zone
)

I_ZONE_COUNT: int = 9
TOTAL_SIZE: int = 32


@dataclass
class Inode:
    i_mode: int
    i_uid: int
    i_size: int
    i_time: int
    i_gid: int
    i_nlinks: int
    i_zone: list[int]

    def pack(self) -> list[int]:
        assert isinstance(self.i_zone, list)
        assert len(self.i_zone) == I_ZONE_COUNT

        raw = I_STRUCT.pack(
            self.i_mode,
            self.i_uid,
            self.i_size,
            self.i_time,
            self.i_gid,
            self.i_nlinks,
            *self.i_zone,
        )

        assert len(raw) == TOTAL_SIZE

        return list(raw)

    @classmethod
    def load(cls, data: list[int]) -> "Inode":
        buf = bytes(data)
        assert len(buf) == TOTAL_SIZE

        fields = I_STRUCT.unpack_from(buf, 0)
        return cls(
            i_mode=fields[0],
            i_uid=fields[1],
            i_size=fields[2],
            i_time=fields[3],
            i_gid=fields[4],
            i_nlinks=fields[5],
            i_zone=list(fields[6:]),
        )
