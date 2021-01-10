all: \
scale-fib_40_10.pdf \
time-fib_40_10.pdf \
rss-fib_40_10.pdf \
scale-nqueen_14_7.pdf \
time-nqueen_14_7.pdf \
rss-nqueen_14_7.pdf \
scale-mandelbrot_2048_16.pdf \
time-mandelbrot_2048_16.pdf \
rss-mandelbrot_2048_16.pdf \
scale-cilksort_4194304_32.pdf \
time-cilksort_4194304_32.pdf \
rss-cilksort_4194304_32.pdf

.DELETE_ON_ERROR:

LOGS = $(wildcard LOG*)
bench.txt: $(LOGS) log.rb
	ruby log.rb $(LOGS) > $@

bench.sqlite3: bench.txt schema.sql
	-rm -f $@
	sqlite3 -init schema.sql $@ '.import bench.txt bench'

scale-%.txt: bench.sqlite3
	sqlite3 -batch -separator '	' bench.sqlite3 \
	"select cores, time, min_time, max_time from scale where bench||'_'||lang||'_'||impl||'_'||size||'_'||cutoff='$*'" > $@

time-%.txt: bench.sqlite3
	sqlite3 -batch -separator '	' bench.sqlite3 \
	"select case when size = cutoff then 'seq' else cores end, time, min_time, max_time from avg where bench||'_'||lang||'_'||impl||'_'||size||'_'||cutoff='$*' and cores in (1,2,4,8,16,32,64)" > $@

rss-%.txt: bench.sqlite3
	sqlite3 -batch -separator '	' bench.sqlite3 \
	"select case when size = cutoff then 'seq' else cores end, maxrss/1024.0/1024, maxrss/1024.0/1024, maxrss/1024.0/1024 from bench where bench||'_'||lang||'_'||impl||'_'||size||'_'||cutoff='$*' and iter = 1 and cores in (1,2,4,8,16,32,64)" > $@

%.pdf: %.eps
	epstopdf $<

scale-fib_40_10.eps: \
 scalegraph.sh \
 scale-fib_c_myth_40_10.txt \
 scale-fib_java_forkjoin_40_10.txt \
 scale-fib_go_value_40_10.txt \
 scale-fib_ghc_par_40_10.txt \
 scale-fib_manticore_ptuple_40_10.txt \
 scale-fib_maple_par_40_10.txt \
 scale-fib_smlsharp_myth_40_10.txt
	sh scalegraph.sh $@ \
	 'C' scale-fib_c_myth_40_10.txt \
	 'Java' scale-fib_java_forkjoin_40_10.txt \
	 'Go' scale-fib_go_value_40_10.txt \
	 'Haskell' scale-fib_ghc_par_40_10.txt \
	 'Manticore' scale-fib_manticore_ptuple_40_10.txt \
	 'MaPLe' scale-fib_maple_par_40_10.txt \
	 'SML#' scale-fib_smlsharp_myth_40_10.txt

time-fib_40_10.eps: \
 bargraph.sh \
 time-fib_c_myth_40_10.txt \
 time-fib_c_seq_40_40.txt \
 time-fib_java_forkjoin_40_10.txt \
 time-fib_java_seq_40_40.txt \
 time-fib_go_value_40_10.txt \
 time-fib_go_value_40_40.txt \
 time-fib_ghc_par_40_10.txt \
 time-fib_ghc_par_40_40.txt \
 time-fib_manticore_ptuple_40_10.txt \
 time-fib_manticore_ptuple_40_40.txt \
 time-fib_maple_par_40_10.txt \
 time-fib_maple_par_40_40.txt \
 time-fib_smlsharp_myth_40_10.txt \
 time-fib_smlsharp_seq_40_40.txt
	ylabel='average task time (sec.)' yrange=3 \
	sh bargraph.sh $@ \
	 'C' time-fib_c_myth_40_10.txt time-fib_c_seq_40_40.txt \
	 'Java' time-fib_java_forkjoin_40_10.txt time-fib_java_seq_40_40.txt \
	 'Go' time-fib_go_value_40_10.txt time-fib_go_value_40_40.txt \
	 'Haskell' time-fib_ghc_par_40_10.txt time-fib_ghc_par_40_40.txt \
	 'Manticore' time-fib_manticore_ptuple_40_10.txt time-fib_manticore_ptuple_40_40.txt \
	 'MaPLe' time-fib_maple_par_40_10.txt time-fib_maple_par_40_40.txt \
	 'SML#' time-fib_smlsharp_myth_40_10.txt time-fib_smlsharp_seq_40_40.txt

