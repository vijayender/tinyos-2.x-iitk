from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("meyer-simple.txt", "r")
m = t.getNode(32)
m.bootAtTime(100)
m2  = t.getNode(30)
m2.bootAtTime(101)

#t.addChannel("RadioCountToLedsC",sys.stdout)
t.addChannel("RSSI",sys.stdout)
print r.add (32, 30, -30)
print r.add (30, 32, -30)

lines = f.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in [32,30]:
      t.getNode(i).addNoiseTraceReading(val)

for i in [32,30]:
  t.getNode(i).createNoiseModel()

for i in xrange(0,1000):
    t.runNextEvent()

print r.add (32,30, -20)

for i in xrange(0,1000):
    t.runNextEvent()
