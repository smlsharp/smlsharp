# -*- Autoconf -*-

AC_PREREQ(2.61)
AC_INIT(smlsharp)
AC_CONFIG_SRCDIR([src/compiler/toplevel2/main/Top.sml])
AC_CONFIG_HEADER([config.h])

AC_CANONICAL_TARGET
AC_ARG_PROGRAM

AC_DEFINE_UNQUOTED(SMLSHARP_PLATFORM, "${target_cpu}-${target_os}",
                   [platform identifier])
SMLSHARP_PLATFORM="${target_cpu}-${target_os}"
AC_SUBST(SMLSHARP_PLATFORM)

# Checks for programs.
AC_PROG_CC
AC_LANG(C)

AC_PROG_MAKE_SET
AC_PROG_INSTALL
AC_PATH_PROG(FIND, find)
AC_PROG_RANLIB
AC_CHECK_TOOL(LD, ld)
AC_CHECK_TOOL(AR, ar)
#AC_CHECK_TOOL(WINDRES, windres)
#AC_PATH_PROG(DOXYGEN, doxygen)

RUNTIME_DEFS=
AC_SUBST(RUNTIME_DEFS)

LIBEXT='a'
DLLEXT='so'
ASMEXT='s'
OBJEXT='o'
EXEEXT=
A_OUT='a.out'
RDYNAMIC_LDFLAGS=
RUNLOOP_DLDFLAGS=
AC_SUBST(LIBEXT)
AC_SUBST(DLLEXT)
AC_SUBST(ASMEXT)
AC_SUBST(OBJEXT)
AC_SUBST(EXEEXT)
AC_SUBST(A_OUT)
AC_SUBST(RDYNAMIC_LDFLAGS)
AC_SUBST(RUNLOOP_DLDFLAGS)

case "$host_os" in
#  *cygwin*)
#    DLLEXT='dll'
#    EXEEXT=.exe
#    A_OUT=a.exe
    #AC_CHECK_TOOL(DLLTOOL, dlltool, :)
    #AC_PATH_PROG(CYGPATH, cygpath)
    #if test "x$CYGPATH" = "x"; then
    #  case "$host_os" in
    #    *cygwin*)
    #      AC_MSG_ERROR([cygpath is not found.])
    #      ;;
    #  esac
    #fi
    #AC_SUBST(CYGPATH)
    #if test "x$WINDRES" != "x"; then
    #  RESOURCE_TYPE=rc
    #fi
    #AC_SUBST(RESOURCE_TYPE)

  *mingw*)
    DLLEXT='dll'
    EXEEXT=.exe
    A_OUT=a.exe
    RDYNAMIC_LDFLAGS='-Wl,-Wl\\,--export-all-symbols -Wl,-Wl\\,--out-implib=src/compiler/smlsharp.lib'
    RUNLOOP_DLDFLAGS='-shared -Wl,--enable-auto-import,--enable-stdcall-fixup'
    ;;
  *darwin*)
    LIBEXT='a'
    DLLEXT='dylib'
    RDYNAMIC_LDFLAGS=
    RUNLOOP_DLDFLAGS='-dynamiclib -Wl,-undefined,dynamic_lookup,-flat_namespace'
    ;;
  *linux*)
    RDYNAMIC_LDFLAGS=-Wl,-rdynamic
    RUNLOOP_DLDFLAGS=-shared
    ;;
esac

if test "x$RDYNAMIC_LDFLAGS" = "x" && test "x$RUNLOOP_DLDFLAGS" = "x"; then
  AC_MSG_WARN(settings for dynamic linking is not specified. interactive mode may not work.)
  RDYNAMIC_LDFLAGS=
  RUNLOOP_DLDFLAGS=-shared
fi

# FIXME: check how to make a static library

# -------- Checks for SML compiler --------

SML_PATH=$PATH
SMLSHARP=./minismlsharp
AC_SUBST(SMLSHARP)
SMLSHARP_DEP=minismlsharp
AC_SUBST(SMLSHARP_DEP)
STAGE0_COMPILER=
AC_SUBST(STAGE0_COMPILER)
INCLUDE_STAGE0='# '
AC_SUBST(INCLUDE_STAGE0)

AC_ARG_WITH(smlsharp,
AS_HELP_STRING([--with-smlsharp=DIR],
               [bootstrap with existing smlsharp command]),
[ SML_PATH="$withval/bin:$SML_PATH" ])

