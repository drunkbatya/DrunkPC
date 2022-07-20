#!/usr/bin/env python3

import argparse
import serial  # pip3 install pyserial

readCmd = b'\x01'
writeCmd = b'\x02'
eepromSize = 32768


def parse_args():
    parser = argparse.ArgumentParser(description='Configurator for STM32-based DrunkPC Z80 dev-board.')
    parser.add_argument("-b", dest="baudrate", type=str, help="UART baudrate", required=True)
    parser.add_argument("-d", dest="device", type=str, help="UART port", required=True)
    parser.add_argument("-c", dest="command", type=str, choices=["read", "write"], help="Command", required=True)
    return parser.parse_args()


def checkError(port):
    if port.read() == b'\x26':
        print("OK")
    else:
        print("Error!")


def readData(port):
    out = open("out.bin", "wb")
    port.write(readCmd)
    out.write(port.read(eepromSize))
    out.close()
    checkError(port)


def writeData(port):
    inData = bytearray(254)
    port.write(writeCmd)
    port.write(b'\xFE')
    port.write(inData)
    checkError(port)


def main():
    args = parse_args()
    port = serial.Serial(args.device, args.baudrate, timeout=1)
    if args.command == "read":
        readData(port)
    if args.command == "write":
        writeData(port)


main()
