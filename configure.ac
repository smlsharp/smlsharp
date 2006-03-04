# -*- Autoconf -*-

AC_PREREQ(2.59)
AC_INIT(smlsharp)
AC_CONFIG_SRCDIR([src/compiler/toplevel/main/Top.sml])
AC_CONFIG_HEADER([config.h])

AC_CANONICAL_TARGET
AC_ARG_PROGRAM

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC

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
AC_CHECK_TOOL(AR, ar)
AC_CHECK_PROG(DOXYGEN, doxygen, :)

STUBLIBS=

case "$host_os" in
  *cygwin*|*mingw*)
    DLEXT='dll'
    DLSTUBEXT='dll.a'
    LIBEXT='a'
    AC_CHECK_TOOL(DLLTOOL, dlltool, :)
    AC_PATH_PROG(CYGPATH, cygpath)
    if test "x$CYGPATH" = "x"; then
      AC_MSG_ERROR([cygpath is not found.])
    fi
    AC_SUBST(CYGPATH)
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
# FIXME: check how to make a static library

AC_ARG_WITH(smlnj,
AS_HELP_STRING([--with-smlnj=DIR],[specify SML/NJ directory]),
[ PATH=${with_smlnj}/bin:$PATH ])

AC_PATH_PROG(SML, sml)
if test "x$SML" = "x"; then
  case "$host_os" in
    *cygwin*|*mingw*)
      AC_PATH_PROG(SML, sml.bat)
      ;;
  esac
fi
if test "x$SML" = "x"; then
  AC_MSG_ERROR([sml command is not found.])
fi
AC_SUBST(SML)

AC_MSG_CHECKING([for version of SML/NJ])
SMLNJ_VERSION=`echo | $SML | \
    sed -n -e 's/^Standard ML of New Jersey, Version \([[0-9\.]]*\).*/\1/' \
           -e 's/^Standard ML of New Jersey v\([[0-9\.]]*\).*/\1/' \
           -e '/^[[0-9.]]*$/p'`
AC_MSG_RESULT([$SMLNJ_VERSION])
case "$SMLNJ_VERSION" in
110.0.[[789]]) ;;
*)
  AC_MSG_WARN([This version of SML/NJ is not supported.])
  ;;
esac
AC_SUBST(SMLNJ_VERSION)

AC_PATH_PROG(SMLCM, sml-cm)
if test "x$SMLCM" = "x"; then
  case "$host_os" in
    *cygwin*|*mingw*)
      AC_PATH_PROG(SMLCM, sml-cm.bat)
      ;;
  esac
fi
if test "x$SMLCM" = "x"; then
  AC_MSG_ERROR([sml-cm command is not found.])
fi
AC_SUBST(SMLCM)

AC_MSG_CHECKING([for version of sml and sml-cm])
smlver=`echo | "$SML"`
smlcmver=`echo | "$SMLCM"`
if test "x$smlver" = "x$smlcmver"; then
  AC_MSG_RESULT([matched])
else
  AC_MSG_RESULT([mismatched])
  AC_MSG_ERROR([both sml and sml-cm must be the same version.])
fi

AC_MSG_CHECKING([for suffix of heap image])
(mkdir conftest && cd conftest \
 && echo 'SMLofNJ.exportFn("conftest",fn _=>OS.Process.success);' \
    | "$SMLCM" > /dev/null 2>&1)
SML_HEAP_SUFFIX=`(cd conftest && echo *) | sed 's,^conftest\.,,'`
AC_MSG_RESULT($SML_HEAP_SUFFIX)
if test "x$SML_HEAP_SUFFIX" = "x"; then
  AC_MSG_ERROR("failed.")
fi
AC_SUBST(SML_HEAP_SUFFIX)
rm -rf conftest

AC_MSG_CHECKING([for SMLFormat])
AC_ARG_WITH(smlformat,
AS_HELP_STRING([--with-smlformat=DIR],[specify SMLFormat directory]),
[ SMLFORMATDIR=$with_smlformat ],
[ if test -d "$srcdir/SMLFormat"; then
    SMLFORMATDIR=$PWD/$srcdir/SMLFormat
  else
    AC_MSG_RESULT(no)
    AC_MSG_ERROR([You must specify --with-smlformat.])
  fi
])
AC_MSG_RESULT([$SMLFORMATDIR])
AC_SUBST(SMLFORMATDIR)

