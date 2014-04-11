(**
 * General structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 6 + -
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

structure General =
struct
  type unit = unit
  type exn = exn
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
  val exnName = exnName
  val exnMessage = exnName
  val ! = !
  val op := = op :=
  val op o = op o
  val op before = op before
  val ignore = ignore

  fun exnMessage e =
      let
        val name = exnName e
        val (msg, loc) = SMLSharp_Builtin.exnMessage e
        val len1 = String.size name
        val len2 = String.size msg
        val len3 = String.size loc
        val extra = if len2 = 0 then 4 else 6
        val buf = String.alloc (len1 + len2 + len3 + extra)
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

end
