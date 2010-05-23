#!/bin/bash

ifil=simul_work/input/'_'$2
fil='_'$1
echo Plot output file $fil
echo " set term x11; set xrange [-40:40];
set yrange [-40:40];
p 'simul_work/output/$fil' using 1:2 with lines, 'simul_work/output/$fil' using 1:2 with points, '$ifil' with lines, '$ifil' with points" | gnuplot -persist
#(cat plot_points.gp ; cat simul_work/output/$fil) | gnuplot -persist
