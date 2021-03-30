(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure RecordKind : KIND_INSTANCE =
struct
  structure TL = TypedLambda
  structure D = DynamicKind
  structure T = Types

  type singleton_ty_body = RecordLabel.label * Types.ty
  type kind = DynamicKind.record * Types.ty RecordLabel.Map.map
  type instance = TypedLambda.tlexp
  val singletonTy = T.INDEXty

  fun compare ((l1, t1), (l2, t2)) =
      case RecordLabel.compare (l1, l2) of
        EQUAL => (case (TypesBasics.derefTy t1, TypesBasics.derefTy t2) of
                    (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
                    BoundTypeVarID.compare (t1, t2)
                  | _ => raise Bug.Bug "compareIndex")
      | x => x

  fun generateArgs btvEnvrecordKind (btv, (indices, fields)) =
      RecordLabel.Map.listItems
        (RecordLabel.Map.mergeWithi
           (fn (l, _, NONE) => NONE
             | (l, NONE, SOME _) => SOME (T.INDEXty (l, T.BOUNDVARty btv))
             | (l, SOME _, SOME _) => NONE)
           (indices, fields))

  fun generateInstance {btvEnv, lookup} (arg as (label, ty)) loc =
      case TypesBasics.derefTy ty of
        ty as T.BOUNDVARty tid =>
        (case BoundTypeVarID.Map.find (btvEnv, tid) of
           SOME (kind as T.KIND {dynamicKind,...}) =>
           (case (case dynamicKind of
                    SOME x => SOME x
                  | NONE => DynamicKindUtils.kindOfStaticKind kind) of
              NONE => raise Bug.Bug "RecordKind.generateInstance"
            | SOME {record, ...} =>
              case RecordLabel.Map.find (record, label) of
                SOME n =>
                SOME (TL.TLCAST
                        {exp = TL.TLINT (TL.WORD32 n, loc),
                         expTy = BuiltinTypes.word32Ty,
                         targetTy = T.SINGLETONty (T.INDEXty (label, ty)),
                         cast = TL.TypeCast,
                         loc = loc})
              | NONE => NONE)
         | NONE => raise Bug.Bug "generateInstance")
      | ty as T.RECORDty _ =>
        SOME (TL.TLINDEXOF {label = label, recordTy = ty, loc = loc})
      | ty as T.DUMMYty (id, T.KIND {tvarKind = T.REC _, ...}) =>
        SOME (TL.TLINDEXOF {label = label, recordTy = ty, loc = loc})
      | _ => NONE

end
