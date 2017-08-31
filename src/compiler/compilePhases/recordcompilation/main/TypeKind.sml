(**
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 * @author UENO Katsuhiro
 *)
structure TypeKind =
struct

  structure T = Types

  fun compareTypeTy (ty1, ty2) =
      case (TypesBasics.derefTy ty1, TypesBasics.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        BoundTypeVarID.compare (t1, t2)
      | _ => raise Bug.Bug "UnivKind.compare"

  fun generateSingletonTy btv =
      [T.TYPEty (T.BOUNDVARty btv)]

end
