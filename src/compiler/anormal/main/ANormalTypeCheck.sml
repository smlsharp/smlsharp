(**
 * Type checker for ANormal
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ANormalTypeCheck : sig

  val check : ANormal.program -> unit

end =
struct

  structure A = ANormal
  structure T = Types
  structure R = RuntimeTypes
  structure B = BuiltinTypes

  fun derefTy ((ty, rty):A.ty) =
      (TypesBasics.derefTy ty, rty) : A.ty

  val errorTy =
      (T.ERRORty, R.UINTty) : A.ty

  val unitptrTy =
      T.CONSTRUCTty {tyCon = B.ptrTyCon, args = [B.unitTy]}

  fun arrayTy ty =
      T.CONSTRUCTty {tyCon = B.arrayTyCon, args = [ty]}

  fun indices l =
      let
        fun f nil i = nil
          | f (h::t) i = i :: f t (i+1)
      in
        f l 0
      end

  datatype extern = EXTERN | EXPORT

  type cconv =
      {haveClsEnv : bool, argTyList : R.ty list, retTy : R.ty}

  type env =
      {
        btvEnv : T.btvEnv,
        varEnv : A.ty VarID.Map.map,
        funEntryEnv : A.ty FunEntryLabel.Map.map,
        callbackEntryEnv : T.callbackEntryTy CallbackEntryLabel.Map.map,
        dataEnv : A.ty DataLabel.Map.map,
        extraDataEnv : unit ExtraDataLabel.Map.map,
        externEnv : (A.ty * extern) ExternSymbol.Map.map,
        localCodeEnv : A.ty list FunLocalLabel.Map.map,
        handlerEnv : HandlerLabel.Set.set,
        returnTy : A.ty
      }

  fun emptyEnv retTy =
      {
        btvEnv = BoundTypeVarID.Map.empty,
        varEnv = VarID.Map.empty,
        funEntryEnv = FunEntryLabel.Map.empty,
        callbackEntryEnv = CallbackEntryLabel.Map.empty,
        dataEnv = DataLabel.Map.empty,
        extraDataEnv = ExtraDataLabel.Map.empty,
        externEnv = ExternSymbol.Map.empty,
        localCodeEnv = FunLocalLabel.Map.empty,
        handlerEnv = HandlerLabel.Set.empty,
        returnTy = retTy
      } : env

  fun printErr s =
      TextIO.output (TextIO.stdErr, s)

  fun printFrontendTy ty =
      printErr (Bug.prettyPrint (T.format_ty nil ty))

  fun printBackendTy rty =
      printErr (Bug.prettyPrint (R.format_ty rty))

  fun printTy ((ty, rty):A.ty) =
      (printFrontendTy ty; printErr "\n";
       printBackendTy rty; printErr "\n")

  fun printElems print head elems =
      ListPair.app
        (fn (i, ty) => (printErr (head ^ "[" ^ Int.toString i ^ "]:\n");
                        print ty))
        (indices elems, elems)

  fun printElemOpt print head NONE = printErr "NONE"
    | printElemOpt print head (SOME elem) = print elem

  fun printFunEntryNotFound msg id =
      printErr (msg ^ ": fun entry not found "
                ^ FunEntryLabel.toString id ^ "\n")
  fun printCallbackEntryNotFound msg id =
      printErr (msg ^ ": callback entry not found "
                ^ CallbackEntryLabel.toString id ^ "\n")
  fun printDataNotFound msg id =
      printErr (msg ^ ": data not found "
                ^ DataLabel.toString id ^ "\n")
  fun printExtraDataNotFound msg id =
      printErr (msg ^ ": extra data not found "
                ^ ExtraDataLabel.toString id ^ "\n")
  fun printExternNotFound msg id =
      printErr (msg ^ ": extern not found "
                ^ ExternSymbol.toString id ^ "\n")
  fun printLocalCodeNotFound msg id =
      printErr (msg ^ ": local code not found "
                ^ FunLocalLabel.toString id ^ "\n")
  fun printHandlerNotFound msg id =
      printErr (msg ^ ": handler not found "
                ^ HandlerLabel.toString id ^ "\n")
  fun printVarNotFound msg id =
      printErr (msg ^ ": var not found "
                ^ VarID.toString id ^ "\n")
  fun printLabelNotFound msg label =
      printErr (msg ^ ": label not found " ^ label ^ "\n")

  fun printDoubledFunEntry msg id =
      printErr (msg ^ ": doubled fun entry "
                ^ FunEntryLabel.toString id ^ "\n")
  fun printDoubledCallbackEntry msg id =
      printErr (msg ^ ": doubled callback entry "
                ^ CallbackEntryLabel.toString id ^ "\n")
  fun printDoubledData msg id =
      printErr (msg ^ ": doubled data "
                ^ DataLabel.toString id ^ "\n")
  fun printDoubledExtraData msg id =
      printErr (msg ^ ": doubled extra data "
                ^ ExtraDataLabel.toString id ^ "\n")
  fun printDoubledExtern msg id =
      printErr (msg ^ ": doubled extern "
                ^ ExternSymbol.toString id ^ "\n")
  fun printDoubledLocalCode msg id =
      printErr (msg ^ ": doubled local code "
                ^ FunLocalLabel.toString id ^ "\n")
  fun printDoubledArg msg id =
      printErr (msg ^ ": doubled arg var "
                ^ VarID.toString id ^ "\n")

  fun printUnificationFailed msg (ty1, ty2) =
      (printErr (msg ^ ": unification failed\n");
       printErr "ty1:\n"; printTy ty1;
       printErr "ty2:\n"; printTy ty2)
  fun printUnificationFailedList msg (tys1, tys2) =
      (printErr (msg ^ ": type list unification failed\n");
       printElems printTy "ty1" tys1;
       printElems printTy "ty2" tys2)
  fun printUnificationFailedOption msg (ty1, ty2) =
      (printErr (msg ^ ": type list unification failed\n");
       printElemOpt printTy "ty1" ty1;
       printElemOpt printTy "ty2" ty2)
  fun printFrontendTypeMismatch msg (ty1, ty2) =
      (printErr (msg ^ ": frontend type mismatch\n");
       printErr "ty1:\n"; printFrontendTy ty1;
       printErr "ty2:\n"; printFrontendTy ty2)
  fun printFrontendTypeListMismatch msg (tys1, tys2) =
      (printErr (msg ^ ": frontend type list mismatch\n");
       printElems printFrontendTy "ty1" tys1;
       printElems printFrontendTy "ty2" tys2)
  fun printBackendTypeMismatch msg (ty1, ty2) =
      (printErr (msg ^ ": backend type mismatch\n");
       printErr "ty1:\n"; printBackendTy ty1;
       printErr "ty2:\n"; printBackendTy ty2)
  fun printBackendTypeListMismatch msg (tys1, tys2) =
      (printErr (msg ^ ": backend type list mismatch\n");
       printElems printBackendTy "ty1" tys1;
       printElems printBackendTy "ty2" tys2)

  fun printCannotComputeRuntimeTy msg ty =
      (printErr (msg ^ ": cannot compute runtime type\n");
       printErr (Bug.prettyPrint (T.format_ty nil ty));
       printErr "\n")

  fun revealConTy {tyCon:T.tyCon, args} =
      case #dtyKind tyCon of
        T.DTY => T.CONSTRUCTty {tyCon=tyCon, args=args}
      | T.BUILTIN _ => T.CONSTRUCTty {tyCon=tyCon, args=args}
      | T.OPAQUE {opaqueRep, revealKey} =>
        case opaqueRep of
          T.TYCON tyCon => revealConTy {tyCon=tyCon, args=args}
        | T.TFUNDEF {iseq, arity, polyTy} => Unify.instOfPolyTy (polyTy, args)

  exception Unify

  fun recordFieldTyEq (tys1, tys2) =
      LabelEnv.listItems
        (LabelEnv.mergeWith
           (fn (SOME ty1, SOME ty2) => SOME (ty1 : T.ty, ty2 : T.ty)
           | _ => raise Unify)
           (tys1, tys2))

  val emptyInst =
      (BoundTypeVarID.Map.empty, BoundTypeVarID.Map.empty)
      : unit ref BoundTypeVarID.Map.map * unit ref BoundTypeVarID.Map.map

  fun unifyTy inst (ty1, ty2) =
      case (ty1, ty2) of
        (T.TYVARty (ref (T.SUBSTITUTED ty1)), _) => unifyTy inst (ty1, ty2)
      | (_, T.TYVARty (ref (T.SUBSTITUTED ty2))) => unifyTy inst (ty1, ty2)
      | (T.CONSTRUCTty (t1 as {tyCon={dtyKind=T.OPAQUE _,...},...}), _) =>
        unifyTy inst (revealConTy t1, ty2)
      | (_, T.CONSTRUCTty (t2 as {tyCon={dtyKind=T.OPAQUE _,...},...})) =>
        unifyTy inst (ty1, revealConTy t2)
      | (T.TYVARty (ref (T.TVAR _)), _) => raise Unify  (* never appear *)
      | (T.SINGLETONty sty1, T.SINGLETONty sty2) =>
        unifySingletonTy inst (sty1, sty2)
      | (T.SINGLETONty _, _) => raise Unify
      | (T.BACKENDty bty1, T.BACKENDty bty2) =>
        unifyBackendTy inst (bty1, bty2)
      | (T.BACKENDty _, _) => raise Unify
      | (T.ERRORty, _) => raise Unify  (* never appear *)
      | (T.DUMMYty t1, T.DUMMYty t2) => if t1 = t2 then () else raise Unify
      | (T.DUMMYty _, _) => raise Unify
      | (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
        (case (BoundTypeVarID.Map.find (#1 inst, t1),
               BoundTypeVarID.Map.find (#2 inst, t2)) of
           (SOME x, SOME y) =>
           if x = y then () else raise Unify
         | (NONE, NONE) =>
           if BoundTypeVarID.eq (t1, t2) then () else raise Unify
         | _ => raise Unify)
      | (T.BOUNDVARty _, _) => raise Unify
      | (T.FUNMty (argTys1, retTy1), T.FUNMty (argTys2, retTy2)) =>
        let
          val argTyEq = ListPair.zipEq (argTys1, argTys2)
                        handle UnequalLengths => raise Unify
        in
          app (unifyTy inst) ((retTy1, retTy2) :: argTyEq)
        end
      | (T.FUNMty _, _) => raise Unify
      | (T.RECORDty tys1, T.RECORDty tys2) =>
        app (unifyTy inst) (recordFieldTyEq (tys1, tys2))
      | (T.RECORDty _, _) => raise Unify
      | (T.CONSTRUCTty {tyCon=tyCon1, args=args1},
         T.CONSTRUCTty {tyCon=tyCon2, args=args2}) =>
        if TypID.eq (#id tyCon1, #id tyCon2)
        then app (unifyTy inst) (ListPair.zipEq (args1, args2)
                                  handle UnequalLengths => raise Unify)
        else raise Unify
      | (T.CONSTRUCTty _, _) => raise Unify
      | (T.POLYty {boundtvars=boundtvars1, body=body1},
         T.POLYty {boundtvars=boundtvars2, body=body2}) =>
        let
          val inst = unifyBtvEnv inst (boundtvars1, boundtvars2)
        in
          unifyTy inst (body1, body2)
        end
      | (T.POLYty _, _) => raise Unify

  and unifyBtvEnv inst (btvEnv1, btvEnv2) =
      let
        val btvEq = ListPair.zipEq (BoundTypeVarID.Map.listItemsi btvEnv1,
                                    BoundTypeVarID.Map.listItemsi btvEnv2)
                    handle UnequalLengths => raise Unify
        val inst =
            foldl (fn (((t1,_),(t2,_)), (inst1, inst2)) =>
                      let
                        val i = ref ()
                      in
                        (BoundTypeVarID.Map.insert (inst1, t1, i),
                         BoundTypeVarID.Map.insert (inst2, t2, i))
                      end)
                  inst
                  btvEq
      in
        app (fn ((_,k1),(_,k2)) => unifyBtvKind inst (k1, k2)) btvEq;
        inst
      end

  and unifySingletonTy inst (sty1, sty2) =
      case (sty1, sty2) of
        (T.INSTCODEty {oprimId=id1,...}, T.INSTCODEty {oprimId=id2,...}) =>
        if OPrimID.eq (id1, id2) then () else raise Unify
      | (T.INSTCODEty _, _) => raise Unify
      | (T.INDEXty (l1, ty1), T.INDEXty (l2, ty2)) =>
        if l1 = l2 then unifyTy inst (ty1, ty2) else raise Unify
      | (T.INDEXty _, _) => raise Unify
      | (T.TAGty ty1, T.TAGty ty2) => unifyTy inst (ty1, ty2)
      | (T.TAGty _, _) => raise Unify
      | (T.SIZEty ty1, T.SIZEty ty2) => unifyTy inst (ty1, ty2)
      | (T.SIZEty _, _) => raise Unify

  and unifyBackendTy inst (bty1, bty2) =
      case (bty1, bty2) of
        (T.RECORDSIZEty ty1, T.RECORDSIZEty ty2) => unifyTy inst (ty1, ty2)
      | (T.RECORDSIZEty _, _) => raise Unify
      | (T.RECORDBITMAPINDEXty (i1, ty1), T.RECORDBITMAPINDEXty (i2, ty2)) =>
        if i1 = i2 then unifyTy inst (ty1, ty2) else raise Unify
      | (T.RECORDBITMAPINDEXty _, _) => raise Unify
      | (T.RECORDBITMAPty (i1, ty1), T.RECORDBITMAPty (i2, ty2)) =>
        if i1 = i2 then unifyTy inst (ty1, ty2) else raise Unify
      | (T.RECORDBITMAPty _, _) => raise Unify
      | (T.CCONVTAGty e1, T.CCONVTAGty e2) => unifyCodeEntryTy inst (e1, e2)
      | (T.CCONVTAGty _, _) => raise Unify
      | (T.FUNENTRYty e1, T.FUNENTRYty e2) => unifyCodeEntryTy inst (e1, e2)
      | (T.FUNENTRYty _, _) => raise Unify
      | (T.CALLBACKENTRYty e1, T.CALLBACKENTRYty e2) =>
        unifyCallbackEntryTy inst (e1, e2)
      | (T.CALLBACKENTRYty _, _) => raise Unify
      | (T.SOME_FUNENTRYty, T.SOME_FUNENTRYty) => ()
      | (T.SOME_FUNENTRYty, _) => raise Unify
      | (T.SOME_FUNWRAPPERty, T.SOME_FUNWRAPPERty) => ()
      | (T.SOME_FUNWRAPPERty, _) => raise Unify
      | (T.SOME_CLOSUREENVty, T.SOME_CLOSUREENVty) => ()
      | (T.SOME_CLOSUREENVty, _) => raise Unify
      | (T.SOME_CCONVTAGty, T.SOME_CCONVTAGty) => ()
      | (T.SOME_CCONVTAGty, _) => raise Unify
      | (T.FOREIGNFUNPTRty {argTyList=argTyList1, varArgTyList=varArgTyList1,
                            resultTy=resultTy1, attributes=attributes1},
         T.FOREIGNFUNPTRty {argTyList=argTyList2, varArgTyList=varArgTyList2,
                            resultTy=resultTy2, attributes=attributes2}) =>
        (unifyTyList inst (argTyList1, argTyList2);
         case (varArgTyList1, varArgTyList2) of
           (NONE, NONE) => ()
         | (SOME tys1, SOME tys2) => unifyTyList inst (tys1, tys2)
         | _ => raise Unify;
         case (resultTy1, resultTy2) of
           (NONE, NONE) => ()
         | (SOME ty1, SOME ty2) => unifyTy inst (ty1, ty2)
         | _ => raise Unify;
         if attributes1 = attributes2 then () else raise Unify)
      | (T.FOREIGNFUNPTRty _, _) => raise Unify

  and unifyTyList inst (tys1, tys2) =
      app (unifyTy inst) (ListPair.zipEq (tys1, tys2)
                          handle UnequalLengths => raise Unify)

  and unifyTyOption inst (NONE, NONE) = ()
    | unifyTyOption inst (SOME ty1, SOME ty2) = unifyTy inst (ty1, ty2)
    | unifyTyOption inst _ = raise Unify

  and unifyCodeEntryTy inst ({tyvars=tyvars1, haveClsEnv=haveClsEnv1,
                               argTyList=argTyList1, retTy=retTy1},
                              {tyvars=tyvars2, haveClsEnv=haveClsEnv2,
                               argTyList=argTyList2, retTy=retTy2}) =
      let
        val _ = if haveClsEnv1 = haveClsEnv2 then () else raise Unify
        val inst = unifyBtvEnv inst (tyvars1, tyvars2)
      in
        unifyTyList inst (argTyList1, argTyList2);
        unifyTyOption inst (retTy1, retTy2)
      end

  and unifyCallbackEntryTy inst ({tyvars=tyvars1, haveClsEnv=haveClsEnv1,
                                  argTyList=argTyList1, retTy=retTy1,
                                  attributes=attr1},
                                 {tyvars=tyvars2, haveClsEnv=haveClsEnv2,
                                  argTyList=argTyList2, retTy=retTy2,
                                  attributes=attr2}) =
      let
        val _ = if haveClsEnv1 = haveClsEnv2 then () else raise Unify
        val _ = if attr1 = attr2 then () else raise Unify
        val inst = unifyBtvEnv inst (tyvars1, tyvars2)
      in
        unifyTyList inst (argTyList1, argTyList2);
        unifyTyOption inst (retTy1, retTy2)
      end

  and unifyBtvKind inst ({eqKind=eq1, tvarKind=k1}, {eqKind=eq2, tvarKind=k2}) =
      if eq1 <> eq2 then raise Unify else
      case (k1, k2) of
        (T.OCONSTkind _, _) => raise Unify  (* never appear *)
      | (T.OPRIMkind i1, T.OPRIMkind i2) => ()  (* ignore overload instances *)
      | (T.OPRIMkind _, _) => raise Unify
      | (T.UNIV, T.UNIV) => ()
      | (T.UNIV, _) => raise Unify
      | (T.REC tys1, T.REC tys2) =>
        app (unifyTy inst) (recordFieldTyEq (tys1, tys2))
      | (T.REC _, _) => raise Unify
      | (T.JOIN _, _) => raise Unify  (* never appear *)

  fun unifyANormalTy ((ty1, rty1):A.ty, (ty2, rty2):A.ty) =
      if rty1 = rty2
      then unifyTy emptyInst (ty1, ty2)
      else raise Unify

  fun unify msg (ty1, ty2) =
      unifyANormalTy (ty1, ty2)
      handle Unify => printUnificationFailed msg (ty1, ty2)

  fun unifyList msg (tys1, tys2) =
      app unifyANormalTy (ListPair.zipEq (tys1, tys2)
                          handle UnequalLengths => raise Unify)
      handle Unify => printUnificationFailedList msg (tys1, tys2)

  fun unifyOption msg (NONE, NONE) = ()
    | unifyOption msg (SOME ty1, SOME ty2) = unify msg (ty1, ty2)
    | unifyOption msg (ty1, ty2) = printUnificationFailedOption msg (ty1, ty2)

  fun unifyFrontendTy msg (ty1, ty2) =
      unifyTy emptyInst (ty1, ty2)
      handle Unify => printFrontendTypeMismatch msg (ty1, ty2)

  fun unifyFrontendTyList msg (tys1, tys2) =
      app (unifyTy emptyInst) (ListPair.zipEq (tys1, tys2)
                               handle UnequalLengths => raise Unify)
      handle Unify => printFrontendTypeListMismatch msg (tys1, tys2)

  fun unifyBackendTy msg (ty1, ty2) =
      if ty1 = ty2
      then ()
      else printBackendTypeMismatch msg (ty1, ty2)

  fun unifyBackendTyList msg (ty1, ty2) =
      if ty1 = ty2
      then ()
      else printBackendTypeListMismatch msg (ty1, ty2)

  fun bindVar (env as {varEnv, ...}:env, {id, ty}:A.varInfo) =
      env # {varEnv = VarID.Map.insert (varEnv, id, ty)}

  fun bindVarOption (env, NONE) = env
    | bindVarOption (env, SOME v) = bindVar (env, v)

  fun extendVarEnv (env:env, varEnv) =
      env # {varEnv = VarID.Map.unionWith #2 (#varEnv env, varEnv)}

  fun bindLocalCode (env as {localCodeEnv, ...}:env, id, argTys) =
      env # {localCodeEnv = FunLocalLabel.Map.insert (localCodeEnv, id, argTys)}

  fun varListToVarEnv msg vars =
      foldl (fn ({id, ty}:A.varInfo, z) =>
                if VarID.Map.inDomain (z, id)
                then (printDoubledArg msg id; z)
                else VarID.Map.insert (z, id, ty))
            VarID.Map.empty
            vars

  fun tyOf ty =
      case TypeLayout2.runtimeTy BoundTypeVarID.Map.empty ty of
        SOME rty => (ty, rty) : A.ty
      | NONE => raise Bug.Bug "tyOf"

  fun tyOf' msg ({btvEnv,...}:env) ty =
      case TypeLayout2.runtimeTy btvEnv ty of
        SOME rty => (ty, rty) : A.ty
      | NONE => (printCannotComputeRuntimeTy msg ty; errorTy)

  fun checkHandler msg ({handlerEnv,...}:env) NONE = ()
    | checkHandler msg ({handlerEnv,...}:env) (SOME handlerId) =
      if HandlerLabel.Set.member (handlerEnv, handlerId)
      then ()
      else printHandlerNotFound msg handlerId

  fun checkConst (env:env) const =
      case const of
        A.NVINT _ => tyOf B.intTy
      | A.NVWORD _ => tyOf B.wordTy
      | A.NVCONTAG _ => tyOf B.contagTy
      | A.NVBYTE _ => tyOf B.word8Ty
      | A.NVREAL _ => tyOf B.realTy
      | A.NVFLOAT _ => tyOf B.real32Ty
      | A.NVCHAR _ => tyOf B.charTy
      | A.NVUNIT => tyOf B.unitTy
      | A.NVNULLPOINTER => tyOf unitptrTy
      | A.NVNULLBOXED => tyOf B.boxedTy
      | A.NVTAG {tag, ty} => tyOf (T.SINGLETONty (T.TAGty ty))
      | A.NVFOREIGNSYMBOL {name, ty} => ty
      | A.NVFUNENTRY id =>
        (case FunEntryLabel.Map.find (#funEntryEnv env, id) of
           NONE => (printFunEntryNotFound "NVFUNENTRY" id; errorTy)
         | SOME ty => ty)
      | A.NVCALLBACKENTRY id =>
        (case CallbackEntryLabel.Map.find (#callbackEntryEnv env, id) of
           NONE => (printCallbackEntryNotFound "NVCALLBACKENTRY" id; errorTy)
         | SOME ty => tyOf (T.BACKENDty (T.CALLBACKENTRYty ty)))
      | A.NVTOPDATA id =>
        (case DataLabel.Map.find (#dataEnv env, id) of
           NONE => (printDataNotFound "NVTOPDATA" id; errorTy)
         | SOME (ty as (_, R.BOXEDty)) => ty
         | SOME ty => (printErr "NVTOPDATA: not BOXEDty\n"; ty))
      | A.NVEXTRADATA id =>
        (case ExtraDataLabel.Map.find (#extraDataEnv env, id) of
           NONE => (printExtraDataNotFound "NVEXTRADATA" id; errorTy)
         | SOME () => tyOf unitptrTy)
      | A.NVCAST {value, valueTy, targetTy, runtimeTyCast, bitCast} =>
        let
          val ty = checkConst env value
        in
          unify "NVCAST" (ty, valueTy);
          if runtimeTyCast
          then ()
          else unifyBackendTy "NVCAST" (#2 valueTy, #2 targetTy);
          targetTy
        end

  fun checkValue env anvalue =
      case anvalue of
        A.ANCONST {const, ty} =>
        let
          val constTy = checkConst env const
        in
          unify "ANCONST" (constTy, ty);
          ty
        end
      | A.ANVAR {id, ty} =>
        (case VarID.Map.find (#varEnv env, id) of
           NONE => (printVarNotFound "ANVAR" id; ty)
         | SOME ty2 => (unify "ANVAR" (ty, ty2); ty))
      | A.ANCAST {exp, expTy, targetTy, runtimeTyCast} =>
        let
          val ty = checkValue env exp
          val _ = unify "ANCAST" (ty, expTy)
        in
          if runtimeTyCast
          then ()
          else unifyBackendTy "ANCAST" (#2 expTy, #2 targetTy);
          targetTy
        end
      | A.ANBOTTOM =>
        (printErr "ANBOTTOM\n"; errorTy)

  fun recordFieldLabel indexTy =
      case TypesBasics.derefTy indexTy of
        T.SINGLETONty (T.INDEXty (label, recordTy)) => label
      | _ => (printErr "record index type expected\n"; "_ERROR_")

  fun recordFieldTys (env:env) recordTy =
      case TypesBasics.derefTy recordTy of
        T.RECORDty fieldTys => fieldTys
      | T.BOUNDVARty btv =>
        (case BoundTypeVarID.Map.find (#btvEnv env, btv) of
           SOME {tvarKind = T.REC fieldTys, ...} => fieldTys
         | _ => (printErr "record kind expected\n"; LabelEnv.empty))
      | _ => (printErr "record type expected\n"; LabelEnv.empty)

  fun checkArrayTy env ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, args=[elemTy]} =>
        if TypID.eq (#id tyCon, #id B.arrayTyCon)
        then elemTy
        else (printErr "array type expected\n"; T.ERRORty)
      | _ => (printErr "array type expected\n"; T.ERRORty)

  fun checkAddress env address =
      case address of
        A.AARECORDFIELD {recordExp, fieldIndex} =>
        let
          val recordTy = checkValue env recordExp
          val indexTy = checkValue env fieldIndex
          val label = recordFieldLabel (#1 indexTy)
          val fieldTys = recordFieldTys env (#1 recordTy)
        in
          unify "AARECORDFIELD"
                (indexTy,
                 tyOf (T.SINGLETONty (T.INDEXty (label, #1 recordTy))));
          case LabelEnv.find (fieldTys, label) of
            NONE => (printLabelNotFound "AARECORDFIELD" label; T.ERRORty)
          | SOME ty => ty
        end
      | A.AAARRAYELEM {arrayExp, elemSize, elemIndex} =>
        let
          val arrayTy = checkValue env arrayExp
          val elemTy = checkArrayTy env (#1 arrayTy)
          val sizeTy = checkValue env elemSize
          val indexTy = checkValue env elemIndex
        in
          unify "AAARRAYELEM1" (sizeTy, tyOf (T.SINGLETONty (T.SIZEty elemTy)));
          unify "AAARRAYELEM2" (indexTy, tyOf B.intTy);
          elemTy
        end

  fun checkInitField env initField =
      case initField of
        A.INIT_VALUE value => checkValue env value
      | A.INIT_COPY {srcExp, fieldSize} =>
        let
          val ty = checkValue env srcExp
          val sizeTy = checkValue env fieldSize
        in
          if #2 ty = R.BOXEDty
          then ()
          else printErr "INIT_COPY: not BOXEDty\n";
          unify "INIT_COPY" (sizeTy, tyOf (T.SINGLETONty (T.SIZEty (#1 ty))));
          ty
        end
      | A.INIT_IF {tagExp, tagOfTy, ifBoxed, ifUnboxed} =>
        let
          val tagTy = checkValue env tagExp
          val _ = unify "INIT_IF1"
                        (tagTy, tyOf (T.SINGLETONty (T.TAGty tagOfTy)))
          val ifBoxedTy = checkInitField env ifBoxed
          val ifUnboxedTy = checkInitField env ifUnboxed
        in
          unify "INIT_IF2" (ifBoxedTy, ifUnboxedTy);
          ifBoxedTy
        end

  fun checkExp env exp =
      case exp of
        A.ANLARGEINT {resultVar, dataLabel, nextExp, loc} =>
        let
          val _ =
              case ExtraDataLabel.Map.find (#extraDataEnv env, dataLabel) of
                SOME _ => ()
              | NONE => printExtraDataNotFound "ANLARGEINT" dataLabel;
        in
          unify "ANLARGEINT" (#ty resultVar, tyOf B.intInfTy);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANFOREIGNAPPLY {resultVar, funExp, argExpList, attributes, nextExp,
                          handler, loc} =>
        let
          val funTy = checkValue env funExp
          val argTys = map (checkValue env) argExpList
          val retTy = Option.map #ty resultVar
          val (funArgTys, varArgTys, funRetTy, funAttributes) =
              case derefTy funTy of
                (T.BACKENDty
                   (T.FOREIGNFUNPTRty
                      {argTyList, varArgTyList, resultTy, attributes=a1}),
                 R.FOREIGNCODEPTRty {argTys,varArgTys,retTy,attributes=a2}) =>
                 (ListPair.zipEq (argTyList, argTys),
                  case (varArgTyList, varArgTys) of
                    (NONE, NONE) => nil
                  | (SOME tys, SOME rtys) => ListPair.zipEq (tys, rtys)
                  | _ => raise Bug.Bug "checkExp: ANFOREIGNAPPLY",
                  case (resultTy, retTy) of
                    (NONE, NONE) => NONE
                  | (SOME ty, SOME rty) => SOME (ty, rty)
                  | _ => raise Bug.Bug "checkExp: ANFOREIGNAPPLY",
                  if a1 = a2 then a1
                  else raise Bug.Bug "checkExp: ANFOREIGNAPPLY")
              | _ => (printErr "FOREIGNAPPLY: not FOREIGNFUNPTRty\n";
                      (nil, nil, NONE, FFIAttributes.defaultFFIAttributes))
        in
          unifyList "FOREIGNAPPLY1" (funArgTys @ varArgTys, argTys);
          unifyOption "FOREIGNAPPLY2" (funRetTy, retTy);
          if attributes = funAttributes then ()
          else printErr "FOREIGNAPPLY: attribute mismatch\n";
          checkHandler "ANFOREIGNAPPLY3" env handler;
          checkExp (bindVarOption (env, resultVar)) nextExp
        end
      | A.ANEXPORTCALLBACK {resultVar, instTyvars, codeExp, closureEnvExp,
                            nextExp, loc} =>
        let
          val codeTy = checkValue env codeExp
          val closureEnvTy = checkValue env closureEnvExp
          val expectTy =
              case derefTy (#ty resultVar) of
                (T.BACKENDty
                   (T.FOREIGNFUNPTRty
                      {argTyList, varArgTyList=NONE, resultTy, attributes=a1}),
                 R.FOREIGNCODEPTRty
                   {argTys, varArgTys=NONE, retTy, attributes=a2}) =>
                (T.BACKENDty
                   (T.CALLBACKENTRYty
                      {tyvars = instTyvars,
                       haveClsEnv = true,
                       argTyList = argTyList,
                       retTy = resultTy,
                       attributes = a1}),
                 R.CALLBACKCODEPTRty
                   {haveClsEnv = true,
                    argTys = argTys,
                    retTy = retTy,
                    attributes = a2})
              | _ => (printErr "ANEXPORTCALLBACK: not FOREIGNFUNPTRty\n";
                      errorTy)
        in
          unify "ANEXPORTCALLBACK1" (codeTy, expectTy);
          unify "ANEXPORTCALLBACK2"
                (closureEnvTy, tyOf (T.BACKENDty (T.SOME_CLOSUREENVty)));
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANEXVAR {resultVar, id, nextExp, loc} =>
        let
          val ty = case ExternSymbol.Map.find (#externEnv env, id) of
                     NONE => (printExternNotFound "ANEXVAR" id; errorTy)
                   | SOME (ty, _) => ty
        in
          unify "ANEXVAR" (#ty resultVar, ty);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANPACK {resultVar, exp, expTy, nextExp, loc} =>
        let
          val ty = checkValue env exp
        in
          unify "ANPACK1" (ty, expTy);
          unify "ANPACK2" (#ty resultVar, (#1 ty, R.BOXEDty));
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANUNPACK {resultVar, exp, nextExp, loc} =>
        let
          val ty = checkValue env exp
        in
          unify "ANUNPACK1" (ty, (#1 ty, R.BOXEDty));
          unify "ANUNPACK2" (#ty resultVar, tyOf' "ANUNPACK" env (#1 ty));
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANDUP {resultVar, srcAddr, valueSize, nextExp, loc} =>
        let
          val ty = checkAddress env srcAddr
          val sizeTy = checkValue env valueSize
        in
          unify "ANDUP1" (sizeTy, tyOf (T.SINGLETONty (T.SIZEty ty)));
          unify "ANDUP2" (#ty resultVar, (ty, R.BOXEDty));
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANLOAD {resultVar, srcAddr, nextExp, loc} =>
        let
          val ty = checkAddress env srcAddr
        in
          unifyFrontendTy "ANLOAD" (#1 (#ty resultVar), ty);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANPRIMAPPLY {resultVar, primInfo, argExpList, argTyList, resultTy,
                       instTyList, instTagList, instSizeList, nextExp, loc} =>
        let
          val primTy = TypesBasics.tpappPrimTy (#ty primInfo, map #1 instTyList)
          val argTys = map (checkValue env) argExpList
        in
          unifyFrontendTyList
            "ANPRIMAPPLY1"
            (map #1 argTyList, #argTyList primTy);
          unifyFrontendTy
            "ANPRIMAPPLY2"
            (#1 resultTy, #resultTy primTy);
          unifyList
            "ANPRIMAPPLY3"
            (argTys, argTyList);
          unifyList
            "ANPRIMAPPLY4"
            (map (checkValue env) instTagList,
             map (fn ty => tyOf (T.SINGLETONty (T.TAGty (#1 ty)))) instTyList);
          unifyList
            "ANPRIMAPPLY5"
            (map (checkValue env) instSizeList,
             map (fn ty => tyOf (T.SINGLETONty (T.SIZEty (#1 ty)))) instTyList);
          unify
            "ANPRIMAPPLY6"
            (#ty resultVar, resultTy);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANBITCAST {resultVar, exp, expTy, targetTy, nextExp, loc} =>
        let
          val ty = checkValue env exp
        in
          unify "ANBITCAST1" (ty, expTy);
          unify "ANBITCAST2" (#ty resultVar, targetTy);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANCALL {resultVar, codeExp, closureEnvExp, argExpList, nextExp,
                  handler, loc} =>
        let
          val codeTy = checkValue env codeExp
          val closureEnvTy = Option.map (checkValue env) closureEnvExp
          val argTys = map (checkValue env) argExpList
          val (haveClsEnv, argTyList, retTy) =
              case codeTy of
                (T.BACKENDty (T.FUNENTRYty _),
                 R.MLCODEPTRty {haveClsEnv, argTys, retTy=SOME retTy}) =>
                (haveClsEnv, argTys, retTy)
              | _ => (printErr "ANCALL: not FUNENTRYty\n";
                      (true, nil, R.UINTty))
        in
          case (haveClsEnv, closureEnvTy) of
            (false, NONE) => ()
          | (true, SOME ty) =>
            unify "ANCALL1" (ty, tyOf (T.BACKENDty T.SOME_CLOSUREENVty))
          | _ => printErr "ANCALL: closure env mismatch\n";
          unifyBackendTyList
            "ANCALL2"
            (map #2 argTys, argTyList);
          unifyBackendTy
            "ANCALL3"
            (#2 (#ty resultVar), retTy);
          checkHandler "ANCALL4" env handler;
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANTAILCALL {resultTy, codeExp, closureEnvExp, argExpList, loc} =>
        let
          val codeTy = checkValue env codeExp
          val closureEnvTy = Option.map (checkValue env) closureEnvExp
          val argTys = map (checkValue env) argExpList
          val (haveClsEnv, argTyList, retTy) =
              case codeTy of
                (T.BACKENDty (T.FUNENTRYty _),
                 R.MLCODEPTRty {haveClsEnv, argTys, retTy=SOME retTy}) =>
                (haveClsEnv, argTys, retTy)
              | _ => (printErr "ANTAILCALL: not FUNENTRYty\n";
                      (true, nil, R.UINTty))
        in
          case (haveClsEnv, closureEnvTy) of
            (false, NONE) => ()
          | (true, SOME ty) =>
            unify "ANTAILCALL1" (ty, tyOf (T.BACKENDty T.SOME_CLOSUREENVty))
          | _ => printErr "ANTAILCALL: closure env mismatch\n";
          unifyBackendTyList "ANTAILCALL2" (map #2 argTys, argTyList);
          unifyBackendTy "ANTAILCALL3" (#2 resultTy, retTy)
        end
      | A.ANRECORD {resultVar, fieldList, isMutable, clearPad,
                    allocSizeExp, bitmaps, nextExp,
                    loc} =>
        let
          val fields =
              map (fn {fieldExp, fieldTy, fieldIndex} =>
                      let
                        val ty = checkInitField env fieldExp
                        val indexTy = checkValue env fieldIndex
                        val label = recordFieldLabel (#1 indexTy)
                      in
                        (label, ty, fieldTy, indexTy)
                      end)
                  fieldList
          val recordTy =
              T.RECORDty (foldl (fn ((label, ty, _, _), z) =>
                                    LabelEnv.insert (z, label, #1 ty))
                                LabelEnv.empty
                                fields)
          val allocSizeTy = checkValue env allocSizeExp
          val bitmaps =
              map (fn {bitmapIndex, bitmapExp} =>
                      {bitmapIndex = checkValue env bitmapIndex,
                       bitmapExp = checkValue env bitmapExp})
                  bitmaps
        in
          unifyList "ANRECORD1" (map #2 fields, map #3 fields);
          unifyList
            "ANRECORD2"
            (map #4 fields,
             map (fn x => tyOf (T.SINGLETONty (T.INDEXty (#1 x, recordTy))))
                 fields);
          unify "ANRECORD3"
                (allocSizeTy, tyOf (T.BACKENDty (T.RECORDSIZEty recordTy)));
          unifyList
            "ANRECORD4"
            (map #bitmapIndex bitmaps,
             map (fn i =>
                     tyOf (T.BACKENDty (T.RECORDBITMAPINDEXty (i, recordTy))))
                 (indices bitmaps));
          unifyList
            "ANRECORD5"
            (map #bitmapExp bitmaps,
             map (fn i => tyOf (T.BACKENDty (T.RECORDBITMAPty (i, recordTy))))
                 (indices bitmaps));
          unify "ANRECORD6" (#ty resultVar, tyOf recordTy);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANMODIFY {resultVar, recordExp, indexExp, valueExp, valueTy,
                    nextExp, loc} =>
        let
          val recordTy = checkValue env recordExp
          val fields = recordFieldTys env (#1 recordTy)
          val indexTy = checkValue env indexExp
          val label = recordFieldLabel (#1 indexTy)
          val ty = checkInitField env valueExp
        in
          case LabelEnv.find (fields, label) of
            NONE => printLabelNotFound "ANMODIFY" label
          | SOME fieldTy =>
            unify "ANMODIFY1" (ty, tyOf' "ANMODIFY" env fieldTy);
          unify "ANMODIFY2"
                (indexTy,
                 tyOf (T.SINGLETONty (T.INDEXty (label, #1 recordTy))));
          unify "ANMODIFY3" (#ty resultVar, recordTy);
          checkExp (bindVar (env, resultVar)) nextExp
        end
      | A.ANRETURN {value, loc} =>
        let
          val ty = checkValue env value
        in
          unify "ANRETURN" (ty, #returnTy env)
        end
      | A.ANCOPY {srcExp, dstAddr, valueSize, nextExp, loc} =>
        let
          val srcTy = checkValue env srcExp
          val dstTy = checkAddress env dstAddr
          val sizeTy = checkValue env valueSize
        in
          unify "ANCOPY1" (srcTy, (dstTy, R.BOXEDty));
          unify "ANCOPY2" (sizeTy, tyOf (T.SINGLETONty (T.SIZEty (#1 srcTy))));
          checkExp env nextExp
        end
      | A.ANSTORE {srcExp, srcTy, dstAddr, nextExp, loc} =>
        let
          val ty = checkValue env srcExp
          val dstTy = checkAddress env dstAddr
        in
          unify "ANSTORE1" (ty, srcTy);
          unifyFrontendTy "ANSTORE2" (#1 ty, dstTy);
          checkExp env nextExp
        end
      | A.ANEXPORTVAR {id, ty, valueExp, nextExp, loc} =>
        let
          val externTy =
              case ExternSymbol.Map.find (#externEnv env, id) of
                NONE => (printExternNotFound "ANEXPORTVAR" id; errorTy)
              | SOME (ty, EXPORT) => ty
              | SOME (ty, EXTERN) =>
                (printErr "ANEXPORTVAR: not own entry\n"; ty)
          val valueTy = checkValue env valueExp
        in
          unify "ANEXPORTVAR1" (externTy, ty);
          unify "ANEXPORTVAR2" (valueTy, ty);
          checkExp env nextExp
        end
      | A.ANRAISE {argExp, loc} =>
        let
          val ty = checkValue env argExp
        in
          unify "ANRAISE" (ty, tyOf B.exnTy)
        end
      | A.ANHANDLER {nextExp, exnVar, id, handlerExp, loc} =>
        let
          val handlerEnv = HandlerLabel.Set.add (#handlerEnv env, id)
        in
          checkExp (env # {handlerEnv = handlerEnv}) nextExp;
          unify "ANHANDLER" (#ty exnVar, tyOf B.exnTy);
          checkExp (bindVar (env, exnVar)) handlerExp
        end
      | A.ANSWITCH {switchExp, expTy, branches, default, loc} =>
        let
          val ty = checkValue env switchExp
        in
          unify "ANSWITCH1" (ty, expTy);
          unifyList
            "ANSWITCH2"
            (map (fn (const,_) => checkConst env const) branches,
             map (fn _ => expTy) branches);
          app
            (fn id =>
                case FunLocalLabel.Map.find (#localCodeEnv env, id) of
                  NONE => printLocalCodeNotFound "ANSWITCH" id
                | SOME argTyList => unifyList "ANSWITCH3" (nil, argTyList))
            (map #2 branches @ [default])
        end
      | A.ANLOCALCODE {id, recursive, argVarList, bodyExp, nextExp, loc} =>
        let
          val env2 = bindLocalCode (env, id, map #ty argVarList)
          val bodyEnv = if recursive then env2 else env
          val varEnv = varListToVarEnv "ANLOCALCODE" argVarList
          val bodyEnv = extendVarEnv (env2, varEnv)
        in
          checkExp bodyEnv bodyExp;
          checkExp env2 nextExp
        end
      | A.ANGOTO {id, argList, loc} =>
        let
          val argTys = map (checkValue env) argList
        in
          case FunLocalLabel.Map.find (#localCodeEnv env, id) of
            NONE => printLocalCodeNotFound "ANGOTO" id
          | SOME argTyList => unifyList "ANGOTO" (argTys, argTyList)
        end
      | A.ANUNREACHABLE =>
        ()

  fun makeTopdataEnv (topdata, env:env) =
      case topdata of
        A.NTEXTERNVAR {id, ty, loc} =>
        if ExternSymbol.Map.inDomain (#externEnv env, id)
        then (printDoubledExtern "NTEXTERNVAR" id; env)
        else env
               # {externEnv =
                    ExternSymbol.Map.insert (#externEnv env, id, (ty, EXTERN))}
      | A.NTEXPORTVAR {id, ty, value, loc} =>
        if ExternSymbol.Map.inDomain (#externEnv env, id)
        then (printDoubledExtern "NTEXPORTVAR" id; env)
        else env
               # {externEnv =
                    ExternSymbol.Map.insert (#externEnv env, id, (ty, EXPORT))}
      | A.NTSTRING {id, string, loc} =>
        if DataLabel.Map.inDomain (#dataEnv env, id)
        then (printDoubledData "NTSTRING" id; env)
        else env
               # {dataEnv =
                    DataLabel.Map.insert (#dataEnv env, id, tyOf B.stringTy)}
      | A.NTLARGEINT {id, value, loc} =>
        if ExtraDataLabel.Map.inDomain (#extraDataEnv env, id)
        then (printDoubledExtraData "NTLARGEINT" id; env)
        else env
               # {extraDataEnv =
                    ExtraDataLabel.Map.insert (#extraDataEnv env, id, ())}
      | A.NTRECORD {id, tyvarKindEnv, fieldList, recordTy,
                    isMutable, clearPad, bitmaps, loc} =>
        if DataLabel.Map.inDomain (#dataEnv env, id)
        then (printDoubledData "NTRECORD" id; env)
        else env
               # {dataEnv =
                    DataLabel.Map.insert (#dataEnv env, id, tyOf recordTy)}
      | A.NTARRAY {id, elemTy=(elemTy,_), isMutable, clearPad, numElements,
                   initialElements, elemSizeExp, tagExp, loc} =>
        if DataLabel.Map.inDomain (#dataEnv env, id)
        then (printDoubledData "NTARRAY" id; env)
        else env
               # {dataEnv = DataLabel.Map.insert (#dataEnv env, id,
                                                  tyOf (arrayTy elemTy))}

  fun checkTopConst env (const, ty) =
      (unify "TopConst" (checkConst env const, ty); ty)

  fun checkTopdata env topdata =
      case topdata of
        A.NTEXTERNVAR {id, ty, loc} => ()
      | A.NTEXPORTVAR {id, ty, value, loc} => ()
      | A.NTSTRING {id, string, loc} => ()
      | A.NTLARGEINT {id, value, loc} => ()
      | A.NTRECORD {id, tyvarKindEnv=_, fieldList, recordTy,
                    isMutable, clearPad, bitmaps, loc} =>
        let
          val fields =
              map
                (fn {fieldExp, fieldSize, fieldIndex} =>
                    let
                      val ty = checkTopConst env fieldExp
                      val sizeTy = checkTopConst env fieldSize
                      val indexTy = checkTopConst env fieldIndex
                      val label = recordFieldLabel (#1 indexTy)
                    in
                      (label, ty, sizeTy, indexTy)
                    end)
                fieldList
          val recordTy2 =
              T.RECORDty (foldl (fn ((label, ty, _, _), z) =>
                                    LabelEnv.insert (z, label, #1 ty))
                                LabelEnv.empty
                                fields)
          val bitmaps =
              map (fn {bitmapIndex, bitmapExp} =>
                      {bitmapIndex = checkTopConst env bitmapIndex,
                       bitmapExp = checkTopConst env bitmapExp})
                  bitmaps
        in
          unify "NTRECORD1" (tyOf recordTy2, tyOf recordTy);
          unifyList
            "NTRECORD2"
            (map #3 fields,
             map (fn (_,ty,_,_) => tyOf (T.SINGLETONty (T.SIZEty (#1 ty))))
                 fields);
          unifyList
            "NTRECORD3"
            (map #4 fields,
             map (fn (l,_,_,_) =>
                     tyOf (T.SINGLETONty (T.INDEXty (l, recordTy))))
                 fields);
          unifyList
            "NTRECORD4"
            (map #bitmapIndex bitmaps,
             map (fn i =>
                     tyOf (T.BACKENDty (T.RECORDBITMAPINDEXty (i, recordTy))))
                 (indices bitmaps));
          unifyList
            "NTRECORD5"
            (map #bitmapExp bitmaps,
             map (fn i => tyOf (T.BACKENDty (T.RECORDBITMAPty (i, recordTy))))
                 (indices bitmaps))
        end
      | A.NTARRAY {id, elemTy=(elemTy,_), isMutable, clearPad, numElements,
                   initialElements, elemSizeExp, tagExp, loc} =>
        let
          val numTy = checkTopConst env numElements
          val sizeTy = checkTopConst env elemSizeExp
          val tagTy = checkTopConst env tagExp
        in
          unifyList "NTARRAY1" (map (checkTopConst env) initialElements,
                                map (fn _ => tyOf elemTy) initialElements);
          unify "NTARRAY2" (numTy, tyOf B.intTy);
          unify "NTARRAY3" (sizeTy, tyOf (T.SINGLETONty (T.SIZEty elemTy)));
          unify "NTARRAY4" (tagTy, tyOf (T.SINGLETONty (T.TAGty elemTy)))
        end

  fun makeTopdecEnv (topdec, env:env) =
      case topdec of
        A.ATFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
                      retTy, loc} =>
        let
          val ty =
              (T.BACKENDty (T.FUNENTRYty {tyvars = tyvarKindEnv,
                                          argTyList = map (#1 o #ty) argVarList,
                                          haveClsEnv = isSome closureEnvVar,
                                          retTy = SOME (#1 retTy)}),
               R.MLCODEPTRty {haveClsEnv = isSome closureEnvVar,
                              argTys = map (#2 o #ty) argVarList,
                              retTy = SOME (#2 retTy)})
        in
          if FunEntryLabel.Map.inDomain (#funEntryEnv env, id)
          then (printDoubledFunEntry "ATFUNCTION" id; env)
          else env # {funEntryEnv = FunEntryLabel.Map.insert
                                      (#funEntryEnv env, id, ty)}
        end
      | A.ATCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              bodyExp, attributes, retTy, cleanupHandler,
                              loc} =>
        let
          val callbackEntryTy =
              {tyvars = tyvarKindEnv,
               argTyList = map (#1 o #ty) argVarList,
               haveClsEnv = isSome closureEnvVar,
               retTy = Option.map #1 retTy,
               attributes = attributes}
        in
          if CallbackEntryLabel.Map.inDomain (#callbackEntryEnv env, id)
          then (printDoubledCallbackEntry "ATCALLBACKFUNCTION" id; env)
          else env # {callbackEntryEnv =
                        CallbackEntryLabel.Map.insert
                          (#callbackEntryEnv env, id, callbackEntryTy)}
        end

  fun checkFunctionBody msg env (tyvarKindEnv, argVarList, closureEnvVar,
                                 bodyExp, retTy) =
      let
        val varEnv =
            varListToVarEnv
              msg
              ((case closureEnvVar of NONE => nil | SOME v => [v])
               @ argVarList)
        val env =
            env # {btvEnv = tyvarKindEnv,
                   varEnv = varEnv,
                   returnTy = retTy}
      in
        checkExp env bodyExp
      end

  fun checkTopdec env topdec =
      case topdec of
        A.ATFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
                      retTy, loc} =>
        checkFunctionBody
          "ATFUNCTION"
          env
          (tyvarKindEnv, argVarList, closureEnvVar, bodyExp, retTy)
      | A.ATCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              bodyExp, attributes, retTy, cleanupHandler,
                              loc} =>
        let
          val handlerEnv =
              HandlerLabel.Set.add (#handlerEnv env, cleanupHandler)
          val env = env # {handlerEnv = handlerEnv}
        in
          checkFunctionBody
            "ATCALLBACKFUNCTION"
            env
            (tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
             case retTy of
               SOME ty => ty
             | NONE => tyOf B.unitTy)
        end

  fun check ({topdata, topdecs, topExp}:A.program) =
      let
        val env = emptyEnv (tyOf B.unitTy)
        val env = foldl makeTopdataEnv env topdata
        val env = foldl makeTopdecEnv env topdecs
      in
        app (checkTopdata env) topdata;
        app (checkTopdec env) topdecs;
        checkExp env topExp
      end

end
