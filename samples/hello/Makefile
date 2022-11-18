M := $(abspath $(lastword $(MAKEFILE_LIST)))
P := $(dir $(M))
RUNTIME_PATH=$(P)/../../src/c-runtime/
TOOL_PATH=$(P)/../../tools/
F=hello

SER_PORT=/dev/ttyUSB1	# Arty-80 connected on serial port
CODE_ADDR=0x8000		# crt0 start here
MAIN_ADDR=0x8040		# C main function starts here
DATA_ADDR=0xDF00		# C data area starts here

CC=sdcc
CFLAGS=-mz80 --no-std-crt0 \
	-I $(RUNTIME_PATH)
LD=sdld
LDFLAGS=-nmjwx \
	-L $(RUNTIME_PATH) \
	-b _CODE=$(MAIN_ADDR) -b _DATA=$(DATA_ADDR) \
	-k /usr/share/sdcc/lib/z80 -l z80

all: $(F).bin

%.rel: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(F).ihx: $(F).rel $(RUNTIME_PATH)/ram_crt0.rel $(RUNTIME_PATH)/runtime.rel
	$(LD) $(LDFLAGS) -i $@ $^

$(F).bin: $(F).ihx
	objcopy --input-target=ihex --output-target=binary $< $@

.PHONY: clean upload

clean:
	@rm -f \
		*.bin *.ihx *.asm \
		*.rel *.lk *.lst *.map *.noi *.sym \
		*~

upload:
	@$(TOOL_PATH)/upload.py \
		--serial $(SER_PORT) \
		--addr $(CODE_ADDR) \
		--run \
		"$(P)/$(F).bin"
