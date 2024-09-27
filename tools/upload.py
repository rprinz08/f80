#!/usr/bin/python3

import argparse
import serial
import sys
import time
from colorama import init as color_init, Fore
color_init()

# This utility uploads compiled binaries to Arty-80 using the monitor program
# running on it.

def upload(args):
    addr = args.addr
    data = args.binary.read()
    data_len = len(data)
    data_remaining = 0
    block_size = 16
    block_addr = 0
    block_retries = 5

    # Setup progress bar.
    toolbar_width = 40
    toolbar_clear = " " * toolbar_width
    w = data_len // toolbar_width
    print("\n\nUpload ({}{}{})".format(Fore.CYAN, args.binary.name, Fore.RESET))
    print("to memory location ({}0x{:04X}{})".format(Fore.CYAN, args.addr, Fore.RESET))
    sys.stdout.write("[%s] %d bytes" % (" " * (toolbar_width+1), data_len))
    sys.stdout.write("\r[")
    sys.stdout.flush()

    data_idx = 0
    addr_offset = 0
    data_remaining = data_len
    block_addr = addr

    while(data_remaining > 0 and block_retries > 0):
        block_valid = False
        data_idx += addr_offset
        block_addr += addr_offset

        while(not block_valid and block_retries > 0):
            addr_offset = 0
            cs = 0
            cmd = f"E {block_addr:04X}"
            for i in range(block_size):
                b = data[data_idx+i]
                cs += b
                cmd += f" {b:02X}"
                addr_offset += 1
                if (data_remaining - addr_offset) < 1:
                    break

                if block_retries == 5:
                    if((data_idx+i) % w) == 0:
                        sys.stdout.write("#")
                        sys.stdout.flush()

            data_remaining -= addr_offset

            cs = cs & 0xff

            # print(cmd)
            # print(f"CS: {cs:02x}")

            cmd += "\x0d"
            cmd_bytes = bytes(cmd, encoding="utf8")

            # Send block command line at once.
            args.serial.write(cmd_bytes)
            time.sleep(0.002)

            # Send block command byte by byte.
            # for b in cmd_bytes:
            #     print(f"{b} ", end='')
            #     args.serial.write(b)
            #     time.sleep(0.002)
            # print("\nline done")

            # Try to read back checksum for sent data block.
            read_retries = 5
            l = ""
            while not l.startswith("CS: ") and read_retries > 0:
                #print(args.serial.in_waiting)
                read_retries -= 1
                time.sleep(0.015)
                if args.serial.in_waiting < 1:
                    continue
                l = args.serial.readline().decode("utf-8")

            if read_retries < 1:
                sys.stdout.write(f"\r{Fore.RED}Error: Unable to read from target{Fore.RESET}" +
                                 toolbar_clear + "\n\n")
                return

            if l.startswith("CS: "):
                la = l.split()
                if len(la) < 2:
                    sys.stdout.write(f"\r{Fore.RED}Error: Unable to read checksum "
                                     f"from target{Fore.RESET}" +
                                     toolbar_clear + "\n\n")
                    return
                try:
                    rx_cs = int(la[1], 16)
                    #print(f"calc cs({cs:02X}), rx cs({rx_cs:02X})")
                except Exception as ex:
                    sys.stdout.write(f"\r{Fore.RED}Error: Unable to read valid checksum " +
                                     f"({la[1]}) from target; {ex}{Fore.RESET}" +
                                     toolbar_clear + "\n\n")
                    return

                # Check CS, if wrong repeat last block.
                if cs == rx_cs:
                    block_valid = True
                else:
                    block_valid = False
                    block_retries -= 1
                    if block_retries < 1:
                        sys.stdout.write(f"\r{Fore.RED}Error: Checksum missmatch " +
                                         f"expected({cs:02X}), got({rx_cs:02X}), " +
                                         f"max retries reached; abort{Fore.RESET}" +
                                         toolbar_clear + "\n\n")
                        return

                    sys.stdout.write(f"\r{Fore.RED}Error: Checksum missmatch " +
                                     f"expected({cs:02X}), got({rx_cs:02X}), " +
                                     f"retry block addr({block_addr:04X}){Fore.RESET}" +
                                     toolbar_clear + "\n\n")

    sys.stdout.write("\r\n\n")


def execute(args):
    addr = args.addr

    cmd = "J {:04X}\x0d".format(addr)
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
            baudrate=19200,
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
