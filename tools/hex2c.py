#!/usr/bin/env python3

import sys


def readFile(file):
    data = []
    byte = inputFile.read(1).hex()
    while byte:
        data.append(byte)
        byte = inputFile.read(1).hex()
    return data


def printData(data):
    print("uint8_t data[] = { ", end='')
    for index, val in enumerate(data):
        print("0x" + val.upper(), end='')
        if index == (len(data) - 1):
            print(" };")
            break
        print(", ", end='')


if __name__ == '__main__':
    inputFile = open(sys.argv[1], "rb")
    printData(readFile(inputFile))
