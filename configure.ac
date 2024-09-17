# -*- Autoconf -*-

AC_PREREQ([2.72])
AC_INIT
AC_CONFIG_SRCDIR([src/compiler/compilePhases/toplevel/main/Top.sml])
AC_CONFIG_HEADERS([config.h])

AC_CANONICAL_TARGET
AC_ARG_PROGRAM

# -------- Checks for C/C++ compiler capability --------

AC_PROG_CC
if test "x$ac_cv_prog_cc_c99" = "xno"; then
  AC_MSG_ERROR([C99 compiler is required])
fi
AC_PROG_CXX

AC_LANG(C)
AC_USE_SYSTEM_EXTENSIONS

AC_CHECK_HEADERS(stdatomic.h, [], [
  AC_MSG_CHECKING([for __atomic builtins])
  AC_COMPILE_IFELSE(
    [ AC_LANG_SOURCE([
        int foo(void **p1, void **p2, void *p3) {
          return __atomic_compare_exchange_n
            (p1, p2, p3, 1, __ATOMIC_RELEASE, __ATOMIC_ACQUIRE);
        }
      ])],
    [ AC_MSG_RESULT([yes])
      AC_DEFINE(HAVE_GCC_ATOMIC, 1, [Define if __atomic builtins are available])
    ],
    [ AC_MSG_RESULT([no])
      AC_MSG_ERROR([__atomic builtins are not available. Use GCC 4.7 or later])
    ])
])

AC_MSG_CHECKING([for alignof])
AC_COMPILE_IFELSE(
  [ AC_LANG_SOURCE([ int x = alignof(void *); ]) ],
  [ AC_MSG_RESULT([yes])
    AC_DEFINE(HAVE_ALIGNOF, 1, [Define if aligonof is available]) ],
  [ AC_COMPILE_IFELSE(
      [ AC_LANG_SOURCE([ int x = __alignof__(void *); ]) ],
      [ AC_MSG_RESULT([yes])
        AC_DEFINE(HAVE_ALIGNOF, 1)
        AC_DEFINE(alignof, __alignof__, [Alternative to alignof]) ],
      [ AC_MSG_RESULT([no]) ]) ])

AC_MSG_CHECKING([for _Thread_local storage class])
AC_COMPILE_IFELSE(
  [ AC_LANG_SOURCE([ _Thread_local int hoge; int foo() { return hoge; } ]) ],
  [ AC_MSG_RESULT([yes])
    AC_DEFINE(HAVE_TLS, 1, [Define if _Thread_local is available]) ],
  [ AC_MSG_RESULT([no])
    AC_MSG_CHECKING([for __thread storage class])
    AC_COMPILE_IFELSE(
      [ AC_LANG_SOURCE([ __thread int hoge; int foo() { return hoge; } ]) ],
      [ AC_MSG_RESULT([yes])
        AC_DEFINE(_Thread_local, __thread, [alternative to _Thread_local])
        AC_DEFINE(HAVE_TLS, 1) ]
      [ AC_MSG_RESULT([no]) ])
  ])

# -------- Check for tools --------

AC_PROG_MAKE_SET
AC_PROG_INSTALL
AC_PATH_PROG(FIND, find)
AC_PROG_RANLIB
AC_CHECK_TOOL(LD, ld)
AC_CHECK_TOOL(AR, ar)
dnl AC_CHECK_TOOL(WINDRES, windres)
dnl AC_PATH_PROG(DOXYGEN, doxygen)

dnl ToDo: check ar and ranlib working

# -------- Check for system-dependent properties --------

: ${SMLFLAGS=-O2}
: ${LLCFLAGS=}
RUNTIME_DEFS=
AC_SUBST(SMLFLAGS)
AC_SUBST(LLCFLAGS)
AC_SUBST(RUNTIME_DEFS)

