import struct
from dataclasses import dataclass
from enum import IntEnum, IntFlag

# B = uint8, H = uint16, L = uint32
D_STRUCT = struct.Struct(
    "<"  # little-endian
    "H"  # inode
    "30B"  # name
)

NAME_SIZE = 30
TOTAL_SIZE = 32


@dataclass
class Dirent:
    inode: int
    name: list[int]

    def pack(self) -> bytes:
        assert isinstance(self.name, list)
        assert len(self.name) <= NAME_SIZE

        raw = D_STRUCT.pack(
            self.inode,
            *self.name,
        )

        assert len(raw) == TOTAL_SIZE

        return raw

    @classmethod
    def load(cls, data: list[int]) -> "Dirent":
        buf = bytes(data)
        assert len(buf) == TOTAL_SIZE

        fields = D_STRUCT.unpack_from(buf, 0)
        return cls(*fields)
