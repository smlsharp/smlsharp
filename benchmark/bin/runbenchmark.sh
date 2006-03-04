#!/bin/sh

set +x

# A script for running benchmark
# $Id: runbenchmark.sh,v 1.8 2006/02/24 14:14:25 kiyoshiy Exp $
#
# Example:
#   ./runonebenchmark.sh -html -usebasis -d D:/tmp/imlbench boyer/load.sml
# Do not use backslash as path separator.

USAGE=\
"usage: $0 \
{-html} \
{-remote|-emulator} \
{-usebasis} \
[-d dir] \
filename ..."

if test $# -lt 1; then
    echo ${USAGE}
    exit 1
fi

###############################################################################

#BENCHDIR=../benchmarks/

###############################################################################

PRINTER=HTML
RUNTIME=Remote
# use default prelude (non Basis)
PRELUDE=../../src/lib/minimum.sml

while true
do
    case $1 in 
    "-html")
	PRINTER="HTML"
	shift;;
#    "-text")
#	PRINTER="Text"
#	shift;;
    "-remote")
	RUNTIME="Remote"
	shift;;
    "-emulator")
	RUNTIME="Emulator"
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

case `uname` in
CYGWIN*) 
	HEAPIMAGE_SUFFIX=.x86-win32 
        SML=sml.bat 
	;; 
*) 
	HEAPIMAGE_SUFFIX= 
        SML=sml 
esac 

###############################################################################

echo "OS.FileSys.chDir \"../driver/main\"; \
    CM.make(); \
    OS.FileSys.chDir \"../../bin\"; \
    ${MAIN}.main \
        (\"imlbench\", [\"${PRELUDE}\",\"${RESULTDIR}\" ${SOURCEPATHS}]);"\
 | ${SML}