AC_SUBST(LIBEXT)
AC_SUBST(DLLEXT)
AC_SUBST(ASMEXT)
AC_SUBST(OBJEXT)
AC_SUBST(EXEEXT)
AC_SUBST(A_OUT)
AC_SUBST(RUNLOOP_DLDFLAGS)
AC_SUBST(HOST_OS_TYPE)
AC_SUBST(CMDLINE_MAXLEN)
case "$target_os" in
dnl  *cygwin*)
dnl    DLLEXT='dll'
dnl    EXEEXT=.exe
dnl    A_OUT=a.exe
dnl    AC_CHECK_TOOL(DLLTOOL, dlltool, :)
dnl    AC_PATH_PROG(CYGPATH, cygpath)
dnl    if test "x$CYGPATH" = "x"; then
dnl      case "$host_os" in
dnl        *cygwin*)
dnl          AC_MSG_ERROR([cygpath is not found.])
dnl          ;;
dnl      esac
dnl    fi
dnl    AC_SUBST(CYGPATH)
dnl    if test "x$WINDRES" != "x"; then
dnl      RESOURCE_TYPE=rc
dnl    fi
dnl    AC_SUBST(RESOURCE_TYPE)

  mingw*)
    : ${DLLEXT='dll'}
    : ${EXEEXT='.exe'}
    : ${A_OUT=a.exe}
    : ${HOST_OS_TYPE=Mingw}
    : ${CMDLINE_MAXLEN='SOME 2047'}
    : ${RDYNAMIC_LDFFLAGS='-Wl,--export-all-symbols -Wl,--out-implib=src/compiler/smlsharp.lib'}
    : ${RUNLOOP_DLDFLAGS='-shared -Wl,--enable-auto-import,--enable-stdcall-fixup'}
    ;;
  darwin*)
    : ${DLLEXT='dylib'}
    : ${HOST_OS_TYPE=Unix}
    : ${CMDLINE_MAXLEN='NONE'}
    : ${RDYNAMIC_LDFLAGS=}
    : ${RUNLOOP_DLDFLAGS='-dynamiclib -Wl,-undefined,dynamic_lookup,-flat_namespace'}
    ;;
  linux*|*bsd*)
    : ${HOST_OS_TYPE=Unix}
    : ${CMDLINE_MAXLEN='NONE'}
    : ${RDYNAMIC_LDFLAGS='-rdynamic'}
    : ${RUNLOOP_DLDFLAGS='-shared'}
    ;;
esac

: ${LIBEXT=a}
: ${DLLEXT=so}
: ${ASMEXT=s}
: ${OBJEXT=o}
: ${EXEEXT=}
: ${A_OUT=a.out}
if test "x${HOST_OS_TYPE-__unset__}" = "x__unset__" || \
   test "x${CMDLINE_MAXLEN-__unset__}" = "x__unset__" || \
   test "x${RDYNAMIC_LDFLAGS-__unset__}" = "x__unset__" || \
   test "x${RUNLOOP_DLDFLAGS-__unset__}" = "x__unset__"; then
echo $HOST_OS_TYPE
echo $CMDLINE_MAXLEN
echo $RDYNAMIC_LDFLAGS
echo $RUNLOOP_DLDFLAGS
   AC_MSG_ERROR([configure cannot guess HOST_OS_TYPE, CMDLINE_MAXLEN, RDYNAMIC_LDFLAGS, and RUNLOOP_DLDFLAGS for $target_os.  You need to speficy them by the configure command line.])
fi

AC_DEFUN([CHECK_LDFLAGS], [
  orig_LDFLAGS=$LDFLAGS
  LDFLAGS="$orig_LDFLAGS $[]$1"
  AC_MSG_CHECKING([that $1 works])
  AC_LINK_IFELSE(
    [ AC_LANG_SOURCE([ int foo() { return 0; } int main() { return 0; } ]) ],
    [ AC_MSG_RESULT(yes) ],
    [ AC_MSG_RESULT(no)
      AC_MSG_ERROR([$1 does not work]) ])
  LDFLAGS=$orig_LDFLAGS
])
CHECK_LDFLAGS(RDYNAMIC_LDFLAGS)
CHECK_LDFLAGS(RUNLOOP_DLDFLAGS)

