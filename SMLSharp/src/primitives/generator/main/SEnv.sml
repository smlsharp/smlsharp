(**
 * @copyright (c) 2007, Tohoku University.
 * @version $Id: SEnv.sml,v 1.1 2007/08/29 06:28:04 kiyoshiy Exp $
 *)
signature ordsig =
sig
  type ord_key
  val compare : ord_key * ord_key -> order
end
local
  structure Sord : ordsig =
  struct 
    type ord_key = string
    fun compare (x,y) = 
        let val (a,b) = (valOf(Int.fromString x), valOf(Int.fromString y))
        in Int.compare (a,b)
        end
        handle Option => String.compare (x,y)
  end
  structure base = BinaryMapFn(Sord)
in
structure SEnv
  : sig
      include ORD_MAP
      val fromList : (string * 'item) list -> 'item map
    end =
struct
  open base
  fun fromList list =
      List.foldl
          (fn ((key, item), map) => insert (map, key, item))
          empty
          list
end
end; (* local *)
