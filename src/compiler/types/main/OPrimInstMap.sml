(**
 * overloaded primitive instance map
 *
 * @copyright (c) 2010, Tohoku University.
 * @author Atsushi Ohori
 * @author UENO Katsuhiro
 *)

local
  structure OPrimInstOrd =
  struct 
    type ord_key = TypID.id option list
    fun compare (idList1, idList2) = 
        let
          fun eqTyConId (NONE, NONE) = EQUAL
            | eqTyConId (NONE, SOME _) = EQUAL
            | eqTyConId (SOME _, NONE) = EQUAL
            | eqTyConId (SOME id1, SOME id2) = TypID.compare (id1, id2)
        in 
          case (idList1, idList2) of
            (nil, nil) => EQUAL
          | (h1::tail1, h2::tail2) => 
            (case eqTyConId(h1, h2) of
               EQUAL => compare (tail1, tail2)
             | x => x)
          | _ => raise Bug.Bug "OPRIMinstOrd: OPrim key length"
        end
  end
in

structure OPrimInstMap = BinaryMapFn(OPrimInstOrd)

end
