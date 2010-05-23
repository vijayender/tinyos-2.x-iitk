from numpy import *
import sys
import numpy.linalg.linalg as l

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

if __name__ == "__main__":
    f1 = sys.argv[1]
    f2 = sys.argv[2]
    n = int(sys.argv[3])
    inp = read_from_file (f1, 0, n, ' ')
    oup = read_from_file (f2,0, n, ',')
    # inp = read_from_file ('simul_work/input/'+f1, 0, n, ' ')
    # oup = read_from_file ('simul_work/output/'+f2,0, n, ', ')
    di = d2_from_p(matrix(inp))
    do = d2_from_p(matrix(oup))
    print di
    print do
    print sqrt(di)-sqrt(do)

    print lt(di), lt(do), lt(di-do)
    print lt(di-do)/lt(di)
