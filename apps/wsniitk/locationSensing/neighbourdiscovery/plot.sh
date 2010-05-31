#!/bin/bash

ifil=simul_work/input/'_'$2
fil='_'$1
echo Plot output file $fil
#echo "set term pngcairo font 'Arial,10' size 640,640; set output 'test.png' ; set xrange [-100:100];
echo "set term x11 ; set xrange [-100:100];
set yrange [-100:100];
p 'simul_work/output/$fil' using 1:2 with lines, 'simul_work/output/$fil' using 1:2 with points, '$ifil' with lines, '$ifil' with points" | gnuplot -persist
#(cat plot_points.gp ; cat simul_work/output/$fil) | gnuplot -persist
