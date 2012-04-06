(**
 * SMLSharpRuntime structure.
 * @author UENO Katsuhiro
 * @copyright 2011, Tohoku University.
 *)
_interface "SMLSharpRuntime.smi"

structure SMLSharpRuntime :> sig

  eqtype syserror
  exception SysErr of string * syserror option

  val cconstInt : string -> int
  val str_new : char ptr -> string
  val str_new_option : char ptr -> string option
  val errno : unit -> syserror
  val errorMsg : syserror -> string
  val errorName : syserror -> string
  val syserror : string -> syserror option
  val OS_SysErr : unit -> exn
  val free : 'a ptr -> unit

end =
struct

  infix 4 < =

  val op < = SMLSharp.Int.lt

  val cconstInt =
      _import "prim_cconst_int"
      : __attribute__((pure,no_callback)) string -> int
  val free =
      _import "free"
      : __attribute__((no_callback)) 'a ptr -> unit
  val str_new =
      _import "sml_str_new"
      : __attribute__((no_callback,alloc)) char ptr -> string
  val errno =
      _import "prim_StandardC_errno"
      : __attribute__((no_callback)) () -> int
  val prim_syserror =
      _import "prim_GenericOS_syserror"
      : __attribute__((pure,no_callback)) string -> int
  val strerror =
      _import "strerror"
      : __attribute__((no_callback)) int -> char ptr
  val errorName =
      _import "prim_GenericOS_errorName"
      : __attribute__((pure,no_callback,alloc)) int -> string

  type syserror = int
  exception SysErr of string * syserror option

  fun syserror errname =
      let
        val err = prim_syserror errname
      in
        if err < 0 then NONE else SOME err
      end

  fun errorMsg err =
      str_new (strerror err)

  fun str_new_option ptr =
      if SMLSharp.Pointer.toUnitPtr ptr = _NULL
      then NONE else SOME (str_new ptr)

  fun OS_SysErr () =
      let
        val err = errno ()
      in
        SysErr (errorMsg err, SOME err)
      end

end
