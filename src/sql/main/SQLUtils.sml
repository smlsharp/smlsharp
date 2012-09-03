(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SMLSharp_SQL_Utils : sig

  exception NotOne
  val fetchAll : 'a SMLSharp_SQL_Prim.rel -> 'a list
  val fetchOne : 'a SMLSharp_SQL_Prim.rel -> 'a

end =
struct

  exception NotOne

  fun fetchAll rel =
      case SMLSharp_SQL_Prim.fetch rel of
        NONE => nil
      | SOME (r, rel) => r :: fetchAll rel

  fun fetchOne rel =
      case SMLSharp_SQL_Prim.fetch rel of
        NONE => raise NotOne
      | SOME (r, rel) =>
        case SMLSharp_SQL_Prim.fetch rel of
          NONE => r
        | SOME _ => raise NotOne

end
