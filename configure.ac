# -*- Autoconf -*-

AC_PREREQ(2.69)
AC_INIT(smlsharp)
AC_CONFIG_SRCDIR([src/compiler/compilePhases/toplevel/main/Top.sml])
AC_CONFIG_HEADER([config.h])

AC_CANONICAL_TARGET
AC_ARG_PROGRAM

# Checks for programs.
AC_PROG_CC
AC_PROG_CC_C99
if test "x$ac_cv_prog_cc_c99" = "xno"; then
  AC_MSG_ERROR([C99 compiler is required])
fi
AC_PROG_CXX

AC_LANG(C++)
AC_LANG(C)

AC_MSG_CHECKING([for gcc version])
version=`$CC -dumpversion 2> /dev/null || echo \*`
AC_MSG_RESULT([$version])
case "$version" in
  [[0-3]].*|4.[[01]].*)
    AC_MSG_ERROR([GCC 4.2 or later is required])
    ;;
esac

AC_PROG_MAKE_SET
AC_PROG_INSTALL
AC_PATH_PROG(FIND, find)
AC_PROG_RANLIB
AC_CHECK_TOOL(LD, ld)
AC_CHECK_TOOL(AR, ar)
#AC_CHECK_TOOL(WINDRES, windres)
#AC_PATH_PROG(DOXYGEN, doxygen)

: ${SMLFLAGS=-O2}
AC_SUBST(SMLFLAGS)
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
EXTRA_OPTIONS=
AC_SUBST(LIBEXT)
AC_SUBST(DLLEXT)
AC_SUBST(ASMEXT)
AC_SUBST(OBJEXT)
AC_SUBST(EXEEXT)
AC_SUBST(A_OUT)
AC_SUBST(RDYNAMIC_LDFLAGS)
AC_SUBST(RUNLOOP_DLDFLAGS)
AC_SUBST(EXTRA_OPTIONS)

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

case "$target_os" in
  *mingw*)
    HOST_OS_TYPE=Mingw
    CMDLINE_MAXLEN='SOME 2047'
    ;;
  *)
    HOST_OS_TYPE=Unix
    CMDLINE_MAXLEN='NONE'
    ;;
esac
AC_SUBST(HOST_OS_TYPE)
AC_SUBST(CMDLINE_MAXLEN)

AC_CHECK_SIZEOF([void *])
if test "x$ac_cv_sizeof_void_p" = "x0"; then
  AC_ERROR([failed to determine sizeof(void *)])
fi
SIZEOF_VOID_P=$ac_cv_sizeof_void_p
AC_SUBST(SIZEOF_VOID_P)

# FIXME: check how to make a static library

# -------- Checks for LLVM --------

LLVM_PATH=$PATH
AC_ARG_WITH(llvm,
AS_HELP_STRING([--with-llvm],
               [specify llvm directory]),
[ case "x$withval" in
    no) ;;
    yes) ;;
    *) LLVM_PATH="$withval/bin:$LLVM_PATH" ;;
  esac
])

AC_PATH_PROG(LLVM_CONFIG, llvm-config, [], $LLVM_PATH)
if test "x$LLVM_CONFIG" = "x"; then
  AC_MSG_ERROR([llvm-config is not found.])
fi

LLVM_bindir=`"$LLVM_CONFIG" --bindir`
AC_DEFUN(LLVM_PROG, [
  AC_PATH_PROG($1, $2, [], $[]LLVM_bindir)
  if test "x$[]$1" = "x"; then
    AC_MSG_ERROR([$2 is not found.])
  fi
  AC_SUBST($1)
])
LLVM_PROG(LLC, llc)
LLVM_PROG(OPT, opt)
LLVM_PROG(LLVM_DIS, llvm-dis)
LLVM_PROG(LLVM_AS, llvm-as)

AC_ARG_WITH(incompatible-llvm,
AS_HELP_STRING([--with-incompatible-llvm],
               [skip LLVM version check]))

