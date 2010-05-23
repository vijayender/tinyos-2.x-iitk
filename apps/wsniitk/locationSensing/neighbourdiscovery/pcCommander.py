#!/usr/bin/env python

import sys
import tos
import time
import select
from struct import *
from ndPacket import *
import array



if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    print "      ", sys.argv[0], "network@host:port"
    sys.exit()

def _getSource(comm, timeout=None):
    source = comm.split('@')
    params = source[1].split(':')
    debug = '--debug' in sys.argv
    if source[0] == 'serial':
        try:
            print params[0], params[1]
            return tos.Serial(params[0], int(params[1]), flush=True, debug=debug, readTimeout=timeout)
        except:
            print "ERROR: Unable to initialize a serial connection to", comm
            raise Exception
    elif source[0] == 'network':
        try:
            return tos.SerialMIB600(params[0], int(params[1]), debug=debug)
        except:
            print "ERROR: Unable to initialize a network connection to", comm
            print "ERROR:", traceback.format_exc()
            raise Exception
    raise Exception


source = _getSource(sys.argv[1], timeout = 0.5)

am = tos.AM(source)
i=0

command = sys.argv[2]
dest = int(sys.argv[3])

def input():
    try:
        foo = raw_input()
        return foo
    except:
        # timeout
        return

def input_loop ():
    if select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], []):
        return sys.stdin.readline()
    else:
        return None

def run_command (cmd):
    if cmd:
        print "|"+cmd+"|"
    if (cmd == 'h'):
        print 'sending hello ..'
        send_command (0)
    elif (cmd == "nd"):
        print "detect neighbour .."
        send_command(1)
    elif (cmd =="get"):
        print "get neighbours .."
        send_command(3)
    elif (cmd == "im"):
        print "test_im .."
        send_command(5)
    elif (cmd == "dbg"):
        send_command (6)
    elif (cmd == "syn"):
        send_command (7)
    elif (cmd == "im2"):
        send_command (8)
    elif (cmd == None):
        pass
    elif (cmd == "q") | (cmd == ""):
        exit(0);
    else:
        print 'command not understood'
#    print ">> ",

def packBits (p):
    r = ''
    for i in p:
        r += chr(i)
    return r

def send_command (cmd):
    rp = Radio_packet ()
    rp.control = cmd
    am.write(rp, 3, dest=dest)

def read_loop():
    p = am.read()
    i = 0;
    run_command(None)
    while True:
        i+=1
        if p:
            if p.type == 8 :
                start = 0
                end = len(p.data)
                # print p.data
                while start < end:
                    if (p.data[start] == 1):
                        print 'uint8_t:', p.data[start+1]
                        start += 2
                        pass
                    elif (p.data[start] == 2):
                        print 'uint16_t:', unpack('H', packBits(p.data[start+1:start+3]))
                        start += 3
                        pass
                    elif (p.data[start] == 3):
                        print 'uint32_t:', unpack('I', packBits(p.data[start+1:start+5]))
                        start += 5
                        pass
                    elif (p.data[start] == 4):
                        print 'double:', unpack('f', packBits(p.data[start+1:start+5]))
                        start += 5
                    elif (p.data[start] == 5):
                        print 'coordinate', unpack('f', packBits(p.data[start+1:start+5])),',', unpack('f', packBits(p.data[start+5:start+9]))
                        start += 9
                    elif (p.data[start] == 0):
                        break
            else :
                print "%(d)5d"% {'d':i},p.type,p.source,p.group,p.destination, p.data
        else:
            pass
        cmd = input_loop()
        if cmd != None:
            run_command(cmd.strip())
        p = am.read()

if (command == "hello"):
    print "saying hello"
    send_command(0);
    read_loop();
elif (command == "nd"):
    print "detect neighbour"
    send_command(1)
    read_loop()
elif (command =="get"):
    send_command(3)
    read_loop()
elif (command == "test_im"):
    send_command(5)
    read_loop()
elif(command == "geto"):
    rp = Radio_packet();
    rp.control = 4;
    if(am.write(rp,9)):
        print "Success issuing command get"
        p = am.read()
        print "{0:7} {1:7} {2:7} {3:7} {4:7} {5:7} {6:7} {7:7} {8:7} {9:7}".format("S.no","toa","rss1","rss2","lqi1","lqi2","ret1","ret2","v1","v2")
        while p:
            m = pcPacket(p.data);
            if m.v2 == 0:
                break;
            print "{0:7} {1:7} {2:7} {3:7} {4:7} {5:7} {6:7} {7:7} {8:7} {9:7}".format(m.counter,m.toa,m.rssi1,m.rssi2,m.lqi1,m.lqi2,m.retr1,m.retr2,m.v1,m.v2)
            p = am.read()
    else:
        print ":( no hello"
elif (command == "erase"):
    rp = Radio_packet();
    rp.control = 3;
    if(am.write(rp,9)):
        print "Success issuing command erase"
        p = am.read();
        m = pcPacket(p.data);
        print "mote returned packet with v1",m.v2
    else:
        print ":( no hello"
