echo " plot '$1' using 1:2:(\$3-\$1):(\$4-\$2) with vectors ls 1 noti, \
  '' using 1:2:5 with labels" noti | gnuplot -persist