AC_MSG_CHECKING([for LLVM version])
LLVM_VERSION=`$LLVM_CONFIG --version`
AC_MSG_RESULT($LLVM_VERSION)
case "$LLVM_VERSION" in
  3.7.[[1-9]])
    ;;
  *)
    AC_MSG_WARN([SML[#] requires LLVM 3.7.1 but $LLVM_VERSION is found. Build may fail due to incompatibility.])
    if test "x$with_incompatible_llvm" != "xyes"; then
      AC_MSG_ERROR([Specify --with-incompatible-llvm if you really want to build SML[#] with the incompatible LLVM.])
    fi
    ;;
esac

AC_DEFUN(LLVM_FLAG, [
  AC_MSG_CHECKING([for $1 for llvm])
  LLVM_$1=`$[]LLVM_CONFIG --$2`
  if test "$[]?" = "0"; then :; else AC_MSG_ERROR([failed]); fi
  AC_MSG_RESULT($[]LLVM_$1)
  AC_SUBST(LLVM_$1)
])

LLVM_FLAG(LIBDIR, libdir)
LLVM_FLAG(LDFLAGS, ldflags)
LLVM_FLAG(SYSLIBS, system-libs)

AC_ARG_ENABLE(rpath,
AS_HELP_STRING([--disable-rpath], [do not specify RPATH]),
[], [ enable_rpath=yes ])

orig_LDFLAGS=$LDFLAGS
LDFLAGS="$LDFLAGS $LLVM_LDFLAGS"
libsuffix=`echo "$LLVM_VERSION" | sed 's,\.[[^.]]*$,,'`
AC_LANG_PUSH(C++)
AC_CHECK_LIB(LLVM-$libsuffix, LLVMCreateTargetMachine,
  [ LLVM_LIBS="-lLLVM-$libsuffix"
    if test "x$enable_rpath" = "xyes"; then
      LLVM_LDFLAGS="$LLVM_LDFLAGS -Wl,-rpath,'$LLVM_LIBDIR'"
    fi
  ],
  [ LLVM_FLAG(LIBS, libs) ],
  [ $LLVM_SYSLIBS ])
AC_LANG_POP(C++)
AC_SUBST(LLVM_LIBS)
LDFLAGS=$orig_LDFLAGS

LLVM_FLAG(CXXFLAGS, cxxflags)
LLVM_FLAG(CPPFLAGS, cppflags)

LLVM_SMLSHARP_LDFLAGS="-c++"
AC_SUBST(LLVM_SMLSHARP_LDFLAGS)

for i in $LLVM_LDFLAGS; do
  case "$i" in
  -L*)
    LLVM_SMLSHARP_LDFLAGS="$LLVM_SMLSHARP_LDFLAGS $i"
    ldflags="$ldflags $i"
    ;;
  *)
    LLVM_SMLSHARP_LDFLAGS="$LLVM_SMLSHARP_LDFLAGS -Xlinker $i"
    ldflags="$ldflags $i"
    ;;
  esac
done

orig_CPPFLAGS=$CPPFLAGS
CPPFLAGS=$LLVM_CPPFLAGS
AC_CHECK_DECLS([LLVM_NATIVE_TARGET],,
  [ AC_MSG_ERROR([LLVM_NATIVE_TARGET is not defined])],
  [#include <llvm/Config/llvm-config.h>])
CPPFLAGS=$orig_CPPFLAGS

# -------- Checks for SML compiler --------

SMLSHARP_STAGE0=
AC_SUBST(SMLSHARP_STAGE0)
SMLSHARP_STAGE1=./minismlsharp
AC_SUBST(SMLSHARP_STAGE1)
INCLUDE_STAGE1='# '
AC_SUBST(INCLUDE_STAGE1)

AC_ARG_WITH(stage0,
AS_HELP_STRING([--with-stage0],
               [bootstrap with existing smlsharp command (may not work)]),
[
  if test "x$withval" != "xno"; then
    SML_PATH=$PATH
    if test "x$withval" != "xyes"; then
      SML_PATH="$withval/bin:$SML_PATH"
    fi
    AC_DEFUN(SMLSHARP_PROG, [
      AC_PATH_PROG($1, $2, [], $SML_PATH)
      if test "x$[]$1" = "x"; then
        AC_MSG_ERROR([$2 is not found])
      fi
    ])
    SMLSHARP_PROG(SMLSHARP_STAGE0, smlsharp)
    SMLSHARP_PROG(SMLFORMAT_STAGE0, smlformat)
    SMLSHARP_PROG(SMLYACC_STAGE0, smlyacc)
    SMLSHARP_PROG(SMLLEX_STAGE0, smllex)
    INCLUDE_STAGE1=
    SMLSHARP_STAGE1=./stage1
  fi
])

if test "x$SMLSHARP_STAGE1" = "x./minismlsharp"; then
  AC_PATH_PROG(XZ, xz)
  if test "x$XZ" = "x"; then
    AC_MSG_ERROR([xz is required to build smlsharp.])
  fi
fi

# -------- Checks for native compile --------

TARGET_TRIPLE="$target"
AC_SUBST(TARGET_TRIPLE)
PRECOMPILED_ARCH=
AC_SUBST(PRECOMPILED_ARCH)

# workaround to avoid the following warnings caused by linker.
# ld: warning: object file (xxx.o) was built for newer OSX version (xx.x) than being linked (xx.xx)
case "$TARGET_TRIPLE" in
  *-apple-darwin*)
    TARGET_TRIPLE=`echo "$TARGET_TRIPLE" | sed 's,[[0-9.]]*$,,'`
    ;;
esac

#case "$TARGET_TRIPLE" in
#  x86_64-*-linux*)
#    TARGET_TRIPLE=`echo "$TARGET_TRIPLE" | sed 's,^x86_64,i686,'`
#    ;;
#esac

AC_MSG_CHECKING([whether target platform is supported])

case "$TARGET_TRIPLE" in
  i[[3456]]86-*)
    AC_MSG_RESULT([yes])
    RUNTIME_DEFS="$RUNTIME_DEFS -DHOST_CPU_i386"
    PRECOMPILED_ARCH=x86
    ;;
  x86_64-*)
    AC_MSG_RESULT([yes])
    RUNTIME_DEFS="$RUNTIME_DEFS -DHOST_CPU_i386"
    PRECOMPILED_ARCH=x86_64
    ;;
  *)
    AC_MSG_RESULT([no])
    AC_MSG_ERROR([target $TARGET_TRIPLE is not supported.])
    ;;
esac

PIC_DEFAULT=false
AC_SUBST(PIC_DEFAULT)

case "$TARGET_TRIPLE" in
  *darwin*)
    PIC_DEFAULT=true
    ;;
  x86_64-*)
    PIC_DEFAULT=true
    ;;
