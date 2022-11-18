#!/usr/bin/env python3

import os
from migen import *
#from migen.build.platforms import arty_a7
from migen.build.openocd import OpenOCD

base_path = os.path.dirname(os.path.realpath(__file__))
prog_path = os.path.join(base_path, 'prog')
bitstream = os.path.join(base_path, 'build', 'top.bit')

# Load with Vivado
#platform = arty_a7.Platform()
#prog = platform.create_programmer()
#prog.load_bitstream(bitstream)
#platform.create_programmer().flash(0, "build/top.bin")

# Load with OpenOCD
prog = OpenOCD(os.path.join(prog_path, 'openocd_xc7_ft2232.cfg'))
prog.load_bitstream(bitstream)
