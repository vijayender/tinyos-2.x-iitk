from numpy import *
import sys
import numpy.linalg.linalg as l
import pylab

def flipColumns(X,i,j):
    """ Flip ith and jth columns of X

    Original X is modified
    
    @returns: X with flipped values

    """
    t = copy(X[:,j])
    X[:,j] = X[:,i]
    X[:,i] = t
    return X

def findRotation(theta):        # x1,x2 are array of coordinates of
                                # point in 2D
    """ Compute the angle of rotation of l2 compared to l1

    @param l1: [[1x2],[1x2]] matrix containing points
    @param l2: same as l1 but in different frame

    Assumes that both the frames are not flipped
    Check with findFlip and flip if necessary
    
    @returns: A matrix of [[c, s],[-s, c]] that rotates a [1x2] point,
    which when multiplied to frame l1 produces l2
    

    """
#    x,y = (l1[0,:] - l1[1,:]).A1 # d1,d2 stand for directions
#    a,b = (l2[0,:] - l2[1,:]).A1
    # Compute cosine and sine
    #c = (x/b+y/a)*a*b/(a**2+b**2) #cosine
    #s = (-x/a+y/b)*a*b/(a**2+b**2) #sine
    #return matrix
#    theta = arctan(y/x) - arctan(b/a)
    c = cos(theta)
    s = sin(theta)
    return matrix([[c,s],[-s,c]])

    pass

def findTranslation(p1,p2):
    """ 
    Assumes that both frames have same angle and same flip
    
    @returns: The translation point which must be added to get p2 from
    p1

    """

    return p2 - p1

def findFlip(t1, t2): # Each arg is a array of coordinates
    """Check if the provided triangles are flipped

    @param t1: 2x3 matrix consisting of coordinates of triangle in
    frame1
    @param t2: 2x3 matrix consisting of coordinates of triangle in
    frame2
    
    @returns: True if the frames are flipped

    """
    det1 = l.det(concatenate((t1,ones((1,3)))))
    det2 = l.det(concatenate((t2,ones((1,3)))))
    return True if (det1/det2 < 0) else False
    pass

def d2_from_p(p):
    d2 = zeros((p.shape[0],p.shape[0]))
    for i in xrange(0, p.shape[0]):
        for j in xrange(0, i):
            d2[i,j] = l.norm(p[i,:] - p[j,:])**2
    return d2;

def lt(p):
    sum = 0;
    for i in range(0,p.shape[0]):
        for j in range(0,i):
            sum += (p[i,j])**2
    return sum

def read_from_file (fname, line1, line2, sep):
    f = open(fname,'r');
    pos = 0;
    a = []
    while pos < line1:
        f.readline()
        pos+=1
    while pos < line2:
        line = f.readline()
        pos+=1
        parts = line.split(sep)
        d=[]
        for i in parts:
            if i != '':
                d.append(float(i))
        a.append(d)
    return a

def similarize(di, do):
    
    pass

if __name__ == "__main__":
    f1 = sys.argv[1]
    f2 = sys.argv[2]
    n = int(sys.argv[3])
    fll = int(sys.argv[4])
    rot = float(sys.argv[5])
    
    inp = read_from_file (f1, 0, n, ' ')
    oup = read_from_file (f2,0, n, ',')
    # inp = read_from_file ('simul_work/input/'+f1, 0, n, ' ')
    # oup = read_from_file ('simul_work/output/'+f2,0, n, ', ')
    X = matrix(inp)
    X1 = matrix(oup)

    numpoints = n
    i = random.randint(0,numpoints)
    j = random.randint(0,numpoints)
    k = random.randint(0,numpoints)
    xi = X[i,:]
    xj = X[j,:]
    xk = X[k,:]
    x1i = X1[i,:]
    x1j = X1[j,:]
    x1k = X1[k,:]
    #Compute the necessary flip
    try:
      flip = findFlip(matrix([xi.A1,xj.A1,xk.A1]).T,matrix([x1i.A1,x1j.A1,x1k.A1]).T)
      print "#flip required" if flip else "flip not required"
    except:
	    pass
    if fll == 1:
        flipColumns(X1,0,1)
        x1i = X1[i,:]
        x1j = X1[j,:]
        x1k = X1[k,:]
    # Computation of rotation matrix x1 = r*x
    print '#',rot,rot/180*pi
    r_matrix = findRotation(rot/180*pi)
    print r_matrix
    X1 = X1*r_matrix
    print "#Rotating by ", arccos(r_matrix[0,0])*180/pi
    x1i = X1[i,:]
    fx = matrix([average(X[:,0]), average(X[:,1])])
    fx1 = matrix([average(X1[:,0]), average(X1[:,1])])
    translateTo = findTranslation(fx1,fx) # Add the required translation
    X1 = X1 + translateTo
    #do = smilarize(di, do)

    
    # print sqrt(di)
    # print sqrt(do)
    # print (sqrt(di)-sqrt(do))

    # print lt(di), lt(do), lt(di-do)
    # print "Actual loss", lt(sqrt(di)-sqrt(do))/lt(sqrt(di))
#     pylab.plot(X[:,0],X[:,1],'xb', label="Original points") #Plot of original content
#     pylab.plot(X1[:,0],X1[:,1],'r+', label="Calculated points") #Plot of calculated content
#     for i in xrange(0,X.shape[0]):
#         # pylab.plot(X[i,0], X[i,1],'ro')
#         # pylab.plot(X1[i,0], X1[i,1],'b+')
#         pylab.plot([X[i,0], X1[i,0]], [X[i,1], X1[i,1]], 'g-')
#         pylab.text(X[i,0], X[i,1], str(i+1))
# #    pylab.legend()
#     # pylab.xlim(-numpoints,numpoints)
#     # pylab.ylim(-numpoints,numpoints)
    di = d2_from_p(matrix(inp))
    do = d2_from_p(matrix(oup))
    print "#Actual loss", lt(sqrt(di)-sqrt(do))/lt(sqrt(di))
    # pylab.show()
    for i in xrange(0,X.shape[0]):
        print X[i,0], X[i,1], X1[i,0], X1[i,1], i+1