esac

# -------- Extra switches for developers --------

SNAPDATE_RULE_='# '
if test -f "$srcdir/../.hg/dirstate"; then
  if test ! -f "$srcdir/RELEASE_DATE" \
     || grep '[[a-f]]' "$srcdir/RELEASE_DATE" > /dev/null 2>&1; then
    SNAPDATE_RULE_=
  fi
fi
AC_SUBST(SNAPDATE_RULE_)

# -------- Checks for Libraries --------

AC_CHECK_LIB(m, sqrt)
AC_CHECK_LIB(socket, socket)

AC_CHECK_LIB(gmp, __gmpz_init,
  [], [ AC_MSG_ERROR([GMP library is not found]) ])

AC_CHECK_LIB(dl, dlopen)
#AC_CHECK_LIB(dld, shl_load)   # for HP-UX

AC_ARG_WITH(yajl_s,
AS_HELP_STRING([--with-yajl_s],[use libyajl_s instead of libyajl]))

if test "x$with_yajl_s" = "xyes"; then
  AC_CHECK_LIB(yajl_s, yajl_complete_parse,
    [], [ AC_MSG_ERROR([YAJL library is not found]) ])
else
  AC_CHECK_LIB(yajl, yajl_complete_parse,
    [], [ AC_MSG_ERROR([YAJL library is not found]) ])
fi

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
[
  if test "x$withval" != "xno"; then
    AC_CHECK_LIB(rt, clock_gettime)
  fi
])

AC_ARG_WITH(pthread,
AS_HELP_STRING([--without-pthread],[disable pthread support (experimental)]),
[],
[ with_pthread=yes ])

if test "x$with_pthread" = "xyes"; then
  AC_CHECK_LIB(pthread, pthread_create)
  if test "x$ac_cv_lib_pthread_pthread_create" = "xno"; then
    AC_MSG_ERROR([pthread library is not found.])
  fi