rss-fib_40_10.eps: \
 bargraph.sh \
 rss-fib_c_myth_40_10.txt \
 rss-fib_c_seq_40_40.txt \
 rss-fib_java_forkjoin_40_10.txt \
 rss-fib_java_seq_40_40.txt \
 rss-fib_go_value_40_10.txt \
 rss-fib_go_value_40_40.txt \
 rss-fib_ghc_par_40_10.txt \
 rss-fib_ghc_par_40_40.txt \
 rss-fib_manticore_ptuple_40_10.txt \
 rss-fib_manticore_ptuple_40_40.txt \
 rss-fib_maple_par_40_10.txt \
 rss-fib_maple_par_40_40.txt \
 rss-fib_smlsharp_myth_40_10.txt \
 rss-fib_smlsharp_seq_40_40.txt
	ylabel='MaxRSS (GB)' yrange=1 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-fib_c_myth_40_10.txt rss-fib_c_seq_40_40.txt \
	 'Java' rss-fib_java_forkjoin_40_10.txt rss-fib_java_seq_40_40.txt \
	 'Go' rss-fib_go_value_40_10.txt rss-fib_go_value_40_40.txt \
	 'Haskell' rss-fib_ghc_par_40_10.txt rss-fib_ghc_par_40_40.txt \
	 'Manticore' rss-fib_manticore_ptuple_40_10.txt rss-fib_manticore_ptuple_40_40.txt \
	 'MaPLe' rss-fib_maple_par_40_10.txt rss-fib_maple_par_40_40.txt \
	 'SML#' rss-fib_smlsharp_myth_40_10.txt rss-fib_smlsharp_seq_40_40.txt

scale-nqueen_14_7.eps: \
 scalegraph.sh \
 scale-nqueen_c_myth_14_7.txt \
 scale-nqueen_java_forkjoin_14_7.txt \
 scale-nqueen_go_ref_14_7.txt \
 scale-nqueen_go_value_14_7.txt \
 scale-nqueen_ghc_par_14_7.txt \
 scale-nqueen_manticore_ptuple_14_7.txt \
 scale-nqueen_maple_par_14_7.txt \
 scale-nqueen_smlsharp_myth_14_7.txt
	sh scalegraph.sh $@ \
	 'C' scale-nqueen_c_myth_14_7.txt \
	 'Java' scale-nqueen_java_forkjoin_14_7.txt \
	 'Go' scale-nqueen_go_ref_14_7.txt \
	 'Haskell' scale-nqueen_ghc_par_14_7.txt \
	 'Manticore' scale-nqueen_manticore_ptuple_14_7.txt \
	 'MaPLe' scale-nqueen_maple_par_14_7.txt \
	 'SML#' scale-nqueen_smlsharp_myth_14_7.txt \
	 'Go(value)' scale-nqueen_go_value_14_7.txt

