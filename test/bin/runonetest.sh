#!/bin/sh

set +x

# A script for running one test
# $Id: runonetest.sh,v 1.9 2006/02/24 14:14:27 kiyoshiy Exp $
#
# Example:
#   ./runonetest.sh -html -usebasis -d D:/tmp/imltest coresml datatype001.sml
# Do not use backslash as path separator.

USAGE="usage: $0 {-html|-text|-remote|-emulator|-usebasis}* [-d dir] testset testfilename"

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
PRELUDE=../../src/lib/minimum.sml

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
    RESULTDIR=./$1
    ;;
esac

mkdir ${RESULTDIR}

TESTSET=$1
if test -z "${TESTSET}"; then
    echo ${USAGE}
    exit 1
fi
shift

TESTFILES=$*
if test -z "${TESTFILES}"; then
    echo ${USAGE}
    exit 1
fi

for TESTFILE in ${TESTFILES};do
    SOURCEPATHS="${SOURCEPATHS} ,\"${TESTSDIR}${TESTSET}/tests/${TESTFILE}\""
done
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

echo "OS.FileSys.chDir \"../driver/main\"; CM.make(); OS.FileSys.chDir \"../../bin\"; ${MAIN}.main(\"imltest\", [\"${PRELUDE}\",\"${EXPECTEDDIR}\",\"${RESULTDIR}\" ${SOURCEPATHS}]);" | ${SML}

