# F80 Emulator

The emulator emulates an F80 including ROM, RAM and I/O devices like serial UART or LEDs.

It is available in a simple version `emulator.sh` which only provides ROM, RAM
and serial UART and a more capable version `emulator_ui.sh` showing also 7-segment display
value and LED state.

Serial UART is connected to Linux stdin/stdout.

Input devices like switches or buttons are not implemented at the moment.

The emulator uses [ruby](https://www.ruby-lang.org) and the C based emulator from [redcode/Z80](https://github.com/redcode/Z80) with ruby
bindings from [zemu](https://github.com/jayvalentine/zemu).

## Installation

### Simple emulator

```shell
$ apt install ruby ruby-dev ruby-ffi
$ gem install zemu
$ gem install colorize
```

### Advanced emulator

```shell
$ apt install ruby ruby-dev ruby-ffi
$ gem install zemu
$ gem install curses
```

## Usage

Shell scripts are provided to start the emulators.

Both versions support the same command line options:

### -r file

Load a Z80 binary file into ROM starting at address 0x0000

### -l file

Load a Z80 binary file into RAM starting at address 0x8000

### Simple emulator

```shell
$ emulator.sh
```

### Advanced emulator

```shell
$ emulator-ui.sh
```

### Sample usage

To run the simple emulator with a monitor BIOS in ROM and the compiled `hello` example in RAM:

```shell
ruby emulator.rb \
      -r monitor.bin" \
      -l demo.bin
```

After the emulator has started the monitor BIOS is shown. To start the binary in RAM enter `J8000`.

To directly start the binary in RAM just omit loading the monitor.
