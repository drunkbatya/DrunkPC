from .block_device import BlockDevice

# 352 inodes
# 1024 blocks
# Firstdatazone=15 (15)
# Zonesize=1024
# Maxsize=268966912

from . import superblock, bitmap, inode, dirent, helpers, path, defaults

from collections.abc import Iterator
from pathlib import Path


class MinixFS:
    def __init__(self, dev: BlockDevice):
        self.dev = dev

        # const
        self.block_size = 1024

        self.superblock_offset = 1024
        self.superblock_size = self.block_size
        self.imap_offset = self.superblock_offset + self.superblock_size
        self.inode_size = inode.TOTAL_SIZE

    def store_superblock(self, sb: superblock.SuperBlock):
        sb_bytes = list(sb.pack())

        superblock_offset_lba = self.superblock_offset // self.block_size
        superblock_size_lba = self.superblock_size // self.block_size
        self.dev.write(superblock_offset_lba, sb_bytes, superblock_size_lba)

    def create_superblock(self):
        sb = superblock.SuperBlock(
            s_ninodes=352,
            s_nzones=1024,
            s_imap_blocks=1,
            s_zmap_blocks=1,
            s_firstdatazone=15,
            s_log_zone_size=0,
            s_max_size=268966912,
            s_magic=superblock.SB_MAGIC_LONG_FN,
            s_state=0,
        )
        self.store_superblock(sb)

    def parse_superblock(self):
        superblock_offset_lba = self.superblock_offset // self.block_size
        superblock_size_lba = self.superblock_size // self.block_size
        data = self.dev.read(superblock_offset_lba, superblock_size_lba)

        self.sb = superblock.SuperBlock.load(data)

        self.imap_size = self.sb.s_imap_blocks * self.block_size
        self.zmap_offset = self.imap_offset + self.imap_size
        self.zmap_size = self.sb.s_zmap_blocks * self.block_size
        self.inodes_offset = self.zmap_offset + self.zmap_size

    def store_inode_bitmap(self, bm: bitmap.BitMap):
        bm_bytes = bm.get_data()
        inode_bitmap_offset_lba = self.imap_offset // self.block_size
        inode_bitmap_size_lba = (
            self.sb.s_imap_blocks * self.block_size
        ) // self.block_size
        self.dev.write(inode_bitmap_offset_lba, bm_bytes, inode_bitmap_size_lba)

    def create_inode_bitmap(self):
        # i think we need to add one more inode here, because inode 0 is reserved
        # that would explane why mkfs.minix creates +1 here
        bm = bitmap.BitMap.create(
            self.sb.s_ninodes + 1, self.sb.s_imap_blocks * self.block_size
        )
        self.store_inode_bitmap(bm)

    def parse_inode_bitmap(self):
        inode_bitmap_offset_lba = self.imap_offset // self.block_size
        inode_bitmap_size_lba = (
            self.sb.s_imap_blocks * self.block_size
        ) // self.block_size
        data = self.dev.read(inode_bitmap_offset_lba, inode_bitmap_size_lba)

        self.inode_bitmap = bitmap.BitMap.load(data)

    def store_znode_bitmap(self, bm: bitmap.BitMap):
        bm_bytes = bm.get_data()
        znode_bitmap_offset_lba = self.zmap_offset // self.block_size
        znode_bitmap_size_lba = (
            self.sb.s_zmap_blocks * self.block_size
        ) // self.block_size
        self.dev.write(znode_bitmap_offset_lba, bm_bytes, znode_bitmap_size_lba)

    def create_znode_bitmap(self):
        # i don't know why, but mkfs.minix creates layout with s_nzones - 14 number of zones
        # for s_firstdatazone=15, so magic formula is s_firstdatazone - 1..
        bm = bitmap.BitMap.create(
            self.sb.s_nzones - (self.sb.s_firstdatazone - 1),
            self.sb.s_zmap_blocks * self.block_size,
        )
        self.store_znode_bitmap(bm)

    def parse_znode_bitmap(self):
        znode_bitmap_offset_lba = self.zmap_offset // self.block_size
        znode_bitmap_size_lba = (
            self.sb.s_zmap_blocks * self.block_size
        ) // self.block_size
        data = self.dev.read(znode_bitmap_offset_lba, znode_bitmap_size_lba)

        self.znode_bitmap = bitmap.BitMap.load(data)

    def store_inode(self, i: inode.Inode, pos: int):
        # need to care about reserved 0 inode, but offet statrs with 0 when disk projection
        assert pos >= 1
        pos -= 1

        # calc block no and LBA addr where inode located
        inode_size_lba = 1
        inode_offset = self.inodes_offset + (pos * self.inode_size)
        inode_offset_lba = inode_offset // self.block_size
        inode_offset_rem = inode_offset % self.block_size

        # read full disk block
        data = self.dev.read(inode_offset_lba, inode_size_lba)

        # read, modify, write
        i_raw = i.pack()
        data[inode_offset_rem : inode_offset_rem + len(i_raw)] = i_raw

        # storing byte back
        self.dev.write(inode_offset_lba, data, inode_size_lba)

    def load_inode(self, pos: int) -> inode.Inode | None:
        # need to care about reserved 0 inode, but offet statrs with 0 when disk projection
        assert pos >= 1
        pos -= 1

        # calc block no and LBA addr where inode located
        inode_size_lba = 1
        inode_offset = self.inodes_offset + (pos * self.inode_size)
        inode_offset_lba = inode_offset // self.block_size
        inode_offset_rem = inode_offset % self.block_size

        # read full disk block
        data = self.dev.read(inode_offset_lba, inode_size_lba)

        # read
        i_data = data[inode_offset_rem : inode_offset_rem + inode.TOTAL_SIZE]

        return inode.Inode.load(i_data)

    def store_dirent(self, d: dirent.Dirent, dir_num: int, data_block: int):
        # calc block no and LBA addr where dirent located
        dirent_size_lba = 1
        dirent_offset = data_block * self.block_size
        dirent_offset_lba = dirent_offset // self.block_size
        dirent_offset_rem = (dirent_offset % self.block_size) + (
            dir_num * dirent.TOTAL_SIZE
        )

        # read full disk block
        data = self.dev.read(dirent_offset_lba, dirent_size_lba)

        # read, modify, write
        d_raw = d.pack()
        data[dirent_offset_rem : dirent_offset_rem + len(d_raw)] = d_raw

        # storing byte back
        self.dev.write(dirent_offset_lba, data, dirent_size_lba)

    def load_dirent(self, dir_num: int, data_block: int) -> dirent.Dirent | None:
        # calc block no and LBA addr where dirent located
        dirent_size_lba = 1
        dirent_offset = data_block * self.block_size
        dirent_offset_lba = dirent_offset // self.block_size
        dirent_offset_rem = (dirent_offset % self.block_size) + (
            dir_num * dirent.TOTAL_SIZE
        )

        # read full disk block
        data = self.dev.read(dirent_offset_lba, dirent_size_lba)

        d_data = data[dirent_offset_rem : dirent_offset_rem + dirent.TOTAL_SIZE]
        return dirent.Dirent.load(d_data)

    # -- multi-block iteration: direct + indirect + double-indirect -------

    def read_block(self, block_num: int) -> list[int]:
        """Read one filesystem block (1024 bytes) by its zone number."""
        return self.dev.read(block_num, 1)

    def read_indirect_pointers(self, block_num: int) -> list[int]:
        """Parse a block as an array of little-endian 16-bit zone numbers."""
        data = self.read_block(block_num)
        return [data[i] | (data[i + 1] << 8) for i in range(0, self.block_size, 2)]

    def iter_inode_blocks(self, ino: inode.Inode) -> Iterator[int]:
        """Yield every data block of `ino` in file order.
        Walks i_zone[0..6] directly, i_zone[7] as single indirect, and
        i_zone[8] as double indirect. Zero entries are skipped (holes)."""
        for z in ino.i_zone[:7]:
            if z != 0:
                yield z
        if ino.i_zone[7] != 0:
            for z in self.read_indirect_pointers(ino.i_zone[7]):
                if z != 0:
                    yield z
        if ino.i_zone[8] != 0:
            for ind_block in self.read_indirect_pointers(ino.i_zone[8]):
                if ind_block == 0:
                    continue
                for z in self.read_indirect_pointers(ind_block):
                    if z != 0:
                        yield z

    # -- multi-block write: allocate zones on demand -----------------------

    def write_indirect_pointers(
        self, block_num: int, pointers: list[int]
    ) -> None:
        """Pack `pointers` (16-bit little-endian) into a block and write it."""
        data = []
        for p in pointers:
            data.append(p & 0xFF)
            data.append((p >> 8) & 0xFF)
        self.dev.write(block_num, data, 1)

    def ensure_inode_has_block(
        self, ino: inode.Inode, ino_num: int, file_block_idx: int
    ) -> int:
        """Return the physical block backing `file_block_idx` in `ino`.
        Walks direct -> indirect -> double-indirect, allocating any missing
        index or data zones as it goes."""
        ptrs_per_block = self.block_size // 2
        if file_block_idx < 7:
            return self._ensure_direct_zone(ino, ino_num, file_block_idx)
        rel = file_block_idx - 7
        if rel < ptrs_per_block:
            return self._ensure_via_indirect(ino, ino_num, 7, rel)
        rel -= ptrs_per_block
        outer, inner = divmod(rel, ptrs_per_block)
        return self._ensure_via_double_indirect(ino, ino_num, outer, inner)

    def _ensure_direct_zone(
        self, ino: inode.Inode, ino_num: int, zone_idx: int
    ) -> int:
        if ino.i_zone[zone_idx] == 0:
            ino.i_zone[zone_idx] = self.allocate_zone()
            self.store_inode(ino, ino_num)
        return ino.i_zone[zone_idx]

    def _ensure_via_indirect(
        self, ino: inode.Inode, ino_num: int, zone_idx: int, slot: int
    ) -> int:
        if ino.i_zone[zone_idx] == 0:
            ino.i_zone[zone_idx] = self.allocate_zone()
            self.store_inode(ino, ino_num)
        return self._ensure_pointer_slot(ino.i_zone[zone_idx], slot)

    def _ensure_via_double_indirect(
        self, ino: inode.Inode, ino_num: int, outer_slot: int, inner_slot: int
    ) -> int:
        if ino.i_zone[8] == 0:
            ino.i_zone[8] = self.allocate_zone()
            self.store_inode(ino, ino_num)
        indir = self._ensure_pointer_slot(ino.i_zone[8], outer_slot)
        return self._ensure_pointer_slot(indir, inner_slot)

    def _ensure_pointer_slot(self, indir_block: int, slot: int) -> int:
        """Make sure slot `slot` of indirect block `indir_block` holds a real
        zone number, allocating + writing back if it doesn't. Returns the
        zone number."""
        pointers = self.read_indirect_pointers(indir_block)
        if pointers[slot] == 0:
            pointers[slot] = self.allocate_zone()
            self.write_indirect_pointers(indir_block, pointers)
        return pointers[slot]

    # -- directory traversal ----------------------------------------------

    def load_dirents_from_block(self, block_num: int) -> list[dirent.Dirent]:
        """Parse one data block as a sequence of dirents."""
        data = self.read_block(block_num)
        per_block = self.block_size // dirent.TOTAL_SIZE
        return [
            dirent.Dirent.load(
                data[i * dirent.TOTAL_SIZE : (i + 1) * dirent.TOTAL_SIZE]
            )
            for i in range(per_block)
        ]

    def iter_dirents(self, dir_inode: inode.Inode) -> Iterator[dirent.Dirent]:
        """Yield every dirent of `dir_inode`, capped by its i_size so we
        don't return stale entries past the end of the directory."""
        total = dir_inode.i_size // dirent.TOTAL_SIZE
        yielded = 0
        for block_num in self.iter_inode_blocks(dir_inode):
            if yielded >= total:
                return
            for d in self.load_dirents_from_block(block_num):
                if yielded >= total:
                    return
                yield d
                yielded += 1

    def find_dirent(
        self, dir_inode: inode.Inode, name: str
    ) -> dirent.Dirent | None:
        """Return the dirent named `name` in `dir_inode`, or None."""
        for d in self.iter_dirents(dir_inode):
            if d.get_str_name() == name:
                return d
        return None

    # -- inode type predicates --------------------------------------------

    def is_directory(self, ino: inode.Inode) -> bool:
        return (ino.i_mode & 0o170000) == int(inode.FileType.S_IFDIR)

    def is_regular_file(self, ino: inode.Inode) -> bool:
        return (ino.i_mode & 0o170000) == int(inode.FileType.S_IFREG)

    # -- path resolution --------------------------------------------------

    def resolve_path(self, p: str) -> tuple[inode.Inode, int] | None:
        """Walk `p` from the root and return (inode, inode_num).
        Returns None if any path component is missing or non-directory."""
        cur_num = 1  # root inode
        cur_inode = self.load_inode(cur_num)
        for name in path.split(p):
            if not self.is_directory(cur_inode):
                return None
            entry = self.find_dirent(cur_inode, name)
            if entry is None:
                return None
            cur_num = entry.inode
            cur_inode = self.load_inode(cur_num)
        return (cur_inode, cur_num)

    # -- allocation -------------------------------------------------------

    def allocate_inode(self) -> int:
        """Reserve a free inode and return its 1-based number."""
        n = self.inode_bitmap.get_free_bit()
        if n is None:
            raise OSError("no free inodes")
        self.inode_bitmap.aquire_bit(n)
        self.store_inode_bitmap(self.inode_bitmap)
        return n

    def allocate_zone(self) -> int:
        """Reserve a free data zone, zero-fill its block, return block number.
        Zone bitmap bit N maps to block (s_firstdatazone + N - 1)."""
        n = self.znode_bitmap.get_free_bit()
        if n is None:
            raise OSError("no free zones")
        self.znode_bitmap.aquire_bit(n)
        self.store_znode_bitmap(self.znode_bitmap)
        block_num = self.sb.s_firstdatazone + n - 1
        self.dev.write(block_num, [0] * self.block_size, 1)
        return block_num

    def append_dirent(
        self,
        dir_inode: inode.Inode,
        dir_inode_num: int,
        child_inode_num: int,
        name: str,
    ) -> None:
        """Add a new entry to the end of a directory. Allocates a new zone
        (direct or indirect or double-indirect) when the next slot crosses
        a block boundary. Updates and stores the directory's inode."""
        new_offset = dir_inode.i_size
        block_idx = new_offset // self.block_size
        slot_in_block = (new_offset % self.block_size) // dirent.TOTAL_SIZE
        block_num = self.ensure_inode_has_block(dir_inode, dir_inode_num, block_idx)

        d = dirent.Dirent.from_str_name(child_inode_num, name)
        self.store_dirent(d, slot_in_block, block_num)

        dir_inode.i_size += dirent.TOTAL_SIZE
        self.store_inode(dir_inode, dir_inode_num)

    def free_inode(self, ino_num: int) -> None:
        """Release the inode bit. The inode struct on disk is left as-is
        (no consumer reads it without consulting the bitmap first)."""
        self.inode_bitmap.release_bit(ino_num)
        self.store_inode_bitmap(self.inode_bitmap)

    def free_zone(self, block_num: int) -> None:
        """Release a data zone bit. Inverse of allocate_zone."""
        bit = block_num - self.sb.s_firstdatazone + 1
        self.znode_bitmap.release_bit(bit)
        self.store_znode_bitmap(self.znode_bitmap)

    def free_inode_zones(self, ino: inode.Inode, ino_num: int) -> None:
        """Release every data zone of `ino` (including indirect index blocks)
        and zero out i_zone / i_size. Leaves `ino` in a fresh state, ready
        for either deletion or rewrite."""
        for i in range(7):
            if ino.i_zone[i] != 0:
                self.free_zone(ino.i_zone[i])
                ino.i_zone[i] = 0
        if ino.i_zone[7] != 0:
            for z in self.read_indirect_pointers(ino.i_zone[7]):
                if z != 0:
                    self.free_zone(z)
            self.free_zone(ino.i_zone[7])
            ino.i_zone[7] = 0
        if ino.i_zone[8] != 0:
            for ind in self.read_indirect_pointers(ino.i_zone[8]):
                if ind == 0:
                    continue
                for z in self.read_indirect_pointers(ind):
                    if z != 0:
                        self.free_zone(z)
                self.free_zone(ind)
            self.free_zone(ino.i_zone[8])
            ino.i_zone[8] = 0
        ino.i_size = 0
        self.store_inode(ino, ino_num)

    # -- read/write at logical "file block" granularity -------------------

    def get_inode_block_at(self, ino: inode.Inode, file_block_idx: int) -> int:
        """Return the physical block at file-relative index (read-only;
        does NOT allocate). Raises IndexError if past end."""
        for i, block_num in enumerate(self.iter_inode_blocks(ino)):
            if i == file_block_idx:
                return block_num
        raise IndexError(f"file block {file_block_idx} out of range")

    def read_dirent_by_index(
        self, dir_inode: inode.Inode, idx: int
    ) -> dirent.Dirent:
        per_block = self.block_size // dirent.TOTAL_SIZE
        block_num = self.get_inode_block_at(dir_inode, idx // per_block)
        return self.load_dirent(idx % per_block, block_num)

    def write_dirent_by_index(
        self, dir_inode: inode.Inode, idx: int, d: dirent.Dirent
    ) -> None:
        per_block = self.block_size // dirent.TOTAL_SIZE
        block_num = self.get_inode_block_at(dir_inode, idx // per_block)
        self.store_dirent(d, idx % per_block, block_num)

    def remove_dirent(
        self, dir_inode: inode.Inode, dir_inode_num: int, name: str
    ) -> None:
        """Find the dirent `name` in `dir_inode` and remove it by moving the
        last dirent into its slot, then shrinking i_size. If the shrink
        empties the trailing block, that data zone (and any index zones
        that go with it) is released."""
        target_idx = None
        for i, d in enumerate(self.iter_dirents(dir_inode)):
            if d.get_str_name() == name:
                target_idx = i
                break
        if target_idx is None:
            raise FileNotFoundError(name)

        last_idx = (dir_inode.i_size // dirent.TOTAL_SIZE) - 1
        if target_idx != last_idx:
            last = self.read_dirent_by_index(dir_inode, last_idx)
            self.write_dirent_by_index(dir_inode, target_idx, last)

        old_blocks = self._blocks_for_size(dir_inode.i_size)
        dir_inode.i_size -= dirent.TOTAL_SIZE
        new_blocks = self._blocks_for_size(dir_inode.i_size)
        if old_blocks > new_blocks:
            self._release_inode_block(dir_inode, old_blocks - 1)

        self.store_inode(dir_inode, dir_inode_num)

    def _blocks_for_size(self, size_bytes: int) -> int:
        """How many full filesystem blocks `size_bytes` of data occupy."""
        return (size_bytes + self.block_size - 1) // self.block_size

    def _release_inode_block(
        self, ino: inode.Inode, file_block_idx: int
    ) -> None:
        """Free the data zone backing `file_block_idx` and cascade-free any
        index blocks (single or double indirect) that become empty.
        Modifies `ino.i_zone[]` in place; caller stores the inode."""
        ptrs_per_block = self.block_size // 2
        if file_block_idx < 7:
            self._release_direct_zone(ino, file_block_idx)
            return
        rel = file_block_idx - 7
        if rel < ptrs_per_block:
            self._release_via_indirect(ino, 7, rel)
            return
        rel -= ptrs_per_block
        outer, inner = divmod(rel, ptrs_per_block)
        self._release_via_double_indirect(ino, outer, inner)

    def _release_direct_zone(self, ino: inode.Inode, zone_idx: int) -> None:
        if ino.i_zone[zone_idx] != 0:
            self.free_zone(ino.i_zone[zone_idx])
            ino.i_zone[zone_idx] = 0

    def _release_via_indirect(
        self, ino: inode.Inode, zone_idx: int, slot: int
    ) -> None:
        ind = ino.i_zone[zone_idx]
        if ind == 0:
            return
        pointers = self.read_indirect_pointers(ind)
        if pointers[slot] != 0:
            self.free_zone(pointers[slot])
            pointers[slot] = 0
        if all(p == 0 for p in pointers):
            self.free_zone(ind)
            ino.i_zone[zone_idx] = 0
        else:
            self.write_indirect_pointers(ind, pointers)

    def _release_via_double_indirect(
        self, ino: inode.Inode, outer: int, inner: int
    ) -> None:
        dind = ino.i_zone[8]
        if dind == 0:
            return
        outer_ptrs = self.read_indirect_pointers(dind)
        ind = outer_ptrs[outer]
        if ind == 0:
            return
        inner_ptrs = self.read_indirect_pointers(ind)
        if inner_ptrs[inner] != 0:
            self.free_zone(inner_ptrs[inner])
            inner_ptrs[inner] = 0
        if not all(p == 0 for p in inner_ptrs):
            self.write_indirect_pointers(ind, inner_ptrs)
            return
        # Inner indirect is now empty: free it and clear the outer slot.
        self.free_zone(ind)
        outer_ptrs[outer] = 0
        if all(p == 0 for p in outer_ptrs):
            self.free_zone(dind)
            ino.i_zone[8] = 0
        else:
            self.write_indirect_pointers(dind, outer_ptrs)

    def create_root_directories(self):
        # this will be a inode 1 - root dir
        free_inode_num = self.inode_bitmap.get_free_bit()
        self.inode_bitmap.aquire_bit(free_inode_num)
        self.store_inode_bitmap(self.inode_bitmap)

        # this will be a inode 1 - root dir
        free_znode_num = self.znode_bitmap.get_free_bit()
        self.znode_bitmap.aquire_bit(free_znode_num)
        self.store_znode_bitmap(self.znode_bitmap)

        data_block = self.sb.s_firstdatazone

        i = inode.Inode(
            i_mode=int(inode.FileType.S_IFDIR) | defaults.DEFAULT_DIR_MODE,
            i_uid=defaults.DEFAULT_UID,
            i_size=dirent.TOTAL_SIZE * 2,  # for "." and ".."
            i_time=defaults.DEFAULT_TIME,
            i_gid=defaults.DEFAULT_GID,
            i_nlinks=2,  # for "." and ".."
            i_zone=[data_block] + [0 for i in range(0, 8)],
        )
        self.store_inode(i, free_inode_num)

        d_num = 0
        d = dirent.Dirent.from_str_name(free_inode_num, ".")
        self.store_dirent(d, d_num, data_block)

        d_num = 1
        d = dirent.Dirent.from_str_name(free_inode_num, "..")
        self.store_dirent(d, d_num, data_block)

    def create(self):
        self.create_superblock()
        self.parse_superblock()
        self.create_inode_bitmap()
        self.parse_inode_bitmap()
        self.create_znode_bitmap()
        self.parse_znode_bitmap()
        self.create_root_directories()

    # -- public operations ------------------------------------------------

    def list_directory(self, p: str = "/"):
        """Print an ls-like listing of the directory at `p`."""
        res = self.resolve_path(p)
        if res is None:
            raise FileNotFoundError(f"no such path: {p}")
        dir_inode, _ = res
        if not self.is_directory(dir_inode):
            raise NotADirectoryError(f"not a directory: {p}")

        entries = dir_inode.i_size // dirent.TOTAL_SIZE
        print(dir_inode)
        print(f"Path: {p}")
        print(f"Total: {entries} entries")
        for d in self.iter_dirents(dir_inode):
            child = self.load_inode(d.inode)
            mode_str = helpers.mode_to_str(child.i_mode)
            print(
                f"{mode_str}\t{child.i_nlinks}{child.i_uid}\t{child.i_gid}\t"
                f"{child.i_size}\t{d.get_str_name()}"
            )

    def touch(self, p: str) -> int:
        """Create an empty regular file at `p`. Parent directory must exist.
        Returns the new inode number."""
        return self._create_entry(
            p,
            mode=int(inode.FileType.S_IFREG) | defaults.DEFAULT_FILE_MODE,
            nlinks=1,
            zones=[0] * 9,
            child_size=0,
        )

    def unlink(self, p: str) -> None:
        """Remove a regular file at `p`. Errors if `p` is a directory."""
        parent_inode, parent_num, child_inode, child_num = self._resolve_for_remove(p)
        if self.is_directory(child_inode):
            raise IsADirectoryError(f"is a directory: {p}")

        self.free_inode_zones(child_inode, child_num)
        self.free_inode(child_num)
        self.remove_dirent(parent_inode, parent_num, path.basename(p))

    def rmdir(self, p: str) -> None:
        """Remove an empty directory at `p`."""
        if p == "/" or not path.split(p):
            raise ValueError("cannot remove the root directory")

        parent_inode, parent_num, child_inode, child_num = self._resolve_for_remove(p)
        if not self.is_directory(child_inode):
            raise NotADirectoryError(f"not a directory: {p}")
        if child_inode.i_size > dirent.TOTAL_SIZE * 2:
            raise OSError(f"directory not empty: {p}")

        self.free_inode_zones(child_inode, child_num)
        self.free_inode(child_num)
        self.remove_dirent(parent_inode, parent_num, path.basename(p))

        # The removed dir's ".." was a link into the parent.
        parent_inode = self.load_inode(parent_num)
        parent_inode.i_nlinks -= 1
        self.store_inode(parent_inode, parent_num)

    def read_file(self, p: str) -> bytes:
        """Return the full contents of the regular file at `p`."""
        res = self.resolve_path(p)
        if res is None:
            raise FileNotFoundError(p)
        ino, _ = res
        if not self.is_regular_file(ino):
            raise IsADirectoryError(p) if self.is_directory(ino) else PermissionError(p)
        return self._read_inode_bytes(ino)

    def write_file(self, p: str, data: bytes) -> int:
        """Write `data` to `p`, creating the file if missing and truncating
        if present. Returns the file's inode number."""
        if len(data) > self.sb.s_max_size:
            raise OSError(f"file too large: {len(data)} > {self.sb.s_max_size}")

        res = self.resolve_path(p)
        if res is None:
            ino_num = self.touch(p)
            ino = self.load_inode(ino_num)
        else:
            ino, ino_num = res
            if not self.is_regular_file(ino):
                raise IsADirectoryError(p)
            self.free_inode_zones(ino, ino_num)

        self._write_inode_bytes(ino, ino_num, data)
        return ino_num

    def copy_to(self, local_source: Path, minix_dest: str) -> int:
        """Read `local_source` from the host filesystem and store at
        `minix_dest` in the image. Overwrites if it already exists."""
        return self.write_file(minix_dest, local_source.read_bytes())

    def copy_from(self, minix_source: str, local_dest: Path) -> None:
        """Read from the image and write to the host filesystem."""
        local_dest.write_bytes(self.read_file(minix_source))

    def populate_from_directory(
        self, local_root: Path, minix_root: str = "/"
    ) -> None:
        """Recursively mirror the contents of `local_root` into `minix_root`.
        Directories that already exist are reused; symlinks and other special
        files are skipped with a printed warning."""
        if not local_root.is_dir():
            raise NotADirectoryError(local_root)

        for entry in sorted(local_root.iterdir()):
            target = (minix_root.rstrip("/") or "") + "/" + entry.name
            if entry.is_dir() and not entry.is_symlink():
                self.mkdir(target, parent=True)
                self.populate_from_directory(entry, target)
            elif entry.is_file() and not entry.is_symlink():
                self.copy_to(entry, target)
            else:
                print(f"skip (unsupported entry type): {entry}")

    def mkdir(self, p: str, parent: bool = False) -> int:
        """Create directory at `p`. With `parent=True` behaves like
        `mkdir -p`: missing intermediate directories are created and an
        already-existing target is accepted silently (as long as it is a
        directory). Returns the inode number of the final directory."""
        components = path.split(p)
        if not components:
            raise ValueError("cannot mkdir the root directory")

        if not parent:
            return self._mkdir_one(p)

        last_num = 0
        for i in range(len(components)):
            partial = "/" + "/".join(components[: i + 1])
            existing = self.resolve_path(partial)
            if existing is None:
                last_num = self._mkdir_one(partial)
            else:
                ino, num = existing
                if not self.is_directory(ino):
                    raise NotADirectoryError(
                        f"path component is not a directory: {partial}"
                    )
                last_num = num
        return last_num

    # -- internal: file/directory creation --------------------------------

    def _create_entry(
        self,
        p: str,
        mode: int,
        nlinks: int,
        zones: list[int],
        child_size: int,
    ) -> int:
        """Create a fresh inode for `p`, link it under its parent directory,
        and return its inode number. Shared core for touch and mkdir."""
        parent_path = path.parent(p)
        name = path.basename(p)
        if not name:
            raise ValueError(f"invalid path: {p}")

        parent_res = self.resolve_path(parent_path)
        if parent_res is None:
            raise FileNotFoundError(f"parent does not exist: {parent_path}")
        parent_inode, parent_num = parent_res
        if not self.is_directory(parent_inode):
            raise NotADirectoryError(f"parent is not a directory: {parent_path}")
        if self.find_dirent(parent_inode, name) is not None:
            raise FileExistsError(f"already exists: {p}")

        child_num = self.allocate_inode()
        child_inode = inode.Inode(
            i_mode=mode,
            i_uid=defaults.DEFAULT_UID,
            i_size=child_size,
            i_time=defaults.DEFAULT_TIME,
            i_gid=defaults.DEFAULT_GID,
            i_nlinks=nlinks,
            i_zone=zones,
        )
        self.store_inode(child_inode, child_num)
        self.append_dirent(parent_inode, parent_num, child_num, name)
        return child_num

    def _mkdir_one(self, p: str) -> int:
        """Create one directory; parent must already exist."""
        parent_path = path.parent(p)
        parent_res = self.resolve_path(parent_path)
        if parent_res is None:
            raise FileNotFoundError(f"parent does not exist: {parent_path}")
        _, parent_num = parent_res

        # New directory needs its own data zone for "." and ".." dirents.
        data_zone = self.allocate_zone()
        child_num = self._create_entry(
            p,
            mode=int(inode.FileType.S_IFDIR) | 0o755,
            nlinks=2,  # "." and parent's reference
            zones=[data_zone] + [0] * 8,
            child_size=dirent.TOTAL_SIZE * 2,
        )

        # Populate the new directory: "." -> self, ".." -> parent.
        self.store_dirent(dirent.Dirent.from_str_name(child_num, "."), 0, data_zone)
        self.store_dirent(dirent.Dirent.from_str_name(parent_num, ".."), 1, data_zone)

        # Parent gains a link via the new entry's "..".
        parent_inode = self.load_inode(parent_num)
        parent_inode.i_nlinks += 1
        self.store_inode(parent_inode, parent_num)

        return child_num

    # -- internal: resolution / bulk file IO ------------------------------

    def _resolve_for_remove(
        self, p: str
    ) -> tuple[inode.Inode, int, inode.Inode, int]:
        """Resolve `p`'s parent and the entry itself, ready for removal.
        Returns (parent_inode, parent_num, child_inode, child_num)."""
        parent_path = path.parent(p)
        name = path.basename(p)
        if not name:
            raise ValueError(f"invalid path: {p}")

        parent_res = self.resolve_path(parent_path)
        if parent_res is None:
            raise FileNotFoundError(f"parent does not exist: {parent_path}")
        parent_inode, parent_num = parent_res

        entry = self.find_dirent(parent_inode, name)
        if entry is None:
            raise FileNotFoundError(p)
        child_inode = self.load_inode(entry.inode)
        return parent_inode, parent_num, child_inode, entry.inode

    def _read_inode_bytes(self, ino: inode.Inode) -> bytes:
        """Return all data bytes of `ino`, trimmed to i_size."""
        out = bytearray()
        remaining = ino.i_size
        for block_num in self.iter_inode_blocks(ino):
            if remaining <= 0:
                break
            block = self.read_block(block_num)
            take = min(self.block_size, remaining)
            out.extend(block[:take])
            remaining -= take
        return bytes(out)

    def _write_inode_bytes(
        self, ino: inode.Inode, ino_num: int, data: bytes
    ) -> None:
        """Allocate enough zones for `data`, write it, set i_size, store ino.
        Assumes `ino` was already truncated (no leftover zones)."""
        nblocks = (len(data) + self.block_size - 1) // self.block_size
        for i in range(nblocks):
            block_num = self.ensure_inode_has_block(ino, ino_num, i)
            chunk = data[i * self.block_size : (i + 1) * self.block_size]
            if len(chunk) < self.block_size:
                chunk = chunk + b"\x00" * (self.block_size - len(chunk))
            self.dev.write(block_num, list(chunk), 1)
        ino.i_size = len(data)
        self.store_inode(ino, ino_num)

    def mount(self):
        self.parse_superblock()
        self.parse_inode_bitmap()
        self.parse_znode_bitmap()
