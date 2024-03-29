# C64 Emulator in a FPGA

This project implement a C64 computer in FPGA logic. I made this to learn how to
write RTL code. I tried to make this implenentaion as close to the real C64 as
possible, usign scematics and datasheets. Unlike most other C64 fpga
implementations this emulator outputs the composite video signal, ie there is no
VGA or HDMI output. 

I tried to make the code a potable as I could but I tested this on a Digilent
Nexys 4 board, with an Artix 7 fpga. Porting this to other boards shoudl be
faily easy. But note that the clock generator must be replaced and maybe
something need to be done about the RAM and ROMS. In the Artix 7 theese are
translated in to Block rams, which is think is a Xilinx specific thing.

## Directory structure

```
assets    : Rom images for the C64
modules   : Functional implentation
sim       : Simulation projects
syn       : Synthesis project
tools     : Tools for controlling the C64
testbench : Toplevel testbenches
top       : Toplevel modules
``` 


## How to build

This porject uses the hdlmake tool to generate make files. Its is also assumed
that Xilinx Vivado is installed and is in the system PATH. To install hdlmake
run
```
python -m pip install hdlmake
```

To run the toplevel C64 simulation
```
cd sim/c64
python -m hdlmake
make clean && make && ./c64_tb.vpp
```

To run synthesis and build the FPGA bitstream

```
cd syn/nexys4
python -m hdlmake
make clean && make
```
This will after some time create the file `c64.runs/impl_1/nexys4_c64.bit` This
which can be programmed to the FPGA.

## Nexyx 4 implementation

When runnign the Nexyxs 4 board will show the memory bus address on the right 4
digits of the 7 segment display. (it show snapshots of the addresses because it
changes really fast). The left most 4 digits indicates the sound waveform.

- The composite video(PAL) is output on the _RED_ pin of the VGA connector, so
  simple cable can be made to connect the ground and red pin of the VGA
  connecotr the tv composite input.

  As an expeirment the video output is also tranmitted as a RF signal on the
  blue pin of the VGA connector. The signal is tranmitted at 55Mhz corresponding
  to VHF channel C3. On my setup I just plug in a jump wire into VGA connector
  then my TV is able to pickup the signal. Audio is transmitted on the green 
  pin of the VGA connector.

> **WARNING**: Tranmitting TV signal on VHF C3 is most likely a violation of RF
> regulatory requirements in your country. (How ever the power will not be very
> high). Also I did not implement propper SSB modulation so the signal has a
> mirror down in channel C3 so it actually occupies a bandwith of 10Mhz. 

- Audio is also output on the Nexsys minijack connector.

- A keyboard can be connected to the Nexys4 usb port.

- They 5 navigation buttons controls the joystick A or B port, swith 15 switches 
between port A and B.

- All switches should be on up position(towards the 7 segment digits). SW0 and
  SW1 controls the EXTROM and GAME c64 pins of the C64. Switching SW1 down will
  boot the cartrige image, which is a C64 diagnostic card.

- The USB UART is attracted to the special C64 debug interface(see below)



## Debug Interface

In order to debug the C64 core a debug interface has been made. The debug
interface is controlled with a normal UART, and is able to do DMA transfers
using the expansion port of the C64. 

I've made a python script which is able to read and write the bus using debug
interface. 

Uploading and running a PRG file:

```
python3 tools/c64debug.py -prg ~/prg/BoulderDash.prg -c RUN
```

Usage:
```
usage: c64debug.py [-h] [-read READ] [-prg PRG] [-snd] [-write WRITE] [-offset OFFSET] [-serial SERIAL] [-cmd CMD]

Read or wirte C64 bus.

optional arguments:
  -h, --help      show this help message and exit
  -read READ      read a number of bytes(in hex)
  -prg PRG        upload prg file
  -snd            play sound
  -write WRITE    Write a hex sequence
  -offset OFFSET  offset in hex
  -serial SERIAL  Serial device to use
  -cmd CMD        Inject a line into the BASIC keyboard buffer followed by RETURN.
```


# Simulation

Using `verialtor` it is possible to run a behavioural simulation of the emualtor almost 
realtime. The simulator has sound support but it sounds very bad. The simulation project is in the folder sim/c64

```
./c64hdl  -p ~/prg/ik_plus.prg
```
Scripts for testing the code with the vice emualtor test suite are also provided.
to run the vice test suite colone the test suite

```
svn co  https://svn.code.sf.net/p/vice-emu/code/testprogs
cd testprogs/testbench
cp ../../vice-tests/* .
cp ../../assets/*.mif .

```
edit test testbench.sh and add 
```
        c64hdl)
                target="$1"
            ;;
```

Run a test 
```
./testbench.sh  c64hdl 
```
Or run a subset of the tests 
```
./testbench.sh  c64hdl cia
```
# Showcase

![International Karate](images/ik_plus.jpeg)

![Bitmap mode](images/bitmap_mode.jpeg)
![Boulder dash simulator](images/boulder_dash_sim.png)

# Known issues

- RF modulation does not use SSB modulation, and occupies ca 12mhz bandwith as opposed to a 6 mhz BW. 
- Sprites can have artifacts when they reach the right side of the border.
- Several of the undocumented MOS6510 opcodes does not work
- A lot of games crashes, there are propably lots of reasons for this.


# License
This project contains code from:
- Arlet Ottens, for the CPU implementation
- Rayne, for the MOS6526 CIA imeplentation

This code is distributed under [3 clause BSD license](./LICENSE).