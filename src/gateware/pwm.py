#
# This file is part of LiteX.
#
# Copyright (c) 2015-2019 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

from migen import *
from migen.genlib.cdc import MultiReg

#from litex.soc.interconnect.csr import *

# Pulse Width Modulation ---------------------------------------------------------------------------

class PWM(Module):
    """Pulse Width Modulation

    Provides the minimal hardware to do Pulse Width Modulation.

    Pulse Width Modulation can be useful for various purposes: dim leds, regulate a fan, control
    an oscillator. Software can configure the PWM width and period and enable/disable it.
    """
    def __init__(self, pwm=None, clock_domain="sys",
        default_enable = 0,
        default_width  = 0,
        default_period = 0):
        if pwm is None:
            self.pwm = pwm = Signal()
        self.enable = Signal(reset=default_enable)
        self.width  = Signal(32, reset=default_width)
        self.period = Signal(32, reset=default_period)

        # # #

        counter = Signal(32, reset_less=True)

        sync = getattr(self.sync, clock_domain)
        sync += [
            If(self.enable,
                counter.eq(counter + 1),
                If(counter < self.width,
                    pwm.eq(1)
                ).Else(
                    pwm.eq(0)
                ),
                If(counter >= (self.period - 1),
                    counter.eq(0)
                )
            ).Else(
                counter.eq(0),
                pwm.eq(0)
            )
        ]
