M := $(abspath $(lastword $(MAKEFILE_LIST)))
P := $(dir $(M))
RUNTIME_PATH=$(P)../../src/c-runtime/
TOOL_PATH=$(P)../../tools/
F=mini

SER_PORT=/dev/arty-a7-100-uart	# Arty-80 connected on serial port
CODE_ADDR=0x8000		# code starts here

AS=sdasz80
ASFLAGS=-l
LD=sdld
LDFLAGS=-nmjwx \
	-L $(RUNTIME_PATH) \
	-k /usr/share/sdcc/lib/z80 -l z80

all: $(F).bin

%.rel: %.s
	$(AS) $(ASFLAGS) -o $<

$(F).ihx: $(F).rel
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
	@$(TOOL_PATH)upload.py \
		--serial $(SER_PORT) \
		--addr $(CODE_ADDR) \
		--run \
		"$(P)/$(F).bin"

