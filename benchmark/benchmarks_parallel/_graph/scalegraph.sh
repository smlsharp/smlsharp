#pointtype1=2
#pointtype2=4
#pointtype3=6
#pointtype4=8
#pointtype5=10
#pointtype6=12
: ${linecolor1:=plum}
: ${linecolor2:=web-green}
: ${linecolor3:=orange}
: ${linecolor4:=light-red}
: ${linecolor5:=grey50}
: ${linecolor6:=brown}
: ${linecolor7:=blue}
: ${linecolor8:=khaki}
: ${linewidth7:=8}
: ${xlabel='the number of workers'}
: ${ylabel='Speed-up'}
: ${bbox:='102 50 356 299'}
(
  cat <<-END
	set term postscript eps enhanced color font "Helvetica";
	set output "$1";
	set xlabel "$xlabel";
	set ylabel "$ylabel";
	set xrange [0.0:64.0];
	set yrange [0.0:64.0];
	set xlabel font "Helvetica,16";
	set ylabel font "Helvetica,16";
	set tics font "Helvetica,16";
	set key font "Helvetica,16";
	set xlabel offset 0,-0.2;
	set ylabel offset -0.4,0;
	set grid ytics;
	set size ratio 1.0;
	set key left top;
	set xtics 8;
	set ytics 8;
	plot \\
	END
  shift 1
  count=1
  while [ "$#" -gt 0 ]; do
    title=$1
    file=$2
    shift 2
    eval "pt=\$pointtype$count"
    eval "lw=\$linewidth$count"
    eval "lc=\$linecolor$count"
    count=$(($count+1))
    cat <<-END
	"$file" using(\$1):(\$2) with linespoints \\
	linetype 1 \\
	pointtype ${pt:-5} \\
	linewidth ${lw:-5} \\
	linecolor rgb "${lc:-black}"\\
	pointsize 1.5 \\
	title "$title", \\
	END
  done
  cat <<-END
	x dashtype 2 linecolor rgb "black" notitle
	END
) | gnuplot
sed -i.orig "/^%%BoundingBox/s/.*/%%BoundingBox: $bbox/" "$1"
