#!/bin/sh
#
# mkdist.sh - make a distribution source package
#

set -e
LANG=C
export LANG

[ -n "$DESTDIR" ] || DESTDIR="."
[ -n "$REPOS" ] || REPOS="../../.."
[ -n "$VERSION" ] || VERSION=`cat ../../VERSION`
[ -n "$TAG" ] || TAG="smlsharp-$VERSION"
[ -n "$NAME" ] || NAME="smlsharp-$VERSION"

if [ -d "$DESTDIR/$NAME" ]; then
  echo "$0: $DESTDIR/$NAME already exists." 1>&2
  exit 1
fi

set -x

hg archive -r "$TAG" smlsharp
(
  cd "$DESTDIR/smlsharp"
  mv smlsharp "$NAME"
  cd "$NAME/SMLSharp"

  # ensure that configure is newer than configure.ac
  touch configure

  # set a static RELEASE_DATE
  RELEASE_DATE=`hg log -r "$TAG" \
    | awk '
        BEGIN {
          m["Jan"] = 1; m["Feb"] = 2; m["Mar"] = 3; m["Apr"] = 4;
          m["May"] = 5; m["Jun"] = 6; m["Jul"] = 7; m["Aug"] = 8;
          m["Sep"] = 9; m["Oct"] = 10; m["Nov"] = 11; m["Dec"] = 12;
        }
        /^date:/ { printf "%04d-%02d-%02d %s\n", $6, m[$3], $4, $5; }'`
  test -n "$RELEASE_DATE" || exit $?
  for i in \
    src/configuration/Configuration.sml.in
  do
    sed "s/%SNAPSHOT_DATE%/$RELEASE_DATE/" $i > $i.new || exit $?
    mv $i.new $i || exit $?
  done
) || exit $?

tar -C "$DESTDIR/smlsharp" -cf - "$NAME" | gzip -9 > "$NAME.tar.gz"