AC_MSG_CHECKING([for SMLDoc])
AC_ARG_WITH(smldoc,
AS_HELP_STRING([--with-smldoc=DIR],[specify SMLDoc directory]),
[ SMLDOCDIR=$with_smldoc ],
[ if test -d "$srcdir/SMLDoc"; then
    SMLDOCDIR=$PWD/$srcdir/SMLDoc
  else
    AC_MSG_RESULT(no)
    AC_MSG_WARN([SMLDoc is not found.])
  fi
])
AC_MSG_RESULT([$SMLDOCDIR])
AC_SUBST(SMLDOCDIR)

AC_MSG_CHECKING([for SMLUnit])
AC_ARG_WITH(smlunit,
AS_HELP_STRING([--with-smlunit=DIR],[specify SMLUnit directory]),
[ SMLUNITDIR=$with_smlunit ],
[ if test -d "$srcdir/SMLUnit"; then
    SMLUNITDIR=$PWD/$srcdir/SMLUnit
  else
    AC_MSG_RESULT(no)
    AC_MSG_WARN([SMLUnit is not found.])
  fi
])
AC_MSG_RESULT([$SMLUNITDIR])
AC_SUBST(SMLUNITDIR)


# FIXME: There should be a more adequate place for config & make submodules.

if test "x$SMLFORMATDIR" = "x$PWD/$srcdir/SMLFormat"; then
  if test \! -f "$SMLFORMATDIR/bin/smlformat"; then
    echo "*** SMLFormat is not configured ***"
    (cd "$SMLFORMATDIR" && ./configure && make SML_CMD="$SML")
  fi
fi

if test "x$SMLDOCDIR" = "x$PWD/$srcdir/SMLDoc"; then
  if test \! -f "$SMLDOCDIR/bin/smldoc"; then
    echo "*** SMLDoc is not configured ***"
    (cd "$SMLDOCDIR" && ./configure && make SML_CMD="$SML")
  fi
fi


AC_PATH_PROG(SMLFORMAT, smlformat, [], [$SMLFORMATDIR/bin:$PATH])
if test "x$SMLFORMAT" = "x"; then
  AC_MSG_ERROR([smlformat is not found. please specify --with-smlformat.])
fi
AC_SUBST(SMLFORMAT)

if test "x$SMLDOCDIR" != "x"; then
  AC_PATH_PROG(SMLDOC, smldoc, [], [$SMLDOCDIR/bin:$PATH])
  if test "x$SMLDOC" = "x"; then
    AC_MSG_ERROR([smldoc is not found. please specify --with-smldoc.])
  fi
fi
AC_SUBST(SMLDOC)



# Checks for libraries.
AC_LANG(C++)
AC_CHECK_LIB(m, sqrt)
AC_CHECK_LIB(stdc++, main)
AC_CHECK_LIB(socket, socket)

AC_CHECK_LIB(dl, dlopen)
AC_CHECK_LIB(dld, shl_load)   # for HP-UX

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

# FIXME: check for extension of dynamic library and method to link at runtime.

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_CHECK_HEADERS([arpa/inet.h fcntl.h limits.h netinet/in.h stdlib.h \
                  string.h strings.h sys/socket.h sys/time.h unistd.h \
                  utime.h ieeefp.h floatingpoint.h])


# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST
AC_C_INLINE
AC_C_VOLATILE
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_STRUCT_TM

AC_TYPE_SIGNAL
AC_C_BIGENDIAN
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
                sigaction sigprocmask \
                fpclass])

if test "x$ac_cv_func_fpclass" != "xyes"; then
  AC_LIBOBJ(fpclass.c)
fi

# check for system characteristics
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

#
# NOTE: FreeBSD version < 4 may return yes.
#
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

# check for singal behaviour
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

