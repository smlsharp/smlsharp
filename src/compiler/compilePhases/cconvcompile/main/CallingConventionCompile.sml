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
  (* structure RC = RecordCalc *)
  structure P = BuiltinPrimitive

  fun tyToString ty = Bug.prettyPrint (T.format_ty ty)
  fun rtyToString ty = Bug.prettyPrint (N.formatWithType_ty ty)

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
      case TypeLayout2.propertyOf btvEnv ty of
        SOME {size = R.SIZE s, tag = R.TAG t, rep = r} =>
        SOME {size = s, tag = t, rep = r}
      | SOME _ => NONE
      | NONE => raise Bug.Bug ("runtimeTy " ^ tyToString ty)

  val genericTy = R.boxedTy

  fun compileTy btvEnv ty =
      case runtimeTy btvEnv ty of
        SOME rty => (ty, rty) : N.ty
      | (* all type variables have R.BOXEDty runtime kind *)
        NONE => (ty, genericTy)

  fun toGenericArgTy (ty, {tag, size, rep} : R.ty) =
      (ty, {tag = tag, size = size, rep = R.BINARY})

  fun coerceArg exp expTy toTy loc =
      if #2 expTy = #2 toTy
      then exp
      else N.NCCAST
             {exp = exp,
              expTy = expTy,
              targetTy = toTy,
              cast = BuiltinPrimitive.BitCast,
              loc = loc}

  type cconv =
       {tyvars : T.btvEnv,
        haveClsEnv : bool,
        argTyList : N.ty list,
        retTy : N.ty,
        (* returns true if any type instantiation does not affect calling
         * convention *)
        isRigid : bool,
        actualArgTyList : N.ty list,
        actualRetTy : N.ty}
