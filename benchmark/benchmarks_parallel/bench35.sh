export LD_LIBRARY_PATH=$PWD/massivethreads/lib
export SMLSHARP_HEAPSIZE=4M:2G
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

  if [ -x "${bench}/${bench}_smlsharp35_seq" ]; then
    for i in 1; do
      echo -
      echo " ncores: $i"
      MYTH_NUM_WORKERS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_smlsharp35_seq $paramseq 2>&1
    done
  fi

  if [ -x "${bench}/${bench}_smlsharp35_myth" ]; then
    for i in $ncores; do
      echo -
      echo " ncores: $i"
      MYTH_NUM_WORKERS=$i \
      ${TIME} -f ' real: %e\n maxrss: %M' \
      ${bench}/${bench}_smlsharp35_myth $param 2>&1
    done
  fi

done
