#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ASM="${P}/build"
sjasmplus --color=on "${ASM}.s"
