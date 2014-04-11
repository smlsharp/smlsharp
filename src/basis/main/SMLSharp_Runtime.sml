(**
 * SMLSharp_Runtime
 * @author UENO Katsuhiro
 * @copyright 2011, 2012, 2013, Tohoku University.
 *)

infix 4 = <> > >= < <=
val op < = SMLSharp_Builtin.Int.lt

structure OS =
struct
  type syserror = int
  (* define an exception with print name "OS.SysErr" *)
  exception SysErr of string * syserror option
end

structure SMLSharp_Runtime =
struct

  exception Bug of string

  val free =
      _import "free"
      : __attribute__((no_callback)) 'a ptr -> ()
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

  open OS

  fun syserror errname =
      let
        val err = prim_syserror errname
      in
        if err < 0 then NONE else SOME err
      end

  fun errorMsg err =
      str_new (strerror err)

  fun str_new_option ptr =
      if SMLSharp_Builtin.Pointer.toUnitPtr ptr = _NULL
      then NONE else SOME (str_new ptr)

  fun OS_SysErr () =
      let
        val err = errno ()
      in
        SysErr (errorMsg err, SOME err)
      end

end