# check for JNI
AC_ARG_ENABLE(jni,
AS_HELP_STRING([--enable-jni],[enable JNI support [[default=no]]]))
AC_ARG_WITH(java-home,
AS_HELP_STRING([--with-java-home=DIR],[JDK directory]))
AC_ARG_WITH(jdk-include,
AS_HELP_STRING([--with-java-include=DIR],[directory for JDK header files]))
AC_ARG_WITH(jdk-lib,
AS_HELP_STRING([--with-java-lib=DIR],[directory for JDK library files]))

if test "x$enable_jni" == "xyes"; then
  DEFS="$DEFS -DENABLE_JNI"
  dnl AC_DEFINE(ENABLE_JNI, 1, ENABLE_JNI)

  AC_MSG_CHECKING([for Java SDK home])
  if test "x$with_java_home" != "x"; then
    JDKDIR="$with_java_home"
    AC_MSG_RESULT($JDKDIR)
  elif test "x$JAVA_HOME" != "x"; then
    JDKDIR="$JAVA_HOME"
    AC_MSG_RESULT($JDKDIR)
  else
    AC_MSG_RESULT([not specified])
  fi

  AC_MSG_CHECKING([for CPPFLAGS for JNI])
  javainc="$with_java_include"
  if test "x$javainc" = "x"; then
    if test "x$JDKDIR" != "x" && test -d "$JDKDIR/include"; then
      javainc="$JDKDIR/include"
    fi
  fi
  if test "x$javainc" != "x"; then
    JDKCPPFLAGS="-I$javainc"
    jdk_os_type=`echo "$host_os" | sed 's,[.0-9]*$,,'`
    if test -f "$javainc/$jdk_os_type/jni_md.h"; then
      JDKCPPFLAGS="$JDKCPPFLAGS -I$javainc/$jdk_os_type"
    else
      for i in "$javainc"/*/jni_md.h; do
        jdk_md_dir=`AS_DIRNAME(["$i"])`
        JDKCPPFLAGS="$JDKCPPFLAGS -I$jdk_md_dir"
        break
      done
    fi
  fi
  AC_MSG_RESULT($JDKCPPFLAGS)
  CPPFLAGS="$CPPFLAGS $JDKCPPFLAGS"

  case "$host_os" in
  *cygwin*|*mingw*)
    STUBLIBS="$STUBLIBS libjvm.def"
    LIBS="$LIBS -ljvm"
    JDKLDFLAGS=
    JDKLIBPATH=
    AC_CHECK_TYPE(__int64, [], [ AC_CHECK_TYPE(long long) ])]
    if test "x$ac_cv_type___int64" = "xno"; then
      if test "x$ac_cv_type_long_long" = "xyes"; then
        AC_DEFINE(TYPEDEF_INT64, [typedef long long __int64;], [typedef])
      fi
    fi
    echo "TYPEDEF_INT64" >> confdefs.h
    ;;

  *)
    AC_MSG_CHECKING([for LDFLAGS for JNI])
    javalib="$with_java_lib"
    if test "x$javalib" = "x" && test "x$JDKDIR" != "x"; then
      case "$host_cpu" in
      i[3456]86) jdk_cpu="i386 i486 i586 i686" ;;
      *) jdk_cpu="" ;;
      esac
      for i in $host_cpu $jdk_cpu; do
        if test -d "$JDKDIR/jre/lib/$host_cpu"; then
          javalib="$JDKDIR/jre/lib/$host_cpu"
          break
        fi
      done
    fi
    if test "x$javalib" != "x"; then
      JDKLIBPATH="$javalib"
      JDKLDFLAGS="-L$javalib"
    fi
    AC_MSG_RESULT($JDKLDFLAGS)
    LDFLAGS="$LDFLAGS $JDKLDFLAGS"

    AC_MSG_CHECKING([for LD_LIBRARY_PATH for JNI])
    AC_MSG_RESULT($JDKLIBPATH)
    ;;
  esac

  AC_SUBST(JDKLIBPATH)

  AC_CHECK_HEADER([jni.h])
  if test "x$ac_cv_header_jni_h" != "xyes"; then
    AC_MSG_ERROR([jni.h is not found. specify --with-java-home.])
  fi

  if test "x$JDKLDFLAGS" != "x"; then
    AC_CHECK_LIB(jvm, JNI_CreateJavaVM)
    if test "x$ac_cv_lib_jvm_JNI_CreateJavaVM" != "xyes"; then
      AC_MSG_ERROR([jvm library is not found. specify --with-java-home.])
    fi

    iml_tmp_ldlibpath="$LD_LIBRARY_PATH"
    LD_LIBRARY_PATH="$JDKLIBPATH:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH
    AC_CACHE_CHECK([whether JNI is available], iml_cv_jni_work,
      [AC_RUN_IFELSE([AC_LANG_SOURCE([
#include <jni.h>
int main() {
  jint n;
  JavaVMInitArgs vm_args;
  JavaVM *jvm;
  JNIEnv *env;
  vm_args.version = JNI_VERSION_1_2;
  vm_args.nOptions = 0;
  n = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
  if (n < 0) exit(1);
  jvm->DestroyJavaVM();
  return 0;
}
  ])], [ iml_cv_jni_work=yes ],
       [ iml_cv_jni_work=no ],
       [ iml_cv_jni_work=no ])])
    unset LD_LIBRARY_PATH
    LD_LIBRARY_PATH="$iml_tmp_ldlibpath"
    if test "x$iml_cv_jni_work" = "xno"; then
      AC_MSG_ERROR([JNI is not available.])
    fi
  fi
fi # test "x$enable_jni" = "xyes"


# Extra switches for developers.

AC_ARG_ENABLE(unboxed-float,
AS_HELP_STRING([--enable-unboxed-float],[unboxed float [[default=yes]]]))
if test "x$enable_unboxed_float" != "xno"; then
  DEFS="$DEFS -DFLOAT_UNBOXING"
  dnl AC_DEFINE(FLOAT_UNBOXING, 1, FLOAT_UNBOXING)
fi

AC_ARG_ENABLE(debug,
AS_HELP_STRING([--enable-debug],
               [enable debug (for developer only) [[default=no]]]))
if test "x$enable_debug" = "xyes"; then
  DEFS="$DEFS -DIML_DEBUG -DIML_ENABLE_EXECUTION_MONITORING"
  # remove default -O options.
  if test "x$ac_env_CFLAGS_value" = "x"; then
    CFLAGS=`echo "$CFLAGS" | sed 's,-O[[0-9]]*,,g'`
  fi
  if test "x$ac_env_CXXFLAGS_value" = "x"; then
    CXXFLAGS=`echo "$CXXFLAGS" | sed 's,-O[[0-9]]*,,g'`
  fi
else
  DEFS="$DEFS -DNDEBUG"
fi

AC_ARG_ENABLE(monitoring,
AS_HELP_STRING([--enable-monitoring],
               [enable monitoring (for developer only) [[default=no]]]))
if test "x$enable_monitoring" = "xyes"; then
  DEFS="$DEFS -DIML_ENABLE_EXECUTION_MONITORING"
fi

AC_ARG_ENABLE(profile,
AS_HELP_STRING([--enable-profile],
               [enable profiling (for developer only) [[default=no]]]))
if test "x$enable_profile" = "xyes"; then
  CFLAGS="$CFLAGS -pg"
  LIBS="$LIBS -lgmon"
fi

DEFS="$DEFS -DUSE_NAMESPACE"
CPPFLAGS="$CPPFLAGS $DEFS"


# setup stub libraries.

if test "x$STUBLIBS" != "x"; then
  if test "x$DLLTOOL" = "x:"; then
    AC_MSG_ERROR([stub library required but dlltool is not found: $STUBLIBS])
  fi
  LIBS="$LIBS -L\$(STUBLIBDIR)"
fi
AC_SUBST(STUBLIBS)


# finish.

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
                 src/compiler/Makefile
                 src/lib/Makefile
                 src/lib/Script/Makefile
                 src/runtime/Makefile
                 src/runtime/runtime-core/main/Makefile
                 src/runtime/runtime-impl/main/Makefile
                 src/runtime/byterun/main/Makefile
                 doc/Makefile
])
AC_OUTPUT
#                 src/configuration/Configuration.sml
