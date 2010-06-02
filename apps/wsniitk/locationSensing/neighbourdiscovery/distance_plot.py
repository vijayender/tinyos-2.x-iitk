# Simulation 5 motes, with some intial locations
import numpy as np
import wsnModel as w
import pylab
import numpy.linalg.linalg as l
import sys

if __name__ == "__main__":
    w.load_d_model ('distances_average.txt')
    x = np.arange(0,50,0.01)
    sys.stderr.write( str(len(x))+ " points\n" )

    y_pdb = w.pdb_from_d(x)
    y_ed = w.ed_from_d(x)
    t = x
    y_mdl2 = np.floor(-1.3295e-6*t**5 + 0.00021291*t**4 - 0.013029*t**3 + 0.37402*t**2 - 5.1057*t + 40.086)
    y_mdl3 = -1.3295e-6*t**5 + 0.00021291*t**4 - 0.013029*t**3 + 0.37402*t**2 - 5.1057*t + 40.086
    curr=y_mdl2[0];
    start=x[0];
    x_new = []
    y_new = []
    for j,i in zip(x,y_mdl2):
        if i!= curr:
            x_new.append(curr)
            y_new.append((start+j)/2)
            curr = i
            start = j

    def find_d(k):
        for i,j in zip(x_new,y_new):
            if i == np.floor(k):
                return j
        return 0

    #print x_new, y_new
    y_m_mdl = 50-11*np.log(2*x+1)
    #x_re = ((np.exp((50.0-y_ed)/11) - 1)/2)
    x_re = [find_d(i) for i in y_ed]
    # pylab.plot(x,y_pdb,'r-')

    x_re2 = [ j-i for (i,j) in zip(x,x_re)]
    pylab.plot(x,y_ed,'b-',label="Experimental ed")
    #pylab.plot(x,y_m_mdl,'g-',label="log model")
    pylab.plot(x,y_mdl2,'r-',label="5th degree linear approximation")
    pylab.plot(y_new,x_new,'r*',label='points of distances table')
    pylab.plot(x,x_re2,'k-',label="Error Plot after reconstruction")
    pylab.plot(x,x_re,'r-',label="Recorrected distances")
    pylab.plot(x,x,'r-',label="Ideal reconstruction")
    # pylab.legend()
    pylab.axis([0,50,-10,50])
    pylab.show()

    
    # x_new is ed
    # y_new is distance
    # 40 -->>> 7 (34 points) linear
    # 0.01 -->>> 47.265 (34 points)
    # print x_new[0], x_new[len(x_new)-1], len(x_new)
    # print y_new[0], y_new[len(y_new)-1], len(y_new)
    print [int(round(i)) for i in y_new]
    #print "#error"
    #for (xx,yy) in zip(x,x_re2):
    #    print xx, yy
