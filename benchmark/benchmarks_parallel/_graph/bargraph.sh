: ${linecolor1:=plum}
: ${linecolor2:=web-green}
: ${linecolor3:=orange}
: ${linecolor4:=light-red}
: ${linecolor5:=grey50}
: ${linecolor6:=brown}
: ${linecolor7:=blue}
: ${linecolor8:=khaki}
: ${xtics:=xtics}
: ${setkey:=key}
: ${xrange:=14.8}
: ${yrange:=3}
: ${xlabel='the number of workers'}
: ${ylabel='Execution time (sec.)'}
: ${bbox:='61 51 297 160'}
(
  cat <<-END
	set term postscript eps enhanced color font "Helvetica";
	set output "$1";
	set size 0.8, 0.45;
	set rmargin 10;
	set lmargin 10;
	set xlabel "$xlabel";
	set ylabel "$ylabel";
	set yrange [0.0:$yrange];
	set xrange [-1.5:$xrange];
	set xlabel font "Helvetica,14";
	set ylabel font "Helvetica,14";
	set tics font "Helvetica,14";
	set xlabel offset 0,-0;
	set ylabel offset -0,0;
	set style data boxes;
	set style fill solid border linecolor rgb "black";
	set boxwidth 0.22 absolute;
	set grid ytics noxtics;
	set xtics nomirror;
	set ytics nomirror;
	set grid ytics noxtics;
	set $xtics;
	set $setkey;
	END
  shift 1
  total=$(($#/3))
  seqoffset=-0.4
  cat <<-END
	plot \\
	"$2" using (0.22*(\$0+1)*($total+2)+$seqoffset):(0):xticlabels(1) \\
	with boxes title "", \\
	END
  if [ -s "$3" ]; then
    cat <<-END
	"$3" using ($seqoffset):(0):xticlabels(1) \\
	with boxes title "", \\
	END
  fi
  count=1
  while [ "$#" -ge 3 ]; do
    title=$1
    file1=$2
    file2=$3
    shift 3
    eval "lc=\$linecolor$count"
    barscenter="0.22*(\$0+1)*($total+2)+$seqoffset"
    baroffset="0.22*(($count-1)-$total/2+0.5)"
    cat <<-END
	"$file1" using ($barscenter+$baroffset):(\$2) \\
	with boxes \\
	linecolor rgb "${lc:-black}" \\
	linewidth 1 \\
	title "$title", \\
	"$file1" using ($barscenter+$baroffset):(\$2):(\$3):(\$4) \\
	with yerrorbars \\
	linecolor rgb "black" \\
	linewidth 1 \\
	pointtype 0 \\
	title "", \\
	END
    if [ -s "$file2" ]; then
      cat <<-END
	"$file2" using ($seqoffset+$baroffset):(\$2) \\
	with boxes \\
	linecolor rgb "${lc:-black}" \\
	linewidth 1 \\
	title "", \\
	"$file2" using ($seqoffset+$baroffset):(\$2):(\$3):(\$4) \\
	with yerrorbars \\
	linecolor rgb "black" \\
	linewidth 1 \\
	pointtype 0 \\
	title "", \\
	END
    fi
    count=$(($count+1))
  done
) | gnuplot
sed -i.orig "/^%%BoundingBox/s/.*/%%BoundingBox: $bbox/" "$1"
