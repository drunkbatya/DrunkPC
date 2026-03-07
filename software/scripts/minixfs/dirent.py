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
TOTAL_SIZE = NAME_SIZE + 2


@dataclass
class Dirent:
    inode: int
    name: list[int]

    @classmethod
    def from_str_name(cls, inode: int, name: str) -> "Dirent":
        name_bytes = name.encode("ascii")
        name_bytes = name_bytes[:NAME_SIZE]
        name_bytes = name_bytes.ljust(NAME_SIZE, b"\x00")
        return cls(inode=inode, name=list(name_bytes))

    def get_str_name(self) -> str:
        b = bytes(self.name)
        b = b.split(b"\x00", 1)[0]
        return b.decode("ascii", errors="replace")

    def __repr__(self) -> str:
        return f"Dirent(inode={self.inode}, name={self.get_str_name()!r})"

    def pack(self) -> list[int]:
        assert isinstance(self.name, list)
        assert len(self.name) <= NAME_SIZE

        raw = D_STRUCT.pack(
            self.inode,
            *self.name,
        )

        assert len(raw) == TOTAL_SIZE

        return list(raw)

    @classmethod
    def load(cls, data: list[int]) -> "Dirent":
        buf = bytes(data)
        assert len(buf) == TOTAL_SIZE

        fields = D_STRUCT.unpack_from(buf, 0)
        return cls(
            inode=fields[0],
            name=list(fields[1:]),
        )