AC_ARG_WITH(stage0,
AS_HELP_STRING([--with-stage0={smlnj|mlton}],
               [bootstrap with other SML compiler]))

if test "${with_smlsharp+set}" = set && test "x${with_smlsharp}" != "xno"; then
  AC_PATH_PROG(SMLSHARP, smlsharp, [], $SML_PATH)
  if test "x$SMLSHARP" = "x"; then
    AC_MSG_ERROR([smlsharp command does not found])
  fi
  SMLSHARP_DEP=
elif test "${with_stage0+set}" = set && test "x${with_smlsharp}" != "xno"; then
  check_mlton=yes
  check_smlnj=yes
  test "x$with_stage0" = "xmlton" && check_smlnj=no
  test "x$with_stage0" = "xsmlnj" && check_mlton=no

  if test "x$check_smlnj" = "xyes"; then
    AC_PATH_PROG(SMLNJ, sml, [], $SML_PATH)
    AC_SUBST(SMLNJ)
    if test "x$SMLNJ" = "x"; then
      SMLBAT=
      case "$host_os" in
      *mingw*)
        AC_PATH_PROG(SMLBAT, sml.bat, [], $SML_PATH)
        if test "x$SMLBAT" != "x"; then
          # convert drive letter from MSYS to DOS
          SMLBAT=`echo "$SMLBAT" | sed 's,^/\\([[a-zA-Z]]\\)/,\\1:/,;s,//*,/,g'`
          test -f "$SMLBAT" && SMLNJ='cmd /c "'"$SMLBAT"'"'
        fi
        ;;
      esac
    fi
    if test "x$SMLNJ" != "x"; then
      AC_MSG_CHECKING([for suffix of heap image])
      (mkdir conftest && cd conftest \
       && echo 'SMLofNJ.exportFn("conftest",fn _=>OS.Process.success);' \
       | $SMLNJ > /dev/null 2>&1)
      SMLNJ_HEAP_SUFFIX=`(cd conftest && echo *) | sed 's,^conftest\\.,,'`
      rm -rf conftest
      AC_MSG_RESULT($SMLNJ_HEAP_SUFFIX)
      AC_SUBST(SMLNJ_HEAP_SUFFIX)
      if test "x$SMLNJ_HEAP_SUFFIX" = "x" || test "x$SMLNJ_HEAP_SUFFIX" = "x*"
      then
        AC_MSG_ERROR("failed.")
      fi
      STAGE0_COMPILER=SMLNJ
    fi
  fi

  if test "x$check_mlton" = "xyes" && test "x$STAGE0_COMPILER" = "x"; then
    AC_PATH_PROG(MLTON, mlton, [], $SML_PATH)
    AC_SUBST(MLTON)
    test "x$MLTON" = "x" || STAGE0_COMPILER=MLTON
  fi

  if test "x$STAGE0_COMPILER" = "x"; then
    AC_MSG_ERROR([no Standard ML compiler is found])
  fi

  INCLUDE_STAGE0=
  SMLSHARP=stage0/smlsharp
  SMLSHARP_DEP=
fi

INCLUDE_FASTBUILD='#'
AC_SUBST(INCLUDE_FASTBUILD)
AC_ARG_ENABLE(fast-build,
AS_HELP_STRING([--enable-fast-build],
               [reuse pre-compiled assembly file to build SML#]),
[ test "x$enableval" = "xyes" && INCLUDE_FASTBUILD= ])

# -------- Checks for multithreading --------

AC_ARG_ENABLE(thread,
AS_HELP_STRING([--enable-thread],
               [enable experimental native thread support [[default=no]]]),
[ RUNTIME_DEFS="$RUNTIME_DEFS -DMULTITHREAD" ],
[])

# -------- Checks for native compile --------

case "$target" in
  i[[3456]]86-*-linux*) NATIVE_TARGET=x86-linux ;;
  x86_64-*-linux*) NATIVE_TARGET=x86-linux ;;
  i[[3456]]86-*-darwin*) NATIVE_TARGET=x86-darwin ;;
  i[[3456]]86-*-mingw*) NATIVE_TARGET=x86-mingw ;;
  i[[3456]]86-*-cygwin*) NATIVE_TARGET=x86-cygwin ;;
  *) NATIVE_TARGET= ;;
