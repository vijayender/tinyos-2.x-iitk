import numpy

distances = None
readings = None

def load_d_model(s):
    global distances, readings
    f = open(s,'r')
    lines = [line.split() for line in f.readlines()]
    readings = [(float(a[1])+float(a[2]))/2 for a in lines]
    distances = [float(a[0]) for a in lines]


def ed_from_d(x):
    """returns ed for a given d based on the experimental readings"""
    if (readings == None):
        print "No distance model loaded"
        return
    else :
        return numpy.interp(x, distances, readings)
        

def pdb_from_d(x):
    """returns pdb for a given distance d"""
    return pdb_from_ed(ed_from_d(x))

def ed_from_pdb(x):
    return (1+x/91)*84

def pdb_from_ed(x):
    return (x/84 - 1)*91

if __name__ == "__main__":
    load_d_model ('distances_average.txt')
    import pylab,numpy
    from scipy import interpolate
    pylab.plot(distances, readings,'+')
    x = numpy.arange(0,50,0.001)
    tck = interpolate.splrep(distances,readings,s=0)
    ynew = interpolate.splev(x,tck,der=0)
    pylab.plot(x, ed_from_d(x))
    pylab.plot(x, ynew)
    pylab.show()
    print 5, ed_from_d(5)
    
