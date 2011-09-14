#!/bin/sh

for i
do
  name=`basename "$i" .smi`
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
end' "$i" > "$i".sml
done
