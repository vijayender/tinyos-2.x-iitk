#!/bin/bash

dfil=simul_work/complete_output/'_'$1
ofil=simul_work/output/'_'$1
ifil=simul_work/input/'_'$2

l=`wc $ifil -l|cut -d' ' -f1`

echo $dfil $ofil $ifil $l

sed -n '
/distance estimates/,/^$/ {
     /distance estimates/ d
     s/DEBUG ([0-9]*): //gp
     /^$/ d
}
' $dfil | sed 's/^$/0,/' | tee simul_work/tempBuff

echo "x
l $l 2" > simul_work/inpFil
head -n $l simul_work/inpData >> simul_work/inpFil
echo "d
l $l $l" >> simul_work/inpFil

cat simul_work/tempBuff | while read line
do 
    p=`echo $line | grep -o ','| wc -l `;
    echo -n $line;
    for i in `seq 1 $((l-p-1))`;
    do 
	echo -n '0,'
    done
    echo 0
done >> simul_work/inpFil
:>simul_work/oup
~/wsn/mds/code/mycode/build/test_library $3 -i simul_work/inpFil -c simul_work/inpConf.basic_sa -o simul_work/oup -l basic_sa
echo "------Input------"
cat $ifil
echo "------Output------"
#cat simul_work/oup
head -n $((l+3)) simul_work/oup | tail -n $l | tee simul_work/oup_t
python process_loss.py $ifil simul_work/oup_t $l simul_work/inpFil