#!/bin/sh

BENCHMARKS=" \
        barnes_hut \
        boyer \
        coresml \
        count_graphs \
        fft \
        knuth_bendix \
        lexgen \
        life \
        logic \
        mandelbrot \
        mlyacc \
        nucleic \
        ray \
        simple \
        tsp \
        vliw \
"
# skipped because it runs infinite loop
#        ratio_regions \

MAXSECONDS=1800
INDEX_HTML=index.html

DONE=

for bench in ${BENCHMARKS};
do
    echo ${bench} 1>&2
    ./runbenchmark.sh -remote -parsable -d ${bench} ../benchmarks/${bench}/load.sml > log_${bench}.txt 2>&1 &
    BENCHPID=$!
    sleep ${MAXSECONDS} && ps | grep ${BENCHPID} && kill ${BENCHPID} &
    wait ${BENCHPID} # wait until the benchmark finishes or is killed.

    DONE="$DONE $bench"
    (for bench in $DONE
     do
       echo "name: $bench"
       cat "$bench/result.txt"
       echo "=="
     done) | awk -f format.awk > $INDEX_HTML
done