RDYNAMIC_SMLFLAGS=
AC_SUBST(RDYNAMIC_SMLFLAGS)
for i in $RDYNAMIC_LDFLAGS; do
  test -n "$RDYNAMIC_SMLFLAGS" && RDYNAMIC_SMLFLAGS="${RDYNAMIC_SMLFLAGS} "
  RDYNAMIC_SMLFLAGS="${RDYNAMIC_SMLFLAGS}-Xlinker $i"
done

# -------- Check for LLVM --------

LLVM_PATH=$PATH
AC_ARG_WITH(llvm,
AS_HELP_STRING([--with-llvm=DIR],
               [specify where LLVM has installed in]),
[
  case "x$withval" in
    yes|no) ;;
    *) LLVM_PATH="$withval/bin:$LLVM_PATH" ;;
  esac
])

AC_DEFUN([LLVM_CHECK_PROG], [
  AC_PATH_PROG($1, $2, [], $3)
  if test -z "$[]$1"; then
    AC_MSG_ERROR([$2 is not found.])
  fi
])
AC_DEFUN([LLVM_CHECK_CONFIG], [
  AC_MSG_CHECKING([for LLVM $2])
  $1=`$[]LLVM_CONFIG --$2` || AC_MSG_ERROR([failed])
  AC_MSG_RESULT($[]$1)
  AC_SUBST($1)
])
LLVM_CHECK_PROG(LLVM_CONFIG, llvm-config, $LLVM_PATH)
LLVM_CHECK_CONFIG(LLVM_bindir, bindir)
LLVM_CHECK_CONFIG(LLVM_CXXFLAGS, cxxflags)
LLVM_CHECK_CONFIG(LLVM_VERSION, version)
LLVM_CHECK_PROG(LLC, llc, $LLVM_bindir)
LLVM_CHECK_PROG(OPT, opt, $LLVM_bindir)
LLVM_CHECK_PROG(LLVM_DIS, llvm-dis, $LLVM_bindir)
LLVM_CHECK_PROG(LLVM_AS, llvm-as, $LLVM_bindir)

AC_ARG_WITH(incompatible-llvm,
AS_HELP_STRING([--with-incompatible-llvm], [skip LLVM compatibility check]))

