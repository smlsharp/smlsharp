#!/bin/sh

dir="$1"
LANG=C
export LANG

if [ -d "$dir/CVS" ]; then
  awk -vFS=/ '
    BEGIN {
      m["Jan"] = 1; m["Feb"] = 2; m["Mar"] = 3; m["Apr"] = 4;
      m["May"] = 5; m["Jun"] = 6; m["Jul"] = 7; m["Aug"] = 8;
      m["Sep"] = 9; m["Oct"] = 10; m["Nov"] = 11; m["Dec"] = 12;
    }
    {
      split($4, d, " *");
      printf "%04d-%02d-%02d %s\n", d[5], m[d[2]], d[3], d[4];
    }
  ' `find "$dir" -name 'CVS' -type d -print | sed 's,$,/Entries,'` \
  | sort -n -r \
  | head -n1
elif [ -d "$dir/.hg" ]; then
  (hg tip || date '+date: %a %b %d %H:%M:%S %Y %z') \
  | awk '
      BEGIN {
        m["Jan"] = 1; m["Feb"] = 2; m["Mar"] = 3; m["Apr"] = 4;
        m["May"] = 5; m["Jun"] = 6; m["Jul"] = 7; m["Aug"] = 8;
        m["Sep"] = 9; m["Oct"] = 10; m["Nov"] = 11; m["Dec"] = 12;
      }
      /^date:/ {
        printf "%04d-%02d-%02d %s\n", $6, m[$3], $4, $5;
      }
    '
else
  date '+%Y-%m-%d %H:%M:%S'
fi
