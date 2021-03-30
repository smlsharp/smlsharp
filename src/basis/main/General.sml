(**
 * General structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

infix 6 + -
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Word32.sub
structure Int32 = SMLSharp_Builtin.Int32
structure Word32 = SMLSharp_Builtin.Word32
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
  val ! = SMLSharp_Builtin.General.!
  val op := = SMLSharp_Builtin.General.:=
  val op o = SMLSharp_Builtin.General.o
  val op before = SMLSharp_Builtin.General.before
  val ignore = SMLSharp_Builtin.General.ignore

  fun exnName e =
      let
        val (tag, _) = SMLSharp_Builtin.General.exnImpl e
        val vec = SMLSharp_Builtin.General.exntagImpl tag
        val ary = SMLSharp_Builtin.Vector.castToArray vec
        val (name, _) = SMLSharp_Builtin.Array.sub_unsafe (ary, 0)
      in
        name
      end

  fun exnMessage e =
      let
        val (tag, loc) = SMLSharp_Builtin.General.exnImpl e
        val vec = SMLSharp_Builtin.General.exntagImpl tag
        val ary = SMLSharp_Builtin.Vector.castToArray vec
        val (name, index) = SMLSharp_Builtin.Array.sub_unsafe (ary, 0)
        val box = SMLSharp_Builtin.General.exnToBoxed e
        val msg =
            if index = 0w0
            then ""
            else if Word32.andb (index, 0w1) = 0w0
            then SMLSharp_Builtin.Dynamic.readString (box, index)
            else SMLSharp_Builtin.Dynamic.readString
                   (SMLSharp_Builtin.Dynamic.readBoxed
                      (box,
                       SMLSharp_Builtin.Dynamic.objectSize box
                       - SMLSharp_Builtin.Dynamic.sizeToWord _sizeof(boxed)),
                    Word32.andb (index, Word32.notb 0w1))
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
