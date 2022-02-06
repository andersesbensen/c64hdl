

all: vic_test.mif iec_test.mif rasterirq_hold.mif

clean:
	rm -f *.mif *.bin

%.mif: %.bin
	hexdump -v -e '/1 "%02X "' $< > $@

%.bin: %.asm
	acme -f plain -o $@ $< 

.SUFFIXES: .asm .bin 