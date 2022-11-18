#CC=sdcc
#CFLAGS=-mz80 --code-loc 0x8000 --data-loc 0xA000 --no-std-crt0
LD=sdld
LDFLAGS=-n -k /usr/share/sdcc/lib/z80 -l z80.lib
AS=sdasz80
#-o ram_crt0.s

ODIR=.

all: monitor.bin

monitor.rel: monitor.s
	$(AS) -o $<

monitor.ihx: monitor.rel
	$(LD) $(LDFLAGS) -i $@ $<

monitor.bin: monitor.ihx
	objcopy --input-target=ihex --output-target=binary $< $@

.PHONY: clean

clean:
	@rm -f \
		monitor.ihx monitor.bin \
		$(ODIR)/*.rel $(ODIR)/*.lk $(ODIR)/*.lst $(ODIR)/*.map \
		$(ODIR)/*.noi $(ODIR)/*.sym \
		*~ core

