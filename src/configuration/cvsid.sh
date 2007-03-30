#!/bin/sh
#
# cvsid.sh
#
# $Id: $
#

[ "$#" = "1" ] || exit 1

files=`find $1 \( -name '*.sml' \
                  -o -name '*.sig' \
                  -o -name '*.ppg' \
                  -o -name '*.in' \
                  -o -name '*.cc' \
                  -o -name '*.hh' \
               \) -print \
       | sed '\,/\.cm/,d;\,/CM/,d'`

[ "x$files" = "x" ] && exit 1

d='[0-9]'

sed -e '/\$Id: .*\$/!d' \
    -e 's,^.*\$Id: *\(.*\) *\$.*$,\1,' \
    -e "s,^.*\($d$d$d$d/$d$d/$d$d $d$d:$d$d:$d$d\).*$,\1," \
    -e 'y,/,-,' \
    $files \
| sort -n -r \
| head -n1
