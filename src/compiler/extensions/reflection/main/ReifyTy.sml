structure ReifyTy =
struct
  structure UP = UserLevelPrimitive
  structure RC = RecordCalc
  (* structure T = Types *)
  
  open ReifiedTy ReifyUtils ReifiedTyData

  exception ReifyTyFail

  infixr 4 -->
  infix 5 **

  fun printExp (exp:RC.rcexp) = 
      print (Bug.prettyPrint (RC.formatWithoutType_rcexp exp))

  fun Boundenv loc btvIdtypIdMap =
      let
        val btvIdBtvIdList = BoundTypeVarID.Map.listItemsi btvIdtypIdMap
        val BtvIdBtvIdList =
            List 
              loc
              (BtvIdTy() ** BtvIdTy())
              (map (fn (btvId1, btvId2) => Pair loc (BtvId loc btvId1) (BtvId loc btvId2))
                   btvIdBtvIdList)
        val BtvIdBtvIdListToBoundenv = 
            MonoVar (UP.REIFY_exInfo_btvIdBtvIdListToBoundenv())
      in
        Apply loc BtvIdBtvIdListToBoundenv BtvIdBtvIdList
      end

  fun TagMap loc tagMap =
      let
        val stringIntList = SEnv.listItemsi tagMap
        val StringIntList =
            List 
              loc 
              (StringTy ** Int32Ty) 
              (map (fn (l,i) => Pair loc (String loc l) (Int loc i)) stringIntList)
        val StringIntListToTagMap = 
            MonoVar (UP.REIFY_exInfo_stringIntListToTagMap())
      in
        Apply loc StringIntListToTagMap StringIntList
      end

  fun TaggedLayout loc taggedLayout = 
      case taggedLayout of 
        TAGGED_RECORD {tagMap} =>
        let
          val TagMapRecord = 
              Apply 
                loc
                (MonoVar (UP.REIFY_exInfo_tagMapToTagMapRecord()))
                (TagMap loc tagMap)
        in
          Con loc (UP.REIFY_conInfo_TAGGED_RECORD()) (SOME TagMapRecord)
        end
      | TAGGED_OR_NULL {tagMap, nullName} =>
        let
          val TagMapNullNameRecord = 
              ApplyList
                loc
                (MonoVar (UP.REIFY_exInfo_tagMapStringToTagMapNullNameRecord()))
                [TagMap loc tagMap, String loc nullName]
        in
          Con
            loc
            (UP.REIFY_conInfo_TAGGED_OR_NULL())
            (SOME TagMapNullNameRecord)
        end
      | TAGGED_TAGONLY {tagMap} =>
        let
          val TagMapRecord = 
              Apply 
                loc
                (MonoVar (UP.REIFY_exInfo_tagMapToTagMapRecord()))
                (TagMap loc tagMap)
        in
          Con loc (UP.REIFY_conInfo_TAGGED_TAGONLY()) (SOME TagMapRecord)
        end
  fun BoolToWrapRecord loc bool = 
      Apply loc (MonoVar (UP.REIFY_exInfo_boolToWrapRecord())) (Bool loc bool)
  fun StringToFalseNameRecord loc bool = 
      Apply loc (MonoVar (UP.REIFY_exInfo_stringToFalseNameRecord())) (String loc bool)
  fun Layout loc layout = 
      case layout of
        LAYOUT_TAGGED taggedLayout =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_TAGGED()) 
            (SOME (TaggedLayout loc taggedLayout))
      | LAYOUT_ARG_OR_NULL {wrap} =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_ARG_OR_NULL()) 
            (SOME (BoolToWrapRecord loc wrap))
      | LAYOUT_SINGLE_ARG {wrap} =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_SINGLE_ARG()) 
            (SOME (BoolToWrapRecord loc wrap))
      | LAYOUT_CHOICE {falseName} =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_CHOICE()) 
            (SOME (StringToFalseNameRecord loc falseName))
      | LAYOUT_SINGLE =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_SINGLE())
            NONE

  fun ReifiedTy loc reifeidTy = 
      case reifeidTy of
        ARRAYty reifiedTy => Con loc (UP.REIFY_conInfo_ARRAYty()) (SOME (ReifiedTy loc reifiedTy))
      | BOOLty => Con loc (UP.REIFY_conInfo_BOOLty()) NONE
      | BOTTOMty => Con loc (UP.REIFY_conInfo_BOTTOMty()) NONE
      | BOXEDty =>  Con loc (UP.REIFY_conInfo_BOXEDty()) NONE
      | BOUNDVARty btvId => Con loc (UP.REIFY_conInfo_BOUNDVARty()) (SOME (BtvId loc btvId))
      | CHARty => Con loc (UP.REIFY_conInfo_CHARty()) NONE
      | CODEPTRty => Con loc (UP.REIFY_conInfo_CODEPTRty()) NONE
      | CONSTRUCTty _ => raise Bug.Bug "CONSTRUCTty to ReifiedTy"
      | DATATYPEty {longsymbol, id, args, layout,size} => 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy())) 
          [Longsymbol loc longsymbol,
           TypId loc id,
           List loc (ReifiedTyTy ()) (map (ReifiedTy loc) args),
           Layout loc layout,
           Int loc size
          ]
      | DUMMYty {boxed, size} => ApplyList loc (MonoVar (UP.REIFY_exInfo_makeDummyTy ())) [Bool loc boxed, Word loc size]
      | DYNAMICty reifiedTy => Con loc (UP.REIFY_conInfo_DYNAMICty()) (SOME (ReifiedTy loc reifiedTy))
      | ERRORty => Con loc (UP.REIFY_conInfo_ERRORty()) NONE
      | EXNTAGty => Con loc (UP.REIFY_conInfo_EXNTAGty()) NONE
      | EXNty => Con loc (UP.REIFY_conInfo_EXNty()) NONE
      | FUNMty (tyList, ty)=> 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_makeFUNMty ())) 
          [List loc (ReifiedTyTy ()) (map (ReifiedTy loc) tyList), ReifiedTy loc ty ]
      | IENVMAPty reifiedTy => Con loc (UP.REIFY_conInfo_IENVMAPty()) (SOME (ReifiedTy loc reifiedTy))
      | INT16ty => Con loc (UP.REIFY_conInfo_INT16ty()) NONE
      | INT64ty => Con loc (UP.REIFY_conInfo_INT64ty()) NONE
      | INT8ty => Con loc (UP.REIFY_conInfo_INT8ty()) NONE
      | INTERNALty => Con loc (UP.REIFY_conInfo_INTERNALty()) NONE
      | INTINFty => Con loc (UP.REIFY_conInfo_INTINFty()) NONE
      | INT32ty => Con loc (UP.REIFY_conInfo_INT32ty()) NONE
      | LISTty reifiedTy  => Con loc (UP.REIFY_conInfo_LISTty()) (SOME (ReifiedTy loc reifiedTy))
      | OPAQUEty {longsymbol, id, args, size} => 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_longsymbolIdArgsToOpaqueTy())) 
          [Longsymbol loc longsymbol,
           TypId loc id,
           List loc (ReifiedTyTy ()) (map (ReifiedTy loc) args),
           Int loc size
          ]
      | OPTIONty reifiedTy => Con loc (UP.REIFY_conInfo_OPTIONty()) (SOME (ReifiedTy loc reifiedTy))
      | POLYty {boundenv, body} =>
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_boundenvReifiedTyToPolyTy()))
          [Boundenv loc boundenv, ReifiedTy loc body]
      | PTRty reifiedTy => Con loc (UP.REIFY_conInfo_PTRty()) (SOME  (ReifiedTy loc reifiedTy))
      | REAL32ty => Con loc (UP.REIFY_conInfo_REAL32ty()) NONE
      | REAL64ty => Con loc (UP.REIFY_conInfo_REAL64ty()) NONE
      | RECORDLABELty => Con loc (UP.REIFY_conInfo_RECORDLABELty()) NONE
      | RECORDLABELMAPty reifiedTy => Con loc (UP.REIFY_conInfo_RECORDLABELMAPty()) (SOME  (ReifiedTy loc reifiedTy))
      | RECORDty reifiedTyMap => RecordTy loc reifiedTyMap
      | REFty reifiedTy => Con loc (UP.REIFY_conInfo_REFty()) (SOME (ReifiedTy loc reifiedTy))
      | SENVMAPty reifiedTy => Con loc (UP.REIFY_conInfo_SENVMAPty()) (SOME (ReifiedTy loc reifiedTy))
      | STRINGty => Con loc (UP.REIFY_conInfo_STRINGty()) NONE
      | VOIDty => Con loc (UP.REIFY_conInfo_VOIDty()) NONE
      | TYVARty => Con loc (UP.REIFY_conInfo_TYVARty()) NONE
      | UNITty  => Con loc (UP.REIFY_conInfo_UNITty()) NONE
      | VECTORty reifiedTy => Con loc (UP.REIFY_conInfo_VECTORty()) (SOME (ReifiedTy loc reifiedTy))
      | WORD16ty => Con loc (UP.REIFY_conInfo_WORD16ty()) NONE
      | WORD64ty => Con loc (UP.REIFY_conInfo_WORD64ty()) NONE
      | WORD8ty => Con loc (UP.REIFY_conInfo_WORD8ty()) NONE
      | WORD32ty => Con loc (UP.REIFY_conInfo_WORD32ty()) NONE
  and RecordTy loc (labelMap : reifiedTy RecordLabel.Map.map)  =
      let
        val StringRieifedTyList =
            List 
              loc
              (StringTy ** ReifiedTyTy()) 
              (map (fn (label, reifiedTy) => 
                       Pair loc (LabelAsString loc label) (ReifiedTy loc reifiedTy))
                   (RecordLabel.Map.listItemsi labelMap))
      in
        Apply 
          loc
          (MonoVar (UP.REIFY_exInfo_stringReifiedTyListToRecordTy()))
          StringRieifedTyList
      end

  fun tyExpList visited lookup (reifeidTy, btvMap)  =
      case reifeidTy of
        BOUNDVARty btvId => 
        (case lookup btvId of
           SOME {path,id,ty} => 
           BoundTypeVarID.Map.insert(btvMap, btvId, Var {path=path, id = id, ty = TyRepTy()})
         | NONE =>  btvMap)
      | ARRAYty ty => tyExpList visited lookup (ty,btvMap)
      | IENVMAPty ty => tyExpList visited lookup (ty,btvMap)
      | SENVMAPty ty => tyExpList visited lookup (ty,btvMap)
      | LISTty ty  => tyExpList visited lookup (ty,btvMap)
      | OPTIONty ty => tyExpList visited lookup (ty,btvMap)
      | POLYty {boundenv, body = ty} =>
        tyExpList visited lookup  (ty,btvMap)
      | PTRty ty => tyExpList visited lookup  (ty,btvMap)
      | REFty ty => tyExpList visited lookup  (ty,btvMap)
      | DYNAMICty ty => tyExpList visited lookup  (ty,btvMap)
      | DATATYPEty {longsymbol, id, args, layout, size} => 
        foldl (tyExpList visited lookup) btvMap args
      | FUNMty (args, ty)=> 
        foldl (tyExpList visited lookup) (tyExpList visited lookup (ty, btvMap)) args
      | OPAQUEty {longsymbol, id, args, size} => 
        foldl (tyExpList visited lookup) btvMap args
      | RECORDty reifiedTyMap =>
        RecordLabel.Map.foldl (tyExpList visited lookup) btvMap reifiedTyMap
      | _ => btvMap

  fun ReifiedTyWithLookUp lookup loc reifeidTy = 
      case reifeidTy of
        ARRAYty reifiedTy =>
        Con loc (UP.REIFY_conInfo_ARRAYty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | BOOLty => Con loc (UP.REIFY_conInfo_BOOLty()) NONE
      | BOTTOMty => Con loc (UP.REIFY_conInfo_BOTTOMty()) NONE
      | BOXEDty =>  Con loc (UP.REIFY_conInfo_BOXEDty()) NONE
      | BOUNDVARty btvId => 
        (case lookup btvId of
           SOME {path,id,ty} => 
           ApplyList 
             loc
             (MonoVar (UP.REIFY_exInfo_TyRepToReifiedTy()))
             [Var {path=path, id = id, ty = TyRepTy()}]
         | NONE =>  Con loc (UP.REIFY_conInfo_BOUNDVARty()) (SOME (BtvId loc btvId)))
      | CHARty => Con loc (UP.REIFY_conInfo_CHARty()) NONE
      | CODEPTRty => Con loc (UP.REIFY_conInfo_CODEPTRty()) NONE
      | CONSTRUCTty _ => raise Bug.Bug "CONSTRUCTty to ReifiedTy"
      | DATATYPEty {longsymbol, id, args, layout,size} => 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy())) 
          [Longsymbol loc longsymbol,
           TypId loc id,
           List loc (ReifiedTyTy ()) (map (ReifiedTyWithLookUp lookup loc) args),
           Layout loc layout,
           Int loc size
          ]
      | DUMMYty {boxed, size} => 
        ApplyList loc (MonoVar (UP.REIFY_exInfo_makeDummyTy ())) [Bool loc boxed, Word loc size]
      | DYNAMICty reifiedTy => 
        Con loc (UP.REIFY_conInfo_DYNAMICty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | ERRORty => Con loc (UP.REIFY_conInfo_ERRORty()) NONE
      | EXNTAGty => Con loc (UP.REIFY_conInfo_EXNTAGty()) NONE
      | EXNty => Con loc (UP.REIFY_conInfo_EXNty()) NONE
      | FUNMty (tyList, ty)=> 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_makeFUNMty ())) 
          [List loc (ReifiedTyTy ()) (map (ReifiedTyWithLookUp lookup loc) tyList), 
           ReifiedTyWithLookUp lookup loc ty ]
      | INT16ty => Con loc (UP.REIFY_conInfo_INT16ty()) NONE
      | INT64ty => Con loc (UP.REIFY_conInfo_INT64ty()) NONE
      | INT8ty => Con loc (UP.REIFY_conInfo_INT8ty()) NONE
      | INTERNALty => Con loc (UP.REIFY_conInfo_INTERNALty()) NONE
      | INTINFty => Con loc (UP.REIFY_conInfo_INTINFty()) NONE
      | INT32ty => Con loc (UP.REIFY_conInfo_INT32ty()) NONE
      | LISTty reifiedTy  => 
        Con loc (UP.REIFY_conInfo_LISTty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | IENVMAPty reifiedTy  => 
        Con loc (UP.REIFY_conInfo_IENVMAPty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | SENVMAPty reifiedTy  => 
        Con loc (UP.REIFY_conInfo_SENVMAPty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | OPAQUEty {longsymbol, id, args, size} => 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_longsymbolIdArgsToOpaqueTy())) 
          [Longsymbol loc longsymbol,
           TypId loc id,
           List loc (ReifiedTyTy ()) (map (ReifiedTyWithLookUp lookup loc) args),
           Int loc size
          ]
      | OPTIONty reifiedTy => 
        Con loc (UP.REIFY_conInfo_OPTIONty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | POLYty {boundenv, body} =>
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_boundenvReifiedTyToPolyTy()))
          [Boundenv loc boundenv, ReifiedTyWithLookUp lookup loc body]
      | PTRty reifiedTy => 
        Con loc (UP.REIFY_conInfo_PTRty()) (SOME  (ReifiedTyWithLookUp lookup loc reifiedTy))
      | REAL32ty => Con loc (UP.REIFY_conInfo_REAL32ty()) NONE
      | REAL64ty => Con loc (UP.REIFY_conInfo_REAL64ty()) NONE
      | RECORDLABELty => Con loc (UP.REIFY_conInfo_RECORDLABELty()) NONE
      | RECORDLABELMAPty reifiedTy => 
        Con loc (UP.REIFY_conInfo_RECORDLABELMAPty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | RECORDty reifiedTyMap => RecordTyWithLookUp lookup loc reifiedTyMap
      | REFty reifiedTy => 
        Con loc (UP.REIFY_conInfo_REFty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | STRINGty => Con loc (UP.REIFY_conInfo_STRINGty()) NONE
      | VOIDty => Con loc (UP.REIFY_conInfo_VOIDty()) NONE
      | TYVARty => Con loc (UP.REIFY_conInfo_TYVARty()) NONE
      | UNITty  => Con loc (UP.REIFY_conInfo_UNITty()) NONE
      | VECTORty reifiedTy => 
        Con loc (UP.REIFY_conInfo_VECTORty()) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | WORD16ty => Con loc (UP.REIFY_conInfo_WORD16ty()) NONE
      | WORD64ty => Con loc (UP.REIFY_conInfo_WORD64ty()) NONE
      | WORD8ty => Con loc (UP.REIFY_conInfo_WORD8ty()) NONE
      | WORD32ty => Con loc (UP.REIFY_conInfo_WORD32ty()) NONE
  and RecordTyWithLookUp lookup loc (labelMap : reifiedTy RecordLabel.Map.map)  =
      let
        val StringRieifedTyList =
            List 
              loc
              (StringTy ** ReifiedTyTy()) 
              (map (fn (label, reifiedTy) => 
                       Pair loc (LabelAsString loc label) (ReifiedTyWithLookUp lookup loc reifiedTy))
                   (RecordLabel.Map.listItemsi labelMap))
      in
        Apply 
          loc
          (MonoVar (UP.REIFY_exInfo_stringReifiedTyListToRecordTy()))
          StringRieifedTyList
      end

  fun ConSet loc (conSet:conSet) =
      let
        val stringRieifedTyOptionList = SEnv.listItemsi conSet
        val StringRieifedTyOptionList =
            List
              loc
              (StringTy ** OptionTy (ReifiedTyTy()))
              (map (fn (string, reifiedTyOpt) =>
                       Pair loc
                            (String loc string) 
                            (Option loc
                                    (ReifiedTyTy ())
                                    (Option.map (ReifiedTy loc) reifiedTyOpt))
                   )
                   stringRieifedTyOptionList)
        val StringReifiedTyListToConSet = 
            MonoVar (UP.REIFY_exInfo_stringReifiedTyOptionListToConSet())
      in
        Apply loc StringReifiedTyListToConSet StringRieifedTyOptionList
      end

  fun ConSetEnv loc conSetEnv = 
      let
        val typIdConSetList = TypID.Map.listItemsi conSetEnv
        val TypIdConSetList =
            List 
              loc
              (TypIdTy () ** ConSetTy ())
              (map (fn (typid, conSet) => 
                       (Pair loc (TypId loc typid) (ConSet loc conSet)))
                   typIdConSetList)
      in
        Apply
          loc
          (MonoVar (UP.REIFY_exInfo_typIdConSetListToConSetEnv()))
          TypIdConSetList
      end

  fun TyRep loc {conSetEnv, reifiedTy} =
      ApplyList 
        loc
        (MonoVar (UP.REIFY_exInfo_TyRep()))
        [ConSetEnv loc conSetEnv, ReifiedTy loc reifiedTy]

  fun TyRepWithLookUp lookup loc (tyRep as {conSetEnv, reifiedTy}) =
      let
        val tyRepListExp = 
            List
              loc
              (TyRepTy()) 
              (BoundTypeVarID.Map.listItems 
                 (tyExpList TypID.Map.empty lookup (reifiedTy, BoundTypeVarID.Map.empty)))
        val reifiedTyExp = ReifiedTyWithLookUp lookup loc reifiedTy
        val conSetEnvExp = ConSetEnv loc conSetEnv
        val conSetEnvExp =
            ApplyList
              loc
              (MonoVar (UP.REIFY_exInfo_MergeConSetEnvWithTyRepList()))
              [conSetEnvExp, tyRepListExp]
      in
        ApplyList 
          loc
          (MonoVar (UP.REIFY_exInfo_TyRep()))
          [conSetEnvExp, reifiedTyExp]
      end
end