time-nqueen_14_7.eps: \
 bargraph.sh \
 time-nqueen_c_myth_14_7.txt \
 time-nqueen_c_seq_14_14.txt \
 time-nqueen_java_forkjoin_14_7.txt \
 time-nqueen_java_seq_14_14.txt \
 time-nqueen_go_ref_14_7.txt \
 time-nqueen_go_ref_14_14.txt \
 time-nqueen_ghc_par_14_7.txt \
 time-nqueen_ghc_par_14_14.txt \
 time-nqueen_manticore_ptuple_14_7.txt \
 time-nqueen_manticore_ptuple_14_14.txt \
 time-nqueen_maple_par_14_7.txt \
 time-nqueen_maple_par_14_14.txt \
 time-nqueen_smlsharp_myth_14_7.txt \
 time-nqueen_smlsharp_seq_14_14.txt
	ylabel='average task time (sec.)' yrange=2.5 \
	sh bargraph.sh $@ \
	 'C' time-nqueen_c_myth_14_7.txt time-nqueen_c_seq_14_14.txt \
	 'Java' time-nqueen_java_forkjoin_14_7.txt time-nqueen_java_seq_14_14.txt \
	 'Go' time-nqueen_go_ref_14_7.txt time-nqueen_go_ref_14_14.txt \
	 'Haskell' time-nqueen_ghc_par_14_7.txt time-nqueen_ghc_par_14_14.txt \
	 'Manticore' time-nqueen_manticore_ptuple_14_7.txt time-nqueen_manticore_ptuple_14_14.txt \
	 'MaPLe' time-nqueen_maple_par_14_7.txt time-nqueen_maple_par_14_14.txt \
	 'SML#' time-nqueen_smlsharp_myth_14_7.txt time-nqueen_smlsharp_seq_14_14.txt

rss-nqueen_14_7.eps: \
 bargraph.sh \
 rss-nqueen_c_myth_14_7.txt \
 rss-nqueen_c_seq_14_14.txt \
 rss-nqueen_java_forkjoin_14_7.txt \
 rss-nqueen_java_seq_14_14.txt \
 rss-nqueen_go_ref_14_7.txt \
 rss-nqueen_go_ref_14_14.txt \
 rss-nqueen_ghc_par_14_7.txt \
 rss-nqueen_ghc_par_14_14.txt \
 rss-nqueen_manticore_ptuple_14_7.txt \
 rss-nqueen_manticore_ptuple_14_14.txt \
 rss-nqueen_maple_par_14_7.txt \
 rss-nqueen_maple_par_14_14.txt \
 rss-nqueen_smlsharp_myth_14_7.txt \
 rss-nqueen_smlsharp_seq_14_14.txt
	ylabel='MaxRSS (GB)' yrange=1 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-nqueen_c_myth_14_7.txt rss-nqueen_c_seq_14_14.txt \
	 'Java' rss-nqueen_java_forkjoin_14_7.txt rss-nqueen_java_seq_14_14.txt \
	 'Go' rss-nqueen_go_ref_14_7.txt rss-nqueen_go_ref_14_14.txt \
	 'Haskell' rss-nqueen_ghc_par_14_7.txt rss-nqueen_ghc_par_14_14.txt \
	 'Manticore' rss-nqueen_manticore_ptuple_14_7.txt rss-nqueen_manticore_ptuple_14_14.txt \
	 'MaPLe' rss-nqueen_maple_par_14_7.txt rss-nqueen_maple_par_14_14.txt \
	 'SML#' rss-nqueen_smlsharp_myth_14_7.txt rss-nqueen_smlsharp_seq_14_14.txt

scale-mandelbrot_2048_16.eps: \
 scalegraph.sh \
 scale-mandelbrot_c_myth_2048_16.txt \
 scale-mandelbrot_java_forkjoin_2048_16.txt \
 scale-mandelbrot_go_value_2048_16.txt \
 scale-mandelbrot_ghc_par_2048_16.txt \
 scale-mandelbrot_manticore_ptuple_2048_16.txt \
 scale-mandelbrot_maple_par_2048_16.txt \
 scale-mandelbrot_smlsharp_myth_2048_16.txt
	sh scalegraph.sh $@ \
	 'C' scale-mandelbrot_c_myth_2048_16.txt \
	 'Java' scale-mandelbrot_java_forkjoin_2048_16.txt \
	 'Go' scale-mandelbrot_go_value_2048_16.txt \
	 'Haskell' scale-mandelbrot_ghc_par_2048_16.txt \
	 'Manticore' scale-mandelbrot_manticore_ptuple_2048_16.txt \
	 'MaPLe' scale-mandelbrot_maple_par_2048_16.txt \
	 'SML#' scale-mandelbrot_smlsharp_myth_2048_16.txt

