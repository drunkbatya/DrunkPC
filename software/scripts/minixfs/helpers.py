def mode_to_str(mode: int) -> str:
    ftype = mode & 0o170000
    type_ch = {
        0o040000: "d",  # directory
        0o100000: "-",  # regular
        0o120000: "l",  # symlink
        0o060000: "b",  # block
        0o020000: "c",  # char
        0o010000: "p",  # fifo
        0o140000: "s",  # socket
    }.get(ftype, "?")

    perm = mode & 0o777
    out = []
    for shift in (6, 3, 0):
        bits = (perm >> shift) & 0b111
        out.append("r" if bits & 0b100 else "-")
        out.append("w" if bits & 0b010 else "-")
        out.append("x" if bits & 0b001 else "-")

    s = type_ch + "".join(out)

    if mode & 0o4000:  # setuid affects user x
        s = s[:3] + ("s" if s[3] == "x" else "S") + s[4:]
    if mode & 0o2000:  # setgid affects group x
        s = s[:6] + ("s" if s[6] == "x" else "S") + s[7:]
    if mode & 0o1000:  # sticky affects other x
        s = s[:9] + ("t" if s[9] == "x" else "T")

    return s
