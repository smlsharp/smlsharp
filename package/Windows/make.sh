#!/bin/sh

set -e -x

SMLSHARP_VERSION=0.30

ISCC="c:/Program Files/Inno Setup 5/ISCC.exe"
srcdir=../..
licensedir=$srcdir/package/MacOSX/Licenses

prefix=c:/smlsharp
EXTRA_CONFIG_OPTS="--with-ffi-max-args=10 $@"

# -------- build SML/NJ version and mlton_config

if [ ! -d "build/src/compiler/mlton_self" ]; then
  rm -rf build
  mkdir build
  (
    cd build
    CFLAGS=-O \
    CXXFLAGS=-O \
      ../$srcdir/configure --prefix="$prefix" $EXTRA_CONFIG_OPTS
    make
    cd src/compiler && make mlton_config
  )
fi

if [ ! -f "build/src/compiler/mlton_self/MLTON_COMPILED_G" ]; then
  echo '** copy build/src/compiler/mlton_self and execute "make mlton_g" on another host.'
  exit 1
fi

# -------- build MLton version

(cd build/src/compiler && make mlton)
(cd build && make install DESTDIR="$PWD/dist" prefix=)

# -------- build and install SMLFormat, SMLDoc and SMLUnit

(
  cd ../../SMLFormat
  make clean
  ./configure
  make
  cd ../package/Windows/build
  cp "../../../SMLFormat/bin/smlformat.exe" "$PWD/dist/bin"
  (cd ../../../SMLFormat && \
   tar cf - `find smlformatlib.sml formatlib/main -type f -print \
             | egrep -v '\.svn|CVS|\.cvsignore|\~\$|\.in\$|Makefile|CM|\.cm'`) \
  | (cd dist/lib/smlsharp && mkdir SMLFormat && cd SMLFormat && tar xf -)
)

(
  cd ../../SMLDoc
  make clean
  ./configure
  make
  cd ../package/Windows/build
  cp "../../../SMLDoc/bin/smldoc.exe" "$PWD/dist/bin"
)

(
  #cd ../..
  (cd ../../SMLUnit && \
   tar cf - `find smlunitlib.sml src/main -type f -print \
             | egrep -v '\.svn|CVS|\.cvsignore|\~\$|\.in\$|Makefile|CM|\.cm'`) \
  | (cd build/dist/lib/smlsharp && mkdir SMLUnit && cd SMLUnit && tar xf -)
  # smlunitlib.sml src/main
)

echo 'use "./SMLFormat/smlformatlib.sml";' > build/dist/lib/smlsharp/smlformatlib.sml
echo 'use "./SMLUnit/smlunitlib.sml";' > build/dist/lib/smlsharp/smlunitlib.sml

# -------- make and setup documents

(cd build && make doc)

rm -rf dist
mkdir -p dist/doc/lib
for i in build/src/lib/*/doc/api; do
  module=`expr "$i" : 'build/src/lib/\\([^/]*\\)/doc/api'`
  dst="dist/doc/lib/$module"
  mkdir "$dst"
  (cd "$i" && tar fc - .) | (cd "$dst" && tar fx -)
  if [ ! -f "$dst/index.html" ]; then
    echo "** no document in $dst."
    exit 1
  fi
done

# --------- setup distribution

(cd build && tar fc - dist) | tar fxk -
rm -r dist/lib/smlsharp/heap

cp $srcdir/LICENSE dist/doc/LICENSE
cp $srcdir/src/lib/SMLNJ/LICENSE dist/doc/LICENSE_SMLNJ
cp $licensedir/MLton-LICENSE dist/doc/LICENSE_MLton
cp $licensedir/gdtoa-LICENSE dist/doc/LICENSE_gdtoa
cp $licensedir/GMP-LICENSE dist/doc/LICENSE_GMP

mkdir dist/samples
(cd $srcdir/sample && tar fc - `find . -type f \
                                | egrep -v 'CVS|\.svn|~$|\.in$'`) \
 | (cd dist/samples && tar fxk -)

mkdir dist/samples/hello
cp files/hello_world.sml dist/samples/hello

# -------- make LICENSE file

(cd $licensedir && m4 -DSRCDIR=../../.. LICENSE.txt) > license.txt

# -------- make setup.exe

"$ISCC" smlsharp.iss
