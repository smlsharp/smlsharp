(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure RecordKind : sig

  val compareIndex
      : (RecordLabel.label * Types.ty) * (RecordLabel.label * Types.ty) -> order

  val generateSingletonTy : BoundTypeVarID.id * Types.ty RecordLabel.Map.map
                            -> Types.singletonTy list

  val generateInstance : (RecordLabel.label * Types.ty)
                         -> Loc.loc
                         -> RecordCalc.rcexp option

end =
struct

  structure RC = RecordCalc
  structure T = Types

  fun compareIndex ((l1, t1), (l2, t2)) =
      case RecordLabel.compare (l1, l2) of
        EQUAL => (case (TypesBasics.derefTy t1, TypesBasics.derefTy t2) of
                    (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
                    BoundTypeVarID.compare (t1, t2)
                  | _ => raise Bug.Bug "compareIndex")
      | x => x

  fun generateSingletonTy (btv:BoundTypeVarID.id, fields:T.ty RecordLabel.Map.map) =
      map (fn label => T.INDEXty (label, T.BOUNDVARty btv))
          (RecordLabel.Map.listKeys fields)

  fun generateInstance (label, ty) loc =
      case TypesBasics.derefTy ty of
        ty as T.RECORDty _ => SOME (RC.RCINDEXOF (label, ty, loc))
      | _ => NONE

end
