M := $(abspath $(lastword $(MAKEFILE_LIST)))
P := $(dir $(M))

CC=sdcc
AR=sdar
CFLAGS=-mz80 --no-std-crt0
AS=sdasz80
#ASFLAGS=-l -g -ff
ASFLAGS=-l

all: ram_crt0.rel rom_crt0.rel runtime.lib

runtime.lib: runtime.rel spi.rel sdcard.rel
	sdar -rc $@ $^

ram_crt0.rel: ram_crt0.s
	$(AS) -o $<

rom_crt0.rel: rom_crt0.s
	$(AS) $(ASFLAGS) -o $<

%.rel: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean

clean:
	@rm -f \
		*.bin *.ihx *.asm *.lib \
		*.rel *.lk *.lst *.map *.noi *.sym \
		*~
