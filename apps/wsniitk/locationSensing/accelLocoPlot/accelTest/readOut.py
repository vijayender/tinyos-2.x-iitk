
import sys
import tos
import time
import ctypes
from read import *
import numpy as np

print sys.argv[3]
class AccelPacket(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('x_tsp','int',4),
                             ('y_tsp', 'int',4),
                             ('x_h','int',4),
                             ('x','blob',2*18),
                             ('y_h','int',4),
                             ('y','blob',2*18)],
                            packet)

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    print "      ", sys.argv[0], "network@host:port"
    sys.exit()


am = tos.AM()

def get_data():
    while 1:
        p = am.read()
        print p.type,p.source,p.group,p.destination,
        if p:
            m = AccelPacket(p.data);
            x = [ctypes.c_short(i<<8|j).value  for (i,j)\
                     in zip(m.x[1::2],\
                                m.x[::2])]
            y = [ctypes.c_short(i<<8|j).value  for (i,j)\
                     in zip(m.y[1::2],\
                                m.y[::2])]
            return [m.x_tsp+i*64/17 for i in xrange(0,18) ], x,  [m.y_tsp+i*64/17 for i in xrange(0,18) ], y
        else:
            # print 'out2'
            pass

xfil = KalmanFilter(533,1,1e-5,.1**2)
xr2a = RawToAccel(475,591,532.5)

d = np.array([])
for i in range(1,100):
    tx,x,ty,y = get_data()
    print np.average(xfil.filter_data(xr2a.convert(x))*180/np.pi), np.average(x), np.mean(x), np.median(x), np.std(x),"\r",
    sys.stdout.flush()
    d = np.concatenate((d,np.array(x)))

print
print "Data from 100 readings"
print np.average(d), np.mean(d), np.median(d), np.std(d)
fil = open(sys.argv[3],'w')
for i in d:
    fil.write(str(i)+'\n')


