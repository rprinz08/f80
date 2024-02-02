LD=sdld
LDFLAGS=-n -i
AS=sdasz80

ODIR=.

all: monitor.bin

monitor.bin: monitor.ihx
	objcopy --input-target=ihex --output-target=binary $< $@

monitor.ihx: monitor.rel tools.rel
	$(LD) $(LDFLAGS) -b _MAIN=0 -b _CODE=MAIN_END $@ $^

%.rel: %.s
	$(AS) -s -l -o $<

.PHONY: clean

clean:
	@rm -f \
		monitor.bin $(ODIR)/*.ihx \
		$(ODIR)/*.rel $(ODIR)/*.lk $(ODIR)/*.lst $(ODIR)/*.map \
		$(ODIR)/*.noi $(ODIR)/*.sym \
		*~ core

