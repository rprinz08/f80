require 'optionparser'
require 'zemu'
require 'colorize'
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


# Process command line arguments.
OptionParser.new do |opts|
	opts.banner = "\nUsage: emulator [options]."

    opts.on("-r", "--rom FILE", "Loads binary file to start of ROM (e.g. monitor or bios") do |file|
        rom.contents(rom.from_binary(file))
    end

	opts.on("-l", "--load FILE", "Loads binary file to start of RAM") do |file|
        puts "\nRAM load file (#{file}) specified.".red
        print "Ensure SKIP_MEMTEST is set to 1 in monitor otherwise RAM is overwritten ".red
        puts "by memory test on emulator start!".red
        ram.contents(ram.from_binary(file))
  	end

end.parse!


# F80 configuration with ROM, RAM test device and serial UART.
conf = Zemu::Config.new do
    name "f80emu"

    add_device rom

    add_device ram

	add_device ticker
	add_device ticker_ms

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

puts "\nStarting F80 emulation. Press CTRL+C to exit ...\n\n"

# Set STDIN to not echo input on Linux.
system('stty raw -echo')

quit = false
ms = 0
last_ms = 0

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
        if uart.transmitted_count() > 0 then
            s = uart.gets()
            print s.green
            $stdout.flush
        end

        # Process serial input.
        k = (STDIN.read_nonblock(1).ord rescue nil)
        if k then
            if k == 3 then # CTRL+C
                quit = true
            else
                if k == 10 then # LF becomes CR
                    k = 13
                end
                uart.put_byte k
            end
        end

        last_ms = ms

    end
rescue Interrupt => ex
end

puts "\nF80 emulation stopped.\n\n"

# Reset STDIN to echo input.
system('stty -raw echo')
puts "\n"

# Close the Z80 emulator instance.
instance.quit

