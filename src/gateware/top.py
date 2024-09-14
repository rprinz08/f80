import sys
sys.path.insert(0, 'src')

from os import path, stat
from pprint import pprint

from migen import *
from migen.genlib.fifo import AsyncFIFO
from migen.genlib.cdc import PulseSynchronizer
from migen.build.generic_platform import *
from clock import *
from gateware.display.display import *
from gateware.uart.uart import *
from pwm import PWM
from litex.soc.cores.spi import SPIMaster


def platform_request_all(platform, name):
    r = []
    while True:
        try:
            r += [platform.request(name, len(r))]
        except ConstraintError:
            break
    if r == []:
        raise ValueError
    return r


class Top(Module):
    def __init__(self, platform, sys_clk_freq_hz=int(100e6), **kwargs):

        # ----------------------------------------------------------------------
        # Platform ports

        # Connect platform connectors to extensions.
        # Some pins on the ChipKit connector are used for debugging purposes.
        platform.add_extension([
            ("debug_0", 0, Pins("ck_io:ck_io0"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_1", 0, Pins("ck_io:ck_io1"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_2", 0, Pins("ck_io:ck_io2"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_3", 0, Pins("ck_io:ck_io3"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_4", 0, Pins("ck_io:ck_io4"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_5", 0, Pins("ck_io:ck_io5"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_6", 0, Pins("ck_io:ck_io6"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
            ("debug_7", 0, Pins("ck_io:ck_io7"), IOStandard("LVCMOS33"), Misc("PULLUP False")),
        ])

        # 7-Segment display PMOD
        platform.add_extension([
            # For self built 7Segment display PMOD
            # see doc/SS7-PMOD.md for details
            # ("debug_disp", 0, Pins("""
            #     pmoda:0 pmoda:1 pmoda:2 pmoda:3
            #     pmoda:4 pmoda:5 pmoda:6 pmoda:7
            #     """), IOStandard("LVCMOS33")),

            # For Digilent 7Segment display PMOD
            # see (https://digilent.com/shop/pmod-ssd-seven-segment-display/)
            # which uses PMODA and PMODB
            ("debug_disp", 0, Pins("""
                pmoda:0 pmoda:1 pmoda:2 pmoda:3
                pmodb:0 pmodb:1 pmodb:2 pmodb:3
                """), IOStandard("LVCMOS33"))
        ])

        # SDCard PMOD:
        # - https://store.digilentinc.com/pmod-microsd-microsd-card-slot/
        platform.add_extension([
            ("spisdcard", 0,
                Subsignal("clk",  Pins("pmodc:3")),
                Subsignal("mosi", Pins("pmodc:1"), Misc("PULLUP True")),
                Subsignal("cs_n", Pins("pmodc:0"), Misc("PULLUP True")),
                Subsignal("miso", Pins("pmodc:2"), Misc("PULLUP True")),
                Misc("SLEW=FAST"),
                IOStandard("LVCMOS33"),
            )
        ])

        # Request ports from platform.
        self.sys_clk = sys_clk = platform.request(platform.default_clk_name)
        self.sys_hw_reset_n = sys_hw_reset_n = platform.request("cpu_reset")

        self.leds = leds = platform_request_all(platform, "user_led")
        self.rgb_led1 = rgb_led1 = platform.request("rgb_led", 0)
        self.rgb_led2 = rgb_led2 = platform.request("rgb_led", 1)
        self.rgb_led3 = rgb_led3 = platform.request("rgb_led", 2)
        self.rgb_led4 = rgb_led4 = platform.request("rgb_led", 3)
        self.serial = serial = platform.request("serial")

        self.buttons = buttons = platform_request_all(platform, "user_btn")
        self.switches = switches = platform_request_all(platform, "user_sw")

        self.debug_0 = debug_0 = platform.request("debug_0")
        self.debug_1 = debug_1 = platform.request("debug_1")
        self.debug_2 = debug_2 = platform.request("debug_2")
        self.debug_3 = debug_3 = platform.request("debug_3")
        self.debug_4 = debug_4 = platform.request("debug_4")
        self.debug_5 = debug_5 = platform.request("debug_5")
        self.debug_6 = debug_6 = platform.request("debug_6")
        self.debug_7 = debug_7 = platform.request("debug_7")

        self.debug_disp = debug_disp = platform.request("debug_disp")

        spi_sdcard_pads = platform.request("spisdcard")


        # ----------------------------------------------------------------------
        # Clocks and clock domains

        # As we have multiple clock domains, create a default sys clock domain
        # manually here. Migen does only automatically add a default sys
        # clock domain if no other clock domains are created.
        self.submodules.crg = CRG(sys_clk)

        # Power on reset.
        reset_delay = Signal(10, reset=1023)
        sys_reset_n = Signal()
        self.comb += sys_reset_n.eq(reset_delay == 0)
        self.sync += \
            If(reset_delay != 0,
                reset_delay.eq(reset_delay - 1)
            )

        # Create CPU clock and clock domain.
        cpu_clk_freq_hz = 8_000_000
        self.submodules.cpu_clk = Clock(sys_clk_freq_hz, cpu_clk_freq_hz)
        self.clock_domains.cpu = ClockDomain(reset_less=True)
        self.comb += self.cpu.clk.eq(self.cpu_clk.clk_out)

        # Millisecond ticker clock domain.
        self.submodules.ms_clk = Clock(sys_clk_freq_hz, 1000)
        self.clock_domains.ms = ClockDomain(reset_less=True)
        self.comb += self.ms.clk.eq(self.ms_clk.clk_out)


        # ----------------------------------------------------------------------
        # Signals

        cpu_din = Signal(8, reset=0)
        cpu_dout = Signal(8)
        cpu_reset_n = Signal(reset=0)
        addr = Signal(16)

        m1_n = Signal()     # M1 is active whenever the Z80 is reading an opcode
        rfsh_n = Signal()
        halt_n = Signal()
        mreq_n = Signal()   # active whenever the Z80 is accessing memory, either reading or writing
        iorq_n = Signal()   # active when the processor is accessing input or output devices
        rd_n = Signal()     # active whenever the Z80 is reading data
        wr_n = Signal()     # active whenever the Z80 is writing data
        wait_n = Signal(reset=1)
        int_n = Signal()
        nmi_n = Signal()
        busrq_n = Signal()

        m_re = Signal()     # memory read data
        m_we = Signal()     # memory write data
        io_re = Signal()    # io read data
        io_we = Signal()    # io write data

        counter = Signal(26)
        tick = Signal()
        ticks = Signal(8)
        ticks_ms = Signal(8)
        #ticks_ms_read_reset = Signal(8, reset=1)
        counter_changed = Signal()

        uart_tx_pend = Signal(reset=0)
        uart_status = Signal(8)
        mem_config = Signal(8)

        mrdws = Signal(2, reset=0)
        mwrws = Signal(2, reset=0)

        iordws = Signal(2, reset=0)
        iowrws = Signal(2, reset=0)
        io_addr = Signal(8, reset=0)

        sd_card_clk_divider = Signal(16, reset=0)


        # ----------------------------------------------------------------------
        # Submodules

        # ----------------------------------------
        # Serial port
        self.submodules.uart = Uart(serial, clk_freq_hz=sys_clk_freq_hz, baud_rate=19200)

        # Uart TX/RX FIFOs
        uart_tx_fifo = AsyncFIFO(8, 64)
        uart_tx_fifo = ClockDomainsRenamer({"read": "sys", "write": "cpu"})(uart_tx_fifo)
        self.submodules.uart_tx_fifo = uart_tx_fifo

        uart_rx_fifo = AsyncFIFO(8, 64)
        uart_rx_fifo = ClockDomainsRenamer({"read": "cpu", "write": "sys"})(uart_rx_fifo)
        self.submodules.uart_rx_fifo = uart_rx_fifo

        # ----------------------------------------
        # 7segment LED display
        self.submodules.disp = disp = Disp7(REFRESH_CLK_HZ=500, NUM_DIGITS=2,
                                            BCD_MODE=False, FLIP=True)

        # SPI SD-Card ---------------------------------------------------------
        self.submodules.spi_sdcard = spi_sdcard = SPIMaster(
            pads         = spi_sdcard_pads,
            data_width   = 8,
            sys_clk_freq = sys_clk_freq_hz,
            spi_clk_freq = 400e3,
            with_csr     = False,
            mode         = "raw"
        )
        self.submodules.sd_start = sd_start = PulseSynchronizer("cpu", "sys")

        # ----------------------------------------
        # One PWM per RGB LED color (4 RGB LEDs * a 3 colors each)
        period = 65280   # 652.8 us
        width = period // 2  # 326.4 us

        for i in range(1, 5):
            for c in ["r", "g", "b"]:
                pwm = f"pwm_rgb{i}_{c}"
                setattr(self.submodules, pwm, PWM(default_enable=0,
                    default_width=width, default_period=period))

        # ----------------------------------------

        # Bank0: 0x0000 - 0x7fff ROM
        #        0x8000 - 0xffff RAM
        # Bank1: 0x0000 - 0xffff RAM

        # Memory bank 0 (32k ROM, 32k RAM)
        # Initialize ROM memory from file containing Z80 monitor binary.
        rom_init_file = path.join(path.abspath(os.path.dirname(__file__)),
            "..", "firmware", "c", "monitor.bin")
        with open(rom_init_file, "rb") as f:
            rom_init = f.read()
        rom_size = 0x7fff
        self.specials.rom = Memory(8, rom_size, init=rom_init)
        self.specials.rom_r = self.rom.get_port(
            clock_domain="sys")

        # Sert-up memory bank 1 (all RAM)
        ram_size = 0xffff
        self.specials.ram = Memory(8, ram_size)
        self.specials.ram_r = self.ram.get_port(
            clock_domain="sys")
        self.specials.ram_w = self.ram.get_port(
            write_capable=True,
            clock_domain="sys")

        # ----------------------------------------
        # Z80 CPU instance and external sources.
        self.specials += Instance("tv80n",
            p_Mode=0,
            p_IOWait=1,
            p_T2Write=1,

            # Outputs
            o_m1_n=m1_n,
            o_mreq_n=mreq_n,
            o_iorq_n=iorq_n,
            o_rd_n=rd_n,
            o_wr_n=wr_n,
            o_rfsh_n=rfsh_n,
            o_halt_n=halt_n,
            #o_busak_n=,
            o_A=addr,
            o_dout=cpu_dout,

            # Inputs
            i_di=cpu_din,
            i_reset_n=cpu_reset_n,
            i_clk=ClockSignal("cpu"),
            i_wait_n=wait_n,
            i_int_n=int_n,
            i_nmi_n=nmi_n,
            i_busrq_n=busrq_n
        )

        # Add Verilog sources.
        # Note: There is a bug in migen/build/generic_platform.py 'copy_sources'
        # method which prepends (build_dir) to destination path while build
        # had already changed current working directory to build_dir. See also
        # migen issues https://github.com/m-labs/migen/issues/207. To fix, change
        # line 'dest = os.path.join(build_dir, path)' to 'dest=path' in
        # 'copy_sources'.

        # Add all sources in z80 subdirectory.
        vdir = os.path.join(os.path.abspath(os.path.dirname(__file__)), "z80")
        platform.add_source_dir(vdir)

        # Add specific sources.
        # platform.add_source("src/gateware/z80/tv80n.v")
        # platform.add_source("src/gateware/z80/tv80_core.v")
        # platform.add_source("src/gateware/z80/tv80_alu.v")
        # platform.add_source("src/gateware/z80/tv80_mcode.v")
        # platform.add_source("src/gateware/z80/tv80_reg.v")


        # ----------------------------------------------------------------------
        # Combinatorial logic

        self.comb += [
            counter_changed.eq(~(counter[0] == tick)),
        ]

        # Place some signals on debug connector for inspection.
        self.comb += [
            debug_0.eq(spi_sdcard.cs),
            debug_1.eq(spi_sdcard.start),
            debug_2.eq(spi_sdcard.done),

            #debug_3.eq(spi_sdcard.irq),
            debug_3.eq(leds[0]),

            debug_4.eq(sd_start.i),
            debug_5.eq(sd_start.o),

            # debug_4.eq(spi_sdcard.pads.clk),
            # debug_5.eq(spi_sdcard.pads.cs_n[0]),
            # debug_6.eq(spi_sdcard.pads.mosi),
            # debug_7.eq(spi_sdcard.pads.miso),

            # debug_0.eq(sys_hw_reset_n),
            # debug_1.eq(buttons[0]),
            # debug_2.eq(cpu_reset_n),
            # debug_3.eq(sys_reset_n),
            # debug_4.eq(0),
            # debug_5.eq(0),
            # debug_6.eq(0),
            # debug_7.eq(ClockSignal("ms")),
        ]

        self.comb += [
            int_n.eq(1),
            nmi_n.eq(1),
            busrq_n.eq(1),

            cpu_reset_n.eq(~(~sys_reset_n | buttons[0])),

            debug_disp.eq(~Cat(disp.port, disp.seg_en[0])),

            m_re.eq(rfsh_n & iorq_n & ~mreq_n & ~rd_n),
            m_we.eq(rfsh_n & iorq_n & ~mreq_n & ~wr_n),

            io_re.eq(~iorq_n & mreq_n & ~rd_n),
            io_we.eq(~iorq_n & mreq_n & ~wr_n),

            # UART Status register
            #     7       6       5       4       3       2       1       0
            # +-------+-------+-------+-------+-------+-------+-------+-------+
            # |       RESERVED        | TX_OK |       RESERVED        |RX_DATA|
            # +-------+-------+-------+-------+-------+-------+-------+-------+
            #
            # TX_OK         high when TX FIFO can accept bytes to send
            # RX_DATA       high when RX FIFO contains received data
            uart_status.eq(Cat(
                uart_rx_fifo.readable, 0, 0, 0,
                uart_tx_fifo.writable, 0, 0, 0
            )),
        ]

        # RGB LEDs
        # Each RBG LED is controlled by 3 8bit registers one for each color
        # (red, green blue). The value (0-255) controls the brightness of
        # the corresponding color.
        cadd = getattr(self.comb, '__iadd__')
        for i in range(1, 5):
            for c in ["r", "g", "b"]:
                pwm = getattr(self, f"pwm_rgb{i}_{c}")
                cadd(pwm.enable.eq(pwm.width != 0))
                led = getattr(self, f"rgb_led{i}")
                led_color = getattr(led, c)
                cadd(led_color.eq(pwm.pwm))


        # ----------------------------------------------------------------------
        # System clock domain logic

        self.sync += [

            # UART TX
            self.uart.tx_ready.eq(0),
            uart_tx_fifo.re.eq(0),

            If(uart_tx_pend,
                If(self.uart.tx_ack,
                    uart_tx_fifo.re.eq(1),
                    uart_tx_pend.eq(0)
                )
            ).Else(
                If(~self.uart.tx_ready,
                    If(self.uart.tx_ack,
                        If(uart_tx_fifo.readable,
                            self.uart.tx_data.eq(uart_tx_fifo.dout),
                            self.uart.tx_ready.eq(1),
                            uart_tx_pend.eq(1)
                        )
                    )
                )
            ),

            # Uart RX
            uart_rx_fifo.we.eq(0),

            If(self.uart.rx_ready,
                If(~self.uart.rx_ack,
                    self.uart.rx_ack.eq(1),
                    If(uart_rx_fifo.writable,
                        uart_rx_fifo.din.eq(self.uart.rx_data),
                        uart_rx_fifo.we.eq(1),
                    )
                )
            ).Else(
                self.uart.rx_ack.eq(0),
            ),

            # SD Card
            spi_sdcard.start.eq(0),
            If(sd_start.o & spi_sdcard.done,
                spi_sdcard.start.eq(1)
            ),
        ]


        # ----------------------------------------------------------------------
        # Millisecond ticker clock domain

        self.sync.ms += [
            ticks_ms.eq(ticks_ms + 1),
        ]


        # ----------------------------------------------------------------------
        # CPU clock domain

        # Reset RGB LEDs.
        reset_rgb_leds = []
        for i in range(1, 5):
            for c in ["r", "g", "b"]:
                pwm = getattr(self, f"pwm_rgb{i}_{c}")
                reset_rgb_leds.append(pwm.width.eq(0))

        # CPU Reset.
        self.sync.cpu += [
            If(~cpu_reset_n,
                mem_config.eq(0),
                disp.dispval.eq(0),

                self.leds[0].eq(0),
                self.leds[1].eq(0),
                self.leds[2].eq(0),
                self.leds[3].eq(0),

                reset_rgb_leds,

                spi_sdcard.cs.eq(0),
                spi_sdcard.cs_mode.eq(0),
                spi_sdcard.length.eq(0),
                spi_sdcard.mosi.eq(0),
            )
        ]

        # Tick counter.
        self.sync.cpu += [
            ticks.eq(ticks + 1),

            counter.eq(counter + 1),
            If(counter_changed,
                tick.eq(counter[0]),
            ),
        ]

        # Millisecond ticker, reset on read.
        ticks_ms_read_reset = Signal()
        ticks_ms_latch = Signal()
        self.sync.cpu += [
            If(ticks_ms_read_reset != 0xff,
                If(ticks_ms[0] == ticks_ms_latch,
                    ticks_ms_read_reset.eq(ticks_ms_read_reset + 1),
                    ticks_ms_latch.eq(~ticks_ms_latch)
                )
            )
        ]

        # Memory access.
        self.sync.cpu += [

            # Memory read
            If(m_re,
                If(mrdws == 0,
                    wait_n.eq(0),
                ).Elif(mrdws == 1,
                    If(addr > 0x7fff,
                        self.ram_r.adr.eq(addr)
                    ).Else(
                        If(mem_config[0] == 0,
                            self.rom_r.adr.eq(addr)
                        ).Else(
                            self.ram_r.adr.eq(addr)
                        )
                    )
                ).Elif(mrdws == 2,
                    wait_n.eq(1),
                    If(addr > 0x7fff,
                        cpu_din.eq(self.ram_r.dat_r),
                    ).Else(
                        If(mem_config[0] == 0,
                            cpu_din.eq(self.rom_r.dat_r),
                        ).Else(
                            cpu_din.eq(self.ram_r.dat_r),
                        )
                    )
                ),
                mrdws.eq(mrdws + 1),
            ).Else(
                mrdws.eq(0),
            ),

            # Memory write
            If(m_we,
                If(mwrws == 0,
                    wait_n.eq(0),
                ).Elif(mwrws == 1,
                    # Ignore writes to ROM
                    If(addr[15] | mem_config[0],
                        self.ram_w.adr.eq(addr),
                        self.ram_w.dat_w.eq(cpu_dout),
                        self.ram_w.we.eq(1)
                    )
                ).Elif(mwrws == 2,
                    wait_n.eq(1),
                    If(addr[15] | mem_config[0],
                        self.ram_w.we.eq(0)
                    )
                ),
                mwrws.eq(mwrws + 1),
            ).Else(
                mwrws.eq(0),
            )
        ]

        # I/O access.
        self.sync.cpu += [
            sd_start.i.eq(0),

            # I/O read
            If(io_re,
                iordws.eq(iordws+1),
                uart_rx_fifo.re.eq(0),

                If(iordws == 1,
                    cpu_din.eq(0x00),

                    Case(addr[0:8], {
                        # I/O address 0x00, serial RX
                        # Byte received by UART or 0x00 when no byte received
                        0x00: [
                            If(uart_rx_fifo.readable,
                                cpu_din.eq(uart_rx_fifo.dout),
                                uart_rx_fifo.re.eq(1),
                            )
                        ],
                        # I/O address 0x01, serial UART status register
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |       RESERVED        | TX_OK |       RESERVED        |RX_DATA|
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # TX_OK         high when TX FIFO can accept bytes to send
                        # RX_DATA       high when RX FIFO contains received data
                        0x01: [
                            cpu_din.eq(uart_status),
                        ],
                        # I/O address 0x02, memory configuration
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                        RESERVED                       |  BANK |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # BANK          Memory bank 0 (ROM/RAM) or 1 (all RAM)
                        0x02: [
                            cpu_din.eq(mem_config),
                        ],
                        # I/O address 0xF0, buttons
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |            RESERVED           |  BTN3 |  BTN2 |  BTN1 | RESET |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        0xf0: [
                            cpu_din.eq(Cat(
                                0, #buttons[0], # Used for manual CPU reset
                                buttons[1],
                                buttons[2],
                                buttons[3],
                                0, 0, 0, 0
                            )),
                        ],
                        # I/O address 0xF1, switches
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |            RESERVED           |  SW3  |  SW2  |  SW1  |  SW0  |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        0xf1: [
                            cpu_din.eq(Cat(
                                switches[0],
                                switches[1],
                                switches[2],
                                switches[3],
                                0, 0, 0, 0
                            ))
                        ],
                        # SD-Card status
                        # I/O address 0xF2
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                    RESERVED                   |  Mode |  Done |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # Done: SPI Xfer Done (when read as 1)
                        # Mode:
                        #       0: Raw: MOSI transfers aligned on core's data-width.
                        #       1: Aligned: MOSI transfers aligned on transfers' length.
                        0xf2: [
                            cpu_din.eq(Cat(
                                spi_sdcard.done,
                                {"raw": 0b0, "aligned": 0b1}[spi_sdcard.mode],
                                0, 0, 0, 0, 0, 0
                            ))
                        ],
                        # SD-Card MISO
                        # I/O address 0xF3
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                             MISO                              |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # SPI MISO data (MSB-first de-serialization)
                        0xf3: [
                            cpu_din.eq(spi_sdcard.miso)
                        ],
                        # I/O address 0xFD, millisecond ticks counter, reset on read.
                        0xfd: [
                            cpu_din.eq(ticks_ms_read_reset),
                            ticks_ms_read_reset.eq(0),
                        ],
                        # I/O address 0xFE, millisecond ticks counter
                        0xfe: [
                            cpu_din.eq(ticks_ms)
                        ],
                        # I/O address 0xFF, CPU clock ticks counter
                        0xff: [
                            cpu_din.eq(ticks)
                        ],
                    }),
                )
            ).Else(
                iordws.eq(0),
                uart_rx_fifo.re.eq(0),
            ),


            # I/O write
            If(io_we,
                wait_n.eq(0),
                iowrws.eq(iowrws+1),
                uart_tx_fifo.we.eq(0),

                If(iowrws == 1,
                    io_addr.eq(addr[0:8])
                ).Elif(iowrws == 2,
                    Case(io_addr, {
                        # I/O address 0x00, serial TX
                        0x00: [
                            If(uart_tx_fifo.writable,
                                uart_tx_fifo.din.eq(cpu_dout),
                                uart_tx_fifo.we.eq(1),
                                wait_n.eq(1),
                            ).Else(
                                iowrws.eq(2)
                            )
                        ],
                        # I/O address 0x02, memory configuration
                        0x02: [
                            mem_config.eq(cpu_dout),
                            wait_n.eq(1),
                        ],
                        # I/O address 0xA0-0xA2, RGB LED 1
                        0xa0: [ # red PWM
                            self.pwm_rgb1_r.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xa1: [ # green PWM
                            self.pwm_rgb1_g.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xa2: [ # blue PWM
                            self.pwm_rgb1_b.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],

                        # I/O address 0xA3-0xA5, RGB LED 2
                        0xa3: [ # red PWM
                            self.pwm_rgb2_r.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xa4: [ # green PWM
                            self.pwm_rgb2_g.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xa5: [ # blue PWM
                            self.pwm_rgb2_b.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],

                        # I/O address 0xA6-0xA8, RGB LED 3
                        0xa6: [ # red PWM
                            self.pwm_rgb3_r.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xa7: [ # green PWM
                            self.pwm_rgb3_g.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xa8: [ # blue PWM
                            self.pwm_rgb3_b.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],

                        # I/O address 0xA9-0xAB, RGB LED 4
                        0xa9: [ # red PWM
                            self.pwm_rgb4_r.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xaa: [ # green PWM
                            self.pwm_rgb4_g.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],
                        0xab: [ # blue PWM
                            self.pwm_rgb4_b.width.eq(cpu_dout << 8),
                            wait_n.eq(1),
                        ],

                        # I/O address 0xF0, 7-Segment display
                        0xf0: [
                            disp.dispval.eq(cpu_dout),
                            wait_n.eq(1),
                        ],
                        # I/O address 0xF1, 4 x LEDs
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |            RESERVED           |  LED3 |  LED2 |  LED1 |  LED0 |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        0xf1: [
                            leds[0].eq(cpu_dout[0]),
                            leds[1].eq(cpu_dout[1]),
                            leds[2].eq(cpu_dout[2]),
                            leds[3].eq(cpu_dout[3]),
                            wait_n.eq(1),
                        ],
                        # SD-Card Control
                        # I/O address 0xF2
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                        Reserved                       | Start |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # Start: SPI Xfer Start (Write 1 to start Xfer).
                        0xf2: [
                            sd_start.i.eq(cpu_dout[0]),
                            wait_n.eq(1),
                        ],
                        # SD-Card MOSI
                        # I/O address 0xF3
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                             MOSI                              |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # MOSI: SPI MOSI data (MSB-first serialization).
                        0xf3: [
                            spi_sdcard.mosi.eq(cpu_dout),
                            wait_n.eq(1),
                        ],
                        # SD-Card Chip Select
                        # I/O address 0xF4
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |  Mode |                           CS                          |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # CS:
                        #   "0b0..001" Chip 0 selected for SPI Xfer.
                        #   "0b1..000" Chip N selected for SPI Xfer.
                        # Mode:
                        #   "0b0", Normal operation (CS handled by Core).
                        #   "0b1", Manual operation (CS handled by User, direct
                        #          recopy of "sel"), useful for Bulk transfers.
                        0xf4: [
                            spi_sdcard.cs.eq(cpu_dout[0]),
                            #spi_sdcard.cs_mode.eq(cpu_dout[7]),
                            wait_n.eq(1),
                        ],
                        # SD-Card Clock Divider low
                        # I/O address 0xF5
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                          CLK_DIV_LOW                          |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        0xf5: [
                            sd_card_clk_divider[0:8].eq(cpu_dout),
                            wait_n.eq(1),
                        ],
                        # SD-Card Clock Divider high
                        # I/O address 0xF6
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                          CLK_DIV_HIGH                         |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        0xf6: [
                            sd_card_clk_divider[8:16].eq(cpu_dout),
                            spi_sdcard.clk_divider.eq(sd_card_clk_divider),
                            wait_n.eq(1),
                        ],
                        # SD-Card TX length
                        # I/O address 0xF7
                        #     7       6       5       4       3       2       1       0
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        # |                            LENGTH                             |
                        # +-------+-------+-------+-------+-------+-------+-------+-------+
                        0xf7: [
                            spi_sdcard.length.eq(cpu_dout),
                            wait_n.eq(1),
                        ],
                        "default": [
                            wait_n.eq(1)
                        ]
                    }),
                )
            ).Else(
                iowrws.eq(0),
                uart_tx_fifo.we.eq(0),
            )
        ]
