#!/bin/sh

set +x

# A script for running benchmark
# $Id: runbenchmark.sh,v 1.11 2008/01/16 07:28:45 kiyoshiy Exp $
#
# Example:
#   ./runonebenchmark.sh -html -usebasis -d D:/tmp/imlbench boyer/load.sml
# Do not use backslash as path separator.
# 
#  If you configured SML# at a directory other than iml3/SMLSharp/, you have to
# specify TOP_BUILDDIR environment.
#   $ env TOP_BUILDDIR=/home/yamato/iml3/SMLSharp/release ./runbenchmark.sh ...

USAGE=\
"usage: $0 \
{-html} \
{-remote|-emulator} \
{-minimum|-usebasis|} \
[-d dir] \
filename ..."

if test $# -lt 1; then
    echo ${USAGE}
    exit 1
fi

###############################################################################

TOP_BUILDDIR=${TOP_BUILDDIR:-${PWD}/../../}
#BENCHDIR=../benchmarks/

###############################################################################

PRINTER=HTML
RUNTIME=Remote
# use default prelude (non Basis)
PRELUDE=""

while true
do
    case $1 in 
    "-html")
	PRINTER="HTML"
	shift;;
    "-parsable")
        PRINTER="Parsable"
        shift;;
#    "-text")
#	PRINTER="Text"
#	shift;;
    "-remote")
	RUNTIME="Remote"
	shift;;
    "-native")
        PRELUDE=../../src/lib/ntprelude.smc
	RUNTIME="Native"
	shift;;
    "-emulator")
	RUNTIME="Emulator"
	shift;;
    "-minimum")
        PRELUDE=../../src/lib/minimum.sml
        shift;;
    "-usebasis")
	PRELUDE=../../src/lib/basis.sml
	shift;;
    *)
	break;;
    esac
done

MAIN="${PRINTER}${RUNTIME}Main"


case $1 in
"-d")
    shift
    RESULTDIR=$1
    shift
    ;;
*)
    RESULTDIR=.
    ;;
esac

mkdir -p ${RESULTDIR}

BENCHFILES=$*
if test -z "${BENCHFILES}"; then
    echo ${USAGE}
    exit 1
fi

#for BENCHFILE in ${BENCHFILES};do
#    SOURCEPATHS="${SOURCEPATHS} ,\"${BENCHDIR}/${BENCHFILE}\""
#done

for BENCHFILE in ${BENCHFILES};do
    SOURCEPATHS="${SOURCEPATHS} ,\"${BENCHFILE}\""
done

###############################################################################

script="OS.FileSys.chDir \"../../bin\"; \
        ${MAIN}.main \
          (\"imlbench\", [\"${PRELUDE}\",\"${RESULTDIR}\" ${SOURCEPATHS}]);"

(cd ../driver/main && exec $SHELL ${TOP_BUILDDIR}/mksmlheap --exec "$script")
