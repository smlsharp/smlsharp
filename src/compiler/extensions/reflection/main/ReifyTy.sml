(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure ReifyTy =
struct
  structure UP = UserLevelPrimitive
  structure TC = TypedCalc
  (* structure T = Types *)
  
  open ReifiedTy ReifyUtils ReifiedTyData

  exception ReifyTyFail

  infixr 4 -->
  infix 5 **

  fun printExp (exp:TC.tpexp) =
      print (Bug.prettyPrint (TC.format_tpexp exp))

  fun Boundenv loc btvIdtypIdMap =
      let
        val btvIdBtvIdList = btvIdtypIdMap
        val BtvIdBtvIdList =
            List
              loc
              (BtvIdTy loc)
              (map (fn btvId1 => BtvId loc btvId1)
                   btvIdBtvIdList)
      in
        BtvIdBtvIdList
      end

  fun TagMap loc tagMap =
      List loc StringTy (map (String loc) tagMap)

  fun TaggedLayout loc taggedLayout = 
      case taggedLayout of 
        TAGGED_RECORD {tagMap} =>
        let
          val TagMapRecord = Record loc [("tagMap", TagMap loc tagMap)]
        in
          Con loc (UP.REIFY_conInfo_TAGGED_RECORD loc) (SOME TagMapRecord)
        end
      | TAGGED_OR_NULL {tagMap, nullName} =>
        let
          val TagMapNullNameRecord =
              Record loc [("tagMap", TagMap loc tagMap),
                          ("nullName", String loc nullName)]
        in
          Con
            loc
            (UP.REIFY_conInfo_TAGGED_OR_NULL loc)
            (SOME TagMapNullNameRecord)
        end
      | TAGGED_TAGONLY {tagMap} =>
        let
          val TagMapRecord = Record loc [("tagMap", TagMap loc tagMap)]
        in
          Con loc (UP.REIFY_conInfo_TAGGED_TAGONLY loc) (SOME TagMapRecord)
        end
  fun BoolToWrapRecord loc bool =
      Record loc [("wrap", Bool loc bool)]
  fun StringToFalseNameRecord loc falseName =
      Record loc [("falseName", String loc falseName)]
  fun Layout loc layout = 
      case layout of
        LAYOUT_TAGGED taggedLayout =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_TAGGED loc) 
            (SOME (TaggedLayout loc taggedLayout))
      | LAYOUT_ARG_OR_NULL {wrap} =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_ARG_OR_NULL loc) 
            (SOME (BoolToWrapRecord loc wrap))
      | LAYOUT_SINGLE_ARG {wrap} =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_SINGLE_ARG loc) 
            (SOME (BoolToWrapRecord loc wrap))
      | LAYOUT_CHOICE {falseName} =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_CHOICE loc) 
            (SOME (StringToFalseNameRecord loc falseName))
      | LAYOUT_SINGLE =>
        Con loc 
            (UP.REIFY_conInfo_LAYOUT_SINGLE loc)
            NONE
      | LAYOUT_REF =>
        raise Bug.Bug "LAYOUT_REF"

  fun ReifiedTy loc reifeidTy = 
      case reifeidTy of
        ARRAYty reifiedTy => Con loc (UP.REIFY_conInfo_ARRAYty loc) (SOME (ReifiedTy loc reifiedTy))
      | BOOLty => Con loc (UP.REIFY_conInfo_BOOLty loc) NONE
      | BOTTOMty => Con loc (UP.REIFY_conInfo_BOTTOMty loc) NONE
      | BOXEDty =>  Con loc (UP.REIFY_conInfo_BOXEDty loc) NONE
      | BOUNDVARty btvId => Con loc (UP.REIFY_conInfo_BOUNDVARty loc) (SOME (BtvId loc btvId))
      | CHARty => Con loc (UP.REIFY_conInfo_CHARty loc) NONE
      | CODEPTRty => Con loc (UP.REIFY_conInfo_CODEPTRty loc) NONE
      | CONSTRUCTty _ => raise Bug.Bug "CONSTRUCTty to ReifiedTy"
      | DATATYPEty {longsymbol, id, args, layout,size} =>
        Con
          loc
          (UP.REIFY_conInfo_DATATYPEty loc)
          (SOME (Record
                   loc
                   [("longsymbol", String loc longsymbol),
                     ("id", TypId loc id),
                     ("args", List loc (ReifiedTyTy loc) (map (ReifiedTy loc) args)),
                     ("layout", Layout loc layout),
                     ("size", Int loc size)]))
      | DUMMYty {boxed, size} =>
        Con
          loc
          (UP.REIFY_conInfo_DUMMYty loc)
          (SOME (Record
                   loc
                   [("boxed", Bool loc boxed),
                    ("size", Word loc size)]))
      | EXISTty {boxed, size, id} =>
        Con
          loc
          (UP.REIFY_conInfo_EXISTty loc)
          (SOME (Record
                   loc
                   [("boxed", Option loc BoolTy (Option.map (Bool loc) boxed)),
                    ("size", Option loc Word32Ty (Option.map (Word loc) size)),
                    ("id", Int loc id)]))
      | DYNAMICty reifiedTy => Con loc (UP.REIFY_conInfo_DYNAMICty loc) 
                                   (SOME (ReifiedTy loc reifiedTy))
      | ERRORty => Con loc (UP.REIFY_conInfo_ERRORty loc) NONE
      | EXNTAGty => Con loc (UP.REIFY_conInfo_EXNTAGty loc) NONE
      | EXNty => Con loc (UP.REIFY_conInfo_EXNty loc) NONE
      | FUNMty (tyList, ty)=> 
        Con
          loc
          (UP.REIFY_conInfo_FUNMty loc)
          (SOME (Pair
                   loc
                   (List loc (ReifiedTyTy loc) (map (ReifiedTy loc) tyList))
                   (ReifiedTy loc ty)))
      | IENVMAPty reifiedTy => Con loc (UP.REIFY_conInfo_IENVMAPty loc) 
                                   (SOME (ReifiedTy loc reifiedTy))
      | INT16ty => Con loc (UP.REIFY_conInfo_INT16ty loc) NONE
      | INT64ty => Con loc (UP.REIFY_conInfo_INT64ty loc) NONE
      | INT8ty => Con loc (UP.REIFY_conInfo_INT8ty loc) NONE
      | INTERNALty => Con loc (UP.REIFY_conInfo_INTERNALty loc) NONE
      | INTINFty => Con loc (UP.REIFY_conInfo_INTINFty loc) NONE
      | INT32ty => Con loc (UP.REIFY_conInfo_INT32ty loc) NONE
      | LISTty reifiedTy  => Con loc (UP.REIFY_conInfo_LISTty loc) 
                                 (SOME (ReifiedTy loc reifiedTy))
      | OPAQUEty {longsymbol, id, args, size, boxed} => 
        Con
          loc
          (UP.REIFY_conInfo_OPAQUEty loc)
          (SOME (Record
                   loc
                   [("longsymbol", String loc longsymbol),
                    ("id", TypId loc id),
                    ("args", List loc (ReifiedTyTy loc) (map (ReifiedTy loc) args)),
                    ("size", Int loc size),
                    ("boxed", Bool loc boxed)]))
      | OPTIONty reifiedTy => Con loc (UP.REIFY_conInfo_OPTIONty loc) 
                                  (SOME (ReifiedTy loc reifiedTy))
      | POLYty {boundenv, body} =>
        Con
          loc
          (UP.REIFY_conInfo_POLYty loc)
          (SOME (Record
                   loc
                   [("boundenv", Boundenv loc boundenv),
                    ("body", ReifiedTy loc body)]))
      | PTRty reifiedTy => Con loc (UP.REIFY_conInfo_PTRty loc) (SOME  (ReifiedTy loc reifiedTy))
      | REAL32ty => Con loc (UP.REIFY_conInfo_REAL32ty loc) NONE
      | REAL64ty => Con loc (UP.REIFY_conInfo_REAL64ty loc) NONE
      | RECORDty reifiedTyMap => RecordTy loc reifiedTyMap
      | REFty reifiedTy => Con loc (UP.REIFY_conInfo_REFty loc) 
                               (SOME (ReifiedTy loc reifiedTy))
      | SENVMAPty reifiedTy => Con loc (UP.REIFY_conInfo_SENVMAPty loc) 
                                   (SOME (ReifiedTy loc reifiedTy))
      | STRINGty => Con loc (UP.REIFY_conInfo_STRINGty loc) NONE
      | VOIDty => Con loc (UP.REIFY_conInfo_VOIDty loc) NONE
      | TYVARty => Con loc (UP.REIFY_conInfo_TYVARty loc) NONE
      | UNITty  => Con loc (UP.REIFY_conInfo_UNITty loc) NONE
      | VECTORty reifiedTy => Con loc (UP.REIFY_conInfo_VECTORty loc) 
                                  (SOME (ReifiedTy loc reifiedTy))
      | WORD16ty => Con loc (UP.REIFY_conInfo_WORD16ty loc) NONE
      | WORD64ty => Con loc (UP.REIFY_conInfo_WORD64ty loc) NONE
      | WORD8ty => Con loc (UP.REIFY_conInfo_WORD8ty loc) NONE
      | WORD32ty => Con loc (UP.REIFY_conInfo_WORD32ty loc) NONE
  and RecordTy loc (labelMap : (string * reifiedTy) list)  =
      let
        val StringRieifedTyList =
            List 
              loc
              (StringTy ** ReifiedTyTy loc) 
              (map (fn (label, reifiedTy) => 
                       Pair loc (String loc label) (ReifiedTy loc reifiedTy))
                   labelMap)
      in
        Con loc (UP.REIFY_conInfo_RECORDty loc) (SOME StringRieifedTyList)
      end

  fun tyExpList loc visited lookup (reifeidTy, btvMap)  =
      let
        val tyExpList = tyExpList loc
      in
      case reifeidTy of
        BOUNDVARty btvId => 
        (case lookup btvId of
           SOME {path,id,ty} =>
           BoundTypeVarID.Map.insert
             (btvMap, btvId,
              TypeCast
                loc
                (Var {path=path, id = id, ty = ty, opaque = false})
                (TyRepTy loc))
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
      | OPAQUEty {longsymbol, id, args, size, boxed} => 
        foldl (tyExpList visited lookup) btvMap args
      | RECORDty reifiedTyMap =>
        foldl (tyExpList visited lookup) btvMap (map #2 reifiedTyMap)
      | _ => btvMap
      end


  fun ReifiedTyWithLookUp lookup loc reifeidTy = 
      case reifeidTy of
        ARRAYty reifiedTy =>
        Con loc (UP.REIFY_conInfo_ARRAYty  loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | BOOLty => Con loc (UP.REIFY_conInfo_BOOLty loc) NONE
      | BOTTOMty => Con loc (UP.REIFY_conInfo_BOTTOMty loc) NONE
      | BOXEDty =>  Con loc (UP.REIFY_conInfo_BOXEDty loc) NONE
      | BOUNDVARty btvId => 
        (case lookup btvId of
           SOME {path,id,ty} =>
           Select
             loc
             "reifiedTy"
             (TypeCast
                loc
                (Var {path=path, id = id, ty = ty, opaque = false})
                (TyRepTy loc))
         | NONE =>  Con loc (UP.REIFY_conInfo_BOUNDVARty loc) (SOME (BtvId loc btvId)))
      | CHARty => Con loc (UP.REIFY_conInfo_CHARty loc) NONE
      | CODEPTRty => Con loc (UP.REIFY_conInfo_CODEPTRty loc) NONE
      | CONSTRUCTty _ => raise Bug.Bug "CONSTRUCTty to ReifiedTy"
      | DATATYPEty {longsymbol, id, args, layout,size} => 
        Con
          loc
          (UP.REIFY_conInfo_DATATYPEty loc)
          (SOME (Record
                   loc
                   [("longsymbol", String loc longsymbol),
                     ("id", TypId loc id),
                     ("args", List loc (ReifiedTyTy loc) (map (ReifiedTyWithLookUp lookup loc) args)),
                     ("layout", Layout loc layout),
                     ("size", Int loc size)]))
      | DUMMYty {boxed, size} =>
        Con
          loc
          (UP.REIFY_conInfo_DUMMYty loc)
          (SOME (Record
                   loc
                   [("boxed", Bool loc boxed),
                    ("size", Word loc size)]))
      | EXISTty {boxed, size, id} =>
        Con
          loc
          (UP.REIFY_conInfo_EXISTty loc)
          (SOME (Record
                   loc
                   [("boxed", Option loc BoolTy (Option.map (Bool loc) boxed)),
                    ("size", Option loc Word32Ty (Option.map (Word loc) size)),
                    ("id", Int loc id)]))
      | DYNAMICty reifiedTy => 
        Con loc (UP.REIFY_conInfo_DYNAMICty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | ERRORty => Con loc (UP.REIFY_conInfo_ERRORty loc) NONE
      | EXNTAGty => Con loc (UP.REIFY_conInfo_EXNTAGty loc) NONE
      | EXNty => Con loc (UP.REIFY_conInfo_EXNty loc) NONE
      | FUNMty (tyList, ty)=> 
        Con
          loc
          (UP.REIFY_conInfo_FUNMty loc)
          (SOME (Pair
                   loc
                   (List loc (ReifiedTyTy loc) (map (ReifiedTyWithLookUp lookup loc) tyList))
                   (ReifiedTyWithLookUp lookup loc ty)))
      | INT16ty => Con loc (UP.REIFY_conInfo_INT16ty loc) NONE
      | INT64ty => Con loc (UP.REIFY_conInfo_INT64ty loc) NONE
      | INT8ty => Con loc (UP.REIFY_conInfo_INT8ty loc) NONE
      | INTERNALty => Con loc (UP.REIFY_conInfo_INTERNALty loc) NONE
      | INTINFty => Con loc (UP.REIFY_conInfo_INTINFty loc) NONE
      | INT32ty => Con loc (UP.REIFY_conInfo_INT32ty loc) NONE
      | LISTty reifiedTy  => 
        Con loc (UP.REIFY_conInfo_LISTty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | IENVMAPty reifiedTy  => 
        Con loc (UP.REIFY_conInfo_IENVMAPty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | SENVMAPty reifiedTy  => 
        Con loc (UP.REIFY_conInfo_SENVMAPty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | OPAQUEty {longsymbol, id, args, size, boxed} => 
        Con
          loc
          (UP.REIFY_conInfo_OPAQUEty loc)
          (SOME (Record
                   loc
                   [("longsymbol", String loc longsymbol),
                    ("id", TypId loc id),
                    ("args", List loc (ReifiedTyTy loc) (map (ReifiedTyWithLookUp lookup loc) args)),
                    ("size", Int loc size),
                    ("boxed", Bool loc boxed)]))
      | OPTIONty reifiedTy => 
        Con loc (UP.REIFY_conInfo_OPTIONty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | POLYty {boundenv, body} =>
        Con
          loc
          (UP.REIFY_conInfo_POLYty loc)
          (SOME (Record
                   loc
                   [("boundenv", Boundenv loc boundenv),
                    ("body", ReifiedTyWithLookUp lookup loc body)]))
      | PTRty reifiedTy => 
        Con loc (UP.REIFY_conInfo_PTRty loc) (SOME  (ReifiedTyWithLookUp lookup loc reifiedTy))
      | REAL32ty => Con loc (UP.REIFY_conInfo_REAL32ty loc) NONE
      | REAL64ty => Con loc (UP.REIFY_conInfo_REAL64ty loc) NONE
      | RECORDty reifiedTyMap => RecordTyWithLookUp lookup loc reifiedTyMap
      | REFty reifiedTy => 
        Con loc (UP.REIFY_conInfo_REFty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | STRINGty => Con loc (UP.REIFY_conInfo_STRINGty loc) NONE
      | VOIDty => Con loc (UP.REIFY_conInfo_VOIDty loc) NONE
      | TYVARty => Con loc (UP.REIFY_conInfo_TYVARty loc) NONE
      | UNITty  => Con loc (UP.REIFY_conInfo_UNITty loc) NONE
      | VECTORty reifiedTy => 
        Con loc (UP.REIFY_conInfo_VECTORty loc) (SOME (ReifiedTyWithLookUp lookup loc reifiedTy))
      | WORD16ty => Con loc (UP.REIFY_conInfo_WORD16ty loc) NONE
      | WORD64ty => Con loc (UP.REIFY_conInfo_WORD64ty loc) NONE
      | WORD8ty => Con loc (UP.REIFY_conInfo_WORD8ty loc) NONE
      | WORD32ty => Con loc (UP.REIFY_conInfo_WORD32ty loc) NONE
  and RecordTyWithLookUp lookup loc (labelMap : (string * reifiedTy) list) =
      let
        val StringRieifedTyList =
            List 
              loc
              (StringTy ** ReifiedTyTy loc) 
              (map (fn (label, reifiedTy) => 
                       Pair loc (String loc label) (ReifiedTyWithLookUp lookup loc reifiedTy))
                   labelMap)
      in
        Con loc (UP.REIFY_conInfo_RECORDty loc) (SOME StringRieifedTyList)
      end

  fun ConSet loc (conSet:conSet) =
      let
        val stringRieifedTyOptionList = SEnv.listItemsi conSet
        val StringRieifedTyOptionList =
            List
              loc
              (StringTy ** OptionTy (ReifiedTyTy loc))
              (map (fn (string, reifiedTyOpt) =>
                       Pair loc
                            (String loc string) 
                            (Option loc
                                    (ReifiedTyTy loc)
                                    (Option.map (ReifiedTy loc) reifiedTyOpt))
                   )
                   stringRieifedTyOptionList)
      in
        StringRieifedTyOptionList
      end

  fun ConSetEnv loc conSetEnv = 
      let
        val typIdConSetList = TypID.Map.listItemsi conSetEnv
        val TypIdConSetList =
            List 
              loc
              (TypIdTy loc ** ListTy (StringTy ** OptionTy (ReifiedTyTy loc)))
              (map (fn (typid, conSet) => 
                       (Pair loc (TypId loc typid) (ConSet loc conSet)))
                   typIdConSetList)
      in
        Apply
          loc
          (MonoVar loc (UP.REIFY_exInfo_makeConSetEnv loc))
          TypIdConSetList
      end
  fun TyRep loc {conSetEnv, reifiedTy} =
      Record loc [("conSetEnv", ConSetEnv loc conSetEnv),
                  ("reifiedTy", ReifiedTy loc reifiedTy)]

  fun TyRepWithLookUp lookup loc (tyRep as {conSetEnv, reifiedTy}) =
      let
        val tyRepListExp = 
            List
              loc
              (TyRepTy loc) 
              (BoundTypeVarID.Map.listItems 
                 (tyExpList loc TypID.Map.empty lookup (reifiedTy, BoundTypeVarID.Map.empty)))
        val reifiedTyExp = ReifiedTyWithLookUp lookup loc reifiedTy
        val conSetEnvExp = ConSetEnv loc conSetEnv
        val conSetEnvExp =
            ApplyList
              loc
              (MonoVar loc (UP.REIFY_exInfo_MergeConSetEnvWithTyRepList loc))
              [conSetEnvExp, tyRepListExp]
      in
        Record loc [("conSetEnv", conSetEnvExp), ("reifiedTy", reifiedTyExp)]
      end
end
