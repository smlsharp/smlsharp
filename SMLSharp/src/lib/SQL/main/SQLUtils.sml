(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SMLSharp = struct open SMLSharp
  structure SQLUtils : sig

    exception NotOne
    val fetchAll : 'a '_SQL'.rel -> 'a list
    val fetchOne : 'a '_SQL'.rel -> 'a

  end =
  struct

    exception NotOne

    fun fetchAll rel =
        case SQLImpl.fetch rel of
          NONE => nil
        | SOME (r, rel) => r :: fetchAll rel

    fun fetchOne rel =
        case SQLImpl.fetch rel of
          NONE => raise NotOne
        | SOME (r, rel) =>
          case SQLImpl.fetch rel of
            NONE => r
          | SOME _ => raise NotOne

  end
end