(*
  fun compileVarInfo btvEnv ({path, id, ty}:RC.varInfo) =
      {path = path, id = id, ty = compileTy btvEnv ty} : N.varInfo
*)

  fun compileConvention ({tyvars, haveClsEnv, argTyList, retTy}:T.codeEntryTy) =
      let
        val isRigid =
            List.all (fn ty => isSome (runtimeTy tyvars ty)) argTyList
            andalso isSome (runtimeTy tyvars retTy)
        val actualArgTyList = map (compileTy tyvars) argTyList
        val argTyList = map toGenericArgTy actualArgTyList
        val actualRetTy = compileTy tyvars retTy
        val retTy = actualRetTy
      in
        {tyvars = tyvars,
         haveClsEnv = haveClsEnv,
         argTyList = argTyList,
         retTy = retTy,
         isRigid = isRigid,
         actualArgTyList = actualArgTyList,
         actualRetTy = actualRetTy} : cconv
      end

  fun funTyToConvention btvEnv funTy =
      case TypesBasics.derefTy funTy of
        T.FUNMty (argTys, retTy) =>
        compileConvention {tyvars = btvEnv,
                           haveClsEnv = true,  (* dummy *)
                           argTyList = argTys,
                           retTy = retTy}
      | _ => raise Bug.Bug "funTyToConvention"

  fun isWrapperConvention ({argTyList, retTy, haveClsEnv, ...}:cconv) =
      haveClsEnv andalso
      List.all (fn (_, {tag=R.BOXED,...}) => true | (_, _) => false)
               (retTy :: argTyList)

  fun toWrapperConvention ({tyvars, argTyList, retTy, haveClsEnv,
                            isRigid, actualArgTyList, actualRetTy}:cconv) =
      {tyvars = tyvars,
       haveClsEnv = true,
       argTyList = map (fn (ty, _) => (ty, genericTy)) argTyList,
       retTy = (#1 retTy, genericTy),
       isRigid = true,
       actualArgTyList = map (fn (ty, _) => (ty, genericTy)) actualArgTyList,
       actualRetTy = (#1 actualRetTy, genericTy)}
      : cconv

  fun funEntryTy ({tyvars, argTyList, retTy, haveClsEnv, ...}:cconv) =
      (T.BACKENDty (T.FUNENTRYty {tyvars = tyvars,
                                  haveClsEnv = haveClsEnv,
                                  argTyList = map #1 argTyList,
                                  retTy = #1 retTy}),
       R.codeptrTy
       # {rep = R.CODEPTR (R.FN {haveClsEnv = haveClsEnv,
                                 argTys = map #2 argTyList,
                                 retTy = #2 retTy})})
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

  fun natural ty =
      case TypeLayout2.propertyOf BoundTypeVarID.Map.empty ty of
        SOME (prop as {size = R.SIZE s, tag = R.TAG t, rep = r}) =>
        (ty, {size = s, tag = t, rep = r})
      | _ => raise Bug.Bug "natural"

  fun unitTy () = natural BuiltinTypes.unitTy
  fun int32Ty () = natural BuiltinTypes.int32Ty
  fun word32Ty () = natural BuiltinTypes.word32Ty
  fun boxedTy () = natural BuiltinTypes.boxedTy
  fun boolTy () = natural BuiltinTypes.boolTy
  fun contagTy () = natural BuiltinTypes.contagTy
  fun someFunWrapperTy () = natural (T.BACKENDty T.SOME_FUNWRAPPERty)
  fun someFunEntryTy () = natural (T.BACKENDty T.SOME_FUNENTRYty)
  fun someClosureEnvTy () = natural (T.BACKENDty T.SOME_CLOSUREENVty)
  fun someCconvtagTy () = natural (T.BACKENDty T.SOME_CCONVTAGty)
  fun cconvtagTy ty = natural (T.BACKENDty (T.CCONVTAGty ty))
  fun tagTy ty = natural (T.SINGLETONty (T.TAGty ty))
  fun sizeTy ty = natural (T.SINGLETONty (T.SIZEty ty))
  fun indexTy x = natural (T.SINGLETONty (T.INDEXty x))
  fun refTy ty =
      natural (T.CONSTRUCTty {tyCon = BuiltinTypes.refTyCon, args = [ty]})
  fun arrayTy ty =
      natural (T.CONSTRUCTty {tyCon = BuiltinTypes.arrayTyCon, args = [ty]})
  fun ptrTy ty =
      natural (T.CONSTRUCTty {tyCon = BuiltinTypes.ptrTyCon, args = [ty]})
  fun intConst n loc =
      N.NCCONST {const = N.NVINT32 n, ty = int32Ty (), loc = loc}

  fun isBoxedKind ((_, {tag=R.BOXED,...}):N.ty) = true
    | isBoxedKind _ = false

  fun evalConstTag tagExp =
      case tagExp of
        N.NCCONST {const = N.NVTAG {tag, ...}, ...} => SOME tag
      | _ => NONE

  fun switchByTag {tagExp, valueTy, ifBoxedTag, ifUnboxedTag, resultTy, loc} =
      case evalConstTag tagExp of
        SOME RuntimeTypes.UNBOXED => ifUnboxedTag
      | SOME RuntimeTypes.BOXED => ifBoxedTag
      | NONE =>
        N.NCSWITCH
          {switchExp = tagExp,
           expTy = tagTy valueTy,
           branches = [{constant = N.NVTAG {tag=RuntimeTypes.UNBOXED,
                                            ty=valueTy},
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
                                    targetTy = boxedTy (),
                                    cast = BuiltinPrimitive.TypeCast,
                                    loc = loc},
                          N.NCCONST {const = N.NVNULLBOXED,
                                     ty = boxedTy (),
                                     loc = loc}],
                       argTyList = [boxedTy (), boxedTy ()],
                       resultTy = boolTy (),
                       instTyList = nil,
                       instTagList = nil,
                       instSizeList = nil,
                       loc = loc},
              expTy = boolTy (),
              targetTy = contagTy (),
              cast = BuiltinPrimitive.TypeCast,
              loc = loc},
         expTy = contagTy (),
         branches = [{constant = N.NVCONTAG 0w0, branchExp = elseExp}],
         defaultExp = thenExp,
         resultTy = resultTy,
         loc = loc}

  fun funEntryExp (id, cconv, loc) =
      N.NCCONST {const = N.NVFUNENTRY id,
                 ty = funEntryTy cconv,
                 loc = loc}

  fun cconvTagConstWord ({isRigid, ...}:cconv) =
      N.NVWORD32 (if isRigid then 0wx80000000 else 0w0)

  fun IfRigidCconvTag {cconvTagExp, ifRigid, ifNotRigid, resultTy, loc} =
      N.NCSWITCH
        {switchExp = N.NCCAST {exp = cconvTagExp,
                               expTy = someCconvtagTy (),
                               targetTy = word32Ty (),
                               cast = BuiltinPrimitive.TypeCast,
                               loc = loc},
         expTy = word32Ty (),
         branches = [{constant = N.NVWORD32 0w0, branchExp = ifNotRigid}],
         defaultExp = ifRigid,
         resultTy = resultTy,
         loc = loc}

  fun staticCall {calleeConv : cconv, callerConv : cconv,
                  codeExp, closureEnvExp, argExpList, loc} =
      let
(*
val _ = (
print "==\n";
print (Bug.prettyPrint (N.format_ncexp codeExp) ^ "\n");
print "caller:\n";
app (fn t => print (Bug.prettyPrint (N.format_ty t) ^ ",")) (#argTyList callerConv);
print "\n";
print (Bug.prettyPrint (N.format_ty (#retTy callerConv)));
print "\ncallee:\n";
app (fn t => print (Bug.prettyPrint (N.format_ty t) ^ ",")) (#argTyList calleeConv);
print "\n";
print (Bug.prettyPrint (N.format_ty (#retTy calleeConv)));
print "\n==\n"
)
*)
        fun convert ((fromTy, toTy), exp) =
            case (#tag (#2 fromTy), #tag (#2 toTy)) of
              (R.BOXED, R.BOXED) => exp
            | (R.BOXED, R.UNBOXED) =>
              N.NCUNPACK {exp = exp, resultTy = toTy, loc = loc}
            | (R.UNBOXED, R.BOXED) =>
              N.NCPACK {exp = exp, expTy = fromTy, loc = loc}
            | (R.UNBOXED, R.UNBOXED) =>
              if #2 fromTy = #2 toTy
              then exp
              else N.NCCAST {exp = exp,
                             expTy = fromTy,
                             targetTy = toTy,
                             cast = BuiltinPrimitive.BitCast,
                             loc = loc}
        val argExpList =
            ListPair.mapEq convert
                           (ListPair.zipEq (#actualArgTyList callerConv,
                                            #argTyList callerConv),
                            argExpList)
        val argExpList =
            ListPair.mapEq convert
                           (ListPair.zipEq (#argTyList callerConv,
                                            #argTyList calleeConv),
                            argExpList)
        val closureEnvExp =
            if #haveClsEnv calleeConv
            then SOME closureEnvExp
            else NONE
        val callExp =
            N.NCCALL {codeExp = codeExp,
                      closureEnvExp = closureEnvExp,
                      argExpList = argExpList,
                      resultTy = #retTy calleeConv,
                      loc = loc}
        val callExp =
            convert ((#retTy calleeConv, #retTy callerConv), callExp)
        val callExp =
            convert ((#retTy callerConv, #actualRetTy callerConv), callExp)
      in
        callExp
      end

  fun dynamicCall {cconvTag, wrapper, codeExp, closureEnvExp,
                   argExpList, callerConv, loc} =
      let
        val (letFn1, codeExp) = makeBind (codeExp, someFunEntryTy (), loc)
        val (letFn2, wrapperExp) = makeBind (wrapper, someFunWrapperTy (), loc)
        val (letFn3, closureEnvExp) =
            makeBind (closureEnvExp, someClosureEnvTy (), loc)
        val (letFn4, argExpList) =
            makeBindList (argExpList, #actualArgTyList callerConv, loc)
        val funEntry = (codeExp, someFunEntryTy ())
        val wrapper = (wrapperExp, someFunWrapperTy ())
        fun call (calleeConv, (codeExp, codeExpTy)) =
            staticCall
              {calleeConv = calleeConv,
               callerConv = callerConv,
               codeExp = N.NCCAST
                           {exp = codeExp,
                            expTy = codeExpTy,
                            targetTy = funEntryTy calleeConv,
                            cast = BuiltinPrimitive.BitCast,
                            loc = loc},
               closureEnvExp = closureEnvExp,
               argExpList = argExpList,
               loc = loc}
        fun callBranch (calleeConv, codeEntry) =
            IfNull
              {exp = closureEnvExp,
               expTy = someClosureEnvTy (),
               thenExp = call (calleeConv # {haveClsEnv = false}, codeEntry),
               elseExp = call (calleeConv # {haveClsEnv = true}, codeEntry),
               resultTy = #actualRetTy callerConv,
               loc = loc}
        val callExp =
            if isWrapperConvention callerConv
            then call (callerConv, wrapper)
            else if not (#isRigid callerConv)
            then call (toWrapperConvention callerConv, wrapper)
            else if !Control.branchByCConvRigidity
            then IfRigidCconvTag
                   {cconvTagExp = cconvTag,
                    ifRigid = callBranch (callerConv, funEntry),
                    ifNotRigid = call (toWrapperConvention callerConv, wrapper),
                    resultTy = #actualRetTy callerConv,
                    loc = loc}
            else call (toWrapperConvention callerConv, wrapper)
      in
        (letFn1 o letFn2 o letFn3 o letFn4) callExp
      end

  fun compileVarInfo btvEnv ({path, id, ty}:RecordCalc.varInfo) =
      {id = id, ty = compileTy btvEnv ty} : N.varInfo

  fun compileConst (env as {btvEnv, wrapperMap}:env) ccvalue =
      case ccvalue of
        C.CVINT8 x => N.NVINT8 x
      | C.CVINT16 x => N.NVINT16 x
      | C.CVINT32 x => N.NVINT32 x
      | C.CVINT64 x => N.NVINT64 x
      | C.CVEXTRADATA x => N.NVEXTRADATA x
      | C.CVWORD8 x => N.NVWORD8 x
      | C.CVWORD16 x => N.NVWORD16 x
      | C.CVWORD32 x => N.NVWORD32 x
      | C.CVWORD64 x => N.NVWORD64 x
      | C.CVCONTAG x => N.NVCONTAG x
      | C.CVREAL64 x => N.NVREAL64 x
      | C.CVREAL32 x => N.NVREAL32 x
      | C.CVCHAR x => N.NVCHAR x
      | C.CVUNIT => N.NVUNIT
      | C.CVNULLPOINTER => N.NVNULLPOINTER
      | C.CVNULLBOXED => N.NVNULLBOXED
      | C.CVTAG x => N.NVTAG x
      | C.CVSIZE x => N.NVSIZE x
      | C.CVINDEX x => N.NVINDEX x
      | C.CVFOREIGNSYMBOL {name, ty} =>
        N.NVFOREIGNSYMBOL {name = name, ty = compileTy btvEnv ty}
      | C.CVFUNENTRY {id, codeEntryTy} =>
        N.NVFUNENTRY id
      | C.CVFUNWRAPPER {id, codeEntryTy} =>
        let
          val cconv = toWrapperConvention (compileConvention codeEntryTy)
          val ty = funEntryTy cconv
        in
          case FunEntryLabel.Map.find (wrapperMap, id) of
            SOME id =>
            N.NVCAST {value = N.NVFUNENTRY id,
                      valueTy = ty,
                      targetTy = someFunWrapperTy (),
                      cast = BuiltinPrimitive.BitCast}
         | NONE => raise Bug.Bug "compileConst: CVFUNWRAPPER"
        end
      | C.CVCALLBACKENTRY {id, callbackEntryTy} =>
        N.NVCALLBACKENTRY id
      | C.CVEXFUNENTRY {id, codeEntryTy} =>
        N.NVEXFUNENTRY id
      | C.CVTOPDATA {id, ty} =>
        N.NVTOPDATA id
      | C.CVCAST {value, valueTy, targetTy, cast} =>
        N.NVCAST {value = compileConst env value,
                  valueTy = compileTy btvEnv valueTy,
                  targetTy = compileTy btvEnv targetTy,
                  cast = cast}
      | C.CVCCONVTAG ty =>
        N.NVCAST
          {value = cconvTagConstWord (compileConvention ty),
           valueTy = word32Ty (),
           targetTy = cconvtagTy ty,
           cast = BuiltinPrimitive.TypeCast}
      | C.CVWORD32_ORB (c1, c2) =>
        N.NVWORD32 (Word32.orb (constToWord (compileConst env c1),
                                constToWord (compileConst env c2)))

  and constToWord (N.NVWORD32 w) = w
    | constToWord (N.NVCAST {value, ...}) = constToWord value
    | constToWord _ = raise Bug.Bug "constToWord"

  fun compileTopConst env (const, ty) =
      (compileConst env const, compileTy (#btvEnv env) ty)

  fun load {srcAddr, resultTy, valueSize, valueTag, loc} =
      let
        val loadExp =
            N.NCLOAD {srcAddr = srcAddr, resultTy = resultTy, loc = loc}
      in
        if isBoxedKind resultTy
        then switchByTag
               {tagExp = valueTag,
                valueTy = #1 resultTy,
                ifBoxedTag = loadExp,
                ifUnboxedTag = N.NCDUP {srcAddr = srcAddr,
                                        resultTy = resultTy,
                                        valueSize = valueSize,
                                        loc = loc},
                resultTy = resultTy,
                loc = loc}
        else loadExp
      end

  fun store {dstAddr, valueExp, valueTy, valueSize, valueTag, loc} =
      let
        val storeExp = N.NCSTORE {srcExp = valueExp,
                                  srcTy = valueTy,
                                  dstAddr = dstAddr,
                                  loc = loc}
      in
        if isBoxedKind valueTy
        then switchByTag
               {tagExp = valueTag,
                valueTy = #1 valueTy,
                ifBoxedTag = storeExp,
                ifUnboxedTag = N.NCCOPY {srcExp = valueExp,
                                         valueSize = valueSize,
                                         dstAddr = dstAddr,
                                         loc = loc},
                resultTy = unitTy (),
                loc = loc}
        else storeExp
      end

  fun polyPrimInfo (prim, argTyFn, retTyFn) =
      let
        val t = BoundTypeVarID.generate ()
        val btvTy = T.BOUNDVARty t
        val univKind = #kind T.univKind
      in
        {primitive = prim,
         ty = {boundtvars = BoundTypeVarID.Map.singleton (t, univKind),
               argTyList = argTyFn btvTy,
               resultTy = retTyFn btvTy}}
        : N.primInfo
      end
      
  fun allocArrayWithInit {allocPrim, resultTy, elemTag, elemSize, elemTy,
                          elemExps, loc} =
      let
        val numElems = length elemExps
        val primInfo =
            polyPrimInfo (allocPrim,
                          fn _ => [BuiltinTypes.int32Ty],
                          fn t => #1 (arrayTy t))
        val allocExp =
            N.NCPRIMAPPLY
              {primInfo = primInfo,
               argExpList = [intConst numElems loc],
               argTyList = [int32Ty ()],
               resultTy = resultTy,
               instTyList = [elemTy],
               instTagList = [elemTag],
               instSizeList = [elemSize],
               loc = loc}
        val (arrayLet, arrayVar) = makeBind (allocExp, resultTy, loc)
        val addrs =
            List.tabulate (numElems,
                           fn i => N.NAARRAYELEM {arrayExp = arrayVar,
                                                  elemSize = elemSize,
                                                  elemIndex = intConst i loc})
        val storeExps =
            ListPair.mapEq (fn (addr, elem) =>
                               N.NCSTORE {srcExp = elem,
                                          srcTy = elemTy,
                                          dstAddr = addr,
                                          loc = loc})
                           (addrs, elemExps)
        val copyExps =
            ListPair.mapEq (fn (addr, elem) =>
                               N.NCCOPY {srcExp = elem,
                                         valueSize = elemSize,
                                         dstAddr = addr,
                                         loc = loc})
                           (addrs, elemExps)
        fun seqExp exps =
            #1 (makeBindList (exps, map (fn _ => unitTy ()) exps, loc))
      in
        if isBoxedKind elemTy
        then arrayLet
               (switchByTag {tagExp = elemTag,
                             valueTy = #1 elemTy,
                             ifBoxedTag = (seqExp storeExps) arrayVar,
                             ifUnboxedTag = (seqExp copyExps) arrayVar,
                             resultTy = resultTy,
                             loc = loc})
        else (arrayLet o seqExp storeExps) arrayVar
      end

  fun compilePrim (primitive, primTy, instTyList, instTagList, instSizeList,
                   argTyList, resultTy, argExpList, loc) =
      case (primitive, instTyList, instTagList, instSizeList, argExpList) of
        (P.Ptr_deref, [ty], [tag], [size], [ptr]) =>
        let
          val (ptrLet, ptrVar) = makeBind (ptr, ptrTy (#1 ty), loc)
          val (sizeLet, sizeVar) = makeBind (size, sizeTy (#1 ty), loc)
        in
          (ptrLet o sizeLet)
            (load {srcAddr = N.NAPTR ptrVar,
                   resultTy = ty,
                   valueSize = sizeVar,
                   valueTag = tag,
                   loc = loc})
        end
      | (P.Ptr_deref, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_deref"

      | (P.Ptr_store, [ty], [tag], [size], [ptr, value]) =>
        let
          val (ptrLet, ptrVar) = makeBind (ptr, ptrTy (#1 ty), loc)
          val (valueLet, valueVar) = makeBind (value, ty, loc)
          val (sizeLet, sizeVar) = makeBind (size, sizeTy (#1 ty), loc)
        in
          (ptrLet o valueLet o sizeLet)
            (store {dstAddr = N.NAPTR ptrVar,
                    valueExp = valueVar,
                    valueTy = ty,
                    valueSize = sizeVar,
                    valueTag = tag,
                    loc = loc})
        end
      | (P.Ptr_store, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_store"

      | (P.Array_sub_unsafe, [ty], [tag], [size], [arrayExp, indexExp]) =>
        let
          val (arrayLet, arrayVar) = makeBind (arrayExp, arrayTy (#1 ty), loc)
          val (indexLet, indexVar) = makeBind (indexExp, int32Ty (), loc)
          val (sizeLet, sizeVar) = makeBind (size, sizeTy (#1 ty), loc)
        in
          (arrayLet o indexLet o sizeLet)
            (load {srcAddr = N.NAARRAYELEM {arrayExp = arrayVar,
                                            elemSize = sizeVar,
                                            elemIndex = indexVar},
                   resultTy = ty,
                   valueSize = sizeVar,
                   valueTag = tag,
                   loc = loc})
        end
      | (P.Array_sub_unsafe, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_sub"

      | (P.Array_update_unsafe, [ty], [tag], [size],
         [arrayExp, indexExp, argExp]) =>
        let
          val (arrayLet, arrayVar) = makeBind (arrayExp, arrayTy (#1 ty), loc)
          val (indexLet, indexVar) = makeBind (indexExp, int32Ty (), loc)
          val (argLet, argVar) = makeBind (argExp, ty, loc)
          val (sizeLet, sizeVar) = makeBind (size, sizeTy (#1 ty), loc)
        in
          (arrayLet o indexLet o argLet o sizeLet)
            (store {dstAddr = N.NAARRAYELEM {arrayExp = arrayVar,
                                             elemSize = sizeVar,
                                             elemIndex = indexVar},
                    valueExp = argVar,
                    valueTy = ty,
                    valueTag = tag,
                    valueSize = sizeVar,
                    loc = loc})
        end
      | (P.Array_update_unsafe, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_update_unsafe"

      | (P.Array_alloc_init, [elemTy], [tag], [size], elems) =>
        allocArrayWithInit
          {allocPrim = P.Array_alloc_unsafe,
           resultTy = resultTy,
           elemTag = tag,
           elemSize = size,
           elemTy = elemTy,
           elemExps = elems,
           loc = loc}
      | (P.Array_alloc_init, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_alloc_init"

      | (P.Vector_alloc_init, [elemTy], [tag], [size], elems) =>
        allocArrayWithInit
          {allocPrim = P.Vector_alloc_unsafe,
           resultTy = resultTy,
           elemTag = tag,
           elemSize = size,
           elemTy = elemTy,
           elemExps = elems,
           loc = loc}
      | (P.Vector_alloc_init, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Vector_alloc_init"

      | (P.Vector_alloc_init_fresh, [elemTy], [tag], [size], elems) =>
        allocArrayWithInit
          {allocPrim = P.Vector_alloc_unsafe,
           resultTy = resultTy,
           elemTag = tag,
           elemSize = size,
           elemTy = elemTy,
           elemExps = elems,
           loc = loc}
      | (P.Vector_alloc_init_fresh, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Vector_alloc_init_fresh"

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
      | C.CCINTINF {srcLabel, loc} =>
        N.NCINTINF {srcLabel = srcLabel, loc = loc}
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
                      closureEnvExp = closureEnvExp,
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
        in
          (recordLet o indexLet)
            (load {srcAddr = N.NARECORDFIELD {recordExp = recordVar,
                                              fieldIndex = indexVar},
                   resultTy = resultTy,
                   valueTag = resultTag,
                   valueSize = resultSize,
                   loc = loc})
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
      | C.CCCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy, loc} =>
        N.NCCATCH {catchLabel = catchLabel,
                   argVarList = map (compileVarInfo btvEnv) argVarList,
                   catchExp = compileExp env catchExp,
                   tryExp = compileExp env tryExp,
                   resultTy = compileTy btvEnv resultTy,
                   loc = loc}
      | C.CCTHROW {catchLabel, argExpList, resultTy, loc} =>
        N.NCTHROW {catchLabel = catchLabel,
                   argExpList = map (compileExp env) argExpList,
                   resultTy = compileTy btvEnv resultTy,
                   loc = loc}
      | C.CCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val expTy as (_, expRty) = compileTy btvEnv expTy
          val targetTy as (_, targetRty) = compileTy btvEnv targetTy
        in
          N.NCCAST {exp = compileExp env exp,
                    expTy = expTy,
                    targetTy = targetTy,
                    cast = cast,
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
            SOME RuntimeTypes.BOXED =>
            (expLet, N.INIT_VALUE expVar)
          | SOME RuntimeTypes.UNBOXED =>
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
                                 retTy = retTy}
        in
          if isWrapperConvention cconv
          then (nil, FunEntryLabel.Map.singleton (id, id))
          else
            let
              val wrapperId = FunEntryLabel.derive id
              val wrapperCconv = toWrapperConvention cconv
              val argVars = map newVar (#argTyList wrapperCconv)
              val wrapperClsEnvVar =
                  case closureEnvVar of
                    SOME v => compileVarInfo tyvarKindEnv v
                  | NONE => newVar (ptrTy BuiltinTypes.unitTy)
              val bodyExp =
                  staticCall
                    {calleeConv = cconv,
                     callerConv = wrapperCconv,
                     codeExp = funEntryExp (id, cconv, loc),
                     closureEnvExp =
                       N.NCVAR {varInfo=wrapperClsEnvVar, loc=loc},
                     argExpList =
                       map (fn v => N.NCVAR {varInfo=v, loc=loc}) argVars,
                     loc = loc}
            in
              ([N.NTFUNCTION {id = wrapperId,
                              tyvarKindEnv = tyvarKindEnv,
                              argVarList = argVars,
                              closureEnvVar = SOME wrapperClsEnvVar,
                              bodyExp = bodyExp,
                              retTy = #retTy wrapperCconv,
                              gcCheck = false,
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
          val actualArgVars = map (compileVarInfo tyvarKindEnv) argVarList
          val argVars =
              map (fn v => newVar (toGenericArgTy (#ty v))) actualArgVars
          val argExps =
              ListPair.mapEq
                (fn (v1, v2) =>
                    (v1, coerceArg (N.NCVAR {varInfo = v2, loc = loc})
                                   (#ty v2)
                                   (#ty v1)
                                   loc))
                (actualArgVars, argVars)
          val bodyExp = compileExp env bodyExp
          val bodyExp =
              foldl (fn ((v,e),z) =>
                        N.NCLET {boundVar = v, boundExp = e,
                                 mainExp = z, loc = loc})
                    bodyExp
                    argExps
          val actualRetTy = compileTy tyvarKindEnv retTy
          val retTy = actualRetTy
          val bodyExp = coerceArg bodyExp actualRetTy retTy loc
        in
          N.NTFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             argVarList = argVars,
             closureEnvVar =
               Option.map (compileVarInfo tyvarKindEnv) closureEnvVar,
             bodyExp = bodyExp,
             retTy = retTy,
             gcCheck = true,
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
        C.CTEXTERNVAR {id, ty, provider, loc} =>
        N.NTEXTERNVAR
          {id = id,
           ty = compileTy emptyBtvEnv ty,
           provider = provider,
           loc = loc}
      | C.CTEXPORTVAR {id, weak, ty, value, loc} =>
        let
          val env = {btvEnv = emptyBtvEnv, wrapperMap = wrapperMap}
        in
          N.NTEXPORTVAR {id = id, weak = weak,
                         ty = compileTy emptyBtvEnv ty,
                         value = Option.map (compileTopConst env) value,
                         loc = loc}
        end
      | C.CTEXTERNFUN {id, tyvars, argTyList, retTy, provider, loc} =>
        N.NTEXTERNFUN
          {id = id,
           tyvars = tyvars,
           argTyList = map (toGenericArgTy o compileTy tyvars) argTyList,
           retTy = compileTy tyvars retTy,
           provider = provider,
           loc = loc}
      | C.CTEXPORTFUN {id, funId, loc} =>
        N.NTEXPORTFUN {id = id, funId = funId, loc = loc}
      | C.CTSTRING {id, string, loc} =>
        N.NTSTRING {id = id, string = string, loc = loc}
      | C.CTINTINF {id, value, loc} =>
        N.NTINTINF {id = id, value = value, loc = loc}
      | C.CTRECORD {id, tyvarKindEnv, fieldList, recordTy, isMutable,
                    isCoalescable, clearPad, bitmaps, loc} =>
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
             isCoalescable = isCoalescable,
             clearPad = clearPad,
             bitmaps =
               map (fn {bitmapIndex, bitmapExp} =>
                       {bitmapIndex = compileTopConst env bitmapIndex,
                        bitmapExp = compileTopConst env bitmapExp})
                   bitmaps,
             loc = loc}
        end
      | C.CTARRAY {id, elemTy, isMutable, isCoalescable, clearPad, numElements,
                   initialElements, elemSizeExp, tagExp, loc} =>
        let
          val env = {btvEnv = emptyBtvEnv, wrapperMap = wrapperMap}
        in
          N.NTARRAY
            {id = id,
             elemTy = compileTy emptyBtvEnv elemTy,
             isMutable = isMutable,
             isCoalescable = isCoalescable,
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
