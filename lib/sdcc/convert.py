#!/usr/bin/env python3

import re
import sys

defc_re = re.compile(r"^DEFC\W+(\w+)\W=\W+(\w+)")
defc_re_lower = re.compile(r"^defc\W+(\w+)\W=\W+(\w+)")
filename = sys.argv[1]


def main():
    file = None
    lines = []
    with open(filename, "r") as f:
        file = f.readlines()
    for line in file:
        matched_line = re.match(defc_re, line)
        if not matched_line:
            matched_line = re.match(defc_re_lower, line)
        if matched_line:
            new_sym = matched_line.group(1)
            old_sym = matched_line.group(2)
            patched_line = f"{new_sym}: .equ {old_sym}\n"
        else:
            patched_line = line
        lines.append(patched_line)
    with open(filename, "w") as f:
        f.writelines(lines)

if __name__ == '__main__':
    main()
