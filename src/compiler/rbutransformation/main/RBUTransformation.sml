(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure RBUTransformation : RBUTRANSFORMATION = struct

  structure BT = BasicTypes
  structure CTX = RBUContext
  structure AT = AnnotatedTypes
  structure T = Types
  structure CT = ConstantTerm
  structure ATU = AnnotatedTypesUtils
  structure CC = ClusterCalc
  structure RBUU = RBUUtils
  structure ECG = ExtraComputationGenerator

  open RBUCalc

  val OFFSET_SHIFT_BITS = 0w16
  val OFFSET_MASK = 0wxFF
  val MAX_BLOCK_SIZE = 31

  infix 8 ++
  fun op ++ (S1,S2) = ISet.union(S1,S2)

  fun tvsInTy ty =
      case ty of
        AT.BOUNDVARty tid => ISet.singleton(tid)
      | AT.SINGLEty tid => ISet.singleton(tid)
      | _ => ISet.empty

  fun tvsInTyList tyList =
      foldl (fn (ty,S) => S ++ (tvsInTy ty)) ISet.empty tyList

  fun tvsInVarInfo ({ty,...} : varInfo) = tvsInTy ty

  fun tvsInVarInfoList varInfoList = 
      foldl (fn (varInfo,S) => S ++ (tvsInVarInfo varInfo)) ISet.empty varInfoList

  fun tvsInExp exp =
      case exp of
        RBUFOREIGNAPPLY {funExp, argExpList, ...} => tvsInExpList (funExp::argExpList)
      | RBUEXPORTCALLBACK {funExp, ...} => tvsInExp funExp
      | RBUCONSTANT _ => ISet.empty
      | RBUEXCEPTIONTAG _ => ISet.empty
      | RBUVAR {varInfo as {ty,...}, loc} => tvsInTy ty
      | RBULABEL _ => ISet.empty
      | RBUGETGLOBAL _ => ISet.empty
      | RBUSETGLOBAL {valueExp,...} => tvsInExp valueExp
      | RBUINITARRAY _ => ISet.empty
      | RBUGETFIELD {arrayExp, ...} => tvsInExp arrayExp
      | RBUSETFIELD {arrayExp, valueExp, valueTy,...} =>
        (tvsInExp arrayExp) ++ (tvsInExp valueExp) ++ (tvsInTy valueTy)
      | RBUSETTAIL {consExp, newTailExp,...} =>
        (tvsInExp consExp) ++ (tvsInExp newTailExp) 
      | RBUARRAY {initialValue, elementTy,...} =>
        (tvsInExp initialValue) ++ (tvsInTy elementTy)
      | RBUPRIMAPPLY {argExpList,...} => tvsInExpList argExpList
      | RBUAPPM {funExp, argExpList, argTyList,...} =>
        (tvsInExpList (funExp::argExpList)) ++ (tvsInTyList argTyList)
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
      | RBUCLOSURE{envExp,...} => tvsInExp envExp
      | RBUENTRYCLOSURE _ => ISet.empty
      | RBUINNERCLOSURE _ => ISet.empty

  and tvsInExpList expList =
      foldl (fn (exp,S) => S ++ (tvsInExp exp)) ISet.empty expList

  and tvsInDecl decl =
      case decl of
        RBUVAL {boundVarList, boundExp,...} =>
        (tvsInVarInfoList boundVarList) ++ (tvsInExp boundExp)
      | RBUCLUSTER _ => ISet.empty

  and tvsInDeclList declList =
      foldl (fn (decl,S) => S ++ (tvsInDecl decl)) ISet.empty declList

  and tvsInFunDecl ({argVarList, bodyExp, resultTyList,...} : funDecl) =
      (tvsInVarInfoList argVarList) ++ (tvsInExp bodyExp) ++ (tvsInTyList resultTyList)

  and tvsInFunDeclList funDeclList =
      foldl (fn (funDecl,S) => S ++ (tvsInFunDecl funDecl)) ISet.empty funDeclList

  fun decomposeOrdinaryRecord (isAligned,pad,tyList,fieldList) =
      let
        val MAX_BLOCK_FIELDS =  if !Control.enableUnboxedFloat then !Control.limitOfBlockFields else MAX_BLOCK_SIZE
        fun align (tyList,fieldList) =
            let
              fun add (NONE, i) = NONE
                | add (SOME n, i) = SOME (n + i)
              fun insert (lengthOpt,tyList,fieldList,[],[]) = (rev tyList,rev fieldList)
                | insert (lengthOpt,tyList,fieldList,ty::tyRest,field::fieldRest) =
                  (
                   case ty of 
                     AT.ATOMty => insert(add(lengthOpt,1),ty::tyList,field::fieldList,tyRest,fieldRest)
                   | AT.BOXEDty =>insert(add(lengthOpt,1),ty::tyList,field::fieldList,tyRest,fieldRest)
                   | AT.DOUBLEty =>
                     if isAligned
                     then
                       let
                         val padTy = AT.PADty {condTy = ty, tyList = rev tyList}
                       in
                         case lengthOpt of
                           SOME n =>
                           if (n mod 2) = 0
                           then insert(SOME(n+2),ty::tyList,field::fieldList,tyRest,fieldRest)
                           else insert(SOME(n+3),ty::AT.ATOMty::tyList,field::pad::fieldList,tyRest,fieldRest)
                         | NONE => insert(NONE,ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                       end
                     else insert(add(lengthOpt,2),ty::tyList,field::fieldList,tyRest,fieldRest)
                   | AT.BOUNDVARty tid =>
                     if isAligned
                     then
                       let
                         val padTy = AT.PADty {condTy = ty, tyList = rev tyList}
                       in
                         case lengthOpt of
                           SOME n =>
                           if (n mod 2) = 0
                           then insert(NONE,ty::tyList,field::fieldList,tyRest,fieldRest)
                           else insert(NONE,ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                         | NONE => insert(NONE,ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                       end 
                     else insert(NONE,ty::tyList,field::fieldList,tyRest,fieldRest)
                   | AT.SINGLEty tid => insert(add(lengthOpt,1),ty::tyList,field::fieldList,tyRest,fieldRest)
                   | AT.UNBOXEDty tid =>
                     if isAligned
                     then
                       let
                         val padTy = AT.PADty {condTy = ty, tyList = rev tyList}
                       in
                         case lengthOpt of
                           SOME n =>
                           if (n mod 2) = 0
                           then insert(NONE,ty::tyList,field::fieldList,tyRest,fieldRest)
                           else insert(NONE,ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                         | NONE => insert(NONE,ty::padTy::tyList,field::pad::fieldList,tyRest,fieldRest)
                       end
                     else insert(NONE,ty::tyList,field::fieldList,tyRest,fieldRest)
                   | _ => raise Control.Bug "decompose: invalid compact type"
                  )
                | insert _ = raise Control.Bug "tyList and fieldList must have the same length"
            in
              insert(SOME 0,[],[],tyList,fieldList)
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
                  if !Control.enableUnboxedFloat andalso !Control.alignRecord
                  then
                    if totalLength = numOfFields
                    then align (blockTyList,blockFieldList)  
                    else 
                      let
                        val (L1,L2) = align(AT.BOXEDty::blockTyList,pad::blockFieldList)
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

  (* transform types appears before rbutransformation into 
   * ATOMty, BOXEDty, DOUBLEty, SINGLEty, UNBOXEDty, BOUNDVARty
   *)
  fun transformType context ty =
      case ty of
        AT.ERRORty => AT.ATOMty
      | AT.DUMMYty _ => AT.ATOMty
      | AT.TYVARty (ref {recKind = AT.REC _,...}) => AT.BOXEDty
      | AT.TYVARty _ => AT.ATOMty
      | AT.BOUNDVARty tid =>
        (
         case CTX.representationOf(context,tid) of
           AT.ATOM_REP => AT.ATOMty
         | AT.BOXED_REP => AT.BOXEDty
         | AT.DOUBLE_REP => if !Control.enableUnboxedFloat then AT.DOUBLEty else AT.BOXEDty
         | AT.SINGLE_REP => AT.SINGLEty tid
         | AT.UNBOXED_REP => if !Control.enableUnboxedFloat then AT.UNBOXEDty tid else ty
         | _ => ty
        )
      | AT.FUNMty _ => AT.BOXEDty
      | AT.MVALty tyList => AT.MVALty (map (transformType context) tyList)
      | AT.RECORDty _ => AT.BOXEDty
      | AT.CONty {tyCon = {boxedKind,...},args} =>
        (
         case !boxedKind of
           T.ATOMty => AT.ATOMty
         | T.BOXEDty => AT.BOXEDty
         | T.DOUBLEty => if !Control.enableUnboxedFloat then AT.DOUBLEty else AT.BOXEDty
         | T.BOUNDVARty _ => raise Control.Bug "not implemented"
        )
      | AT.POLYty {boundtvars, body} => transformType context body
      | AT.BOXEDty => AT.BOXEDty
      | AT.ATOMty => AT.ATOMty
      | AT.DOUBLEty => if !Control.enableUnboxedFloat then AT.DOUBLEty else AT.BOXEDty
      | _ => raise Control.Bug "transformType invalid type"


  fun generateExtraArgTyList (btvEnv : AT.btvEnv) =
      let
        fun generate {id,recKind,eqKind,instancesRef,representationRef} =
            case recKind of
              AT.REC flty =>
              map (fn label => AT.INDEXty{label = label, recordTy = AT.BOUNDVARty id}) (SEnv.listKeys flty)
            | _ =>
              (
               case !representationRef of
                 AT.ATOM_REP => []
               | AT.BOXED_REP => []
               | AT.DOUBLE_REP => []
               | AT.SINGLE_REP => [AT.TAGty id]
               | AT.UNBOXED_REP => [AT.SIZEty id]
               | _ => 
                 if !Control.enableUnboxedFloat
                 then [AT.TAGty id, AT.SIZEty id]
                 else [AT.TAGty id]
              )
      in
        IEnv.foldr (fn (btvKind, L) => (generate btvKind) @ L) [] btvEnv
      end

  fun generateExtraArgExpList context (btvEnv : AT.btvEnv, subst, loc) =
      let
        fun substitute tid =
            case IEnv.find(subst, tid) of
              SOME ty => ty
            | _ => raise Control.Bug "type variable not found"
        val tyList = generateExtraArgTyList btvEnv
      in
        foldr
            (fn (ty, (L,C)) =>
                case ty of
                  AT.INDEXty {label, recordTy as (AT.BOUNDVARty tid)} =>
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
                   | AT.TYVARty (ref {recKind = AT.REC fieldTypes,...}) =>
                     let
                       val groundRecordType = 
                           AT.RECORDty 
                               {
                                fieldTypes = fieldTypes, 
                                annotation = ref {labels = AT.LE_GENERIC, boxed = true, align = false}
                               }
                       val (nestLevelExp, offsetExp, newC) = generateRecordOffset C (label, groundRecordType, loc)
                     in
                       ((encodeIndexExp(nestLevelExp, offsetExp, loc))::L, newC)
                     end
                   | _ => raise Control.Bug "invalid record type"
                  )
                | AT.TAGty tid => 
                  let
                    val (tagExp, newC) = generateTag C (transformType C (substitute tid),loc)
                  in
                    (tagExp::L,newC)
                  end
                | AT.SIZEty tid => 
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
      if !Control.enableUnboxedFloat
      then
        case RBUU.constSize ty of
          SOME w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
        | NONE =>
          (
           case ty of
             AT.UNBOXEDty tid => CTX.lookupSize context (tid,loc)
           | AT.BOUNDVARty tid => CTX.lookupSize context (tid, loc)
           (* this type only appear in the offset/bitmap type*)
           | AT.PADty {condTy, tyList} =>
             let
               val varInfo = RBUU.newVar LOCAL (AT.PADSIZEty {condTy = condTy, tyList = tyList})
               val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
             in
               (RBUVAR {varInfo = newVarInfo, loc = loc},newContext)
             end
           | _ => raise Control.Bug "invalid type"
          )
      else (RBUU.singleSizeExp loc, context)
        
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
           AT.SINGLEty tid => CTX.lookupTag context (tid,loc)
         | AT.BOUNDVARty tid => CTX.lookupTag context (tid, loc)
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
      val tyList = [AT.ATOMty, elemTy]
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
                 SOME tyList' => (n,AT.BOXEDty::tyList')
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
      | AT.TYVARty (ref {recKind = AT.REC fieldTypes,...}) =>
        let
          val groundRecordType = 
              AT.RECORDty 
                  {
                   fieldTypes = fieldTypes, 
                   annotation = ref {labels = AT.LE_GENERIC, boxed = true, align = false}
                  }
        in
          generateRecordOffset context (label, groundRecordType, loc)
        end
      | _ => raise Control.Bug "record type is expected"

  and generateBitmap context (tyList, loc) =
      case RBUU.optimizeBitmap tyList of
        RBUU.BO_CONST w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | RBUU.BO_TYVAR ty => generateTag context (ty,loc)
      | RBUU.BO_NONE =>
        let
          val varInfo = RBUU.newVar LOCAL (AT.BITMAPty tyList)
          val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
        in
          (RBUVAR {varInfo = newVarInfo, loc = loc}, newContext)
        end

  and generateFrameBitmap context ([], loc) = (RBUU.word_constant(0w0,loc),context)
    | generateFrameBitmap context ([tid], loc) = generateTag context (AT.BOUNDVARty tid,loc)
    | generateFrameBitmap context (tidList, loc) =
      let
        val varInfo = RBUU.newVar LOCAL (AT.FRAMEBITMAPty tidList)
        val (newVarInfo as {id,...}, newContext) = CTX.mergeVariable context varInfo
        val _ = CTX.registerFrameBitmapID newContext id
      in
        (RBUVAR {varInfo = newVarInfo, loc = loc}, newContext)
      end

  and generateEnvBitmap context (tyList, fixedSizeList, loc) =
      case RBUU.optimizeEnvBitmap (tyList, fixedSizeList) of
        RBUU.BO_CONST w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | RBUU.BO_TYVAR ty => generateTag context (ty,loc)
      | RBUU.BO_NONE =>
        let
          val varInfo = RBUU.newVar LOCAL (AT.ENVBITMAPty {tyList = tyList, fixedSizeList = fixedSizeList})
          val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
        in
          (RBUVAR {varInfo = newVarInfo, loc = loc}, newContext)
        end

  and generateOffset context (tyList, loc) =
      case RBUU.optimizeOffset tyList of
        RBUU.BO_CONST w => (RBUU.word_constant(BT.WordToUInt32 w,loc), context)
      | RBUU.BO_TYVAR ty => generateSize context (ty,loc)
      | RBUU.BO_NONE =>
        let
          val varInfo = RBUU.newVar LOCAL (AT.OFFSETty tyList)
          val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
        in
          (RBUVAR {varInfo = newVarInfo, loc = loc}, newContext)
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
            | (_,_) =>
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
        generateRecordFromList newContext isMutable (AT.BOXEDty::tyList,nested::expList,loc)
      end

  and generateEnvBlock context (clusterContext, loc) =
      let
        fun generateEnvRecord context (tyList, expList, fixedSizeList, loc) =
            let
              val newTyList = 
                  map 
                      (fn ty =>
                          case ty of
                            AT.ATOMty => AT.ATOMty
                          | AT.BOXEDty => AT.BOXEDty
                          | AT.DOUBLEty => AT.DOUBLEty
                          | AT.BOUNDVARty _ => ty
                          | AT.SINGLEty _ => ty
                          | AT.UNBOXEDty _ => ty
                          | AT.TAGty _ => AT.ATOMty
                          | AT.SIZEty _ => AT.ATOMty
                          | AT.INDEXty _ => AT.ATOMty
                          | AT.BITMAPty _ => AT.ATOMty
                          | AT.FRAMEBITMAPty _ => AT.ATOMty
                          | AT.ENVBITMAPty _ => AT.ATOMty
                          | AT.PADSIZEty _ => AT.ATOMty
                          | AT.OFFSETty _ => AT.ATOMty
                          | _ => raise Control.Bug "invalid target type"
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
        fun generateNestedEnvRecord context ([],loc) = (RBUU.emptyRecord loc, context)
          | generateNestedEnvRecord context ([block],loc) = 
            let
              val (varList, fixedSizeList) = ListPair.unzip block
              val tyList = map #ty varList
              val expList = (*have to clean*)
                  map 
                      (fn (v as {varKind,...}) => 
                          case !varKind of
                            ENTRYLABEL codeId => 
                            RBUENTRYCLOSURE {codeExp = RBULABEL {codeId = codeId, loc = loc}, loc = loc}
                          | INNERLABEL codeId => 
                            RBUINNERCLOSURE {codeExp = RBULABEL {codeId = codeId, loc = loc}, loc = loc}
                          | _ => RBUVAR {varInfo = v, loc = loc})
                      varList 
              val fixedSizeList = map BT.UInt32.fromInt fixedSizeList
            in
              generateEnvRecord context (tyList,expList,fixedSizeList,loc)
            end
          | generateNestedEnvRecord context (block::rest,loc) =
            let
              val (nested, newContext) = generateNestedEnvRecord context (rest,loc)
              val (varList, fixedSizeList) = ListPair.unzip block
              val tyList = map #ty varList
              val expList = 
                  map 
                      (fn (v as {varKind,...}) => 
                          case !varKind of
                            ENTRYLABEL codeId => 
                            RBUENTRYCLOSURE {codeExp = RBULABEL {codeId = codeId, loc = loc}, loc = loc}
                          | INNERLABEL codeId => 
                            RBUINNERCLOSURE {codeExp = RBULABEL {codeId = codeId, loc = loc}, loc = loc}
                          | _ => RBUVAR {varInfo = v, loc = loc})
                      varList 
              val fixedSizeList = map BT.UInt32.fromInt fixedSizeList
            in
              generateEnvRecord newContext (AT.BOXEDty::tyList,nested::expList,0w1::fixedSizeList,loc)
            end
        (* rearrange a list of variables:  priorVars - fixedVars - polyVars*)
        fun rearrange (varList, priorIDs) =
            let
              fun isFixedSizeType (AT.BOUNDVARty _) = false
                | isFixedSizeType (AT.UNBOXEDty _) = false
                | isFixedSizeType _ = true
              val (priorVars,fixedSizeVars,polyVars) =
                  foldl 
                      (fn (varInfo as {id,displayName,ty,varKind},(L1,L2,L3)) =>
                          if ID.Set.member(priorIDs,id) 
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
              fun split (blockSize,block,[] : varInfo list) = (rev block ,[])
                | split (blockSize,block,varList as ((varInfo as {ty,...})::rest)) =
                  let
                    val varSize =
                        if !Control.enableUnboxedFloat
                        then 
                          case ty of
                            AT.DOUBLEty => 2
                          | AT.BOUNDVARty tid => 2 (* always reserve 2 words for generic type *)
                          | AT.UNBOXEDty tid => 2 (* always reserve 2 words for generic type *)
                          | _ => 1
                        else 1
                    val newBlockSize = blockSize + varSize
                  in
                    if newBlockSize >= MAX_BLOCK_SIZE
                    then (rev block, varList)
                    else split(newBlockSize,(varInfo,varSize)::block,rest)
                  end
              fun updateAndMerge context (offset, block, []) = (rev block, context)
                | updateAndMerge context (offset, block, ((varInfo as {varKind,...}),size)::rest) =
                  let
                    val _ = varKind := FREEWORD {nestLevel = BT.UInt32.fromInt nestLevel, offset = BT.UInt32.fromInt offset}
                    val (newVarInfo, newContext) = CTX.mergeVariable context varInfo
                  in
                    updateAndMerge newContext (offset + size, (newVarInfo,size)::block, rest)
                  end
              val (block, restVarList) = split (0,[],varList)
            in
              case restVarList of 
                [] => 
                let
                  (*indexes of the last block starts from 0*)
                  val (newBlock, newContext) = updateAndMerge context (0,[],block)
                in
                  (rev (newBlock::blocks), newContext)
                end
              | _ => 
                let
                  (*indexes of inner block starts from 1 (including nest pointer)*)
                  val (newBlock, newContext) = updateAndMerge context (1,[],block)
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
        val (tagArgList, newContext) = generateTagList newContext (map AT.BOUNDVARty tyvarArgs, loc)

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
        CC.CCFOREIGNAPPLY {funExp, funTy as AT.FUNMty{argTyList,...}, argExpList, convention, loc} =>
         let
          val (newFunExp::newArgExpList, newContext) = transformExpList context (funExp::argExpList)
          val newArgTyList = map (transformType newContext) argTyList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
        in
          (
           RBUFOREIGNAPPLY
               {
                funExp = newFunExp,
                argExpList = newArgExpList,
                argTyList = newArgTyList,
                argSizeExpList = argSizeExpList,
                convention = convention,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCFOREIGNAPPLY {funExp, funTy, argExpList, convention, loc} =>
        raise Control.Bug "invalid function type"

      | CC.CCEXPORTCALLBACK {funExp, funTy as AT.FUNMty{argTyList, bodyTy,...}, loc} =>
        let
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
                loc = loc
               },
           newContext
          )
        end

      | CC.CCEXPORTCALLBACK {funExp, funTy, loc} =>
        raise Control.Bug "invalid function type"

      | CC.CCSIZEOF {ty, loc} =>
        let
          val newTy = transformType context ty
          val (sizeExp, newContext) = generateSize context (newTy, loc)
        in
          (RBUU.makePrimApply (#name Primitives.mulIntPrimInfo,
                               [sizeExp, RBUU.wordBytesExp loc],
                               [AT.ATOMty, AT.ATOMty],
                               loc),
           newContext)
        end

      | CC.CCCONSTANT v => (RBUCONSTANT v, context)

      | CC.CCEXCEPTIONTAG {tagValue, loc} => (RBUEXCEPTIONTAG {tagValue = BT.UInt32.fromInt tagValue, loc = loc}, context)

      | CC.CCVAR {varInfo as {id, displayName, ty}, loc} =>
        (
         case CTX.findVariable(context, id) of
           SOME (newVarInfo as {varKind = ref (ENTRYLABEL codeId),...}) => 
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
         | SOME newVarInfo => (RBUVAR {varInfo = newVarInfo, loc = loc}, context)
         | NONE =>
           let
             val newVarInfo = 
                 {id = id, displayName = displayName, ty = transformType context ty, varKind = ref FREE}
             val newContext = CTX.insertVariable context newVarInfo
           in
             (RBUVAR {varInfo = newVarInfo, loc = loc}, newContext)
           end
        )

      | CC.CCGETGLOBAL {arrayIndex, valueIndex, valueTy, loc} =>
        let
          val newValueTy = transformType context valueTy
          val (valueOffsetExp, newContext) = 
              generateArrayOffset context (RBUU.int_constant (Int32.fromInt valueIndex, loc), newValueTy, loc)
          val valueOffset = RBUU.wordOf valueOffsetExp
        in
          (
           RBUGETGLOBAL
               {
                arrayIndex = arrayIndex,
                valueOffset = valueOffset,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCSETGLOBAL {arrayIndex, valueIndex, valueExp, valueTy, loc} =>
        let
          val newValueTy = transformType context valueTy
          val (valueOffsetExp, newContext) = 
              generateArrayOffset context (RBUU.int_constant (Int32.fromInt valueIndex, loc),newValueTy, loc)
          val valueOffset = RBUU.wordOf valueOffsetExp
          val (newValueExp, newContext) = transformExp newContext valueExp 
          val (valueSizeExp, newContext) = generateSize newContext (newValueTy, loc)
          val valueSize = RBUU.wordOf valueSizeExp
        in
          (
           RBUSETGLOBAL
               {
                arrayIndex = arrayIndex,
                valueOffset = valueOffset,
                valueExp = newValueExp,
                valueSize = valueSize,
                valueTy = newValueTy,
                loc = loc
               },
           newContext
          )
        end
        
      | CC.CCINITARRAY {arrayIndex, size, elementTy, loc} =>
        let
          val newElementTy = transformType context elementTy
          val (sizeExp, newContext) = 
              generateArrayOffset context (RBUU.int_constant(Int32.fromInt size, loc),newElementTy, loc)
          val newSize = RBUU.wordOf sizeExp
        in
          (
           RBUINITARRAY
               {
                arrayIndex = arrayIndex,
                arraySize = newSize,
                elementTy = newElementTy,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val ([newArrayExp,newIndexExp], newContext) =
              transformExpList context [arrayExp, indexExp]
          val newElementTy = transformType newContext elementTy
          val (offsetExp, newContext) = generateArrayOffset newContext (newIndexExp, newElementTy, loc)
        in
          (
           RBUGETFIELD
               {
                arrayExp = newArrayExp,
                offsetExp = offsetExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val newElementTy = transformType context elementTy
          val ([newArrayExp,newIndexExp,newValueExp], newContext) =
              transformExpList context [arrayExp, indexExp, valueExp]
          val (offsetExp, newContext) = generateArrayOffset newContext (newIndexExp, newElementTy, loc)
          val (valueSizeExp, newContext) = generateSize newContext (newElementTy , loc)
        in
          (
           RBUSETFIELD
               {
                arrayExp = newArrayExp,
                offsetExp = offsetExp,
                valueExp = newValueExp,
                valueSizeExp = valueSizeExp,
                valueTy = newElementTy,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        let
          val ([newConsExp,newNewTailExp], newContext) =
            transformExpList context [consExp, newTailExp]
          val (nestLevelExp, offsetExp, newContext) =  
              generateRecordOffset newContext (tailLabel, consRecordTy, loc)
        in
          (
           RBUSETTAIL
               {
                consExp = newConsExp,
                newTailExp = newNewTailExp,
                nestLevelExp = nestLevelExp,
                offsetExp = offsetExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCARRAY {sizeExp, initialValue, elementTy, loc} =>
        let
          val ([newSizeExp,newInitialValue], newContext) =
              transformExpList context [sizeExp, initialValue]
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
                loc = loc
               },
           newContext
          )
        end

      | CC.CCPRIMAPPLY {primInfo as {name, ty as AT.FUNMty{argTyList,...}}, argExpList, loc} =>
        let
          val newArgTyList = map (transformType context) argTyList
          val (newArgExpList, newContext) = transformExpList context argExpList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
        in
          (
           RBUPRIMAPPLY
               {
                primName = name,
                argExpList = newArgExpList,
                argSizeExpList = argSizeExpList,
                argTyList = newArgTyList,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCPRIMAPPLY {primInfo, argExpList, loc} =>        
        raise Control.Bug "invalid function type"

      | CC.CCAPPM 
            {
             funExp as CC.CCTAPP {exp, expTy as AT.POLYty {boundtvars,...}, instTyList,...}, 
             funTy as AT.FUNMty {argTyList,...}, 
             argExpList, 
             loc
            } =>
        let
          val (newFunExp::newArgExpList, newContext) = transformExpList context (exp::argExpList)
          val subst = ATU.makeSubst(boundtvars, instTyList)
          val newArgTyList = map ((transformType context) o (ATU.substitute subst)) argTyList
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList,loc)
          val (extraArgExpList, newContext) = generateExtraArgExpList newContext (boundtvars, subst, loc)
          val extraArgTyList = map (fn _ => AT.ATOMty) extraArgExpList
          val extraArgSizeExpList = map (fn _ => RBUU.singleSizeExp loc) extraArgExpList
        in
          (
           RBUAPPM
               {
                funExp = newFunExp,
                argExpList = extraArgExpList @ newArgExpList,
                argTyList = extraArgTyList @ newArgTyList,
                argSizeExpList = extraArgSizeExpList @ argSizeExpList,
                loc = loc
               },
           newContext
          )
        end
                       
      | CC.CCAPPM {funExp, funTy as AT.FUNMty{argTyList,...}, argExpList, loc} =>
        let
          val newArgTyList = map (transformType context) argTyList
          val (newFunExp::newArgExpList, newContext) = transformExpList context (funExp::argExpList)
          val (argSizeExpList, newContext) = generateSizeList newContext (newArgTyList, loc)
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
                  loc = loc
                 },
             newContext
            )
        end

      | CC.CCAPPM {funExp, funTy, argExpList, loc} =>
        raise Control.Bug "invalid function type"

      | CC.CCTAPP {exp, expTy as AT.POLYty {boundtvars, body}, instTyList, loc} =>
        (
         case generateExtraArgTyList boundtvars of
           [] => transformExp context exp
         | _ => 
           let
             val (argTyList, funTy, expTy) = 
                 case ATU.tpappTy(expTy, instTyList) of
                   (funTy as AT.FUNMty {argTyList,...}) => (argTyList, funTy, expTy)
                 | ty => 
                   (
                    [], 
                    AT.FUNMty 
                        {
                         argTyList = [], 
                         bodyTy = ty, 
                         annotation = ref {labels = AT.LE_GENERIC, boxed = true}
                        },
                    AT.POLYty 
                        {
                         boundtvars = boundtvars, 
                         body = AT.FUNMty 
                                    {
                                     argTyList = [], 
                                     bodyTy = body, 
                                     annotation = ref {labels = AT.LE_GENERIC, boxed = true}
                                    }
                        }
                   )
             val argVarList = map ATU.newVar argTyList
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
                     val funVar = ATU.newVar funTy
                     val funDecl = 
                         {
                          funVar = funVar,
                          argVarList = argVarList,
                          bodyExp = bodyExp,
                          annotation = ATU.freshAnnotationLabel ()
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
          generateNestedRecord newContext  isMutable (blocks, loc)
        end

      | CC.CCRECORD {expList, recordTy, annotation, isMutable, loc} => 
        raise Control.Bug "invalid record type"

      | CC.CCSELECT {recordExp, label, recordTy, loc} =>
        let
          val (newRecordExp, newContext) = transformExp context recordExp
          val (nestLevelExp, offsetExp, newContext) =  generateRecordOffset newContext (label, recordTy,loc)
        in
          (
           RBUSELECT
               {
                recordExp = newRecordExp,
                nestLevelExp = nestLevelExp,
                offsetExp = offsetExp,
                loc = loc
               },
           newContext
          )
        end

      | CC.CCMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        let
          val ([newRecordExp, newValueExp], newContext) = transformExpList context [recordExp, valueExp]
          val (nestLevelExp, offsetExp, newContext) =  generateRecordOffset newContext (label, recordTy,loc)
          val newValueTy = transformType newContext valueTy
          val (valueSizeExp, newContext) = generateSize newContext (newValueTy, loc)
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

      | CC.CCHANDLE {exp, exnVar as {id, displayName, ty}, handler, loc} =>
        let
          val (newExp, newContext) = transformExp context exp
          val newExnVar = {id = id, displayName = displayName, ty = transformType newContext ty, varKind = ref LOCAL}
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
          val ([newSwitchExp, newDefaultExp], newContext) = transformExpList context [switchExp, defaultExp]
          val (newBranches, newContext) =
              foldr
                  (fn ({constant, exp},(L,C)) =>
                      let
                        val ([newConstant, newExp], newC) = transformExpList C [constant,exp]
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
          ({funVar as {ty,...}, argVarList, bodyExp, ...} : CC.funDecl, 
           codeId,
           loc
          ) =
      let
        val bodyTy = case ty of AT.FUNMty{bodyTy,...} => bodyTy | _ => ty
        val (newArgVarList, argTyList) = 
            ListPair.unzip
                (
                 map 
                     (fn {id, displayName,ty} =>
                         let
                           val newTy = transformType context ty
                         in
                           ({id = id, displayName = displayName, ty = newTy, varKind = ref ARG}, newTy)
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
          resultSizeExpList = resultSizeExpList
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

  and transformCluster 
          surroundingContext initialContext 
          (extraArgVarList, entryFunctions, innerFunctions, isRecursive, loc) =
      let
        fun generateLabel makeVarKind ({funVar = {id, displayName, ty},...} : CC.funDecl) =
            let
              val label = ID.generate ()
              val labelVarInfo =
                  {id = id, displayName = displayName, ty = AT.BOXEDty, varKind = ref (makeVarKind label)}
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
                (fn {codeId, argVarList, argSizeExpList, bodyExp, resultTyList, resultSizeExpList} =>
                    {
                     codeId = codeId,
                     argVarList = extraArgVarList @ argVarList,
                     argSizeExpList = (map (fn _ => RBUU.singleSizeExp loc) extraArgVarList) @ argSizeExpList,
                     bodyExp = makeNewBody bodyExp,
                     resultTyList = resultTyList,
                     resultSizeExpList = resultSizeExpList
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
        val (clusterDecl as (RBUCLUSTER {entryFunctions = newEntryFunctions,...}), envExp, newContext) =
            transformCluster 
                surroundingContext initialContext 
                (extraArgVarList,entryFunctions,innerFunctions,isRecursive,loc)
        val envVar = RBUU.newVar LOCAL AT.BOXEDty
        val envDecl = RBUVAL {boundVarList = [envVar], sizeExpList = [RBUU.singleSizeExp loc], boundExp = envExp, loc = loc}
        val (funVars, funDecls) = 
            ListPair.unzip
                (
                 ListPair.map
                     (fn ({funVar = {id, displayName, ty},...}, {codeId,...}) =>
                         let
                           val newFunVar = {id = id, displayName = displayName, ty = AT.BOXEDty, varKind = ref LOCAL}
                           val newFunDecl =
                               RBUVAL
                                   {
                                    boundVarList = [newFunVar],
                                    sizeExpList = [RBUU.singleSizeExp loc],
                                    boundExp = RBUCLOSURE 
                                                   {
                                                    codeExp = RBULABEL {codeId = codeId, loc = loc}, 
                                                    envExp = RBUVAR {varInfo = envVar, loc = loc},
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
        val newContext = CTX.insertVariables newContext funVars
      in
        (clusterDecl::envDecl::funDecls, newContext)
      end

  and generateWrappers 
          context wrapperContext
          (extraArgVarList, entryFunctions, innerFunctions, isRecursive, loc) =
      let
        val clusterContext = CTX.createContext wrapperContext IEnv.empty
        val (clusterDecl as RBUCLUSTER {entryFunctions = newEntryFunctions,...}, clusterEnvExp, newWrapperContext) =
            transformCluster
                wrapperContext clusterContext
                ([],entryFunctions,innerFunctions,isRecursive,loc)
        val extraArgSizeExpList = map (fn _ => RBUU.singleSizeExp loc) extraArgVarList
        val (wrapperInfoList, newWrapperContext) =
            ListPair.foldr
                (fn ({funVar as {ty as AT.FUNMty {argTyList, bodyTy,...},...},...}, {codeId,...}, (L,C)) =>
                    let
                      val argTyList = map (transformType C) argTyList
                      val argVarList = map (RBUU.newVar ARG) argTyList
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
                               argExpList = map (fn v => RBUVAR {varInfo = v, loc = loc}) argVarList,
                               argSizeExpList = argSizeExpList,
                               argTyList = argTyList,
                               loc = loc
                              }
                      val wrapperFunction =
                          {
                           codeId = ID.generate(),
                           argVarList = extraArgVarList @ argVarList,
                           argSizeExpList = extraArgSizeExpList @ argSizeExpList,
                           bodyExp = wrapperBodyExp,
                           resultTyList = resultTyList,
                           resultSizeExpList = resultSizeExpList
                          } : funDecl
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
        val wrapperEnvVar = RBUU.newVar LOCAL AT.BOXEDty
        val wrapperEnvDecl = 
            RBUVAL 
                {
                 boundVarList = [wrapperEnvVar], 
                 sizeExpList = [RBUU.singleSizeExp loc], 
                 boundExp = wrapperEnvExp, 
                 loc = loc
                }
        val (wrapperDeclList, newContext) =
            foldr
                (fn (({id, displayName,ty},
                      {codeId, argVarList, argSizeExpList, bodyExp, resultTyList, resultSizeExpList} : funDecl, 
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
                                 resultSizeExpList = resultSizeExpList
                                } : funDecl
                               ],
                               innerFunctions = [],
                               isRecursive = false,
                               loc = loc
                              }
                      val closureVarInfo =
                          {id = id, displayName = displayName, ty = AT.BOXEDty, varKind = ref LOCAL}
                      val closureDecl =
                          RBUVAL
                              {
                               boundVarList = [closureVarInfo],
                               sizeExpList = [RBUU.singleSizeExp loc],
                               boundExp = RBUCLOSURE
                                              {
                                               codeExp = RBULABEL{codeId=codeId,loc=loc}, 
                                               envExp = RBUVAR {varInfo = wrapperEnvVar, loc = loc}, 
                                               loc = loc
                                              },
                               loc = loc
                              }
                    in
                      (clusterDecl::closureDecl::declList,CTX.insertVariable context closureVarInfo)
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
          val (newBoundVars, sizeExps, newContext) =
              foldr
                  (fn ({id, displayName, ty}, (L1,L2,C)) =>
                      let
                        val newTy = transformType context ty
                        val (sizeExp, newC) = generateSize C (newTy,loc)
                        val newVarInfo = {id = id, displayName = displayName, ty = newTy, varKind = ref LOCAL}
                      in
                          (newVarInfo::L1,sizeExp::L2,CTX.insertVariable newC newVarInfo)
                      end
                  )
                  ([],[],newContext)
                  boundVars
        in
          (
           [
            RBUVAL
                {
                 boundVarList = newBoundVars,
                 sizeExpList = sizeExps,
                 boundExp = newBoundExp,
                 loc = loc
                }
           ],
           newContext
          )
        end

      | CC.CCPOLYVAL {btvEnv, boundVar as {id, displayName, ty}, boundExp, loc} =>
        (
         case generateExtraArgTyList btvEnv of
           [] =>
           let
             val newContext = CTX.extendBtvEnv context btvEnv
             val newTy = AT.POLYty {boundtvars = btvEnv, body = ty}
             val newBoundVar = {id = id, displayName = displayName, ty = newTy}
             val newDecl = CC.CCVAL {boundVars = [newBoundVar], boundExp = boundExp, loc = loc}
           in
             transformDecl newContext newDecl
           end
         | _ =>
           let
             val (argTyList, funTy) =
                 case ty of 
                   AT.FUNMty {argTyList,...} => (argTyList, ty)
                 | _ => 
                   (
                    [], 
                    AT.FUNMty 
                        {
                         argTyList = [], 
                         bodyTy = ty, 
                         annotation = ref {labels = AT.LE_GENERIC, boxed = true}
                        }
                   )
             val argVarList = map ATU.newVar argTyList
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
                  annotation = ATU.freshAnnotationLabel ()
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

      | CC.CCPOLYCLUSTER {btvEnv, entryFunctions, innerFunctions, isRecursive, loc} =>
        let
          val extraArgTyList = generateExtraArgTyList btvEnv 
          val extraArgVarList = map (RBUU.newVar ARG) extraArgTyList
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

  fun transform declList = 
      let 
         val (newDeclList, _) = transformDeclList (CTX.createEmptyContext ()) declList
      in
        newDeclList
      end

end