else
  RUNTIME_DEFS="$RUNTIME_DEFS -DWITHOUT_MULTITHREAD"
fi

AC_ARG_WITH(massivethreads,
AS_HELP_STRING([--without-massivethreads],[use pthread instead of massivethreads]),
[
  case "x$withval" in
    xno) ;;
    xyes) ;;
    *) CPPFLAGS="$CPPFLAGS -I$withval/include"
       LDFLAGS="$LDFLAGS -L$withval/lib"
       with_massivethreads=yes
       ;;
  esac
],
[ with_massivethreads=yes ])

if test "x$with_massivethreads" = "xyes"; then
  if test "x$with_pthread" != "xyes"; then
    AC_MSG_ERROR([massivethreads requires pthread.])
  fi
  AC_CHECK_LIB(myth, myth_create)
  if test "x$ac_cv_lib_myth_myth_create" = "xno"; then
    AC_MSG_ERROR([massivethreads library is not found.])
  fi
else
  RUNTIME_DEFS="$RUNTIME_DEFS -DWITHOUT_MASSIVETHREADS"
fi

AC_ARG_ENABLE(concurrentgc,
AS_HELP_STRING([--disable-concurrentgc],[disable concurrent GC (experimental)]),
[
  if test "x$enableval" = "xno"; then
    if "x$with_massivethreads" = "xyes"; then
      AC_MSG_ERROR([massivethreads support requires concurrent GC.])
    fi
    RUNTIME_DEFS="$RUNTIME_DEFS -DWITHOUT_CONCURRENCY"
  fi
])

AC_CHECK_HEADERS(stdatomic.h, [], [
  AC_MSG_CHECKING([for GCC __atomic builtins])
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

AC_CHECK_TYPES([max_align_t])

case "$target_os" in
  *mingw*)
    AC_DEFINE(MINGW32, 1, [Define if your system is Windows])
    ;;
esac

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

# FIXME: check for method for dynamic linking.

# check whether C++ is available as well as C
AC_LANG_PUSH(C++)
AC_MSG_CHECKING([whether C++ linker is available])
AC_LINK_IFELSE([AC_LANG_CALL([], [__gmpz_init])],
  [ AC_MSG_RESULT(yes) ],
  [ AC_MSG_RESULT(no)
    AC_MSG_ERROR([failed to link libraries by $CXX.]) ])
AC_LANG_POP(C++)

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
REQUIRED_HEADER(pthread.h)
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

AC_DEFUN(CHECK_DECLS_GNU_SOURCE, [
  AC_CHECK_DECLS([$1],[$2],[
    unset ac_cv_have_decl_$1
    AC_CHECK_DECLS([$1],
      [ CPPFLAGS="$[]CPPFLAGS -D_GNU_SOURCE" ]
      [ $2 ],
      [ $3 ],
      [ #define _GNU_SOURCE ]
      [ $4 ])
  ],[$4])
])

CHECK_DECLS_GNU_SOURCE(RTLD_DEFAULT,,[
  AC_ERROR("RTLD_DEFAULT is required")
],[#include <dlfcn.h>])
CHECK_DECLS_GNU_SOURCE(RTLD_NEXT,,,[#include <dlfcn.h>])

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
# for utime
AC_CHECK_HEADERS(utime.h)

AC_CHECK_HEADERS([strings.h sys/socket.h])

AC_CHECK_HEADERS(libunwind.h)
AC_CHECK_FUNCS(unw_getcontext)

# -------- check for C language --------

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

# -------- Finale --------

AC_CONFIG_FILES([config.mk src/config.mk Makefile])
AC_CONFIG_FILES([stamp-h], [echo timestamp > stamp-h])
AC_OUTPUT

if test "x$no_create" != "xyes" && test "x$srcdir" != "x."; then
  (cd "$srcdir" && $FIND precompiled src -type d) | while read i; do
    AS_ECHO "creating directory $i"
    mkdir "$i"
  done
  for i in src/builtin.smi; do
    AS_ECHO "copying file $i"
    cp $srcdir/$i $i
  done
fi
