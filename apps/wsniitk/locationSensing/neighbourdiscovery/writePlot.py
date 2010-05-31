from pylab import *
import sys, os,gtk.gdk
import numpy.linalg.linalg as l
import numpy as np

if len(sys.argv) < 2:
    print "Usage: writePlot <filename.py>"
    exit(0)

fname = sys.argv[1]
if (os.path.isfile(fname)):
    print "file aready exists!"
    exit(0)

plot(-100,-100)
plot(100,100)
title('Left click to add points. Right click to save to file'+fname)
coords = []
i=0

def addPoint (x, y):
    global i
    i+=1
    coords.append((x,y))
    for (x1,y1) in coords:
        if l.norm(np.array([x, y]) - np.array([x1, y1])) < 50:
            plot([x,x1],[y,y1],'b-')
    plot(x,y,'ro')
    text(x,y,str(i))
    draw()
    pass
def savePlot ():
    f = open(fname,'w')
    for (x,y) in coords:
        print "%(x)f %(y)f " % {'x':x, 'y':y}
        f.write("%(x)f %(y)f\n" % {'x':x, 'y':y})
    f.close()
    print "wrote into file", fname
    exit(0)
    pass

def on_move(event):
    # get the x and y pixel coords
    x, y = event.x, event.y
    if event.inaxes:
        if event.button == 1:
            addPoint (event.xdata, event.ydata)
        elif event.button == 3:
            savePlot()

connect('button_press_event', on_move)

show()