time-mandelbrot_2048_16.eps: \
 bargraph.sh \
 time-mandelbrot_c_myth_2048_16.txt \
 time-mandelbrot_c_seq_2048_2048.txt \
 time-mandelbrot_java_forkjoin_2048_16.txt \
 time-mandelbrot_java_seq_2048_2048.txt \
 time-mandelbrot_go_value_2048_16.txt \
 time-mandelbrot_go_value_2048_2048.txt \
 time-mandelbrot_ghc_par_2048_16.txt \
 time-mandelbrot_ghc_par_2048_2048.txt \
 time-mandelbrot_manticore_ptuple_2048_16.txt \
 time-mandelbrot_manticore_ptuple_2048_2048.txt \
 time-mandelbrot_maple_par_2048_16.txt \
 time-mandelbrot_maple_par_2048_2048.txt \
 time-mandelbrot_smlsharp_myth_2048_16.txt \
 time-mandelbrot_smlsharp_seq_2048_2048.txt
	ylabel='average task time (sec.)' yrange=10 \
	sh bargraph.sh $@ \
	 'C' time-mandelbrot_c_myth_2048_16.txt time-mandelbrot_c_seq_2048_2048.txt \
	 'Java' time-mandelbrot_java_forkjoin_2048_16.txt time-mandelbrot_java_seq_2048_2048.txt \
	 'Go' time-mandelbrot_go_value_2048_16.txt time-mandelbrot_go_value_2048_2048.txt \
	 'Haskell' time-mandelbrot_ghc_par_2048_16.txt time-mandelbrot_ghc_par_2048_2048.txt \
	 'Manticore' time-mandelbrot_manticore_ptuple_2048_16.txt time-mandelbrot_manticore_ptuple_2048_2048.txt \
	 'MaPLe' time-mandelbrot_maple_par_2048_16.txt time-mandelbrot_maple_par_2048_2048.txt \
	 'SML#' time-mandelbrot_smlsharp_myth_2048_16.txt time-mandelbrot_smlsharp_seq_2048_2048.txt

rss-mandelbrot_2048_16.eps: \
 bargraph.sh \
 rss-mandelbrot_c_myth_2048_16.txt \
 rss-mandelbrot_c_seq_2048_2048.txt \
 rss-mandelbrot_java_forkjoin_2048_16.txt \
 rss-mandelbrot_java_seq_2048_2048.txt \
 rss-mandelbrot_go_value_2048_16.txt \
 rss-mandelbrot_go_value_2048_2048.txt \
 rss-mandelbrot_ghc_par_2048_16.txt \
 rss-mandelbrot_ghc_par_2048_2048.txt \
 rss-mandelbrot_manticore_ptuple_2048_16.txt \
 rss-mandelbrot_manticore_ptuple_2048_2048.txt \
 rss-mandelbrot_maple_par_2048_16.txt \
 rss-mandelbrot_maple_par_2048_2048.txt \
 rss-mandelbrot_smlsharp_myth_2048_16.txt \
 rss-mandelbrot_smlsharp_seq_2048_2048.txt
	ylabel='MaxRSS (GB)' yrange=1 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-mandelbrot_c_myth_2048_16.txt rss-mandelbrot_c_seq_2048_2048.txt \
	 'Java' rss-mandelbrot_java_forkjoin_2048_16.txt rss-mandelbrot_java_seq_2048_2048.txt \
	 'Go' rss-mandelbrot_go_value_2048_16.txt rss-mandelbrot_go_value_2048_2048.txt \
	 'Haskell' rss-mandelbrot_ghc_par_2048_16.txt rss-mandelbrot_ghc_par_2048_2048.txt \
	 'Manticore' rss-mandelbrot_manticore_ptuple_2048_16.txt rss-mandelbrot_manticore_ptuple_2048_2048.txt \
	 'MaPLe' rss-mandelbrot_maple_par_2048_16.txt rss-mandelbrot_maple_par_2048_2048.txt \
	 'SML#' rss-mandelbrot_smlsharp_myth_2048_16.txt rss-mandelbrot_smlsharp_seq_2048_2048.txt

