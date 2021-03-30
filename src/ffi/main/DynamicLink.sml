(**
 * wrapper of libdl.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

infix 6 +
infix 4 < =
infix 3 :=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op < = SMLSharp_Builtin.Int32.lt
val op := = SMLSharp_Builtin.General.:=
val ! = SMLSharp_Builtin.General.!

structure DynamicLink =
struct

  exception Error of string

  type lib = unit ptr
  datatype scope = LOCAL | GLOBAL
  datatype mode = LAZY | NOW

  val c_dlopen =
      _import "dlopen"
      : (string, int) -> lib
  val c_dlsym =
      _import "dlsym"
      : (lib, string) -> unit ptr
  val c_dlerror =
      _import "dlerror"
      : __attribute__((fast))
        () -> char ptr
  val c_dlclose =
      _import "dlclose"
      : lib -> int

  local
    val loaded = ref false
    val RTLD_LAZY = ref 0
    val RTLD_NOW = ref 0
    val RTLD_LOCAL = ref 0
    val RTLD_GLOBAL = ref 0
    val RTLD_DEFAULT = ref (SMLSharp_Builtin.Pointer.null ())
    val RTLD_NEXT = ref (SMLSharp_Builtin.Pointer.null ())

    val const_RTLD_LAZY =
        _import "prim_const_RTLD_LAZY"
        : __attribute__((pure,fast)) () -> int
    val const_RTLD_NOW =
        _import "prim_const_RTLD_NOW"
        : __attribute__((pure,fast)) () -> int
    val const_RTLD_LOCAL =
        _import "prim_const_RTLD_LOCAL"
        : __attribute__((pure,fast)) () -> int
    val const_RTLD_GLOBAL =
        _import "prim_const_RTLD_GLOBAL"
        : __attribute__((pure,fast)) () -> int
    val const_RTLD_DEFAULT =
        _import "prim_const_RTLD_DEFAULT"
        : __attribute__((pure,fast)) () -> lib
    val const_RTLD_NEXT =
        _import "prim_const_RTLD_NEXT"
        : __attribute__((pure,fast)) () -> lib

    fun load () =
        if !loaded then () else
        (RTLD_LAZY := const_RTLD_LAZY ();
         RTLD_NOW := const_RTLD_NOW ();
         RTLD_LOCAL := const_RTLD_LOCAL ();
         RTLD_GLOBAL := const_RTLD_GLOBAL ();
         RTLD_DEFAULT := const_RTLD_DEFAULT ();
         RTLD_NEXT := const_RTLD_NEXT ();
         loaded := true)

  in
    fun dlopenMode (scope, mode) =
      let
        val _ = load ()
        val scope = case scope of LOCAL => !RTLD_LOCAL | GLOBAL => !RTLD_GLOBAL
        val mode = case mode of LAZY => !RTLD_LAZY | NOW => !RTLD_NOW
      in
        scope + mode
      end
    fun default () = (load (); !RTLD_DEFAULT)
    fun next () = (load (); !RTLD_NEXT)
  end (* local *)

  fun dlerror () =
      SMLSharp_Runtime.str_new (c_dlerror ())

  fun dlopen' (libname, scope, mode) =
      let
        val lib = c_dlopen (libname, dlopenMode (scope, mode))
      in
        if lib = SMLSharp_Builtin.Pointer.null ()
        then raise Error (dlerror ())
        else lib
      end

  fun dlopen libname =
      dlopen' (libname, LOCAL, LAZY)

  fun dlclose lib =
      if c_dlclose lib < 0
      then raise Error (dlerror ())
      else ()

  fun dlsym' (lib, symbol) =
      let
        val _ = c_dlerror ()  (* clear the last error *)
        val ptr = c_dlsym (lib, symbol)
      in
        if ptr = SMLSharp_Builtin.Pointer.null ()
        then let
               val err = c_dlerror ()
             in
               if err = SMLSharp_Builtin.Pointer.null ()
               then ptr
               else raise Error (SMLSharp_Runtime.str_new err)
             end
        else ptr
      end

  fun dlsym args =
      SMLSharp_Builtin.Pointer.toCodeptr (dlsym' args)

end
