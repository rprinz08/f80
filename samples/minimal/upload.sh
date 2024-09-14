#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
F="mini"

"${P}/../../tools/upload.py" \
	--serial /dev/arty-a7-100-uart \
	--addr 0x8000 \
	"${P}/${F}.bin"

