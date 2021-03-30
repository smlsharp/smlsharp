(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure TagKind : KIND_INSTANCE =
struct
  structure RC = RecordCalc
  structure T = Types
  structure R = RuntimeTypes

  type singleton_ty_body = Types.ty
  type kind = RuntimeTypes.tag_prop
  type instance = RecordCalc.rcvalue * RecordCalc.loc
  val singletonTy = T.TAGty

  fun compare (ty1, ty2) =
      case (TypesBasics.derefTy ty1, TypesBasics.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        BoundTypeVarID.compare (t1, t2)
      | _ => raise Bug.Bug "TagKind.compare"

  fun generateArgs btvEnv (btv, tagKind) =
      case tagKind of
        R.ANYTAG => [T.TAGty (T.BOUNDVARty btv)]
      | R.TAG _ => nil

  fun generateInstance {btvEnv, lookup} ty loc =
      case TypeLayout2.propertyOf btvEnv ty of
        NONE => raise Bug.Bug "TagKind.generateInstance"
      | SOME {tag = R.ANYTAG, ...} => NONE
      | SOME {tag = R.TAG t, ...} =>
        SOME (RC.RCCONSTANT (RC.TAG (t, ty)), loc)

end
