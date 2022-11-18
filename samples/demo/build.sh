#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
F="demo"

make --directory "${P}" $*
