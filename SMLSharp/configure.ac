# -*- Autoconf -*-
# $Id: configure.ac,v 1.53 2010/01/19 11:26:31 katsu Exp $

AC_PREREQ(2.61)
AC_INIT(smlsharp)
AC_CONFIG_SRCDIR([src/compiler/toplevel/main/Top.sml])
AC_CONFIG_HEADER([config.h])

AC_CANONICAL_TARGET
AC_ARG_PROGRAM

AC_DEFINE_UNQUOTED(SMLSHARP_PLATFORM, "${target_cpu}-${target_os}",
                   [platform identifier])
SMLSHARP_PLATFORM="${target_cpu}-${target_os}"
AC_SUBST(SMLSHARP_PLATFORM)

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC
AC_LANG(C)

## default optimization flag is -O. -O2 may cause some trouble.
if test "x$ac_env_CFLAGS_value" = "x"; then
  CFLAGS=`echo "$CFLAGS" | sed 's,-O2,-O,'`
fi
if test "x$ac_env_CXXFLAGS_value" = "x"; then
  CXXFLAGS=`echo "$CXXFLAGS" | sed 's,-O2,-O,'`
fi

AC_PROG_MAKE_SET
AC_PROG_INSTALL
AC_PATH_PROG(FIND, find)
AC_PROG_RANLIB
AC_CHECK_TOOL(LD, ld)
AC_CHECK_TOOL(AR, ar)
AC_CHECK_TOOL(WINDRES, windres)
AC_PATH_PROG(DOXYGEN, doxygen)

STUBLIBS=

case "$host_os" in
  *cygwin*|*mingw*)
    DLEXT='dll'
    DLSTUBEXT='dll.a'
    LIBEXT='a'
    AC_CHECK_TOOL(DLLTOOL, dlltool, :)
    AC_PATH_PROG(CYGPATH, cygpath)
    if test "x$CYGPATH" = "x"; then
      case "$host_os" in
        *cygwin*)
          AC_MSG_ERROR([cygpath is not found.])
          ;;
      esac
    fi
    AC_SUBST(CYGPATH)
    if test "x$WINDRES" != "x"; then
      RESOURCE_TYPE=rc
    fi
    AC_SUBST(RESOURCE_TYPE)
    ;;
  *)
    DLEXT='so'
    DLSTUBEXT='a'
    LIBEXT='a'
    ;;
esac
AC_SUBST(DLEXT)
AC_SUBST(DLSTUBEXT)
AC_SUBST(LIBEXT)

# flags to generate src/runtime/byterun/main/libsmlsharp.{dll,so}
# This is experimental.
case "$host_os" in
  *solaris*)
        CFLAGS="$CFLAGS -fPIC"
        CXXFLAGS="$CXXFLAGS -fPIC"
        ;;
  *)
        ;;
esac
case "$host_os" in
  *darwin*)
        DL_LDFLAGS=-dynamiclib
        ;;
  *)
        DL_LDFLAGS=-shared
        ;;
esac
AC_SUBST(DL_LDFLAGS)

# FIXME: check how to make a static library

# -------- Checks for SML/NJ --------

AC_ARG_WITH(smlnj,
AS_HELP_STRING([--with-smlnj=DIR],[specify SML/NJ directory]),
[ PATH=${with_smlnj}/bin:$PATH ])

AC_PATH_PROG(SML, sml)
if test "x$SML" = "x"; then
  case "$host_os" in
    *cygwin*)
      AC_PATH_PROG(SML, sml.bat)
      SML_BAT="$SML"
      ;;
    *mingw*)
      AC_PATH_PROG(SML, sml.bat)
      if test "x$SML" != "x"; then
        SML_BAT=`echo "$SML" | sed 's,^/\\([[a-zA-Z]]\\)/,\\1:/,;s,//*,/,g'`
        if test -f "$SML_BAT"; then
          SML="cmd /c $SML_BAT"
        else
          AC_MSG_ERROR([$SML is found, but $sml_bat is not found.])
        fi
      fi
      ;;
  esac
  AC_SUBST(SML_BAT)
fi
if test "x$SML" = "x"; then
  AC_MSG_ERROR([sml command is not found.])
fi
AC_SUBST(SML)

