#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

make --directory "${P}" $*