scale-cilksort_4194304_32.eps: \
 scalegraph.sh \
 scale-cilksort_c_myth_4194304_32.txt \
 scale-cilksort_java_forkjoin_4194304_32.txt \
 scale-cilksort_go_value_4194304_32.txt \
 scale-cilksort_ghc_par_4194304_32.txt \
 scale-cilksort_manticore_ptuple_4194304_32.txt \
 scale-cilksort_maple_par_4194304_32.txt \
 scale-cilksort_smlsharp_myth_4194304_32.txt
	sh scalegraph.sh $@ \
	 'C' scale-cilksort_c_myth_4194304_32.txt \
	 'Java' scale-cilksort_java_forkjoin_4194304_32.txt \
	 'Go' scale-cilksort_go_value_4194304_32.txt \
	 'Haskell' scale-cilksort_ghc_par_4194304_32.txt \
	 'Manticore' scale-cilksort_manticore_ptuple_4194304_32.txt \
	 'MaPLe' scale-cilksort_maple_par_4194304_32.txt \
	 'SML#' scale-cilksort_smlsharp_myth_4194304_32.txt

time-cilksort_4194304_32.eps: \
 bargraph.sh \
 time-cilksort_c_myth_4194304_32.txt \
 time-cilksort_c_seq_4194304_4194304.txt \
 time-cilksort_java_forkjoin_4194304_32.txt \
 time-cilksort_java_seq_4194304_4194304.txt \
 time-cilksort_go_value_4194304_32.txt \
 time-cilksort_go_value_4194304_4194304.txt \
 time-cilksort_ghc_par_4194304_32.txt \
 time-cilksort_ghc_par_4194304_4194304.txt \
 time-cilksort_manticore_ptuple_4194304_32.txt \
 time-cilksort_manticore_ptuple_4194304_4194304.txt \
 time-cilksort_maple_par_4194304_32.txt \
 time-cilksort_maple_par_4194304_4194304.txt \
 time-cilksort_smlsharp_myth_4194304_32.txt \
 time-cilksort_smlsharp_seq_4194304_4194304.txt
	ylabel='average task time (sec.)' yrange=5 \
	sh bargraph.sh $@ \
	 'C' time-cilksort_c_myth_4194304_32.txt time-cilksort_c_seq_4194304_4194304.txt \
	 'Java' time-cilksort_java_forkjoin_4194304_32.txt time-cilksort_java_seq_4194304_4194304.txt \
	 'Go' time-cilksort_go_value_4194304_32.txt time-cilksort_go_value_4194304_4194304.txt \
	 'Haskell' time-cilksort_ghc_par_4194304_32.txt time-cilksort_ghc_par_4194304_4194304.txt \
	 'Manticore' time-cilksort_manticore_ptuple_4194304_32.txt time-cilksort_manticore_ptuple_4194304_4194304.txt \
	 'MaPLe' time-cilksort_maple_par_4194304_32.txt time-cilksort_maple_par_4194304_4194304.txt \
	 'SML#' time-cilksort_smlsharp_myth_4194304_32.txt time-cilksort_smlsharp_seq_4194304_4194304.txt