AC_MSG_CHECKING([for version of SML/NJ])
SMLNJ_VERSION=`echo | $SML 2>&1`
if test "x$?" = "x0"; then
  SMLNJ_VERSION=`echo "$SMLNJ_VERSION" | \
    sed -n -e 's/^Standard ML of New Jersey, Version \\([[0-9\.]]*\\).*/\1/' \
           -e 's/^Standard ML of New Jersey v\\([[0-9\.]]*\\).*/\\1/' \
           -e '/^[[0-9.]]*$/p'`
  AC_MSG_RESULT([$SMLNJ_VERSION])
else
  AC_MSG_ERROR([$SML failed.])
fi

case "$SMLNJ_VERSION" in
#  110.0.[[789]])
#    NEW_CM=no
#    AC_PATH_PROG(SMLCM, sml-cm)
#    if test "x$SMLCM" = "x"; then
#      case "$host_os" in
#        *cygwin*)
#          AC_PATH_PROG(SMLCM, sml-cm.bat)
#          SMLCM_BAT="$SMLCM"
#          ;;
#        *mingw*)
#          AC_PATH_PROG(SMLCM, sml-cm.bat)
#          if test "x$SMLCM" != "x"; then
#            SMLCM_BAT=`echo "$SMLCM" | \
#                       sed 's,^/\\([[a-zA-Z]]\\)/,\\1:/,;s,//*,/,g'`
#            if test -f "$SMLCM_BAT"; then
#              SMLCM="cmd /c $SMLCM_BAT"
#            else
#              AC_MSG_ERROR([$SML is found, but $sml_bat is not found.])
#            fi
#          fi
#          ;;
#      esac
#      AC_SUBST(SMLCM_BAT)
#    fi
#    if test "x$SMLCM" = "x"; then
#      AC_MSG_ERROR([sml-cm command is not found.])
#    fi
#
#    AC_MSG_CHECKING([for version of sml and sml-cm])
#    smlver=`echo | $SML`
#    smlcmver=`echo | $SMLCM`
#    if test "x$smlver" = "x$smlcmver"; then
#      AC_MSG_RESULT([matched])
#    else
#      AC_MSG_RESULT([mismatched])
#     AC_MSG_ERROR([both sml and sml-cm must be the same version.])
#    fi
#    ;;
#
  110.5[[3-9]]|110.[[6-9]][[0-9]])
    # NOTE: SML/NJ 110.52 or earlier unstable version tells a lie
    #       that PowerPC is LITTLE_ENDIAN.
    NEW_CM=yes
    SMLCM="$SML"
    ;;

  *)
    if expr "$SMLNJ_VERSION" : ['.*[^0-9.]'] > /dev/null 2>&1; then
      AC_MSG_ERROR([cannot detect SML/NJ version number. $SML does not seem to work.])
    fi
    AC_MSG_WARN([This version of SML/NJ is not supported.])
    ;;
esac

AC_SUBST(SMLNJ_VERSION)
AC_SUBST(SMLCM)
AC_SUBST(NEW_CM)

AC_MSG_CHECKING([for suffix of heap image])
(mkdir conftest && cd conftest \
 && echo 'SMLofNJ.exportFn("conftest",fn _=>OS.Process.success);' \
    | $SMLCM > /dev/null 2>&1)
SML_HEAP_SUFFIX=`(cd conftest && echo *) | sed 's,^conftest\\.,,'`
AC_MSG_RESULT($SML_HEAP_SUFFIX)
if test "x$SML_HEAP_SUFFIX" = "x" || test "x$SML_HEAP_SUFFIX" = "x*"; then
  AC_MSG_ERROR("failed.")
fi
AC_SUBST(SML_HEAP_SUFFIX)
rm -rf conftest

# -------- Checks for MLton --------

USE_MLTON=no
MLTON=mlton
MLTON_LEX=mllex
MLTON_YACC=mlyacc

AC_ARG_WITH(mlton,
AS_HELP_STRING([--with-mlton=DIR],[use MLton for compiling frontend]),
[
  USE_MLTON=yes

  if test "x$with_mlton" = "x"; then
    mlton_path=$PATH
  else
    mlton_path=${with_mlton}/bin:$PATH
  fi

  AC_PATH_PROG(MLTON, mlton, [], $mlton_path)
  if test "x$MLTON" = "x"; then
    AC_MSG_ERROR([mlton command is not found.])
  fi

  AC_PATH_PROG(MLTON_LEX, mllex, [], $mlton_path)
  if test "x$MLTON_LEX" = "x"; then
    AC_MSG_ERROR([ml-lex command is not found.])
  fi

  AC_PATH_PROG(MLTON_YACC, mlyacc, [], $mlton_path)
  if test "x$MLTON_YACC" = "x"; then
    AC_MSG_ERROR([ml-yacc command is not found.])
  fi
])

