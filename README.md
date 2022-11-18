# F80 - Simple Z80 system running on an FPGA

This project creates a simple Z80 based computer using:

* an FPGA development board (e.g. [Digilent Arty](https://digilent.com/shop/arty-a7-artix-7-fpga-development-board/))
* a [Z80 soft-core](https://github.com/hutch31/tv80)
* [Migen](https://github.com/m-labs/migen) hardware description language
* [Small Device C Compiler](http://sdcc.sourceforge.net/)
* [SJASM+](https://github.com/z00m128/sjasmplus) Z80 Assembler


Z80 CPU documentation can be found in the [doc folder](doc).

# Introduction

I started my career when 8bit computers emerge. especially
the venerable Z80 (e.g. Sinclair ZX81 or spectrum). Late,
I wanted to show my kids some computer basics and remembered
how I discovered how things work on my homecomputer, years
ago.

Unfortunately I no longer have any old 8 bit machines
laying around and I also did not want to use any of the
many available emulators. I thought it would be better they
can touch the machine and could directly see when things
change like blinking some LEDs.

Sure nowadays this could also
easily be done with one of the many boards like RasPIs etc.
But their internals (e.g. like ARM CPU) are not that easy
for kids and - I wanted to have some fun too. So I decided to
implement a simple Z80 system on an FPGA development board.

# Overview

The Digilent Arty-A100 was used as platform but any other FPGA board will work
(assuming all needed development tools are available).

The Arty provides some LEDs, buttons, switches and a serial interface which are
used by the F80 implementation

In addition, a
7-segment display for some more output was added. Either the
[Digilent 7-Segment PMOD](https://digilent.com/shop/pmod-ssd-seven-segment-display/)
or, if you have some solder skills, an
[easy to build alternative](doc/SS7-PMOD.md) can be used. The used type/PMOD can be
changed in the code (see `src/gateware/top` after `Platform ports` comment).

# Installation

The following instructions gets you going, assuming no requirements are
installed on your system. If some of the required components are already
available then skip the corresponding steps or packages.

```shell
# Install system dependencies (assuming Debian based distro)
$ sudo apt install git curl clang python3-pip make xxd libpcap0.8-dev openocd
# If you prefer 'hexdump' over of 'xxd'...
$ sudo apt install bsdmainutils
```

```
# Create project root folder (e.g. projects)
$ mkdir -p projects
$ cd projects
```

```
# Install Litex
# See additional infos at:
# https://github.com/enjoy-digital/litex
$ mkdir litex
$ cd litex
$ curl -o litex_setup.py https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
$ chmod +x litex_setup.py
$ ./litex_setup.py init install --user
```

```
# Install f80
$ cd ..
$ git clone https://github.com/rprinz08/f80.git
$ cd f80
```

For working with hardware you need, in addition to the above, a toolchain which
supports your board/target. This project includes one board/target from Xilinx
so to build the FPGA bitstreams yourself you have to install
[Xilinx Vivado](https://www.xilinx.com/products/design-tools/vivado.html).

*Note: Prebuilt bitstreams for included target is provided.*

# Build

## Z80 monitor

Before building the bitstream, the monitor program must be built. It is written
in Z80 assembler using [SJASM](https://github.com/z00m128/sjasmplus). Run
`build.sh` in `src/firmware.sjasm` folder. The compiled monitor binary is then
included in the bitstream in the next step.

*Note: There is a monitor version available using [Small Device C Compiler](http://sdcc.sourceforge.net/) assembler in `src/firmware` folder. To include this version in the bitstream open `src/gateware/top.py` and search for `Z80 monitor binary`.*

## FPGA bitstream

To build the FPGA bitstream, run `build.py` script in project root folder. To
upload the bitstream to the board used `upload.py`. This is non permanent so
your changes are gone when the board is power-cycled. To make changes permanent
use `flash.py`.

## Sample/demo applications

When F80 is running there are some sample/demo applications provided in
the project (see `samples` folder) to play with. They are written in C using the
[Small Device C Compiler](http://sdcc.sourceforge.net/).
For this to work the C runtime entry must first be built.

```
cd src/c-runtime
make
```

After this any sample can be compiled and uploaded to F80 using (e.g. clock
sample):

```
cd src/samples/clock
make
./upload.sh
```

*Note: the upload script automatically start the uploaded binary. To avoid this,
remove `--run` parameter in the script. Also note that the serial port your
board is connected to must be adjusted in the script.*

# Using

F80 provides a simple monitor program built into the FPGA bitstream. It
allows actions like dumping and loading memory and starting programs at given
addresses.

The monitor is accessible using a serial terminal program on the host with
settings 115200 baud, 8 data bits, no parity and 1 stop bit (115200 8 N 1).

When F80 is powered up, the following output should be shown on the serial
console:

```
BSX Version 0.2
D<addr>,<length>  Dump <length> memory bytes starting at <addr>
L<addr>,<length>  Load <length> memory bytes starting at <addr>
J<addr>           Start execution jumping to memory address <addr>
T                 Memory test RAM
V                 Show version and board ID

All <arguments> in uppercase hex (e.g. D8000,0100)
OK
```

Enter **H** to show some help. The upload function is very simple and uses
direct raw binary data. The utility `tools/upload.py` is used to simplify this.
