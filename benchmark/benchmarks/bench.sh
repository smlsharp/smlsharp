#!/bin/sh
: ${TIME:=/usr/bin/time}
tmp=`mktemp`
trap 'exit 127' INT QUIT STOP
trap 'rm -f "$tmp"' EXIT

for doit in */doit; do
  echo -
  echo " bench: ${doit%/doit}"
  echo ' results:'
  for i in 1 2 3 4 5 6 7 8 9 10; do
    SMLSHARP_HEAPSIZE=32M:2G \
    $TIME -f 'real: %e\nmaxrss: %M' $doit > /dev/null 2> "$tmp"
    echo '  -'
    sed 's/^ */   /' "$tmp"
  done
done
