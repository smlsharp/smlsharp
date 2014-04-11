(**
 * wrapper of libdl.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 6 +
infix 4 < =
infix 3 :=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op < = SMLSharp_Builtin.Int.lt

structure DynamicLink =
struct

  type lib = unit ptr
  datatype scope = LOCAL | GLOBAL
  datatype mode = LAZY | NOW

  val c_dlopen =
      _import "dlopen"
      : __attribute__((no_callback))
        (string, int) -> lib
  val c_dlsym =
      _import "dlsym"
      : __attribute__((no_callback))
        (lib, string) -> unit ptr
  val c_dlerror =
      _import "dlerror"
      : __attribute__((no_callback))
        () -> char ptr
  val c_dlclose =
      _import "dlclose"
      : __attribute__((no_callback))
        lib -> int

  local
    val loaded = ref false
    val RTLD_LAZY = ref 0
    val RTLD_NOW = ref 0
    val RTLD_LOCAL = ref 0
    val RTLD_GLOBAL = ref 0

    val const_RTLD_LAZY =
        _import "prim_const_RTLD_LAZY"
        : __attribute__((pure,no_callback)) () -> int
    val const_RTLD_NOW =
        _import "prim_const_RTLD_NOW"
        : __attribute__((pure,no_callback)) () -> int
    val const_RTLD_LOCAL =
        _import "prim_const_RTLD_LOCAL"
        : __attribute__((pure,no_callback)) () -> int
    val const_RTLD_GLOBAL =
        _import "prim_const_RTLD_GLOBAL"
        : __attribute__((pure,no_callback)) () -> int
  in
    fun dlopenMode (scope, mode) =
      let
        val _ =
            if !loaded then () else
            (RTLD_LAZY := const_RTLD_LAZY ();
             RTLD_NOW := const_RTLD_NOW ();
             RTLD_LOCAL := const_RTLD_LOCAL ();
             RTLD_GLOBAL := const_RTLD_GLOBAL ();
             loaded := true)
        val scope = case scope of LOCAL => !RTLD_LOCAL | GLOBAL => !RTLD_GLOBAL
        val mode = case mode of LAZY => !RTLD_LAZY | NOW => !RTLD_NOW
      in
        scope + mode
      end
  end (* local *)

  fun dlerror () =
      SMLSharp_Runtime.str_new (c_dlerror ())

  fun dlopen' (libname, scope, mode) =
      let
        val lib = c_dlopen (libname, dlopenMode (scope, mode))
      in
        if lib = _NULL
        then raise SMLSharp_Runtime.SysErr (dlerror (), NONE)
        else lib
      end

  fun dlopen libname =
      dlopen' (libname, LOCAL, LAZY)

  fun dlclose lib =
      if c_dlclose lib < 0
      then raise SMLSharp_Runtime.SysErr (dlerror (), NONE)
      else ()

  fun dlsym' (lib, symbol) =
      let
        val ptr = c_dlsym (lib, symbol)
      in
        if ptr = _NULL
        then raise SMLSharp_Runtime.SysErr (dlerror (), NONE)
        else ptr
      end

  fun dlsym args =
      SMLSharp_Builtin.Pointer.toCodeptr (dlsym' args)

end
