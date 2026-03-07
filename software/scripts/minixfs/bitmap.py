from dataclasses import dataclass


@dataclass
class BitMap:
    data: list[int]

    @classmethod
    def create(cls, bits_count: int, need_size: int) -> "BitMap":
        bits_in_byte = 8
        need_bytes = bits_count // bits_in_byte

        # Bit 0 for both bitmaps are reserved by original mkfs
        data = [0x01]
        data += [0x00] * (need_bytes - 1)

        need_bytes_rem = bits_count % bits_in_byte
        if need_bytes_rem:
            data += [(0xFF << need_bytes_rem) & 0xFF]
            need_bytes += 1

        assert need_bytes <= need_size

        add_bytes = need_size - need_bytes
        if add_bytes != 0:
            data += [0xFF] * add_bytes

        assert len(data) == need_size

        return cls(data=data)

    def get_data(self) -> list[int]:
        return self.data

    def get_free_bit(self) -> int | None:
        bits_in_byte = 8

        assert len(self.data) != 0

        for cur_byte_idx, cur_byte in enumerate(self.data):
            if cur_byte != 0xFF:
                for n_bit in range(0, bits_in_byte):
                    if (cur_byte & (0x01 << n_bit)) == 0:
                        return n_bit + (bits_in_byte * cur_byte_idx)

        return None

    def aquire_bit(self, num: int):
        bits_in_byte = 8
        byte_pos = num // bits_in_byte
        bit_pos = num % bits_in_byte

        self.data[byte_pos] |= 0x01 << bit_pos

    def release_bit(self, num: int):
        bits_in_byte = 8
        byte_pos = num // bits_in_byte
        bit_pos = num % bits_in_byte

        self.data[byte_pos] &= ~(0x01 << bit_pos)

    @classmethod
    def load(cls, data: list[int]) -> "BitMap":
        return cls(data=data)
