structure ReifyTy =
struct
  structure UP = UserLevelPrimitive
  structure RC = RecordCalc
  structure T = Types
  
  open ReifiedTy ReifyUtils ReifiedTyData

  exception ReifyTyFail

  infixr 4 -->
  infix 5 **

  fun printExp (exp:RC.rcexp) = 
      print (Bug.prettyPrint (RC.formatWithoutType_rcexp nil exp))

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
            MonoVar (UP.REIFY_btvIdBtvIdListToBoundenv_exInfo())
      in
        Apply loc BtvIdBtvIdListToBoundenv BtvIdBtvIdList
      end

  fun TagMap loc tagMap =
      let
        val stringIntList = SEnv.listItemsi tagMap
        val StringIntList =
            List 
              loc 
              (StringTy ** IntTy) 
              (map (fn (l,i) => Pair loc (String loc l) (Int loc i)) stringIntList)
        val StringIntListToTagMap = 
            MonoVar (UP.REIFY_stringIntListToTagMap_exInfo())
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
                (MonoVar (UP.REIFY_tagMapToTagMapRecord_exInfo()))
                (TagMap loc tagMap)
        in
          Con loc (UP.REIFY_TAGGED_RECORD_conInfo()) (SOME TagMapRecord)
        end
      | TAGGED_OR_NULL {tagMap, nullName} =>
        let
          val TagMapNullNameRecord = 
              ApplyList
                loc
                (MonoVar (UP.REIFY_tagMapStringToTagMapNullNameRecord_exInfo()))
                [TagMap loc tagMap, String loc nullName]
        in
          Con
            loc
            (UP.REIFY_TAGGED_OR_NULL_conInfo())
            (SOME TagMapNullNameRecord)
        end
      | TAGGED_TAGONLY {tagMap} =>
        let
          val TagMapRecord = 
              Apply 
                loc
                (MonoVar (UP.REIFY_tagMapToTagMapRecord_exInfo()))
                (TagMap loc tagMap)
        in
          Con loc (UP.REIFY_TAGGED_TAGONLY_conInfo()) (SOME TagMapRecord)
        end
  fun BoolToWrapRecord loc bool = 
      Apply loc (MonoVar (UP.REIFY_boolToWrapRecord_exInfo())) (Bool loc bool)
  fun StringToFalseNameRecord loc bool = 
      Apply loc (MonoVar (UP.REIFY_stringToFalseNameRecord_exInfo())) (String loc bool)
  fun Layout loc layout = 
      case layout of
        LAYOUT_TAGGED taggedLayout =>
        Con loc 
            (UP.REIFY_LAYOUT_TAGGED_conInfo()) 
            (SOME (TaggedLayout loc taggedLayout))
      | LAYOUT_ARG_OR_NULL {wrap} =>
        Con loc 
            (UP.REIFY_LAYOUT_ARG_OR_NULL_conInfo()) 
            (SOME (BoolToWrapRecord loc wrap))
      | LAYOUT_SINGLE_ARG {wrap} =>
        Con loc 
            (UP.REIFY_LAYOUT_SINGLE_ARG_conInfo()) 
            (SOME (BoolToWrapRecord loc wrap))
      | LAYOUT_CHOICE {falseName} =>
        Con loc 
            (UP.REIFY_LAYOUT_CHOICE_conInfo()) 
            (SOME (StringToFalseNameRecord loc falseName))
      | LAYOUT_SINGLE =>
        Con loc 
            (UP.REIFY_LAYOUT_SINGLE_conInfo())
            NONE

  fun ReifiedTy loc reifeidTy = 
      case reifeidTy of
        INTERNALty int => Con loc (UP.REIFY_INTERNALty_conInfo()) (SOME (Int loc int))
      | BOUNDVARty btvId => 
        Con loc (UP.REIFY_BOUNDVARty_conInfo()) (SOME (BtvId loc btvId))
      | CODEPTRty =>
        Con loc (UP.REIFY_CODEPTRty_conInfo()) NONE
      | EXNTAGty =>
        Con loc (UP.REIFY_EXNTAGty_conInfo()) NONE
      | INTty =>
        Con loc (UP.REIFY_INTty_conInfo()) NONE
      | INT8ty =>
        Con loc (UP.REIFY_INT8ty_conInfo()) NONE
      | INT16ty =>
        Con loc (UP.REIFY_INT16ty_conInfo()) NONE
      | INT64ty =>
        Con loc (UP.REIFY_INT64ty_conInfo()) NONE
      | INTINFty =>
        Con loc (UP.REIFY_INTINFty_conInfo()) NONE
      | BOOLty =>
        Con loc (UP.REIFY_BOOLty_conInfo()) NONE
      | WORDty =>
        Con loc (UP.REIFY_WORDty_conInfo()) NONE
      | WORD8ty =>
        Con loc (UP.REIFY_WORD8ty_conInfo()) NONE
      | WORD16ty =>
        Con loc (UP.REIFY_WORD16ty_conInfo()) NONE
      | WORD64ty =>
        Con loc (UP.REIFY_WORD64ty_conInfo()) NONE
      | CHARty =>
        Con loc (UP.REIFY_CHARty_conInfo()) NONE
      | STRINGty =>
        Con loc (UP.REIFY_STRINGty_conInfo()) NONE
      | REALty =>
        Con loc (UP.REIFY_REALty_conInfo()) NONE
      | REAL32ty =>
        Con loc (UP.REIFY_REAL32ty_conInfo()) NONE
      | UNITty  =>
        Con loc (UP.REIFY_UNITty_conInfo()) NONE
      | EXNty =>
        Con loc (UP.REIFY_EXNty_conInfo()) NONE
      | PTRty reifiedTy =>
        Con loc (UP.REIFY_PTRty_conInfo()) (SOME  (ReifiedTy loc reifiedTy))
      | DUMMYty {boxed, size} =>
        ApplyList 
          loc
          (MonoVar (UP.REIFY_makeDummyTy_exInfo ()))
          [Bool loc boxed,
           Word loc size]
      | ERRORty =>
        Con loc (UP.REIFY_ERRORty_conInfo()) NONE
      | FUNty =>
        Con loc (UP.REIFY_FUNty_conInfo()) NONE
      | TYVARty =>
        Con loc (UP.REIFY_TYVARty_conInfo()) NONE
      | LISTty reifiedTy  =>
        Con loc (UP.REIFY_LISTty_conInfo()) (SOME (ReifiedTy loc reifiedTy))
      | ARRAYty reifiedTy =>
        Con loc (UP.REIFY_ARRAYty_conInfo()) (SOME (ReifiedTy loc reifiedTy))
      | VECTORty reifiedTy =>
        Con loc (UP.REIFY_VECTORty_conInfo()) (SOME (ReifiedTy loc reifiedTy))
      | OPTIONty reifiedTy =>
        Con loc (UP.REIFY_OPTIONty_conInfo()) (SOME (ReifiedTy loc reifiedTy))
      | REFty reifiedTy =>
        Con loc (UP.REIFY_REFty_conInfo()) (SOME (ReifiedTy loc reifiedTy))
      | RECORDty reifiedTyMap => RecordTy loc reifiedTyMap
      | DATATYPEty {longsymbol, id, args, layout,size} => 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_longsymbolIdArgsLayoutListToDatatypeTy_exInfo())) 
          [Longsymbol loc longsymbol,
           TypId loc id,
           List loc (ReifiedTyTy ()) (map (ReifiedTy loc) args),
           Layout loc layout,
           Int loc size
          ]
      | OPAQUEty {longsymbol, id, args, size} => 
        ApplyList 
          loc
          (MonoVar (UP.REIFY_longsymbolIdArgsToOpaqueTy_exInfo())) 
          [Longsymbol loc longsymbol,
           TypId loc id,
           List loc (ReifiedTyTy ()) (map (ReifiedTy loc) args),
           Int loc size
          ]
      | POLYty {boundenv, body} =>
        ApplyList 
          loc
          (MonoVar (UP.REIFY_boundenvReifiedTyToPolyTy_exInfo()))
          [Boundenv loc boundenv, ReifiedTy loc body]
      | CONSTRUCTty _ => raise Bug.Bug "CONSTRUCTty to ReifiedTy"
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
          (MonoVar (UP.REIFY_stringReifiedTyListToRecordTy_exInfo()))
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
            MonoVar (UP.REIFY_stringReifiedTyOptionListToConSet_exInfo())
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
          (MonoVar (UP.REIFY_typIdConSetListToConSetEnv_exInfo()))
          TypIdConSetList
      end

  fun TyRep loc {conSetEnv, reifiedTy} =
      ApplyList 
        loc
        (MonoVar (UP.REIFY_TyRep_exInfo()))
        [ConSetEnv loc conSetEnv, ReifiedTy loc reifiedTy]
end
