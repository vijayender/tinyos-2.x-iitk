# Simulation 5 motes, with some intial locations
import numpy as np
import wsnModel as w
import pylab
import numpy.linalg.linalg as l
from ndPacket import *
from TOSSIM import *
import sys

def sim_loop():
    l = sys.stdin.readline()
    while l[0] != 'q':
        l = sys.stdin.readline()
    

def distance(a,b):
    return l.norm(a-b)

def send_command (t, cmd, addr):
    rp = Radio_packet ()
    rp.control = cmd
    payload = rp.payload()
    data = [ chr(i) for i in payload ]
    data = "".join(data)
    pkt = t.newPacket();
    pkt.setData(data)
    pkt.setType(3)
    pkt.setDestination(addr)
    pkt.setSource(255)
    pkt.deliver(addr, t.time() + 3)
    print repr(data)
    print payload

def simulate(x):
    for i in xrange (0,x):
         t.runNextEvent()
        

    
if __name__ == "__main__":
    
    t = Tossim([])
    r = t.radio()
    f = open("meyer-simple.txt", "r")

    t.addChannel("ndC", sys.stdout)
    t.addChannel("debug_v", sys.stdout)
    w.load_d_model ('distances_average.txt')
    r = t.radio()
    if len(sys.argv) < 2:
        locs = np.matrix([[0,0],
                          [0,5],
                          [2.5,3.5],
                          [3.2,1],
                          [2,-1]])
    else:
        locs = np.genfromtxt(sys.argv[1])

    print locs, sys.argv[1]
    print len(locs), "Motes in the network"
    distances = np.zeros((len(locs), len(locs)))
    for i in xrange(0, len(locs)):
        for j in xrange(0,i):
            #distances[i,j] = -distance(locs[i], locs[j]) -40
            distances[i,j] = w.pdb_from_d(distance(locs[i], locs[j]))
    #Change ndC, add dbg channel, to see output.
    #Write a function to inject packets.
    lines = f.readlines()
    for line in lines:
        str1 = line.strip()
        if (str1 != ""):
            val = int(str1)
            for i in xrange(0,len(locs)):
                t.getNode(i).addNoiseTraceReading(val)

    for i in  xrange(0,len(locs)):
        t.getNode(i).createNoiseModel()
    
    
    for i in xrange(0,len(locs)):
        m = t.getNode(i)
        m.bootAtTime (100+i*100)

    for i in xrange(0, len(locs)):
        for j in xrange(0,i):
            if i == j:
                continue
            r.add(i, j, distances[i,j])
            r.add(j, i, distances[i,j])
            print i, j,  distances[i,j], distance(locs[i], locs[j]), w.ed_from_pdb(distances[i,j])
    
    simulate(100)
    print "time is now", t.time()
    for i in xrange(0,len(locs)):
        send_command(t, 1, i)
    simulate(10000)

    print "time is now", t.time(), "Going to get the messages from the leader"
    send_command(t, 3, 0)
    simulate(5000)

    send_command(t, 7, 0)
    simulate(2000)
    print 
    # sim_loop()
    #exit(0)

    # r = np.zeros((5,5))
    # devs=[0,1,2,3,4];
    # for i in xrange(0,5):
    #     for j in xrange(0,5):
    #         r[i,j] = distance(locs[devs[i]], locs[devs[j]])
    #         distances[i,j] = w.ed_from_d(r[i,j])
    # print distances,'\n', r
    send_command(t, 8, 0)
    simulate(20000)

