#!/bin/sh

for i
do
  name=`basename "$i" .smi`
  dstfile=`echo "$i" | sed y/./_/`.sml
  sed '
1i\
structure '"$name"'Source = \
struct \
val name = "('"$name"'.smi)" \
val body = "\\
s/[\\"]/\\&/g
s/^/\\/
s/$/\\n\\/
$a\
\\"\
val source = {name=name, body=body}\
end' "$i" > "$dstfile"
done