AC_MSG_CHECKING([for LLVM compatibility])
LLVM_VERSION=`echo "$LLVM_VERSION" | sed 's/\.[[0-9]]*$//'`
AC_SUBST(LLVM_VERSION)
case "$LLVM_VERSION" in
  3.9|[[4-9]].0|7.1|1[[0-7]].0|11.1|18.1)
    AC_MSG_RESULT(yes)
    ;;
  *)
    AC_MSG_RESULT(no)
    AC_MSG_WARN([SML[#] does not support LLVM $LLVM_VERSION. Build may fail due to incompatibility.])
    if test "x$with_incompatible_llvm" != "xyes"; then
      AC_MSG_ERROR([Specify --with-incompatible-llvm if you really want to build SML[#] with it.])
    fi
    ;;
esac

LLVM7_CONFIG=
AC_SUBST(LLVM7_CONFIG)

AC_ARG_WITH(llvm7,
AS_HELP_STRING([--with-llvm7=DIR],
               [specify where LLVM 7 has installed in (for developers only)]),
[
  case "$withval" in
    no) ;;
    yes) AC_PATH_PROG(LLVM7_CONFIG, llvm-config, [], $PATH) ;;
    *) AC_PATH_PROG(LLVM7_CONFIG, llvm-config, [], $withval/bin:$PATH) ;;
  esac
],
[
  case "$LLVM_VERSION" in
    7.[01]) LLVM7_CONFIG=LLVM_CONFIG ;;
  esac
])

if test -n "$LLVM7_CONFIG"; then
  AC_MSG_CHECKING([for LLVM 7 version])
  LLVM7_VERSION=`$LLVM7_CONFIG --version` || AC_MSG_ERROR([failed])
  AC_MSG_RESULT($LLVM7_VERSION)
  if test "_$LLVM7_VERSION" != "_7.1.0"; then
    AC_MSG_ERROR([Specify LLVM 7.1.0 to --with-llvm7.])
  fi
fi

# -------- Check for self- and cross-compilation ---------

MINISMLLEX='$(SMLLEX)'
MINISMLYACC='$(SMLYACC)'
MINISMLFORMAT='$(SMLFORMAT)'
MINISMLSHARP_LLVM_PLUGIN='$(LLVM_PLUGIN)'
MINISMLSHARP=./minismlsharp
AC_SUBST(MINISMLLEX)
AC_SUBST(MINISMLYACC)
AC_SUBST(MINISMLFORMAT)
AC_SUBST(MINISMLSHARP_LLVM_PLUGIN)
AC_SUBST(MINISMLSHARP)

AC_ARG_WITH(smlsharp,
AS_HELP_STRING([--with-smlsharp=DIR],
               [specify smlsharp directory (required for cross compile)]),
[
  if test "x$withval" = "xno"; then
    if test "x$build" != "x$target"; then
      AC_MSG_ERROR(--with-smlsharp is required for cross-compiling the compiler)
    fi
  elif test -f "$withval/src/compiler/smlsharp"; then
    MINISMLLEX="$withval/src/ml-lex/smllex"
    MINISMLYACC="$withval/src/ml-yacc/smlyacc"
    MINISMLFORMAT="$withval/src/smlformat/smlformat"
    MINISMLSHARP_LLVM_PLUGIN=""
    MINISMLSHARP="$withval/src/compiler/smlsharp"
    SMLFLAGS="-BX $withval/src $SMLFLAGS"
  else
    AC_MSG_ERROR(Specify a complete build tree to --with-smlsharp)
  fi
],
[
  if test "x$build" != "x$target"; then
    AC_MSG_ERROR(--with-smlsharp is required for cross-compiling the compiler)
  fi
])

AC_SUBST(PRECOMPILED_ARCH)
if test "x$build" = "x$target"; then
  if test "x$MINISMLSHARP" = "x./minismlsharp"; then
    AC_PATH_PROG(XZ, xz)
    if test "x$XZ" = "x"; then
      AC_MSG_ERROR([xz is required to build smlsharp.])
    fi
  fi
  case "$target_cpu" in
    x86_64|amd64)
      PRECOMPILED_ARCH=x86_64
      ;;
    *)
      AC_MSG_ERROR([the compiler is not precompiled for target_cpu $target_cpu.])
      ;;
  esac
else
  SMLFLAGS="--target=$target $SMLFLAGS"
fi

# -------- Check for supporting target platform --------

AC_MSG_CHECKING([whether target platform is supported])

case "$target_cpu" in
  i[[3456]]86)
    AC_MSG_RESULT([yes])
    RUNTIME_DEFS="$RUNTIME_DEFS -DHOST_CPU_i386"
    LLCFLAGS="$LLCFLAGS -no-x86-call-frame-opt"
    ;;
  x86_64|amd64)
    AC_MSG_RESULT([yes])
    RUNTIME_DEFS="$RUNTIME_DEFS -DHOST_CPU_i386"
    LLCFLAGS="$LLCFLAGS -no-x86-call-frame-opt"
    ;;
  *)
    AC_MSG_RESULT([no])
    AC_MSG_ERROR([target_cpu $target_cpu is not supported.])
    ;;
esac

PIC_DEFAULT=false
AC_SUBST(PIC_DEFAULT)
case "$target" in
  *-darwin*-*|x86_64-*|amd64-*)
    PIC_DEFAULT=true
    ;;
esac

if test "x$PIC_DEFAULT" = "xtrue"; then
  LLCFLAGS="$LLCFLAGS -relocation-model=pic"
  CFLAGS="$CFLAGS -fPIC"
fi

case "$target_os" in
  *mingw*)
    AC_DEFINE(MINGW, 1, [Define if your system is Windows])
    ;;
esac

AC_C_BIGENDIAN([
  AC_DEFINE(WORDS_BIGENDIAN, [1], [Define if your processor is big endian])
])
AC_SUBST(BYTE_ORDER)

# -------- Extra options for developers --------

RELEASE='$(srcdir)/RELEASE'
MKREL='#'
MKDST='#'
AC_SUBST(RELEASE)
AC_SUBST(MKREL)
AC_SUBST(MKDST)
if test -d "$srcdir/.git" || test -f "$srcdir/.git"; then
  MKDST=
  x=`cd "$srcdir" && git ls-files RELEASE 2>/dev/null || :`
  if test -z "$x"; then
    RELEASE=RELEASE
    MKREL=
  fi
