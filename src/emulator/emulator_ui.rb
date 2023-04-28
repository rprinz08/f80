require 'optionparser'
require 'zemu'
require 'curses'
require_relative 'register'
require_relative 'uart'


# Configure F80 ROM.
rom =  Zemu::Config::ROM.new do
    name "rom"
    address 0x0000
    size 0x8000
end


# Configure F80 ram.
ram = Zemu::Config::RAM.new do
    name "ram"
    address 0x8000
    size 0x8000
end


# ticker devices
ticker = Register.new do
	name "ticker"
	io_port 0xff
end
ticker_ms = Register.new do
	name "ticker_ms"
	io_port 0xfe
end


# F80 serial UART.
uart = Uart.new do
	name "uart"
	in_port 0x00
	out_port 0x00
    ready_port 0x01
end


# 7-segment display, LEDs, Buttons and Switches
disp = Register.new do
	name "disp"
	io_port 0xf0
end


# LEDs
leds = Register.new do
    name "leds"
    io_port 0xf1
end


# Prepare curses/screen
Curses.init_screen
Curses.start_color
#Curses.crmode
Curses.cbreak
Curses.noecho
Curses.stdscr.keypad = true
Curses.raw
Curses.nonl
Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_WHITE)
Curses.init_pair(2, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
Curses.init_pair(3, Curses::COLOR_RED, Curses::COLOR_BLACK)
Curses.init_pair(4, Curses::COLOR_WHITE, Curses::COLOR_BLACK)

header = Curses::Window.new(1, Curses.cols, 0, 0)
header.bkgd(Curses.color_pair(1))
header.setpos(0, 0)
header.clear
header.refresh

console = Curses::Window.new(Curses.lines-1, Curses.cols, 1, 0)
console.bkgd(Curses.color_pair(2))
console.scrollok(true)
console.timeout = 0
console.nodelay = true
console.clear
console.refresh


# Process command line arguments.
OptionParser.new do |opts|
	opts.banner = "\nUsage: emulator [options]."

    opts.on("-r", "--rom FILE", "Loads binary file to start of ROM (e.g. monitor or bios") do |file|
        rom.contents(rom.from_binary(file))
    end

	opts.on("-l", "--load FILE", "Loads binary file to start of RAM") do |file|
        console.attrset Curses.color_pair(3)
        console.addstr "\nRAM load file (#{file}) specified.\n"
        console.addstr "Ensure SKIP_MEMTEST is set to 1 in monitor otherwise RAM is overwritten"
        console.addstr "by memory test on emulator start!\n"
        console.attrset Curses.color_pair(2)
        ram.contents(rom.from_binary(file))
  	end

end.parse!


# F80 configuration with ROM, RAM test device and serial UART.
conf = Zemu::Config.new do
    name "f80emu"

    add_device rom

    add_device ram

	add_device ticker
	add_device ticker_ms

	add_device disp
	add_device leds

	add_device uart
end

# Start a new Z80 emulator instance with this configuration.
instance = Zemu.start(conf)

# Program breakpoint.
# Will trigger if the emulator is about to execute an
# instruction at 0x102.
#instance.break 0x102, :program

# Continue. Emulator will run until HALT or until
# the breakpoint (set above) is hit.
#instance.continue

# Continue for 100 cycles.
#instance.continue(100)

# Display the value of the A register (accumulator)
# at the breakpoint.
#puts instance.registers["A"]

# Get value of register device.
#reg_value = instance.device('reg').get_reg_state
#puts reg_value

console.attrset Curses.color_pair(4)
console.addstr "\nStarting F80 emulation. Press CTRL+C to exit ...\n\n"
console.attrset Curses.color_pair(2)

quit = false
ms = 0
last_ms = 0
last_cr = false

begin
    while !quit do

        # Z80 CPU cycles to perform on each turn. Low values are more accurate
        # but slower. Larger values (e.g. 10 or 100) make emulator run faster.
        cycles = 10

        # Tick Z80 for next n cycles.
        instance.continue(cycles)

        # Set cycle ticker value.
        ticker.set_reg_state(ticker.get_reg_state + cycles)

        # Set millisecond ticker value.
        ms = (Time.now().to_f * 1000).to_i
        if last_ms <= 0 then
            last_ms = ms
        end
        ms_diff = ms - last_ms
        ticker_ms.set_reg_state(ticker_ms.get_reg_state + ms_diff)

        # Process serial output.
        while uart.transmitted_count() > 0 do
            char = uart.get_byte

            # Handle CR/LF explicitely. Unfortunately, curses clears a screen
            # line after adding a CR to window
            # According to: https://linux.die.net/man/3/addch
            # ... Newline does a clrtoeol(), then moves the cursor to the
            # window left margin on the next line, scrolling the window if on
            # the last line). ...
            # So, if a CR is followed by not LF just output CR an char. If CR
            # is followed by LF just output LF.
            if last_cr then
                if char != 10 then
                    console.addch 13
                end
                console.addch char
                last_cr = false
            else
                if char == 13 then
                    last_cr = true
                else
                    console.addch char
                end
            end

            console.refresh
        end

        # Process serial input.
        key = console.getch
        if key then
            key = key.ord
            if key == 3 then # CTRL+C
                quit = true
            else
                if key == 10 then # LF becomes CR
                    uart.put_byte key
                    key = 13
                end
                uart.put_byte key
            end
        end

        # Update 7-segment display, LEDS etc.
        d = disp.get_reg_state
        l = leds.get_reg_state

        # Update header.
        header.setpos(0, 0)
        header.addstr("I/O: Disp7 (0x%02X), LED1 (%d), LED2 (%d), LED3 (%d), LED4 (%d)" %
                      [d, (l & 0x01), (l & 0x02)>>1, (l & 0x04)>>2, (l & 0x08)>>3])
        header.refresh

        # Update millisecond ticker
        last_ms = ms

    end
rescue Interrupt => ex
end

console.attrset Curses.color_pair(4)
console.addstr("\nF80 emulation stopped.\n\n")
console.attrset Curses.color_pair(2)

# Close the Z80 emulator instance.
instance.quit

Curses.close_screen

