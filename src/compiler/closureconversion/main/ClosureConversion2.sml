(**
 * closure conversion with static allocation
 *
 * @copyright (c) 2011, 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ClosureConversion2 : sig

  val convert : BitmapCalc2.bcdecl list -> ClosureCalc.program

end =
struct

  structure B = BitmapCalc2
  structure C = ClosureCalc
  structure T = Types
  structure P = BuiltinPrimitive

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, path = ["$" ^ VarID.toString id], ty = ty} : C.varInfo
      end

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
      | C.CCLARGEINT _ => false
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
      | C.CCLOCALCODE _ => false
      | C.CCGOTO _ => false
      | C.CCCAST {exp, expTy, targetTy, runtimeTyCast, bitCast, loc} =>
        isAtomic exp
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
        | C.CCLARGEINT {srcLabel, loc} => emptySet
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
        | C.CCLOCALCODE {codeLabel, argVarList, codeBodyExp, mainExp,
                         resultTy, loc} =>
          let
            val bv2 = foldl (fn ({id,...},z) => VarID.Set.add (z,id))
                            bv
                            argVarList
          in
            unionSet (fvExp bv2 codeBodyExp, fvExp bv mainExp)
          end
        | C.CCGOTO {destinationLabel, argExpList, resultTy, loc} =>
          fvExpList bv argExpList
        | C.CCCAST {exp, expTy, targetTy, runtimeTyCast, bitCast, loc} =>
          fvExp bv exp
        | C.CCEXPORTVAR {id, ty, valueExp, loc} =>
          fvExpList bv [valueExp]

    and fvExpList bv exps =
        foldl (fn (x,z) => unionSet (fvExp bv x, z)) emptySet exps

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
      | C.CCLARGEINT {srcLabel, loc} => ccexp
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
      | C.CCLOCALCODE {codeLabel, argVarList, codeBodyExp, mainExp,
                       resultTy, loc} =>
        let
          val subst2 = foldl (fn (x,z) => remove (z, #id x)) subst argVarList
        in
          C.CCLOCALCODE
            {codeLabel = codeLabel,
             argVarList = argVarList,
             codeBodyExp = substExp subst2 codeBodyExp,
             mainExp = substExp subst mainExp,
             resultTy = resultTy,
             loc = loc}
        end
      | C.CCGOTO {destinationLabel, argExpList, resultTy, loc} =>
        C.CCGOTO
          {destinationLabel = destinationLabel,
           argExpList = map (substExp subst) argExpList,
           resultTy = resultTy,
           loc = loc}
      | C.CCCAST {exp, expTy, targetTy, runtimeTyCast, bitCast, loc} =>
        C.CCCAST
          {exp = substExp subst exp,
           expTy = expTy,
           targetTy = targetTy,
           runtimeTyCast = runtimeTyCast,
           bitCast = bitCast,
           loc = loc}
      | C.CCEXPORTVAR {id, ty, valueExp, loc} =>
        C.CCEXPORTVAR
          {id = id,
           ty = ty,
           valueExp = substExp subst valueExp,
           loc = loc}

  and substCconv subst cconv =
      case cconv of
        C.STATICCALL ty => cconv
      | C.DYNAMICCALL {cconvTag, wrapper} =>
        C.DYNAMICCALL {cconvTag = substExp subst cconvTag,
                       wrapper = substExp subst wrapper}

  fun toCcexp loc value =
      case value of
        SingletonTyEnv2.CONST n =>
        (C.CCCONST {const = C.CVWORD n, ty = BuiltinTypes.wordTy, loc = loc},
         BuiltinTypes.wordTy)
      | SingletonTyEnv2.VAR v =>
        (C.CCVAR {varInfo = v, loc = loc}, #ty v)
      | SingletonTyEnv2.TAG (ty, n) =>
        (C.CCCONST {const = C.CVTAG {tag = n, ty = ty},
                    ty = T.SINGLETONty (T.TAGty ty),
                    loc = loc},
         T.SINGLETONty (T.TAGty ty))
      | SingletonTyEnv2.SIZE (ty, n) =>
        (C.CCCAST
           {exp = C.CCCONST {const = C.CVWORD (Word32.fromInt n),
                             ty = BuiltinTypes.wordTy,
                             loc = loc},
            expTy = BuiltinTypes.wordTy,
            targetTy = T.SINGLETONty (T.SIZEty ty),
            runtimeTyCast = false,
            bitCast = false,
            loc = loc},
         T.SINGLETONty (T.SIZEty ty))
      | SingletonTyEnv2.CAST (v, ty2) =>
        let
          val (exp, ty) = toCcexp loc v
        in
          (C.CCCAST {exp = exp, expTy = ty, targetTy = ty2,
                     runtimeTyCast = false, bitCast = false, loc = loc},
           ty2)
        end

  fun unitExp loc =
      C.CCCONST {const = C.CVUNIT, ty = BuiltinTypes.unitTy, loc = loc}

  fun nullClosureEnvExp loc =
      C.CCCAST {exp = C.CCCONST {const = C.CVNULLBOXED,
                                 ty = BuiltinTypes.boxedTy,
                                 loc = loc},
                expTy = BuiltinTypes.boxedTy,
                targetTy = T.BACKENDty T.SOME_CLOSUREENVty,
                runtimeTyCast = false,
                bitCast = false,
                loc = loc}

  fun intExp n loc =
      C.CCCONST {const = C.CVINT n, ty = BuiltinTypes.intTy, loc = loc}

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

  datatype top =
      DEC of C.topdec
    | DATA of C.topdata

  exception ExpToConst
  fun expToConst (C.CCCONST {const, ty, ...}) = (const, ty)
    | expToConst (C.CCCAST {exp, expTy, targetTy, runtimeTyCast, bitCast,
                            loc}) =
      (C.CVCAST {value = #1 (expToConst exp),
                 valueTy = expTy,
                 targetTy = targetTy,
                 runtimeTyCast = runtimeTyCast,
                 bitCast = bitCast},
       targetTy)
    | expToConst _ = raise ExpToConst

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
                       clearPad, elemSizeExp, tagExp, loc} fallback =
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

  fun declToCcexp (decls, mainExp, loc) =
      foldr
        (fn (RecordLayout2.PRIMAPPLY {boundVar, primInfo, argList}, z) =>
            C.CCLET
              {boundVar = boundVar,
               boundExp =
                 C.CCPRIMAPPLY
                   {primInfo = primInfo,
                    argExpList = map (fn x => #1 (toCcexp loc x)) argList,
                    instTyList = nil,
                    instTagList = nil,
                    instSizeList = nil,
                    loc = loc},
               mainExp = z,
               loc = loc})
        mainExp
        decls

  fun checkNoExtraComputation accum =
      case RecordLayout2.extractDecls accum of
        nil => ()
      | _::_ => raise Bug.Bug "extra computation"

  fun computeTupleLayout accum fields loc =
      let
        val {allocSize, fieldIndexes, bitmaps, padding} =
            RecordLayout2.computeRecord
              accum
              (map (fn {tag, size, ...} => {tag=tag, size=size}) fields)
        val fieldList =
            mapi (fn (i, (index, {tag, size, ty, ...})) =>
                     {fieldLabel = Int.toString (i+1),
                      fieldIndex = toCcexp loc index,
                      fieldSize = toCcexp loc size,
                      fieldTag = #1 (toCcexp loc tag),
                      fieldTy = ty})
                 (ListPair.zipEq (fieldIndexes, fields))
        val recordTy =
            T.RECORDty
              (foldl (fn ({fieldLabel, fieldTy, ...},z) =>
                         LabelEnv.insert (z, fieldLabel, fieldTy))
                     LabelEnv.empty
                     fieldList)
        val fieldList =
            map
              (fn {fieldLabel, fieldIndex, fieldSize, fieldTag, fieldTy} =>
                  {fieldLabel = fieldLabel,
                   fieldIndex =
                     C.CCCAST
                       {exp = #1 fieldIndex,
                        expTy = #2 fieldIndex,
                        targetTy = T.SINGLETONty
                                     (T.INDEXty (fieldLabel, recordTy)),
                        runtimeTyCast = false,
                        bitCast = false,
                        loc = loc},
                   fieldSize =
                     C.CCCAST
                       {exp = #1 fieldSize,
                        expTy = #2 fieldSize,
                        targetTy = T.SINGLETONty (T.SIZEty fieldTy),
                        runtimeTyCast = false,
                        bitCast = false,
                        loc = loc},
                   fieldTag = fieldTag,
                   fieldTy = fieldTy})
              fieldList
        val bitmapList =
            mapi
              (fn (i, {index, bitmap}) =>
                  let
                    val index = toCcexp loc index
                    val bitmap = toCcexp loc bitmap
                  in
                    {bitmapIndex =
                       C.CCCAST
                         {exp = #1 index,
                          expTy = #2 index,
                          targetTy = T.BACKENDty (T.RECORDBITMAPINDEXty
                                                    (i, recordTy)),
                          runtimeTyCast = false,
                          bitCast = false,
                          loc = loc},
                     bitmapExp =
                       C.CCCAST
                         {exp = #1 bitmap,
                          expTy = #2 bitmap,
                          targetTy = T.BACKENDty (T.RECORDBITMAPty
                                                    (i, recordTy)),
                          runtimeTyCast = false,
                          bitCast = false,
                          loc = loc}}
                  end)
              bitmaps
        val allocSize = toCcexp loc allocSize
        val allocSizeExp =
            C.CCCAST {exp = #1 allocSize,
                      expTy = #2 allocSize,
                      targetTy = T.BACKENDty (T.RECORDSIZEty recordTy),
                      runtimeTyCast = false,
                      bitCast = false,
                      loc = loc}
      in
        {fieldList = fieldList,
         recordTy = recordTy,
         allocSizeExp = allocSizeExp,
         bitmaps = bitmapList}
      end

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
                  tag: SingletonTyEnv2.value,
                  size: SingletonTyEnv2.value,
                  usize: int}

    fun fvValue value =
        case value of
          SingletonTyEnv2.CONST _ => emptySet
        | SingletonTyEnv2.VAR var => singletonSet var
        | SingletonTyEnv2.SIZE _ => emptySet
        | SingletonTyEnv2.TAG _ => emptySet
        | SingletonTyEnv2.CAST (v, _) => fvValue v

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
              case Int.compare (u1, u2) of
                EQUAL => VarID.compare (#id v1, #id v2)
              | LESS => GREATER
              | GREATER => LESS)
          fields
  in

  fun makeClosureEnvRecord accum styEnv (freeVars, loc) =
      let
        val fields = sortFields (envFields styEnv freeVars)
        val tupleFields =
            map (fn {var as {ty,...}, tag, usize, ...} =>
                    {exp = C.CCVAR {varInfo=var, loc=loc},
                     ty = ty,
                     tag = tag,
                     size = SingletonTyEnv2.CONST (Word32.fromInt usize)})
                fields
        val record as {fieldList,recordTy,...} = makeTuple accum tupleFields loc
        (* generated closure environment should not be statically-allocatable;
         * If it is statically determined that a free variable binds a
         * constant value, such variable should be already substituted with
         * the constant value term by compileExp. *)
        val recordExp =
            C.CCCAST {exp = C.CCRECORD record,
                      expTy = recordTy,
                      targetTy = T.BACKENDty T.SOME_CLOSUREENVty,
                      runtimeTyCast = false,
                      bitCast = false,
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
                                     resultSize = #1 (toCcexp loc size),
                                     resultTag = #1 (toCcexp loc tag)}))
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
                                   runtimeTyCast = false,
                                   bitCast = false,
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
                      runtimeTyCast = true,
                      bitCast = true,
                      loc = loc}
        val cconvExp =
            C.CCCAST {exp = cconvTagExp (codeEntryTy, loc),
                      expTy = T.BACKENDty (T.CCONVTAGty codeEntryTy),
                      targetTy = T.BACKENDty T.SOME_CCONVTAGty,
                      runtimeTyCast = false,
                      bitCast = false,
                      loc = loc}
        val wrapperExp = funWrapperExp (id, codeEntryTy, loc)
        val fields =
            map (fn (exp, ty) =>
                    {exp = exp,
                     ty = ty,
                     tag = SingletonTyEnv2.findTag styEnv ty,
                     size = SingletonTyEnv2.findSize styEnv ty})
                [(closureEnvExp, T.BACKENDty T.SOME_CLOSUREENVty),
                 (cconvExp, T.BACKENDty T.SOME_CCONVTAGty),
                 (entryExp, T.BACKENDty T.SOME_FUNENTRYty),
                 (wrapperExp, T.BACKENDty T.SOME_FUNWRAPPERty)]
        val accum = RecordLayout2.newComputationAccum ()
        val record = makeTuple accum fields loc
        val _ = checkNoExtraComputation accum
        val (top1, recordExp) = allocRecord (styEnv, path) record
      in
        (top1,
         C.CCCAST {exp = recordExp,
                   expTy = #recordTy record,
                   targetTy = resultTy,
                   runtimeTyCast = false,
                   bitCast = false,
                   loc = loc})
      end

  fun decomposeClosureRecord styEnv (funExp, funTy) loc =
      let
        val accum = RecordLayout2.newComputationAccum ()
        val {fieldList, recordTy, allocSizeExp, bitmaps} =
            computeTupleLayout
              accum
              (map (fn ty => {tag = SingletonTyEnv2.findTag styEnv ty,
                              size = SingletonTyEnv2.findSize styEnv ty,
                              ty = ty})
                   [T.BACKENDty T.SOME_CLOSUREENVty,
                    T.BACKENDty T.SOME_CCONVTAGty,
                    T.BACKENDty T.SOME_FUNENTRYty,
                    T.BACKENDty T.SOME_FUNWRAPPERty])
              loc
        val _ = checkNoExtraComputation accum
        val recordExp = C.CCCAST {exp = funExp,
                                  expTy = funTy,
                                  targetTy = recordTy,
                                  runtimeTyCast = false,
                                  bitCast = false,
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
      in
        case selectExps of
          [closureEnvExp, cconvtagExp, entryExp, wrapperExp] =>
          {codeExp = entryExp,
           closureEnvExp = closureEnvExp,
           cconv = C.DYNAMICCALL {cconvTag = cconvtagExp, wrapper = wrapperExp}}
        | _ => raise Bug.Bug "decomposeClosureRecord"
      end

  datatype staticEvalResult =
      CLOSURE of static_closure
    | RECCLOSURE of static_closure
    | VALUE   (* any others *)

  type varEnv = (C.varInfo * C.ccconst option * staticEvalResult) VarID.Map.map

  type env =
      {
        varEnv: varEnv,
        styEnv: SingletonTyEnv2.env,
        path: RecordCalc.path,
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

  fun setPath ({varEnv, styEnv, path, toplevel}:env, newPath) : env =
      {varEnv = varEnv, styEnv = styEnv, path = newPath, toplevel = toplevel}

  fun enterFunction ({varEnv, styEnv, path, toplevel}:env) : env =
      {varEnv = varEnv, styEnv = styEnv, path = path, toplevel = false}

  fun compileConst (env:env) const loc =
      case const of
        ConstantTerm.INT n => (nil, C.CVINT n)
      | ConstantTerm.WORD n => (nil, C.CVWORD n)
      | ConstantTerm.CONTAG n => (nil, C.CVCONTAG n)
      | ConstantTerm.BYTE n => (nil, C.CVBYTE n)
      | ConstantTerm.REAL n => (nil, C.CVREAL n)
      | ConstantTerm.FLOAT n => (nil, C.CVFLOAT n)
      | ConstantTerm.CHAR c => (nil, C.CVCHAR c)
      | ConstantTerm.UNIT => (nil, C.CVUNIT)
      | ConstantTerm.NULLPOINTER => (nil, C.CVNULLPOINTER)
      | ConstantTerm.NULLBOXED => (nil, C.CVNULLBOXED)
      | ConstantTerm.LARGEINT n => (* for case branches *)
        let
          val id = ExtraDataLabel.generate (#path env)
        in
          ([DATA (C.CTLARGEINT {id = id, value = n, loc = loc})],
           C.CVEXTRADATA id)
        end
      | ConstantTerm.STRING s =>
        let
          val id = DataLabel.generate (#path env)
        in
          ([DATA (C.CTSTRING {id = id, string = s, loc = loc})],
           C.CVTOPDATA {id = id, ty = BuiltinTypes.stringTy})
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
                       runtimeTyCast = true,
                       bitCast = true,
                       loc = loc}
           | SOME (_, closureEnvExp) =>
             C.CCEXPORTCALLBACK {codeExp = codeExp,
                                 closureEnvExp = closureEnvExp,
                                 instTyvars = tyvarKindEnv,
                                 resultTy = funPtrTy,
                                 loc = loc})
        end
      | B.BCCONSTANT {const = ConstantTerm.LARGEINT n, ty, loc} =>
        let
          val id = ExtraDataLabel.generate (#path env)
        in
          ([DATA (C.CTLARGEINT {id = id, value = n, loc = loc})],
           VALUE,
           C.CCLARGEINT {srcLabel = id, loc = loc})
        end
      | B.BCCONSTANT {const, ty, loc} =>
        let
          val (top, const) = compileConst env const loc
        in
          (top, VALUE, C.CCCONST {const = const, ty = ty, loc = loc})
        end
      | B.BCTAG {tag, ty, loc} =>
        (nil, VALUE,
         C.CCCONST {const = C.CVTAG {tag = tag, ty = ty},
                    ty = T.SINGLETONty (T.TAGty ty),
                    loc = loc})
      | B.BCFOREIGNSYMBOL {name, ty, loc} =>
        (nil, VALUE,
         C.CCCONST {const = C.CVFOREIGNSYMBOL {name=name, ty=ty},
                    ty = ty,
                    loc = loc})
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
        (nil, VALUE,
         C.CCEXVAR {id = ExternSymbol.touch path,
                    ty = ty,
                    loc = loc})
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
        in
          (* only toplevel arrays can be allocated statically *)
          case (#toplevel env, primitive, instTyList,
                instTagList, instSizeList, argExpList) of
            (true, P.R P.Array_alloc_init, [ty], [tag], [size], args) =>
            let
              val (top4, arrayExp) =
                  allocArray (#path env)
                             {elemTy = ty,
                              isMutable = true,
                              clearPad = false,
                              initialElements = args,
                              numElements = intExp (length args) loc,
                              elemSizeExp = size,
                              tagExp = tag,
                              loc = loc}
                             origResultExp
            in
              (top @ top4, VALUE, arrayExp)
            end
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
              | VALUE =>
                let
                  val (letFn, funExp) = makeBind (funExp, funTy, loc)
                in
                  (letFn,
                   decomposeClosureRecord (#styEnv env) (funExp, funTy) loc)
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
      | B.BCLOCALCODE {codeLabel, argVarList, codeBodyExp, mainExp, resultTy,
                       loc} =>
        let
          val env2 = addBoundVars (env, argVarList)
          val (top1, _, codeBodyExp) = compileExp accum env codeBodyExp
          val (top2, _, mainExp) = compileExp accum env mainExp
        in
          (top1 @ top2,
           VALUE,
           C.CCLOCALCODE {codeLabel = codeLabel,
                          argVarList = argVarList,
                          codeBodyExp = codeBodyExp,
                          mainExp = mainExp,
                          resultTy = resultTy,
                          loc = loc})
        end
      | B.BCGOTO {destinationLabel, argExpList, resultTy, loc} =>
        let
          val (top1, argExpList) = compileExpList accum env argExpList
        in
          (top1,
           VALUE,
           C.CCGOTO {destinationLabel = destinationLabel,
                     argExpList = argExpList,
                     resultTy = resultTy,
                     loc = loc})
        end
      | B.BCFNM {argVarList, bodyExp, retTy, loc} =>
        let
          val id = VarID.generate ()
          val var = {id = id,
                     ty = T.FUNMty (map #ty argVarList, retTy),
                     path = #path env} : C.varInfo
          val decl = B.BCVAL {boundVar = var, boundExp = bcexp, loc = loc}
        in
          compileExp accum env
                     (B.BCLET {localDecl = decl,
                               mainExp = B.BCVAR {varInfo=var, loc=loc},
                               loc = loc})
        end
      | B.BCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val env = addBoundTyvars (env, btvEnv)
          val (top1, c, exp) = compileExp accum env exp
        in
          (top1, c,
           C.CCCAST {exp = exp,
                     expTy = expTyWithoutTAbs,
                     targetTy = T.POLYty {boundtvars=btvEnv,
                                          body=expTyWithoutTAbs},
                     runtimeTyCast = false,
                     bitCast = false,
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
                     runtimeTyCast = false,
                     bitCast = false,
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
      | B.BCCAST {exp, expTy, targetTy, runtimeTyCast, bitCast, loc} =>
        let
          val (top1, value, exp) = compileExp accum env exp
        in
          (top1,
           VALUE,
           C.CCCAST {exp = exp,
                     expTy = expTy,
                     targetTy = targetTy,
                     runtimeTyCast = runtimeTyCast,
                     bitCast = bitCast,
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
        val (top1, const) = compileConst env constant loc
        val (top2, _, branchExp) = compileExp accum env branchExp
        val (top3, branches) = compileBranches accum env branches loc
      in
        (top1 @ top2 @ top3,
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

  and compileFuncBody env bodyExp loc =
      let
        val accum = RecordLayout2.newComputationAccum ()
        val (top, _, bodyExp) = compileExp accum env bodyExp
        val decls = RecordLayout2.extractDecls accum
      in
        (top, declToCcexp (decls, bodyExp, loc))
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
                            retTy = SOME retTy}}
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
        B.BCEXTERNVAR {exVarInfo as {path,ty}, loc} =>
        ([DATA (C.CTEXTERNVAR {id=ExternSymbol.touch path, ty=ty, loc=loc})],
         emptyVarEnv,
         nil)
      | B.BCEXPORTVAR {exVarInfo={path,ty}, exp, loc} =>
        let
          val (top1, _, exp) = compileExp accum env exp
          val value = SOME (expToConst exp) handle ExpToConst => NONE
          val id = ExternSymbol.touch path
        in
          (top1 @ [DATA (C.CTEXPORTVAR {id=id, ty=ty, value=value, loc=loc})],
           emptyVarEnv,
           case value of
             SOME _ => nil
           | NONE =>
             [{boundVar = newVar BuiltinTypes.unitTy,
               boundExp = C.CCEXPORTVAR
                            {id = id,
                             ty = ty,
                             valueExp = exp,
                             loc = loc},
               loc = loc}])
        end
      | B.BCVAL {boundVar, boundExp = B.BCFNM func, loc} =>
        compileFunc accum env (boundVar, func)
      | B.BCVAL {boundVar, boundExp = B.BCPOLY {btvEnv, exp=B.BCFNM func,
                                                expTyWithoutTAbs, loc=_},
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
                           retTy = SOME retTy}
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
        val accum = RecordLayout2.newComputationAccum ()
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
