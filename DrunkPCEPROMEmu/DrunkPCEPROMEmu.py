#!/usr/bin/env python3

import argparse
import serial  # pip3 install pyserial

readCmd = b'\x5A'
print(readCmd)


def parse_args():
    parser = argparse.ArgumentParser(description='Configurator for STM32-based DrunkPC Z80 dev-board.')
    parser.add_argument("-b", dest="baudrate", type=str, help="UART baudrate", required=True)
    parser.add_argument("-d", dest="device", type=str, help="UART port", required=True)
    parser.add_argument("-c", dest="command", type=str, choices=["read", "write"], help="Command", required=True)
    return parser.parse_args()


def readData(port):
    port.write(readCmd)
    #port.write(b'hello')
    print(port.read())


def main():
    args = parse_args()
    port = serial.Serial(args.device, args.baudrate)
    if args.command == "read":
        readData(port)


main()
