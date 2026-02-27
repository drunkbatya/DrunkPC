from abc import ABC, abstractmethod


class BlockDevice(ABC):
    @abstractmethod
    def read(self, lba_addr: int, size_in_lba: int) -> list[int]: ...

    @abstractmethod
    def write(self, lba_addr: int, data: list[int], size_in_lba: int) -> None: ...
