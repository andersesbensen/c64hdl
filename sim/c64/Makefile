

TOP_MODULE := c64_tb

VERILATOR_OPT := -D XILINX_SIMULATOR

VERILOG_SRC :=  \
../../modules/c64/c64.v \
../../modules/c64/pla.v \
../../modules/c64/ram.v \
../../modules/c64/ramr.v \
../../modules/c64/rom.v \
../../modules/cia/cia.v \
../../modules/cpu/ALU.v \
../../modules/cpu/cpu.v \
../../modules/cpu/mos6510.v \
../../modules/rf_modulator/rf_modulator.v \
../../modules/sid/sid.v \
../../modules/sid/sid_env.v \
../../modules/sid/sid_filter.v \
../../modules/sid/sid_voice.v \
../../modules/vicii/vicii.v \
../../modules/vicii/vicii_palette.v \
../../modules/vicii/vicii_sprite.v \

CFLAGS= -O3 $(shell pkg-config --cflags libpng) $(shell pkg-config --cflags sdl2)
LDFLAGS= -O3 $(shell pkg-config --libs libpng) $(shell pkg-config --libs sdl2)



all: c64hdl

verilog_code: $(VERILOG_SRC) keyboard.cpp main.cpp 
	verilator --cc +1364-2001ext+v --trace \
		-LDFLAGS "$(LDFLAGS)" \
		-CFLAGS "-g $(CFLAGS)" \
		-Wno-INFINITELOOP -Wno-CASEOVERLAP \
		-Wno-CASEX -Wno-STMTDLY -Wno-COMBDLY \
		-Wno-PINMISSING \
		-DXILINX_SIMULATOR=1 \
		-Wno-WIDTH -exe -o c64hdl $(VERILOG_SRC)  \
		keyboard.cpp main.cpp

c64hdl: verilog_code
	make -C obj_dir -f Vc64.mk
	cp obj_dir/c64hdl .

clean:
		rm -rf obj_dir c64hdl

mrproper: clean
		rm -rf *.vcd *.vvp

.PHONY: mrproper clean 