rss-cilksort_4194304_32.eps: \
 bargraph.sh \
 rss-cilksort_c_myth_4194304_32.txt \
 rss-cilksort_c_seq_4194304_4194304.txt \
 rss-cilksort_java_forkjoin_4194304_32.txt \
 rss-cilksort_java_seq_4194304_4194304.txt \
 rss-cilksort_go_value_4194304_32.txt \
 rss-cilksort_go_value_4194304_4194304.txt \
 rss-cilksort_ghc_par_4194304_32.txt \
 rss-cilksort_ghc_par_4194304_4194304.txt \
 rss-cilksort_manticore_ptuple_4194304_32.txt \
 rss-cilksort_manticore_ptuple_4194304_4194304.txt \
 rss-cilksort_maple_par_4194304_32.txt \
 rss-cilksort_maple_par_4194304_4194304.txt \
 rss-cilksort_smlsharp_myth_4194304_32.txt \
 rss-cilksort_smlsharp_seq_4194304_4194304.txt
	ylabel='MaxRSS (GB)' yrange=2 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-cilksort_c_myth_4194304_32.txt rss-cilksort_c_seq_4194304_4194304.txt \
	 'Java' rss-cilksort_java_forkjoin_4194304_32.txt rss-cilksort_java_seq_4194304_4194304.txt \
	 'Go' rss-cilksort_go_value_4194304_32.txt rss-cilksort_go_value_4194304_4194304.txt \
	 'Haskell' rss-cilksort_ghc_par_4194304_32.txt rss-cilksort_ghc_par_4194304_4194304.txt \
	 'Manticore' rss-cilksort_manticore_ptuple_4194304_32.txt rss-cilksort_manticore_ptuple_4194304_4194304.txt \
	 'MaPLe' rss-cilksort_maple_par_4194304_32.txt rss-cilksort_maple_par_4194304_4194304.txt \
	 'SML#' rss-cilksort_smlsharp_myth_4194304_32.txt rss-cilksort_smlsharp_seq_4194304_4194304.txt








smlsharp35: \
 scale35-fib_40_10.pdf \
 time35-fib_40_10.pdf \
 rss35-fib_40_10.pdf \
 scale35-nqueen_14_7.pdf \
 time35-nqueen_14_7.pdf \
 rss35-nqueen_14_7.pdf \
 scale35-mandelbrot_2048_16.pdf \
 time35-mandelbrot_2048_16.pdf \
 rss35-mandelbrot_2048_16.pdf \
 scale35-cilksort_4194304_32.pdf \
 time35-cilksort_4194304_32.pdf \
 rss35-cilksort_4194304_32.pdf

scale35-fib_40_10.eps: \
 scalegraph.sh \
 scale-fib_c_myth_40_10.txt \
 scale-fib_smlsharp_myth_40_10.txt \
 scale-fib_smlsharp35_myth_40_10.txt
	sh scalegraph.sh $@ \
	 'C' scale-fib_c_myth_40_10.txt \
	 'SML#-3.5' scale-fib_smlsharp35_myth_40_10.txt \
	 'SML#' scale-fib_smlsharp_myth_40_10.txt

time35-fib_40_10.eps: \
 bargraph.sh \
 time-fib_c_myth_40_10.txt \
 time-fib_c_seq_40_40.txt \
 time-fib_smlsharp_myth_40_10.txt \
 time-fib_smlsharp_seq_40_40.txt \
 time-fib_smlsharp35_myth_40_10.txt \
 time-fib_smlsharp35_seq_40_40.txt
	ylabel='average task time (sec.)' xrange=9 yrange=2 \
	sh bargraph.sh $@ \
	 'C' time-fib_c_myth_40_10.txt time-fib_c_seq_40_40.txt \
	 'SML#-3.5' time-fib_smlsharp35_myth_40_10.txt time-fib_smlsharp35_seq_40_40.txt \
	 'SML#' time-fib_smlsharp_myth_40_10.txt time-fib_smlsharp_seq_40_40.txt

rss35-fib_40_10.eps: \
 bargraph.sh \
 rss-fib_c_myth_40_10.txt \
 rss-fib_c_seq_40_40.txt \
 rss-fib_smlsharp_myth_40_10.txt \
 rss-fib_smlsharp_seq_40_40.txt \
 rss-fib_smlsharp35_myth_40_10.txt \
 rss-fib_smlsharp35_seq_40_40.txt
	ylabel='MaxRSS (GB)' xrange=9 yrange=0.6 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-fib_c_myth_40_10.txt rss-fib_c_seq_40_40.txt \
	 'SML#-3.5' rss-fib_smlsharp35_myth_40_10.txt rss-fib_smlsharp35_seq_40_40.txt \
	 'SML#' rss-fib_smlsharp_myth_40_10.txt rss-fib_smlsharp_seq_40_40.txt

