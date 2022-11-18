M := $(abspath $(lastword $(MAKEFILE_LIST)))
P := $(dir $(M))

CC=sdcc
CFLAGS=-mz80 --no-std-crt0
AS=sdasz80

all: ram_crt0.rel rom_crt0.rel runtime.rel

ram_crt0.rel: ram_crt0.s
	$(AS) -o $<

rom_crt0.rel: rom_crt0.s
	$(AS) -o $<

%.rel: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean

clean:
	@rm -f \
		*.bin *.ihx *.asm \
		*.rel *.lk *.lst *.map *.noi *.sym \
		*~
