
from os import SCHED_OTHER, read
from time import sleep
import serial
import sys
import argparse
import time
    

def write_reg(addr,data):
    global ser
    ser.write([0x2,(addr >> 8) & 0xff, (addr )& 0xff,data])
    return
    b = ser.read(1)

    if(b):
        if(6 != b[0]):
            print( "%04x : %02x : %c" % (addr,b[0],b[0] ) )
    else:
        print("No response")

def read_reg(a):
    global ser
    ser.write([0x1,(a >> 8) & 0xff, (a )& 0xff])
    b = ser.read(1)
    
    if(b):
        return b[0]
    else:
        #return read_reg(a)
        print("No response")


def send_cmd(cmd):
    for c in cmd:
        write_reg(631,ord(c) )
        write_reg(198,1 )
        read_reg(198)


parser = argparse.ArgumentParser(description='Read or wirte C64 bus.')
parser.add_argument('-read')
parser.add_argument('-prg', help="upload prg file")
parser.add_argument('-snd',action="store_true", help="play sound")

parser.add_argument('-write')
parser.add_argument('-offset', help='offset in hex', default="00")
parser.add_argument('-serial',default='/dev/ttyUSB1')

parser.add_argument('-cmd')


args = parser.parse_args()

ser = serial.Serial(args.serial, baudrate=115200,timeout=0.02)  # open serial port

offset = int(args.offset,16)

if(args.prg):
    f = open(args.prg,"rb")
    d = f.read()
    f.close()
    offset = d[1]<< 8 | d[0]
    for i in range(len(d)-2):
        write_reg( offset +i ,d[2+i])
        if(i & 0xf == 0):
            print("%04x: write  " % (offset + i))


if( args.read ):
    length = int(args.read,16)
    for i in range(length):
        if(i & 0xf == 0):
            print("\n%04x:  " % (offset + i),end='')
        print( "%02x" % (read_reg(offset + i)),end='')

    print()

if( args.write ):
    length = int(len(args.write) / 2)
    d=""
    for i in range(length):
        d = int( args.write[2*i:2*i+2],16)
        write_reg( offset +i ,d)
    
if (args.cmd):
    send_cmd(args.cmd)
    send_cmd("\r")

if (args.snd):
    
    osc = 0*7
    write_reg(0xd400+osc,0x5)
    write_reg(0xd401+osc,0x24)
    write_reg(0xd402+osc,0)
    write_reg(0xd403+osc,8)
    write_reg(0xd405+osc,0x4e)
    write_reg(0xd406+osc,0x47)



    write_reg(0xd415,0x01)
    write_reg(0xd416,0x2f)
    write_reg(0xd417,0x10) #filter route
    write_reg(0xd418,0x2f) #Volume and low pass 
    #write_reg(0xd419,0xf)
    write_reg(0xd404+osc,0x41)
    time.sleep(2)
    write_reg(0xd404+osc,0x40)

ser.close()             # close portf