from abc import ABC, abstractmethod


class BlockDevice(ABC):
    @property
    @abstractmethod
    def block_size(self) -> int: ...

    @property
    @abstractmethod
    def size_in_blocks(self) -> int: ...

    @abstractmethod
    def read(self, block_index: int, block_count: int) -> list[int]: ...

    @abstractmethod
    def write(self, block_index: int, data: list[int], block_count: int) -> None: ...