fi
if test -n "$MKREL" && test ! -f "$srcdir/RELEASE"; then
  AC_MSG_WARN([SML[#] version is unknown because of lack of RELEASE file])
  RELEASE=
fi

EXTRA_OPTIONS=
AC_SUBST(EXTRA_OPTIONS)
AC_ARG_ENABLE(extra-options,
AS_HELP_STRING([--enable-extra-options=OPTIONS],
               [set default extra options (for developers only)]),
[
  case "$enableval" in
    yes|no) ;;
    *) EXTRA_OPTIONS=$enableval ;;
  esac
])

# -------- Checks for multithread support --------

AC_CHECK_LIB(pthread, pthread_create,
  [], [ AC_MSG_ERROR([pthread library is not found]) ])

AC_ARG_WITH(massivethreads,
AS_HELP_STRING([--with-massivethreads=DIR],
               [specify where MassiveThreads has installed in]),
[
  case "$withval" in
    yes|no) ;;
    *) if test -d "$withval/include"; then
         CPPFLAGS="$CPPFLAGS -I$withval/include"
       fi
       if test -d "$withval/lib"; then
         LDFLAGS="$LDFLAGS -L$withval/lib"
       elif test -d "$withval/lib64"; then
         LDFLAGS="$LDFLAGS -L$withval/lib64"
       fi
       with_massivethreads=yes
       ;;
  esac
], [ with_massivethreads=yes ])
if test "x$with_massivethreads" = "xyes"; then
  AC_CHECK_LIB(myth, myth_is_myth_worker,
    [], [
      AC_CHECK_LIB(myth, myth_create,
        [ AC_MSG_ERROR([the massivethreads library is old. check out the latest one.]) ],
        [ AC_MSG_ERROR([the massivethreads library is not found]) ])
    ])
else
  RUNTIME_DEFS="$RUNTIME_DEFS -DWITHOUT_MASSIVETHREADS"
fi

# -------- Check for required libraries --------

AC_CHECK_LIB(gmp, __gmpz_init,
  [], [ AC_MSG_ERROR([GMP library is not found]) ])

AC_CHECK_LIB(m, sqrt)
AC_CHECK_LIB(socket, socket)
AC_CHECK_LIB(dl, dlopen)
AC_CHECK_LIB(rt, clock_gettime)

dnl ## cygwin has dlopen in libcygwin.dll.
dnl if test "x$ac_cv_lib_dl_dlopen" = "xno"; then
dnl   case "$target_os" in
dnl   *cygwin*)
dnl     AC_SEARCH_LIBS(dlopen, [dl],
dnl     [ ac_cv_lib_dl_dlopen=yes; echo "#define HAVE_LIBDL 1" >> confdefs.h ])
dnl     ;;
dnl   *)
dnl     ;;
dnl   esac
dnl fi

# -------- Check for linker --------

# ToDo: check for method for dynamic linking.

AC_LANG_PUSH(C++)
AC_MSG_CHECKING([whether C++ linker works])
AC_LINK_IFELSE(
  [ AC_LANG_CALL([], [__gmpz_init]) ],
  [ AC_MSG_RESULT(yes) ],
  [ AC_MSG_RESULT(no)
    AC_MSG_ERROR([failed to link libraries by $CXX.]) ])
AC_LANG_POP(C++)

# -------- Check for C header files --------

AC_DEFUN([REQUIRED_HEADER], [
AC_CHECK_HEADER($1, [], [
  AC_MSG_ERROR([required header file <$1> is not found.])
])])

