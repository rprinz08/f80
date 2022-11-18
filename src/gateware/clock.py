from argparse import ArgumentError
from migen import *


def Divisor(freq_in, freq_out, max_ppm=None):
    divisor = freq_in // freq_out
    if divisor <= 0:
        raise ArgumentError("output frequency is too high")

    ppm = 1000000 * ((freq_in / divisor) - freq_out) / freq_out
    if max_ppm is not None and ppm > max_ppm:
        raise ArgumentError("output frequency deviation is too high")

    return divisor


def Divisor2(freq_in, freq_out, max_ppm=None):
    divisor = round(freq_in / freq_out) // 2
    if divisor <= 0:
        raise ArgumentError("output frequency is too high")

    ppm = 1_000_000 * ((freq_in / (divisor * 2)) - freq_out) / freq_out
    if max_ppm is not None and ppm > max_ppm:
        raise ArgumentError("output frequency deviation is too high")

    return divisor


class Clock(Module):
    def __init__(self, clk_in_freq, clk_out_frq, max_ppm=50_000, **kwargs):

        self.clk_out = clk_out = Signal()

        # # #

        clk_div = Divisor2(freq_in=clk_in_freq, freq_out=clk_out_frq, max_ppm=max_ppm)
        clk_div_cnt = Signal(max=clk_div)

        self.sync += [
            If(clk_div_cnt == 0,
                clk_out.eq(~clk_out),
                clk_div_cnt.eq(clk_div - 1)
            ).Else(
                clk_div_cnt.eq(clk_div_cnt - 1)
            )
        ]