AC_SUBST(USE_MLTON)
AC_SUBST(MLTON)
AC_SUBST(MLTON_LEX)
AC_SUBST(MLTON_YACC)
AC_SUBST(MLTON_FLAGS)

# ------- Checks for Java Environment --------

AC_ARG_WITH(java-home,
AS_HELP_STRING([--with-java-home=DIR],[specify JRE directory]))
AC_ARG_WITH(java-lib,
AS_HELP_STRING([--with-java-lib=DIR],[directory for JRE library files]))

if test "x$with_java_home" != "x"; then
  JAVADIR="$with_java_home"
elif test "x$JAVA_HOME" != "x"; then
  JAVADIR="$JAVA_HOME"
fi
AC_SUBST(JAVADIR)

if test "x$with_java_lib" != "x"; then
  JAVALIBDIR="$with_java_lib"
elif test "x$JAVADIR" != "x"; then
  case "$host_cpu" in
    i[3456]86) jre_cpu="i386 i486 i586 i686" ;;
    *) jre_cpu="" ;;
  esac
  for i in $host_cpu $jre_cpu; do
    if test -d "$JAVADIR/jre/lib/$host_cpu"; then
      JAVALIBDIR="$JAVADIR/jre/lib/$host_cpu"
      break
    fi
  done
else
  case "$target_os" in
    *darwin*)
      if test -d "/System/Library/Frameworks/JavaVM.framework/Libraries"; then
        JAVALIBDIR=/System/Library/Frameworks/JavaVM.framework/Libraries
      fi
      ;;
  esac
fi
AC_SUBST(JAVALIBDIR)

AC_PATH_PROG(JAVA, java)
AC_PATH_PROG(JAVAC, javac)
AC_PATH_PROG(JAR, jar)

# ------- Checks for subprojects (SMLFormat, etc.) --------

SUBPROJECTS=""
AC_SUBST(SUBPROJECTS)

SUBPROJECTS="$SUBPROJECTS smlnj-lib"
SMLNJLIBDIR="$PWD/$srcdir/../smlnj-lib"
AC_SUBST(SMLNJLIBDIR)
AC_CONFIG_FILES([smlnj-lib/Makefile:../smlnj-lib/Makefile.in])

#SUBPROJECTS="$SUBPROJECTS mllex"
SMLLEXDIR="$PWD/$srcdir/../mllex"
SMLLEX='$(top_builddir)/mllex/smllex'
AC_SUBST(SMLLEXDIR)
AC_SUBST(SMLLEX)
AC_CONFIG_FILES([mllex/Makefile:../mllex/Makefile.in])

#SUBPROJECTS="$SUBPROJECTS mlyacc"
SMLYACCDIR="$PWD/$srcdir/../mlyacc"
SMLYACC='$(top_builddir)/mlyacc/smlyacc'
AC_SUBST(SMLYACCDIR)
AC_SUBST(SMLYACC)
AC_CONFIG_FILES([mlyacc/Makefile:../mlyacc/Makefile.in])

SUBPROJECTS="$SUBPROJECTS SMLFormat"
SMLFORMATDIR="$PWD/$srcdir/../SMLFormat"
SMLFORMAT='$(top_builddir)/SMLFormat/smlformat'
AC_SUBST(SMLFORMATDIR)
AC_SUBST(SMLFORMAT)
AC_CONFIG_FILES([SMLFormat/Makefile:../SMLFormat/Makefile.in])

AC_MSG_CHECKING([for building SMLDoc])
AC_ARG_WITH(smldoc,
AS_HELP_STRING([--with-smldoc], [compile and install SMLDoc [[default=yes]]]))
if test "x$with_smldoc" = "xno"; then
  AC_MSG_RESULT([no])
else
  SUBPROJECTS="$SUBPROJECTS SMLDoc"
  SMLDOCDIR="$PWD/$srcdir/../SMLDoc"
  SMLDOC='$(top_builddir)/SMLDoc/smldoc'
  AC_SUBST(SMLDOCDIR)
  AC_SUBST(SMLDOC)
  AC_CONFIG_FILES([SMLDoc/Makefile:../SMLDoc/Makefile.in])
  AC_MSG_RESULT([yes])
