(**
 * calling compilation compile
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure CallingConventionCompile : sig

  val compile : ClosureCalc.program -> RuntimeCalc.program

end =
struct

  structure C = ClosureCalc
  structure N = RuntimeCalc
  structure T = Types
  structure R = RuntimeTypes
  structure RC = RecordCalc
  structure P = BuiltinPrimitive

  fun tyToString ty = Bug.prettyPrint (T.format_ty nil ty)
  fun rtyToString ty = Bug.prettyPrint (N.formatWithType_ty nil ty)

  type env =
      {
        btvEnv : Types.btvEnv,
        wrapperMap : FunEntryLabel.id FunEntryLabel.Map.map
      }

  val emptyBtvEnv =
      BoundTypeVarID.Map.empty : Types.btvEnv

  val emptyWrapperMap =
      FunEntryLabel.Map.empty : FunEntryLabel.id FunEntryLabel.Map.map

  val emptyEnv =
      {btvEnv = emptyBtvEnv, wrapperMap = emptyWrapperMap} : env

  fun bindTyvars (env:env, btvEnv) =
      {btvEnv = BoundTypeVarID.Map.unionWith #2 (#btvEnv env, btvEnv),
       wrapperMap = #wrapperMap env}
      : env

  fun runtimeTy btvEnv ty =
      case TypeLayout2.runtimeTy btvEnv ty of
          SOME rty => SOME rty
        | NONE =>
          case TypesBasics.derefTy ty of
            ty as T.BOUNDVARty tid =>
            (case BoundTypeVarID.Map.find (btvEnv, tid) of
               SOME _ => NONE
             | NONE => raise Bug.Bug ("runtimeTy " ^ tyToString ty))
           | _ => raise Bug.Bug ("runtimeTy " ^ tyToString ty)

  fun compileTy btvEnv ty =
      case runtimeTy btvEnv ty of
        SOME rty => (ty, rty) : N.ty
      | (* all type variables have R.BOXEDty runtime kind *)
        NONE => (ty, R.BOXEDty)

  type cconv =
       {tyvars : T.btvEnv,
        argTyList : N.ty list,
        retTy : N.ty,
        (* returns true if any type instantiation does not affect calling
         * convention *)
        isRigid : bool}
(*
  fun compileVarInfo btvEnv ({path, id, ty}:RC.varInfo) =
      {path = path, id = id, ty = compileTy btvEnv ty} : N.varInfo
*)

  fun compileConvention ({tyvars, haveClsEnv, argTyList, retTy}:T.codeEntryTy) =
      let
        val isRigid =
            List.all (fn ty => isSome (runtimeTy tyvars ty)) argTyList
            andalso case retTy of NONE => true
                               | SOME ty => isSome (runtimeTy tyvars ty)
        val argTyList = map (compileTy tyvars) argTyList
        val retTy = case retTy of
                      NONE => raise Bug.Bug "compileConvention"
                    | SOME ty => compileTy tyvars ty
      in
        {tyvars = tyvars,
         argTyList = argTyList,
         retTy = retTy,
         isRigid = isRigid} : cconv
      end

  fun funTyToConvention btvEnv funTy =
      case TypesBasics.derefTy funTy of
        T.FUNMty (argTys, retTy) =>
        compileConvention {tyvars = btvEnv,
                           haveClsEnv = true,  (* dummy *)
                           argTyList = argTys,
                           retTy = SOME retTy}
      | _ => raise Bug.Bug "funTyToConvention"

  fun isWrapperConvention ({argTyList, retTy, ...}:cconv) =
      List.all (fn (_, R.BOXEDty) => true | (_, _) => false)
               (retTy :: argTyList)

  fun toWrapperConvention ({tyvars, argTyList, retTy, isRigid}:cconv) =
      {tyvars = tyvars,
       argTyList = map (fn (ty, _) => (ty, R.BOXEDty)) argTyList,
       retTy = (#1 retTy, R.BOXEDty),
       isRigid = true}
      : cconv

  fun funEntryTy ({tyvars, argTyList, retTy, ...}:cconv, haveClsEnv) =
      (T.BACKENDty (T.FUNENTRYty {tyvars = tyvars,
                                  haveClsEnv = haveClsEnv,
                                  argTyList = map #1 argTyList,
                                  retTy = SOME (#1 retTy)}),
       R.MLCODEPTRty {haveClsEnv = haveClsEnv,
                      argTys = map #2 argTyList,
                      retTy = SOME (#2 retTy)})
      : N.ty

  fun newVar ty =
      {id = VarID.generate (), ty = ty} : N.varInfo

  fun makeLet (N.NCVAR {varInfo,...}, _, loc) = (fn K => K, varInfo)
    | makeLet (exp, ty, loc) =
      let
        val v = newVar ty
      in
        (fn K => N.NCLET {boundVar = v,
                          boundExp = exp,
                          mainExp = K,
                          loc = loc},
         v)
      end

  fun makeBind (exp as N.NCCONST _, _, loc) = (fn K => K, exp)
    | makeBind (exp, ty, loc) =
      let
        val (letFn, v) = makeLet (exp, ty, loc)
      in
        (letFn, N.NCVAR {varInfo=v, loc=loc})
      end

  fun makeBindList (nil, nil, loc) = (fn x => x, nil)
    | makeBindList (exp::exps, ty::tys, loc) =
      let
        val (letFn1, var) = makeBind (exp, ty, loc)
        val (letFn2, vars) = makeBindList (exps, tys, loc)
      in
        (letFn1 o letFn2, var::vars)
      end
    | makeBindList _ = raise Bug.Bug "makeBindList"

  val unitTy = (BuiltinTypes.unitTy, R.UINTty)
  val intTy = (BuiltinTypes.intTy, R.INTty)
  val wordTy = (BuiltinTypes.wordTy, R.UINTty)
  val boxedTy = (BuiltinTypes.boxedTy, R.BOXEDty)
  val boolTy = (BuiltinTypes.boolTy, R.UINTty)
  val contagTy = (BuiltinTypes.contagTy, R.UINTty)
  val someFunWrapperTy = (T.BACKENDty T.SOME_FUNWRAPPERty, R.SOME_CODEPTRty)
  val someFunEntryTy = (T.BACKENDty T.SOME_FUNENTRYty, R.SOME_CODEPTRty)
  val someClosureEnvTy = (T.BACKENDty T.SOME_CLOSUREENVty, R.BOXEDty)
  val someCconvtagTy = (T.BACKENDty T.SOME_CCONVTAGty, R.UINTty)
  fun cconvtagTy ty = (T.BACKENDty (T.CCONVTAGty ty), R.UINTty)
  fun tagTy ty = (T.SINGLETONty (T.TAGty ty), R.UINTty)
  fun sizeTy ty = (T.SINGLETONty (T.SIZEty ty), R.UINTty)
  fun indexTy x = (T.SINGLETONty (T.INDEXty x), R.UINTty)
  fun refTy ty =
      (T.CONSTRUCTty {tyCon = BuiltinTypes.refTyCon, args = [ty]}, R.BOXEDty)
  fun arrayTy ty =
      (T.CONSTRUCTty {tyCon = BuiltinTypes.arrayTyCon, args = [ty]}, R.BOXEDty)

  fun isBoxedKind ((_, R.BOXEDty):N.ty) = true
    | isBoxedKind _ = false

  fun evalConstTag tagExp =
      case tagExp of
        N.NCCONST {const = N.NVTAG {tag, ...}, ...} => SOME tag
      | _ => NONE

  fun switchByTag {tagExp, valueTy, ifBoxedTag, ifUnboxedTag, resultTy, loc} =
      case evalConstTag tagExp of
        SOME R.TAG_UNBOXED => ifUnboxedTag
      | SOME R.TAG_BOXED => ifBoxedTag
      | NONE =>
        N.NCSWITCH
          {switchExp = tagExp,
           expTy = tagTy valueTy,
           branches = [{constant = N.NVTAG {tag=R.TAG_UNBOXED, ty=valueTy},
                        branchExp = ifUnboxedTag}],
           defaultExp = ifBoxedTag,
           resultTy = resultTy,
           loc = loc}

  fun IfNull {exp, expTy, thenExp, elseExp, resultTy, loc} =
      N.NCSWITCH
        {switchExp =
           N.NCCAST
             {exp = N.NCPRIMAPPLY
                      {primInfo =
                         {primitive = P.M P.IdentityEqual,
                          ty = {boundtvars = emptyBtvEnv,
                                argTyList = [BuiltinTypes.boxedTy,
                                             BuiltinTypes.boxedTy],
                                resultTy = BuiltinTypes.boolTy}},
                       argExpList =
                         [N.NCCAST {exp = exp,
                                    expTy = expTy,
                                    targetTy = boxedTy,
                                    runtimeTyCast = false,
                                    bitCast = false,
                                    loc = loc},
                          N.NCCONST {const=N.NVNULLBOXED, ty=boxedTy, loc=loc}],
                       argTyList = [boxedTy, boxedTy],
                       resultTy = boolTy,
                       instTyList = nil,
                       instTagList = nil,
                       instSizeList = nil,
                       loc = loc},
              expTy = boolTy,
              targetTy = contagTy,
              runtimeTyCast = false,
              bitCast = false,
              loc = loc},
         expTy = contagTy,
         branches = [{constant = N.NVCONTAG 0w0, branchExp = elseExp}],
         defaultExp = thenExp,
         resultTy = resultTy,
         loc = loc}

  fun funEntryExp (id, cconv, haveClsEnv, loc) =
      N.NCCONST {const = N.NVFUNENTRY id,
                 ty = funEntryTy (cconv, haveClsEnv),
                 loc = loc}

  fun cconvTagConstWord ({isRigid, ...}:cconv) =
      N.NVWORD (if isRigid then 0w1 else 0w0)

  fun IfRigidCconvTag {cconvTagExp, ifRigid, ifNotRigid, resultTy, loc} =
      N.NCSWITCH
        {switchExp = N.NCCAST {exp = cconvTagExp,
                               expTy = someCconvtagTy,
                               targetTy = wordTy,
                               runtimeTyCast = false,
                               bitCast = false,
                               loc = loc},
         expTy = wordTy,
         branches = [{constant = N.NVWORD 0w0, branchExp = ifNotRigid}],
         defaultExp = ifRigid,
         resultTy = resultTy,
         loc = loc}

  fun staticCall {calleeConv : cconv, callerConv : cconv,
                  codeExp, closureEnvExp, argExpList, loc} =
      let
        fun convert ((fromTy, toTy), exp) =
            case (fromTy, toTy) of
              ((_, R.BOXEDty), (_, R.BOXEDty)) => exp
            | ((_, R.BOXEDty), _) =>
              N.NCUNPACK {exp = exp, resultTy = toTy, loc = loc}
            | (_, (_, R.BOXEDty)) =>
              N.NCPACK {exp = exp, expTy = fromTy, loc = loc}
            | _ =>
              if #2 fromTy = #2 toTy
              then exp
              else raise Bug.Bug ("staticCall: convert from "
                                  ^ rtyToString fromTy
                                  ^ " to " ^ rtyToString toTy)
        val argExpList =
            ListPair.mapEq convert
                           (ListPair.zipEq (#argTyList callerConv,
                                            #argTyList calleeConv),
                            argExpList)
        val callExp =
            N.NCCALL {codeExp = codeExp,
                      closureEnvExp = closureEnvExp,
                      argExpList = argExpList,
                      resultTy = #retTy calleeConv,
                      loc = loc}
      in
        convert ((#retTy calleeConv, #retTy callerConv), callExp)
      end

  fun dynamicCall {cconvTag, wrapper, codeExp, closureEnvExp,
                   argExpList, callerConv, loc} =
      let
        val (letFn1, codeExp) = makeBind (codeExp, someFunEntryTy, loc)
        val (letFn2, wrapper) = makeBind (wrapper, someFunWrapperTy, loc)
        val (letFn3, closureEnvExp) =
            makeBind (closureEnvExp, someClosureEnvTy, loc)
        val (letFn4, argExpList) =
            makeBindList (argExpList, #argTyList callerConv, loc)
        fun call (calleeConv, codeExp, codeExpTy) =
            IfNull
              {exp = closureEnvExp,
               expTy = someClosureEnvTy,
               thenExp = staticCall
                           {calleeConv = calleeConv,
                            callerConv = callerConv,
                            codeExp =
                              N.NCCAST
                                {exp = codeExp,
                                 expTy = codeExpTy,
                                 targetTy = funEntryTy (calleeConv, false),
                                 runtimeTyCast = true,
                                 bitCast = true,
                                 loc = loc},
                            closureEnvExp = NONE,
                            argExpList = argExpList,
                            loc = loc},
               elseExp = staticCall
                           {calleeConv = calleeConv,
                            callerConv = callerConv,
                            codeExp =
                              N.NCCAST
                                {exp = codeExp,
                                 expTy = codeExpTy,
                                 targetTy = funEntryTy (calleeConv, true),
                                 runtimeTyCast = true,
                                 bitCast = true,
                                 loc = loc},
                            closureEnvExp = SOME closureEnvExp,
                            argExpList = argExpList,
                            loc = loc},
               resultTy = #retTy callerConv,
               loc = loc}
        val callExp =
            if isWrapperConvention callerConv
            then call (callerConv, wrapper, someFunWrapperTy)
            else if not (#isRigid callerConv)
            then call (toWrapperConvention callerConv, wrapper,
                       someFunWrapperTy)
            else IfRigidCconvTag
                   {cconvTagExp = cconvTag,
                    ifRigid = call (callerConv, codeExp, someFunEntryTy),
                    ifNotRigid = call (toWrapperConvention callerConv, wrapper,
                                       someFunWrapperTy),
                    resultTy = #retTy callerConv,
                    loc = loc}
      in
        (letFn1 o letFn2 o letFn3 o letFn4) callExp
      end

  fun compileVarInfo btvEnv ({path, id, ty}:RecordCalc.varInfo) =
      {id = id, ty = compileTy btvEnv ty} : N.varInfo

  fun compileConst (env as {btvEnv, wrapperMap}:env) ccvalue =
      case ccvalue of
        C.CVINT x => N.NVINT x
      | C.CVEXTRADATA x => N.NVEXTRADATA x
      | C.CVWORD x => N.NVWORD x
      | C.CVCONTAG x => N.NVCONTAG x
      | C.CVBYTE x => N.NVBYTE x
      | C.CVREAL x => N.NVREAL x
      | C.CVFLOAT x => N.NVFLOAT x
      | C.CVCHAR x => N.NVCHAR x
      | C.CVUNIT => N.NVUNIT
      | C.CVNULLPOINTER => N.NVNULLPOINTER
      | C.CVNULLBOXED => N.NVNULLBOXED
      | C.CVTAG x => N.NVTAG x
      | C.CVFOREIGNSYMBOL {name, ty} =>
        N.NVFOREIGNSYMBOL {name = name, ty = compileTy btvEnv ty}
      | C.CVFUNENTRY {id, codeEntryTy} =>
        N.NVFUNENTRY id
      | C.CVFUNWRAPPER {id, codeEntryTy} =>
        let
          val cconv = toWrapperConvention (compileConvention codeEntryTy)
          val ty = funEntryTy (cconv, #haveClsEnv codeEntryTy)
        in
          case FunEntryLabel.Map.find (wrapperMap, id) of
            SOME id =>
            N.NVCAST {value = N.NVFUNENTRY id,
                      valueTy = ty,
                      targetTy = someFunWrapperTy,
                      runtimeTyCast = true,
                      bitCast = true}
         | NONE => raise Bug.Bug "compileConst: CVFUNWRAPPER"
        end
      | C.CVCALLBACKENTRY {id, callbackEntryTy} =>
        N.NVCALLBACKENTRY id
      | C.CVTOPDATA {id, ty} =>
        N.NVTOPDATA id
      | C.CVCAST {value, valueTy, targetTy, runtimeTyCast, bitCast} =>
        N.NVCAST {value = compileConst env value,
                  valueTy = compileTy btvEnv valueTy,
                  targetTy = compileTy btvEnv targetTy,
                  runtimeTyCast = runtimeTyCast,
                  bitCast = bitCast}
      | C.CVCCONVTAG ty =>
        N.NVCAST
          {value = cconvTagConstWord (compileConvention ty),
           valueTy = wordTy,
           targetTy = cconvtagTy ty,
           runtimeTyCast = false,
           bitCast = false}

  fun compileTopConst env (const, ty) =
      (compileConst env const, compileTy (#btvEnv env) ty)

  fun compilePrim (primitive, primTy, instTyList, instTagList, instSizeList,
                   argTyList, resultTy, argExpList, loc) =
      case (primitive, instTyList, instTagList, instSizeList, argExpList) of
        (P.Array_sub_unsafe, [ty], [tag], [size], [arrayExp, indexExp]) =>
        let
          val (arrayLet, arrayVar) = makeBind (arrayExp, arrayTy (#1 ty), loc)
          val (indexLet, indexVar) = makeBind (indexExp, intTy, loc)
          val (sizeLet, sizeVar) = makeBind (size, sizeTy (#1 ty), loc)
          val addr = N.NAARRAYELEM {arrayExp = arrayVar,
                                    elemSize = sizeVar,
                                    elemIndex = indexVar}
          val loadExp = N.NCLOAD {srcAddr = addr,
                                  resultTy = ty,
                                  loc = loc}
        in
          (arrayLet o indexLet o sizeLet)
            (if isBoxedKind ty
             then switchByTag
                    {tagExp = tag,
                     valueTy = #1 ty,
                     ifBoxedTag = loadExp,
                     ifUnboxedTag = N.NCDUP {srcAddr = addr,
                                             resultTy = ty,
                                             valueSize = sizeVar,
                                             loc = loc},
                     resultTy = ty,
                     loc = loc}
             else loadExp)
        end
      | (P.Array_sub_unsafe, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_sub"

      | (P.Array_update_unsafe, [ty], [tag], [size],
         [arrayExp, indexExp, argExp]) =>
        let
          val (arrayLet, arrayVar) = makeBind (arrayExp, arrayTy (#1 ty), loc)
          val (indexLet, indexVar) = makeBind (indexExp, intTy, loc)
          val (argLet, argVar) = makeBind (argExp, ty, loc)
          val (sizeLet, sizeVar) = makeBind (size, sizeTy (#1 ty), loc)
          val addr = N.NAARRAYELEM {arrayExp = arrayVar,
                                    elemSize = sizeVar,
                                    elemIndex = indexVar}
          val storeExp = N.NCSTORE {srcExp = argVar,
                                    srcTy = ty,
                                    dstAddr = addr,
                                    loc = loc}
        in
          (arrayLet o indexLet o argLet o sizeLet)
            (if isBoxedKind ty
             then switchByTag
                    {tagExp = tag,
                     valueTy = #1 ty,
                     ifBoxedTag = storeExp,
                     ifUnboxedTag = N.NCCOPY {srcExp = argVar,
                                              valueSize = sizeVar,
                                              dstAddr = addr,
                                              loc = loc},
                     resultTy = unitTy,
                     loc = loc}
             else storeExp)
        end
      | (P.Array_update_unsafe, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_update_unsafe"

      | (P.R prim, _, _, _, _) =>
        N.NCPRIMAPPLY {primInfo = {primitive = prim, ty = primTy},
                       argExpList = argExpList,
                       argTyList = argTyList,
                       resultTy = resultTy,
                       instTyList = instTyList,
                       instTagList = instTagList,
                       instSizeList = instSizeList,
                       loc = loc}

  fun compileExp (env as {btvEnv, ...}:env) ccexp =
      case ccexp of
        C.CCFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        N.NCFOREIGNAPPLY
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           attributes = attributes,
           resultTy = Option.map (compileTy btvEnv) resultTy,
           loc = loc}
      | C.CCEXPORTCALLBACK {codeExp, closureEnvExp, instTyvars, resultTy,
                            loc} =>
        N.NCEXPORTCALLBACK
          {codeExp = compileExp env codeExp,
           closureEnvExp = compileExp env closureEnvExp,
           instTyvars = instTyvars,
           resultTy = compileTy btvEnv resultTy,
           loc = loc}
      | C.CCCONST {const, ty, loc} =>
        N.NCCONST {const = compileConst env const,
                   ty = compileTy btvEnv ty,
                   loc = loc}
      | C.CCLARGEINT {srcLabel, loc} =>
        N.NCLARGEINT {srcLabel = srcLabel, loc = loc}
      | C.CCVAR {varInfo, loc} =>
        N.NCVAR {varInfo = compileVarInfo btvEnv varInfo, loc = loc}
      | C.CCEXVAR {id, ty, loc} =>
        N.NCEXVAR {id = id,
                   ty = compileTy btvEnv ty,
                   loc = loc}
      | C.CCPRIMAPPLY {primInfo={primitive, ty}, argExpList, instTyList,
                       instTagList, instSizeList, loc} =>
        let
          val {argTyList, resultTy} = TypesBasics.tpappPrimTy (ty, instTyList)
          val argTyList = map (compileTy btvEnv) argTyList
          val resultTy = compileTy btvEnv resultTy
          val argExpList = map (compileExp env) argExpList
          val instTyList = map (compileTy btvEnv) instTyList
          val instTagList = map (compileExp env) instTagList
          val instSizeList = map (compileExp env) instSizeList
        in
          compilePrim (primitive, ty, instTyList, instTagList, instSizeList,
                       argTyList, resultTy, argExpList, loc)
        end
      | C.CCCALL {codeExp, closureEnvExp, argExpList,
                  cconv = C.STATICCALL cconv, funTy, loc} =>
        let
          val codeExp = compileExp env codeExp
          val closureEnvExp = compileExp env closureEnvExp
          val argExpList = map (compileExp env) argExpList
          val calleeConv = compileConvention cconv
          val callerConv = funTyToConvention btvEnv funTy
        in
          staticCall {calleeConv = calleeConv,
                      callerConv = callerConv,
                      codeExp = codeExp,
                      closureEnvExp = if #haveClsEnv cconv
                                      then SOME closureEnvExp else NONE,
                      argExpList = argExpList,
                      loc = loc}
        end
      | C.CCCALL {codeExp, closureEnvExp, argExpList,
                  cconv = C.DYNAMICCALL {cconvTag, wrapper}, funTy, loc} =>
        let
          val codeExp = compileExp env codeExp
          val closureEnvExp = compileExp env closureEnvExp
          val argExpList = map (compileExp env) argExpList
          val cconvTag = compileExp env cconvTag
          val wrapper = compileExp env wrapper
          val callerConv = funTyToConvention btvEnv funTy
        in
          dynamicCall {callerConv = callerConv,
                       cconvTag = cconvTag,
                       wrapper = wrapper,
                       codeExp = codeExp,
                       closureEnvExp = closureEnvExp,
                       argExpList = argExpList,
                       loc = loc}
        end
      | C.CCLET {boundVar, boundExp, mainExp, loc} =>
        N.NCLET {boundVar = compileVarInfo btvEnv boundVar,
                 boundExp = compileExp env boundExp,
                 mainExp = compileExp env mainExp,
                 loc = loc}
      | C.CCRECORD {fieldList, recordTy, isMutable, clearPad, allocSizeExp,
                    bitmaps, loc} =>
        let
          val (letFns, fieldList) =
              ListPair.unzip
                (map (fn {fieldExp, fieldTy, fieldLabel, fieldSize, fieldTag,
                          fieldIndex} =>
                         let
                           val fieldTy = compileTy btvEnv fieldTy
                           val fieldIndex = compileExp env fieldIndex
                           val (letFn, fieldExp) =
                               compileRecordField env {fieldExp = fieldExp,
                                                       fieldTy = fieldTy,
                                                       fieldSize = fieldSize,
                                                       fieldTag = fieldTag,
                                                       loc = loc}
                         in
                           (letFn,
                            {fieldExp = fieldExp,
                             fieldTy = fieldTy,
                             fieldIndex = fieldIndex})
                         end)
                     fieldList)
          val bitmaps =
              map (fn {bitmapIndex, bitmapExp} =>
                      {bitmapIndex = compileExp env bitmapIndex,
                       bitmapExp = compileExp env bitmapExp})
                  bitmaps
        in
          foldr
            (fn (letFn, z) => letFn z)
            (N.NCRECORD {fieldList = fieldList,
                         recordTy = compileTy btvEnv recordTy,
                         isMutable = isMutable,
                         clearPad = clearPad,
                         allocSizeExp = compileExp env allocSizeExp,
                         bitmaps = bitmaps,
                         loc = loc})
            letFns
        end
      | C.CCSELECT {recordExp, indexExp, label, recordTy, resultTy,
                    resultSize, resultTag, loc} =>
        let
          val recordExp = compileExp env recordExp
          val indexExp = compileExp env indexExp
          val recordTy = compileTy btvEnv recordTy
          val resultTy = compileTy btvEnv resultTy
          val resultSize = compileExp env resultSize
          val resultTag = compileExp env resultTag
          val (recordLet, recordVar) = makeBind (recordExp, recordTy, loc)
          val (indexLet, indexVar) =
              makeBind (indexExp, indexTy (label, #1 recordTy), loc)
          val addr = N.NARECORDFIELD {recordExp = recordVar,
                                      fieldIndex = indexVar}
          val loadExp = N.NCLOAD {srcAddr = addr,
                                  resultTy = resultTy,
                                  loc = loc}
        in
          (recordLet o indexLet)
            (if isBoxedKind resultTy
             then switchByTag
                    {tagExp = resultTag,
                     valueTy = #1 resultTy,
                     ifBoxedTag = loadExp,
                     ifUnboxedTag = N.NCDUP {srcAddr = addr,
                                             resultTy = resultTy,
                                             valueSize = resultSize,
                                             loc = loc},
                     resultTy = resultTy,
                     loc = loc}
             else loadExp)
        end
      | C.CCMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    valueTag, valueSize, loc} =>
        let
          val recordExp = compileExp env recordExp
          val recordTy = compileTy btvEnv recordTy
          val indexExp = compileExp env indexExp
          val valueTy = compileTy btvEnv valueTy
          val (letFn, valueExp) =
              compileRecordField env {fieldExp = valueExp,
                                      fieldTy = valueTy,
                                      fieldTag = valueTag,
                                      fieldSize = valueSize,
                                      loc = loc}
        in
          letFn
            (N.NCMODIFY
               {recordExp = recordExp,
                recordTy = recordTy,
                indexExp = indexExp,
                valueExp = valueExp,
                valueTy = valueTy,
                loc = loc})
        end
      | C.CCRAISE {argExp, resultTy, loc} =>
        N.NCRAISE {argExp = compileExp env argExp,
                   resultTy = compileTy btvEnv resultTy,
                   loc = loc}
      | C.CCHANDLE {tryExp, exnVar, handlerExp, resultTy, loc} =>
        N.NCHANDLE {tryExp = compileExp env tryExp,
                    exnVar = compileVarInfo btvEnv exnVar,
                    handlerExp = compileExp env handlerExp,
                    resultTy = compileTy btvEnv resultTy,
                    loc = loc}
      | C.CCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        N.NCSWITCH {switchExp = compileExp env switchExp,
                    expTy = compileTy btvEnv expTy,
                    branches = map (fn {constant, branchExp} =>
                                       {constant = compileConst env constant,
                                        branchExp = compileExp env branchExp})
                                   branches,
                    defaultExp = compileExp env defaultExp,
                    resultTy = compileTy btvEnv resultTy,
                    loc = loc}
      | C.CCLOCALCODE {codeLabel, argVarList, codeBodyExp, mainExp, resultTy,
                       loc} =>
        N.NCLOCALCODE {codeLabel = codeLabel,
                       argVarList = map (compileVarInfo btvEnv) argVarList,
                       codeBodyExp = compileExp env codeBodyExp,
                       mainExp = compileExp env mainExp,
                       resultTy = compileTy btvEnv resultTy,
                       loc = loc}
      | C.CCGOTO {destinationLabel, argExpList, resultTy, loc} =>
        N.NCGOTO {destinationLabel = destinationLabel,
                  argExpList = map (compileExp env) argExpList,
                  resultTy = compileTy btvEnv resultTy,
                  loc = loc}
      | C.CCCAST {exp, expTy, targetTy, runtimeTyCast, bitCast, loc} =>
        let
          val expTy as (_, expRty) = compileTy btvEnv expTy
          val targetTy as (_, targetRty) = compileTy btvEnv targetTy
        in
          if runtimeTyCast then ()
          else if expRty = targetRty then ()
          else raise Bug.Bug ("compileExp: CCCAST "
                              ^ rtyToString expTy
                              ^ " -> "
                              ^ rtyToString targetTy);
          if bitCast andalso expRty = targetRty
          then raise Bug.Bug ("compileExp: CCCAST bitcast "
                              ^ rtyToString expTy
                              ^ " -> "
                              ^ rtyToString targetTy)
          else ();
          N.NCCAST {exp = compileExp env exp,
                    expTy = expTy,
                    targetTy = targetTy,
                    runtimeTyCast = runtimeTyCast,
                    bitCast = bitCast,
                    loc = loc}
        end
      | C.CCEXPORTVAR {id, ty, valueExp, loc} =>
        (* ty is not a type variable. we can always produce a static store
         * instruction. *)
        N.NCEXPORTVAR {id = id,
                       ty = compileTy btvEnv ty,
                       valueExp = compileExp env valueExp,
                       loc = loc}

  and compileRecordField env {fieldExp, fieldTy, fieldSize, fieldTag, loc} =
      let
        val fieldExp = compileExp env fieldExp
        val fieldSize = compileExp env fieldSize
        val fieldTag = compileExp env fieldTag
        val (expLet, expVar) = makeLet (fieldExp, fieldTy, loc)
        val (sizeLet, sizeVar) = makeLet (fieldSize, sizeTy (#1 fieldTy), loc)
        val (tagLet, tagVar) = makeLet (fieldTag, tagTy (#1 fieldTy), loc)
      in
        if not (isBoxedKind fieldTy)
        then (expLet, N.INIT_VALUE expVar)
        else
          case evalConstTag fieldTag of
            SOME R.TAG_BOXED =>
            (expLet, N.INIT_VALUE expVar)
          | SOME R.TAG_UNBOXED =>
            (expLet o sizeLet,
             N.INIT_COPY {srcExp = expVar, fieldSize = sizeVar})
          | NONE =>
            (expLet o sizeLet o tagLet,
             N.INIT_IF {tagExp = tagVar,
                        tagOfTy = #1 (tagTy (#1 fieldTy)),
                        ifBoxed = N.INIT_VALUE expVar,
                        ifUnboxed = N.INIT_COPY {srcExp = expVar,
                                                 fieldSize = sizeVar}})
      end

  fun generateWrapper topdec =
      case topdec of
        C.CTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              bodyExp, attributes, retTy, loc} =>
        (nil, FunEntryLabel.Map.empty)
      | C.CTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
                      retTy, loc} =>
        let
          val cconv =
              compileConvention {tyvars = tyvarKindEnv,
                                 haveClsEnv = isSome closureEnvVar,
                                 argTyList = map #ty argVarList,
                                 retTy = SOME retTy}
        in
          if isWrapperConvention cconv
          then (nil, FunEntryLabel.Map.singleton (id, id))
          else
            let
              val wrapperId = FunEntryLabel.derive id
              val wrapperCconv = toWrapperConvention cconv
              val argVars = map newVar (#argTyList wrapperCconv)
              val closureEnvVar =
                  Option.map (compileVarInfo tyvarKindEnv) closureEnvVar
              val bodyExp =
                  staticCall
                    {calleeConv = cconv,
                     callerConv = wrapperCconv,
                     codeExp = funEntryExp (id, cconv, isSome closureEnvVar,
                                            loc),
                     closureEnvExp =
                       case closureEnvVar of
                         SOME v => SOME (N.NCVAR {varInfo=v, loc=loc})
                       | NONE => NONE,
                     argExpList =
                       map (fn v => N.NCVAR {varInfo=v, loc=loc}) argVars,
                     loc = loc}
            in
              ([N.NTFUNCTION {id = wrapperId,
                              tyvarKindEnv = tyvarKindEnv,
                              argVarList = argVars,
                              closureEnvVar = closureEnvVar,
                              bodyExp = bodyExp,
                              retTy = #retTy wrapperCconv,
                              loc = loc}],
               FunEntryLabel.Map.singleton (id, wrapperId))
            end
        end

  fun generateWrappers nil = (nil, FunEntryLabel.Map.empty)
    | generateWrappers (topdec::topdecs) =
      let
        val (decs1, wrapperMap1) = generateWrapper topdec
        val (decs2, wrapperMap2) = generateWrappers topdecs
      in
        (decs1 @ decs2,
         FunEntryLabel.Map.unionWith
           (fn _ => raise Bug.Bug "generateWrappers")
           (wrapperMap1, wrapperMap2))
      end

  fun compileTopdec wrapperMap topdec =
      case topdec of
        C.CTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
                      retTy, loc} =>
        let
          val env = {btvEnv = tyvarKindEnv, wrapperMap = wrapperMap} : env
        in
          N.NTFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             argVarList = map (compileVarInfo tyvarKindEnv) argVarList,
             closureEnvVar =
               Option.map (compileVarInfo tyvarKindEnv) closureEnvVar,
             bodyExp = compileExp env bodyExp,
             retTy = compileTy tyvarKindEnv retTy,
             loc = loc}
        end
      | C.CTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              bodyExp, attributes, retTy, loc} =>
        let
          val env = {btvEnv = tyvarKindEnv, wrapperMap = wrapperMap} : env
        in
          N.NTCALLBACKFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             argVarList = map (compileVarInfo tyvarKindEnv) argVarList,
             closureEnvVar =
               Option.map (compileVarInfo tyvarKindEnv) closureEnvVar,
             bodyExp = compileExp env bodyExp,
             attributes = attributes,
             retTy = Option.map (compileTy tyvarKindEnv) retTy,
             loc = loc}
        end

  fun compileTopdata wrapperMap topdata =
      case topdata of
        C.CTEXTERNVAR {id, ty, loc} =>
        N.NTEXTERNVAR {id = id, ty = compileTy emptyBtvEnv ty, loc = loc}
      | C.CTEXPORTVAR {id, ty, value, loc} =>
        let
          val env = {btvEnv = emptyBtvEnv, wrapperMap = wrapperMap}
        in
          N.NTEXPORTVAR {id = id, ty = compileTy emptyBtvEnv ty,
                         value = Option.map (compileTopConst env) value,
                         loc = loc}
        end
      | C.CTSTRING {id, string, loc} =>
        N.NTSTRING {id = id, string = string, loc = loc}
      | C.CTLARGEINT {id, value, loc} =>
        N.NTLARGEINT {id = id, value = value, loc = loc}
      | C.CTRECORD {id, tyvarKindEnv, fieldList, recordTy, isMutable, clearPad,
                    bitmaps, loc} =>
        let
          val env = {btvEnv = tyvarKindEnv, wrapperMap = wrapperMap}
        in
          N.NTRECORD
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             fieldList =
               map (fn {fieldExp, fieldTy, fieldLabel,
                        fieldSize, fieldIndex} =>
                       {fieldExp = compileTopConst env fieldExp,
                        fieldSize = compileTopConst env fieldSize,
                        fieldIndex = compileTopConst env fieldIndex})
                   fieldList,
             recordTy = recordTy,
             isMutable = isMutable,
             clearPad = clearPad,
             bitmaps =
               map (fn {bitmapIndex, bitmapExp} =>
                       {bitmapIndex = compileTopConst env bitmapIndex,
                        bitmapExp = compileTopConst env bitmapExp})
                   bitmaps,
             loc = loc}
        end
      | C.CTARRAY {id, elemTy, isMutable, clearPad, numElements,
                   initialElements, elemSizeExp, tagExp, loc} =>
        let
          val env = {btvEnv = emptyBtvEnv, wrapperMap = wrapperMap}
        in
          N.NTARRAY
            {id = id,
             elemTy = compileTy emptyBtvEnv elemTy,
             isMutable = isMutable,
             clearPad = clearPad,
             numElements = compileTopConst env numElements,
             initialElements = map (compileTopConst env) initialElements,
             elemSizeExp = compileTopConst env elemSizeExp,
             tagExp = compileTopConst env tagExp,
             loc = loc}
        end

  fun compile ({topdata, topdecs, topExp}:C.program) =
      let
        val (topdecs2, wrapperMap) = generateWrappers topdecs
        val topdata = map (compileTopdata wrapperMap) topdata
        val topdecs1 = map (compileTopdec wrapperMap) topdecs
        val env = {btvEnv = emptyBtvEnv, wrapperMap = wrapperMap}
        val topExp = compileExp env topExp
      in
        {topdata = topdata,
         topdecs = topdecs1 @ topdecs2,
         topExp = topExp}
      end

end
