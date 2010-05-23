#!/bin/bash

mkdir -p simul_work/input
if [ -z $2 ]; then
	echo 'Usage: ./run.sh <output> <input>'
	exit 0
fi

ifil=simul_work/input/'_'$2

if [[ -e "$ifil" ]]; then
	echo Input file $ifil already exists.
else
	python  writePlot.py $ifil
fi
l=`wc $ifil -l|cut -d' ' -f1`
echo $l $((l+1))

fil='_'$1
echo working on $fil
mkdir -p simul_work/output
mkdir -p simul_work/complete_output
python simulate_wsn.py $ifil| tee simul_work/complete_output/$fil | tail -n $((l + 2)) | head -n -2 | cut -d':' -f2 | tee simul_work/output/$fil ;
grep 'Final loss' simul_work/complete_output/$fil
echo p "'simul_work/output/$fil' using 1:2 with lines, 'simul_work/output/$fil' using 1:2 with points, '$ifil' with lines, '$ifil' with points" | gnuplot -persist
python process_loss.py $ifil simul_work/output/$fil $l
