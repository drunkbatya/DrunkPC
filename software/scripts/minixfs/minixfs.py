from .block_device import BlockDevice

# 352 inodes
# 1024 blocks
# Firstdatazone=15 (15)
# Zonesize=1024
# Maxsize=268966912

from . import superblock, bitmap, inode, dirent, helpers, path

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
        """Add a new entry to a directory. Allocates a new zone if the next
        slot crosses a block boundary. Updates and stores the directory's
        i_size and inode. Only direct zones (i_zone[0..6]) supported for now."""
        new_offset = dir_inode.i_size
        block_idx = new_offset // self.block_size
        slot_in_block = (new_offset % self.block_size) // dirent.TOTAL_SIZE

        if block_idx >= 7:
            raise NotImplementedError(
                "directory has outgrown direct zones; indirect-zone allocation TODO"
            )

        if dir_inode.i_zone[block_idx] == 0:
            dir_inode.i_zone[block_idx] = self.allocate_zone()

        block_num = dir_inode.i_zone[block_idx]
        d = dirent.Dirent.from_str_name(child_inode_num, name)
        self.store_dirent(d, slot_in_block, block_num)

        dir_inode.i_size += dirent.TOTAL_SIZE
        self.store_inode(dir_inode, dir_inode_num)

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
            i_mode=int(inode.FileType.S_IFDIR) | 0o755,
            i_uid=0,
            i_size=dirent.TOTAL_SIZE * 2,  # for "." and ".."
            i_time=0x699F6471,
            i_gid=0,
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
            mode=int(inode.FileType.S_IFREG) | 0o644,
            nlinks=1,
            zones=[0] * 9,
            child_size=0,
        )

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
            i_uid=0,
            i_size=child_size,
            i_time=0x699F6471,
            i_gid=0,
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

    def mount(self):
        self.parse_superblock()
        self.parse_inode_bitmap()
        self.parse_znode_bitmap()
