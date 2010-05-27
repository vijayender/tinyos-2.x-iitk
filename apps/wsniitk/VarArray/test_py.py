from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
m = t.getNode(32)
m.bootAtTime(100)
t.addChannel("tVA",sys.stdout)

for i in xrange(0,1000):
    t.runNextEvent()