esac
case "$target" in
  i[[3456]]86-*|x86_64-*)
    RUNTIME_DEFS="$RUNTIME_DEFS -DHOST_CPU_i386 -DMAXALIGN=16"
    ;;
esac

AC_MSG_CHECKING([for native code generation target])

AC_ARG_ENABLE(native,
AS_HELP_STRING([--enable-native],
               [enable native code generation [[default=yes]]]),
[ case "x$enable_native" in
  x|xyes)
    if test "x$NATIVE_TARGET" = "x"; then
      AC_MSG_RESULT([unsupported.])
      AC_MSG_ERROR([specify target platform by --enable-native=<TARGET>.])
    fi ;;
  xno)
    NATIVE_TARGET= ;;
  *)
    NATIVE_TARGET="$enable_native" ;;
  esac ])

if test "x$NATIVE_TARGET" = "x"; then
  AC_MSG_RESULT([unsupported.])
  AC_MSG_ERROR([specify target platform by --enable-native=<TARGET>.])
else
  AC_MSG_RESULT([$NATIVE_TARGET])
fi
AC_SUBST(NATIVE_TARGET)

# -------- Extra switches for developers --------

SNAPDATE_RULE_='# '
if test -f "${srcdir}/../.hg/dirstate"; then
  (test ! -f ${srcdir}/RELEASE_DATE \
   || grep '[[a-f]]' ${srcdir}/RELEASE_DATE > /dev/null 2>&1) \
  && SNAPDATE_RULE_=
fi
AC_SUBST(SNAPDATE_RULE_)

AC_ARG_ENABLE(heapimpl,
AS_HELP_STRING([--enable-heapimpl],
               [select heap management algorithm [[default=bitmap]]]),
[ HEAPIMPL=$enable_heapimpl ],
[ HEAPIMPL=bitmap ])

if test "x$NATIVE_TARGET" = "x"; then
  :
else
  AC_MSG_CHECKING([for heap management algorithm])
  AC_MSG_RESULT([$HEAPIMPL])
fi
if test -f "$srcdir/src/runtime/heap_$HEAPIMPL.c"; then
  :