# C99 headers
REQUIRED_HEADER(assert.h)
REQUIRED_HEADER(ctype.h)
REQUIRED_HEADER(dirent.h)
REQUIRED_HEADER(errno.h)
REQUIRED_HEADER(inttypes.h)
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
REQUIRED_HEADER(fcntl.h)
REQUIRED_HEADER(fenv.h)
REQUIRED_HEADER(dlfcn.h)
REQUIRED_HEADER(poll.h)
REQUIRED_HEADER(signal.h)
REQUIRED_HEADER(sys/mman.h)
REQUIRED_HEADER(sys/resource.h)
REQUIRED_HEADER(sys/time.h)
REQUIRED_HEADER(sys/times.h)
REQUIRED_HEADER(sys/stat.h)
REQUIRED_HEADER(sys/socket.h)
REQUIRED_HEADER(unistd.h)
REQUIRED_HEADER(utime.h)
if test "x$with_pthread" = "xyes"; then
  REQUIRED_HEADER(pthread.h)
fi

# others
REQUIRED_HEADER(gmp.h)
case "$target_os" in
  *mingw*)
    REQUIRED_HEADER(windows.h)
    ;;
esac

AC_CHECK_HEADERS(libunwind.h)
AC_CHECK_FUNCS(unw_getcontext)

# -------- check for C functions --------

dnl AC_FUNC_FORK
dnl AC_FUNC_MALLOC
dnl AC_FUNC_REALLOC

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
getrusage \
gettimeofday \
ldexpf \
mkstemp \
mmap \
modf \
modff \
nextafter \
nextafterf \
poll \
readlink \
roundf \
select \
sleep \
socket \
strptime \
times \
utime \
utimes \
])
AC_CHECK_DECLS([CLOCK_MONOTONIC],,,[#include <time.h>])
AC_CHECK_DECLS([fpclassify, isinf, isnan, isnormal, signbit],,,
               [#include <math.h>])

# FreeBSD does not define fegetround/fesetround as library functions,
# but as inline functions in fenv.h.
if test "x$ac_cv_func_fegetround" = "xno"; then
  AC_CHECK_DECLS([fegetround],,,[#include <fenv.h>])
fi
if test "x$ac_cv_func_fesetround" = "xno"; then
  AC_CHECK_DECLS([fesetround],,,[#include <fenv.h>])
fi

AC_CHECK_TYPES([max_align_t])

# -------- check for C/POSIX features that the compiler implies --------

AC_DEFUN([REQUIRED_TYPE], [
  AC_CHECK_SIZEOF($1, [], [
    AC_INCLUDES_DEFAULT
    $3
  ])
  if test "$[]AS_TR_SH([ac_cv_sizeof_$1])" -eq 0; then
    AC_MSG_ERROR([required type $1 is not found.])
  fi
  flag=
  for i in $2; do
    if test "[$]AS_TR_SH([ac_cv_sizeof_$1])" -eq [$]i; then
      flag="AS_TR_CPP($1)=[$]i"
      METAFLAGS="$METAFLAGS [$]flag"
   fi
  done
  if test -z "$[]flag"; then
    AC_MSG_ERROR([unsupported size of $1])
  fi
  AS_TR_SH([SIZEOF_$1])=[$]AS_TR_SH([ac_cv_sizeof_$1])
  AS_TR_SH([BITSOF_$1])=`expr "$[]AS_TR_SH([SIZEOF_$1])" '*' 8`
  AC_SUBST(AS_TR_SH([SIZEOF_$1]))
  AC_SUBST(AS_TR_SH([BITSOF_$1]))
])

REQUIRED_TYPE(int, 4)
REQUIRED_TYPE(float, 4)
REQUIRED_TYPE(double, 8)
REQUIRED_TYPE(long, 4 8)
REQUIRED_TYPE(long long, 4 8)
REQUIRED_TYPE(size_t, 4 8)

# -------- Finale --------

AC_CONFIG_FILES([
  Makefile
  config.mk
  src/config.mk
])
AC_CONFIG_FILES([stamp-h], [AS_ECHO(timestamp) > stamp-h])
AC_OUTPUT

if test "x$no_create" != "xyes" && test "x$srcdir" != "x."; then
  (cd "$srcdir" && $FIND precompiled src tests -type d) | while read i; do
    AS_ECHO("creating directory $i")
    AS_MKDIR_P("$i")
  done
  for i in src/builtin.smi; do
    AS_ECHO("copying file $i")
    cp $srcdir/$i $i
  done
fi
