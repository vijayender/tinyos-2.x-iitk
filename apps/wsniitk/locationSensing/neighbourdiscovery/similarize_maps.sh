#!/bin/bash

dfil=simul_work/complete_output/'_'$1
ofil=simul_work/output/'_'$1
ifil=simul_work/input/'_'$2

l=`wc $ifil -l|cut -d' ' -f1`

mkdir -p simul_work/pl/
echo $dfil $ofil $ifil $l
f=simul_work/pl/$3
:>$f
echo \# `grep Final $dfil | cut -d's' -f3` | tee $f
python process_loss3.py $ifil $ofil $l $4 $5 | tee -a $f
cat $f
echo " plot '$f' using 1:2:(\$3-\$1):(\$4-\$2) with vectors ls 1 noti, \
  '$f' using 1:2:5 with labels" noti | gnuplot -persist
# echo " plot '$f' using 1:2 with linespoints ls 1 ti 'Actual points', '$f' using 3:4 with linespoints ls 2 ti 'Computed points',\
#   '$f' using 1:2:5 with labels, '$f' using 3:4:5 with labels" | gnuplot -persist