# f80 - Simple Z80 system running on an FPGA

This project creates a simple Z80 based computer using:

* an FPGA development board (e.g. [Digilent Arty](https://digilent.com/shop/arty-a7-artix-7-fpga-development-board/))
* a [Z80 soft-core](https://github.com/hutch31/tv80)
* [Migen](https://github.com/m-labs/migen) hardware description language
* [Small Device C Compiler](http://sdcc.sourceforge.net/)

Z80 CPU documentation can be found in the [doc folder](doc).

![Arty-f80](doc/arty-f80.png)


# Introduction

I started my professional career when 8bit computers emerge. Especially the venerable Z80 (e.g. Sinclair ZX81 or Spectrum). Lately, I wanted to teach my kids some computer basics and remembered how I discovered how things work on my home computers, years ago.

Unfortunately I no longer have any old 8 bit machines laying around and I also did not want to use any of the many available emulators. I thought it would be better they can touch the machine and could directly see when things change like blinking some LEDs.

Sure nowadays this could also easily be done with one of the many boards like Raspberry PI or Arduinos etc. But their internals (e.g. like an ARM CPU) are not that easy for kids and - I wanted to have some fun too. So I decided to implement a simple Z80 system on an FPGA development board.

# Overview

The Digilent Arty-A100 was used as platform but any other FPGA board will work (assuming all needed development tools are available).

## Hardware

f80 runs at 4MHz (allthough it can run much faster - depending on the boards clock - can be changed in `src/gateware/top.py` - search for `cpu_clk_freq_hz`) and uses 64kB memory organized as all RAM. The monitor program starts at address 0x0000. Uploaded programms normally start at 0x8000.

### Peripherals

The Arty provides some LEDs, buttons, switches and a serial interface which are used by the f80 implementation.

Additional peripherals can be added using PMODs. Currently f80 supports the following PMODs:

#### Display

A 7-Segment display for some more output can be added. Either the [Digilent 7-Segment PMOD](https://digilent.com/shop/pmod-ssd-seven-segment-display/) or, if you have some solder skills, an [easy to build alternative](doc/SS7-PMOD.md) can be used. The used PMOD type can be changed in the code (see `src/gateware/top.py` after `Platform ports` comment).

#### Storage

An SD-Card PMOD can be used to provide f80 with mass storage. The [Digilent MicroSD PMOD](https://digilent.com/shop/pmod-microsd-microsd-card-slot/) is supported.

#### Access

Peripherals are accessible through Z80 `in` and `out` instructions using the following I/O ports:

|Port|Direction|Description|
|----|---------|-----------|
|0x00| In      |UART byte received|
|0x00| Out     |UART byte to send|
|0x01| In      |UART status register|
|0x02| Out     |Memory configuration|
|0xa0| Out     |RGB LED 1 red PWM|
|0xa1| Out     |RGB LED 1 green PWM|
|0xa2| Out     |RGB LED 1 blue PWM|
|0xa3| Out     |RGB LED 2 red PWM|
|0xa4| Out     |RGB LED 2 green PWM|
|0xa5| Out     |RGB LED 2 blue PWM|
|0xa6| Out     |RGB LED 3 red PWM|
|0xa7| Out     |RGB LED 3 green PWM|
|0xa8| Out     |RGB LED 3 blue PWM|
|0xa9| Out     |RGB LED 4 red PWM|
|0xaa| Out     |RGB LED 4 green PWM|
|0xab| Out     |RGB LED 4 blue PWM|
|0xf0| In      |Buttons|
|0xf0| Out     |Value to display on 7-Segment display|
|0xf1| In      |Switches|
|0xf1| Out     |LEDs|
|0xf2| Out     |SD-Card I/O control|
|0xf2| In      |SD-Card Status|
|0xf3| Out     |SD-Card SPI MOSI|
|0xf3| In      |SD-Card SPI MISO|
|0xf4| Out     |SD-Card SPI CS|
|0xf5| Out     |SD-Card Clock Divider Low Byte|
|0xf6| Out     |SD-Card Clock Divider High Byte|
|0xf7| Out     |SD-Card TX length|
|0xfd| In      |Millisecond ticks, reset on read|
|0xfe| In      |Millisecond ticks|
|0xff| In      |CPU clock ticks|

The Z80 is implemented in Verilog and the surrounding peripherals are integrated/implemented using [Migen](https://github.com/m-labs/migen).

# Installation

The following instructions get you going, assuming no requirements are installed on your system. If some of the required components are already available then skip the corresponding steps or packages.

```shell
# Install system dependencies (assuming Debian based distro)
$ sudo apt install git curl python3-pip make xxd openocd
# If you prefer 'hexdump' over of 'xxd'...
$ sudo apt install bsdmainutils
```

```shell
# Create project root folder (e.g. projects)
$ mkdir -p projects
$ cd projects
```

```shell
# Install Litex
# See additional infos at:
# https://github.com/enjoy-digital/litex
$ mkdir litex
$ cd litex
$ curl -o litex_setup.py https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
$ chmod +x litex_setup.py
$ ./litex_setup.py init install --user
```

```shell
# Install f80
$ cd ..
$ git clone https://github.com/rprinz08/f80.git
$ cd f80
```

For working with hardware you need, in addition to the above, a toolchain which supports your board/target. This project includes one board/target from Xilinx so to build the FPGA bitstreams yourself you have to install [Xilinx Vivado](https://www.xilinx.com/products/design-tools/vivado.html).

*Note: Prebuilt bitstreams for included target is provided.*

*Note: Depending on your LiteX/Migen version, there might be a bug including external Verilog sources (See [Issue #207](https://github.com/m-labs/migen/issues/207) or [Lines ~240 in src/gateware/top.py](src/gateware/top.py#L240)). To fix this change line `dest = os.path.join(build_dir, path)` to `dest=path` in function `copy_sources` in Migen file `build/generic_platform.py`.*

# Build

## Z80 monitor

Before building the bitstream, the monitor program must be built. It is available in two versions: an assembler and a C version. The C version offers more features like SD-Card support. Run `make` in `src/firmware/asm` or `src/firmware/C` folder. The compiled monitor binary is then included in the bitstream in the next step.

*Note: The assembler monitor was used from the [BSX Project](http://www.breakintoprogram.co.uk/projects/homebrew-z80/z80-monitor-program-for-the-bsx) and was slightly modified for f80.*

To include the monitor in the FPGA bitstream ROM memory open `src/gateware/top.py` and search for `Z80 monitor binary`.*

More infos about the monitor can be found [here](src/firmware/).

## FPGA bitstream

To build the FPGA bitstream, run `build.py` script in project root folder. To upload the bitstream to the board used `upload.py`. This is non permanent so your changes are gone when the board is power-cycled. To make changes permanent use `flash.py`.

## Sample/demo applications

When f80 is running there are some sample/demo applications provided in
the project (see `samples` folder) to play with. They are written in C using the
[Small Device C Compiler](http://sdcc.sourceforge.net/).Documentation for the C compiler macro assembler can be found at:
* https://sdcc.sourceforge.net/doc/sdccman.pdf
* https://github.com/atsidaev/sdcc-z80-gas/tree/master/sdas/doc

To build the C runtime:

```shell
cd src/c-runtime
make
```

After this any sample can be compiled and uploaded to f80 using (e.g. clock sample):

```shell
cd src/samples/clock
make
./upload.sh
```

*Note: The upload script automatically starts the uploaded binary. To avoid this, remove `--run` parameter in the script. Also note that the serial port your board is connected to must be adjusted in the script.*

## BBC Basic

A version of BBC Basic from R.T.Russel, which is now open-source is included in this project. It is based on the BSX version frome [here](http://www.breakintoprogram.co.uk/projects/homebrew-z80/bbc-basic-for-z80-on-the-bsx) and only supports basic console I/O for now. So no possibility to load or store programs at the moment.

## Operating Systems

Included in this project is a port of [Collapse OS](http://collapseos.org/). Collapse OS is a [Forth](https://en.wikipedia.org/wiki/Forth_(programming_language)) system including lots of options (e.g., SD-Card support, Cross Compiler). See the [readme](src/collapse-os/readme.md) for infos on how to install and use it on the f80.

# Using

The system can be controlled using the integrated [monitor program](./src/firmware).

# Emulator

To ease development or to try f80 without a board an [emulator](./src/emulator) is also included.

# ToDo

Some ideas for next additions / improvements:

* additional monitor functions
* implement missing SDCC C-runtime functions
* get [CP-M](https://en.wikipedia.org/wiki/CP/M) running
