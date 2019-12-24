(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure TypeLayout2 =
struct

  structure T = Types
  structure R = RuntimeTypes
  (* structure D = DynamicKind *)

  val emptyBtvEnv = BoundTypeVarID.Map.empty : T.btvEnv

  exception PropOf

  fun dummyTy {tag, size, rep} =
      {tag = case tag of R.ANYTAG => R.TAG R.UNBOXED | R.TAG _ => tag,
       size = case size of R.ANYSIZE => #size R.int32Prop | R.SIZE _ => size,
       rep = rep}

  fun toGeneric ({tag, size, rep}:R.ty) =
      {tag = tag, size = size, rep = R.BINARY}

  fun coerceToBoxed ({tag, size, rep}:R.property) =
      if (tag = R.ANYTAG orelse tag = #tag R.boxedProp)
         andalso (size = R.ANYSIZE orelse size = #size R.boxedProp)
      then SOME (R.boxedProp # {rep = rep})
      else NONE

  fun coerceToUnboxed ({tag, size, rep}:R.property) =
      if tag = R.ANYTAG orelse tag = R.TAG R.UNBOXED
      then SOME {tag = R.TAG R.UNBOXED, size = size, rep = rep}
      else NONE

  fun coerceToProperties properties prop =
      case Types.propertiesOf properties of
        {reify, boxed, unboxed, eq} =>
        if boxed andalso unboxed then NONE
        else if boxed then coerceToBoxed prop
        else if unboxed then coerceToUnboxed prop
        else SOME prop

  fun propertyOfTvarKind btvEnv tvarKind =
      case tvarKind of
        T.UNIV => SOME R.anyProp
      | T.REC _ => SOME R.recordProp
      | T.OCONSTkind tys => propertyOfTyList btvEnv tys
      | T.OPRIMkind {instances, operators} => propertyOfTyList btvEnv instances

  and propertyOfKind btvEnv (T.KIND {dynamicKind, properties, tvarKind}) =
      case propertyOfTvarKind btvEnv tvarKind of
        NONE => NONE
      | SOME prop1 =>
        case coerceToProperties properties prop1 of
          NONE => NONE
        | SOME static =>
          case dynamicKind of
            NONE => SOME static
          | SOME {tag, size, record} =>
            let
              val dynamic = {tag = tag, size = size, rep = #rep static}
            in
              (* dynamicKind must be more specific than property of tvarKind *)
              if R.lub (static, dynamic) = static
              then ()
              else raise Bug.Bug ("propertyOfKind: dynamicKind mismatch. "
                                  ^ "dynamicKind="
                                  ^ Bug.prettyPrint (R.format_property dynamic)
                                  ^ " must be more specific than staticKind="
                                  ^ Bug.prettyPrint (R.format_property static));
              SOME dynamic
            end

  and propertyOfTyList btvEnv nil = NONE
    | propertyOfTyList btvEnv [ty] = propertyOf btvEnv ty
    | propertyOfTyList btvEnv (ty :: tys) =
      case propertyOf btvEnv ty of
        NONE => NONE
      | SOME prop1 =>
        case propertyOfTyList btvEnv tys of
          NONE => NONE
        | SOME prop2 => SOME (R.lub (prop1, prop2))

  and propertyOf btvEnv ty =
      case ty of
        T.SINGLETONty (T.INSTCODEty _) => SOME R.recordProp
      | T.SINGLETONty (T.INDEXty _) => SOME R.word32Prop
      | T.SINGLETONty (T.TAGty _) => SOME R.word32Prop
      | T.SINGLETONty (T.SIZEty _) => SOME R.word32Prop
      | T.SINGLETONty (T.REIFYty _) => SOME R.recordProp
      | T.BACKENDty (T.RECORDSIZEty _) => SOME R.word32Prop
      | T.BACKENDty (T.RECORDBITMAPINDEXty _) => SOME R.word32Prop
      | T.BACKENDty (T.RECORDBITMAPty _) => SOME R.word32Prop
      | T.BACKENDty (T.CCONVTAGty _) => SOME R.word32Prop
      | T.BACKENDty T.SOME_CLOSUREENVty => SOME R.recordProp
      | T.BACKENDty T.SOME_CCONVTAGty => SOME R.word32Prop
      | T.BACKENDty T.SOME_FUNENTRYty => SOME R.codeptrProp
      | T.BACKENDty T.SOME_FUNWRAPPERty => SOME R.codeptrProp
      | T.BACKENDty (T.FUNENTRYty {tyvars, haveClsEnv, argTyList, retTy}) =>
        (SOME
           (R.codeptrProp
            # {rep =
                 R.CODEPTR
                   (R.FN
                      {haveClsEnv = haveClsEnv,
                       argTys = map (toGeneric o runtimeArgTy tyvars) argTyList,
                       retTy = runtimeArgTy tyvars retTy})})
         handle PropOf => NONE)
      | T.BACKENDty (T.CALLBACKENTRYty ({tyvars, haveClsEnv, argTyList, retTy,
                                         attributes})) =>
        (SOME
           (R.codeptrProp
            # {rep =
                 R.CODEPTR
                   (R.CALLBACK
                      {haveClsEnv = haveClsEnv,
                       argTys = map (runtimeArgTy tyvars) argTyList,
                       retTy = Option.map (runtimeArgTy tyvars) retTy,
                       attributes = attributes})})
         handle PropOf => NONE)
      | T.BACKENDty (T.FOREIGNFUNPTRty {tyvars, argTyList, varArgTyList,
                                        resultTy, attributes}) =>
        (SOME
           (R.codeptrProp
            # {rep =
                 R.CODEPTR
                   (R.FOREIGN
                      {argTys = map (runtimeArgTy tyvars) argTyList,
                       varArgTys = Option.map (map (runtimeArgTy tyvars))
                                              varArgTyList,
                       retTy = Option.map (runtimeArgTy tyvars) resultTy,
                       attributes = attributes})})
         handle PropOf => NONE)
      | T.ERRORty => NONE
      | T.DUMMYty (_, kind) =>
        Option.map dummyTy (propertyOfKind btvEnv kind)
      | T.TYVARty (ref (T.TVAR {kind, ...})) =>
        propertyOfKind btvEnv kind
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => propertyOf btvEnv ty
      | T.FUNMty _ => SOME R.recordProp  (* function closure *)
      | T.RECORDty _ => SOME R.recordProp
      | T.POLYty {boundtvars, constraints, body} =>
        propertyOf (BoundTypeVarID.Map.unionWith #2 (btvEnv, boundtvars)) body
      | T.CONSTRUCTty {tyCon, args} =>
        (
          case #dtyKind tyCon of
            T.DTY p => SOME p
          | T.OPAQUE {opaqueRep, revealKey} =>
            propertyOfOpaqueRep btvEnv (opaqueRep, args)
          | T.INTERFACE opaqueRep =>
            propertyOfOpaqueRep btvEnv (opaqueRep, args)
        )
      | T.BOUNDVARty tid =>
        case BoundTypeVarID.Map.find (btvEnv, tid) of
          SOME kind => propertyOfKind btvEnv kind
        | NONE => NONE

  and propertyOfOpaqueRep btvEnv (opaqueRep, args) =
      case opaqueRep of
        T.TYCON tyCon =>
        propertyOf btvEnv (T.CONSTRUCTty {tyCon = tyCon, args = args})
      | T.TFUNDEF {admitsEq, arity, polyTy} =>
        propertyOf btvEnv (TypesBasics.tpappTy (polyTy, args))

  and runtimeArgTy btvEnv ty =
      case propertyOf btvEnv ty of
        SOME {tag = R.TAG t, size = R.SIZE s, rep = r} =>
        {tag = t, size = s, rep = r}
      | SOME _ => R.boxedTy (* packed *)
      | NONE => raise PropOf

  fun tagValue R.UNBOXED = 0
    | tagValue R.BOXED = 1

  val sizeValue = RuntimeTypes.getSize

  datatype size_assumption =
      (* every type has power-of-2 size *)
      ALL_SIZES_ARE_POWER_OF_2
(*
    | (* every type except long double has power-of-2 size *)
      ALL_SIZES_ARE_POWER_OF_2_EXCEPT_LONG_DOUBLE
*)
  datatype align_computation =
      (* For every type, its alignment is equal to its size *)
      ALIGN_EQUAL_SIZE
(*
    | (* For every type except double, its alignment is equal to its size.
       * The size of double is 8 and its alignment is 4. *)
      ALIGN_EQUAL_SIZE_EXECPT_DOUBLE
    | (* For each type whose size is larger than 8, its alignment is 4.
       * For any other types, their alignments are equal to their sizes *)
      ALIGN_UPTO_4
*)

  val charBits = 8

  (* maximum size that sizeOf returns.
   * It is also the maximum alignment constraint *)
  val maxSize = #size RuntimeTypes.word64Ty

  (* NOTE: On x86 Linux (and any other long-lived operating systems on x86),
   * sizeof(long double) is 12. So ALL_SIZES_ARE_POWER_OF_2_EXCEPT_LONG_DOUBLE
   * is more appropriate for those platforms. *)
  val sizeAssumption = ALL_SIZES_ARE_POWER_OF_2
  val alignComputation = ALIGN_EQUAL_SIZE
end
