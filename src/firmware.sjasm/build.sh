#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ASM="${P}/monitor"
sjasmplus --color=on "${ASM}.asm"

