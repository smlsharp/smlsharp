(**
 * General structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 6 + -
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
structure Int32 = SMLSharp_Builtin.Int32
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

structure General =
struct
  datatype order = EQUAL | GREATER | LESS
  exception Bind = Bind
  exception Chr = Chr
  exception Div = Div
  exception Domain = Domain
  exception Fail = Fail
  exception Match = Match
  exception Overflow = Overflow
  exception Size = Size
  exception Span
  exception Subscript = Subscript
  val exnName = SMLSharp_Builtin.General.exnName
  val ! = SMLSharp_Builtin.General.!
  val op := = SMLSharp_Builtin.General.:=
  val op o = SMLSharp_Builtin.General.o
  val op before = SMLSharp_Builtin.General.before
  val ignore = SMLSharp_Builtin.General.ignore

  fun exnMessage e =
      let
        val name = exnName e
        val (loc, index, boxed) = SMLSharp_Builtin.General.exnMessage e
        val msg = if SMLSharp_Builtin.Pointer.identityEqual
                       (boxed, SMLSharp_Builtin.Pointer.nullBoxed ())
                  then ""
                  else SMLSharp_Builtin.Dynamic.readString (boxed, index)
        val len1 = String.size name
        val len2 = String.size msg
        val len3 = String.size loc
        val extra = if len2 = 0 then 4 else 6
        val allocSize =
            Int32.add (Int32.add (Int32.add (len1, len2), len3), extra)
            handle Overflow => raise Size
        val buf = String.alloc allocSize
        (* name ^ ": " ^ msg ^ " at " ^ loc *)
        val i = 0
        val _ = Array.copy_unsafe (String.castToArray name, 0,
                                   String.castToArray buf, i, len1)
        val i = i + len1
        val i =
            if len2 = 0 then i else
            let
              val _ = Array.update_unsafe (String.castToArray buf, i, #":")
              val i = i + 1
              val _ = Array.update_unsafe (String.castToArray buf, i, #" ")
              val i = i + 1
              val _ = Array.copy_unsafe (String.castToArray msg, 0,
                                         String.castToArray buf, i, len2)
            in
              i + len2
            end
        val _ = Array.update_unsafe (String.castToArray buf, i, #" ")
        val i = i + 1
        val _ = Array.update_unsafe (String.castToArray buf, i, #"a")
        val i = i + 1
        val _ = Array.update_unsafe (String.castToArray buf, i, #"t")
        val i = i + 1
        val _ = Array.update_unsafe (String.castToArray buf, i, #" ")
        val i = i + 1
        val _ = Array.copy_unsafe (String.castToArray loc, 0,
                                   String.castToArray buf, i, len3)
      in
        buf
      end

  type unit = unit
  type exn = exn
end
