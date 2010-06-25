(**
 * overloaded primitive instance management
 *
 * @copyright (c) 2010, Tohoku University.
 * @author Atsushi Ohori
 *)

structure OPrimInstance : sig
  
  datatype instance =
       PRIMAPPLY of BuiltinPrimitive.prim_or_special
     | EXTERNVAR of string
  (* FIXME:
   * EXTERNVAR holds an external name of variable.
   * Resolving reference to the variable is delayed until an overload
   * instance will be generated. If there is no entry in the toplevel
   * environment for the variable at the time of resolusion, compiler
   * generates a dummy expression instead of a variable reference.
   *)

  type oprimInstInfo =
      {
        name: string,
        instance: instance
      }

  (* wildCard type must be used for uninstanciated types in oprim instances. *) 
  val wildCardTyConId : TyConID.id

  structure Map : ORD_MAP where type Key.ord_key = TyConID.id list

  type oprimInstMap = oprimInstInfo Map.map

end =
struct

  datatype instance =
       PRIMAPPLY of BuiltinPrimitive.prim_or_special
     | EXTERNVAR of string

  type oprimInstInfo =
      {
        name: string,
        instance: instance
      }

  val wildCardTyConId = TyConID.generate ()

  structure OPrimInstOrd =
  struct 
    type ord_key = TyConID.id list
    fun compare (idList1, idList2) = 
        let
          fun eqTyConId(id1,id2) =
              if TyConID.eq (id1, wildCardTyConId) orelse
                 TyConID.eq (id2, wildCardTyConId) 
              then EQUAL
              else TyConID.compare (id1, id2)
        in 
          case (idList1, idList2) of
            (nil, nil) => EQUAL
          | (h1::tail1, h2::tail2) => 
            (case eqTyConId(h1, h2) of
               EQUAL => compare (tail1, tail2)
             | x => x)
          | _ => raise Control.Bug "OPRIMinstOrd: OPrim key length"
        end
  end
  structure Map = BinaryMapMaker(OPrimInstOrd)

  type oprimInstMap = oprimInstInfo Map.map

end
