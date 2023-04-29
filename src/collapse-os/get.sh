#!/bin/bash

S=`basename $0`
P=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

C_OS_DIST="collapseos-latest.tar.gz"
C_OS_PATH="${P}/os"

# Download Collapse OS (Forth) and documentation
wget "http://collapseos.org/files/${C_OS_DIST}"
wget "https://schierlm.github.io/CollapseOS-Web-Emulator/2022-08/collapseos.pdf"

# Extract Collapse OS distribution
mkdir -p "${C_OS_PATH}"
if [ -f "${P}/${C_OS_DIST}" ]; then
    tar xvf "${P}/${C_OS_DIST}" --directory "${C_OS_PATH}"
else
    echo "\nUnable to extract Collapse OS distribution\n"
    exit 1
fi

# Prepare Collapse OS, integrating f80 sources into its source tree
if [ ! -d "${C_OS_PATH}/arch/z80/" ]; then
    echo "\nUnable to prepare Collapse OS distribution\n"
    exit 2
fi
cp -R "${P}/f80" "${C_OS_PATH}/arch/z80"
