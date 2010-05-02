#!/usr/bin/env python

# This program is a mapping of the simple.c program
# written by Naofumi. It should provide a good test case for the
# relevant gtk.gdkgl.* classes and functions in PyGtkGLExt.
#
# Alif Wahid, March 2003.

#
# Rewritten in object-oriented style.
# --Naofumi
#

import sys

import pygtk
pygtk.require('2.0')
import gtk
import gtk.gtkgl
import gobject
import numpy as np
import threading

from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *
from MovingPlot import *
from read import *


class SimpleDrawingArea(gtk.DrawingArea, gtk.gtkgl.Widget):
    """OpenGL drawing area for simple demo."""

    def __init__(self, glconfig):
        self.rotx = 0
	self.roty = 0
        gtk.DrawingArea.__init__(self)

        # Set OpenGL-capability to the drawing area
        self.set_gl_capability(glconfig)

        # Connect the relevant signals.
        self.connect_after('realize',   self._on_realize)
        self.connect('configure_event', self._on_configure_event)
        self.connect('expose_event',    self._on_expose_event)
        glutInit()

    def _on_realize(self, *args):
        # Obtain a reference to the OpenGL drawable
        # and rendering context.
        gldrawable = self.get_gl_drawable()
        glcontext = self.get_gl_context()

        # OpenGL begin.
        if not gldrawable.gl_begin(glcontext):
            return

        light_diffuse = [1.0, 1.0, 1.0, 1.0]
        light_position = [1.0, 1.0, 1.0, 0.0]
        # qobj = gluNewQuadric()

        # gluQuadricDrawStyle(qobj, GLU_LINE)
        # glNewList(1, GL_COMPILE)
        # glEndList()

        glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse)
        glLightfv(GL_LIGHT0, GL_POSITION, light_position)

        glShadeModel(GL_SMOOTH)
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClearDepth(1.0)
	glEnable (GL_LINE_SMOOTH);
	glEnable (GL_POLYGON_SMOOTH);
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glHint (GL_LINE_SMOOTH_HINT|GL_POLYGON_SMOOTH_HINT, GL_DONT_CARE);
	glDisable (GL_DEPTH_TEST);

        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        gluPerspective(40.0, 1.0, 1.0, 100.0)

        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity()
        gluLookAt(0.0, 0.0, 3.0,
                  0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0)
        glTranslatef(0.0, 0.0, -3.0)

        # OpenGL end
        gldrawable.gl_end()

    def _on_configure_event(self, *args):
        # Obtain a reference to the OpenGL drawable
        # and rendering context.
        gldrawable = self.get_gl_drawable()
        glcontext = self.get_gl_context()

        # OpenGL begin
        if not gldrawable.gl_begin(glcontext):
            return False

        glViewport(0, 0, self.allocation.width, self.allocation.height)

        # OpenGL end
        gldrawable.gl_end()

        return False

    def _on_expose_event(self, *args):
        # Obtain a reference to the OpenGL drawable
        # and rendering context.
        gldrawable = self.get_gl_drawable()
        glcontext = self.get_gl_context()

        # OpenGL begin
        if not gldrawable.gl_begin(glcontext):
            return False

	glLineWidth (1.5);


        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glLoadIdentity()
        glTranslatef(0.0,0.0,-12.0)
	glRotate(90,0,1,0)
        glRotate(self.rotx,1,0,0)
        glRotate(self.roty,0,0,1)
        glRotate(90,1,0,0)
        glScale(3,3,3)
        glColor3f(1.,0,0)
        glutWireCube(1)
        glScale(1.,0.1,1.)
        glTranslate(0.,6.,0.)
        glColor3f(0,1,0)
        glutWireCube(1)

        if gldrawable.is_double_buffered():
            gldrawable.swap_buffers()
        else:
            glFlush()

        # OpenGL end
        gldrawable.gl_end()
        gobject.timeout_add(100,self._on_expose_event)

        return False


