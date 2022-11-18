#!/usr/bin/env python3

import sys
sys.path.insert(0, 'src/gateware')

from migen import *
from migen.build.platforms import arty_a7
from top import *

# Arty-A7-35 = xc7a35ticsg324-1L
# Arty-A7-100 = xc7a100tcsg324-1
platform = arty_a7.Platform(device="xc7a100tcsg324-1")
top = Top(platform)

# Convert and build

# Only convert to verilog
#with open('top.v', 'w') as fd:
#    fd.write(str(verilog.convert(top)))

platform.build(top)
