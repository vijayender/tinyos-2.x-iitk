from numpy import *
import sys,pylab

if __name__ == "__main__":
    fil = sys.argv[1]
    mat = genfromtxt(fil)
    mat2 = zeros((mat.shape[0]/30,mat.shape[1]+3))
    lens = [0.5,1,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10,10.5,11,11.5,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
    print "#sno toa rssi rssi lqi lqi retries retries bat1 bat2 std1 std2 len"
    for i in xrange(0,mat2.shape[0]):
        temp = mat[30*i:30*i+30]
        mat2[i][0] = i
        temp[:,1] = multiply(temp[:,1], (temp[:,1] != 255))
        mat2[i][1] = sum(temp[:,1])/ sum(temp[:,1] > 0)
        mat2[i][2] = average(temp[:,2])
        mat2[i][3] = average(temp[:,3])
        mat2[i][4] = average(temp[:,4])
        mat2[i][5] = average(temp[:,5])
        mat2[i][6] = average(temp[:,6])
        mat2[i][7] = average(temp[:,7])
        mat2[i][8] = average(temp[1:,8])
        mat2[i][9] = average(temp[:,9])
        mat2[i][10] = std(temp[:,2])
        mat2[i][11] = std(temp[:,3])
        mat2[i][12] = lens[i]
        for j in range(0,temp.shape[1]+3):
            print "%2.3g" % mat2[i][j],
        print
    



