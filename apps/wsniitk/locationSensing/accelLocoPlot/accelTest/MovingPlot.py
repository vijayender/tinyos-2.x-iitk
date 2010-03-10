#!/usr/bin/env python

"""
This example utlizes restore_region with optional bbox and xy
arguments.  The plot is continuously shifted to the left. Instead of
drawing everything again, the plot is saved (copy_from_bbox) and
restored with offset by the amount of the shift. And only newly
exposed area is drawn. This technique may reduce drawing time for some cases.
"""

import time

import gtk, gobject

import matplotlib
matplotlib.use('GTKAgg')


# Import from matplotlib the FigureCanvas with GTKAgg backend
from matplotlib.backends.backend_gtkagg \
        import FigureCanvasGTKAgg as FigureCanvas

# Import the matplotlib Toolbar2
# from matplotlib.backends.backend_gtk \
#         import NavigationToolbar2GTK as NavigationToolbar

import numpy as np
#import matplotlib.pyplot as plt
from matplotlib.figure import Figure
import threading

gtk.gdk.threads_init()

class MovingPlot(object):
    def get_bg_bbox(self):

        return self.ax.bbox.padded(-6)

    def __init__(self,x1,x2,y1,y2,numOfPlots):
        self.pad = float(x2 - x1) / 100
	self.windowname = 'PlotScanWindow'
        self.window = gtk.Window()
        self.window.connect("destroy", lambda x:gtk.main_quit());
        self.window.set_title(self.windowname)
        self.window.set_default_size(700,500)

        self.vbox = gtk.VBox()
        self.window.add(self.vbox)
	self.numOfPlots = numOfPlots
       
        # Create the figure, the axis and the canvas
        self.figure = Figure(figsize=(5,4), dpi=100)
        self.axis = self.figure.add_subplot(111)
        self.canvas = FigureCanvas(self.figure)
	self.axis.set_xlim((x1,x2))
	self.axis.xaxis.set_animated(True)
	self.axis.yaxis.set_animated(True)
        
        # Add the canvas to the container
        self.vbox.pack_start(self.canvas)
        
        # Create the matplotlib toolbar
        # self.toolbar = NavigationToolbar(self.canvas, self.window)
        # self.vbox.pack_start(self.toolbar,False,False)
        
        self.window.show_all()
        

        self.cnt = 0
        self.ax = self.axis
        self.canvas.mpl_connect('draw_event', self.on_draw)
        
        self.prev_pixel_offset = 0.

	self.xx = np.array([])
	self.yy = []
        
        self.x0 = 0
        self.xmax = self.ax.get_xlim()[1]
        self.width = self.xmax - self.x0
	self.line = []
	style = ["b-","r-","g-","k-","b-","r-","g-" ]
	for i in xrange(0,numOfPlots):
	    self.line.append(self.axis.plot([], [], style[i], animated=True, lw=1)[0])
	    self.yy.append(np.array([]))

        self.redraw_axis = 0

        #self.point, = ax.plot([], [], "ro", animated=True, lw=2)
        
        self.ax.set_ylim(y1, y2)
        
        self.background1 = None

        #cmap = plt.cm.jet
        #from itertools import cycle
        #self.color_cycle = cycle(cmap(np.arange(cmap.N)))


    def save_bg(self):
        self.background1 = self.canvas.copy_from_bbox(self.ax.get_figure().bbox)

        self.background2 = self.canvas.copy_from_bbox(self.get_bg_bbox())


    def get_dx_pixel(self, dx_data):
        tp = self.ax.transData.transform_point
        x0, y0 = tp((0, 0))
        x1, y1 = tp((dx_data, 0))
        return (x1-x0)

    def restore_background_shifted(self, dx_pixel):
        """
        restore bacground shifted by dx in data coordinate. This only
        works if the data coordinate system is linear.
        """

        # restore the clean slate background
        self.canvas.restore_region(self.background1)
        # restore subregion (x1+dx, y1, x2, y2) of the second bg
        # in a offset position (x1-dx, y1)
        x1, y1, x2, y2 = self.background2.get_extents()
        self.canvas.restore_region(self.background2,
                                   bbox=(x1+dx_pixel, y1, x2, y2),
                                   xy=(x1-dx_pixel, y1))

        return dx_pixel

    def on_draw(self, *args):
        self.save_bg()
        return False

    def add_data(self, xdata, ydata):

        if self.background1 is None:
            return True
        # assuming that xdata is ascending.
        xmax = xdata[-1:]

        if xmax < self.xmax:
            self.ax.set_xlim(self.x0, self.xmax)
            self.redraw_axis += 1
            
        else:
            # assuming that self.xx[0] exists
            dx_data = xdata[-1:][0] - self.xmax # Length of new line
            self.redraw_axis = 0
            
            x0 = self.x0
            xmax = self.xmax
            self.x0 += dx_data
            self.xmax += dx_data
            dx_pixel = self.get_dx_pixel(dx_data)
            self.ax.set_xlim(self.x0, self.xmax+self.pad)

            if dx_pixel > 0:
                self.restore_background_shifted(dx_pixel) #x0, self.x0)

        self.xx = np.concatenate((self.xx,xdata))
	for i in xrange(0,self.numOfPlots):
	    self.yy[i] = np.concatenate((self.yy[i],ydata[i]))
	    # print self.xx,'aaa',self.xx2,'bbb',self.yy,'ccc',self.yy2,'ddd',self.yy2-self.yy
	    self.line[i].set_xdata(self.xx)
	    self.line[i].set_ydata(self.yy[i])
	    self.ax.draw_artist(self.line[i])
	    self.yy[i] = self.yy[i][-2:]
	    
	self.xx = self.xx[-2:]


        if self.redraw_axis < 2:
            self.ax.draw_artist(self.ax.xaxis)
            self.ax.draw_artist(self.ax.yaxis)
        self.background2 = self.canvas.copy_from_bbox(self.get_bg_bbox())

        self.canvas.blit(self.ax.get_figure().bbox)
        self.cnt += 1
        return True

class Data(threading.Thread):
    def __init__(self,mp):
	super(Data,self).__init__()
	self.i=1
	self.mp = mp

    def run(self):
	while True:
	    x = np.linspace(self.i,self.i+4,5)
	    self.i = self.i+5
	    y = 0.3*np.sin(x*np.pi/10)
	    gtk.gdk.threads_enter()
	    self.mp.add_data(x,y)
	    gtk.gdk.threads_leave()
	    time.sleep(0.01)
    
if __name__ == "__main__":
    mp = MovingPlot(0,100,-1,1)
    data = Data(mp)
    
    gobject.timeout_add(1000, data.start)
    gtk.gdk.threads_enter()
    gtk.main()
    gtk.gdk.threads_leave()
