(**
 * closure conversion with static allocation
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure ClosureConversion2 : sig

  val convert : BitmapCalc2.bcdecl list -> ClosureCalc.program

end =
struct

  structure L = TypedLambda
  structure R = RecordCalc
  structure B = BitmapCalc2
  structure C = ClosureCalc
  structure T = Types
  structure P = BuiltinPrimitive

  fun newVar ty =
      {id = VarID.generate (), path = [], ty = ty} : C.varInfo

  fun mapi f l =
      let
        fun loop f i nil = nil
          | loop f i (h::t) = f (i,h) :: loop f (i+1) t
      in
        loop f 0 l
      end

  fun remove (map, key) =
      if VarID.Map.inDomain (map, key)
      then #1 (VarID.Map.remove (map, key))
      else map

  fun isAtomic ccexp =
      case ccexp of
        C.CCFOREIGNAPPLY _ => false
      | C.CCEXPORTCALLBACK _ => false
      | C.CCCONST _ => true
      | C.CCINTINF _ => false
      | C.CCVAR _ => true
      | C.CCEXVAR _ => false
      | C.CCPRIMAPPLY _ => false
      | C.CCCALL _ => false
      | C.CCLET _ => false
      | C.CCRECORD _ => false
      | C.CCSELECT _ => false
      | C.CCMODIFY _ => false
      | C.CCRAISE _ => false
      | C.CCHANDLE _ => false
      | C.CCSWITCH _ => false
      | C.CCCATCH _ => false
      | C.CCTHROW _ => false
      | C.CCCAST {exp, expTy, targetTy, cast, loc} => isAtomic exp
      | C.CCEXPORTVAR _ => false

  fun makeBind (exp, ty, loc) =
      if isAtomic exp then (fn x => x, exp) else
        let
          val v = newVar ty
        in
          (fn x => C.CCLET {boundVar=v, boundExp=exp, mainExp=x, loc=loc},
           C.CCVAR {varInfo=v, loc=loc})
        end

  type varSet = C.varInfo VarID.Map.map
  val emptySet = VarID.Map.empty : varSet
  fun singletonSet (v : C.varInfo) =
      VarID.Map.singleton (#id v, v)
  fun varSet vars : varSet =
      foldl (fn (v,z) => VarID.Map.insert (z, #id v, v)) emptySet vars
  fun varList set : C.varInfo list =
      VarID.Map.listItems set
  fun unionSet (set1, set2) : varSet =
      VarID.Map.unionWith #2 (set1, set2)
  fun unionSetList sets =
      foldl unionSet emptySet sets
  fun minusSet (set1, set2 : varSet) : varSet =
      VarID.Map.filter
        (fn {id,...} => not (VarID.Map.inDomain (set2, id)))
        set1

  local
    fun fvExp bv ccexp =
        case ccexp of
          C.CCFOREIGNAPPLY {funExp, attributes, argExpList, resultTy, loc} =>
          fvExpList bv (funExp :: argExpList)
        | C.CCEXPORTCALLBACK {codeExp, closureEnvExp, instTyvars, resultTy,
                              loc} =>
          fvExpList bv [codeExp, closureEnvExp]
        | C.CCCONST {const, ty, loc} => emptySet
        | C.CCINTINF {srcLabel, loc} => emptySet
        | C.CCVAR {varInfo, loc} =>
          if VarID.Set.member (bv, #id varInfo)
          then emptySet else singletonSet varInfo
        | C.CCEXVAR {id, ty, loc} => emptySet
        | C.CCPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                         instSizeList, loc} =>
          fvExpList bv (argExpList @ instTagList @ instSizeList)
        | C.CCCALL {codeExp, closureEnvExp, argExpList, cconv, funTy, loc} =>
          unionSet (fvExpList bv (codeExp :: closureEnvExp :: argExpList),
                    fvCconv bv cconv)
        | C.CCLET {boundVar, boundExp, mainExp, loc} =>
          unionSet (fvExp bv boundExp,
                    fvExp (VarID.Set.add (bv, #id boundVar)) mainExp)
        | C.CCRECORD {fieldList, recordTy, isMutable, clearPad, allocSizeExp,
                      bitmaps, loc} =>
          let
            val fvFields =
                foldl
                  (fn ({fieldExp, fieldTy, fieldLabel, fieldSize, fieldTag,
                        fieldIndex}, fv) =>
                      unionSet (fv, fvExpList bv [fieldExp, fieldSize,
                                                  fieldIndex, fieldTag]))
                  emptySet
                  fieldList
            val fvBitmaps =
                foldl
                  (fn ({bitmapIndex, bitmapExp}, fv) =>
                      unionSet (fv, fvExpList bv [bitmapIndex, bitmapExp]))
                  emptySet
                  bitmaps
          in
            unionSet (unionSet (fvExp bv allocSizeExp, fvFields), fvBitmaps)
          end
        | C.CCSELECT {recordExp, indexExp, label, recordTy, resultTy,
                      resultSize, resultTag, loc} =>
          fvExpList bv [recordExp, indexExp, resultSize, resultTag]
        | C.CCMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                      valueTag, valueSize, loc} =>
          fvExpList bv [recordExp, indexExp, valueExp, valueTag, valueSize]
        | C.CCRAISE {argExp, resultTy, loc} =>
          fvExp bv argExp
        | C.CCHANDLE {tryExp, exnVar, handlerExp, resultTy, loc} =>
          unionSet (fvExp bv tryExp,
                    fvExp (VarID.Set.add (bv, #id exnVar)) handlerExp)
        | C.CCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
          foldl (fn ({constant, branchExp}, fv) =>
                    unionSet (fv, fvExp bv branchExp))
                (fvExpList bv [switchExp, defaultExp])
                branches
        | C.CCCATCH {recursive, rules, tryExp, resultTy, loc} =>
          unionSetList (fvExp bv tryExp :: map (fvCatchRule bv) rules)
        | C.CCTHROW {catchLabel, argExpList, resultTy, loc} =>
          fvExpList bv argExpList
        | C.CCCAST {exp, expTy, targetTy, cast, loc} =>
          fvExp bv exp
        | C.CCEXPORTVAR {id, ty, valueExp, loc} =>
          fvExpList bv [valueExp]

    and fvExpList bv exps =
        foldl (fn (x,z) => unionSet (fvExp bv x, z)) emptySet exps

    and fvCatchRule bv {catchLabel, argVarList, catchExp} =
        let
          val bv2 = foldl (fn ({id, ...}, z) => VarID.Set.add (z, id))
                          bv
                          argVarList
        in
          fvExp bv2 catchExp
        end

    and fvCconv bv cconv =
        case cconv of
          C.STATICCALL ty => emptySet
        | C.DYNAMICCALL {cconvTag, wrapper} =>
          fvExpList bv [cconvTag, wrapper]
  in

  fun freeVars ccexp =
      fvExp VarID.Set.empty ccexp
  fun freeVarsFn (argVarList, ccexp) =
      fvExp (foldl (fn ({id,...}:C.varInfo, bv) => VarID.Set.add (bv, id))
                   VarID.Set.empty
                   argVarList)
            ccexp

  end (* local *)

  fun substExp subst ccexp =
      case ccexp of
        C.CCFOREIGNAPPLY {funExp, attributes, argExpList, resultTy, loc} =>
        C.CCFOREIGNAPPLY
          {funExp = substExp subst funExp,
           attributes = attributes,
           argExpList = map (substExp subst) argExpList,
           resultTy = resultTy,
           loc = loc}
      | C.CCEXPORTCALLBACK {codeExp, closureEnvExp, instTyvars, resultTy,
                            loc} =>
        C.CCEXPORTCALLBACK
          {codeExp = substExp subst codeExp,
           closureEnvExp = substExp subst closureEnvExp,
           instTyvars = instTyvars,
           resultTy = resultTy,
           loc = loc}
      | C.CCCONST {const, ty, loc} => ccexp
      | C.CCINTINF {srcLabel, loc} => ccexp
      | C.CCVAR {varInfo, loc} =>
        (
          case VarID.Map.find (subst, #id varInfo) of
            NONE => ccexp
          | SOME exp => exp
        )
      | C.CCEXVAR {id, ty, loc} => ccexp
      | C.CCPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                       instSizeList, loc} =>
        C.CCPRIMAPPLY
          {primInfo = primInfo,
           argExpList = map (substExp subst) argExpList,
           instTyList = instTyList,
           instTagList = map (substExp subst) instTagList,
           instSizeList = map (substExp subst) instSizeList,
           loc = loc}
      | C.CCCALL {codeExp, closureEnvExp, argExpList, cconv, funTy, loc} =>
        C.CCCALL
          {codeExp = substExp subst codeExp,
           closureEnvExp = substExp subst closureEnvExp,
           argExpList = map (substExp subst) argExpList,
           cconv = substCconv subst cconv,
           funTy = funTy,
           loc = loc}
      | C.CCLET {boundVar, boundExp, mainExp, loc} =>
        let
          val boundExp = substExp subst boundExp
          val subst = remove (subst, #id boundVar)
          val mainExp = substExp subst mainExp
        in
          C.CCLET {boundVar = boundVar,
                   boundExp = boundExp,
                   mainExp = mainExp,
                   loc = loc}
        end
      | C.CCRECORD {fieldList, recordTy, isMutable, clearPad, allocSizeExp,
                    bitmaps, loc} =>
        C.CCRECORD
          {fieldList =
             map (fn {fieldExp, fieldTy, fieldLabel, fieldSize, fieldTag,
                      fieldIndex} =>
                     {fieldExp = substExp subst fieldExp,
                      fieldTy = fieldTy,
                      fieldLabel = fieldLabel,
                      fieldSize = substExp subst fieldSize,
                      fieldTag = substExp subst fieldTag,
                      fieldIndex = substExp subst fieldIndex})
                 fieldList,
           recordTy = recordTy,
           isMutable = isMutable,
           clearPad = clearPad,
           allocSizeExp = substExp subst allocSizeExp,
           bitmaps =
             map (fn {bitmapIndex, bitmapExp} =>
                     {bitmapIndex = substExp subst bitmapIndex,
                      bitmapExp = substExp subst bitmapExp})
                 bitmaps,
           loc = loc}
      | C.CCSELECT {recordExp, indexExp, label, recordTy, resultTy,
                    resultSize, resultTag, loc} =>
        C.CCSELECT
          {recordExp = substExp subst recordExp,
           indexExp = substExp subst indexExp,
           label = label,
           recordTy = recordTy,
           resultTy = resultTy,
           resultSize = substExp subst resultSize,
           resultTag = substExp subst resultTag,
           loc = loc}
      | C.CCMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    valueTag, valueSize, loc} =>
        C.CCMODIFY
          {recordExp = substExp subst recordExp,
           recordTy = recordTy,
           indexExp = substExp subst indexExp,
           label = label,
           valueExp = substExp subst valueExp,
           valueTy = valueTy,
           valueTag = substExp subst valueTag,
           valueSize = substExp subst valueSize,
           loc = loc}
      | C.CCRAISE {argExp, resultTy, loc} =>
        C.CCRAISE
          {argExp = substExp subst argExp,
           resultTy = resultTy,
           loc = loc}
      | C.CCHANDLE {tryExp, exnVar, handlerExp, resultTy, loc} =>
        C.CCHANDLE
          {tryExp = substExp subst tryExp,
           exnVar = exnVar,
           handlerExp = substExp (remove (subst, #id exnVar)) handlerExp,
           resultTy = resultTy,
           loc = loc}
      | C.CCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        C.CCSWITCH
          {switchExp = substExp subst switchExp,
           expTy = expTy,
           branches = map (fn {constant, branchExp} =>
                              {constant = constant,
                               branchExp = substExp subst branchExp})
                          branches,
           defaultExp = substExp subst defaultExp,
           resultTy = resultTy,
           loc = loc}
      | C.CCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        C.CCCATCH
          {recursive = recursive,
           rules = map (substCatchRule subst) rules,
           tryExp = substExp subst tryExp,
           resultTy = resultTy,
           loc = loc}
      | C.CCTHROW {catchLabel, argExpList, resultTy, loc} =>
        C.CCTHROW
          {catchLabel = catchLabel,
           argExpList = map (substExp subst) argExpList,
           resultTy = resultTy,
           loc = loc}
      | C.CCCAST {exp, expTy, targetTy, cast, loc} =>
        C.CCCAST
          {exp = substExp subst exp,
           expTy = expTy,
           targetTy = targetTy,
           cast = cast,
           loc = loc}
      | C.CCEXPORTVAR {id, ty, valueExp, loc} =>
        C.CCEXPORTVAR
          {id = id,
           ty = ty,
           valueExp = substExp subst valueExp,
           loc = loc}

  and substCatchRule subst {catchLabel, argVarList, catchExp} =
      let
        val subst2 = foldl (fn (x,z) => remove (z, #id x)) subst argVarList
      in
        {catchLabel = catchLabel,
         argVarList = argVarList,
         catchExp = substExp subst2 catchExp}
      end

  and substCconv subst cconv =
      case cconv of
        C.STATICCALL ty => cconv
      | C.DYNAMICCALL {cconvTag, wrapper} =>
        C.DYNAMICCALL {cconvTag = substExp subst cconvTag,
                       wrapper = substExp subst wrapper}

  fun wordConst w loc =
      C.CCCONST {const = C.CVWORD32 w, ty = BuiltinTypes.word32Ty, loc = loc}

  fun sizeToCcexp loc ty value =
      case value of
        SingletonTyEnv2.VAR v => C.CCVAR {varInfo = v, loc = loc}
      | SingletonTyEnv2.VAL n =>
        C.CCCONST {const = C.CVSIZE {ty = ty, size = n},
                   ty = T.SINGLETONty (T.SIZEty ty),
                   loc = loc}

  fun tagToCcexp loc ty value =
      case value of
        SingletonTyEnv2.VAR v => C.CCVAR {varInfo = v, loc = loc}
      | SingletonTyEnv2.VAL n =>
        C.CCCONST {const = C.CVTAG {ty = ty, tag = n},
                   ty = T.SINGLETONty (T.TAGty ty),
                   loc = loc}

  fun unitExp loc =
      C.CCCONST {const = C.CVUNIT, ty = BuiltinTypes.unitTy, loc = loc}

  fun nullClosureEnvExp loc =
      C.CCCAST {exp = C.CCCONST {const = C.CVNULLBOXED,
                                 ty = BuiltinTypes.boxedTy,
                                 loc = loc},
                expTy = BuiltinTypes.boxedTy,
                targetTy = T.BACKENDty T.SOME_CLOSUREENVty,
                cast = BuiltinPrimitive.TypeCast,
                loc = loc}

  fun intExp n loc =
      C.CCCONST {const = C.CVINT32 n, ty = BuiltinTypes.int32Ty, loc = loc}

  fun varExp varInfo loc =
      (C.CCVAR {varInfo = varInfo, loc = loc}, #ty varInfo)

  fun funEntryExp (id, codeEntryTy, loc) =
      let
        val ty = T.BACKENDty (T.FUNENTRYty codeEntryTy)
        val const = C.CVFUNENTRY {id=id, codeEntryTy=codeEntryTy}
      in
        C.CCCONST {const = const, ty = ty, loc = loc}
      end

  fun funWrapperExp (id, codeEntryTy, loc) =
      let
        val ty = T.BACKENDty T.SOME_FUNWRAPPERty
        val const = C.CVFUNWRAPPER {id=id, codeEntryTy=codeEntryTy}
      in
        C.CCCONST {const = const, ty = ty, loc = loc}
      end

  fun cconvTagExp (codeEntryTy, loc) =
      let
        val ty = T.BACKENDty (T.CCONVTAGty codeEntryTy)
        val const = C.CVCCONVTAG codeEntryTy
      in
        C.CCCONST {const = const, ty = ty, loc = loc}
      end

  local
    fun primapply prim (exp1ty, exp2ty) (exp1, exp2) loc =
        C.CCPRIMAPPLY
          {primInfo =
             {primitive = P.R prim,
              ty = {boundtvars = BoundTypeVarID.Map.empty,
                    argTyList = [exp1ty, exp2ty],
                    resultTy = BuiltinTypes.word32Ty}},
           argExpList = [exp1, exp2],
           instTyList = nil,
           instTagList = nil,
           instSizeList = nil,
           loc = loc}
    fun primop2 prim exps loc =
        primapply (P.M prim)
                  (BuiltinTypes.word32Ty, BuiltinTypes.word32Ty)
                  exps
                  loc
  in
  fun word32_orb (exp1, exp2, loc) = primop2 P.Word_orb (exp1, exp2) loc
  fun word32_andb (exp1, exp2, loc) = primop2 P.Word_andb (exp1, exp2) loc
  fun word32_deref (exp1, exp2, loc) =
      primapply P.Boxed_deref
                (BuiltinTypes.boxedTy, BuiltinTypes.word32Ty)
                (exp1, exp2)
                loc
  end (* local *)

  datatype top =
      DEC of C.topdec
    | DATA of C.topdata

  exception ExpToConst

  fun valueToWord value =
      case value of
        (C.CVWORD32 n, _) => n
      | (C.CVCAST {value, valueTy, ...}, _) => valueToWord (value, valueTy)
      | _ => raise ExpToConst

  fun expToConst (C.CCCONST {const, ty, ...}) = (const, ty)
    | expToConst (C.CCCAST {exp, expTy, targetTy, cast, loc}) =
      (C.CVCAST {value = #1 (expToConst exp),
                 valueTy = expTy,
                 targetTy = targetTy,
                 cast = cast},
       targetTy)
    | expToConst (C.CCPRIMAPPLY prim) = primToConst prim
    | expToConst _ = raise ExpToConst

  and expToWord exp = valueToWord (expToConst exp)

  and primToConst {primInfo={primitive, ty={resultTy,...}},
                   argExpList, instTyList, instTagList, instSizeList, loc} =
      case (primitive, instTyList, argExpList) of
        (P.R (P.M P.Word_add), [], [e1, e2]) =>
        (C.CVWORD32 (Word32.+ (expToWord e1, expToWord e2)), resultTy)
      | (P.R (P.M P.Word_andb), [], [e1, e2]) =>
        (C.CVWORD32 (Word32.andb (expToWord e1, expToWord e2)), resultTy)
      | (P.R (P.M P.Word_orb), [], [e1, e2]) =>
        (C.CVWORD32 (Word32.orb (expToWord e1, expToWord e2))
         handle ExpToConst =>
                C.CVWORD32_ORB (#1 (expToConst e1), #1 (expToConst e2)),
         resultTy)
      | (P.R (P.M P.Word_xorb), [], [e1, e2]) =>
        (C.CVWORD32 (Word32.xorb (expToWord e1, expToWord e2)), resultTy)
      | (P.R (P.M P.Word_sub), [], [e1, e2]) =>
        (C.CVWORD32 (Word32.- (expToWord e1, expToWord e2)), resultTy)
      | _ =>
        (* FIXME : evaluate other primitives *)
        raise ExpToConst

  fun allocRecord (styEnv, path)
                  (record as {fieldList, recordTy, isMutable, clearPad,
                              allocSizeExp, bitmaps, loc}) =
      let
        val fieldList =
            map (fn {fieldExp, fieldTy, fieldLabel, fieldSize, fieldTag,
                     fieldIndex} =>
                    {fieldExp = expToConst fieldExp,
                     fieldTy = fieldTy,
                     fieldLabel = fieldLabel,
                     fieldSize = expToConst fieldSize,
                     fieldIndex = expToConst fieldIndex})
                fieldList
        val bitmapList =
            map (fn {bitmapIndex, bitmapExp} =>
                    {bitmapIndex = expToConst bitmapIndex,
                     bitmapExp = expToConst bitmapExp})
                bitmaps
        val id = DataLabel.generate path
      in
        ([DATA (C.CTRECORD {id = id,
                            tyvarKindEnv = SingletonTyEnv2.btvEnv styEnv,
                            fieldList = fieldList,
                            recordTy = recordTy,
                            isMutable = isMutable,
                            isCoalescable = not isMutable,
                            clearPad = clearPad,
                            bitmaps = bitmapList,
                            loc = loc})],
         C.CCCONST {const = C.CVTOPDATA {id=id, ty=recordTy},
                    ty = recordTy,
                    loc = loc})
      end
      handle ExpToConst => (nil, C.CCRECORD record)

  fun arrayTy elemTy =
      T.CONSTRUCTty {tyCon = BuiltinTypes.arrayTyCon, args = [elemTy]}

  fun allocArray path {elemTy, initialElements, numElements, isMutable,
                       isCoalescable, clearPad, elemSizeExp, tagExp, loc}
                      fallback =
      let
        val initialElements = map expToConst initialElements
        val numElements = expToConst numElements
        val elemSizeExp = expToConst elemSizeExp
        val tagExp = expToConst tagExp
        val id = DataLabel.generate path
        val topDataTy = arrayTy elemTy
      in
        ([DATA (C.CTARRAY {id = id,
                           elemTy = elemTy,
                           isMutable = isMutable,
                           isCoalescable = isCoalescable,
                           clearPad = clearPad,
                           initialElements = initialElements,
                           numElements = numElements,
                           elemSizeExp = elemSizeExp,
                           tagExp = tagExp,
                           loc = loc})],
         C.CCCONST {const = C.CVTOPDATA {id=id, ty = topDataTy},
                    ty = topDataTy,
                    loc = loc})
      end
      handle ExpToConst => (nil, fallback)

  fun valbind (var, exp, result, loc) =
      let
        val v = SOME (#1 (expToConst exp)) handle ExpToConst => NONE
      in
        (case v of SOME _ => nil
                 | NONE => [{boundVar = var, boundExp = exp, loc = loc}],
         VarID.Map.singleton (#id var, (var, v, result)))
      end

  fun Let (binds, mainExp) =
      foldr
        (fn ({boundVar, boundExp, loc}, mainExp) =>
            C.CCLET {boundVar = boundVar,
                     boundExp = boundExp,
                     mainExp = mainExp,
                     loc = loc})
        mainExp
        binds

  type accum =
      {comp : RecordLayout.computation_accum,
       subst : (ClosureCalc.loc -> ClosureCalc.ccexp) VarID.Map.map ref}

  fun newAccum () : accum =
      {comp = RecordLayout.newComputationAccum (),
       subst = ref VarID.Map.empty}

  fun toCcexp ({subst, ...}:accum) loc value =
      case value of
        RecordLayoutCalc.WORD n =>
        wordConst n loc
      | RecordLayoutCalc.VAR {id, path} =>
        case VarID.Map.find (!subst, id) of
          NONE =>
          C.CCVAR {varInfo = {id = id, path = path, ty = BuiltinTypes.word32Ty},
                   loc = loc}
        | SOME exp => exp loc

  fun primInfo op2 =
      {primitive =
         case op2 of
           RecordLayoutCalc.ADD => P.R (P.M P.Word_add)
         | RecordLayoutCalc.SUB => P.R (P.M P.Word_sub)
         | RecordLayoutCalc.DIV => P.R (P.M P.Word_div_unsafe)
         | RecordLayoutCalc.AND => P.R (P.M P.Word_andb)
         | RecordLayoutCalc.OR => P.R (P.M P.Word_orb)
         | RecordLayoutCalc.LSHIFT => P.R (P.M P.Word_lshift_unsafe)
         | RecordLayoutCalc.RSHIFT => P.R (P.M P.Word_rshift_unsafe),
       ty = {boundtvars = BoundTypeVarID.Map.empty,
             argTyList = [BuiltinTypes.word32Ty, BuiltinTypes.word32Ty],
             resultTy = BuiltinTypes.word32Ty}}

  fun extractDecls (accum, mainExp, loc) =
      foldr
        (fn (RecordLayoutCalc.VAL ({id, path}, exp), z) =>
            C.CCLET
              {boundVar = {id = id, path = path, ty = BuiltinTypes.word32Ty},
               boundExp =
                 case exp of
                   RecordLayoutCalc.VALUE value =>
                   toCcexp accum loc value
                 | RecordLayoutCalc.OP (op2, (v1, v2)) =>
                   C.CCPRIMAPPLY
                     {primInfo = primInfo op2,
                      argExpList = [toCcexp accum loc v1, toCcexp accum loc v2],
                      instTyList = nil,
                      instTagList = nil,
                      instSizeList = nil,
                      loc = loc},
               mainExp = z,
               loc = loc})
        mainExp
        (RecordLayout.extractDecls (#comp accum))

  fun tagToValue ({subst, ...}:accum) tag =
      case tag of
        SingletonTyEnv2.VAL n =>
        RecordLayoutCalc.WORD (Word.fromInt (RuntimeTypes.tagValue n))
      | SingletonTyEnv2.VAR (var as {id, ty, path}) =>
        let
          val e = fn loc => C.CCCAST
                              {exp = C.CCVAR {varInfo = var, loc = loc},
                               expTy = ty,
                               targetTy = BuiltinTypes.word32Ty,
                               cast = P.TypeCast,
                               loc = loc}
        in
          subst := VarID.Map.insert (!subst, id, e);
          RecordLayoutCalc.VAR {id = id, path = path}
        end

  fun checkNoExtraComputation ({comp, ...}:accum) =
      case RecordLayout.extractDecls comp of
        nil => ()
      | _ => raise Bug.Bug "extra computation"

  fun computeTupleLayout accum fields loc =
      let
        val {allocSize, fieldIndexes, bitmaps, padding} =
            RecordLayout.computeRecord
              (#comp accum)
              (map (fn {tag, size, ...} =>
                       {tag = tagToValue accum tag,
                        size = RecordLayoutCalc.WORD
                                 (Word.fromInt (RuntimeTypes.getSize size))})
                   fields)
        val fieldList =
            map (fn (label, (index, {tag, size, ty, ...})) =>
                    {fieldLabel = label,
                     fieldIndex = index,
                     fieldSize = size,
                     fieldTag = tag,
                     fieldTy = ty})
                (RecordLabel.tupleList (ListPair.zipEq (fieldIndexes, fields)))
        val recordTy =
            T.RECORDty
              (foldl (fn ({fieldLabel, fieldTy, ...},z) =>
                         RecordLabel.Map.insert (z, fieldLabel, fieldTy))
                     RecordLabel.Map.empty
                     fieldList)
        val fieldList =
            map
              (fn {fieldLabel, fieldIndex, fieldSize, fieldTag, fieldTy} =>
                  {fieldLabel = fieldLabel,
                   fieldIndex =
                     C.CCCAST
                       {exp = toCcexp accum loc fieldIndex,
                        expTy = BuiltinTypes.word32Ty,
                        targetTy = T.SINGLETONty
                                     (T.INDEXty (fieldLabel, recordTy)),
                        cast = BuiltinPrimitive.TypeCast,
                        loc = loc},
                   fieldSize =
                     C.CCCONST
                       {const = C.CVSIZE {ty = fieldTy, size = fieldSize},
                        ty = T.SINGLETONty (T.SIZEty fieldTy),
                        loc = loc},
                   fieldTag = tagToCcexp loc fieldTy fieldTag,
                   fieldTy = fieldTy})
              fieldList
        val bitmapList =
            mapi
              (fn (i, {index, bitmap}) =>
                  {bitmapIndex =
                     C.CCCAST
                       {exp = toCcexp accum loc index,
                        expTy = BuiltinTypes.word32Ty,
                        targetTy = T.BACKENDty (T.RECORDBITMAPINDEXty
                                                  (i, recordTy)),
                        cast = BuiltinPrimitive.TypeCast,
                        loc = loc},
                   bitmapExp =
                     C.CCCAST
                       {exp = toCcexp accum loc bitmap,
                        expTy = BuiltinTypes.word32Ty,
                        targetTy = T.BACKENDty (T.RECORDBITMAPty
                                                  (i, recordTy)),
                        cast = BuiltinPrimitive.TypeCast,
                        loc = loc}})
              bitmaps
        val allocSizeExp =
            C.CCCAST {exp = toCcexp accum loc allocSize,
                      expTy = BuiltinTypes.word32Ty,
                      targetTy = T.BACKENDty (T.RECORDSIZEty recordTy),
                      cast = BuiltinPrimitive.TypeCast,
                      loc = loc}
      in
        {fieldList = fieldList,
         recordTy = recordTy,
         allocSizeExp = allocSizeExp,
         bitmaps = bitmapList}
      end

  fun addExtraBitmapBit (recordTy, bitmap0Exp, extraBitsExp, loc) =
      C.CCCAST
        {exp = word32_orb
                 (C.CCCAST
                    {exp = bitmap0Exp,
                     expTy = T.BACKENDty (T.RECORDBITMAPty (0, recordTy)),
                     targetTy = BuiltinTypes.word32Ty,
                     cast = BuiltinPrimitive.TypeCast,
                     loc = loc},
                  extraBitsExp,
                  loc),
         expTy = BuiltinTypes.word32Ty,
         targetTy = T.BACKENDty (T.RECORDBITMAPty (0, recordTy)),
         cast = BuiltinPrimitive.TypeCast,
         loc = loc}

  fun readBitmap0 (recordTy, recordExp, bitmap0IndexExp, loc) =
      word32_deref
        (C.CCCAST
           {exp = recordExp,
            expTy = recordTy,
            targetTy = BuiltinTypes.boxedTy,
            cast = BuiltinPrimitive.TypeCast,
            loc = loc},
         C.CCCAST
           {exp = bitmap0IndexExp,
            expTy = T.BACKENDty (T.RECORDBITMAPINDEXty (0, recordTy)),
            targetTy = BuiltinTypes.word32Ty,
            cast = BuiltinPrimitive.TypeCast,
            loc = loc},
         loc)

  fun makeTuple accum fields loc =
      let
        val {fieldList, recordTy, allocSizeExp, bitmaps} =
            computeTupleLayout accum fields loc
        val recordFields =
            ListPair.mapEq
              (fn ({exp, ty, tag, size},
                   {fieldLabel, fieldIndex, fieldSize, fieldTy, fieldTag}) =>
                  {fieldExp = exp,
                   fieldLabel = fieldLabel,
                   fieldIndex = fieldIndex,
                   fieldSize = fieldSize,
                   fieldTag = fieldTag,
                   fieldTy = fieldTy})
              (fields, fieldList)
      in
        {fieldList = recordFields,
         recordTy = recordTy,
         isMutable = false,
         clearPad = false,
         allocSizeExp = allocSizeExp,
         bitmaps = bitmaps,
         loc = loc}
      end

  local
    type field = {var: C.varInfo,
                  tag: RuntimeTypes.tag SingletonTyEnv2.value,
                  size: RuntimeTypes.size SingletonTyEnv2.value,
                  usize: RuntimeTypes.size}

    fun fvValue value =
        case value of
          SingletonTyEnv2.VAR v => singletonSet v
        | SingletonTyEnv2.VAL _ => emptySet

    fun tagSizeVars fields =
        VarID.Map.foldl
          (fn ({size,tag,...}:field, set) =>
              unionSet (unionSet (set, fvValue size), fvValue tag))
          emptySet
          fields

    fun envFields styEnv vars =
      let
        val fields =
            VarID.Map.map
              (fn (var as {ty,...}:C.varInfo) =>
                  {var = var,
                   tag = SingletonTyEnv2.findTag styEnv ty,
                   size = SingletonTyEnv2.findSize styEnv ty,
                   usize = SingletonTyEnv2.unalignedSize styEnv ty})
              vars
        (* tag and size is needed to read a value from closure environment. *)
        val set = minusSet (tagSizeVars fields, vars)
      in
        if VarID.Map.isEmpty set
        then VarID.Map.listItems fields
        else envFields styEnv (unionSet (vars, set))
      end

    fun sortFields fields =
        ListSorter.sort
          (fn ({usize=u1, var=v1, ...}:field, {usize=u2, var=v2, ...}) =>
              (* larger field first *)
              case Int.compare (RuntimeTypes.getSize u1,
                                RuntimeTypes.getSize u2) of
                EQUAL => VarID.compare (#id v1, #id v2)
              | LESS => GREATER
              | GREATER => LESS)
          fields
  in

  fun makeClosureEnvRecord accum styEnv (freeVars, loc) =
      let
        val fields = sortFields (envFields styEnv freeVars)
        (* Allocate the maximum size to polymorphic fields in closure
         * environment records in order to reduce the cost of dynamic
         * record layout computation.  Since closure environment records
         * are never passed to C functions, its accurate layout is not
         * needed.  In contrast to field sizes, the bitmap of closure
         * environment records would be computed at runtime; therefore,
         * we need to deal with RecordLayout.computationAccum. *)
        val tupleFields =
            map (fn {var as {ty,...}, tag, usize, ...} =>
                    {exp = C.CCVAR {varInfo=var, loc=loc},
                     ty = ty,
                     tag = tag,
                     size = usize})
                fields
        val record as {fieldList,recordTy,...} =
            makeTuple accum tupleFields loc
        val envRecordFields =
            record # {fieldList =
                        ListPair.map
                          (fn ({size, var = {ty, ...}, ...}, field) =>
                              field # {fieldSize = sizeToCcexp loc ty size})
                          (fields, #fieldList record)}
        (* Closure environment records are never statically allocated;
         * every closure environment record contains at least one dynamic
         * field since free variables whose values are statically determined
         * are substituted with their values by constant propagation
         * performed by compileExp. *)
        val recordExp =
            C.CCCAST {exp = C.CCRECORD envRecordFields,
                      expTy = recordTy,
                      targetTy = T.BACKENDty T.SOME_CLOSUREENVty,
                      cast = BuiltinPrimitive.TypeCast,
                      loc = loc}
        val selectMap =
            ListPair.foldlEq
              (fn ({var={id,...}, tag, size, ...},
                   {fieldLabel, fieldIndex, fieldSize, fieldTy, ...},
                   selectMap) =>
                  VarID.Map.insert (selectMap, id,
                                    {indexExp = fieldIndex,
                                     label = fieldLabel,
                                     recordTy = recordTy,
                                     resultTy = fieldTy,
                                     resultSize = sizeToCcexp loc fieldTy size,
                                     resultTag = tagToCcexp loc fieldTy tag}))
              VarID.Map.empty
              (fields, fieldList)
      in
        (recordExp, selectMap)
      end

  end (* local *)

  fun closureSubst selectMap envVar loc =
      let
        val subst =
            VarID.Map.map
              (fn {indexExp, label, recordTy, resultTy, resultSize,
                   resultTag} =>
                  C.CCSELECT {recordExp =
                                C.CCCAST
                                  {exp = C.CCVAR {varInfo=envVar, loc=loc},
                                   expTy = #ty envVar,
                                   targetTy = recordTy,
                                   cast = BuiltinPrimitive.TypeCast,
                                   loc = loc},
                              indexExp = indexExp,
                              label = label,
                              recordTy = recordTy,
                              resultTy = resultTy,
                              resultSize = resultSize,
                              resultTag = resultTag,
                              loc = loc})
              selectMap
      in
        (* substitute free variables in resultSize fields *)
        VarID.Map.map (fn exp => substExp subst exp) subst
      end

  fun computeClosure accum styEnv (freeVars, loc) =
      if VarID.Map.isEmpty freeVars then (NONE, VarID.Map.empty) else
      let
        val (envExp, selectMap) =
            makeClosureEnvRecord accum styEnv (freeVars, loc)
        val envArgVar = newVar (T.BACKENDty T.SOME_CLOSUREENVty)
        val subst = closureSubst selectMap envArgVar loc
      in
        (SOME (envArgVar, envExp), subst)
      end

  type static_closure =
      {
        id : FunEntryLabel.id,
        closureEnvVar: C.varInfo option,   (* SOME_CLOSUREENVty *)
        codeEntryTy : T.codeEntryTy
      }

  fun replaceClosureEnvVar ({id, closureEnvVar, codeEntryTy} : static_closure,
                            var) =
      {id = id,
       closureEnvVar = var,
       codeEntryTy = codeEntryTy # {haveClsEnv = isSome var}}
      : static_closure

  fun decomposeExFunEntry (x as {id, codeEntryTy}) loc =
      let
        val ty = T.BACKENDty (T.FUNENTRYty codeEntryTy)
        val const = C.CVEXFUNENTRY x
      in
        {codeExp = C.CCCONST {const = const, ty = ty, loc = loc},
         closureEnvExp = nullClosureEnvExp loc,
         cconv = C.STATICCALL codeEntryTy}
      end

  fun decomposeStaticClosure ({id, closureEnvVar, codeEntryTy}:static_closure)
                             loc =
      {codeExp = funEntryExp (id, codeEntryTy, loc),
       closureEnvExp = case closureEnvVar of
                         NONE => nullClosureEnvExp loc
                       | SOME v => C.CCVAR {varInfo = v, loc = loc},
       cconv = C.STATICCALL codeEntryTy}

  fun makeClosureRecord (styEnv, path)
                        ({id, closureEnvVar, codeEntryTy}:static_closure,
                         resultTy)
                        loc =
      let
        val closureEnvExp =
            case closureEnvVar of
              NONE => nullClosureEnvExp loc
            | SOME v => C.CCVAR {varInfo=v, loc=loc}
        val entryExp =
            C.CCCAST {exp = funEntryExp (id, codeEntryTy, loc),
                      expTy = T.BACKENDty (T.FUNENTRYty codeEntryTy),
                      targetTy = T.BACKENDty T.SOME_FUNENTRYty,
                      cast = BuiltinPrimitive.BitCast,
                      loc = loc}
        val cconvWordExp =
            C.CCCAST {exp = cconvTagExp (codeEntryTy, loc),
                      expTy = T.BACKENDty (T.CCONVTAGty codeEntryTy),
                      targetTy = BuiltinTypes.word32Ty,
                      cast = BuiltinPrimitive.TypeCast,
                      loc = loc}
        val wrapperExp = funWrapperExp (id, codeEntryTy, loc)
        val fields =
            map (fn (exp, ty) =>
                    {exp = exp,
                     ty = ty,
                     tag = SingletonTyEnv2.findTag styEnv ty,
                     size = case SingletonTyEnv2.constSize styEnv ty of
                              SOME x => x
                            | NONE => raise Bug.Bug "makeClosureRecord"})
                [(closureEnvExp, T.BACKENDty T.SOME_CLOSUREENVty),
                 (entryExp, T.BACKENDty T.SOME_FUNENTRYty),
                 (wrapperExp, T.BACKENDty T.SOME_FUNWRAPPERty)]
        val accum = newAccum ()
        val record = makeTuple accum fields loc
        val _ = checkNoExtraComputation accum
        (* pack CCONVTAG into record bitmap *)
        val bitmaps =
            case #bitmaps record of
              [{bitmapIndex, bitmapExp}] =>
              [{bitmapIndex = bitmapIndex,
                bitmapExp = addExtraBitmapBit (#recordTy record, bitmapExp,
                                               cconvWordExp, loc)}]
            | _ => raise Bug.Bug "makeClosureRecord"
        val record = record # {bitmaps = bitmaps}
        val (top1, recordExp) = allocRecord (styEnv, path) record
      in
        (top1,
         C.CCCAST {exp = recordExp,
                   expTy = #recordTy record,
                   targetTy = resultTy,
                   cast = BuiltinPrimitive.TypeCast,
                   loc = loc})
      end

  fun decomposeClosureRecord (funExp, funTy) loc =
      let
        val styEnv = SingletonTyEnv2.emptyEnv
        val accum = newAccum ()
        val {fieldList, recordTy, allocSizeExp, bitmaps} =
            computeTupleLayout
              accum
              (map (fn ty =>
                       {tag = SingletonTyEnv2.findTag styEnv ty,
                        size = case SingletonTyEnv2.constSize styEnv ty of
                                 SOME x => x
                               | NONE => raise Bug.Bug "decomposeClosureRecord",
                        ty = ty})
                   [T.BACKENDty T.SOME_CLOSUREENVty,
                    T.BACKENDty T.SOME_FUNENTRYty,
                    T.BACKENDty T.SOME_FUNWRAPPERty])
              loc
        val _ = checkNoExtraComputation accum
        val recordExp = C.CCCAST {exp = funExp,
                                  expTy = funTy,
                                  targetTy = recordTy,
                                  cast = BuiltinPrimitive.TypeCast,
                                  loc = loc}
        val selectExps =
            map (fn {fieldLabel, fieldIndex, fieldSize, fieldTy, fieldTag} =>
                    C.CCSELECT {recordExp = recordExp,
                                indexExp = fieldIndex,
                                label = fieldLabel,
                                recordTy = recordTy,
                                resultTy = fieldTy,
                                resultSize = fieldSize,
                                resultTag = fieldTag,
                                loc = loc})
                fieldList
        val (closureEnvExp, entryExp, wrapperExp, {bitmapIndex,...}) =
            case (selectExps, bitmaps) of
              ([a, b, c], [d]) => (a, b, c, d)
            | _ => raise Bug.Bug "decomposeClosureRecord"
        val cconvtagExp =
            C.CCCAST
              {exp = word32_andb
                       (readBitmap0 (recordTy, recordExp, bitmapIndex, loc),
                        wordConst 0wx80000000 loc,
                        loc),
               expTy = BuiltinTypes.word32Ty,
               targetTy = T.BACKENDty T.SOME_CCONVTAGty,
               cast = BuiltinPrimitive.TypeCast,
               loc = loc}
      in
        {codeExp = entryExp,
         closureEnvExp = closureEnvExp,
         cconv = C.DYNAMICCALL {cconvTag = cconvtagExp, wrapper = wrapperExp}}
      end

  datatype staticEvalResult =
      CLOSURE of static_closure
    | RECCLOSURE of static_closure
    | EXFUNENTRY of {id : ExternFunSymbol.id, codeEntryTy : T.codeEntryTy}
    | VALUE   (* any others *)

  type varEnv = (C.varInfo * C.ccconst option * staticEvalResult) VarID.Map.map

  type env =
      {
        varEnv: varEnv,
        styEnv: SingletonTyEnv2.env,
        path: Symbol.longsymbol,
        toplevel: bool
      }

  val emptyVarEnv = VarID.Map.empty : varEnv
  fun extendVarEnv (varEnv1, varEnv2) : varEnv =
      VarID.Map.unionWith #2 (varEnv1, varEnv2)

  fun extendEnv ({varEnv, styEnv, path, toplevel}:env, varEnv2) : env =
      {varEnv = VarID.Map.unionWith #2 (varEnv, varEnv2),
       styEnv = SingletonTyEnv2.bindVars
                  (styEnv, map #1 (VarID.Map.listItems varEnv2)),
       path = path,
       toplevel = toplevel}

  fun addBoundVars ({varEnv, styEnv, path, toplevel}:env, vars) : env =
      {varEnv = foldl (fn (v as {id,ty,...}:C.varInfo,varEnv) =>
                          VarID.Map.insert (varEnv, id, (v, NONE, VALUE)))
                      varEnv
                      vars,
       styEnv = SingletonTyEnv2.bindVars (styEnv, vars),
       path = path,
       toplevel = toplevel}

  fun addBoundTyvars ({varEnv, styEnv, path, toplevel}:env, btvEnv) : env =
      {varEnv = varEnv,
       styEnv = SingletonTyEnv2.bindTyvars (styEnv, btvEnv),
       path = path,
       toplevel = toplevel}

  fun setPath (env as {varEnv, styEnv, path, toplevel}:env, newPath) : env =
      case newPath of
        nil => env
      | _::_ =>
        {varEnv = varEnv, styEnv = styEnv, path = newPath, toplevel = toplevel}

  fun enterFunction ({varEnv, styEnv, path, toplevel}:env) : env =
      {varEnv = varEnv, styEnv = styEnv, path = path, toplevel = false}

  fun constTy const =
      case const of
        R.INT (L.INT8 n) => BuiltinTypes.int8Ty
      | R.INT (L.INT16 n) => BuiltinTypes.int16Ty
      | R.INT (L.INT32 n) => BuiltinTypes.int32Ty
      | R.INT (L.INT64 n) => BuiltinTypes.int64Ty
      | R.INT (L.WORD8 n) => BuiltinTypes.word8Ty
      | R.INT (L.WORD16 n) => BuiltinTypes.word16Ty
      | R.INT (L.WORD32 n) => BuiltinTypes.word32Ty
      | R.INT (L.WORD64 n) => BuiltinTypes.word64Ty
      | R.INT (L.CONTAG n) => BuiltinTypes.contagTy
      | R.CONST (L.REAL64 n) => BuiltinTypes.real64Ty
      | R.CONST (L.REAL32 n) => BuiltinTypes.real32Ty
      | R.INT (L.CHAR c) => BuiltinTypes.charTy
      | R.CONST L.UNIT => BuiltinTypes.unitTy
      | R.CONST L.NULLPOINTER => T.CONSTRUCTty {tyCon = BuiltinTypes.ptrTyCon,
                                                args = [BuiltinTypes.unitTy]}
      | R.CONST L.NULLBOXED => BuiltinTypes.boxedTy
      | R.CONST (L.FOREIGNSYMBOL {name, ty}) => ty
      | R.TAG (n, ty) => T.SINGLETONty (T.TAGty ty)
      | R.SIZE (n, ty) => T.SINGLETONty (T.SIZEty ty)

  fun compileTlint const =
      case const of
        L.INT8 n => C.CVINT8 n
      | L.INT16 n => C.CVINT16 n
      | L.INT32 n => C.CVINT32 n
      | L.INT64 n => C.CVINT64 n
      | L.WORD8 n => C.CVWORD8 n
      | L.WORD16 n => C.CVWORD16 n
      | L.WORD32 n => C.CVWORD32 n
      | L.WORD64 n => C.CVWORD64 n
      | L.CONTAG n => C.CVCONTAG n
      | L.CHAR c => C.CVCHAR c

  fun compileTlconst const =
      case const of
        L.REAL64 n => C.CVREAL64 n
      | L.REAL32 n => C.CVREAL32 n
      | L.UNIT => C.CVUNIT
      | L.NULLPOINTER => C.CVNULLPOINTER
      | L.NULLBOXED => C.CVNULLBOXED
      | L.FOREIGNSYMBOL {name, ty} => C.CVFOREIGNSYMBOL {name=name, ty=ty}

  fun compileConst const =
      case const of
        R.INT c => compileTlint c
      | R.CONST c => compileTlconst c
      | R.TAG (n, ty) => C.CVTAG {tag = n, ty = ty}
      | R.SIZE (n, ty) => C.CVSIZE {size = n, ty = ty}

  fun getFunTy ty =
      case TypesBasics.derefTy ty of
        T.FUNMty (argTys, retTy) =>
        SOME {tyvars = BoundTypeVarID.Map.empty,
              argTyList = argTys,
              retTy = retTy}
      | T.POLYty {boundtvars, constraints, body} =>
        (case getFunTy body of
           NONE => NONE
         | SOME {tyvars, argTyList, retTy} =>
           SOME {tyvars = BoundTypeVarID.Map.unionWith #2 (boundtvars, tyvars),
                 argTyList =argTyList,
                 retTy = retTy})
      | _ => NONE

  fun exFunCodeEntryTy styEnv {tyvars, argTyList, retTy} : T.codeEntryTy =
      {tyvars = BoundTypeVarID.Map.unionWith
                  #2 (SingletonTyEnv2.btvEnv styEnv, tyvars),
       haveClsEnv = false,
       argTyList = argTyList,
       retTy = retTy}

  fun exportFunEntry (styEnv, path) (exvar as {ty, loc, ...}, value) =
      case getFunTy ty of
        NONE => nil
      | SOME (fty as {argTyList, retTy, ...}) =>
        let
          val codeEntryTy = exFunCodeEntryTy styEnv fty
          val funTy = T.FUNMty (argTyList, retTy)
          val funExp = C.CCCAST {exp = C.CCEXVAR exvar,
                                 expTy = ty,
                                 targetTy = funTy,
                                 cast = BuiltinPrimitive.TypeCast,
                                 loc = loc}
          val staticCls =
              case value of
                CLOSURE x => SOME x
              | RECCLOSURE x => SOME x
              | EXFUNENTRY _ => NONE
              | VALUE => NONE
          val (call, funId) =
              case staticCls of
                NONE =>
                (SOME (decomposeClosureRecord (funExp, funTy) loc),
                 FunEntryLabel.generate path)
              | SOME {id, closureEnvVar = NONE, ...} => (NONE, id)
              | SOME cls =>
                let
                  val {codeExp, cconv, ...} = decomposeStaticClosure cls loc
                  val {closureEnvExp, ...} =
                      decomposeClosureRecord (funExp, funTy) loc
                in
                  (SOME {codeExp=codeExp, cconv=cconv,
                         closureEnvExp=closureEnvExp},
                   FunEntryLabel.generate path)
                end
          val top =
              DATA (C.CTEXPORTFUN {id = ExternFunSymbol.touch path,
                                   funId = funId,
                                   loc = loc})
        in
          case call of
            NONE => [top]
          | SOME {codeExp, cconv, closureEnvExp} =>
            let
              val argVarList = map newVar argTyList
            in
              [top,
               DEC (C.CTFUNCTION
                      {id = funId,
                       tyvarKindEnv = #tyvars codeEntryTy,
                       argVarList = argVarList,
                       closureEnvVar = NONE,
                       bodyExp =
                         C.CCCALL
                           {codeExp = codeExp,
                            closureEnvExp = closureEnvExp,
                            argExpList =
                              map (fn v => C.CCVAR {varInfo=v, loc=loc})
                                  argVarList,
                            cconv = cconv,
                            funTy = funTy,
                            loc = loc},
                       retTy = retTy,
                       loc = loc})]
            end
        end

  fun compileExp accum env bcexp =
      case bcexp of
        B.BCFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        let
          val (top1, _, funExp) = compileExp accum env funExp
          val (top2, argExpList) = compileExpList accum env argExpList
        in
          (top1 @ top2,
           VALUE,
           C.CCFOREIGNAPPLY {funExp = funExp,
                             attributes = attributes,
                             argExpList = argExpList,
                             resultTy = resultTy,
                             loc = loc})
        end
      | B.BCCALLBACKFN {attributes, resultTy, argVarList, bodyExp, loc} =>
        let
          val env = addBoundVars (env, argVarList)
          val (top1, bodyExp) = compileFuncBody env bodyExp loc
          val fv = freeVarsFn (argVarList, bodyExp)
          val (closureEnv, subst) = computeClosure accum (#styEnv env) (fv, loc)
          val tyvarKindEnv = SingletonTyEnv2.btvEnv (#styEnv env)
          val id = CallbackEntryLabel.generate (#path env)
          val func = {id = id,
                      tyvarKindEnv = tyvarKindEnv,
                      argVarList = argVarList,
                      closureEnvVar = Option.map #1 closureEnv,
                      bodyExp = substExp subst bodyExp,
                      attributes = attributes,
                      retTy = resultTy,
                      loc = loc}
          val entryTy = {tyvars = tyvarKindEnv,
                         haveClsEnv = isSome closureEnv,
                         argTyList = map #ty argVarList,
                         retTy = resultTy,
                         attributes = attributes}
          val callbackEntryTy = T.BACKENDty (T.CALLBACKENTRYty entryTy)
          val funPtrTy =
              T.BACKENDty (T.FOREIGNFUNPTRty
                             {argTyList = #argTyList entryTy,
                              varArgTyList = NONE,
                              resultTy = #retTy entryTy,
                              attributes = #attributes entryTy})
          val codeExp =
              C.CCCONST {const = C.CVCALLBACKENTRY
                                   {id = id, callbackEntryTy = entryTy},
                         ty = callbackEntryTy,
                         loc = loc}
        in
          (top1 @ [DEC (C.CTCALLBACKFUNCTION func)],
           VALUE,
           case closureEnv of
             NONE =>
             (* no need to make a C closure *)
             C.CCCAST {exp = codeExp,
                       expTy = callbackEntryTy,
                       targetTy = funPtrTy,
                       cast = BuiltinPrimitive.BitCast,
                       loc = loc}
           | SOME (_, closureEnvExp) =>
             C.CCEXPORTCALLBACK {codeExp = codeExp,
                                 closureEnvExp = closureEnvExp,
                                 instTyvars = tyvarKindEnv,
                                 resultTy = funPtrTy,
                                 loc = loc})
        end
      | B.BCSTRING {string = L.STRING s, loc} =>
        let
          val id = DataLabel.generate (#path env)
        in
          ([DATA (C.CTSTRING {id = id, string = s, loc = loc})],
           VALUE,
           C.CCCONST {const = C.CVTOPDATA {id = id, ty = BuiltinTypes.stringTy},
                      ty = BuiltinTypes.stringTy,
                      loc = loc})
        end
      | B.BCSTRING {string = L.INTINF n, loc} =>
        let
          val id = ExtraDataLabel.generate (#path env)
        in
          ([DATA (C.CTINTINF {id = id, value = n, loc = loc})],
           VALUE,
           C.CCINTINF {srcLabel = id, loc = loc})
        end
      | B.BCCONSTANT {const = const, loc} =>
        let
          val ty = constTy const
          val const = compileConst const
        in
          (nil, VALUE, C.CCCONST {const = const, ty = ty, loc = loc})
        end
      | B.BCVAR {varInfo, loc} =>
        (
          case VarID.Map.find (#varEnv env, #id varInfo) of
            SOME ({ty,...}, SOME const, cls) =>
            (nil, cls, C.CCCONST {const=const, ty=ty, loc=loc})
          | SOME ({ty,...}, NONE, RECCLOSURE cls) =>
            let
              val (top1, recordExp) =
                  makeClosureRecord (#styEnv env, #path env) (cls, ty) loc
            in
              (top1, CLOSURE cls, recordExp)
            end
          | SOME (_, NONE, cls) =>
            (nil, cls, C.CCVAR {varInfo=varInfo, loc=loc})
          | NONE => raise Bug.Bug ("compileExp: BCVAR "
                                   ^ VarID.toString (#id varInfo))
        )
      | B.BCEXVAR {exVarInfo as {path,ty}, loc} =>
        (nil,
         case getFunTy ty of
           NONE => VALUE
         | SOME x =>
           EXFUNENTRY {id = ExternFunSymbol.touch path,
                       codeEntryTy = exFunCodeEntryTy (#styEnv env) x},
         C.CCEXVAR {id = ExternSymbol.touch path, ty = ty, loc = loc})
      | B.BCPRIMAPPLY {primInfo as {primitive,...}, argExpList, instTyList,
                       instTagList, instSizeList, loc} =>
        let
          val (top1, argExpList) = compileExpList accum env argExpList
          val (top2, instTagList) = compileExpList accum env instTagList
          val (top3, instSizeList) = compileExpList accum env instSizeList
          val top = top1 @ top2 @ top3
          val origResultExp =
              C.CCPRIMAPPLY {primInfo = primInfo,
                             argExpList = argExpList,
                             instTyList = instTyList,
                             instTagList = instTagList,
                             instSizeList = instSizeList,
                             loc = loc}
          fun array_alloc (mutable, coalescable, ty, tag, size, args, len) =
              let
                val (top4, arrayExp) =
                    allocArray (#path env)
                               {elemTy = ty,
                                isMutable = mutable,
                                isCoalescable = coalescable,
                                clearPad = false,
                                initialElements = args,
                                numElements = case len of
                                                NONE => intExp (length args) loc
                                              | SOME e => e,
                                elemSizeExp = size,
                                tagExp = tag,
                                loc = loc}
                               origResultExp
              in
                (top @ top4, VALUE, arrayExp)
              end
        in
          case (#toplevel env, primitive, instTyList,
                instTagList, instSizeList, argExpList) of
            (true, P.Array_alloc_init, [ty], [tag], [size], args) =>
            (* only toplevel arrays can be allocated statically *)
            array_alloc (true, false, ty, tag, size, args, NONE)
          | (true, P.R P.Array_alloc_unsafe, [ty], [tag], [size], [lenExp]) =>
            array_alloc (true, false, ty, tag, size, nil, SOME lenExp)
          | (true, P.Vector_alloc_init_fresh, [ty], [tag], [size], args) =>
            array_alloc (false, false, ty, tag, size, args, NONE)
          | (_, P.Vector_alloc_init, [ty], [tag], [size], args) =>
            array_alloc (false, true, ty, tag, size, args, NONE)
          | _ =>
            (top, VALUE, origResultExp)
        end
      | B.BCAPPM {funExp, argExpList, funTy, loc} =>
        let
          val (top1, c, funExp) = compileExp accum env funExp
          val (top2, argExpList) = compileExpList accum env argExpList
          val (letFn, {codeExp, closureEnvExp, cconv}) =
              case c of
                CLOSURE x => (fn x => x, decomposeStaticClosure x loc)
              | RECCLOSURE x => (fn x => x, decomposeStaticClosure x loc)
              | EXFUNENTRY x => (fn x => x, decomposeExFunEntry x loc)
              | VALUE =>
                let
                  val (letFn, funExp) = makeBind (funExp, funTy, loc)
                in
                  (letFn, decomposeClosureRecord (funExp, funTy) loc)
                end
        in
          (top1 @ top2,
           VALUE,
           letFn (C.CCCALL {codeExp = codeExp,
                            closureEnvExp = closureEnvExp,
                            argExpList = argExpList,
                            cconv = cconv,
                            funTy = funTy,
                            loc = loc}))
        end
      | B.BCLET {localDecl, mainExp, loc} =>
        let
          val (top1, varenv1, bindList) = compileDecl accum env localDecl
          val (top2, c, mainExp) =
              compileExp accum (extendEnv (env, varenv1)) mainExp
          val top = top1 @ top2
        in
          case (bindList, c) of
            (nil, _) => (top, c, mainExp)
          | (_::_, _) => (top, VALUE, Let (bindList, mainExp))
        end
      | B.BCRECORD {fieldList, recordTy, isMutable, clearPad, allocSizeExp,
                    bitmaps, loc} =>
        let
          val (top1, fieldList) = compileFieldList accum env fieldList
          val (top2, _, allocSizeExp) = compileExp accum env allocSizeExp
          val (top3, bitmaps) = compileBitmapList accum env bitmaps
          val (top4, recordExp) =
              allocRecord (#styEnv env, #path env)
                          {fieldList = fieldList,
                           recordTy = recordTy,
                           isMutable = isMutable,
                           clearPad = clearPad,
                           allocSizeExp = allocSizeExp,
                           bitmaps = bitmaps,
                           loc = loc}
        in
          (top1 @ top2 @ top3 @ top4,
           VALUE,
           recordExp)
        end
      | B.BCSELECT {recordExp, indexExp, label, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        let
          val (top1, _, recordExp) = compileExp accum env recordExp
          val (top2, _, indexExp) = compileExp accum env indexExp
          val (top3, _, resultSize) = compileExp accum env resultSize
          val (top4, _, resultTag) = compileExp accum env resultTag
        in
          (top1 @ top2 @ top3 @ top4,
           VALUE,
           C.CCSELECT {recordExp = recordExp,
                       label = label,
                       indexExp = indexExp,
                       recordTy = recordTy,
                       resultTy = resultTy,
                       resultSize = resultSize,
                       resultTag = resultTag,
                       loc = loc})
        end
      | B.BCMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    valueTag, valueSize, loc} =>
        let
          val (top1, _, recordExp) = compileExp accum env recordExp
          val (top2, _, indexExp) = compileExp accum env indexExp
          val (top3, _, valueExp) = compileExp accum env valueExp
          val (top4, _, valueTag) = compileExp accum env valueTag
          val (top5, _, valueSize) = compileExp accum env valueSize
        in
          (top1 @ top2 @ top3 @ top4 @ top5,
           VALUE,
           C.CCMODIFY {recordExp = recordExp,
                       recordTy = recordTy,
                       indexExp = indexExp,
                       label = label,
                       valueExp = valueExp,
                       valueTy = valueTy,
                       valueTag = valueTag,
                       valueSize = valueSize,
                       loc = loc})
        end
      | B.BCRAISE {argExp, resultTy, loc} =>
        let
          val (top1, _, argExp) = compileExp accum env argExp
        in
          (top1,
           VALUE,
           C.CCRAISE {argExp = argExp,
                      resultTy = resultTy,
                      loc = loc})
        end
      | B.BCHANDLE {tryExp, exnVar, handlerExp, resultTy, loc} =>
        let
          val (top1, _, tryExp) = compileExp accum env tryExp
          val env = addBoundVars (env, [exnVar])
          val (top2, _, handlerExp) = compileExp accum env handlerExp
        in
          (top1 @ top2,
           VALUE,
           C.CCHANDLE {tryExp = tryExp,
                       exnVar = exnVar,
                       handlerExp = handlerExp,
                       resultTy = resultTy,
                       loc = loc})
        end
      | B.BCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val (top1, rules) = compileCatchRules accum env rules
          val (top2, _, tryExp) = compileExp accum env tryExp
        in
          (top1 @ top2,
           VALUE,
           C.CCCATCH {recursive = recursive,
                      rules = rules,
                      tryExp = tryExp,
                      resultTy = resultTy,
                      loc = loc})
        end
      | B.BCTHROW {catchLabel, argExpList, resultTy, loc} =>
        let
          val (top1, argExpList) = compileExpList accum env argExpList
        in
          (top1,
           VALUE,
           C.CCTHROW {catchLabel = catchLabel,
                      argExpList = argExpList,
                      resultTy = resultTy,
                      loc = loc})
        end
      | B.BCFNM {argVarList, bodyExp, retTy, loc} =>
        let
          val var = newVar (T.FUNMty (map #ty argVarList, retTy))
          val decl = B.BCVAL {boundVar = var, boundExp = bcexp, loc = loc}
        in
          compileExp accum env
                     (B.BCLET {localDecl = decl,
                               mainExp = B.BCVAR {varInfo=var, loc=loc},
                               loc = loc})
        end
      | B.BCPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
        let
          val env = addBoundTyvars (env, btvEnv)
          val (top1, c, exp) = compileExp accum env exp
        in
          (top1, c,
           C.CCCAST {exp = exp,
                     expTy = expTyWithoutTAbs,
                     targetTy = T.POLYty {boundtvars=btvEnv,
                                          constraints = constraints,
                                          body=expTyWithoutTAbs},
                     cast = BuiltinPrimitive.TypeCast,
                     loc = loc})
        end
      | B.BCTAPP {exp, expTy, instTyList, loc} =>
        let
          val (top1, c, exp) = compileExp accum env exp
        in
          (top1, c,
           C.CCCAST {exp = exp,
                     expTy = expTy,
                     targetTy = TypesBasics.tpappTy (expTy, instTyList),
                     cast = BuiltinPrimitive.TypeCast,
                     loc = loc})
        end
      | B.BCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val (top1, _, switchExp) = compileExp accum env switchExp
          val (top2, branches) = compileBranches accum env branches loc
          val (top3, _, defaultExp) = compileExp accum env defaultExp
        in
          (top1 @ top2 @ top3,
           VALUE,
           C.CCSWITCH {switchExp = switchExp,
                       expTy = expTy,
                       branches = branches,
                       defaultExp = defaultExp,
                       resultTy = resultTy,
                       loc = loc})
        end
      | B.BCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val (top1, value, exp) = compileExp accum env exp
        in
          (top1,
           VALUE,
           C.CCCAST {exp = exp,
                     expTy = expTy,
                     targetTy = targetTy,
                     cast = cast,
                     loc = loc})
        end

  and compileExpList accum env nil = (nil, nil)
    | compileExpList accum env (exp::exps) =
      let
        val (top1, _, exp) = compileExp accum env exp
        val (top2, exps) = compileExpList accum env exps
      in
        (top1 @ top2, exp::exps)
      end

  and compileBranches accum env nil loc = (nil, nil)
    | compileBranches accum env ({constant,branchExp}::branches) loc =
      let
        val const = compileTlint constant
        val (top1, _, branchExp) = compileExp accum env branchExp
        val (top2, branches) = compileBranches accum env branches loc
      in
        (top1 @ top2,
         {constant = const, branchExp = branchExp} :: branches)
      end

  and compileFieldList accum env nil = (nil, nil)
    | compileFieldList accum env ({fieldExp, fieldTy, fieldLabel, fieldSize,
                                   fieldTag, fieldIndex}::fields) =
      let
        val (top1, _, fieldExp) = compileExp accum env fieldExp
        val (top2, _, fieldSize) = compileExp accum env fieldSize
        val (top3, _, fieldTag) = compileExp accum env fieldTag
        val (top4, _, fieldIndex) = compileExp accum env fieldIndex
        val (top5, fields) = compileFieldList accum env fields
      in
        (top1 @ top2 @ top3 @ top4 @ top5,
         {fieldExp = fieldExp,
          fieldTy = fieldTy,
          fieldLabel = fieldLabel,
          fieldSize = fieldSize,
          fieldTag = fieldTag,
          fieldIndex = fieldIndex}::fields)
      end

  and compileBitmapList accum env nil = (nil, nil)
    | compileBitmapList accum env ({bitmapIndex, bitmapExp}::bitmaps) =
      let
        val (top1, _, bitmapIndex) = compileExp accum env bitmapIndex
        val (top2, _, bitmapExp) = compileExp accum env bitmapExp
        val (top3, bitmaps) = compileBitmapList accum env bitmaps
      in
        (top1 @ top2 @ top3,
         {bitmapIndex = bitmapIndex,
          bitmapExp = bitmapExp} :: bitmaps)
      end

  and compileCatchRules accum env nil = (nil, nil)
    | compileCatchRules accum env ({catchLabel, argVarList, catchExp}::rules) =
      let
          val env2 = addBoundVars (env, argVarList)
          val (top1, _, catchExp) = compileExp accum env2 catchExp
          val (top2, rules) = compileCatchRules accum env rules
      in
        (top1 @ top2,
         {catchLabel = catchLabel,
          argVarList = argVarList,
          catchExp = catchExp} :: rules)
      end

  and compileFuncBody env bodyExp loc =
      let
        val accum = newAccum ()
        val (top, _, bodyExp) = compileExp accum env bodyExp
      in
        (top, extractDecls (accum, bodyExp, loc))
      end

  and compileFunc accum env (boundVar, {argVarList, bodyExp, retTy, loc}) =
      let
        val env = addBoundVars (env, argVarList)
        val env = setPath (env, #path boundVar)
        val (top1, bodyExp) = compileFuncBody (enterFunction env) bodyExp loc
        val fv = freeVarsFn (argVarList, bodyExp)
        val (closureEnv, subst) = computeClosure accum (#styEnv env) (fv, loc)
        val closureEnvVar =
            case closureEnv of
              NONE => NONE
            | SOME (closureEnvVar, _) => SOME closureEnvVar
        val tyvarKindEnv = SingletonTyEnv2.btvEnv (#styEnv env)
        val id = FunEntryLabel.generate (#path env)
        val func = {id = id,
                    tyvarKindEnv = tyvarKindEnv,
                    argVarList = argVarList,
                    closureEnvVar = closureEnvVar,
                    bodyExp = substExp subst bodyExp,
                    retTy = retTy,
                    loc = loc}
        val top2 = [DEC (C.CTFUNCTION func)]
        val funTy = T.FUNMty (map #ty argVarList, retTy)
        val closure : static_closure =
            {id = id,
             closureEnvVar = Option.map #1 closureEnv,
             codeEntryTy = {tyvars = tyvarKindEnv,
                            haveClsEnv = isSome closureEnvVar,
                            argTyList = map #ty argVarList,
                            retTy = retTy}}
        val (top3, recordExp) =
            makeClosureRecord (#styEnv env, #path env)
                              (closure, #ty boundVar)
                              loc
        val (binds1, varenv1) =
            case closureEnv of
              NONE => (nil, emptyVarEnv)
            | SOME (var, exp) => valbind (var, exp, VALUE, loc)
        val (binds2, varenv2) =
            valbind (boundVar, recordExp, CLOSURE closure, loc)
      in
        (top1 @ top2 @ top3,
         extendVarEnv (varenv1, varenv2),
         binds1 @ binds2)
      end

  and compileRecfunBinds env nil = (nil, nil)
    | compileRecfunBinds env ({boundVar, boundtvars, closure, func}::recfuns) =
      let
        val {argVarList, bodyExp, retTy : T.ty, loc} = func
        val env = addBoundTyvars (env, boundtvars)
        val env = addBoundVars (env, argVarList)
        val env = setPath (env, #path boundVar)
        val (top1, bodyExp) = compileFuncBody (enterFunction env) bodyExp loc
        val (top2, recfuns) = compileRecfunBinds env recfuns
      in
        (top1 @ top2,
         {boundVar = boundVar : C.varInfo,
          closure = closure : static_closure,
          func = {argVarList = argVarList,
                  bodyExp = bodyExp,
                  retTy = retTy,
                  loc = loc}}
         :: recfuns)
      end

  and compileDecl accum env bcdecl =
      case bcdecl of
        B.BCEXTERNVAR {exVarInfo as {path,ty}, provider, loc} =>
        (DATA (C.CTEXTERNVAR
                 {id = ExternSymbol.touch path,
                  ty = ty,
                  provider = provider,
                  loc = loc})
         :: (case getFunTy ty of
               NONE => nil
             | SOME {tyvars, argTyList, retTy} =>
               [DATA (C.CTEXTERNFUN {id = ExternFunSymbol.touch path,
                                     tyvars = tyvars,
                                     argTyList = argTyList,
                                     retTy = retTy,
                                     provider = provider,
                                     loc = loc})]),
         emptyVarEnv,
         nil)
      | B.BCEXPORTVAR {weak, exVarInfo={path,ty}, exp, loc} =>
        let
          val env = setPath (env, path)
          val (top1, c, exp) = compileExp accum env exp
          val value = SOME (expToConst exp) handle ExpToConst => NONE
          val id = ExternSymbol.touch path
          val binds =
              case value of
                SOME _ => nil
              | NONE =>
                [{boundVar = newVar BuiltinTypes.unitTy,
                  boundExp = C.CCEXPORTVAR
                               {id=id, ty=ty, valueExp=exp, loc=loc},
                  loc = loc}]
          val top2 =
              if weak
              then nil
              else exportFunEntry (#styEnv env, path)
                                  ({id=id, ty=ty, loc=loc}, c)
          val top3 =
              [DATA (C.CTEXPORTVAR {id=id, weak=weak, ty=ty, value=value,
                                    loc=loc})]
        in
          (top1 @ top2 @ top3, emptyVarEnv, binds)
        end
      | B.BCVAL {boundVar, boundExp = B.BCFNM func, loc} =>
        compileFunc accum env (boundVar, func)
      | B.BCVAL {boundVar,
                 boundExp = B.BCPOLY {btvEnv,
                                      constraints,
                                      exp=B.BCFNM func,
                                      expTyWithoutTAbs,
                                      loc=_},
                 loc} =>
        compileFunc accum (addBoundTyvars (env, btvEnv)) (boundVar, func)
      | B.BCVAL {boundVar, boundExp, loc} =>
        let
          val env = setPath (env, #path boundVar)
          val (top1, c, boundExp) = compileExp accum env boundExp
          val (binds, varenv1) = valbind (boundVar, boundExp, c, loc)
        in
          (top1, varenv1, binds)
        end
      | B.BCVALREC {recbindList, loc} =>
        let
          (* tmpEnvVar is to be substituted with actual closure environemnt *)
          val tmpEnvVar = newVar (T.BACKENDty T.SOME_CLOSUREENVty)
          val tyvarKindEnv = SingletonTyEnv2.btvEnv (#styEnv env)
          val recfunBinds =
              map
                (fn {boundVar : B.varInfo, boundExp} =>
                    let
                      val (boundtvars, func as {argVarList, retTy, ...}) =
                          case boundExp of
                            B.BCFNM f => (BoundTypeVarID.Map.empty, f)
                          | B.BCPOLY {btvEnv, exp=B.BCFNM f, ...} => (btvEnv, f)
                          | _ => raise Bug.Bug "prepareRecfunBinds"
                      val codeEntryTy =
                          {tyvars = BoundTypeVarID.Map.unionWith
                                      #2 (tyvarKindEnv, boundtvars),
                           haveClsEnv = true,
                           argTyList = map #ty argVarList,
                           retTy = retTy}
                    in
                      {boundVar = boundVar,
                       boundtvars = boundtvars,
                       closure = {id = FunEntryLabel.generate (#path boundVar),
                                  closureEnvVar = SOME tmpEnvVar,
                                  codeEntryTy = codeEntryTy} : static_closure,
                       func = func}
                    end)
                recbindList
          val recfunVarEnv =
              foldl
                (fn ({boundVar as {id,...}, closure, func, ...}, varEnv) =>
                    VarID.Map.insert
                      (varEnv, id, (boundVar, NONE, RECCLOSURE closure)))
                emptyVarEnv
                recfunBinds
          val env1 = extendEnv (env, recfunVarEnv)
          val (top1, newRecfunBinds) = compileRecfunBinds env1 recfunBinds
          val fv = foldl (fn ({func={argVarList, bodyExp, ...}, ...}, fv) =>
                             unionSet (fv, freeVarsFn (argVarList, bodyExp)))
                         emptySet
                         newRecfunBinds
          val fv = minusSet (fv, singletonSet tmpEnvVar)
          val (closureEnv, subst) = computeClosure accum (#styEnv env) (fv, loc)
          val closureEnvVar = Option.map #1 closureEnv
          val newRecfunBinds =
              map (fn {boundVar, closure, func} =>
                      {boundVar = boundVar,
                       closure = replaceClosureEnvVar (closure, closureEnvVar),
                       func = func})
                  newRecfunBinds
          val tyvarKindEnv = SingletonTyEnv2.btvEnv (#styEnv env)

          fun makeTopFunctions subst binds =
              map
                (fn {boundVar : C.varInfo,
                     closure={id, closureEnvVar, codeEntryTy} : static_closure,
                     func={argVarList, bodyExp, retTy, loc}} =>
                    DEC (C.CTFUNCTION
                           {id = id,
                            tyvarKindEnv = #tyvars codeEntryTy,
                            argVarList = argVarList,
                            closureEnvVar = closureEnvVar,
                            bodyExp = substExp subst bodyExp,
                            retTy = retTy,
                            loc = loc}))
                binds

          fun makeRecClsBinds nil = (nil, nil)
            | makeRecClsBinds ({boundVar:C.varInfo, closure, func}::binds) =
              let
                val (top1, exp) =
                    makeClosureRecord (#styEnv env, #path boundVar)
                                      (closure, #ty boundVar)
                                      loc
                val (top2, binds) = makeRecClsBinds binds
              in
                (top1 @ top2,
                 {boundVar = boundVar, boundExp = exp, loc = loc}::binds)
              end

        in
          case closureEnv of
            SOME (closureEnvVar, closureEnvExp) =>
            let
              val envVarExp = C.CCVAR {varInfo=closureEnvVar, loc=loc}
              val subst = VarID.Map.insert (subst, #id tmpEnvVar, envVarExp)
              val top2 = makeTopFunctions subst newRecfunBinds
              val (top3, binds) = makeRecClsBinds newRecfunBinds
              val binds =
                  {boundVar=closureEnvVar, boundExp=closureEnvExp, loc=loc}
                  :: binds
              val varenv1 =
                  foldl
                    (fn ({boundVar as {id,...}, closure, ...}, varenv) =>
                        VarID.Map.insert
                          (varenv, id, (boundVar, NONE, CLOSURE closure)))
                    emptyVarEnv
                    newRecfunBinds
            in
              (top1 @ top2, varenv1, binds)
            end
          | NONE =>
            let
              val recfunBinds =
                  map (fn x as {boundVar, boundtvars, closure, func} =>
                          x # {closure = replaceClosureEnvVar (closure, NONE)})
                      recfunBinds
              (* these closures can be allocated statically *)
              val (top1, binds) = makeRecClsBinds newRecfunBinds
              (* every boundVar should bind a value. No binding list should
               * be returned. *)
              val varEnv =
                  ListPair.foldlEq
                    (fn ({closure,...}, {boundVar, boundExp,...}, varenv) =>
                        VarID.Map.insert
                          (varenv, #id boundVar,
                           (boundVar, SOME (#1 (expToConst boundExp)),
                            CLOSURE closure)))
                    emptyVarEnv
                    (newRecfunBinds, binds)
                  handle ExpToConst => raise Bug.Bug "compileDecl: BCVALREC"
              (* compile again without closure environment variable.
               * This yields more chances for static allocation. *)
              val env1 = extendEnv (env, varEnv)
              val (top2, newRecfunBinds) = compileRecfunBinds env1 recfunBinds
              (* newRecfunBinds should have no free variable.
               * No need to compute closure here. *)
              val top3 = makeTopFunctions VarID.Map.empty newRecfunBinds
            in
              (top1 @ top2 @ top3, varEnv, nil)
            end
        end

  fun compileDeclList accum env nil = (nil, emptyVarEnv, nil)
    | compileDeclList accum env (decl::decls) =
      let
        val (top1, varenv1, decls1) = compileDecl accum env decl
        val env = extendEnv (env, varenv1)
        val (top2, varenv2, decls2) = compileDeclList accum env decls
      in
        (top1 @ top2,
         extendVarEnv (varenv1, varenv2),
         decls1 @ decls2)
      end

  fun convert bcdecls =
      let
        val env = {varEnv = emptyVarEnv,
                   styEnv = SingletonTyEnv2.emptyEnv,
                   path = nil,
                   toplevel = true} : env
        val accum = newAccum ()
        val (top, _, binds) = compileDeclList accum env bcdecls
        val _ = checkNoExtraComputation accum
        val (topdecs, topdata) =
            foldr
              (fn (DEC dec, (topdecs, topdata)) => (dec::topdecs, topdata)
                | (DATA data, (topdecs, topdata)) => (topdecs, data::topdata))
              (nil, nil)
              top
        val topExp = Let (binds, unitExp Loc.noloc)
      in
        {topdata = topdata, topdecs = topdecs, topExp = topExp}
      end

end
