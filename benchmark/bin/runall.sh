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

echo '<HTML><BODY>' > ${INDEX_HTML}

for bench in ${BENCHMARKS};
do
    echo "<A HREF='${bench}/index.html'>${bench}</A><BR>" >> ${INDEX_HTML}

    echo ${bench}
    ./runbenchmark.sh -remote -html -d ${bench} ../benchmarks/${bench}/load.sml > log_${bench}.txt 2>&1 &
    BENCHPID=$!
    sleep ${MAXSECONDS} && ps | grep ${BENCHPID} && kill ${BENCHPID} &
    wait ${BENCHPID} # wait until the benchmark finishes or is killed.
done

echo '</BODY></HTML>' >> ${INDEX_HTML}
