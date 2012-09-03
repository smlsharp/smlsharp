#!/bin/sh

for f in *.sml;
do 
    output=../outputs/${f%%.sml}.out
    if [ ! -e ${output} ];
    then
        sml.bat < ${f} | \
        # "tail +2" skips the first line.
        tail +2 | \
        grep -v '^\\- *$' | \
        cat > ${output}
        echo ${output}
    fi
done
