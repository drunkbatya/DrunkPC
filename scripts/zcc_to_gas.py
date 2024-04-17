#!/usr/bin/env python3

import argparse
import re


class SCCZ80Converter:
    def __init__(self):
        self.args = self.parse_args()
        self.source_lines = []
        self.dest_lines = []

    def parse_args(self):
        parser = argparse.ArgumentParser()
        parser.add_argument("source")
        parser.add_argument("dest")
        return parser.parse_args()

    def load_source(self):
        with open(self.args.source, "r") as f:
            self.source_lines = f.readlines()

    @staticmethod
    def replace_section(line) -> str | None:
        section_name = re.match(r"\WSECTION\W(\w+)", line).group(1)
        if section_name == "code_compiler":
            section = ".text"
        elif section_name == "rodata_compiler":
            section = ".rodata"
        elif section_name == "bss_compiler":
            section = ".bss"
        elif section_name == "data_compiler":
            section = ".data"
        else:
            return None
        return f".section {section}\n"

    @staticmethod
    def rename_symbol(line):
        parsed_line = re.match(r"^\.(\w+)(?:\W(.+))?", line)
        symbol_name = parsed_line.group(1)
        other_line = parsed_line.group(2)
        if parsed_line is None:
            raise Exception(f"Failed to parse line: {line}")
        if other_line is not None:
            return f"{symbol_name}: {other_line}\n"
        else:
            return f"{symbol_name}:\n"

    @staticmethod
    def fix_a_instruction(line):
        parsed_line = re.match(
            r"(\W+)(xor|cp|sub|add|and|or)[ \t]+([0-9a-zA-Z+\-()]+)(?:(?:,[ \t]*)?([0-9a-zA-Z+\-()]+))?",
            line,
        )
        if parsed_line is None:
            return line
        space = parsed_line.group(1)
        cmd = parsed_line.group(2)
        op1 = parsed_line.group(3)
        op2 = parsed_line.group(4)
        if op2 is not None and op1 == "a":  # 'xor a, ..' is not valid syntax for GAS
            return f"{space}xor {op2}\n"
        else:
            return line

    def convert(self):
        self.load_source()
        for line in self.source_lines:
            if "C_LINE" in line:
                continue
            if "MODULE" in line:
                continue
            if "z80_crt0.hdr" in line:
                continue
            #if line.startswith(";"):
            #    continue
            if "SECTION" in line:
                patched_line = self.replace_section(line)
            else:
                patched_line = line
            #elif line.startswith("."):
            #    patched_line = self.rename_symbol(line)
            #else:
            #    patched_line = self.fix_a_instruction(line)
            if patched_line is None:
                continue
            self.dest_lines.append(patched_line)
        self.write_dest()

    def write_dest(self):
        with open(self.args.dest, "w") as f:
            f.writelines(self.dest_lines)


if __name__ == "__main__":
    con = SCCZ80Converter()
    con.convert()
