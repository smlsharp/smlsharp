(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure UnivKind : sig

  val compareTagTy : Types.ty * Types.ty -> order
  val compareSizeTy : Types.ty * Types.ty -> order

  val generateSingletonTy : BoundTypeVarID.id -> Types.singletonTy list

  val generateTagInstance : Types.ty -> Loc.loc -> RecordCalc.rcexp option
  val generateSizeInstance : Types.ty -> Loc.loc -> RecordCalc.rcexp option

end =
struct

  structure RC = RecordCalc
  structure T = Types

  fun compare (ty1, ty2) =
      case (TypesUtils.derefTy ty1, TypesUtils.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        BoundTypeVarID.compare (t1, t2)
      | _ => raise Control.Bug "UnivKind.compare"

  val compareTagTy = compare
  val compareSizeTy = compare

  fun generateSingletonTy btv =
      [T.SIZEty (T.BOUNDVARty btv), T.TAGty (T.BOUNDVARty btv)]

  fun generateTagInstance ty loc =
      case TypesUtils.derefTy ty of
        T.BOUNDVARty _ => NONE
      | _ => SOME (RC.RCTAGOF (ty, loc))

  fun generateSizeInstance ty loc =
      case TypesUtils.derefTy ty of
        T.BOUNDVARty _ => NONE
      | _ => SOME (RC.RCSIZEOF (ty, loc))

end
