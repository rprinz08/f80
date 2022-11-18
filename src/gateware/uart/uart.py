import sys
sys.path.insert(0, 'src')

from argparse import ArgumentError
from migen import *
from migen.genlib.fsm import *
from gateware.clock import Divisor


class Uart(Module):
    def __init__(self, serial, clk_freq_hz, baud_rate):
        self.rx_data = Signal(8)
        self.rx_ready = Signal()
        self.rx_ack = Signal()
        self.rx_error = Signal()

        self.tx_data = Signal(8)
        self.tx_ready = Signal()
        self.tx_ack = Signal()

        divisor = Divisor(freq_in=clk_freq_hz, freq_out=baud_rate, max_ppm=50000)

        # # #

        rx_counter = Signal(max=divisor)
        self.rx_strobe = rx_strobe = Signal()
        self.comb += rx_strobe.eq(rx_counter == 0)
        self.sync += \
            If(rx_counter == 0,
                rx_counter.eq(divisor - 1)
            ).Else(
                rx_counter.eq(rx_counter - 1)
            )

        self.rx_bitno = rx_bitno = Signal(3)
        self.submodules.rx_fsm = FSM(reset_state="IDLE")
        self.rx_fsm.act("IDLE",
            If(~serial.rx,
                NextValue(rx_counter, divisor // 2),
                NextState("START")
            )
        )
        self.rx_fsm.act("START",
            If(rx_strobe,
                NextState("DATA")
            )
        )
        self.rx_fsm.act("DATA",
            If(rx_strobe,
                NextValue(self.rx_data, Cat(self.rx_data[1:8], serial.rx)),
                NextValue(rx_bitno, rx_bitno + 1),
                If(rx_bitno == 7,
                    NextState("STOP")
                )
            )
        )
        self.rx_fsm.act("STOP",
            If(rx_strobe,
                If(~serial.rx,
                    NextState("ERROR")
                ).Else(
                    NextState("FULL")
                )
            )
        )
        self.rx_fsm.act("FULL",
            self.rx_ready.eq(1),
            If(self.rx_ack,
                NextState("IDLE")
            ).Elif(~serial.rx,
                NextState("ERROR")
            )
        )
        self.rx_fsm.act("ERROR",
            self.rx_error.eq(1))

        # # #

        tx_counter = Signal(max=divisor)
        self.tx_strobe = tx_strobe = Signal()
        self.comb += tx_strobe.eq(tx_counter == 0)
        self.sync += \
            If(tx_counter == 0,
                tx_counter.eq(divisor - 1)
            ).Else(
                tx_counter.eq(tx_counter - 1)
            )

        self.tx_bitno = tx_bitno = Signal(3)
        self.tx_latch = tx_latch = Signal(8)
        self.submodules.tx_fsm = FSM(reset_state="IDLE")
        self.tx_fsm.act("IDLE",
            self.tx_ack.eq(1),
            If(self.tx_ready,
                NextValue(tx_counter, divisor - 1),
                NextValue(tx_latch, self.tx_data),
                NextState("START")
            ).Else(
                NextValue(serial.tx, 1)
            )
        )
        self.tx_fsm.act("START",
            self.tx_ack.eq(0),
            If(self.tx_strobe,
                NextValue(serial.tx, 0),
                NextState("DATA")
            )
        )
        self.tx_fsm.act("DATA",
            If(self.tx_strobe,
                NextValue(serial.tx, tx_latch[0]),
                NextValue(tx_latch, Cat(tx_latch[1:8], 0)),
                NextValue(tx_bitno, tx_bitno + 1),
                If(self.tx_bitno == 7,
                    NextState("STOP")
                )
            )
        )
        self.tx_fsm.act("STOP",
            If(self.tx_strobe,
                NextValue(serial.tx, 1),
                NextState("IDLE")
            )
        )
