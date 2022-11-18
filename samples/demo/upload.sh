#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
F="demo"

"${P}/../../tools/upload.py" \
	--serial /dev/ttyUSB1 \
	--addr 0x8000 \
	--run \
	"${P}/${F}.bin"
