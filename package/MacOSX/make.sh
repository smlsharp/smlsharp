#!/bin/sh

set -e -x

SMLSHARP_VERSION_MAJOR=0
SMLSHARP_VERSION_MINOR=30
SMLSHARP_VERSION_TENNY=

srcdir=../..

prefix=/usr/local
EXTRA_CONFIG_OPTS="--with-ffi-max-args=10 $@"

mlton_target_x86=i686-apple-darwin8
mlton_target_ppc=powerpc-apple-darwin8


SMLSHARP_VERSION="${SMLSHARP_VERSION_MAJOR}.${SMLSHARP_VERSION_MINOR}"
if [ "x$SMLSHARP_VERSION_TENNY" != "x" ]; then
  SMLSHARP_VERSION="${SMLSHARP_VERSION}.${SMLSHARP_VERSION_TENNY}"
fi

target=`$srcdir/config.guess | sed 's,[0-9.]*$,,'`

case "$target" in
  i?86*)
   target_x86="$target"
   target_ppc=`echo "$target" | sed 's,^[^-]*-,powerpc-,'`
   ;;
  powerpc*)
   target_x86=`echo "$target" | sed 's,^[^-]*-,powerpc-,'`
   target_ppc="$target"
   ;;
  *)
   echo "unknown platform: $target" 1>&2
   exit 1
   ;;
esac

chmod +x cc.sh cxx.sh

cc_sh="$PWD/cc.sh"
cxx_sh="$PWD/cxx.sh"

build () {
  (
    arch=$1
    target=$2
    mlton_target=$3
    rm -rf $arch
    mkdir $arch && cd $arch
    CFLAGS="-arch $arch -O" \
    CXXFLAGS="-arch $arch -O" \
    LDFLAGS="-arch $arch -static-libgcc" \
    LD="ld -arch $arch" \
      ../$srcdir/configure --prefix="$prefix" --target="$target" \
                           $EXTRA_CONFIG_OPTS
    make
    make mlton \
         CC="$cc_sh" \
         CXX="$cxx_sh" \
         MLTON_TARGET_PLATFORM="$mlton_target" \
         MLTON_FLAGS="-cc-opt -arch -cc-opt $arch -link-opt -arch -link-opt $arch -link-opt -static-libgcc"
    make install \
         MLTON_TARGET_PLATFORM="$mlton_target" \
         DESTDIR=$PWD/dest
  )
}

# -------- build for Intel

build i386 "$target_x86" "$mlton_target_x86"

# -------- make and setup documents

(cd i386 && make doc)

rm -rf local
mkdir -p local/share/doc/smlsharp/lib
for i in i386/src/lib/*/doc/api; do
  module=`expr "$i" : 'i386/src/lib/\\([^/]*\\)/doc/api'`
  dst="local/share/doc/smlsharp/lib/$module"
  mkdir "$dst"
  (cd "$i" && tar fc - .) | (cd "$dst" && tar fx -)
  if [ ! -f "$dst/index.html" ]; then
    echo "** no document in $dst."
    exit 1
  fi
done

# -------- build for PowerPC

(cd i386 && make distclean)
build ppc "$target_ppc" "$mlton_target_ppc"

# -------- make a universal binary

mkdir local/bin
mkdir local/lib
lipo -create i386/dest/usr/local/bin/smlsharp \
             ppc/dest/usr/local/bin/smlsharp \
     -output local/bin/smlsharp
lipo -create i386/dest/usr/local/bin/smlsharprun \
             ppc/dest/usr/local/bin/smlsharprun \
     -output local/bin/smlsharprun
lipo -create i386/dest/usr/local/lib/libsmlsharp.a \
             ppc/dest/usr/local/lib/libsmlsharp.a \
     -output local/lib/libsmlsharp.a

strip local/bin/smlsharp
strip local/bin/smlsharprun
ranlib local/lib/libsmlsharp.a

# -------- setup package structure

(cd i386/dest/usr && tar fc - local) | tar fxk -
rm -r local/lib/smlsharp/heap
mv local/bin/smlsharp2exe.sh local/bin/smlsharp2exe
chmod +x local/bin/smlsharp2exe

cp $srcdir/LICENSE local/share/doc/smlsharp/LICENSE
cp $srcdir/src/lib/SMLNJ/LICENSE local/share/doc/smlsharp/LICENSE_SMLNJ
cp Licenses/MLton-LICENSE local/share/doc/smlsharp/LICENSE_MLton
cp Licenses/gdtoa-LICENSE local/share/doc/smlsharp/LICENSE_gdtoa
cp Licenses/GMP-LICENSE local/share/doc/smlsharp/LICENSE_GMP

mkdir local/share/doc/smlsharp/samples
(cd $srcdir/sample && tar fc - `find . -type f \
                              | egrep -v 'CVS|\.svn|~$|\.in$'`) \
 | (cd local/share/doc/smlsharp/samples && tar fxk -)

sudo chown -R root:wheel local

# -------- create a package

rm -rf Resources
mkdir Resources
(cd Licenses && m4 LICENSE.html) > LICENSE.html
textutil -convert rtf LICENSE.html
cp LICENSE.rtf Resources/License.rtf

rm -f Info.plist
sed -e "s,@SMLSHARP_VERSION@,$SMLSHARP_VERSION,g" \
    -e "s,@SMLSHARP_VERSION_MAJOR@,$SMLSHARP_VERSION_MAJOR,g" \
    -e "s,@SMLSHARP_VERSION_MINOR@,$SMLSHARP_VERSION_MINOR,g" \
    Info.plist.in > Info.plist

rm -rf dist
mkdir dist
/Developer/Tools/packagemaker -build -ds -v \
    -p "dist/SML#-${SMLSHARP_VERSION}-Universal.pkg" \
    -f local \
    -r Resources \
    -i Info.plist \
    -d Description.plist 

# -------- create a diskimage

sudo chown -R root:wheel dist

rm -f "smlsharp-${SMLSHARP_VERSION}-Universal-Installer.dmg"
hdiutil create \
    -srcfolder dist \
    -volname "SML#-${SMLSHARP_VERSION}-Universal-Installer" \
    "smlsharp-${SMLSHARP_VERSION}-Universal-Installer"


# make.sh ends here.