else
  AC_MSG_ERROR([heap implementation \`$HEAPIMPL' is not available.])
fi
AC_SUBST(HEAPIMPL)

# -------- Checks for Libraries --------

AC_CHECK_LIB(m, sqrt)
AC_CHECK_LIB(socket, socket)

AC_CHECK_LIB(gmp, __gmpz_init)
if test "x$ac_cv_lib_gmp___gmpz_init" = "xno"; then
    AC_MSG_ERROR([GMP library is not found.])
fi

AC_CHECK_LIB(dl, dlopen)
#AC_CHECK_LIB(dld, shl_load)   # for HP-UX

## cygwin has dlopen in libcygwin.dll.
if test "x$ac_cv_lib_dl_dlopen" = "xno"; then
  case "$target_os" in
  *cygwin*)
    AC_SEARCH_LIBS(dlopen, [dl],
    [ ac_cv_lib_dl_dlopen=yes; echo "#define HAVE_LIBDL 1" >> confdefs.h ])
    ;;
  *)
    ;;
  esac
fi

AC_ARG_WITH(rt,
AS_HELP_STRING([--with-rt],[try to use clock_gettime for benchmark]),
[ AC_CHECK_LIB(rt, clock_gettime) ])

if test "x$enable_thread" = "xyes"; then
  AC_CHECK_LIB(pthread, pthread_create)
  if test "x$ac_cv_lib_pthread_pthread_create" = "xno"; then
      AC_MSG_ERROR([pthread library is not found.])
  fi
fi

case "$target_os" in
  *mingw*)
    AC_DEFINE(MINGW32, 1, [Define if your system is Windows])
    ;;
esac

# FIXME: check for method for dynamic linking.

# -------- Checks for Header Files --------

AC_DEFUN(REQUIRED_HEADER, [
AC_CHECK_HEADER($1, [], [
  AC_MSG_ERROR([required header file <$1> is not found.])
])])

# C99 headers
REQUIRED_HEADER(assert.h)
REQUIRED_HEADER(ctype.h)
REQUIRED_HEADER(dirent.h)
REQUIRED_HEADER(errno.h)
REQUIRED_HEADER(limits.h)
REQUIRED_HEADER(math.h)
REQUIRED_HEADER(setjmp.h)
REQUIRED_HEADER(stdarg.h)
REQUIRED_HEADER(stddef.h)
REQUIRED_HEADER(stdint.h)
REQUIRED_HEADER(stdio.h)
REQUIRED_HEADER(stdlib.h)
REQUIRED_HEADER(string.h)
REQUIRED_HEADER(time.h)

# POSIX headers
REQUIRED_HEADER(unistd.h)
REQUIRED_HEADER(fcntl.h)
REQUIRED_HEADER(sys/time.h)
REQUIRED_HEADER(sys/stat.h)
if test "x$enable_thread" = "xyes"; then
  REQUIRED_HEADER(pthread.h)
fi
REQUIRED_HEADER(signal.h)
case "$target_os" in
  *mingw*)
    # mingw does not have sigaction.
    ;;
  *)
    AC_CHECK_FUNCS([sigaction sigprocmask], [], [
      AC_ERROR([POSIX signal functions are not found.])
    ])
    ;;
esac

# auxiliary libraries
REQUIRED_HEADER(gmp.h)
case "$target_os" in
  *mingw*)
    REQUIRED_HEADER(windows.h)
    ;;
esac

# for dlopen etc.
AC_CHECK_HEADERS(dlfcn.h)
# for poll
AC_CHECK_HEADERS(poll.h)
# for mmap
AC_CHECK_HEADERS(sys/mman.h)
AC_CHECK_HEADERS(sys/types.h)
# for fpclassify
AC_CHECK_HEADERS(float.h)
# for fpclass
AC_CHECK_HEADERS(ieeefp.h)
# for getrusage
AC_CHECK_HEADERS(sys/resource.h)
# for fesetround, fegetround
AC_CHECK_HEADERS(fenv.h)
# for times
AC_CHECK_HEADERS(sys/times.h)
# for ftime
AC_CHECK_HEADERS(sys/timeb.h)
# for utime
AC_CHECK_HEADERS(utime.h)

AC_CHECK_HEADERS([strings.h sys/socket.h])

# -------- check for C language --------

AC_C_CONST
AC_C_INLINE
AC_C_VOLATILE
AC_TYPE_SIZE_T

#AC_TYPE_SIGNAL
#AC_CHECK_SIZEOF(int)
#AC_CHECK_SIZEOF(short)
#AC_CHECK_SIZEOF(long)
#AC_CHECK_SIZEOF(void*)
#AC_CHECK_SIZEOF(float)
#AC_CHECK_SIZEOF(double)

AC_C_BIGENDIAN([
  AC_DEFINE(WORDS_BIGENDIAN, [1], [Define if your processor is big endian])
  BYTE_ORDER=Big
], [
  BYTE_ORDER=Little
])
AC_SUBST(BYTE_ORDER)

# -------- check for C functions --------

#AC_FUNC_FORK
#AC_FUNC_MALLOC
#AC_FUNC_REALLOC

AC_CHECK_FUNCS([ \
ceilf \
clock_gettime \
copysign \
copysignf \
dlopen \
fegetround \
fesetround \
finite \
floorf \
fpclass \
frexpf \
ftime \
getrusage \
gettimeofday \
ldexpf \
mkstemp \
mmap  \
modf  \
modff \
nextafter \
nextafterf \
poll \
readlink \
roundf \
select \
sleep \
socket \
times \
utime \
utimes \
])
AC_CHECK_DECLS([CLOCK_PROCESS_CPUTIME_ID],,,[#include <time.h>])
AC_CHECK_DECLS([fpclassify, isinf, isnan, isnormal, signbit],,,
               [#include <math.h>])

# -------- Finale --------

AC_CONFIG_FILES([stamp-h config.mk src/config.mk Makefile],
                [echo timestamp > stamp-h])
AC_OUTPUT

(cd "$srcdir" && $FIND src -type d) | while read i; do \
  if test ! -d "$i"; then
    AS_ECHO "creating directory $i"
    mkdir "$i"
  fi
done

if test "x$STAGE0_COMPILER" != "x"; then
  AS_ECHO
  AS_ECHO "*** NOTE:"
  AS_ECHO "*** You need to build stage 0 compiler. Do \`make stage0' at first."
  AS_ECHO "***"
fi
