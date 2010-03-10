#!/usr/bin/env python

import sys
import tos
import time
import ctypes
from MovingPlot import MovingPlot
import threading,gobject
import gtk
import numpy as np


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

class KalmanFilter:
    def __init__(self,x,P,Q,R):
        self.Q = Q
        self.R = R
        self.P = P
        self.K = 0
        self.x = x
        
    def filter_data(self,data):
        xfil = np.zeros(len(data))
        i=0
        for z in data:
            self.P = self.P + self.Q
            self.K = self.P / (self.P + self.R)
            self.x = self.x + self.K * (z - self.x)
            self.P = (1 - self.K) * self.P
            xfil[i] = self.x
            i += 1
        return xfil

class IntegrateAccel:
    def __init__(self,tstart,tfactor):
        self.v = 0
        self.x = 0
        self.t = tstart
        self.tfactor = tfactor
        
    def synthesize_data(self,adata,tdata):
        xd = np.zeros(len(adata))
        vd = np.zeros(len(adata))
        i=0
        for (a,t1) in zip(adata,tdata):
            t = (t1 - self.t)*self.tfactor
            self.t = t1
            self.x += self.v*t + 1/2*a*t**2
            self.v += a*t
            xd[i] = self.x
            vd[i] = self.v
            i += 1
        return xd,vd

class RawToAccel:
    def __init__(self,neg_1g,pos_1g,default):
        self.neg_1g = neg_1g
        self.pos_1g = pos_1g
        self.default = default
        self.scale_factor = float(pos_1g - neg_1g)/2
        self.offset = 0

    def convert(self,raw):
        #print np.average(raw)
        return [self.offset + (1 - (self.scale_factor+self.default-i)/self.scale_factor)*9.8 for i in raw ]

    def calibrate(self,raw):
        self.offset = -1*np.average(self.convert(raw))

class Data(threading.Thread):
    def __init__(self,mp):
	super(Data,self).__init__()
	self.i=1
	self.mp = mp
        self.am = tos.AM()
        self.xfil = KalmanFilter(532,1,1e-5,.1**2)
        self.yfil = KalmanFilter(304,1,1e-5,.1**2)
        self.xr2a = RawToAccel(475,591,531)
        self.a2x = IntegrateAccel(172,1e-3)
        self.discard1 = True
        self.xfilx = KalmanFilter(0,1,1e-5,1e-2)

    def run(self):
	while True:
	    # x = np.linspace(self.i,self.i+4,5)
	    # self.i = self.i+5
	    # y = 0.3*np.sin(x*np.pi/10)
	    # print x,y
            if self.discard1:
                tx,x,ty,y = self.get_data()
                self.discard1 = False
                tx,x,ty,y = self.get_data()
                self.xr2a.calibrate(x)
            tx,x,ty,y = self.get_data()
            # print x
            #print self.xr2a.convert(x)
            a =  self.xfilx.filter_data(self.xr2a.convert(x))
            ox,v = self.a2x.synthesize_data(a,tx)
            # print self.a2x.synthesize_data(self.xr2a.convert(x),tx)
            # print tx
	    gtk.gdk.threads_enter()
	    self.mp.add_data(tx,[x,y,self.xfil.filter_data(x),self.yfil.filter_data(y),a*5 + 400,v*100+400,ox*10+400])
	    gtk.gdk.threads_leave()
	    time.sleep(0.01)

    def get_data(self):
        while 1:
            p = self.am.read()
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



    
if __name__ == "__main__":
    mp = MovingPlot(0,10000,200,600,7)
    data = Data(mp)
    
    gobject.timeout_add(1000, data.start)
    gtk.gdk.threads_enter()
    gtk.main()
    gtk.gdk.threads_leave()


