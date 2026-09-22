from dataclasses import dataclass

BITS_IN_BYTE: int = 8


@dataclass
class BitMap:
    data: list[int]

    @classmethod
    def create(cls, bit_count: int, size_in_bytes: int) -> "BitMap":
        mapped_bytes = bit_count // BITS_IN_BYTE
        mapped_bits_rem = bit_count % BITS_IN_BYTE
        used_bytes = mapped_bytes + (1 if mapped_bits_rem else 0)

        if used_bytes > size_in_bytes:
            raise Exception(
                f"BitMap of `{bit_count}` bits needs `{used_bytes}` bytes, got `{size_in_bytes}`"
            )

        data = [0x00] * mapped_bytes
        if mapped_bits_rem:
            data += [(0xFF << mapped_bits_rem) & 0xFF]

        data += [0xFF] * (size_in_bytes - len(data))

        # Bit 0 for both bitmaps are reserved by original mkfs
        data[0] |= 0x01

        assert len(data) == size_in_bytes

        return cls(data=data)

    def get_data(self) -> list[int]:
        return self.data

    def get_free_bit(self) -> int | None:
        assert len(self.data) != 0

        for cur_byte_idx, cur_byte in enumerate(self.data):
            if cur_byte != 0xFF:
                for n_bit in range(0, BITS_IN_BYTE):
                    if (cur_byte & (0x01 << n_bit)) == 0:
                        return n_bit + (BITS_IN_BYTE * cur_byte_idx)

        return None

    def is_bit_set(self, num: int) -> bool:
        byte_pos = num // BITS_IN_BYTE
        bit_pos = num % BITS_IN_BYTE

        return (self.data[byte_pos] & (0x01 << bit_pos)) != 0

    def acquire_bit(self, num: int):
        byte_pos = num // BITS_IN_BYTE
        bit_pos = num % BITS_IN_BYTE

        self.data[byte_pos] |= 0x01 << bit_pos

    def release_bit(self, num: int):
        byte_pos = num // BITS_IN_BYTE
        bit_pos = num % BITS_IN_BYTE

        self.data[byte_pos] &= ~(0x01 << bit_pos) & 0xFF

    @classmethod
    def load(cls, data: list[int]) -> "BitMap":
        return cls(data=data)
