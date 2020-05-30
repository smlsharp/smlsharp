export LD_LIBRARY_PATH=$PWD/massivethreads/lib
: ${TIME:=/usr/bin/time}
: ${ncores:='1 2 4 8 16 24 32 40 48 56 64'}
times=10
fib_size=40
fib_cutoff=10
nqueen_size=14
nqueen_cutoff=7
mandelbrot_size=2048
mandelbrot_cutoff=16
cilksort_size=4194304
cilksort_cutoff=32
cilksortpair_size=1048576
cilksortpair_cutoff=32

param_fib='11 40 10'
param_nqueen='11 14 7'
param_mandelbrot='11 2048 16'
param_cilksort='11 4194304 32'
param_cilksortpair='11 1048576 32'

for bench in fib nqueen mandelbrot cilksort cilksortpair; do
  eval "size=\$${bench}_size"
  eval "cutoff=\$${bench}_cutoff"
  param="$times $size $cutoff"
  paramseq="$times $size $size"

  if [ -x "${bench}/${bench}_c_seq" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      MYTH_NUM_WORKERS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_c_seq $paramseq 2>&1
    done
  fi

  if [ -x "${bench}/${bench}_c_myth" ]; then
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      MYTH_NUM_WORKERS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_c_myth $param 2>&1
    done
  fi
  
  if [ -x "${bench}/${bench}_smlsharp_seq" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      MYTH_NUM_WORKERS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_smlsharp_seq $paramseq 2>&1
    done
  fi

  if [ -x "${bench}/${bench}_smlsharp_myth" ]; then
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      MYTH_NUM_WORKERS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_smlsharp_myth $param 2>&1
    done
  fi

  if [ -x "${bench}/${bench}_ghc_par" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_ghc_par +RTS -N$i -RTS $paramseq 2>&1
    done
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_ghc_par +RTS -N$i -RTS $param 2>&1
    done
  fi
  
  if [ -x "${bench}/${bench}_manticore_ptuple" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_manticore_ptuple -p $i $paramseq 2>&1
    done
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_manticore_ptuple -p $i $param 2>&1
    done
  fi

  if [ -x "${bench}/${bench}_maple_par" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_maple_par @mpl procs $i -- $paramseq 2>&1
    done
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_maple_par @mpl procs $i set-affinity -- $param 2>&1
    done
  fi
 
  if [ -x "${bench}/${bench}_go_ref" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      GOMAXPROCS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_go_ref $paramseq 2>&1
    done
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      GOMAXPROCS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_go_ref $param 2>&1
    done
  fi

  if [ -x "${bench}/${bench}_go_value" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      GOMAXPROCS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_go_value $paramseq 2>&1
    done
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      GOMAXPROCS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_go_value $param 2>&1
    done
  fi

  b=`echo "$bench" | perl -ne 'print ucfirst'`
  if [ -f "${bench}/${b}JavaSeq.class" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      ${TIME} -f ' real: %e\n maxrss: %M' \
      java -classpath ${bench} ${b}JavaSeq $paramseq 2>&1
    done
  fi

  b=`echo "$bench" | perl -ne 'print ucfirst'`
  if [ -f "${bench}/${b}JavaForkJoin.class" ]; then
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      NPROCS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      java -classpath ${bench} ${b}JavaForkJoin $param 2>&1
    done
  fi

done