fi

AC_MSG_CHECKING([for building SMLUnit])
AC_ARG_WITH(smlunit,
AS_HELP_STRING([--with-smlunit], [compile and install SMLUnit [[default=yes]]]))
if test "x$with_smlunit" = "xno"; then
  AC_MSG_RESULT([no])
else
  SUBPROJECTS="$SUBPROJECTS SMLUnit"
  SMLUNITDIR="$PWD/$srcdir/../SMLUnit"
  AC_SUBST(SMLUNITDIR)
  AC_CONFIG_FILES([SMLUnit/Makefile:../SMLUnit/Makefile.in])
  AC_MSG_RESULT([yes])
fi

# -------- Checks for libffi --------

AC_MSG_CHECKING([for building libffi])
AC_ARG_ENABLE(libffi,
AS_HELP_STRING([--enable-libffi],[use libffi [[default=yes]]]))
if test "x$enable_libffi" = "xyes"; then
  SUBPROJECTS="$SUBPROJECTS libffi"
  LIBFFIDIR="$PWD/$srcdir/../libffi"
  AC_SUBST(LIBFFIDIR)
  AC_CONFIG_FILES([libffi/Makefile:../libffi/Makefile.in])
  AC_MSG_RESULT([yes])
  LIBFFI_CPPFLAGS="-I\$(top_builddir)/libffi/libffi/include"
  LIBFFI_LDFLAGS="-L\$(top_builddir)/libffi/libffi/.libs"
  LIBFFI_LIBS="-lffi"
  USE_LIBFFI=yes
else
  AC_MSG_RESULT([no])
  LIBFFI_CPPFLAGS="-DNOLIBFFI"
  LIBFFI_LDFLAGS=
  LIBFFI_LIBS=
  USE_LIBFFI=no
fi
AC_SUBST(LIBFFI_CPPFLAGS)
AC_SUBST(LIBFFI_LDFLAGS)
AC_SUBST(LIBFFI_LIBS)

# ------- Checks for tools --------

TOOLS="smlsharp2exe"
AC_SUBST(TOOLS)

AC_ARG_WITH(mlb2use,
AS_HELP_STRING([--with-mlb2use], [compile and install mlb2use]))
if test "x$with_mlb2use" != "xno" && test "x$USE_MLTON" = "xyes"; then
  TOOLS="$TOOLS mlb2use"
elif test "x$with_mlb2use" = "xyes"; then
  AC_MSG_WARN([mlb2use will not be built.])
else
  AC_MSG_NOTICE([mlb2use will not be built.])
fi

