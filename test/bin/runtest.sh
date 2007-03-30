#!/bin/sh

# A script for running through test
# $Id: runtest.sh,v 1.18 2007/01/26 09:33:15 kiyoshiy Exp $
#
# Example:
#   ./runtest.sh -html -usebasis -d D:/tmp/imltest coresml
# Do not use backslash as path separator.

USAGE="usage: $0 {-html|-text|-remote|-emulator|-usebasis}* [-d dir] testset"

if test $# -lt 2; then
    echo ${USAGE}
    exit 1
fi

###############################################################################

TESTSDIR=../tests/

###############################################################################

PRINTER=HTML
RUNTIME=ML
# use default prelude (non Basis)
PRELUDE=""

while true
do
    case $1 in 
    "-html")
	PRINTER="HTML"
	shift;;
    "-text")
	PRINTER="Text"
	shift;;
    "-remote")
	RUNTIME="Remote"
	shift;;
    "-emulator")
	RUNTIME="ML"
	shift;;
    "-minimum")
        PRELUDE=../../src/lib/minimum.sml
        shift;;
    "-usebasis")
	PRELUDE=../../src/lib/prelude.sml
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
    RESULTDIR=./$1
    ;;
esac

mkdir ${RESULTDIR}

TESTSET=$1
if test -z "${TESTSET}"; then
    echo ${USAGE}
    exit 1
fi

SOURCEDIR=${TESTSDIR}${TESTSET}/tests
EXPECTEDDIR=${TESTSDIR}${TESTSET}/outputs

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

script="OS.FileSys.chDir \"../../bin\"; ${MAIN}.main (\"imltest\", [\"${PRELUDE}\",\"${EXPECTEDDIR}\",\"${RESULTDIR}\",\"${SOURCEDIR}\"]);"

(cd ../driver/main && exec $SHELL ../../../mksmlheap --exec "$script")
