set term epslatex color size 7.45143in,5.2161in
set output 'graph.tex'
set format "$%g$"
set xlabel 'distance'
set ylabel 'P\_dB'
set title 'Plot of $D$ vs P\_dB'
plot 'readings4-finaldata' using 9:(($3+$4)/2) with points pt 1 lc rgb 'red' noti