class SimpleDemo(gtk.Window):
    """Simple demo application."""

    def __init__(self):
        gtk.Window.__init__(self)

        self.set_title('simple')
        if sys.platform != 'win32':
            self.set_resize_mode(gtk.RESIZE_IMMEDIATE)
        self.set_reallocate_redraws(True)
        self.set_size_request(500,600)
        self.connect('delete_event', gtk.main_quit)

        # VBox to hold everything.
        vbox = gtk.VBox()
        self.add(vbox)

        # Query the OpenGL extension version.
        print "OpenGL extension version - %d.%d\n" % gtk.gdkgl.query_version()

        # Configure OpenGL framebuffer.
        # Try to get a double-buffered framebuffer configuration,
        # if not successful then try to get a single-buffered one.
        display_mode = (gtk.gdkgl.MODE_RGB    |
                        gtk.gdkgl.MODE_DEPTH  |
                        gtk.gdkgl.MODE_DOUBLE)
        try:
            glconfig = gtk.gdkgl.Config(mode=display_mode)
        except gtk.gdkgl.NoMatches:
            display_mode &= ~gtk.gdkgl.MODE_DOUBLE
            glconfig = gtk.gdkgl.Config(mode=display_mode)

        print "is RGBA:",                 glconfig.is_rgba()
        print "is double-buffered:",      glconfig.is_double_buffered()
        print "is stereo:",               glconfig.is_stereo()
        print "has alpha:",               glconfig.has_alpha()
        print "has depth buffer:",        glconfig.has_depth_buffer()
        print "has stencil buffer:",      glconfig.has_stencil_buffer()
        print "has accumulation buffer:", glconfig.has_accum_buffer()
        print

        # SimpleDrawingArea
        drawing_area = SimpleDrawingArea(glconfig)
        drawing_area.set_size_request(200, 200)
        vbox.pack_start(drawing_area)
	self.drawing_area = drawing_area

        # A quit button.
        button = gtk.Button('Quit')
        button.connect('clicked', gtk.main_quit)
        vbox.pack_start(button, expand=False)
	
    def set_rotation(self,alphax,alphay):
	# print alphax,alphay
	self.drawing_area.rotx = alphay
	self.drawing_area.roty = alphax
	self.drawing_area._on_expose_event();


class Data2(threading.Thread):
    def __init__(self,mp):
	super(Data2,self).__init__()
	self.i=1
	self.mp = mp
        self.am = tos.AM()
        self.xfil = KalmanFilter(532,1,1e-5,.1**2)
        self.yfil = KalmanFilter(304,1,1e-5,.1**2)
        self.xr2a = RawToAccel(475,591,533)
	self.yr2a = RawToAccel(279,330,305)
        self.a2x = IntegrateAccel(172,1e-3)
        self.discard1 = True
        self.xfilx = KalmanFilter(0,1,1e-5,1e-2)
	self.yfilx = KalmanFilter(0,1,1e-5,1e-2)

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
                #self.xr2a.calibrate(x)
            tx,x,ty,y = self.get_data()
	    self.xr2a.offset = 0;
            ax = self.xfilx.filter_data(self.xr2a.convert(x))
	    ay = self.yfilx.filter_data(self.yr2a.convert(y))
	    
	    alphax = np.arcsin(np.average(ax)/9.8)*180/np.pi
	    alphay = np.arcsin(np.average(ay)/9.8)*180/np.pi

	    gtk.gdk.threads_enter()
	    self.mp.set_rotation(alphax,alphay)
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


class _Main(object):
    """Simple application driver."""

    def __init__(self, app):
        self.app = app

    def run(self):
        self.app.show_all()
        gtk.main()


if __name__ == '__main__':
    m = SimpleDemo()
    data = Data2(m)
    gobject.timeout_add(1000, data.start)
    gtk.gdk.threads_enter()
    m.show_all()
    gtk.main()
    gtk.gdk.threads_leave()
