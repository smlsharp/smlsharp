(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author UENO Katsuhiro
 *)
structure ReifyKind : KIND_INSTANCE =
struct

  (* structure RC = RecordCalc *)
  (* structure RTy = ReifiedTy *)
  structure T = Types

  type singleton_ty_body = Types.ty
  type kind = bool
  type instance = TypedLambda.tlexp
  val singletonTy = T.REIFYty

  fun compare (ty1, ty2) =
      case (TypesBasics.derefTy ty1, TypesBasics.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        BoundTypeVarID.compare (t1, t2)
      | _ => raise Bug.Bug "ReifyKind.compare"

  fun generateArgs btvEnv (btv, kind) =
      case kind of
        false => nil
      | true => [T.REIFYty (T.BOUNDVARty btv)]
       
  fun generateInstance {btvEnv, lookup} ty loc =
      let
        fun evalTy ty = 
            case TypesBasics.derefTy ty of
              T.BOUNDVARty tid => NONE
            | _ =>
              let
                val tyRep = TyToReifiedTy.toTy loc ty
              in
                SOME (#exp (ReifyTy.TyRep loc tyRep))
              end
      in
        evalTy ty
      end
      
  fun generateInstance {btvEnv, lookup} ty loc =
      let
        fun lookUp btv = lookup (T.REIFYty (T.BOUNDVARty btv))
        val tyRep = TyToReifiedTy.toTy loc ty
        val tyRepExp = ReifyTy.TyRepWithLookUp lookUp loc tyRep
        val retExp = DatatypeCompilation.compileExp
                       DatatypeCompilation.emptyEnv
                       (#exp tyRepExp)
      in
        SOME (TypedLambda.TLCAST
                {exp = retExp,
                 expTy = #ty tyRepExp,
                 targetTy = T.SINGLETONty (T.REIFYty ty),
                 cast = TypedLambda.TypeCast,
                 loc = loc})
      end
end
