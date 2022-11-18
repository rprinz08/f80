#!/usr/bin/python3

import argparse
import serial
import sys

# This utility uploads compiled binaries to Arty-80 using the monitor program
# running on it.

def upload(args):
    addr = args.addr
    data = args.binary.read()
    data_len = len(data)

    cmd = "L{:04X},{:04X}\x0d".format(addr, data_len)
    args.serial.write(bytes(cmd, encoding="utf8"))

    toolbar_width = 40
    w = data_len // toolbar_width
    print("Upload ({})".format(args.binary.name))
    sys.stdout.write("[%s] %d bytes" % (" " * (toolbar_width+1), data_len))
    sys.stdout.flush()
    sys.stdout.write("\r[")

    for i in range(data_len):
        b = data[i].to_bytes(1, "big")
        args.serial.write(b)
        if(i % w) == 0:
            sys.stdout.write("#")
            sys.stdout.flush()

    sys.stdout.write("]\n")


def execute(args):
    addr = args.addr

    cmd = "J{:04X}\x0d".format(addr)
    args.serial.write(bytes(cmd, encoding="utf8"))


def auto_int(v):
    return int(v, 0)


def auto_file(filename):
    try:
        f = open(filename, "rb")
        return f
    except Exception as ex:
        print(ex)
        raise TypeError("Unable to open ({})".format(filename))


def auto_serial(portname):
    try:
        ser = serial.Serial(
            port=portname,
            baudrate=115200,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            bytesize=serial.EIGHTBITS,
            timeout=0
        )
        ser.isOpen()
        return ser
    except Exception as ex:
        print(ex)
        raise TypeError("Unable to open ({})".format(portname))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Upload binaries to Arty-80')
    parser.add_argument('-s', '--serial', default='/dev/ttyUSB0', type=auto_serial)
    parser.add_argument('-a', '--addr', default='0x8000', type=auto_int)
    parser.add_argument('-r', '--run', action='store_true')
    parser.add_argument('binary', type=auto_file)
    args = parser.parse_args()

    upload(args)

    if(args.run):
        execute(args)

    args.binary.close()
    args.serial.close()
