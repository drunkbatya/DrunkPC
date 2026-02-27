class BitMap:
    def __init__(self, bits_count: int, need_size: int):
        bits_in_byte = 8

        need_bytes = bits_count // bits_in_byte
        data = (b"\x00" * need_bytes)

        need_bytes_rem = bits_count % bits_in_byte
        if need_bytes_rem:
            data += (0xFF << need_bytes_rem) & 0xFF
            need_bytes += 1

        if need_bytes > need_size:
            raise Exception(f'Need more bytes to create bitmap then size requested')

        add_bytes = need_size - need_bytes
        data += (b"\xFF" * add_bytes)

        assert len(data) == need_size

        self.data = data

    def get_bytes(self) -> bytes:
        return self.data
