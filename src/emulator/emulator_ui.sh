#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

EMULATOR="ruby ${P}/emulator_ui.rb"

$EMULATOR --help

function run_demo {
    $EMULATOR \
        -r "${P}/../../src/firmware.sjasm/monitor.bin" \
        -l "${P}/../../samples/demo/demo.bin"
}

function run_clock {
    $EMULATOR \
        -r "${P}/../../src/firmware.sjasm/monitor.bin" \
        -l "${P}/../../samples/clock/clock.bin"
}

function run_hello {
    $EMULATOR \
        -r "${P}/../../src/firmware.sjasm/monitor.bin" \
        -l "${P}/../../samples/hello/hello.bin"
}

function run_os {
    $EMULATOR \
        -r "${P}/../../src/collapse-os/os/arch/z80/f80/os.bin"
}

function run_basic {
    $EMULATOR \
        -l "${P}/../../src/bbc-basic/build.bin"
}

# Uncomment what you want to run ...
#run_demo
#run_clock
#run_hello
#run_os
run_basic

