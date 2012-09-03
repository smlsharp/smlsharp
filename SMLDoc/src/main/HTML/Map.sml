(**
 * @author John Reppy
 * @version $Id: Map.sml,v 1.2 2004/10/20 03:33:57 kiyoshiy Exp $
 *)
functor Map(type key val sameKey : key * key -> bool) =
struct
  type 'a table = ((key * 'a) list ref * exn)
  fun mkTable (elementNum, exn) = (ref [], exn) : 'a table
  fun insert (elementsRef, exn) (name, value) =
      elementsRef := (name, value) :: (!elementsRef)
  fun find (elementsRef, exn) name =
      case List.find (fn (n, _) => sameKey (n, name)) (!elementsRef) of
        NONE => NONE
      | SOME(_, value) => SOME value
  fun lookup (table as (_, exn)) name =
      case find table name of
        NONE => raise exn
      | SOME value => value
end