AC_ARG_WITH(java-tool,
AS_HELP_STRING([--with-java-tool], [compile and install SML# Java tool]))
if test "x$with_java_tool" != "xno" && test "x$JAVAC" != "x"; then
  TOOLS="$TOOLS Java"
elif test "x$with_java_tool" = "xyes"; then
  AC_MSG_WARN([Java tool will not be built.])
else
  AC_MSG_NOTICE([Java tool will not be built.])
fi

AC_ARG_WITH(ole-tool,
AS_HELP_STRING([--with-ole-tool], [compile and install SML# OLE tool]))
if test "x$with_ole_tool" != "xno"; then
  case "$target_os" in
  *cygwin*|*mingw*)
    TOOLS="$TOOLS OLE"
    ;;
  *)
    if test "x$with_ole_tool" = "xyes"; then
      AC_MSG_WARN([OLE tool will not be built.])
    else
      AC_MSG_NOTICE([OLE tool will not be built.])
    fi
    ;;
  esac
fi

AC_MSG_CHECKING([tools to be built])
AC_MSG_RESULT([$TOOLS])

# -------- Checks for FFI --------

FFI_STUB=default
LIBFFI_BUILD=
FFI_MAX_ARGS=10:5

AC_ARG_WITH(ffi-max-args,
AS_HELP_STRING([--with-ffi-max-args=NUM],[specify the maximum number of arguments of foreign function [[default=10:5]]]),
[ FFI_MAX_ARGS=$with_ffi_max_args ])

AC_MSG_CHECKING([for the max number of arguments])
if expr "x$FFI_MAX_ARGS" : ['x[0-9][0-9]*:[0-9][0-9]*$'] > /dev/null 2>&1; then
  FFI_MAX_ARGS=`echo "$FFI_MAX_ARGS" | sed 's/:/ /'`
elif expr "x$FFI_MAX_ARGS" : ['x[0-9][0-9]*$'] > /dev/null 2>&1; then
  FFI_MAX_ARGS="$FFI_MAX_ARGS $FFI_MAX_ARGS"
else
  AC_MSG_RESULT($FFI_MAX_ARGS)
  AC_MSG_ERROR([invalid --with-ffi-max-args option])
fi
AC_MSG_RESULT($FFI_MAX_ARGS)
AC_SUBST(FFI_MAX_ARGS)
AC_SUBST(FFI_STUB)
AC_SUBST(LIBFFI_BUILD)

# -------- Checks for Libraries --------

AC_CHECK_LIB(m, sqrt)
AC_CHECK_LIB(socket, socket)
AC_LANG_PUSH(C++)
AC_CHECK_LIB(stdc++, main,
[
  LIBSTDCXX="-lstdc++"
  AC_DEFINE(HAVE_LIBSTDC__, 1,
            [Define to 1 if you have the `stdc++' library (-lstdc++).])
])
AC_SUBST(LIBSTDCXX)
AC_LANG_POP(C++)

AC_CHECK_LIB(gmp, __gmpz_init)
if test "x$ac_cv_lib_gmp___gmpz_init" = "xno"; then
    AC_MSG_ERROR([GMP library is not found.])
fi

AC_CHECK_LIB(dl, dlopen)
AC_CHECK_LIB(dld, shl_load)   # for HP-UX

AC_ARG_WITH(rt,
AS_HELP_STRING([--with-rt],[try to use clock_gettime for benchmark]),
[ AC_CHECK_LIB(rt, clock_gettime) ])

## cygwin has dlopen in libcygwin.dll.

if test "x$ac_cv_lib_dl_dlopen" = "xno"; then
  case "$host_os" in
  *cygwin*)
    AC_SEARCH_LIBS(dlopen, [dl],
    [ ac_cv_lib_dl_dlopen=yes; echo "#define HAVE_LIBDL 1" >> confdefs.h ])
    ;;
  *)
    ;;
  esac
fi

# FIXME: check for method to link at runtime.

# -------- Checks for Header Files --------

AC_HEADER_DIRENT
AC_HEADER_STDC
AC_CHECK_HEADERS([arpa/inet.h fcntl.h limits.h netinet/in.h stdlib.h \
                  string.h strings.h sys/socket.h time.h unistd.h \
                  poll.h utime.h ieeefp.h floatingpoint.h inttypes.h gmp.h])


# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST
AC_C_INLINE
AC_C_VOLATILE
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_STRUCT_TM

AC_C_BIGENDIAN([
  AC_DEFINE(WORDS_BIGENDIAN, [1], [Define if your processor is big endian])
  BYTE_ORDER=Big
], [
  BYTE_ORDER=Little
])
AC_SUBST(BYTE_ORDER)

AC_TYPE_SIGNAL
AC_CHECK_SIZEOF(int)
AC_CHECK_SIZEOF(bool)
AC_CHECK_SIZEOF(short)
AC_CHECK_SIZEOF(long)
AC_CHECK_SIZEOF(void*)
AC_CHECK_SIZEOF(float)
AC_CHECK_SIZEOF(double)

# Checks for library functions.
AC_FUNC_CLOSEDIR_VOID
AC_FUNC_ERROR_AT_LINE
AC_FUNC_FORK
AC_FUNC_MALLOC
AC_FUNC_MEMCMP
AC_FUNC_MKTIME
AC_FUNC_REALLOC
AC_TYPE_SIGNAL
AC_FUNC_STAT
AC_FUNC_STRFTIME
AC_FUNC_UTIME_NULL
AC_CHECK_FUNCS([bzero floor getcwd gettimeofday localtime_r memmove \
                memset mkdir modf pow rmdir socket sqrt strerror utime \
                sigaction sigprocmask sleep dlopen finite fpclass copysign \
                clock_gettime getrusage times])
AC_CHECK_DECLS([CLOCK_PROCESS_CPUTIME_ID],,,[#include <time.h>])
AC_CHECK_DECLS([fpclassify, isinf, isnan, isnormal, signbit],,,
               [#include <math.h>])

if test "x$ac_cv_func_fpclass" != "xyes"; then
  AC_LIBOBJ(fpclass.c)
fi

# -------- Checks for Signal Behaviour --------

AC_CACHE_CHECK([for SIGFPE by division by 0], iml_cv_sigfpe_intdiv,
  [AC_RUN_IFELSE([AC_LANG_SOURCE([
#include <signal.h>
#include <stdlib.h>
RETSIGTYPE sigfpe(int signum) { exit(0); }
volatile int divide(int a, int b) { return a / b; }
int main() {
  volatile int a;
  signal(SIGFPE, sigfpe);
  a = divide(1, 0);
  exit(1);
}
])], [ iml_cv_sigfpe_intdiv=yes ],
     [ iml_cv_sigfpe_intdiv=no ],
     [ iml_cv_sigfpe_intdiv=no ])])

# NOTE: FreeBSD version < 4 may return yes.
AC_CACHE_CHECK([for SIGFPE by division by 0.0], iml_cv_sigfpe_fltdiv,
  [AC_RUN_IFELSE([AC_LANG_SOURCE([
#include <signal.h>
#include <stdlib.h>
RETSIGTYPE sigfpe(int signum) { exit(0); }
volatile double divide(double a, double b) { return a / b; }
int main() {
  volative double d;
  signal(SIGFPE, sigfpe);
  d = divide(1.0, 0.0);
  exit(1);
}
])], [ iml_cv_sigfpe_fltdiv=yes ],
     [ iml_cv_sigfpe_fltdiv=no ],
     [ iml_cv_sigfpe_fltdiv=no ])])

if test "x$ac_cv_func_sigprocmask" = "xyes" \
   && test "x$ac_cv_func_sigaction" = "xyes"; then
  AC_DEFINE(POSIX_SIGNAL, 1, POSIX_SIGNAL)
fi
AC_CACHE_CHECK(for BSD signal semantics, iml_cv_bsd_signal,
  [AC_RUN_IFELSE([AC_LANG_SOURCE([
#include <signal.h>
void sigint(int signum) {}
int main() {
  signal(SIGINT, sigint);
  kill(getpid(), SIGINT);
  kill(getpid(), SIGINT);
  return 0;
}
])], [ iml_cv_bsd_signal=yes ],
     [ iml_cv_bsd_signal=no ],
     [ iml_cv_bsd_signal=no ])])
if test "x$iml_cv_bsd_signal" = "xyes"; then
  AC_DEFINE(BSD_SIGNAL, 1, BSD_SIGNAL)
fi

# -------- Extra Switches for Developers --------

AC_ARG_ENABLE(unboxed-float,
AS_HELP_STRING([--enable-unboxed-float],[unboxed float [[default=yes]]]))
if test "x$enable_unboxed_float" != "xno"; then
  RUNTIME_DEFS="$RUNTIME_DEFS -DFLOAT_UNBOXING"
  dnl AC_DEFINE(FLOAT_UNBOXING, 1, FLOAT_UNBOXING)
fi

AC_ARG_ENABLE(debug,
AS_HELP_STRING([--enable-debug],
               [enable debug (for developer only) [[default=no]]]))
if test "x$enable_debug" = "xyes"; then
  RUNTIME_DEFS="$RUNTIME_DEFS -DIML_DEBUG -DIML_ENABLE_EXECUTION_MONITORING"
  # remove default -O options.
  if test "x$ac_env_CFLAGS_value" = "x"; then
    CFLAGS=`echo "$CFLAGS" | sed 's,-O[[0-9]]*,,g'`
  fi
  if test "x$ac_env_CXXFLAGS_value" = "x"; then
    CXXFLAGS=`echo "$CXXFLAGS" | sed 's,-O[[0-9]]*,,g'`
  fi
else
  RUNTIME_DEFS="$RUNTIME_DEFS -DNDEBUG"
fi

AC_ARG_ENABLE(monitoring,
AS_HELP_STRING([--enable-monitoring],
               [enable monitoring (for developer only) [[default=no]]]))
if test "x$enable_monitoring" = "xyes"; then
  RUNTIME_DEFS="$RUNTIME_DEFS -DIML_ENABLE_EXECUTION_MONITORING"
fi

AC_ARG_ENABLE(profile,
AS_HELP_STRING([--enable-profile],
               [enable profiling (for developer only) [[default=no]]]))
if test "x$enable_profile" = "xyes"; then
  CFLAGS="$CFLAGS -pg"
  LIBS="$LIBS -lgmon"
fi

RUNTIME_DEFS="$RUNTIME_DEFS -DUSE_NAMESPACE"
AC_SUBST(RUNTIME_DEFS)

case "$target" in
  i[[3456]]86-*-linux*) NATIVE_TARGET=x86-linux ;;
  i[[3456]]86-*-darwin*) NATIVE_TARGET=x86-darwin ;;
  *) NATIVE_TARGET= ;;
esac

AC_MSG_CHECKING([for native code generation])
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
  esac ])

if test "x$NATIVE_TARGET" = "x"; then
  NATIVE_RUNTIME=
  NATIVE_PRELUDE=
  AC_MSG_RESULT([no])
else
  NATIVE_RUNTIME=nativeruntime
  NATIVE_PRELUDE=ntprelude.smc
  AC_MSG_RESULT([$NATIVE_TARGET])
fi
AC_SUBST(NATIVE_RUNTIME)
AC_SUBST(NATIVE_TARGET)
AC_SUBST(NATIVE_PRELUDE)

AC_ARG_ENABLE(heapimpl,
AS_HELP_STRING([--enable-heapimpl],
               [select heap implemenatation of native backend [[default=bitmap]]]),
[ NATIVE_HEAPIMPL=$enable_heapimpl ],
[ NATIVE_HEAPIMPL=bitmap ])
if test "x$NATIVE_TARGET" = "x"; then
  :
else
  AC_MSG_CHECKING([for heap implementation of native backend])
  AC_MSG_RESULT([$NATIVE_HEAPIMPL])
fi
if test -f "$srcdir/src/nativeruntime/heap_$NATIVE_HEAPIMPL.h"; then
  :
else
  AC_MSG_ERROR([heap implementation \`$NATIVE_HEAPIMPL\' is not available.])
fi
AC_SUBST(NATIVE_HEAPIMPL)

# -------- Setup Stub Libraries --------

if test "x$STUBLIBS" != "x"; then
  if test "x$DLLTOOL" = "x:"; then
    AC_MSG_ERROR([stub library required but dlltool is not found: $STUBLIBS])
  fi
  LIBS="$LIBS -L\$(STUBLIBDIR)"
fi
AC_SUBST(STUBLIBS)

# -------- Finale --------

# For subprojects.
AC_SUBST(DEFAULT_SML_COMPILER, "smlnj")

AC_CONFIG_FILES([commonrule
                 mksmlheap
                 mksmlrun
                 mksmlpath
                 Makefile
                 stublibs/Makefile
                 src/Makefile
                 src/configuration/Makefile
                 src/primitives/Makefile
                 src/primitives/generator/main/Makefile
                 src/primitives/runtime/main/Makefile
                 src/primitives/compiler/main/Makefile
                 src/instructions/Makefile
                 src/instructions/generator/Makefile
                 src/instructions/runtime/main/Makefile
                 src/instructions/compiler/main/Makefile
                 src/vmgen/Makefile
                 src/yaruntime/Makefile
                 src/nativeruntime/Makefile
                 src/compiler/Makefile
                 src/lib/Makefile
                 src/lib/basis/Makefile
                 src/lib/CConfig/Makefile
                 src/lib/FFI/Makefile
                 src/lib/LMLML/Makefile
                 src/lib/Script/Makefile
                 src/lib/SMLSharp/Makefile
                 src/runtime/Makefile
                 src/runtime/runtime-core/main/Makefile
                 src/runtime/runtime-impl/main/Makefile
                 src/runtime/icons/Makefile
                 src/runtime/byterun/main/Makefile
                 src/tool/Makefile
                 src/tool/Java/Makefile
                 src/tool/OLE/Makefile
                 src/tool/smlsharp2exe/Makefile
                 src/tool/mlb2use/Makefile
                 doc/Makefile
])
AC_OUTPUT
#                 src/configuration/Configuration.sml

if test "x$USE_LIBFFI" = "xyes"; then
  AC_MSG_NOTICE([starting configure libffi])
  if test -f liffi/libffi/config.status; then
    AC_MSG_NOTICE([libffi is already configured.])
  else
    mkdir libffi/libffi 2> /dev/null
    if cd libffi/libffi && \
       ../../$srcdir/../libffi/libffi/configure \
         --disable-shared --enable-static
    then
      :
    else
      AC_MSG_ERROR([configure libffi failed. try again with --disable-libffi])
    fi
  fi
fi
