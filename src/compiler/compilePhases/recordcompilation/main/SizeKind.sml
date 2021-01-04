(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure SizeKind : KIND_INSTANCE =
struct
  structure RC = RecordCalc
  structure T = Types
  structure R = RuntimeTypes

  type singleton_ty_body = Types.ty
  type kind = RuntimeTypes.size_prop
  type instance = RecordCalc.rcvalue * RecordCalc.loc
  val singletonTy = T.SIZEty

  fun compare (ty1, ty2) =
      case (TypesBasics.derefTy ty1, TypesBasics.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        BoundTypeVarID.compare (t1, t2)
      | _ => raise Bug.Bug "SizeKind.compare"

  fun generateArgs btvEnv (btv, sizeKind) =
      case sizeKind of
        R.ANYSIZE => [T.SIZEty (T.BOUNDVARty btv)]
      | R.SIZE _ => nil

  fun generateInstance {btvEnv, lookup} ty loc =
      case TypeLayout2.propertyOf btvEnv ty of
        NONE => raise Bug.Bug "SizeKind.generateInstance"
      | SOME {size = R.ANYSIZE, ...} => NONE
      | SOME {size = R.SIZE s, ...} =>
        SOME (RC.RCCONSTANT (RC.SIZE (s, ty)), loc)

end
