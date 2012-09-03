(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure TypeLayout : sig

  val runtimeTy : AnnotatedTypes.btvEnv
                  -> AnnotatedTypes.ty
                  -> RuntimeTypes.ty option
  val tagOf : RuntimeTypes.ty -> int

  datatype alignComputation =
      TRAILING_ZEROES

  val sizeOf : RuntimeTypes.ty -> int
  val maxSize : int
  val alignComputation : alignComputation
  val bitmapWordBits : int

end =
struct

  structure T = Types
  structure AT = AnnotatedTypes
  structure R = RuntimeTypes

  (* ToDo: ad-hoc translation of Types into AnnotatedTypes only for
   * determining runtimeTy. This should be done at StaticAnalysis, or
   * Types and AnnotatedTypes should be integrated. *)
  val boxedty = AT.CONty {tyCon = BuiltinEnv.BOXEDtyCon, args=[]}
  fun transformTy subst ty =
      case ty of
        T.SINGLETONty (T.INSTCODEty _) => boxedty
      | T.SINGLETONty (T.INDEXty _) => AT.SINGLETONty (AT.SIZEty AT.ERRORty)
      | T.SINGLETONty (T.TAGty _) => AT.SINGLETONty (AT.TAGty AT.ERRORty)
      | T.SINGLETONty (T.SIZEty _) => AT.SINGLETONty (AT.SIZEty AT.ERRORty)
      | T.ERRORty => AT.ERRORty
      | T.DUMMYty x => AT.DUMMYty x
      | T.TYVARty (ref (T.TVAR _)) => AT.ERRORty
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => transformTy subst ty
      | T.FUNMty _ => boxedty
      | T.RECORDty _ => boxedty
      | T.CONSTRUCTty {tyCon, args} =>
        AT.CONty {tyCon = tyCon, args = map (transformTy subst) args}
      | T.POLYty _ => AT.ERRORty   (* never appear *)
      | T.BOUNDVARty tid =>
        case BoundTypeVarID.Map.find (subst, tid) of
          NONE => AT.BOUNDVARty tid
        | SOME ty => ty
  fun tpappTy (ty, args) =
      case TypesUtils.derefTy ty of
        T.POLYty {boundtvars, body} =>
        let
          val subst =
              ListPair.foldlEq
                (fn (tid, arg, z) => BoundTypeVarID.Map.insert (z, tid, arg))
                BoundTypeVarID.Map.empty
                (BoundTypeVarID.Map.listKeys boundtvars, args)
        in
          transformTy subst body
        end
      | ty => transformTy BoundTypeVarID.Map.empty ty


  fun runtimeTy btvEnv ty =
      case ty of
        AT.SINGLETONty (AT.INSTCODEty _) => SOME R.BOXEDty
      | AT.SINGLETONty (AT.INDEXty _) => SOME R.UINTty
      | AT.SINGLETONty (AT.TAGty _) => SOME R.UINTty
      | AT.SINGLETONty (AT.SIZEty _) => SOME R.UINTty
      | AT.SINGLETONty (AT.RECORDSIZEty _) => SOME R.UINTty
      | AT.SINGLETONty (AT.RECORDBITMAPty _) => SOME R.UINTty
      | AT.ERRORty => NONE
      | AT.DUMMYty _ => SOME R.INTty
      | AT.FUNMty {funStatus = {codeStatus,...},...} =>
        (
          case codeStatus of
            ref AT.LOCAL => SOME R.CODEPOINTERty   (* local function entry *)
          | _ => SOME R.BOXEDty   (* function closure *)
        )
      | AT.MVALty _ => NONE
      | AT.RECORDty _ => SOME R.BOXEDty
      | AT.POLYty {boundtvars, body} =>
        runtimeTy (BoundTypeVarID.Map.unionWith #2 (btvEnv, boundtvars)) body
      | AT.CONty {tyCon, args} =>
        (
          case #dtyKind tyCon of
            T.BUILTIN ty => SOME (RuntimeTypes.runtimeTyOfBuiltinTy ty)
          | T.OPAQUE {opaqueRep, revealKey} =>
            (
              case opaqueRep of
                T.TYCON tyCon =>
                runtimeTy btvEnv (AT.CONty {tyCon=tyCon, args=args})
              | T.TFUNDEF {iseq, arity, polyTy} =>
                runtimeTy btvEnv (tpappTy (polyTy, args))
            )
          | Types.DTY =>
            SOME (RuntimeTypes.runtimeTyOfBuiltinTy (#runtimeTy tyCon))
        )
      | AT.BOUNDVARty tid =>
        case BoundTypeVarID.Map.find (btvEnv, tid) of
          SOME {tvarKind=AT.UNIV,...} => NONE
        | SOME {tvarKind=AT.OPRIMkind _,...} => NONE
        | SOME {tvarKind=AT.REC _,...} => SOME R.BOXEDty
        | NONE => NONE

  fun tagOf ty =
      case ty of
        R.UCHARty => 0
      | R.INTty => 0
      | R.UINTty => 0
      | R.BOXEDty => 1
      | R.POINTERty => 0
      | R.CODEPOINTERty => 0
      | R.DOUBLEty => 0
      | R.FLOATty => 0

  datatype alignComputation =
      TRAILING_ZEROES

  (* FIXME: ILP32 layout is hard-coded. *)
  fun sizeOf ty =
      case ty of
        R.UCHARty => 1
      | R.INTty => 4
      | R.UINTty => 4
      | R.BOXEDty => 4
      | R.POINTERty => 4
      | R.CODEPOINTERty => 4
      | R.DOUBLEty => 8
      | R.FLOATty => 4

  (* the largest size object which has the most strict alignment constraint. *)
  (* ASSERT(maxSize mod sizeOf BOXEDty = 0) *)
  val maxSize = 16

  (* how to compute alignment constraint from size *)
  val alignComputation = TRAILING_ZEROES

  val bitmapWordBits = 32  (* = sizeof(UINTty) * 8 *)

end
