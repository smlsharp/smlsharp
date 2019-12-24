(**
 * UserLevelPrimitive
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @author Tomohiro Sasaki
 *)


structure UserLevelPrimitive =
struct
  local
    structure N = NameEvalEnv
    structure I = IDCalc
    structure S = Symbol
    structure T = Types
    structure E = EvalIty
    structure L = LongsymbolEnv

    exception IDNotFound of string

    fun mkLongsymbol longid = S.mkLongsymbol longid Loc.noloc

    val stack = ref LongsymbolEnv.empty : IDCalc.exInfo LongsymbolEnv.map ref
    fun insert exInfo = stack := LongsymbolEnv.insert (!stack, #longsymbol exInfo, exInfo)

    fun get name x = 
        case !x of
          NONE => raise IDNotFound name
        | SOME v => v
  
    fun getVar name x = 
        let
          val exInfo = 
              case !x of
                NONE => raise IDNotFound name
              | SOME v => v
        in
          I.ICEXVAR {exInfo = exInfo, longsymbol = #longsymbol exInfo}
        end
  
    fun getVarInfo name x =
        let
          val exInfo = 
              case !x of
                NONE => raise IDNotFound name
              | SOME v => v
        in
          {path = #longsymbol exInfo, 
           ty = E.evalIty E.emptyContext (#ty exInfo)}
        end        

    fun getExExnInfo name x =
        case !x of
          NONE => raise IDNotFound name
        | SOME v => v

    fun findCon ({Env,...}:N.topEnv) longid =
        case N.findId (Env, mkLongsymbol longid) of
          NONE => 
          (Bug.printError "not found (findCon):";
           Bug.printError (String.concatWith "." longid);
           Bug.printError "\n";
           NONE)
        | SOME (I.IDCON {id, longsymbol, ty}) =>
          SOME {id = id, path = longsymbol,
                ty = E.evalIty E.emptyContext ty}
        | SOME _ => 
          (Bug.printError "not found (findCon):";
           Bug.printError (String.concatWith "." longid);
           Bug.printError "\n";
           NONE)

    fun findIDCalcCon ({Env,...}:N.topEnv) longid =
        case N.findId(Env, mkLongsymbol longid) of
          SOME (I.IDCON {id, longsymbol, ty}) =>
          SOME {longsymbol=longsymbol, id=id, ty=ty}
        | _ => 
          (Bug.printError "not found (findIDCalcCon):";
           Bug.printError (String.concatWith "." longid);
           Bug.printError "\n";
           NONE)


    (*
       type exExnInfo = {path: Symbol.longsymbol, ty: ty}
       IDEXEXN of {longsymbol:longsymbol, version:version, ty:ty} * bool ref
       IDEXEXNREP of {ty:ty, version:version, longsymbol:longsymbol} * bool ref
     *)
    fun findExExnInfo ({Env,...}:N.topEnv) longid =
        case N.findId(Env, mkLongsymbol longid) of
          SOME (I.IDEXEXN {used, longsymbol,version, ty}) => 
          SOME {path = longsymbol, ty = E.evalIty E.emptyContext ty}
        | SOME (I.IDEXEXNREP {used, longsymbol,version, ty}) => 
          SOME {path = longsymbol, ty = E.evalIty E.emptyContext ty}
        | _ => 
          (Bug.printError "not found (findExExnInfo):";
           Bug.printError (String.concatWith "." longid);
           Bug.printError "\n";
           NONE)


    fun findVar ({Env,...}:N.topEnv) longid =
        let
          val longsymbol = mkLongsymbol longid
        in
          case N.findId (Env, longsymbol) of
            NONE => 
            (Bug.printError "not found (findVar):";
             Bug.printError (String.concatWith "." longid);
             Bug.printError "\n";
             NONE)
          | SOME (I.IDEXVAR {exInfo= exInfo as {used,...},...}) => 
            (if !used then () else (used := true; insert exInfo); SOME exInfo)
          | SOME _ => 
            (Bug.printError "not found (findVar):";
             Bug.printError (String.concatWith "." longid);
             Bug.printError "\n";
             NONE)
        end

    fun findExnVar ({Env,...}:N.topEnv) longid =
        case N.findId(Env, mkLongsymbol longid) of
          SOME (I.IDEXEXN (exInfo as {longsymbol,...})) => 
          SOME exInfo
        | SOME (I.IDEXEXNREP (exInfo as {longsymbol,...})) => 
          SOME exInfo
        | _ => 
          (Bug.printError "not found (findExnVar):";
           Bug.printError (String.concatWith "." longid);
           Bug.printError "\n";
           NONE)

    fun findTy ({Env,...}:N.topEnv) longid =
        (case N.findTstr (Env, S.mkLongsymbol longid Loc.noloc) of
           NONE => 
           (Bug.printError "not found (findTy):";
            Bug.printError (String.concatWith "." longid);
            Bug.printError "\n";
            NONE)
         | SOME (N.TSTR tfun) => SOME (E.evalTfun E.emptyContext tfun)
         | SOME (N.TSTR_DTY {tfun, ...}) => SOME (E.evalTfun E.emptyContext tfun))
        handle E.EVALTFUN _ => 
          let
            val path = String.concatWith "." longid
            val _ =Bug.printError ("UserlevelPrimitive.findTy not found:" ^ path ^ "\n")
          in
            raise  (IDNotFound (String.concatWith "." longid))
          end

    (* SQL data *)
    val SQL_exInfo_toyServer = ref NONE : I.exInfo option ref
    val SQL_tyCon_command = ref NONE : T.tyCon option ref
    val SQL_tyCon_db = ref NONE : T.tyCon option ref
    val SQL_tyCon_exp = ref NONE : T.tyCon option ref
    val SQL_tyCon_from = ref NONE : T.tyCon option ref
    val SQL_tyCon_limit = ref NONE : T.tyCon option ref
    val SQL_tyCon_offset = ref NONE : T.tyCon option ref
    val SQL_tyCon_orderby = ref NONE : T.tyCon option ref
    val SQL_tyCon_query = ref NONE : T.tyCon option ref
    val SQL_tyCon_select = ref NONE : T.tyCon option ref
    val SQL_tyCon_whr = ref NONE : T.tyCon option ref
    (* SQL data end *)

    (* REIFY data *)
    val REIFY_conInfo_ARRAYty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_BOOLty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_BOTTOMty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_BOXEDty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_BOUNDVARty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_BUILTIN = ref NONE : T.conInfo option ref
    val REIFY_conInfo_CHARty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_CODEPTRty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_ERRORty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_DYNAMICty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_EXNTAGty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_EXNty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_INT16ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_INT64ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_INT8ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_INTERNALty = ref NONE : T.conInfo option ref 
    val REIFY_conInfo_INTINFty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_INT32ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_LAYOUT_ARG_OR_NULL = ref NONE : T.conInfo option ref
    val REIFY_conInfo_LAYOUT_CHOICE = ref NONE : T.conInfo option ref
    val REIFY_conInfo_LAYOUT_SINGLE = ref NONE : T.conInfo option ref
    val REIFY_conInfo_LAYOUT_SINGLE_ARG = ref NONE : T.conInfo option ref
    val REIFY_conInfo_LAYOUT_TAGGED = ref NONE : T.conInfo option ref
    val REIFY_conInfo_LISTty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_IENVMAPty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_SENVMAPty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_OPTIONty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_PTRty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_RECORDLABELty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_RECORDLABELMAPty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_REAL32ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_REAL64ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_REFty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_STRINGty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_TAGGED_OR_NULL = ref NONE : T.conInfo option ref
    val REIFY_conInfo_TAGGED_RECORD = ref NONE : T.conInfo option ref
    val REIFY_conInfo_TAGGED_TAGONLY = ref NONE : T.conInfo option ref
    val REIFY_conInfo_VOIDty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_TYVARty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_UNITty = ref NONE : T.conInfo option ref 
    val REIFY_conInfo_VECTORty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_WORD16ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_WORD64ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_WORD8ty = ref NONE : T.conInfo option ref
    val REIFY_conInfo_WORD32ty = ref NONE : T.conInfo option ref

    val REIFY_exExnInfo_NaturalJoin = ref NONE : T.exExnInfo option ref  
    val REIFY_exExnInfo_RuntimeTypeError = ref NONE : T.exExnInfo option ref  

    val REIFY_exInfo_RecordLabelFromString = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_SymbolMkLongSymbol = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_TyRep = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_TyRepToReifiedTy = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_MergeConSetEnvWithTyRepList = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_boolToWrapRecord = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_boundenvReifiedTyToPolyTy = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_btvIdBtvIdListToBoundenv = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_coerceTermGeneric = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_checkTermGeneric = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_viewTermGeneric = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_null = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_void = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_dynamicTypeCase = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_longsymbolIdArgsToOpaqueTy = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_makeDummyTy = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_makeFUNMty = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_makePos = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_mkENVenv = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_mkEXEXNIdstatus = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_mkEXEXNREPIdstatus = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_mkEXVarIdstatus = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_mkTopEnv = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_naturalJoin = ref NONE : I.exInfo option ref
    val REIFY_exInfo_extend = ref NONE : I.exInfo option ref
    val REIFY_exInfo_printTopEnv = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_reifiedTermToML = ref NONE : I.exInfo option ref
    val REIFY_exInfo_stringIntListToTagMap = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_stringReifiedTyListToRecordTy = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_stringReifiedTyOptionListToConSet = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_stringToFalseNameRecord = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_tagMapStringToTagMapNullNameRecord = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_tagMapToTagMapRecord = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_toReifiedTerm = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_toReifiedTermPrint = ref NONE : I.exInfo option ref 
    val REIFY_exInfo_typIdConSetListToConSetEnv = ref NONE : I.exInfo option ref 

    val REIFY_tyCon_BoundTypeVarIDMapMap = ref NONE : T.tyCon option ref
    val REIFY_tyCon_RecordLabelMapMap = ref NONE : T.tyCon option ref
    val REIFY_tyCon_RECORDLABELty = ref NONE : T.tyCon option ref
    val REIFY_tyCon_SENVMAPty = ref NONE : T.tyCon option ref
    val REIFY_tyCon_IENVMAPty = ref NONE : T.tyCon option ref
    val REIFY_tyCon_TypIDMapMap = ref NONE : T.tyCon option ref
    val REIFY_tyCon_void = ref NONE : T.tyCon option ref
    val REIFY_tyCon_btvId = ref NONE : T.tyCon option ref
    val REIFY_tyCon_dyn = ref NONE : T.tyCon option ref
    val REIFY_tyCon_env = ref NONE : T.tyCon option ref
    val REIFY_tyCon_idstatus = ref NONE : T.tyCon option ref
    val REIFY_tyCon_label = ref NONE : T.tyCon option ref
    val REIFY_tyCon_reifiedTerm = ref NONE : T.tyCon option ref
    val REIFY_tyCon_reifiedTy = ref NONE : T.tyCon option ref
    val REIFY_tyCon_typId = ref NONE : T.tyCon option ref
 (* REIFY data end *)


  in
    exception IDNotFound = IDNotFound

    fun initExternalDecls () = stack := L.empty
    fun getExternDecls () = map (fn exInfo => I.ICEXTERNVAR exInfo) (L.listItems (!stack))
    fun init env =
    (initExternalDecls ();

     (* SQL_tyCon data *)
     SQL_exInfo_toyServer := findVar env   ["SMLSharp_SQL_Prim", "toyServer"];
     SQL_tyCon_command := findTy env       ["SMLSharp_SQL_Prim","command"];
     SQL_tyCon_db := findTy env            ["SMLSharp_SQL_Prim","db"];
     SQL_tyCon_exp := findTy env           ["SMLSharp_SQL_Prim","exp"];
     SQL_tyCon_from := findTy env          ["SMLSharp_SQL_Prim","from"];
     SQL_tyCon_limit := findTy env         ["SMLSharp_SQL_Prim","limit"];
     SQL_tyCon_offset := findTy env        ["SMLSharp_SQL_Prim","offset"];
     SQL_tyCon_orderby := findTy env       ["SMLSharp_SQL_Prim","orderby"];
     SQL_tyCon_query := findTy env         ["SMLSharp_SQL_Prim","query"];
     SQL_tyCon_select := findTy env        ["SMLSharp_SQL_Prim","select"];
     SQL_tyCon_whr := findTy env           ["SMLSharp_SQL_Prim","whr"];
     (* SQL data end *)

     (* REIFY data *)
     REIFY_conInfo_ARRAYty := findCon env                          ["ReifiedTy", "ARRAYty"];
     REIFY_conInfo_BOOLty := findCon env                           ["ReifiedTy", "BOOLty"];
     REIFY_conInfo_BOTTOMty := findCon env                         ["ReifiedTy", "BOTTOMty"];
     REIFY_conInfo_BOXEDty := findCon env                          ["ReifiedTy", "BOXEDty"];
     REIFY_conInfo_BOUNDVARty := findCon env                       ["ReifiedTy", "BOUNDVARty"];
     REIFY_conInfo_BUILTIN := findCon env                          ["ReifiedTerm", "BUILTIN"];
     REIFY_conInfo_CHARty := findCon env                           ["ReifiedTy", "CHARty"];
     REIFY_conInfo_CODEPTRty := findCon env                        ["ReifiedTy", "CODEPTRty"];
     REIFY_conInfo_DYNAMICty := findCon env                        ["ReifiedTy", "DYNAMICty"];
     REIFY_conInfo_ERRORty := findCon env                          ["ReifiedTy", "ERRORty"];
     REIFY_conInfo_EXNTAGty := findCon env                         ["ReifiedTy", "EXNTAGty"];
     REIFY_conInfo_EXNty := findCon env                            ["ReifiedTy", "EXNty"];
     REIFY_conInfo_INT16ty := findCon env                          ["ReifiedTy", "INT16ty"];
     REIFY_conInfo_INT64ty := findCon env                          ["ReifiedTy", "INT64ty"];
     REIFY_conInfo_INT8ty := findCon env                           ["ReifiedTy", "INT8ty"];
     REIFY_conInfo_INTERNALty := findCon env                       ["ReifiedTy", "INTERNALty"];
     REIFY_conInfo_INTINFty := findCon env                         ["ReifiedTy", "INTINFty"];
     REIFY_conInfo_INT32ty := findCon env                          ["ReifiedTy", "INT32ty"];
     REIFY_conInfo_LAYOUT_ARG_OR_NULL := findCon env               ["ReifiedTy", "LAYOUT_ARG_OR_NULL"];
     REIFY_conInfo_LAYOUT_CHOICE := findCon env                    ["ReifiedTy", "LAYOUT_CHOICE"];
     REIFY_conInfo_LAYOUT_SINGLE := findCon env                    ["ReifiedTy", "LAYOUT_SINGLE"];
     REIFY_conInfo_LAYOUT_SINGLE_ARG := findCon env                ["ReifiedTy", "LAYOUT_SINGLE_ARG"];
     REIFY_conInfo_LAYOUT_TAGGED := findCon env                    ["ReifiedTy", "LAYOUT_TAGGED"];
     REIFY_conInfo_LISTty := findCon env                           ["ReifiedTy", "LISTty"];
     REIFY_conInfo_IENVMAPty := findCon env                        ["ReifiedTy", "IENVMAPty"];
     REIFY_conInfo_SENVMAPty := findCon env                        ["ReifiedTy", "SENVMAPty"];
     REIFY_conInfo_OPTIONty := findCon env                         ["ReifiedTy", "OPTIONty"];
     REIFY_conInfo_PTRty := findCon env                            ["ReifiedTy", "PTRty"];
     REIFY_conInfo_RECORDLABELty := findCon env                    ["ReifiedTy", "RECORDLABELty"];
     REIFY_conInfo_RECORDLABELMAPty := findCon env                 ["ReifiedTy", "RECORDLABELMAPty"];
     REIFY_conInfo_REAL32ty := findCon env                         ["ReifiedTy", "REAL32ty"];
     REIFY_conInfo_REAL64ty := findCon env                         ["ReifiedTy", "REAL64ty"];
     REIFY_conInfo_REFty := findCon env                            ["ReifiedTy", "REFty"];
     REIFY_conInfo_STRINGty := findCon env                         ["ReifiedTy", "STRINGty"];
     REIFY_conInfo_TAGGED_OR_NULL := findCon env                   ["ReifiedTy", "TAGGED_OR_NULL"];
     REIFY_conInfo_TAGGED_RECORD := findCon env                    ["ReifiedTy", "TAGGED_RECORD"];
     REIFY_conInfo_TAGGED_TAGONLY := findCon env                   ["ReifiedTy", "TAGGED_TAGONLY"];
     REIFY_conInfo_VOIDty := findCon env                           ["ReifiedTy", "VOIDty"];
     REIFY_conInfo_TYVARty := findCon env                          ["ReifiedTy", "TYVARty"];
     REIFY_conInfo_UNITty := findCon env                           ["ReifiedTy", "UNITty"];
     REIFY_conInfo_VECTORty := findCon env                         ["ReifiedTy", "VECTORty"];
     REIFY_conInfo_WORD16ty := findCon env                         ["ReifiedTy", "WORD16ty"];
     REIFY_conInfo_WORD64ty := findCon env                         ["ReifiedTy", "WORD64ty"];
     REIFY_conInfo_WORD8ty := findCon env                          ["ReifiedTy", "WORD8ty"];
     REIFY_conInfo_WORD32ty := findCon env                         ["ReifiedTy", "WORD32ty"];

     REIFY_exExnInfo_NaturalJoin := findExExnInfo env              ["NaturalJoin", "NaturalJoin"];
     REIFY_exExnInfo_RuntimeTypeError := findExExnInfo env         ["PartialDynamic", "RuntimeTypeError"];

     REIFY_exInfo_RecordLabelFromString  := findVar env            ["RecordLabel", "fromString"];
     REIFY_exInfo_SymbolMkLongSymbol  := findVar env               ["Symbol", "mkLongsymbol"];
     REIFY_exInfo_TyRep := findVar env                             ["ReifiedTy", "TyRep"];
     REIFY_exInfo_TyRepToReifiedTy := findVar env                  ["ReifiedTy", "TyRepToReifiedTy"];
     REIFY_exInfo_MergeConSetEnvWithTyRepList := findVar env       ["ReifiedTy", "MergeConSetEnvWithTyRepList"];
     REIFY_exInfo_boolToWrapRecord := findVar env                  ["ReifiedTy", "boolToWrapRecord"];
     REIFY_exInfo_boundenvReifiedTyToPolyTy := findVar env         ["ReifiedTy", "boundenvReifiedTyToPolyTy"];
     REIFY_exInfo_btvIdBtvIdListToBoundenv := findVar env          ["ReifiedTy", "btvIdBtvIdListToBoundenv"];
     REIFY_exInfo_coerceTermGeneric := findVar env                 ["PartialDynamic", "coerceTermGeneric"];
     REIFY_exInfo_checkTermGeneric := findVar env                  ["PartialDynamic", "checkTermGeneric"];
     REIFY_exInfo_viewTermGeneric := findVar env                   ["PartialDynamic", "viewTermGeneric"];
     REIFY_exInfo_null := findVar env                              ["PartialDynamic", "null"];
     REIFY_exInfo_void := findVar env                              ["PartialDynamic", "void"];
     REIFY_exInfo_dynamicTypeCase := findVar env                   ["PartialDynamic", "dynamicTypeCase"];
     REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy := findVar env  ["ReifiedTy", "longsymbolIdArgsLayoutListToDatatypeTy"];
     REIFY_exInfo_longsymbolIdArgsToOpaqueTy := findVar env        ["ReifiedTy", "longsymbolIdArgsToOpaqueTy"];
     REIFY_exInfo_makeDummyTy := findVar env                       ["ReifiedTy", "makeDummyTy"];
     REIFY_exInfo_makeFUNMty := findVar env                        ["ReifiedTy", "makeFUNMty"];
     REIFY_exInfo_makePos := findVar env                           ["ReifiedTy", "makePos"];
     REIFY_exInfo_mkENVenv := findVar env                          ["ReifiedTerm", "mkENVenv"];
     REIFY_exInfo_mkEXEXNIdstatus := findVar env                   ["ReifiedTerm", "mkEXEXNIdstatus"];
     REIFY_exInfo_mkEXEXNREPIdstatus := findVar env                ["ReifiedTerm", "mkEXEXNREPIdstatus"];
     REIFY_exInfo_mkEXVarIdstatus := findVar env                   ["ReifiedTerm", "mkEXVarIdstatus"];
     REIFY_exInfo_mkTopEnv := findVar env                          ["ReifiedTerm", "mkTopEnv"];
     REIFY_exInfo_naturalJoin := findVar env                       ["NaturalJoin", "naturalJoin"];
     REIFY_exInfo_extend := findVar env                            ["NaturalJoin", "extend"];
     REIFY_exInfo_printTopEnv := findVar env                       ["ReifiedTerm", "printTopEnv"];
     REIFY_exInfo_reifiedTermToML := findVar env                   ["ReifiedTermToML", "reifiedTermToML"];
     REIFY_exInfo_stringIntListToTagMap := findVar env             ["ReifiedTy", "stringIntListToTagMap"];
     REIFY_exInfo_stringReifiedTyListToRecordTy  := findVar env    ["ReifiedTy", "stringReifiedTyListToRecordTy"];
     REIFY_exInfo_stringReifiedTyOptionListToConSet := findVar env ["ReifiedTy", "stringReifiedTyOptionListToConSet"];
     REIFY_exInfo_stringToFalseNameRecord := findVar env           ["ReifiedTy", "stringToFalseNameRecord"];
     REIFY_exInfo_tagMapStringToTagMapNullNameRecord := findVar env ["ReifiedTy", "tagMapStringToTagMapNullNameRecord"];
     REIFY_exInfo_tagMapToTagMapRecord := findVar env              ["ReifiedTy", "tagMapToTagMapRecord"];
     REIFY_exInfo_toReifiedTerm := findVar env                     ["ReifyTerm", "toReifiedTerm"];
     REIFY_exInfo_toReifiedTermPrint := findVar env                ["ReifyTerm", "toReifiedTermPrint"];
     REIFY_exInfo_typIdConSetListToConSetEnv := findVar env        ["ReifiedTy", "typIdConSetListToConSetEnv"];

     REIFY_tyCon_BoundTypeVarIDMapMap := findTy env                ["BoundTypeVarID", "Map", "map"];
     REIFY_tyCon_RecordLabelMapMap := findTy env                   ["RecordLabel", "Map", "map"];
     REIFY_tyCon_RECORDLABELty := findTy env                       ["RecordLabel", "label"];
     REIFY_tyCon_SENVMAPty := findTy env                           ["SEnv", "map"];
     REIFY_tyCon_IENVMAPty := findTy env                           ["IEnv", "map"];
     REIFY_tyCon_TypIDMapMap := findTy env                         ["TypID", "Map", "map"];
     REIFY_tyCon_void := findTy env                                ["ReifiedTy", "void"];
     REIFY_tyCon_btvId := findTy env                               ["BoundTypeVarID", "id"];
     REIFY_tyCon_dyn := findTy env                                 ["ReifiedTerm", "dyn"];
     REIFY_tyCon_env := findTy env                                 ["ReifiedTerm", "env"];
     REIFY_tyCon_idstatus := findTy env                            ["ReifiedTerm", "idstatus"];
     REIFY_tyCon_label := findTy env                               ["RecordLabel", "label"];
     REIFY_tyCon_reifiedTerm := findTy env                         ["ReifiedTerm", "reifiedTerm"];
     REIFY_tyCon_reifiedTy := findTy env                           ["ReifiedTy", "reifiedTy"];
     REIFY_tyCon_typId := findTy env                               ["TypID", "id"];
 (* REIFY data end *)
  
     getExternDecls ()
    )

    val SQL_icexp_toyServer = fn () => getVar "SQL_exInfo_toyServer" SQL_exInfo_toyServer
    val SQL_tyCon_command = fn () => get "SQL_tyCon_command" SQL_tyCon_command
    val SQL_tyCon_db = fn () => get "SQL_tyCon_db" SQL_tyCon_db
    val SQL_tyCon_exp = fn () => get "SQL_tyCon_exp" SQL_tyCon_exp
    val SQL_tyCon_from = fn () => get "SQL_tyCon_from" SQL_tyCon_from
    val SQL_tyCon_limit = fn () => get "SQL_tyCon_limit" SQL_tyCon_limit
    val SQL_tyCon_offset = fn () => get "SQL_tyCo_noffset" SQL_tyCon_offset
    val SQL_tyCon_orderby = fn () => get "SQL_tyCon_orderby" SQL_tyCon_orderby
    val SQL_tyCon_query = fn () => get "SQL_tyCon_query" SQL_tyCon_query
    val SQL_tyCon_select = fn () => get "SQL_tyCon_select" SQL_tyCon_select
    val SQL_tyCon_whr = fn () => get "SQL_tyCon_whr" SQL_tyCon_whr

    val REIFY_conInfo_ARRAYty = fn () => get "REIFY_conInfo_ARRAYty" REIFY_conInfo_ARRAYty
    val REIFY_conInfo_BOOLty = fn () => get "REIFY_conInfo_BOOLty" REIFY_conInfo_BOOLty
    val REIFY_conInfo_BOTTOMty = fn () => get "REIFY_conInfo_BOTTOMty" REIFY_conInfo_BOTTOMty
    val REIFY_conInfo_BOXEDty = fn () => get "REIFY_conInfo_BOXEDty" REIFY_conInfo_BOXEDty
    val REIFY_conInfo_BOUNDVARty = fn () => get "REIFY_conInfo_BOUNDVARty" REIFY_conInfo_BOUNDVARty
    val REIFY_conInfo_BUILTIN = fn () => get "REIFY_conInfo_BUILTIN" REIFY_conInfo_BUILTIN
    val REIFY_conInfo_CHARty = fn () => get "REIFY_conInfo_CHARty" REIFY_conInfo_CHARty
    val REIFY_conInfo_CODEPTRty = fn () => get "REIFY_conInfo_CODEPTRty" REIFY_conInfo_CODEPTRty
    val REIFY_conInfo_DYNAMICty = fn () => get "REIFY_conInfo_DYNAMICty" REIFY_conInfo_DYNAMICty
    val REIFY_conInfo_ERRORty = fn () => get "REIFY_conInfo_ERRORty" REIFY_conInfo_ERRORty
    val REIFY_conInfo_EXNTAGty = fn () => get "REIFY_conInfo_EXNTAGty" REIFY_conInfo_EXNTAGty
    val REIFY_conInfo_EXNty = fn () => get "REIFY_conInfo_EXNty" REIFY_conInfo_EXNty
    val REIFY_conInfo_INT16ty = fn () => get "REIFY_conInfo_INT16ty" REIFY_conInfo_INT16ty
    val REIFY_conInfo_INT64ty = fn () => get "REIFY_conInfo_INT64ty" REIFY_conInfo_INT64ty
    val REIFY_conInfo_INT8ty = fn () => get "REIFY_conInfo_INT8ty" REIFY_conInfo_INT8ty
    val REIFY_conInfo_INTERNALty = fn () => get "REIFY_conInfo_INTERNALty" REIFY_conInfo_INTERNALty
    val REIFY_conInfo_INTINFty = fn () => get "REIFY_conInfo_INTINFty" REIFY_conInfo_INTINFty
    val REIFY_conInfo_INT32ty = fn () => get "REIFY_conInfo_INT32ty" REIFY_conInfo_INT32ty
    val REIFY_conInfo_LAYOUT_ARG_OR_NULL = fn () => get "REIFY_conInfo_LAYOUT_ARG_OR_NULL" REIFY_conInfo_LAYOUT_ARG_OR_NULL
    val REIFY_conInfo_LAYOUT_CHOICE = fn () => get "REIFY_conInfo_LAYOUT_CHOICE" REIFY_conInfo_LAYOUT_CHOICE
    val REIFY_conInfo_LAYOUT_SINGLE = fn () => get "REIFY_conInfo_LAYOUT_SINGLE" REIFY_conInfo_LAYOUT_SINGLE
    val REIFY_conInfo_LAYOUT_SINGLE_ARG = fn () => get "REIFY_conInfo_LAYOUT_SINGLE_ARG" REIFY_conInfo_LAYOUT_SINGLE_ARG
    val REIFY_conInfo_LAYOUT_TAGGED = fn () => get "REIFY_conInfo_LAYOUT_TAGGED" REIFY_conInfo_LAYOUT_TAGGED
    val REIFY_conInfo_LISTty = fn () => get "REIFY_conInfo_LISTty" REIFY_conInfo_LISTty
    val REIFY_conInfo_IENVMAPty = fn () => get "REIFY_conInfo_IENVMAPty" REIFY_conInfo_IENVMAPty
    val REIFY_conInfo_SENVMAPty = fn () => get "REIFY_conInfo_SENVMAPty" REIFY_conInfo_SENVMAPty
    val REIFY_conInfo_OPTIONty = fn () => get "REIFY_conInfo_OPTIONty" REIFY_conInfo_OPTIONty
    val REIFY_conInfo_PTRty = fn () => get "REIFY_conInfo_PTRty" REIFY_conInfo_PTRty
    val REIFY_conInfo_RECORDLABELty = fn () => get "REIFY_conInfo_RECORDLABELty" REIFY_conInfo_RECORDLABELty
    val REIFY_conInfo_RECORDLABELMAPty = fn () => get "REIFY_conInfo_RECORDLABELMAPty" REIFY_conInfo_RECORDLABELMAPty
    val REIFY_conInfo_REAL32ty = fn () => get "REIFY_conInfo_REAL32ty" REIFY_conInfo_REAL32ty
    val REIFY_conInfo_REAL64ty = fn () => get "REIFY_conInfo_REAL64ty" REIFY_conInfo_REAL64ty
    val REIFY_conInfo_REFty = fn () => get "REIFY_conInfo_REFty" REIFY_conInfo_REFty
    val REIFY_conInfo_STRINGty = fn () => get "REIFY_conInfo_STRINGty" REIFY_conInfo_STRINGty
    val REIFY_conInfo_TAGGED_OR_NULL = fn () => get "REIFY_conInfo_TAGGED_OR_NULL" REIFY_conInfo_TAGGED_OR_NULL
    val REIFY_conInfo_TAGGED_RECORD = fn () => get "REIFY_conInfo_TAGGED_RECORD" REIFY_conInfo_TAGGED_RECORD
    val REIFY_conInfo_TAGGED_TAGONLY = fn () => get "REIFY_conInfo_TAGGED_TAGONLY" REIFY_conInfo_TAGGED_TAGONLY
    val REIFY_conInfo_VOIDty = fn () => get "REIFY_conInfo_VOIDty" REIFY_conInfo_VOIDty
    val REIFY_conInfo_TYVARty = fn () => get "REIFY_conInfo_TYVARty" REIFY_conInfo_TYVARty
    val REIFY_conInfo_UNITty = fn () => get "REIFY_conInfo_UNITty" REIFY_conInfo_UNITty
    val REIFY_conInfo_VECTORty = fn () => get "REIFY_conInfo_VECTORty" REIFY_conInfo_VECTORty
    val REIFY_conInfo_WORD16ty = fn () => get "REIFY_conInfo_WORD16ty" REIFY_conInfo_WORD16ty
    val REIFY_conInfo_WORD64ty = fn () => get "REIFY_conInfo_WORD64ty" REIFY_conInfo_WORD64ty
    val REIFY_conInfo_WORD8ty =  fn () => get "REIFY_conInfo_WORD8ty" REIFY_conInfo_WORD8ty
    val REIFY_conInfo_WORD32ty = fn () => get "REIFY_conInfo_WORD32ty" REIFY_conInfo_WORD32ty

    val REIFY_exExnInfo_NaturalJoin = fn () => getExExnInfo "REIFY_exExnInfo_NaturalJoin" REIFY_exExnInfo_NaturalJoin
    val REIFY_exExnInfo_RuntimeTypeError = fn () => getExExnInfo "REIFY_exExnInfo_RuntimeTypeError" REIFY_exExnInfo_RuntimeTypeError

    val REIFY_exInfo_RecordLabelFromString = fn () => getVarInfo "REIFY_exInfo_RecordLabelFromString" REIFY_exInfo_RecordLabelFromString
    val REIFY_exInfo_SymbolMkLongSymbol = fn () => getVarInfo "REIFY_exInfo_SymbolMkLongSymbol" REIFY_exInfo_SymbolMkLongSymbol
    val REIFY_exInfo_TyRep = fn () => getVarInfo "REIFY_exInfo_TyRep" REIFY_exInfo_TyRep
    val REIFY_exInfo_TyRepToReifiedTy = fn () => getVarInfo "REIFY_exInfo_TyRepToReifiedTy" REIFY_exInfo_TyRepToReifiedTy
    val REIFY_exInfo_MergeConSetEnvWithTyRepList = fn () => getVarInfo "REIFY_exInfo_MergeConSetEnvWithTyRepList" REIFY_exInfo_MergeConSetEnvWithTyRepList
    val REIFY_exInfo_boolToWrapRecord = fn () => getVarInfo "REIFY_exInfo_boolToWrapRecord" REIFY_exInfo_boolToWrapRecord
    val REIFY_exInfo_boundenvReifiedTyToPolyTy = fn () => getVarInfo "REIFY_exInfo_boundenvReifiedTyToPolyTy" REIFY_exInfo_boundenvReifiedTyToPolyTy
    val REIFY_exInfo_btvIdBtvIdListToBoundenv = fn () => getVarInfo "REIFY_exInfo_btvIdBtvIdListToBoundenv" REIFY_exInfo_btvIdBtvIdListToBoundenv
    val REIFY_exInfo_coerceTermGeneric = fn () => getVarInfo "REIFY_exInfo_coerceTermGeneric" REIFY_exInfo_coerceTermGeneric
    val REIFY_exInfo_checkTermGeneric = fn () => getVarInfo "REIFY_exInfo_checkTermGeneric" REIFY_exInfo_checkTermGeneric
    val REIFY_exInfo_viewTermGeneric = fn () => getVarInfo "REIFY_exInfo_viewTermGeneric" REIFY_exInfo_viewTermGeneric
    val REIFY_exInfo_null = fn () => getVarInfo "REIFY_exInfo_null" REIFY_exInfo_null
    val REIFY_exInfo_void = fn () => getVarInfo "REIFY_exInfo_void" REIFY_exInfo_void
    val REIFY_exInfo_dynamicTypeCase = fn () => getVarInfo "REIFY_exInfo_dynamicTypeCase" REIFY_exInfo_dynamicTypeCase
    val REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy = fn () => getVarInfo "REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy" REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy
    val REIFY_exInfo_longsymbolIdArgsToOpaqueTy = fn () => getVarInfo "REIFY_exInfo_longsymbolIdArgsToOpaqueTy" REIFY_exInfo_longsymbolIdArgsToOpaqueTy
    val REIFY_exInfo_makeDummyTy = fn () => getVarInfo "REIFY_exInfo_makeDummyTy" REIFY_exInfo_makeDummyTy
    val REIFY_exInfo_makeFUNMty = fn () => getVarInfo "REIFY_exInfo_makeFUNMty" REIFY_exInfo_makeFUNMty
    val REIFY_exInfo_makePos = fn () => getVarInfo "REIFY_exInfo_makePos" REIFY_exInfo_makePos
    val REIFY_exInfo_mkENVenv = fn () => getVarInfo "REIFY_exInfo_mkENVenv" REIFY_exInfo_mkENVenv
    val REIFY_exInfo_mkEXEXNIdstatus = fn () => getVarInfo "REIFY_exInfo_mkEXEXNIdstatus" REIFY_exInfo_mkEXEXNIdstatus
    val REIFY_exInfo_mkEXEXNREPIdstatus = fn () => getVarInfo "REIFY_exInfo_mkEXEXNREPIdstatus" REIFY_exInfo_mkEXEXNREPIdstatus
    val REIFY_exInfo_mkEXVarIdstatus = fn () => getVarInfo "REIFY_exInfo_mkEXVarIdstatus" REIFY_exInfo_mkEXVarIdstatus
    val REIFY_exInfo_mkTopEnv = fn () => getVarInfo "REIFY_exInfo_mkTopEnv" REIFY_exInfo_mkTopEnv
    val REIFY_exInfo_naturalJoin = fn () => getVarInfo "REIFY_exInfo_naturalJoin" REIFY_exInfo_naturalJoin
    val REIFY_exInfo_extend = fn () => getVarInfo "REIFY_exInfo_extend" REIFY_exInfo_extend
    val REIFY_exInfo_printTopEnv = fn () => getVarInfo "REIFY_exInfo_printTopEnv" REIFY_exInfo_printTopEnv
    val REIFY_exInfo_reifiedTermToML = fn () => getVarInfo "REIFY_exInfo_reifiedTermToML" REIFY_exInfo_reifiedTermToML
    val REIFY_exInfo_stringIntListToTagMap = fn () => getVarInfo "REIFY_exInfo_stringIntListToTagMap" REIFY_exInfo_stringIntListToTagMap
    val REIFY_exInfo_stringReifiedTyListToRecordTy = fn () => getVarInfo "REIFY_exInfo_stringReifiedTyListToRecordTy" REIFY_exInfo_stringReifiedTyListToRecordTy
    val REIFY_exInfo_stringReifiedTyOptionListToConSet = fn () => getVarInfo "REIFY_exInfo_stringReifiedTyOptionListToConSet" REIFY_exInfo_stringReifiedTyOptionListToConSet
    val REIFY_exInfo_stringToFalseNameRecord = fn () => getVarInfo "REIFY_exInfo_stringToFalseNameRecord" REIFY_exInfo_stringToFalseNameRecord
    val REIFY_exInfo_tagMapStringToTagMapNullNameRecord = fn () => getVarInfo "REIFY_exInfo_tagMapStringToTagMapNullNameRecord" REIFY_exInfo_tagMapStringToTagMapNullNameRecord
    val REIFY_exInfo_tagMapToTagMapRecord = fn () => getVarInfo "REIFY_exInfo_tagMapToTagMapRecord" REIFY_exInfo_tagMapToTagMapRecord
    val REIFY_exInfo_toReifiedTerm = fn () => getVarInfo "REIFY_exInfo_toReifiedTerm" REIFY_exInfo_toReifiedTerm
    val REIFY_exInfo_toReifiedTermPrint = fn () => getVarInfo "REIFY_exInfo_toReifiedTermPrint" REIFY_exInfo_toReifiedTermPrint
    val REIFY_exInfo_typIdConSetListToConSetEnv = fn () => getVarInfo "REIFY_exInfo_typIdConSetListToConSetEnv" REIFY_exInfo_typIdConSetListToConSetEnv

    val REIFY_tyCon_BoundTypeVarIDMapMap = fn () => get "REIFY_tyCon_BoundTypeVarIDMapMap" REIFY_tyCon_BoundTypeVarIDMapMap
    val REIFY_tyCon_RecordLabelMapMap = fn () => get "REIFY_tyCon_RecordLabelMapMap"  REIFY_tyCon_RecordLabelMapMap
    val REIFY_tyCon_RECORDLABELty = fn () => get "REIFY_tyCon_RECORDLABELty" REIFY_tyCon_RECORDLABELty
    val REIFY_tyCon_SENVMAPty = fn () => get "REIFY_tyCon_SENVMAPty" REIFY_tyCon_SENVMAPty
    val REIFY_tyCon_IENVMAPty = fn () => get "REIFY_tyCon_IENVMAPty" REIFY_tyCon_IENVMAPty
    val REIFY_tyCon_TypIDMapMap = fn () => get "REIFY_tyCon_TypIDMapMap" REIFY_tyCon_TypIDMapMap
    val REIFY_tyCon_void = fn () => get "REIFY_tyCon_void" REIFY_tyCon_void
    val REIFY_tyCon_btvId = fn () => get "REIFY_tyCon_btvId" REIFY_tyCon_btvId
    val REIFY_tyCon_dyn = fn () => get "REIFY_tyCon_dyn" REIFY_tyCon_dyn
    val REIFY_tyCon_env = fn () => get "REIFY_tyCon_env" REIFY_tyCon_env
    val REIFY_tyCon_idstatus = fn () => get "REIFY_tyCon_idstatus" REIFY_tyCon_idstatus
    val REIFY_tyCon_label = fn () => get "REIFY_tyCon_label" REIFY_tyCon_label
    val REIFY_tyCon_reifiedTerm = fn () => get "REIFY_tyCon_reifiedTerm" REIFY_tyCon_reifiedTerm
    val REIFY_tyCon_reifiedTy = fn () => get "REIFY_tyCon_reifiedTy" REIFY_tyCon_reifiedTy
    val REIFY_tyCon_typId = fn () => get "REIFY_tyCon_typId" REIFY_tyCon_typId

  end
end