scale35-nqueen_14_7.eps: \
 scalegraph.sh \
 scale-nqueen_c_myth_14_7.txt \
 scale-nqueen_smlsharp_myth_14_7.txt \
 scale-nqueen_smlsharp35_myth_14_7.txt
	sh scalegraph.sh $@ \
	 'C' scale-nqueen_c_myth_14_7.txt \
	 'SML#-3.5' scale-nqueen_smlsharp35_myth_14_7.txt \
	 'SML#' scale-nqueen_smlsharp_myth_14_7.txt

time35-nqueen_14_7.eps: \
 bargraph.sh \
 time-nqueen_c_myth_14_7.txt \
 time-nqueen_c_seq_14_14.txt \
 time-nqueen_smlsharp_myth_14_7.txt \
 time-nqueen_smlsharp_seq_14_14.txt \
 time-nqueen_smlsharp35_myth_14_7.txt \
 time-nqueen_smlsharp35_seq_14_14.txt
	ylabel='average task time (sec.)' xrange=9 yrange=2.5 \
	sh bargraph.sh $@ \
	 'C' time-nqueen_c_myth_14_7.txt time-nqueen_c_seq_14_14.txt \
	 'SML#-3.5' time-nqueen_smlsharp35_myth_14_7.txt time-nqueen_smlsharp35_seq_14_14.txt \
	 'SML#' time-nqueen_smlsharp_myth_14_7.txt time-nqueen_smlsharp_seq_14_14.txt

rss35-nqueen_14_7.eps: \
 bargraph.sh \
 rss-nqueen_c_myth_14_7.txt \
 rss-nqueen_c_seq_14_14.txt \
 rss-nqueen_smlsharp_myth_14_7.txt \
 rss-nqueen_smlsharp_seq_14_14.txt \
 rss-nqueen_smlsharp35_myth_14_7.txt \
 rss-nqueen_smlsharp35_seq_14_14.txt
	ylabel='MaxRSS (GB)' xrange=9 yrange=0.6 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-nqueen_c_myth_14_7.txt rss-nqueen_c_seq_14_14.txt \
	 'SML#-3.5' rss-nqueen_smlsharp35_myth_14_7.txt rss-nqueen_smlsharp35_seq_14_14.txt \
	 'SML#' rss-nqueen_smlsharp_myth_14_7.txt rss-nqueen_smlsharp_seq_14_14.txt

scale35-mandelbrot_2048_16.eps: \
 scalegraph.sh \
 scale-mandelbrot_c_myth_2048_16.txt \
 scale-mandelbrot_smlsharp_myth_2048_16.txt \
 scale-mandelbrot_smlsharp35_myth_2048_16.txt
	sh scalegraph.sh $@ \
	 'C' scale-mandelbrot_c_myth_2048_16.txt \
	 'SML#-3.5' scale-mandelbrot_smlsharp35_myth_2048_16.txt \
	 'SML#' scale-mandelbrot_smlsharp_myth_2048_16.txt

time35-mandelbrot_2048_16.eps: \
 bargraph.sh \
 time-mandelbrot_c_myth_2048_16.txt \
 time-mandelbrot_c_seq_2048_2048.txt \
 time-mandelbrot_smlsharp_myth_2048_16.txt \
 time-mandelbrot_smlsharp_seq_2048_2048.txt \
 time-mandelbrot_smlsharp35_myth_2048_16.txt \
 time-mandelbrot_smlsharp35_seq_2048_2048.txt
	ylabel='average task time (sec.)' xrange=9 yrange=8 \
	sh bargraph.sh $@ \
	 'C' time-mandelbrot_c_myth_2048_16.txt time-mandelbrot_c_seq_2048_2048.txt \
	 'SML#-3.5' time-mandelbrot_smlsharp35_myth_2048_16.txt time-mandelbrot_smlsharp35_seq_2048_2048.txt \
	 'SML#' time-mandelbrot_smlsharp_myth_2048_16.txt time-mandelbrot_smlsharp_seq_2048_2048.txt

