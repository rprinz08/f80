#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

EMULATOR="ruby ${P}/emulator.rb"

$EMULATOR --help

$EMULATOR \
	-r "${P}/../../src/firmware.sjasm/monitor.bin" \
	-l "${P}/../../samples/demo/demo.bin"
	#-l "${P}/../../samples/clock/clock.bin"
	#-l "${P}/../../samples/hello/hello.bin"

