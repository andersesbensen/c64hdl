
from concurrent.futures import thread
from os import SCHED_OTHER, read
from time import sleep
from traceback import print_tb
import serial
import sys
import argparse
import time
    
cnt = 0
def reset():
    print("Reset")
    global ser
    ser.write([0xde,0xad,0xbe,0xef])
    sleep(3.5)    

def write_reg(addr,data):
    global ser
    global cnt

    ser.write([0x2,(addr >> 8) & 0xff, (addr )& 0xff,data])
    cnt = cnt + 1

    if(cnt > 20):
        b = ser.read(20)
        cnt = 0
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

def load_prg(file):
    f = open(file,"rb")
    d = f.read()
    f.close()
    offset = d[1]<< 8 | d[0]
    for i in range(len(d)-2):
        write_reg( offset +i ,d[2+i])
        if(i & 0xf == 0):
            print("%04x: write\r" % (offset + i),end=" ")

def do_gui():
    import pygame, time
    import pygame.locals as loc

    pygame.init()
    screen = pygame.display.set_mode((640, 480))
    pygame.display.set_caption('Pygame Keyboard Test')
    #pygame.mouse.set_visible(0)
    
    running = True;
    while running:
        for event in pygame.event.get():
            if (event.type == loc.KEYUP):
                print("key released %x\n" % event.scancode )
            
            elif (event.type == loc.KEYDOWN):

                print("key pressed %x \n" % event.scancode)
            elif(event.type == pygame.QUIT):
                running = False
        time.sleep(0.1)
    
    pygame.quit()

parser = argparse.ArgumentParser(description='Read or wirte C64 bus.')
parser.add_argument('-read',help="read a number of bytes(in hex)")
parser.add_argument('-prg', help="upload PRG file")
parser.add_argument('-test', help="RUN vice test case")

parser.add_argument('-snd',action="store_true", help="play sound")
parser.add_argument('-reset',action="store_true", help="Reset chip")

parser.add_argument('-write', help="Write a hex sequence")
parser.add_argument('-offset', help='offset in hex', default="00")
parser.add_argument('-timeout', help='test timeout cycles', default="1000000")

parser.add_argument('-serial', help="Serial device to use",default='/dev/ttyUSB1')
parser.add_argument('-cmd', help="Inject a line into the BASIC keyboard buffer followed by RETURN.")
parser.add_argument('-gui',action="store_true", help="show gui for keyboard and joystick input")


args = parser.parse_args()

if(args.gui):
    do_gui()

rc = 0
ser = serial.Serial(args.serial, baudrate=115200,timeout=0.02)  # open serial port

offset = int(args.offset,16)

if(args.reset):
    reset()

if(args.prg):
    load_prg(args.prg)

if(args.test):

    load_prg(args.test)
    ser.read(1000) # empty RX buffer
    send_cmd("RUN")
    send_cmd("\r")
    ser.read(1000) # empty RX buffer

    t = int(args.timeout)/1000000 * 50
    for _ in range(int(t)):
        status = ser.read(1)
        print(status, t,len(status))
        if(len(status) >0 ):
            break
    
    sleep(int(args.timeout) / 1000000)
    print( "Status %i" % ord(status))
    #Read the border color
    color = read_reg(0xD020) & 0xf
    if(color == 5):     #Green
        print("SUCSESS")
        rc = 0
    elif(color == 10):  #Red
        print("FAIL")
        rc = 0xff
    else:
        print("INCONCLUSIVE (%x)" % rc)
        rc = 2

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
    write_reg(0xd401+osc,0x44)
    write_reg(0xd402+osc,0)
    write_reg(0xd403+osc,8)
    write_reg(0xd405+osc,0x4e)
    write_reg(0xd406+osc,0x44)

    osc = 2*7
    write_reg(0xd400+osc,0x5)
    write_reg(0xd401+osc,0x1)
    write_reg(0xd402+osc,0)
    write_reg(0xd403+osc,8)
    write_reg(0xd405+osc,0x4e)
    write_reg(0xd406+osc,0x4a)


    write_reg(0xd415,0x01)
    write_reg(0xd416,0x0f)
    write_reg(0xd417,0x91) #filter route
    write_reg(0xd418,0x9f) #Volume and low pass 
    #write_reg(0xd419,0xf)
    write_reg(0xd404+2*7,0x01)
    write_reg(0xd404+0*7,0x13)

    time.sleep(2)
    write_reg(0xd404+2*7,0x00)
    write_reg(0xd404+0*7,0x12)


ser.close()             # close portf
sys.exit(rc)