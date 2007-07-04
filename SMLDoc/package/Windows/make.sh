#!/bin/sh

set -e -x

if test "x${ISCC}" = "x"; then
    ISCC="c:/Program Files/Inno Setup 5/ISCC.exe"
fi
srcdir=../..
licensedir=$srcdir/package/MacOSX/Licenses

# -------- build SMLDoc

(cd $srcdir && ./configure && make)

# --------- setup distribution

mkdir -p dist/bin dist/doc
cp $srcdir/bin/smldoc.exe dist/bin/
cp $srcdir/LICENSE dist/doc/LICENSE
cp $licensedir/MLton-LICENSE dist/doc/LICENSE_MLton
cp $licensedir/gdtoa-LICENSE dist/doc/LICENSE_gdtoa
cp $licensedir/GMP-LICENSE dist/doc/LICENSE_GMP

# -------- make LICENSE file

(cd $licensedir && m4 -DSRCDIR=../../.. LICENSE.txt) > license.txt

# -------- make setup.exe

"$ISCC" smldoc.iss
