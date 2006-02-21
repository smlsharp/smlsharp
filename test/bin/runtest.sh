#!/bin/sh

# A script for running through test
# $Id: runtest.sh,v 1.14 2005/06/15 04:27:12 kiyoshiy Exp $
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
PRELUDE=../../src/lib/preludes/preludes.sml

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
    "-usebasis")
	PRELUDE=../../src/lib/basis/main/basis.sml
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

echo "OS.FileSys.chDir \"../driver/main\"; CM.make(); OS.FileSys.chDir \"../../bin\"; ${MAIN}.main(\"imltest\", [\"${PRELUDE}\",\"${EXPECTEDDIR}\",\"${RESULTDIR}\",\"${SOURCEDIR}\"]);" | ${SML}