rss35-mandelbrot_2048_16.eps: \
 bargraph.sh \
 rss-mandelbrot_c_myth_2048_16.txt \
 rss-mandelbrot_c_seq_2048_2048.txt \
 rss-mandelbrot_smlsharp_myth_2048_16.txt \
 rss-mandelbrot_smlsharp_seq_2048_2048.txt \
 rss-mandelbrot_smlsharp35_myth_2048_16.txt \
 rss-mandelbrot_smlsharp35_seq_2048_2048.txt
	ylabel='MaxRSS (GB)' xrange=9 yrange=0.6 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-mandelbrot_c_myth_2048_16.txt rss-mandelbrot_c_seq_2048_2048.txt \
	 'SML#-3.5' rss-mandelbrot_smlsharp35_myth_2048_16.txt rss-mandelbrot_smlsharp35_seq_2048_2048.txt \
	 'SML#' rss-mandelbrot_smlsharp_myth_2048_16.txt rss-mandelbrot_smlsharp_seq_2048_2048.txt

scale35-cilksort_4194304_32.eps: \
 scalegraph.sh \
 scale-cilksort_c_myth_4194304_32.txt \
 scale-cilksort_smlsharp_myth_4194304_32.txt \
 scale-cilksort_smlsharp35_myth_4194304_32.txt
	sh scalegraph.sh $@ \
	 'C' scale-cilksort_c_myth_4194304_32.txt \
	 'SML#-3.5' scale-cilksort_smlsharp35_myth_4194304_32.txt \
	 'SML#' scale-cilksort_smlsharp_myth_4194304_32.txt

time35-cilksort_4194304_32.eps: \
 bargraph.sh \
 time-cilksort_c_myth_4194304_32.txt \
 time-cilksort_c_seq_4194304_4194304.txt \
 time-cilksort_smlsharp_myth_4194304_32.txt \
 time-cilksort_smlsharp_seq_4194304_4194304.txt \
 time-cilksort_smlsharp35_myth_4194304_32.txt \
 time-cilksort_smlsharp35_seq_4194304_4194304.txt
	ylabel='average task time (sec.)' xrange=9 yrange=4 \
	sh bargraph.sh $@ \
	 'C' time-cilksort_c_myth_4194304_32.txt time-cilksort_c_seq_4194304_4194304.txt \
	 'SML#-3.5' time-cilksort_smlsharp35_myth_4194304_32.txt time-cilksort_smlsharp35_seq_4194304_4194304.txt \
	 'SML#' time-cilksort_smlsharp_myth_4194304_32.txt time-cilksort_smlsharp_seq_4194304_4194304.txt

rss35-cilksort_4194304_32.eps: \
 bargraph.sh \
 rss-cilksort_c_myth_4194304_32.txt \
 rss-cilksort_c_seq_4194304_4194304.txt \
 rss-cilksort_smlsharp_myth_4194304_32.txt \
 rss-cilksort_smlsharp_seq_4194304_4194304.txt \
 rss-cilksort_smlsharp35_myth_4194304_32.txt \
 rss-cilksort_smlsharp35_seq_4194304_4194304.txt
	ylabel='MaxRSS (GB)' xrange=9 yrange=0.6 setkey=key \
	sh bargraph.sh $@ \
	 'C' rss-cilksort_c_myth_4194304_32.txt rss-cilksort_c_seq_4194304_4194304.txt \
	 'SML#-3.5' rss-cilksort_smlsharp35_myth_4194304_32.txt rss-cilksort_smlsharp35_seq_4194304_4194304.txt \
	 'SML#' rss-cilksort_smlsharp_myth_4194304_32.txt rss-cilksort_smlsharp_seq_4194304_4194304.txt
