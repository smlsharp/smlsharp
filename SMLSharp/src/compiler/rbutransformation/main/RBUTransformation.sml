(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @author Atsushi Ohori
 * @version $$
 *)
structure RBUTransformation : RBUTRANSFORMATION = struct

  structure BT = BasicTypes
  structure CTX = RBUContext
  structure AT = AnnotatedTypes
  structure T = Types
  structure RT = RBUTypes
  structure CT = ConstantTerm
  structure ATU = AnnotatedTypesUtils
  structure CC = ClusterCalc
  structure RBUU = RBUUtils
  structure ECG = ExtraComputationGenerator

  open RBUCalc

  val OFFSET_SHIFT_BITS = 0w16
  val OFFSET_MASK = 0wxFF
  val MAX_BLOCK_SIZE = 31

  (*========================================================*)
  (* change the kind of external recursive variable to internal*)

  fun changeKindExp vSet ccexp =
      case ccexp of
        CC.CCFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
        CC.CCFOREIGNAPPLY
            {
             funExp = changeKindExp vSet funExp,
             funTy = funTy,
             argExpList = changeKindExpList vSet argExpList,
             attributes = attributes,
             loc = loc
            }
(*
      | CC.CCEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        CC.CCEXPORTCALLBACK 
            {
             funExp = changeKindExp vSet funExp,
             funTy = funTy,
             attributes = attributes,
             loc = loc
            }
*)
      | CC.CCSIZEOF {ty, loc} => ccexp
      | CC.CCCONSTANT {value, loc} => ccexp
      | CC.CCGLOBALSYMBOL _ => ccexp
      | CC.CCEXCEPTIONTAG {tagValue, loc} => ccexp
      | CC.CCVAR {varInfo as {displayName, ty, varId}, loc} =>
        if VarIdSet.member(vSet, varId) 
        then CC.CCVAR {varInfo = {displayName = displayName, ty = ty, varId = varId}, loc = loc}
        else ccexp
      | CC.CCGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        CC.CCGETFIELD 
            {
             arrayExp = changeKindExp vSet arrayExp,
             indexExp = changeKindExp vSet indexExp,
             elementTy = elementTy,
             loc = loc
            }
      | CC.CCSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        CC.CCSETFIELD
            {
             valueExp = changeKindExp vSet valueExp,
             arrayExp = changeKindExp vSet arrayExp,
             indexExp = changeKindExp vSet indexExp,
             elementTy = elementTy,
             loc = loc
            }
      | CC.CCSETTAIL {consExp, newTailExp, listTy, tailLabel, consRecordTy, loc} =>
        CC.CCSETTAIL
            {
             consExp = changeKindExp vSet consExp,
             newTailExp = changeKindExp vSet newTailExp,
             listTy = listTy,
             tailLabel = tailLabel,
             consRecordTy = consRecordTy, 
             loc = loc
            }
      | CC.CCARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        CC.CCARRAY
            {
             sizeExp = changeKindExp vSet sizeExp,
             initialValue = changeKindExp vSet initialValue,
             elementTy = elementTy,
             isMutable = isMutable,
             loc = loc
            }
      | CC.CCCOPYARRAY {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
        CC.CCCOPYARRAY
            {
             srcExp = changeKindExp vSet srcExp,
             srcIndexExp = changeKindExp vSet srcIndexExp,
             dstExp = changeKindExp vSet dstExp,
             dstIndexExp = changeKindExp vSet dstIndexExp,
             lengthExp = changeKindExp vSet lengthExp,
             elementTy = elementTy,
             loc = loc
            }
      | CC.CCPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        CC.CCPRIMAPPLY 
            {
             primInfo = primInfo,
             argExpList = changeKindExpList vSet argExpList,
             instTyList = instTyList,
             loc = loc
            }
      | CC.CCAPPM {funExp, funTy, argExpList, loc} =>
        CC.CCAPPM
            {
             funExp = changeKindExp vSet funExp,
             funTy = funTy,
             argExpList = changeKindExpList vSet argExpList,
             loc = loc
            }
      | CC.CCLOCALAPPM {funExp, funTy, argExpList, loc} =>
        CC.CCLOCALAPPM
            {
             funExp = changeKindExp vSet funExp,
             funTy = funTy,
             argExpList = changeKindExpList vSet argExpList,
             loc = loc
            }
      | CC.CCTAPP {exp, expTy, instTyList, loc} =>
        CC.CCTAPP
            {
             exp = changeKindExp vSet exp,
             expTy = expTy,
             instTyList = instTyList,
             loc = loc
            }
      | CC.CCLET {localDeclList, mainExp, loc} =>
        CC.CCLET
            {
             localDeclList = changeKindDeclList vSet localDeclList,
             mainExp = changeKindExp vSet mainExp,
             loc = loc
            }
      | CC.CCMVALUES {expList, tyList, loc} =>
        CC.CCMVALUES 
            {
             expList = changeKindExpList vSet expList,
             tyList = tyList,
             loc = loc
            }
      | CC.CCRECORD {expList, recordTy, annotation, isMutable, loc} =>
        CC.CCRECORD
            {
             expList = changeKindExpList vSet expList,
             recordTy = recordTy,
             annotation = annotation,
             isMutable = isMutable,
             loc = loc
            }
      | CC.CCSELECT {recordExp, label, recordTy, resultTy, loc} =>
        CC.CCSELECT
            {
             recordExp = changeKindExp vSet recordExp,
             label = label,
             recordTy = recordTy,
             resultTy = resultTy,
             loc = loc
            }
      | CC.CCMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        CC.CCMODIFY
            {
             recordExp = changeKindExp vSet recordExp,
             recordTy = recordTy,
             label = label,
             valueExp = changeKindExp vSet valueExp,
             valueTy = valueTy,
             loc = loc
            }
      | CC.CCRAISE {argExp, resultTy, loc} =>
        CC.CCRAISE 
            {
             argExp = changeKindExp vSet argExp,
             resultTy = resultTy,
             loc = loc
            }
      | CC.CCHANDLE {exp, exnVar, handler, loc} =>
        CC.CCHANDLE
            {
             exp = changeKindExp vSet exp,
             exnVar = exnVar,
             handler = changeKindExp vSet handler,
             loc = loc
            }
      | CC.CCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        CC.CCSWITCH
            {
             switchExp = changeKindExp vSet switchExp,
             expTy = expTy,
             branches =
             map
                 (fn {constant, exp} => 
                     {
                      constant = changeKindExp vSet constant,
                      exp = changeKindExp vSet exp
                     }
                 )
                 branches,
             defaultExp = changeKindExp vSet defaultExp,
             loc = loc
            }
      | CC.CCCAST {exp, expTy, targetTy, loc} =>
        CC.CCCAST
            {
             exp = changeKindExp vSet exp,
             expTy = expTy, 
             targetTy = targetTy,
             loc = loc
            }

  and changeKindExpList vSet expList = map (changeKindExp vSet) expList

  and changeKindFunDecl vSet {funVar, argVarList, bodyExp, loc} =
      {
       funVar = funVar,
       argVarList = argVarList,
       bodyExp = changeKindExp vSet bodyExp,
       loc = loc
      }

  and changeKindCodeDecl vSet {funVar, argVarList, bodyExp, loc} =
      {
       funVar = funVar,
       argVarList = argVarList,
       bodyExp = changeKindExp vSet bodyExp,
       loc = loc
      }

  and changeKindFunDeclList vSet funDeclList = map (changeKindFunDecl vSet) funDeclList

  and changeKindCodeDeclList vSet codeDeclList = map (changeKindCodeDecl vSet) codeDeclList

  and changeKindDecl vSet decl =
      case decl of
        CC.CCVAL {boundVars, boundExp, loc} =>
        CC.CCVAL
            {
             boundVars = boundVars,
             boundExp = changeKindExp vSet boundExp,
             loc = loc
            }
      | CC.CCVALCODE
          {
           code,
	   isRecursive,
           loc
          }
          =>
          let
              val vSet =
                  foldl
                      (fn ({funVar as {varId,...},...}, vSet) => VarIdSet.add(vSet, varId))
                      vSet
                      code
              val newCodeList = changeKindCodeDeclList vSet code
          in
              CC.CCVALCODE
                  {
                   code = newCodeList,
                   isRecursive = isRecursive,
                   loc = loc
                   }
          end
      | CC.CCPOLYVAL {btvEnv, boundVar, boundExp, loc} =>
        CC.CCPOLYVAL
            {
             btvEnv = btvEnv,
             boundVar = boundVar,
             boundExp = changeKindExp vSet boundExp,
             loc = loc
            }
      | CC.CCPOLYVALCODE
          {
           btvEnv,
           code,
           isRecursive,
           loc
          }
          =>
          let
          val vSet =
              foldl
                  (fn ({funVar as {varId,...},...}, vSet) => VarIdSet.add(vSet, varId))
                  vSet
                  code
            val newCodeList = changeKindCodeDeclList vSet code
          in
            CC.CCPOLYVALCODE
            {
             btvEnv = btvEnv,
             code = newCodeList,
             isRecursive = isRecursive,
             loc = loc
             }
          end
      | CC.CCCLUSTER {entryFunctions, innerFunctions, isRecursive, loc} =>
        let
          val vSet =
              foldl
                  (fn ({funVar as {varId,...},...}, vSet) => VarIdSet.add(vSet, varId))
                  vSet
                  (entryFunctions @ innerFunctions)
        in
          CC.CCCLUSTER
              {
               entryFunctions = changeKindFunDeclList vSet entryFunctions,
               innerFunctions = changeKindFunDeclList vSet innerFunctions,
               isRecursive = isRecursive,
               loc = loc
              }
        end
      | CC.CCCALLBACKCLUSTER {funDecl as {funVar={varId,...},...},
                              attributes, loc} =>
        let
          val vSet = VarIdSet.add (vSet, varId)
        in
          CC.CCCALLBACKCLUSTER {funDecl = changeKindFunDecl vSet funDecl,
                                attributes = attributes,
                                loc = loc}
        end
      | CC.CCPOLYCLUSTER {btvEnv, entryFunctions, innerFunctions, isRecursive, loc} =>
        let
          val vSet =
              foldl
                  (fn ({funVar as {varId,...},...}, vSet) => VarIdSet.add(vSet, varId))
                  vSet
                  (entryFunctions @ innerFunctions)
        in
          CC.CCPOLYCLUSTER
              {
               btvEnv = btvEnv,
               entryFunctions = changeKindFunDeclList vSet entryFunctions,
               innerFunctions = changeKindFunDeclList vSet innerFunctions,
               isRecursive = isRecursive,
               loc = loc
              }
        end
        
  and changeKindDeclList vSet declList = map (changeKindDecl vSet) declList

  (*========================================================*)

  infix 8 ++
  fun op ++ (S1,S2) = ISet.union(S1,S2)

  fun tvsInTy ty =
      case ty of
        RT.BOUNDVARty tid => ISet.singleton(tid)
      | RT.SINGLEty tid => ISet.singleton(tid)
      | _ => ISet.empty

  fun tvsInTyList tyList =
      foldl (fn (ty,S) => S ++ (tvsInTy ty)) ISet.empty tyList

  fun tvsInVarInfo ({ty,...} : varInfo) = tvsInTy ty

  fun tvsInVarInfoList varInfoList = 
      foldl (fn (varInfo,S) => S ++ (tvsInVarInfo varInfo)) ISet.empty varInfoList

  fun tvsInExp exp =
      case exp of
        RBUFOREIGNAPPLY {funExp, argExpList, ...} => tvsInExpList (funExp::argExpList)
      | RBUCALLBACKCLOSURE {codeExp, envExp, argTyList, resultTyList, ...} =>
        tvsInExp codeExp ++ tvsInExp envExp
        ++ tvsInTyList argTyList ++ tvsInTyList resultTyList
      | RBUCONSTANT _ => ISet.empty
      | RBUGLOBALSYMBOL _ => ISet.empty
      | RBUEXCEPTIONTAG _ => ISet.empty
      | RBUVAR {varInfo as {ty,...}, valueSizeExp, loc} => tvsInTy ty
      | RBULABEL _ => ISet.empty
      | RBUGETFIELD {arrayExp, ...} => tvsInExp arrayExp
      | RBUSETFIELD {arrayExp, valueExp, valueTy,...} =>
        (tvsInExp arrayExp) ++ (tvsInExp valueExp) ++ (tvsInTy valueTy)
      | RBUSETTAIL {consExp, newTailExp,...} =>
        (tvsInExp consExp) ++ (tvsInExp newTailExp) 
      | RBUARRAY {initialValue, elementTy,...} =>
        (tvsInExp initialValue) ++ (tvsInTy elementTy)
      | RBUCOPYARRAY
        {srcExp, srcOffsetExp, dstExp, dstOffsetExp, lengthExp, elementTy,...} =>
        (tvsInExp srcExp)
        ++ (tvsInExp srcOffsetExp)
        ++ (tvsInExp dstExp)
        ++ (tvsInExp dstOffsetExp)
        ++ (tvsInExp lengthExp)
        ++ (tvsInTy elementTy)
      | RBUPRIMAPPLY {argExpList,...} => tvsInExpList argExpList
      | RBUAPPM {funExp, argExpList, argTyList,...} =>
        (tvsInExpList (funExp::argExpList)) ++ (tvsInTyList argTyList)
      | RBULOCALAPPM {funLabel, argExpList, argTyList,...} =>
        (tvsInExpList argExpList) ++ (tvsInTyList argTyList)
      | RBURECCALL {argExpList, argTyList,...} =>
        (tvsInExpList argExpList) ++ (tvsInTyList argTyList)
      | RBUINNERCALL {argExpList, argTyList,...} =>
        (tvsInExpList argExpList) ++ (tvsInTyList argTyList)
      | RBULET {localDeclList, mainExp,...} =>
        (tvsInDeclList localDeclList) ++ (tvsInExp mainExp)
      | RBUMVALUES {expList, tyList,...} =>
        (tvsInExpList expList) ++ (tvsInTyList tyList)
      | RBURECORD {fieldList, fieldTyList,...} =>
        (tvsInExpList fieldList) ++ (tvsInTyList fieldTyList)
      | RBUENVRECORD {fieldList, fieldTyList,...} =>
        (tvsInExpList fieldList) ++ (tvsInTyList fieldTyList)
      | RBUSELECT {recordExp, ...} => tvsInExp recordExp
      | RBUMODIFY {recordExp, valueExp, valueTy,...} =>
        (tvsInExpList [recordExp, valueExp]) ++ (tvsInTy valueTy)
      | RBURAISE {argExp,...} => tvsInExp argExp
      | RBUHANDLE {exp, handler,...} => tvsInExpList [exp, handler]
      | RBUSWITCH {switchExp, defaultExp, branches,...} =>
        (tvsInExpList [switchExp, defaultExp]) ++
        (foldl (fn ({constant,exp}, S) => S ++ (tvsInExp exp)) ISet.empty branches)
      | RBUCLOSURE{codeExp,envExp,...} => tvsInExp codeExp ++ tvsInExp envExp
      | RBUENTRYCLOSURE _ => ISet.empty
      | RBUINNERCLOSURE _ => ISet.empty

  and tvsInExpList expList =
      foldl (fn (exp,S) => S ++ (tvsInExp exp)) ISet.empty expList

  and tvsInDecl decl =
      case decl of
        RBUVAL {boundVarList, boundExp,...} =>
        (tvsInVarInfoList boundVarList) ++ (tvsInExp boundExp)
      | RBUCLUSTER _ => ISet.empty
      | RBUVALCODE {codeList = codeDeclList, isRecursive, loc} =>
        tvsInCodeDeclList codeDeclList
  and tvsInDeclList declList =
      foldl (fn (decl,S) => S ++ (tvsInDecl decl)) ISet.empty declList

  and tvsInFunDecl ({argVarList, bodyExp, resultTyList,...} : funDecl) =
      (tvsInVarInfoList argVarList) ++ (tvsInExp bodyExp) ++ (tvsInTyList resultTyList)

  and tvsInFunDeclList funDeclList =
      foldl (fn (funDecl,S) => S ++ (tvsInFunDecl funDecl)) ISet.empty funDeclList

  and tvsInCodeDecl ({argVarList, bodyExp,...} : codeDecl) =
      (tvsInVarInfoList argVarList) ++ (tvsInExp bodyExp)

  and tvsInCodeDeclList codeDeclList =
      foldl (fn (codeDecl,S) => S ++ (tvsInCodeDecl codeDecl)) ISet.empty codeDeclList

  fun decomposeOrdinaryRecord (isAligned,pad,tyList,fieldList) =
      let
        val MAX_BLOCK_FIELDS =  if !Control.enableUnboxedFloat then !Control.limitOfBlockFields else MAX_BLOCK_SIZE
        fun align (tyList,fieldList) =
            let
              (* NOTE: This algorithm is O(n^2). *)
              fun insert (tyList,fieldList,[],[]) = (rev tyList,rev fieldList)
                | insert (nil,nil,ty::tys,field::fields) =
                  insert ([ty],[field],tys,fields)
                | insert (tyList,fieldList,ty::tys,field::fields) =
                  let
                    val padTy = RT.PADty {condTy = ty, tyList = rev tyList}

                    (* FIXME: "isAligned" means "is to be aligned". *)
                    val padSize =
                        if isAligned
                        then RBUU.constSize padTy
                        else SOME 0w0
                  in
                    case padSize of
                      SOME 0w0 =>
                      insert(ty::tyList,field::fieldList,tys,fields)
                    | _ =>
                      insert(ty::padTy::tyList,field::pad::fieldList,tys,fields)
                  end
                | insert _ = raise Control.Bug "tyList and fieldList must have the same length"
            in
              insert([],[],tyList,fieldList)
            end
        fun decompose (blocks,[],[]) = rev blocks
          | decompose (blocks,tyList,fieldList) =
            let
              val totalLength = List.length tyList
              val numOfFields = if totalLength > MAX_BLOCK_FIELDS then MAX_BLOCK_FIELDS else totalLength
              val blockTyList = List.take(tyList, numOfFields)
              val blockFieldList = List.take(fieldList, numOfFields)
              val tyRest = List.drop(tyList,numOfFields)
              val fieldRest = List.drop(fieldList,numOfFields)
              val block = 
                  if !Control.alignRecord
                  then
                    if totalLength = numOfFields
                    then align (blockTyList,blockFieldList)  
                    else 
                      let
                        val (L1,L2) = align(RT.BOXEDty::blockTyList,pad::blockFieldList)
                      in
                        (List.tl L1, List.tl L2)
                      end
                  else (blockTyList,blockFieldList)
            in
              decompose (block::blocks,tyRest,fieldRest)
            end
      in
        case decompose ([],tyList,fieldList) of
          [] => [([],[])]
        | L => L
      end

  fun encodeIndexExp (RBUCONSTANT {value = CT.WORD w1,...}, RBUCONSTANT {value = CT.WORD w2,...}, loc) =
      RBUU.word_constant
          (
           BT.UInt32.orb(BT.UInt32.<<(w1, OFFSET_SHIFT_BITS),w2),
           loc
          )
    | encodeIndexExp (RBUCONSTANT {value = CT.WORD 0w0,...}, offsetExp, loc) = offsetExp
    | encodeIndexExp (nestLevelExp, offsetExp, loc) =
      RBUU.word_orb
          (
           RBUU.word_leftShift
               (
                nestLevelExp,
                RBUU.word_constant(BT.WordToUInt32 OFFSET_SHIFT_BITS, loc),
                loc
               ),
           offsetExp,
           loc
          )

  fun decodeIndexExp (RBUCONSTANT {value = CT.WORD w,...}, loc) =
      (
       RBUU.word_constant(BT.UInt32.>>(w, OFFSET_SHIFT_BITS), loc),
       RBUU.word_constant(BT.UInt32.andb(w, BT.WordToUInt32 OFFSET_MASK), loc)
      )
    | decodeIndexExp (indexExp, loc) =
      (
       RBUU.word_logicalRightShift
           (
            indexExp,
            RBUU.word_constant(BT.WordToUInt32 OFFSET_SHIFT_BITS, loc),
            loc
           ),
       RBUU.word_andb
           (
            indexExp,
            RBUU.word_constant(BT.WordToUInt32 OFFSET_MASK, loc),
            loc
           )
      )

(*
  (* transform AT types appears before rbutransformation into 
   * those of RBUTypes
   *)
  fun transformType context ty =
    (
(*
     print (Control.prettyPrint (RT.format_ty ty));
     print "\n";
*)
      case ty of
        AT.ERRORty => RT.ATOMty
      | AT.DUMMYty _ => RT.ATOMty
      | AT.TYVARty (ref {recKind = AT.REC _,...}) => RT.BOXEDty
      | AT.TYVARty _ => RT.ATOMty
      | AT.BOUNDVARty tid =>
        (
         case CTX.representationOf(context,tid) of
           AT.ATOM_REP => RT.ATOMty
         | AT.BOXED_REP => RT.BOXEDty
         | AT.DOUBLE_REP => RT.DOUBLEty
         | AT.SINGLE_REP => RT.SINGLEty tid
         | AT.UNBOXED_REP => RT.UNBOXEDty tid
         | _ => RT.BOUNDVARty tid
        )
      | AT.FUNMty _ => RT.BOXEDty
      | AT.MVALty tyList => 
        raise Control.Bug "MVALty  to transformType in (RBUTransformation)"
      | AT.RECORDty _ => RT.BOXEDty
      | AT.CONty {tyName = {boxedKind,...},args} =>
        (
         case !boxedKind of
           T.ATOMty => RT.ATOMty
         | T.BOXEDty => RT.BOXEDty
         | T.DOUBLEty => RT.DOUBLEty
         | T.GENERICty => 
           raise Control.Bug "illeagal boxed kind : (rbutransformation/main/RBUTransformation.sml)"
        )
      | AT.POLYty {boundtvars, body} => transformType context body
(*
      | AT.SPECty (AT.CONty _)  => raise Control.Bug "to be implemented!"
*)
    )
*)

  fun transformType (context:CTX.context) ty =
      RBUU.toRBUType (#btvEnv (#staticEnv context), ty)


(*
 This function is move to AnnotatedTypes sintce it is used in Clustering.

  fun generateExtraArgTyList (btvEnv : AT.btvEnv) =
      let
        fun generate {id,recKind,eqKind,instancesRef,representationRef} =
            case recKind of
              AT.REC flty =>
              map (fn label => RT.INDEXty{label = label, recordTy = RT.BOUNDVARty id}) (SEnv.listKeys flty)
            | _ =>
              (
               case !representationRef of
                 AT.ATOM_REP => []
               | AT.BOXED_REP => []
               | AT.DOUBLE_REP => []
               | AT.SINGLE_REP => [RT.TAGty id]
               | AT.UNBOXED_REP => [RT.SIZEty id]
               | _ => 
                 if !Control.enableUnboxedFloat
                 then [RT.TAGty id, RT.SIZEty id]
                 else [RT.TAGty id]
              )
      in
        IEnv.foldr (fn (btvKind, L) => (generate btvKind) @ L) [] btvEnv
      end


*)
  fun generateExtraArgExpList context (btvEnv : AT.btvEnv, subst, loc) =
      let
        fun substitute tid =
            case IEnv.find(subst, tid) of
              SOME ty => ty
            | _ => raise Control.Bug "type variable not found"
        val tyList = RBUU.generateExtraArgTyList (#btvEnv (#staticEnv context)) btvEnv
      in
        foldr
            (fn (ty, (L,C)) =>
                case ty of
                  RT.INDEXty {label, recordTy as (RT.BOUNDVARty tid)} =>
                  (
                   case substitute tid of
                     (recordTy as (AT.RECORDty _)) =>
                     let
                       val (nestLevelExp, offsetExp, newC) = generateRecordOffset C (label, recordTy, loc)
                     in
                       ((encodeIndexExp(nestLevelExp, offsetExp, loc))::L, newC)
                     end
                   | AT.BOUNDVARty tid' => 
                     let
                       val (indexExp, newC) = CTX.lookupIndex C (label, tid',loc)
                     in
                       (indexExp::L, newC)
                     end
                   | _ => raise Control.Bug "invalid record type"
                  )
                | RT.TAGty tid => 
                  let
                    val (tagExp, newC) = generateTag C (transformType C (substitute tid),loc)
                  in
                    (tagExp::L,newC)
                  end
                | RT.SIZEty tid => 
                  let
                    val (sizeExp, newC) = generateSize C (transformType C (substitute tid),loc)
                  in
                    (sizeExp::L,newC)
                  end
                | _ => raise Control.Bug "invalid extra arg type"
            )
            ([],context)
            tyList
      end

  and generateSize context (ty, loc) =
      case RBUU.constSize ty of
        SOME w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | NONE =>
        case ty of
          RT.UNBOXEDty tid => CTX.lookupSize context (tid,loc)
        | RT.BOUNDVARty tid => CTX.lookupSize context (tid, loc)
        (* this type only appear in the offset/bitmap type*)
        | RT.PADty {condTy, tyList} =>
          let
            val varInfo = Counters.newRBUVar LOCAL (RT.PADSIZEty {condTy = condTy, tyList = tyList})
            val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
          in
            (RBUVAR {varInfo = newVarInfo, valueSizeExp = RBUU.constSizeExp (#ty newVarInfo,loc), loc = loc},
             newContext)
          end
        | _ => raise Control.Bug "invalid type"
        
  and generateSizeList context ([], loc) = ([], context)
    | generateSizeList context (ty::rest, loc) =
      let
        val (sizeExp, newContext) = generateSize context (ty, loc)
        val (sizeExpList, newContext) = generateSizeList newContext (rest, loc)
      in
        (sizeExp::sizeExpList, newContext)
      end

  and generateTag context (ty, loc) =
      case RBUU.constTag ty of
        SOME w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | NONE =>
        (
         case ty of
           RT.SINGLEty tid => CTX.lookupTag context (tid,loc)
         | RT.BOUNDVARty tid => CTX.lookupTag context (tid, loc)
         | _ => raise Control.Bug "invalid compact type"
        )
 
  and generateTagList context ([], loc) = ([], context)
    | generateTagList context (ty::rest, loc) =
      let
        val (tagExp, newContext) = generateTag context (ty, loc)
        val (tagExpList, newContext) = generateTagList newContext (rest, loc)
      in
        (tagExp::tagExpList, newContext)
      end

  and generateSetTailOffset context (elemTy, loc) =
    let
      val tyList = [RT.ATOMty, elemTy]
      val (offsetExp, newContext) = generateOffset context (tyList,loc)
    in
      (offsetExp, newContext)
    end


  and generateRecordOffset context (label, recordTy, loc) =
      case recordTy of
        AT.RECORDty {fieldTypes,annotation = ref {align,...}} =>
        let
          fun take (L,[],[]) = NONE
            | take (L,ty::tyRest,label'::labelRest) =
              if label = label'
              then SOME (rev L)
              else take(ty::L,tyRest,labelRest)
            | take _ = raise Control.Bug "compileNestedOffset: tyList and labelList do not have the same number"
                             
          fun lookup (n,[]) = raise Control.Bug "label not found"
            | lookup (n,[(tyList,labelList)]) = (*the last block - no nested pointer inserted*)
              (
               case take([],tyList,labelList) of 
                 SOME tyList' => (n,tyList')
               | _ => raise Control.Bug "compileNestedOffset: label not found"
              )
            | lookup (n,(tyList,labelList)::rest) = (* nested pointer needs to be inserted*)
              (
               case take([],tyList,labelList) of
                 SOME tyList' => (n,RT.BOXEDty::tyList')
               | _ => lookup(n + 1,rest)
              )

          (* make new record layout*)
          val labelList = SEnv.listKeys fieldTypes
          val tyList = map (transformType context) (SEnv.listItems fieldTypes)
          val dummyLabel = "{DUMMY}"
          val blocks = decomposeOrdinaryRecord (align,dummyLabel,tyList,labelList)
          (*lookup the label*)
          val (nestLevel,newTyList) = lookup(0,blocks)
          val (offsetExp, newContext) = generateOffset context (newTyList,loc)
        in
          (RBUU.word_constant (BT.UInt32.fromInt nestLevel, loc), offsetExp, newContext)
        end
      | AT.BOUNDVARty tid =>
        let
          val (indexExp, newContext) = CTX.lookupIndex context (label, tid, loc)
          val (nestLevelExp, offsetExp) = decodeIndexExp (indexExp, loc)
        in
          (nestLevelExp, offsetExp, newContext)
        end
      | _ => raise Control.Bug "record type is expected"

  and generateBitmap context (tyList, loc) =
      case RBUU.optimizeBitmap tyList of
        RBUU.BO_CONST w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | RBUU.BO_TYVAR ty => generateTag context (ty,loc)
      | RBUU.BO_NONE =>
        let
          val varInfo = Counters.newRBUVar LOCAL (RT.BITMAPty tyList)
          val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
        in
          (RBUVAR {varInfo = newVarInfo, valueSizeExp = RBUU.constSizeExp (#ty newVarInfo,loc), loc = loc},
           newContext)
        end

  and generateFrameBitmap context ([], loc) = (RBUU.word_constant(0w0,loc),context)
    | generateFrameBitmap context ([tid], loc) = generateTag context (RT.BOUNDVARty tid,loc)
    | generateFrameBitmap context (tidList, loc) =
      let
        val varInfo = Counters.newRBUVar LOCAL (RT.FRAMEBITMAPty tidList)
        val (newVarInfo as {varId,...}, newContext) = CTX.mergeVariable context varInfo
        val _ = CTX.registerFrameBitmapID newContext varId
      in
        (RBUVAR {varInfo = newVarInfo, valueSizeExp = RBUU.constSizeExp (#ty newVarInfo,loc), loc = loc},
         newContext)
      end

  and generateEnvBitmap context (tyList, fixedSizeList, loc) =
      case RBUU.optimizeEnvBitmap (tyList, fixedSizeList) of
        RBUU.BO_CONST w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | RBUU.BO_TYVAR ty => generateTag context (ty,loc)
      | RBUU.BO_NONE =>
        let
          val varInfo = Counters.newRBUVar LOCAL (RT.ENVBITMAPty {tyList = tyList, fixedSizeList = fixedSizeList})
          val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
        in
          (RBUVAR {varInfo = newVarInfo, valueSizeExp = RBUU.constSizeExp (#ty newVarInfo,loc), loc = loc},
           newContext)
        end

  and generateOffset context (tyList, loc) =
      case RBUU.optimizeOffset tyList of
        RBUU.BO_CONST w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | RBUU.BO_TYVAR ty => generateSize context (ty,loc)
      | RBUU.BO_NONE =>
        let
          val varInfo = Counters.newRBUVar LOCAL (RT.OFFSETty tyList)
          val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
        in
          (RBUVAR {varInfo = newVarInfo, valueSizeExp = RBUU.constSizeExp (#ty newVarInfo,loc), loc = loc},
           newContext)
        end

  and generateArrayOffset context (indexExp, elementTy, loc) =
      let
        val (sizeExp, newContext) = generateSize context (elementTy, loc)
        val indexExp =
            case indexExp of 
              RBUCONSTANT {value = CT.INT n, loc} =>
              RBUU.word_constant(BT.UInt32.fromInt (Int32.toInt n), loc)
            | _ => indexExp
        val offsetExp = 
            case (indexExp,sizeExp) of
              (RBUCONSTANT {value = CT.WORD w1, loc = loc1},RBUCONSTANT {value = CT.WORD w2, loc = loc2}) => 
              RBUU.word_constant(w1 * w2,loc1)
            | (_,RBUCONSTANT {value = CT.WORD 0w1, loc =  loc2}) => indexExp
            | (_,RBUCONSTANT {value = CT.WORD 0w2, loc = loc2}) =>
              RBUU.word_leftShift(indexExp,RBUU.word_constant(0w1,loc),loc)
            | (_,RBUCONSTANT {value = CT.WORD 0w4, loc = loc2}) =>
              RBUU.word_leftShift(indexExp,RBUU.word_constant(0w2,loc),loc)
            | (_,RBUCONSTANT {value = CT.WORD 0w8, loc = loc2}) =>
              RBUU.word_leftShift(indexExp,RBUU.word_constant(0w3,loc),loc)
            | (_,RBUCONSTANT {value = CT.WORD 0w16, loc = loc2}) =>
              RBUU.word_leftShift(indexExp,RBUU.word_constant(0w4,loc),loc)
            | (_,_) =>
              if Control.nativeGen()
              then RBUU.word_mul(indexExp, sizeExp, loc)
              else
              RBUU.word_leftShift(indexExp,RBUU.word_logicalRightShift(sizeExp,RBUU.word_constant(0w1,loc),loc),loc)
      in
        (offsetExp, newContext)
      end

  and generateRecordFromList context isMutable (tyList,expList,loc) =
      let
        val (bitmapExp, newContext) = generateBitmap context (tyList,loc)
        val (totalSizeExp, newContext) = generateOffset newContext (tyList,loc)
        val (fieldSizeExpList, newContext) = generateSizeList newContext (tyList, loc)
      in
        (
         RBURECORD
             {
              bitmapExp = bitmapExp,
              totalSizeExp = totalSizeExp,
              fieldList = expList,
              fieldSizeExpList = fieldSizeExpList,
              fieldTyList = tyList,
              isMutable = isMutable,
              loc = loc
             },
         newContext
        )
      end

  and generateNestedRecord context isMutable ([],loc) = 
      raise Control.Bug "empty record should be transformed into unitval"
    | generateNestedRecord context isMutable  ([(tyList,expList)],loc) = 
      generateRecordFromList context isMutable (tyList,expList,loc)
    | generateNestedRecord context isMutable ((tyList,expList)::rest,loc) =
      let
        val (nested, newContext) = generateNestedRecord context isMutable (rest,loc)
      in
        generateRecordFromList newContext isMutable (RT.BOXEDty::tyList,nested::expList,loc)
      end

  and generateEnvBlock context (clusterContext, loc) =
      let
        fun generateEnvRecord context (tyList, expList, fixedSizeList, loc) =
            let
              val newTyList = 
                  map 
                      (fn ty =>
                          case ty of
                            RT.ATOMty => RT.ATOMty
                          | RT.BOXEDty => RT.BOXEDty
                          | RT.DOUBLEty => RT.DOUBLEty
                          | RT.FLOATty => RT.FLOATty
                          | RT.BOUNDVARty _ => ty
                          | RT.SINGLEty _ => ty
                          | RT.UNBOXEDty _ => ty
                          | RT.TAGty _ => RT.ATOMty
                          | RT.SIZEty _ => RT.ATOMty
                          | RT.INDEXty _ => RT.ATOMty
                          | RT.BITMAPty _ => RT.ATOMty
                          | RT.FRAMEBITMAPty _ => RT.ATOMty
                          | RT.ENVBITMAPty _ => RT.ATOMty
                          | RT.PADSIZEty _ => RT.ATOMty
                          | RT.OFFSETty _ => RT.ATOMty
                          | RT.PADty _ =>
                            raise Control.Bug "invalid target type"
                      ) 
                      tyList
              val (bitmapExp, newContext) = generateEnvBitmap context (newTyList, fixedSizeList, loc)
              val totalSize = foldl (fn (w,s) => w + s) 0w0 fixedSizeList
              val (fieldSizeExpList, newContext) = generateSizeList newContext (newTyList, loc)
            in
              (
               RBUENVRECORD
                   {
                    bitmapExp = bitmapExp,
                    totalSize = totalSize,
                    fieldList = expList,
                    fieldSizeExpList = fieldSizeExpList,
                    fieldTyList = tyList,
                    fixedSizeList = fixedSizeList,
                    loc = loc
                   },
               newContext
              )
            end
        fun generateEnvRecordContent context (block,loc) =
            let
              val (varList, fixedSizeList) = ListPair.unzip block
              val tyList = map #ty varList
              val (expList, newContext) =
                  foldr
                      (fn (v as {varKind,ty,...}, (expList, context)) =>
                          case !varKind of
                            ENTRYLABEL codeId => 
                            (RBUENTRYCLOSURE {codeExp = RBULABEL {codeId = codeId, loc = loc}, loc = loc}::expList, context)
                          | INNERLABEL codeId => 
                            (RBUINNERCLOSURE {codeExp = RBULABEL {codeId = codeId, loc = loc}, loc = loc}::expList, context)
                          | _ =>
                            let
                              val (valueSizeExp, newContext) = generateSize context (#ty v,loc)
                            in
                              (RBUVAR {varInfo = v, valueSizeExp = valueSizeExp, loc = loc}::expList, newContext)
                            end)
                      (nil, context)
                      varList
              val fixedSizeList = map BT.WordToUInt32 fixedSizeList
            in
              (tyList, expList, fixedSizeList, newContext)
            end
        fun generateNestedEnvRecord context ([],loc) = (RBUU.emptyRecord loc, context)
          | generateNestedEnvRecord context ([block],loc) = 
            let
              val (tyList, expList, fixedSizeList, newContext) =
                  generateEnvRecordContent context (block,loc)
            in
              generateEnvRecord newContext (tyList,expList,fixedSizeList,loc)
            end
          | generateNestedEnvRecord context (block::rest,loc) =
            let
              val (nested, newContext) = generateNestedEnvRecord context (rest,loc)
              val (tyList, expList, fixedSizeList, newContext) =
                  generateEnvRecordContent newContext (block,loc)
            in
              generateEnvRecord newContext (RT.BOXEDty::tyList,nested::expList,BT.WordToUInt32 (RBUU.pointerSize())::fixedSizeList,loc)
            end
        (* rearrange a list of variables:  priorVars - fixedVars - polyVars*)
        fun rearrange (varList, priorIDs) =
            let
              fun isFixedSizeType (RT.BOUNDVARty _) = false
                | isFixedSizeType (RT.UNBOXEDty _) = false
                | isFixedSizeType _ = true
              val (priorVars,fixedSizeVars,polyVars) =
                  foldl 
                      (fn (varInfo as {varId,displayName,ty,varKind},(L1,L2,L3)) =>
                          if VarIdSet.member(priorIDs,varId) 
                          then (varInfo::L1,L2,L3)
                          else
                            if isFixedSizeType ty
                            then (L1,varInfo::L2,L3)
                            else (L1,L2,varInfo::L3)
                      )
                      ([],[],[])
                      varList
            in
              (priorVars @ fixedSizeVars @ polyVars)
            end
        (* decompose a list of free variables into blocks, 
         * update their varKinds and merge to the surrounding context *)
        fun decompose context (nestLevel, blocks, []) = (rev blocks, context)
          | decompose context (nestLevel, blocks, varList) =
            let
              val MAX_BLOCK_SIZE =
                  if Control.nativeGen()
                  then Word.fromInt MAX_BLOCK_SIZE * RBUU.pointerSize ()
                  else Word.fromInt MAX_BLOCK_SIZE

              fun split (blockSize,block,[] : varInfo list) = (rev block ,[])
                | split (blockSize,block,varList as ((varInfo as {ty,...})::rest)) =
                  let
                    val varSize =
                        case RBUU.constSize ty of
                          SOME x => x
                        | NONE => RBUU.maxSize () (* always reserve 2 words for generic type *)
                    val newBlockSize = blockSize + varSize
                  in
                    if newBlockSize >= MAX_BLOCK_SIZE
                    then (rev block, varList)
                    else split(newBlockSize,(varInfo,varSize)::block,rest)
                  end
              fun updateAndMerge context (offset, block, []) = (rev block, context)
                | updateAndMerge context (offset, block, ((varInfo as {varKind,...}),size)::rest) =
                  let
                    val _ = varKind := FREEWORD {nestLevel = BT.UInt32.fromInt nestLevel, 
                                                 offset = BT.WordToUInt32 offset}
                    val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
                  in
                    updateAndMerge newContext (offset + size, (newVarInfo,size)::block, rest)
                  end
              val (block, restVarList) = split (0w0,[],varList)
            in
              case restVarList of 
                [] => 
                let
                  (*indexes of the last block starts from 0*)
                  val (newBlock, newContext) = updateAndMerge context (0w0,[],block)
                in
                  (rev (newBlock::blocks), newContext)
                end
              | _ => 
                let
                  (*indexes of inner block starts from 1 (including nest pointer)*)
                  val (newBlock, newContext) = updateAndMerge context (RBUU.pointerSize(),[],block)
                in
                  decompose newContext (nestLevel + 1, newBlock::blocks, restVarList)
                end
            end
        (* collect free variables and rearrange*)
        val freeVarList = 
            rearrange 
                (
                 CTX.listFreeVariables clusterContext, 
                 CTX.getFrameBitmapIDs clusterContext
                )
        (* decompose free variables into blocks and update their varKinds*)
        val (blocks, newContext) = decompose context (0,[],freeVarList)
      in
        generateNestedEnvRecord newContext (blocks, loc)
      end
 
  and generateFrameInfo context (entryFunctions, innerFunctions, loc) =
      let
        val tyvars = tvsInFunDeclList (entryFunctions @ innerFunctions)
        val (tyvarFrees, tyvarArgs) =
            ISet.foldr
                (fn (tid,(frees,args)) =>
                    if CTX.isBoundTypeVariable (context,tid) 
                    then (frees,tid::args) 
                    else (tid::frees,args)
                )
                ([],[])
                tyvars
        val (bitmapFree, newContext) = generateFrameBitmap context (tyvarFrees,loc)
        val (tagArgList, newContext) = generateTagList newContext (map RT.BOUNDVARty tyvarArgs, loc)

        val frameInfo = 
            {
             tyvars = tyvarArgs @ tyvarFrees,
             bitmapFree = bitmapFree,
             tagArgList = tagArgList
            }
      in
        (frameInfo, newContext)
      end 
 
  and transformExp context (exp as ccexp) = 
      case exp of
        CC.CCFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
         let
           val (argTyList, bodyTy) =
             case funTy of
               AT.FUNMty{argTyList,bodyTy,...} => (argTyList, bodyTy)
             | _ => raise Control.Bug "invalid function type"
          val (newFunExp, newContext) = transformExp context funExp
          val (newArgExpList, newContext) = transformExpList newContext argExpList
          val newArgTyList = map (transformType newContext) argTyList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
          val newResultTyList = map (transformType context) (ATU.flatTyList bodyTy)
        in
          (
           RBUFOREIGNAPPLY
               {
                funExp = newFunExp,
                argExpList = newArgExpList,
                argTyList = newArgTyList,
                argSizeExpList = argSizeExpList,
                resultTyList = newResultTyList,
                attributes = attributes,
                loc = loc
               },
           newContext
          )
        end

(*
      | CC.CCEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        let
           val (argTyList,bodyTy) = 
             case funTy of
               AT.FUNMty{argTyList, bodyTy,...}  => (argTyList,bodyTy)
             | _ => raise Control.Bug "invalid function type"
          val (newFunExp, newContext) = transformExp context funExp
          val newArgTyList = map (transformType newContext) argTyList
          val newBodyTyList = map (transformType newContext) (ATU.flatTyList bodyTy)
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
          val (resultSizeExpList, newContext) = generateSizeList newContext (newBodyTyList ,loc)
        in
          (
           RBUEXPORTCALLBACK
               {
                funExp = newFunExp,
                argSizeExpList = argSizeExpList,
                resultSizeExpList = resultSizeExpList,
                argTyList = newArgTyList,
                resultTyList = newBodyTyList,
                attributes = attributes,
                loc = loc
               },
           newContext
          )
        end
*)

      | CC.CCSIZEOF {ty, loc} =>
        let
          val newTy = transformType context ty
          val (sizeExp, newContext) = generateSize context (newTy, loc)
        in
          (if Control.nativeGen()
           then sizeExp
           else RBUU.word_mul (sizeExp, RBUU.word_constant(0w4,loc), loc),
           newContext)
        end

      | CC.CCCONSTANT v => (RBUCONSTANT v, context)

      | CC.CCGLOBALSYMBOL {name,kind,ty,loc} =>
        let
          val newTy = transformType context ty
        in
          (RBUGLOBALSYMBOL {name=name,kind=kind,ty=newTy,loc=loc}, context)
        end

      | CC.CCEXCEPTIONTAG {tagValue, loc} => 
        (RBUEXCEPTIONTAG {tagValue = tagValue, loc = loc}, context)

      | CC.CCVAR {varInfo as {displayName, ty, varId}, loc} =>
        (
         case CTX.findVariable(context, varId) of
           SOME (newVarInfo as {varKind = ref (LOCALCODE _),...}) => 
             raise Control.Bug "LOCALCODE used as value : RBUTransformation"
         | SOME (newVarInfo as {varKind = ref (ENTRYLABEL codeId),...}) => 
           (
            RBUENTRYCLOSURE
                {
                 codeExp = RBULABEL {codeId = codeId, loc = loc},
                 loc = loc
                },
            context
           )
         | SOME (newVarInfo as {varKind = ref (INNERLABEL codeId),...}) => 
           (
            RBUINNERCLOSURE
                {
                 codeExp = RBULABEL {codeId = codeId, loc = loc},
                 loc = loc
                },
            context
           )
         | SOME newVarInfo =>
           let
             val (valueSizeExp, newContext) = generateSize context (#ty newVarInfo,loc)
           in
             (RBUVAR {varInfo = newVarInfo, valueSizeExp = valueSizeExp, loc = loc}, newContext)
           end
         | NONE =>
           (
            case varId of 
              T.INTERNAL _ =>
              let
                val newTy = transformType context ty
                val (sizeExp, newContext) = generateSize context (newTy, loc)
                val newVarInfo = 
                    {varId = varId, displayName = displayName, ty = newTy, varKind = ref FREE}
                val newContext = CTX.insertVariable newContext newVarInfo
              in
                (RBUVAR {varInfo = newVarInfo, valueSizeExp = sizeExp, loc = loc}, newContext)
              end
            | T.EXTERNAL _ =>
              let
                val newTy = transformType context ty
                val (sizeExp, newContext) = generateSize context (newTy, loc)
                val newVarInfo = 
                    {varId = varId, displayName = displayName, ty = newTy, varKind = ref EXTERNAL}
              in
                (RBUVAR {varInfo = newVarInfo, valueSizeExp = sizeExp, loc = loc}, newContext)
              end
           )
        )

      | CC.CCGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val (newArrayExp, newContext) = transformExp context arrayExp
          val (newIndexExp, newContext) = transformExp newContext indexExp
          val newElementTy = transformType newContext elementTy
          val (offsetExp, newContext) = generateArrayOffset newContext (newIndexExp, newElementTy, loc)
          val (sizeExp, newContext) = generateSize newContext (newElementTy, loc)
        in
          (
           RBUGETFIELD
               {
                arrayExp = newArrayExp,
                offsetExp = offsetExp,
                sizeExp = sizeExp,
                elementTy = newElementTy,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val newElementTy = transformType context elementTy
          val (newArrayExp, newContext) =transformExp context arrayExp
          val (newIndexExp, newContext) = transformExp newContext indexExp
          val (newValueExp, newContext) = transformExp newContext valueExp
          val (offsetExp, newContext) = generateArrayOffset newContext (newIndexExp, newElementTy, loc)
          val (valueSizeExp, newContext) = generateSize newContext (newElementTy , loc)
          val (valueTagExp, newContext) = generateTag newContext (newElementTy, loc)
        in
          (
           RBUSETFIELD
               {
                arrayExp = newArrayExp,
                offsetExp = offsetExp,
                valueExp = newValueExp,
                valueSizeExp = valueSizeExp,
                valueTagExp = valueTagExp,
                valueTy = newElementTy,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        let
          val (newConsExp, newContext) = transformExp context consExp
          val (newNewTailExp, newContext) = transformExp newContext newTailExp
          val (nestLevelExp, offsetExp, newContext) =  
              generateRecordOffset newContext (tailLabel, consRecordTy, loc)
          val newTailTy = transformType newContext listTy
          val (newTailSizeExp, newContext) =
              generateSize newContext (newTailTy, loc)
          val (newTailTagExp, newContext) =
              generateTag newContext (newTailTy, loc)
        in
          (
           RBUSETTAIL
               {
                consExp = newConsExp,
                newTailExp = newNewTailExp,
                newTailTy = newTailTy,
                newTailSizeExp = newTailSizeExp,
                newTailTagExp = newTailTagExp,
                nestLevelExp = nestLevelExp,
                offsetExp = offsetExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        let
          val (newSizeExp, newContext) = transformExp context sizeExp
          val (newInitialValue, newContext) = transformExp newContext initialValue
          val newElementTy = transformType context elementTy
          val (arraySizeExp, newContext) = generateArrayOffset newContext (newSizeExp, newElementTy, loc)
          val (elementSizeExp, newContext) = generateSize newContext (newElementTy, loc)
          val (bitmapExp, newContext) = generateTag newContext (newElementTy, loc)
        in
          (
           RBUARRAY
               {
                bitmapExp = bitmapExp,
                sizeExp = arraySizeExp,
                initialValue = newInitialValue,
                elementSizeExp = elementSizeExp,
                elementTy = newElementTy,
                isMutable = isMutable,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCCOPYARRAY {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
        let
          val (newSrcExp, newContext) =
              transformExp context srcExp
          val (newSrcIndexExp, newContext) =
              transformExp newContext srcIndexExp
          val (newDstExp, newContext) =
              transformExp newContext dstExp
          val (newDstIndexExp, newContext) =
              transformExp newContext dstIndexExp
          val (newLengthExp, newContext) =
              transformExp newContext lengthExp

          val newElementTy = transformType newContext elementTy

          val (srcOffsetExp, newContext) =
              generateArrayOffset
                  newContext (newSrcIndexExp, newElementTy, loc)
          val (dstOffsetExp, newContext) =
              generateArrayOffset
                  newContext (newDstIndexExp, newElementTy, loc)
          val (elementSizeExp, newContext) =
              generateSize newContext (newElementTy, loc)
          val (elementTagExp, newContext) =
              generateTag newContext (newElementTy, loc)
        in
          (
           RBUCOPYARRAY
               {
                srcExp = newSrcExp,
                srcOffsetExp = srcOffsetExp,
                dstExp = newDstExp,
                dstOffsetExp = dstOffsetExp,
                lengthExp = newLengthExp,
                elementTy = newElementTy,
                elementSizeExp = elementSizeExp,
                elementTagExp = elementTagExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCPRIMAPPLY {primInfo as {name, ty}, argExpList, instTyList, loc} =>
        let
           val (argTyList, bodyTy) =
             case ty of
               AT.FUNMty{argTyList,bodyTy,...} => (argTyList, bodyTy)
             | _ => raise Control.Bug "invalid function type"
          val newArgTyList = map (transformType context) argTyList
          val (newArgExpList, newContext) = transformExpList context argExpList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
          val newResultTyList = map (transformType context) (ATU.flatTyList bodyTy)
          val newInstTyList = map (transformType newContext) instTyList
          val (instSizeExpList, newContext) = generateSizeList newContext (newInstTyList, loc)
          val (instTagExpList, newContext) = generateTagList newContext (newInstTyList, loc)
        in
          (
           RBUPRIMAPPLY
               {
                prim = name,
                argExpList = newArgExpList,
                argSizeExpList = argSizeExpList,
                argTyList = newArgTyList,
                resultTyList = newResultTyList,
                instSizeExpList = instSizeExpList,
                instTagExpList = instTagExpList,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCAPPM 
            {
             funExp as CC.CCTAPP {exp, expTy as AT.POLYty {boundtvars,...}, instTyList,...}, 
             funTy, 
             argExpList, 
             loc
            } =>
        let
          val (argTyList, bodyTy) =
              case funTy of
                AT.FUNMty{argTyList,bodyTy,...} => (argTyList, bodyTy)
              | _ => raise Control.Bug "invalid function type"
          val (newFunExp, newContext) = transformExp context exp
          val (newArgExpList, newContext) = transformExpList newContext argExpList
          val subst = ATU.makeSubst(boundtvars, instTyList)
          val newArgTyList = map ((transformType context) o (ATU.substitute subst)) argTyList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList,loc)
          val (extraArgExpList, newContext) = generateExtraArgExpList newContext (boundtvars, subst, loc)
          val extraArgTyList = map (fn _ => RT.ATOMty) extraArgExpList
          val extraArgSizeExpList = map (fn ty => RBUU.constSizeExp (ty,loc)) extraArgTyList
          val newResultTyList = map (transformType context) (ATU.flatTyList bodyTy)
        in
          (
           RBUAPPM
               {
                funExp = newFunExp,
                argExpList = extraArgExpList @ newArgExpList,
                argTyList = extraArgTyList @ newArgTyList,
                argSizeExpList = extraArgSizeExpList @ argSizeExpList,
                resultTyList = newResultTyList,
                loc = loc
               },
           newContext
          )
        end
                       
      | CC.CCLOCALAPPM 
            {
             funExp as CC.CCTAPP {exp, expTy as AT.POLYty {boundtvars,...}, instTyList,...}, 
             funTy, 
             argExpList, 
             loc
            } =>
        let
          val (argTyList, bodyTy) =
              case funTy of
                AT.FUNMty{argTyList,bodyTy,...} => (argTyList, bodyTy)
              | _ => raise Control.Bug "invalid function type"
          val (funLabel,argVarList) = 
            case exp of 
              CC.CCVAR {varInfo as {displayName, ty, varId}, loc}
               =>
              (case CTX.findVariable(context, varId) of
                SOME (newVarInfo as {varKind = ref (LOCALCODE (codeId, argVarList)),...}) => 
                  (
                   codeId,
                   argVarList
                   )
              | NONE => (
                      print (ClusterCalcFormatter.ccexpToString exp);
                      print (ClusterCalcFormatter.ccexpToString ccexp);
                      print "\n";
                      raise Control.Bug "var not found : RUBTransformation"
                      )
              | _ => (
                      print (ClusterCalcFormatter.ccexpToString exp);
                      print "\n";
                      raise Control.Bug "var of localcode kind expected : RUBTransformation"
                      )
                  )
            | _ => (
                    print (ClusterCalcFormatter.ccexpToString exp);
                    print "\n";
                    raise Control.Bug "var of localcode kind expected : RUBTransformation"
                      )
          val subst = ATU.makeSubst(boundtvars, instTyList)
          val (newArgExpList, newContext) = transformExpList context argExpList
          val newArgTyList = map (transformType newContext) argTyList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList,loc)
          val (extraArgExpList, newContext) = generateExtraArgExpList newContext (boundtvars, subst, loc)
          val extraArgTyList = map (fn _ => RT.ATOMty) extraArgExpList
          val extraArgSizeExpList = map (fn ty => RBUU.constSizeExp (ty,loc)) extraArgTyList
          val newResultTyList = map (transformType context) (ATU.flatTyList bodyTy)
       in
          (
           RBULOCALAPPM
               {
                funLabel = funLabel,
                argVarList = argVarList,
                argExpList = extraArgExpList @ newArgExpList,
                argTyList = extraArgTyList @ newArgTyList,
                argSizeExpList = extraArgSizeExpList @ argSizeExpList,
                resultTyList = newResultTyList,
                loc = loc
               },
           newContext
          )
        end
                       
      | CC.CCAPPM 
         {funExp, 
          funTy, 
          argExpList, 
          loc} =>
        let
          val (argTyList, bodyTy) =
              case funTy of
                AT.FUNMty{argTyList,bodyTy,...} => (argTyList, bodyTy)
              | _ => raise Control.Bug "invalid function type"
          val newArgTyList = map (transformType context) argTyList
          val (newFunExp, newContext) = transformExp context funExp
          val (newArgExpList, newContext) = transformExpList newContext argExpList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
          val newResultTyList = map (transformType context) (ATU.flatTyList bodyTy)
        in
          (*We should have a better technique to identify reccall and inner call*)
          case newFunExp of
            RBUENTRYCLOSURE {codeExp, ...} =>
            (
             RBURECCALL
                 {
                  codeExp = codeExp,
                  argExpList = newArgExpList,
                  argTyList = newArgTyList,
                  argSizeExpList = argSizeExpList,
                  resultTyList = newResultTyList,
                  loc = loc
                 },
             newContext
            )
          | RBUINNERCLOSURE {codeExp, ...} =>
            (
             RBUINNERCALL
                 {
                  codeExp = codeExp,
                  argExpList = newArgExpList,
                  argTyList = newArgTyList,
                  argSizeExpList = argSizeExpList,
                  resultTyList = newResultTyList,
                  loc = loc
                 },
             newContext
            )
          | _ =>
            (
             RBUAPPM
                 {
                  funExp = newFunExp,
                  argExpList = newArgExpList,
                  argTyList = newArgTyList,
                  argSizeExpList = argSizeExpList,
                  resultTyList = newResultTyList,
                  loc = loc
                 },
             newContext
            )
        end

      | CC.CCLOCALAPPM 
         {funExp, 
          funTy, 
          argExpList, 
          loc} =>
        let
           val (argTyList, bodyTy) =
             case funTy of
               AT.FUNMty{argTyList,bodyTy,...} => (argTyList, bodyTy)
             | _ => raise Control.Bug "invalid function type"
          val (funLabel,argVarList) = 
            case funExp of 
              CC.CCVAR {varInfo as {displayName, ty, varId}, loc}
               =>
              (case CTX.findVariable(context, varId) of
                SOME (newVarInfo as {varKind = ref (LOCALCODE (codeId, argVarList)),...}) => 
                  (
                   codeId,
                   argVarList
                   )
              | _ => raise Control.Bug "var of localcode kind expected : RUBTransformation 1")
            | _ => raise Control.Bug "var of localcode kind expected : RUBTransformation 2"
          val newArgTyList = map (transformType context) argTyList
          val (newArgExpList, newContext) = transformExpList context argExpList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
          val newResultTyList = map (transformType context) (ATU.flatTyList bodyTy)
        in
            (
             RBULOCALAPPM
                 {
                  funLabel = funLabel,
                  argVarList = argVarList,
                  argExpList = newArgExpList,
                  argTyList = newArgTyList,
                  argSizeExpList = argSizeExpList,
                  resultTyList = newResultTyList,
                  loc = loc
                 },
             newContext
            )
        end

      | CC.CCTAPP {exp, expTy as AT.POLYty {boundtvars, body}, instTyList, loc} =>
        (
         case RBUU.generateExtraArgTyList (#btvEnv (#staticEnv context)) boundtvars of
           [] => transformExp context exp
         | _ => 
           let
             val (argTyList, funTy, expTy) = 
                 case ATU.tpappTy(expTy, instTyList) of
                   (funTy as AT.FUNMty {annotation, argTyList,...}) => (argTyList, funTy, expTy)
                 | ty => 
                   (
                    [], 
                    AT.FUNMty 
                        {
                         argTyList = [], 
                         bodyTy = ty, 
                         annotation = ATU.freshFunctionAnnotation(),
                         funStatus = ATU.newClosureFunStatus ()
                        },
                    AT.POLYty 
                        {
                         boundtvars = boundtvars, 
                         body = AT.FUNMty 
                                    {
                                     argTyList = [], 
                                     bodyTy = body, 
                                     annotation = ATU.freshFunctionAnnotation(),
                                     funStatus = ATU.newClosureFunStatus ()
                                    }
                        }
                   )
             val argVarList = map Counters.newATVar argTyList
             val bodyExp = 
                 CC.CCAPPM
                     {
                      funExp = CC.CCTAPP{exp = exp, expTy = expTy, instTyList = instTyList, loc = loc},
                      funTy = funTy,
                      argExpList = map (fn v => CC.CCVAR {varInfo = v, loc = loc}) argVarList,
                      loc = loc
                     }
             val newExp = 
                 case argVarList of 
                   [] => bodyExp
                 | _ =>
                   let
                     val funVar = Counters.newATVar funTy
                     val funDecl = 
                         {
                          funVar = funVar,
                          argVarList = argVarList,
                          bodyExp = bodyExp,
                          loc = loc
                         }
                     val clusterDecl =
                         CC.CCCLUSTER
                             {
                              entryFunctions = [funDecl],
                              innerFunctions = [],
                              isRecursive = false,
                              loc = loc
                             }
                   in
                     CC.CCLET
                         {
                          localDeclList = [clusterDecl],
                          mainExp = CC.CCVAR {varInfo = funVar, loc = loc},
                          loc = loc
                         }
                   end
           in
             transformExp context newExp
           end
        )

      | CC.CCTAPP {exp, expTy, instTyList, loc} =>
        raise Control.Bug "invalid polymorphic type"

      | CC.CCLET {localDeclList, mainExp, loc} =>
        let
          val (newLocalDeclList, newContext) = transformDeclList context localDeclList
          val (newMainExp, newContext) = transformExp newContext mainExp
        in
          (
           RBULET
               {
                localDeclList = newLocalDeclList,
                mainExp = newMainExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCMVALUES {expList, tyList, loc} =>
        let
          val (newExpList, newContext) = transformExpList context expList
          val newTyList = map (transformType context) tyList
          val (sizeExpList, newContext) = generateSizeList newContext (newTyList, loc) 
        in
          (
           RBUMVALUES {expList = newExpList, tyList = newTyList, sizeExpList = sizeExpList, loc = loc},
           newContext
          )
        end

      | CC.CCRECORD {expList, 
                     recordTy as AT.RECORDty{fieldTypes,annotation= ref {align,...}}, 
                     annotation, 
                     isMutable,
                     loc} =>
        let
          val (newExpList, newContext) = transformExpList context expList
          val newTyList = map (transformType context) (SEnv.listItems fieldTypes) 
          val padExp = RBUU.word_constant(0w0, loc)
          val blocks = decomposeOrdinaryRecord (align,padExp, newTyList, newExpList)
        in
          generateNestedRecord newContext isMutable (blocks, loc)
        end

      | CC.CCRECORD {expList, recordTy, annotation, isMutable, loc} => 
        raise Control.Bug "invalid record type"

      | CC.CCSELECT {recordExp, label, recordTy, resultTy, loc} =>
        let
          val (newRecordExp, newContext) = transformExp context recordExp
          val (nestLevelExp, offsetExp, newContext) =  generateRecordOffset newContext (label, recordTy,loc)
          val newFieldTy = transformType newContext resultTy
          val (sizeExp, newContext) = generateSize newContext (newFieldTy, loc)
        in
          (
           RBUSELECT
               {
                recordExp = newRecordExp,
                nestLevelExp = nestLevelExp,
                offsetExp = offsetExp,
                sizeExp = sizeExp,
                fieldTy = newFieldTy,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        let
          val (newRecordExp, newContext) = transformExp context recordExp
          val (newValueExp, newContext) = transformExp newContext valueExp
          val (nestLevelExp, offsetExp, newContext) =  generateRecordOffset newContext (label, recordTy,loc)
          val newValueTy = transformType newContext valueTy
          val (valueSizeExp, newContext) = generateSize newContext (newValueTy, loc)
          val (valueTagExp, newContext) = generateTag newContext (newValueTy, loc)
        in
          (
           RBUMODIFY
               {
                recordExp = newRecordExp,
                nestLevelExp = nestLevelExp,
                offsetExp = offsetExp,
                valueExp = newValueExp,
                valueTy = newValueTy,
                valueSizeExp = valueSizeExp,
                valueTagExp = valueTagExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCRAISE {argExp, resultTy, loc} =>
        let
          val (newArgExp, newContext) = transformExp context argExp
        in
          (
           RBURAISE {argExp = newArgExp, loc = loc},
           newContext
          )
        end

      | CC.CCHANDLE {exp, exnVar as {displayName, ty, varId}, handler, loc} =>
        let
          val (newExp, newContext) = transformExp context exp
          val newExnVar = {varId = varId, displayName = displayName, ty = transformType newContext ty, varKind = ref LOCAL}
          val newContext = CTX.insertVariable newContext newExnVar
          val (newHandler, newContext) = transformExp newContext handler
        in
          (
           RBUHANDLE
               {
                exp = newExp,
                exnVar = newExnVar,
                handler = newHandler,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val (newSwitchExp, newContext) = transformExp context switchExp
          val (newDefaultExp, newContext) = transformExp newContext defaultExp
          val (newBranches, newContext) =
              foldr
                  (fn ({constant, exp},(L,C)) =>
                      let
                        val (newConstant, newC) = transformExp C constant
                        val (newExp, newC) = transformExp newC exp
                      in
                        ({constant = newConstant, exp = newExp}::L,newC)
                      end
                  )
                  ([],newContext)
                  branches
        in
          (
           RBUSWITCH
               {
                switchExp = newSwitchExp,
                expTy = transformType newContext expTy,
                branches = newBranches,
                defaultExp = newDefaultExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCCAST {exp, expTy, targetTy, loc} => transformExp context exp

  and transformExpList context [] = ([],context)
    | transformExpList context (exp::rest) =
      let
        val (newExp, newContext) = transformExp context exp
        val (newRest, newContext) = transformExpList newContext rest
      in
        (newExp::newRest, newContext)
      end

  and transformFunction 
          context 
          ({funVar as {ty, displayName, ...}, argVarList, bodyExp, ...} : CC.funDecl, 
           codeId,
           loc
          ) =
      let
        val bodyTy = 
          case ty of 
            AT.FUNMty{bodyTy,...} => bodyTy 
          | _ => ty
        val (newArgVarList, argTyList) = 
            ListPair.unzip
                (
                 map 
                     (fn {displayName, ty, varId} =>
                         let
                           val newTy = transformType context ty
                         in
                           ({varId = varId, displayName = displayName, ty = newTy, varKind = ref ARG}, newTy)
                         end
                     )
                     argVarList
                )
        val newContext = CTX.insertVariables context newArgVarList
        val resultTyList = map (transformType context) (ATU.flatTyList bodyTy)
        val (argSizeExpList,newContext) = generateSizeList newContext (argTyList,loc)
        val (resultSizeExpList,newContext) = generateSizeList newContext (resultTyList,loc)
        val (newBodyExp, newContext) = transformExp newContext bodyExp
      in
        (
         {
          codeId = codeId,
          argVarList = newArgVarList,
          argSizeExpList = argSizeExpList,
          bodyExp = newBodyExp,
          resultTyList = resultTyList,
          resultSizeExpList = resultSizeExpList,
          ffiAttributes = NONE
         } : funDecl,
         newContext
        )
      end

  and transformFunctionList context ([],[], loc) = ([],context)
    | transformFunctionList context (funDecl::L1,codeId::L2, loc) =
      let
        val (newFunDecl, newContext) = transformFunction context (funDecl, codeId, loc)
        val (rest, newContext) = transformFunctionList newContext (L1, L2, loc)
      in
        (newFunDecl::rest, newContext)
      end
    | transformFunctionList _ _ =
      raise Control.Bug "length of fundecl and codeid do not agree :\
                        \ (rbutransformation/main/RBUTransformation.sml)"


  and transformMonoValCode context (codeList, isRecursive, codeValLoc) =
        let
          val codeInfoList =
              foldr 
              (
               fn (
                   code as {funVar = {displayName, ty, varId}, 
                            argVarList, ...} : CC.codeDecl,
                   codeInfoList
                   ) =>
               let
                 val (argVarList, argTyList) = 
                     foldr
                     (fn (
                          {displayName,ty,varId},
                          (argVarList, argTyList)
                          )
                          =>
                          let
                            val newTy = transformType context ty
                          in
                             (
                              {
                               varId = varId, 
                               displayName = displayName, 
                               ty = newTy, 
                               varKind = ref LOCALARG
                               } :: argVarList,
                              newTy :: argTyList
                              )
                          end
                          )
                     (nil, nil)
                     argVarList
                 val codeLabel = Counters.newLocalId ()
                 val codeVarInfo =
                   {
                    varId = varId, 
                    displayName = displayName, 
                    ty = RT.ATOMty,   
                    varKind = ref (LOCALCODE (codeLabel, argVarList))
                    }
               in
                 {
                  code=code, 
                  codeLabel=codeLabel,
                  codeVar=codeVarInfo,
                  argVarList = argVarList,
                  argTyList = argTyList
                  }
                 :: codeInfoList
               end
             )
              nil
              codeList
          val context = CTX.insertVariables context (map #codeVar codeInfoList)
          val (newCodeList, newContext) = 
              foldr 
              (fn (
                   {
                    code={funVar = {ty = funVarTy,...}, bodyExp, loc=codeLoc, ...} : CC.codeDecl, 
                    codeLabel,
                    codeVar, 
                    argVarList,
                    argTyList
                    },
                   (newCodeList, newContext)
                   ) =>
               let
                 val (argSizeExpList, newContext) = generateSizeList newContext (argTyList,codeLoc)
                 val newContext = CTX.insertVariables newContext argVarList
                 val bodyTy = 
                   case funVarTy of 
                     AT.FUNMty{bodyTy,...} => bodyTy 
                   | _ => funVarTy
                 val resultTyList = map (transformType newContext) (ATU.flatTyList bodyTy)
                 val (resultSizeExpList,newContext) = generateSizeList newContext (resultTyList,codeLoc)
                 val (newBodyExp, newContext) = transformExp newContext bodyExp
               in
                 (
                  {
                   codeLabel = codeLabel,
                   argVarList = argVarList,
                   argSizeExpList = argSizeExpList,
                   bodyExp = newBodyExp,
                   resultTyList = resultTyList,
                   resultSizeExpList = resultSizeExpList,
                   loc = codeLoc
                   } :: newCodeList,
                  newContext
                  )
               end
               )
              (nil, context)
              codeInfoList
        in
          (
           [
            RBUVALCODE
            {
             codeList = newCodeList,
             isRecursive = isRecursive,
             loc = codeValLoc
             }
            ],
           newContext
           )
        end

  and transformCluster 
          surroundingContext initialContext 
          (extraArgVarList, entryFunctions, innerFunctions, isRecursive, loc) =
      let
        fun generateLabel makeVarKind ({funVar = {displayName, ty, varId},...} : CC.funDecl) =
            let
              val label = Counters.newLocalId ()
              val labelVarInfo =
                  {varId = varId, displayName = displayName, ty = RT.BOXEDty, varKind = ref (makeVarKind label)}
            in
              (labelVarInfo, label)
            end

        (* insert assumptions of recursive ids*)
        val (entryVars,entryLabels) =  ListPair.unzip (map (generateLabel ENTRYLABEL) entryFunctions)
        val context = CTX.insertVariables initialContext entryVars
        val (innerVars,innerLabels) =  ListPair.unzip (map (generateLabel INNERLABEL) innerFunctions)
        val context = CTX.insertVariables context innerVars
        (* transform functions*)
        val (newEntryFunctions, context) = transformFunctionList context (entryFunctions, entryLabels, loc)
        val (newInnerFunctions, context) = transformFunctionList context (innerFunctions, innerLabels, loc)
        (* generate frame info*)
        val (frameInfo, context) = generateFrameInfo context (newEntryFunctions, newInnerFunctions, loc) 
        (* generate extra code - extra code only appear in a non-recursive, polymorphic cluster*)
        val (extraCode, context) = ECG.generate context loc
        fun makeNewBody exp =
            case extraCode of
              [] => exp
            | _ => RBULET {localDeclList = extraCode, mainExp = exp, loc = loc}
        (* generate env block*)
        val (envExp, newSurroundingContext) = generateEnvBlock surroundingContext (context, loc)
        (* extend entry functions with extra argument and extra code*)
        val newEntryFunctions = 
            map 
                (fn {codeId, argVarList, argSizeExpList, bodyExp, resultTyList, resultSizeExpList, ffiAttributes} =>
                    {
                     codeId = codeId,
                     argVarList = extraArgVarList @ argVarList,
                     argSizeExpList = (map (fn {ty,...} => RBUU.constSizeExp (ty,loc)) extraArgVarList) @ argSizeExpList,
                     bodyExp = makeNewBody bodyExp,
                     resultTyList = resultTyList,
                     resultSizeExpList = resultSizeExpList,
                     ffiAttributes = ffiAttributes
                    }
                )
                newEntryFunctions
      in
        (
         RBUCLUSTER
             {
              frameInfo = frameInfo,
              entryFunctions = newEntryFunctions,
              innerFunctions = newInnerFunctions,
              isRecursive = isRecursive,
              hasClosureEnv = not (RBUU.isEmptyRecord envExp),
              loc = loc
             },
         envExp,
         newSurroundingContext
        )
      end

  and transformClusterDecl
          surroundingContext initialContext
          (extraArgVarList, entryFunctions, innerFunctions, isRecursive, loc) =
      let
        val (clusterDecl, newEntryFunctions, envExp, newContext) =
            case 
              transformCluster surroundingContext initialContext 
                (extraArgVarList,entryFunctions,innerFunctions,isRecursive,loc)
           of (clusterDecl as (RBUCLUSTER {entryFunctions = newEntryFunctions,...}), envExp, newContext) 
                 => (clusterDecl, newEntryFunctions, envExp, newContext) 
            | _  => 
             raise 
               Control.Bug
               "RBUCLUSTER expected from transformCluster : (rbutransformation/main/RBUTransformation.sml)"
             
        val envVar = Counters.newRBUVar LOCAL RT.BOXEDty
        val envDecl = RBUVAL {boundVarList = [envVar], 
                              sizeExpList = [RBUU.constSizeExp (RT.BOXEDty,loc)],
                              tagExpList = [RBUU.constTagExp (RT.BOXEDty, loc)],
                              boundExp = envExp, 
                              loc = loc}
        val (funVars, funDecls) = 
            ListPair.unzip
                (
                 ListPair.map
                     (fn ({funVar = {displayName, ty, varId},...}, {codeId,...}) =>
                         let
                           val varKind =
                               case varId of
                                 T.INTERNAL _ => ref LOCAL
                               | T.EXTERNAL _ => ref EXTERNAL
                           val newFunVar = {varId = varId, 
                                            displayName = displayName, 
                                            ty = RT.BOXEDty, 
                                            varKind = varKind}
                           val newFunDecl =
                               RBUVAL
                                   {
                                    boundVarList = [newFunVar],
                                    sizeExpList = [RBUU.constSizeExp (RT.BOXEDty,loc)],
                                    tagExpList = [RBUU.constTagExp (RT.BOXEDty,loc)],
                                    boundExp = RBUCLOSURE 
                                                   {
                                                    codeExp = RBULABEL {codeId = codeId, loc = loc}, 
                                                    envExp = RBUVAR {varInfo = envVar,
                                                                     valueSizeExp = RBUU.constSizeExp (#ty envVar,loc),
                                                                     loc = loc},
                                                    loc = loc
                                                   },
                                    loc = loc
                                   }
                         in
                           (newFunVar, newFunDecl)
                         end
                     )
                     (entryFunctions, newEntryFunctions)
                )
        val newContext = 
            foldl
                (fn (varInfo as {varKind as ref LOCAL,...}, C) => CTX.insertVariable C varInfo
                  | (varInfo, C) => C
                )
                newContext
                funVars
      in
        (clusterDecl::envDecl::funDecls, newContext)
      end

  and transformCallbackClusterDecl surroundingContext initialContext
                                   (funDecl, attributes, loc) =
      let
        val (clusterDecl, envExp, newContext) = 
            transformCluster surroundingContext initialContext
                             (nil, [funDecl], nil, false, loc)
        val ({frameInfo, entryFunctions=_, innerFunctions, isRecursive,
              hasClosureEnv, loc, ...}, newFunDecl) =
            case clusterDecl of
              RBUCLUSTER (x as {entryFunctions = [funDecl], ...}) =>
              (x, funDecl)
            | _ => raise Control.Bug "transformCallbackClusterDecl"
        val newFunDecl =
            {codeId = #codeId newFunDecl,
             argVarList = #argVarList newFunDecl,
             argSizeExpList = #argSizeExpList newFunDecl,
             bodyExp = #bodyExp newFunDecl,
             resultTyList = #resultTyList newFunDecl,
             resultSizeExpList = #resultSizeExpList newFunDecl,
             ffiAttributes = SOME attributes} : funDecl
        val clusterDecl =
            RBUCLUSTER {frameInfo = frameInfo,
                        entryFunctions = [newFunDecl],
                        innerFunctions = innerFunctions,
                        isRecursive = isRecursive,
                        hasClosureEnv = hasClosureEnv,
                        loc = loc}

        val {funVar, ...} = funDecl
        val codeVar =
            {varId = #varId funVar,
             displayName = #displayName funVar,
             ty = RT.ATOMty,  (* FIXME: code pointer type *)
             varKind = case #varId funVar of
                         T.INTERNAL _ => ref LOCAL
                       | T.EXTERNAL _ => ref EXTERNAL} : varInfo
        val codeLabelExp =
            RBULABEL {codeId = #codeId newFunDecl, loc = loc}

        val nativeCallback =
            Control.nativeGen ()
            andalso #cpu (Control.targetInfo ()) <> "newvm"

        val codeExp =
(*
            if nativeCallback andalso RBUU.isEmptyRecord envExp
            then codeLabelExp
            else
*)
              let
                val (argTyList, bodyTy) =
                    case #ty funVar of
                      AT.FUNMty {argTyList, bodyTy, ...} => (argTyList, bodyTy)
                    | _ => raise Control.Bug "transformCallbackClusterDecl"
                val argTyList = 
                    map (transformType newContext) argTyList
                val resultTyList =
                    map (transformType newContext) (ATU.flatTyList bodyTy)
                val (argSizeExpList, newContext) =
                    generateSizeList newContext (argTyList, loc)
                val (resultSizeExpList, newContext) =
                    generateSizeList newContext (resultTyList, loc)
              in
                RBUCALLBACKCLOSURE {codeExp = codeLabelExp,
                                    envExp = envExp,
                                    argSizeExpList = argSizeExpList,
                                    resultSizeExpList = resultSizeExpList,
                                    argTyList = argTyList,
                                    resultTyList = resultTyList,
                                    attributes = attributes,
                                    loc = loc}
              end

        val codeDecl =
            RBUVAL {boundVarList = [codeVar],
                    sizeExpList = [RBUU.constSizeExp (#ty codeVar, loc)],
                    tagExpList = [RBUU.constTagExp (#ty codeVar, loc)],
                    boundExp = codeExp,
                    loc = loc}
            
        val newContext = CTX.insertVariable newContext codeVar
      in
        ([clusterDecl, codeDecl], newContext)
      end

  and generateWrappers 
          context wrapperContext
          (extraArgVarList, entryFunctions, innerFunctions, isRecursive, loc) =
      let
        val clusterContext = CTX.createContext wrapperContext IEnv.empty
        val (clusterDecl, newEntryFunctions, clusterEnvExp, newWrapperContext) = 
          case transformCluster
                wrapperContext clusterContext
                ([],entryFunctions,innerFunctions,isRecursive,loc)
          of (clusterDecl as RBUCLUSTER {entryFunctions = newEntryFunctions,...}, 
              clusterEnvExp, 
              newWrapperContext) =>
               (clusterDecl, newEntryFunctions, clusterEnvExp, newWrapperContext)
           | _ => raise Control.Bug "RBUCLUSTER expected from transformCluster :\
                                    \ (rbutransformation/main/RBUTransformation.sml)"
        val extraArgSizeExpList = map (fn {ty,...} => RBUU.constSizeExp (ty,loc)) extraArgVarList
        val (wrapperInfoList, newWrapperContext) =
            ListPair.foldr
                (fn ({funVar as {ty,...},...}, {codeId,...}, (L,C)) =>
                    let
                      val (argTyList, bodyTy) = 
                        case ty of 
                          AT.FUNMty {argTyList, bodyTy,...} => (argTyList, bodyTy)
                        | _ => 
                            raise Control.Bug "non FUNMty of funVar :\
                              \(rbutransformation/main/RBUTransformation.sml)"
                      val argTyList = map (transformType C) argTyList
                      val argVarList = map (Counters.newRBUVar ARG) argTyList
                      val (argSizeExpList, C) = generateSizeList C (argTyList, loc)
                      val resultTyList = map (transformType C) (ATU.flatTyList bodyTy)
                      val (resultSizeExpList, C) = generateSizeList C (resultTyList, loc)
                      val wrapperBodyExp =
                          RBUAPPM
                              {
                               funExp = RBUCLOSURE 
                                            {
                                             codeExp = RBULABEL{codeId = codeId, loc = loc}, 
                                             envExp = clusterEnvExp, 
                                             loc = loc
                                            },
                               argExpList = ListPair.map (fn (v, sz) => RBUVAR {varInfo = v,
                                                                                valueSizeExp = sz,
                                                                                loc = loc})
                                                         (argVarList, argSizeExpList),
                               argSizeExpList = argSizeExpList,
                               argTyList = argTyList,
                               resultTyList = resultTyList,
                               loc = loc
                              }
                      val wrapperFunction =
                          {
                           codeId = Counters.newLocalId(),
                           argVarList = extraArgVarList @ argVarList,
                           argSizeExpList = extraArgSizeExpList @ argSizeExpList,
                           bodyExp = wrapperBodyExp,
                           resultTyList = resultTyList,
                           resultSizeExpList = resultSizeExpList,
                           ffiAttributes = NONE
                          }
                      val (frameInfo, C) = generateFrameInfo C ([wrapperFunction],[],loc) 
                    in
                      ((funVar,wrapperFunction,frameInfo)::L,C)
                    end
                )
                ([],newWrapperContext)
                (entryFunctions, newEntryFunctions)
        val (extraCode, newWrapperContext) = ECG.generate newWrapperContext loc
        fun makeBodyExp exp = 
            case extraCode of
              [] => exp
            | _ => RBULET {localDeclList = extraCode, mainExp = exp, loc = loc} 
        val (wrapperEnvExp, newContext) = generateEnvBlock context (newWrapperContext, loc) 
        val wrapperEnvVar = Counters.newRBUVar LOCAL RT.BOXEDty
        val wrapperEnvDecl = 
            RBUVAL 
                {
                 boundVarList = [wrapperEnvVar], 
                 sizeExpList = [RBUU.constSizeExp (RT.BOXEDty, loc)], 
                 tagExpList = [RBUU.constTagExp (RT.BOXEDty, loc)],
                 boundExp = wrapperEnvExp, 
                 loc = loc
                }
        val (wrapperDeclList, newContext) =
            foldr
                (fn (({displayName,ty, varId},
                      {codeId, argVarList, argSizeExpList, bodyExp, resultTyList, resultSizeExpList, ffiAttributes} : funDecl,
                      frameInfo : frameInfo),
                     (declList, context)
                    ) =>
                    let
                      val clusterDecl =
                          RBUCLUSTER
                              {
                               frameInfo = frameInfo,
                               entryFunctions =
                               [
                                {
                                 codeId = codeId,
                                 argVarList = argVarList,
                                 argSizeExpList = argSizeExpList,
                                 bodyExp = makeBodyExp bodyExp,
                                 resultTyList = resultTyList,
                                 resultSizeExpList = resultSizeExpList,
                                 ffiAttributes = ffiAttributes
                                } : funDecl
                               ],
                               innerFunctions = [],
                               isRecursive = false,
                               hasClosureEnv = not (RBUU.isEmptyRecord wrapperEnvExp),
                               loc = loc
                              }
                      val closureVarKind =
                          case varId of
                            T.INTERNAL _ => ref LOCAL
                          | T.EXTERNAL _ => ref EXTERNAL
                      val closureVarInfo =
                          {varId = varId, displayName = displayName, ty = RT.BOXEDty, varKind = closureVarKind}
                      val closureDecl =
                          RBUVAL
                              {
                               boundVarList = [closureVarInfo],
                               sizeExpList = [RBUU.constSizeExp (RT.BOXEDty,loc)],
                               tagExpList = [RBUU.constTagExp (RT.BOXEDty,loc)],
                               boundExp = RBUCLOSURE
                                              {
                                               codeExp = RBULABEL{codeId=codeId,loc=loc}, 
                                               envExp = RBUVAR {varInfo = wrapperEnvVar,
                                                                valueSizeExp = RBUU.constSizeExp (#ty wrapperEnvVar,loc),
                                                                loc = loc},
                                               loc = loc
                                              },
                               loc = loc
                              }
                      val context =
                          case varId of
                            T.INTERNAL _ => CTX.insertVariable context closureVarInfo
                          | T.EXTERNAL _ => context
                    in
                      (clusterDecl::closureDecl::declList,context)
                    end
                )
                ([],newContext)
                wrapperInfoList
      in
        (clusterDecl::wrapperEnvDecl::wrapperDeclList, newContext)
      end

  and transformDecl context decl =
      case decl of
        CC.CCVAL {boundVars, boundExp, loc} =>
        let
          val (newBoundExp, newContext) = transformExp context boundExp
          val (newBoundVars, sizeExps, tagExps, newContext) =
            foldr
            (fn ({displayName, ty, varId}, (L1,L2,L3,C)) =>
             let
               val newTy = transformType context ty
               val (sizeExp, newC) = generateSize C (newTy,loc)
               val (tagExp, newC) = generateTag newC (newTy,loc)
               val (newVarInfo, newContext) =
                 case varId of
                   T.INTERNAL _ => 
                     let
                       val newVarInfo = {varId = varId, displayName = displayName, ty = newTy, varKind = ref LOCAL}
                     in
                       (newVarInfo, CTX.insertVariable newC newVarInfo)
                     end
                 | T.EXTERNAL _ =>
                     (
                      {varId = varId, displayName = displayName, ty = newTy, varKind = ref EXTERNAL},
                      newC
                      )
             in
               (newVarInfo::L1,sizeExp::L2,tagExp::L3,newContext)
             end
             )
            ([],[],[],newContext)
            boundVars
        in
          (
           [
            RBUVAL
                {
                 boundVarList = newBoundVars,
                 sizeExpList = sizeExps,
                 tagExpList = tagExps,
                 boundExp = newBoundExp,
                 loc = loc
                }
           ],
           newContext
          )
        end
        
      | CC.CCVALCODE {code = codeList, isRecursive, loc} =>
        transformMonoValCode context (codeList, isRecursive, loc)

      | CC.CCPOLYVALCODE {btvEnv, code=codeList, isRecursive, loc} =>
        let
          val extraArgTyList = RBUU.generateExtraArgTyList (#btvEnv (#staticEnv context)) btvEnv 
        in
          case extraArgTyList of
            nil =>
              let
                val newContext = CTX.extendBtvEnv context btvEnv
              in
                transformMonoValCode newContext (codeList, isRecursive, loc)
              end
          | _ =>
              raise Control.Bug "non empty extraArgTyList in CCPOLYVALCODE"
        end

      | CC.CCPOLYVAL {btvEnv, boundVar as {displayName, ty, varId}, boundExp, loc} =>
        (
         case RBUU.generateExtraArgTyList (#btvEnv (#staticEnv context)) btvEnv of
           [] =>
           let
             val newContext = CTX.extendBtvEnv context btvEnv
             val newTy = AT.POLYty {boundtvars = btvEnv, body = ty}
             val newBoundVar = {displayName = displayName, ty = newTy, varId = varId}
             val newDecl = CC.CCVAL {boundVars = [newBoundVar], boundExp = boundExp, loc = loc}
           in
             transformDecl newContext newDecl
           end
         | _ =>
           let
             val (argTyList, funTy) =
                 case ty of 
                   AT.FUNMty {annotation, argTyList,...} => (argTyList, ty)
                 | _ => 
                   (
                    [], 
                    AT.FUNMty 
                        {
                         argTyList = [], 
                         bodyTy = ty, 
                         annotation = ATU.freshFunctionAnnotation(),
                         funStatus = ATU.newClosureFunStatus ()
                        }
                   )
             val argVarList = map Counters.newATVar argTyList
             val bodyExp =
                 case argTyList of 
                   [] => boundExp
                 | _ => CC.CCAPPM 
                            {
                             funExp = boundExp, 
                             funTy = funTy, 
                             argExpList = map (fn v => CC.CCVAR {varInfo = v, loc = loc}) argVarList,
                             loc = loc
                            } 
             val funDecl =
                 {
                  funVar = boundVar,
                  argVarList = argVarList,
                  bodyExp = bodyExp,
                  loc = loc
                 } : CC.funDecl
             val newDecl =
                 CC.CCPOLYCLUSTER
                     {
                      btvEnv = btvEnv,
                      entryFunctions = [funDecl],
                      innerFunctions = [],
                      isRecursive = false,
                      loc = loc
                     }
           in
             transformDecl context newDecl
           end
        )
          
      | CC.CCCLUSTER {entryFunctions, innerFunctions, isRecursive, loc} =>
        transformClusterDecl 
            context (CTX.createContext context IEnv.empty)
            ([],entryFunctions, innerFunctions, isRecursive, loc)

      | CC.CCCALLBACKCLUSTER {funDecl, attributes, loc} =>
        (* FIXME *)
        transformCallbackClusterDecl
            context (CTX.createContext context IEnv.empty)
            (funDecl, attributes, loc)

      | CC.CCPOLYCLUSTER {btvEnv, entryFunctions, innerFunctions, isRecursive, loc} =>
        let
          val extraArgTyList = RBUU.generateExtraArgTyList (#btvEnv (#staticEnv context)) btvEnv 
          val extraArgVarList = map (Counters.newRBUVar ARG) extraArgTyList
          val wrapperContext = CTX.insertVariables (CTX.createContext context btvEnv) extraArgVarList
        in
          if isRecursive
          then
            generateWrappers 
                context wrapperContext
                (extraArgVarList,entryFunctions,innerFunctions,isRecursive,loc)
          else
            transformClusterDecl 
                context wrapperContext
                (extraArgVarList,entryFunctions,innerFunctions,isRecursive,loc)
        end

  and transformDeclList context [] = ([],context)
    | transformDeclList context (decl::rest) =
      let
        val (newDeclList, newContext) = transformDecl context decl
        val (newRest, newContext) = transformDeclList newContext rest
      in
        (newDeclList @ newRest, newContext)
      end

  fun transform (stamp:Counters.stamp) declList = 
      let 
          val _ = Counters.init stamp
          val declList = changeKindDeclList VarIdSet.empty declList
          val (newDeclList, _) = transformDeclList (CTX.createEmptyContext ()) declList
      in
          (Counters.getCounterStamp(), newDeclList)
      end

end
