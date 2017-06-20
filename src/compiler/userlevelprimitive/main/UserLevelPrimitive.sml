(**
 * UserLevelPrimitive
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @author Tomohiro Sasaki
 *)

(*
 * This structure is for compiler codes to use user level codes.
 * This structure is a merge of the former version of JSONData.sml and a part of ConstantTerm.ppg.
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
    val SQL_toyServer_exInfo = ref NONE : I.exInfo option ref
    val SQL_exp_tyCon = ref NONE : T.tyCon option ref
    val SQL_whr_tyCon = ref NONE : T.tyCon option ref
    val SQL_from_tyCon = ref NONE : T.tyCon option ref
    val SQL_orderby_tyCon = ref NONE : T.tyCon option ref
    val SQL_offset_tyCon = ref NONE : T.tyCon option ref
    val SQL_limit_tyCon = ref NONE : T.tyCon option ref
    val SQL_select_tyCon = ref NONE : T.tyCon option ref
    val SQL_query_tyCon = ref NONE : T.tyCon option ref
    val SQL_command_tyCon = ref NONE : T.tyCon option ref
    val SQL_db_tyCon = ref NONE : T.tyCon option ref
    (* SQL data end *)

    (* FOREACH data *)
    val FOREACH_ForeachArray_exInfo = ref NONE : I.exInfo option ref
    val FOREACH_ForeachData_exInfo = ref NONE : I.exInfo option ref
    val FOREACH_index_tyCon = ref NONE : T.tyCon option ref
    (* FOREACH data end *)

    (* REIFY data *)
    val REIFY_RecordLabelMapMap_tyCon = ref NONE : T.tyCon option ref
    val REIFY_SEnvMap_tyCon = ref NONE : T.tyCon option ref
    val REIFY_TypIDMapMap_tyCon = ref NONE : T.tyCon option ref
    val REIFY_btvId_tyCon = ref NONE : T.tyCon option ref
    val REIFY_label_tyCon = ref NONE : T.tyCon option ref
    val REIFY_pos_tyCon = ref NONE : T.tyCon option ref
    val REIFY_reifiedTy_tyCon = ref NONE : T.tyCon option ref
    val REIFY_symbol_tyCon = ref NONE : T.tyCon option ref
    val REIFY_typId_tyCon = ref NONE : T.tyCon option ref
    val REIFY_env_tyCon = ref NONE : T.tyCon option ref
    val REIFY_reifiedTerm_tyCon = ref NONE : T.tyCon option ref
    val REIFY_idstatus_tyCon = ref NONE : T.tyCon option ref

    val REIFY_ARRAYty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_BOOLty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_BOUNDVARty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_BoundTypeVarIDMapMap_tyCon = ref NONE : T.tyCon option ref
    val REIFY_CHARty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_CODEPTRty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_ERRORty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_EXNTAGty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_EXNty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_FUNty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_INTty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_INT8ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_INT16ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_INT64ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_LAYOUT_ARG_OR_NULL_conInfo = ref NONE : T.conInfo option ref
    val REIFY_INTERNALty_conInfo = ref NONE : T.conInfo option ref 
    val REIFY_INTINFty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_LAYOUT_CHOICE_conInfo = ref NONE : T.conInfo option ref
    val REIFY_LAYOUT_SINGLE_ARG_conInfo = ref NONE : T.conInfo option ref
    val REIFY_LAYOUT_SINGLE_conInfo = ref NONE : T.conInfo option ref
    val REIFY_LAYOUT_TAGGED_conInfo = ref NONE : T.conInfo option ref
    val REIFY_LISTty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_OPAQUEty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_OPTIONty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_PTRty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_REAL32ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_REALty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_REFty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_STRINGty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_TAGGED_OR_NULL_conInfo = ref NONE : T.conInfo option ref
    val REIFY_TAGGED_RECORD_conInfo = ref NONE : T.conInfo option ref
    val REIFY_TAGGED_TAGONLY_conInfo = ref NONE : T.conInfo option ref
    val REIFY_TYVARty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_UNITty_conInfo = ref NONE : T.conInfo option ref 
    val REIFY_VECTORty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_WORD8ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_WORD16ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_WORD64ty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_WORDty_conInfo = ref NONE : T.conInfo option ref
    val REIFY_BUILTIN_conInfo = ref NONE : T.conInfo option ref
    val REIFY_UNPRINTABLE_conInfo = ref NONE : T.conInfo option ref

    val REIFY_RecordLabelFromString_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_SymbolMkLongSymbol_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_TyRep_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_boolToWrapRecord_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_boundenvReifiedTyToPolyTy_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_makeDummyTy_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_btvIdBtvIdListToBoundenv_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_longsymbolIdArgsLayoutListToDatatypeTy_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_longsymbolIdArgsToOpaqueTy_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_makePos_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_stringIntListToTagMap_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_stringReifiedTyListToRecordTy_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_stringReifiedTyOptionListToConSet_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_stringToFalseNameRecord_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_tagMapStringToTagMapNullNameRecord_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_tagMapToTagMapRecord_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_typIdConSetListToConSetEnv_exInfo = ref NONE : I.exInfo option ref 

    val REIFY_toReifiedTerm_exInfo = ref NONE : I.exInfo option ref 

    val REIFY_reifiedTermToML_exInfo = ref NONE : I.exInfo option ref

    val REIFY_naturalJoin_exInfo = ref NONE : I.exInfo option ref

    val REIFY_mkEXEXNIdstatus_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_mkEXEXNREPIdstatus_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_mkEXVarIdstatus_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_mkENVenv_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_mkTopEnv_exInfo = ref NONE : I.exInfo option ref 
    val REIFY_printTopEnv_exInfo = ref NONE : I.exInfo option ref 
  
    val REIFY_NaturalJoin_exExnInfo = ref NONE : T.exExnInfo option ref  

 (* REIFY data end *)
 (* JSON data *)
    (* types *)
    val JSON_dyn_tyCon = ref NONE : T.tyCon option ref
    val JSON_json_tyCon = ref NONE : T.tyCon option ref
    val JSON_jsonTy_tyCon = ref NONE : T.tyCon option ref
    val JSON_void_tyCon = ref NONE : T.tyCon option ref
    val JSON_null_tyCon = ref NONE : T.tyCon option ref

    (* exception *)
    val JSON_RuntimeTypeError_exExnInfo = ref NONE : T.exExnInfo option ref
    val JSON_NaturalJoin_exExnInfo = ref NONE : T.exExnInfo option ref
 
    (* constructor *)
(*
    val JSON_DYN_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_ARRAYty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_OPTIONty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_BOOLty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_PARTIALBOOLty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_INTty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_PARTIALINTty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_NULLty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_DYNty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_RECORDty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSONRECORD_WITH_TERMtyIDCconInfo = ref NONE : I.conInfo option ref
    val JSON_PARTIALRECORDty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_REALty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_PARTIALREALty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_STRINGty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_PARTIALSTRINGty_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_ARRAY_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_BOOL_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_INT_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_NULLObject_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_OBJECT_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_REAL_IDCconInfo = ref NONE : I.conInfo option ref
    val JSON_STRING_IDCconInfo = ref NONE : I.conInfo option ref
*)
 
    val JSON_DYN_conInfo = ref NONE : T.conInfo option ref
    val JSON_ARRAYty_conInfo = ref NONE : T.conInfo option ref
    val JSON_OPTIONty_conInfo = ref NONE : T.conInfo option ref
    val JSON_BOOLty_conInfo = ref NONE : T.conInfo option ref
    val JSON_PARTIALBOOLty_conInfo = ref NONE : T.conInfo option ref
    val JSON_INTty_conInfo = ref NONE : T.conInfo option ref
    val JSON_PARTIALINTty_conInfo = ref NONE : T.conInfo option ref
    val JSON_NULLty_conInfo = ref NONE : T.conInfo option ref
    val JSON_DYNty_conInfo = ref NONE : T.conInfo option ref
    val JSON_RECORDty_conInfo = ref NONE : T.conInfo option ref
    val JSONRECORD_WITH_TERMtyconInfo = ref NONE : T.conInfo option ref
    val JSON_PARTIALRECORDty_conInfo = ref NONE : T.conInfo option ref
    val JSON_REALty_conInfo = ref NONE : T.conInfo option ref
    val JSON_PARTIALREALty_conInfo = ref NONE : T.conInfo option ref
    val JSON_STRINGty_conInfo = ref NONE : T.conInfo option ref
    val JSON_PARTIALSTRINGty_conInfo = ref NONE : T.conInfo option ref
    val JSON_ARRAY_conInfo = ref NONE : T.conInfo option ref
    val JSON_BOOL_conInfo = ref NONE : T.conInfo option ref
    val JSON_INT_conInfo = ref NONE : T.conInfo option ref
    val JSON_NULLObject_conInfo = ref NONE : T.conInfo option ref
    val JSON_OBJECT_conInfo = ref NONE : T.conInfo option ref
    val JSON_REAL_conInfo = ref NONE : T.conInfo option ref
    val JSON_STRING_conInfo = ref NONE : T.conInfo option ref

    (* variables *)
    val JSON_getJson_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkTy_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkInt_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkReal_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkBool_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkString_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkArray_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkNull_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkDyn_exInfo = ref NONE : I.exInfo option ref
    val JSON_checkRecord_exInfo = ref NONE : I.exInfo option ref
    val JSON_mapCoerce_exInfo = ref NONE : I.exInfo option ref
    val JSON_optionCoerce_exInfo = ref NONE : I.exInfo option ref
    val JSON_makeCoerce_exInfo = ref NONE : I.exInfo option ref
    val JSON_naturalJoin_exInfo = ref NONE : I.exInfo option ref
    val JSON_toJson_exInfo = ref NONE : I.exInfo option ref
    val JSON_coerceJson_exInfo = ref NONE : I.exInfo option ref
 (* JSON data end *)

 (* PolyDynamic data *)
    (* types *)
    val DYNAMIC_dynamic_tyCon = ref NONE : T.tyCon option ref
    (* PolyDynamic data end *)

  in
    exception IDNotFound = IDNotFound

    fun initExternalDecls () = stack := L.empty
    fun getExternDecls () = map (fn exInfo => I.ICEXTERNVAR exInfo) (L.listItems (!stack))
    fun init env =
    (initExternalDecls ();
     (* SQL data *)
     SQL_toyServer_exInfo := findVar env   ["SMLSharp_SQL_Prim", "toyServer"];
     SQL_exp_tyCon := findTy env           ["SMLSharp_SQL_Prim","exp"];
     SQL_whr_tyCon := findTy env           ["SMLSharp_SQL_Prim","whr"];
     SQL_from_tyCon := findTy env          ["SMLSharp_SQL_Prim","from"];
     SQL_orderby_tyCon := findTy env       ["SMLSharp_SQL_Prim","orderby"];
     SQL_offset_tyCon := findTy env        ["SMLSharp_SQL_Prim","offset"];
     SQL_limit_tyCon := findTy env         ["SMLSharp_SQL_Prim","limit"];
     SQL_select_tyCon := findTy env        ["SMLSharp_SQL_Prim","select"];
     SQL_query_tyCon := findTy env         ["SMLSharp_SQL_Prim","query"];
     SQL_command_tyCon := findTy env       ["SMLSharp_SQL_Prim","command"];
     SQL_db_tyCon := findTy env            ["SMLSharp_SQL_Prim","db"];
     (* SQL data end *)

     (* FOREACH data *)
     FOREACH_ForeachArray_exInfo := findVar env                    ["ForeachArray", "ForeachArray"];
     FOREACH_ForeachData_exInfo := findVar env                     ["ForeachData", "ForeachData"];
     FOREACH_index_tyCon := findTy env                             ["ForeachData", "index"];
     (* FOREACH data end *)

     (* REIFY data *)
     REIFY_BoundTypeVarIDMapMap_tyCon := findTy env                ["BoundTypeVarID", "Map", "map"];
     REIFY_RecordLabelFromString_exInfo  := findVar env            ["RecordLabel", "fromString"];
     REIFY_RecordLabelMapMap_tyCon := findTy env                   ["RecordLabel", "Map", "map"];
     REIFY_SEnvMap_tyCon := findTy env                             ["SEnv", "map"];
     REIFY_TypIDMapMap_tyCon := findTy env                         ["TypID", "Map", "map"];
     REIFY_btvId_tyCon := findTy env                               ["BoundTypeVarID", "id"];
     REIFY_label_tyCon := findTy env                               ["RecordLabel", "label"];
     REIFY_pos_tyCon := findTy env                                 ["Loc", "pos"];
     REIFY_reifiedTy_tyCon := findTy env                           ["ReifiedTy", "reifiedTy"];
     REIFY_symbol_tyCon := findTy env                              ["Symbol", "symbol"];
     REIFY_typId_tyCon := findTy env                               ["TypID", "id"];
     REIFY_idstatus_tyCon := findTy env                            ["ReifiedTerm", "idstatus"];
     REIFY_env_tyCon := findTy env                                 ["ReifiedTerm", "env"];
     REIFY_reifiedTerm_tyCon := findTy env                         ["ReifiedTerm", "reifiedTerm"];

     REIFY_ARRAYty_conInfo := findCon env                          ["ReifiedTy", "ARRAYty"];
     REIFY_BOOLty_conInfo := findCon env                           ["ReifiedTy", "BOOLty"];
     REIFY_BOUNDVARty_conInfo := findCon env                       ["ReifiedTy", "BOUNDVARty"];
     REIFY_CHARty_conInfo := findCon env                           ["ReifiedTy", "CHARty"];
     REIFY_CODEPTRty_conInfo := findCon env                        ["ReifiedTy", "CODEPTRty"];
     REIFY_ERRORty_conInfo := findCon env                          ["ReifiedTy", "ERRORty"];
     REIFY_EXNTAGty_conInfo := findCon env                         ["ReifiedTy", "EXNTAGty"];
     REIFY_EXNty_conInfo := findCon env                            ["ReifiedTy", "EXNty"];
     REIFY_FUNty_conInfo := findCon env                            ["ReifiedTy", "FUNty"];
     REIFY_INT64ty_conInfo := findCon env                          ["ReifiedTy", "INT64ty"];
     REIFY_INTERNALty_conInfo := findCon env                       ["ReifiedTy", "INTERNALty"];
     REIFY_INTINFty_conInfo := findCon env                         ["ReifiedTy", "INTINFty"];
     REIFY_INTty_conInfo := findCon env                            ["ReifiedTy", "INTty"];
     REIFY_INT8ty_conInfo := findCon env                           ["ReifiedTy", "INT8ty"];
     REIFY_INT16ty_conInfo := findCon env                          ["ReifiedTy", "INT16ty"];
     REIFY_LAYOUT_ARG_OR_NULL_conInfo := findCon env               ["ReifiedTy", "LAYOUT_ARG_OR_NULL"];
     REIFY_LAYOUT_CHOICE_conInfo := findCon env                    ["ReifiedTy", "LAYOUT_CHOICE"];
     REIFY_LAYOUT_SINGLE_ARG_conInfo := findCon env                ["ReifiedTy", "LAYOUT_SINGLE_ARG"];
     REIFY_LAYOUT_SINGLE_conInfo := findCon env                    ["ReifiedTy", "LAYOUT_SINGLE"];
     REIFY_LAYOUT_TAGGED_conInfo := findCon env                    ["ReifiedTy", "LAYOUT_TAGGED"];
     REIFY_LISTty_conInfo := findCon env                           ["ReifiedTy", "LISTty"];
     REIFY_OPAQUEty_conInfo := findCon env                         ["ReifiedTy", "OPAQUEty"];
     REIFY_OPTIONty_conInfo := findCon env                         ["ReifiedTy", "OPTIONty"];
     REIFY_PTRty_conInfo := findCon env                            ["ReifiedTy", "PTRty"];
     REIFY_REAL32ty_conInfo := findCon env                         ["ReifiedTy", "REAL32ty"];
     REIFY_REALty_conInfo := findCon env                           ["ReifiedTy", "REALty"];
     REIFY_REFty_conInfo := findCon env                            ["ReifiedTy", "REFty"];
     REIFY_STRINGty_conInfo := findCon env                         ["ReifiedTy", "STRINGty"];
     REIFY_TAGGED_OR_NULL_conInfo := findCon env                   ["ReifiedTy", "TAGGED_OR_NULL"];
     REIFY_TAGGED_RECORD_conInfo := findCon env                    ["ReifiedTy", "TAGGED_RECORD"];
     REIFY_TAGGED_TAGONLY_conInfo := findCon env                   ["ReifiedTy", "TAGGED_TAGONLY"];
     REIFY_TYVARty_conInfo := findCon env                          ["ReifiedTy", "TYVARty"];
     REIFY_UNITty_conInfo := findCon env                           ["ReifiedTy", "UNITty"];
     REIFY_VECTORty_conInfo := findCon env                         ["ReifiedTy", "VECTORty"];
     REIFY_WORD8ty_conInfo := findCon env                          ["ReifiedTy", "WORD8ty"];
     REIFY_WORD16ty_conInfo := findCon env                         ["ReifiedTy", "WORD16ty"];
     REIFY_WORD64ty_conInfo := findCon env                         ["ReifiedTy", "WORD64ty"];
     REIFY_WORDty_conInfo := findCon env                           ["ReifiedTy", "WORDty"];
     REIFY_BUILTIN_conInfo := findCon env                          ["ReifiedTerm", "BUILTIN"];
     REIFY_UNPRINTABLE_conInfo := findCon env                      ["ReifiedTerm", "UNPRINTABLE"];

     REIFY_SymbolMkLongSymbol_exInfo  := findVar env                ["Symbol", "mkLongsymbol"];
     REIFY_TyRep_exInfo := findVar env                              ["ReifiedTy", "TyRep"];
     REIFY_boolToWrapRecord_exInfo := findVar env                   ["ReifiedTy", "boolToWrapRecord"];
     REIFY_boundenvReifiedTyToPolyTy_exInfo := findVar env          ["ReifiedTy", "boundenvReifiedTyToPolyTy"];
     REIFY_makeDummyTy_exInfo := findVar env                        ["ReifiedTy", "makeDummyTy"];
     REIFY_btvIdBtvIdListToBoundenv_exInfo := findVar env           ["ReifiedTy", "btvIdBtvIdListToBoundenv"];
     REIFY_longsymbolIdArgsLayoutListToDatatypeTy_exInfo := findVar env  ["ReifiedTy", "longsymbolIdArgsLayoutListToDatatypeTy"];
     REIFY_longsymbolIdArgsToOpaqueTy_exInfo := findVar env         ["ReifiedTy", "longsymbolIdArgsToOpaqueTy"];
     REIFY_makePos_exInfo := findVar env                            ["ReifiedTy", "makePos"];
     REIFY_stringIntListToTagMap_exInfo := findVar env              ["ReifiedTy", "stringIntListToTagMap"];
     REIFY_stringReifiedTyListToRecordTy_exInfo  := findVar env     ["ReifiedTy", "stringReifiedTyListToRecordTy"];
     REIFY_stringReifiedTyOptionListToConSet_exInfo := findVar env  ["ReifiedTy", "stringReifiedTyOptionListToConSet"];
     REIFY_stringToFalseNameRecord_exInfo := findVar env            ["ReifiedTy", "stringToFalseNameRecord"];
     REIFY_tagMapStringToTagMapNullNameRecord_exInfo := findVar env ["ReifiedTy", "tagMapStringToTagMapNullNameRecord"];
     REIFY_tagMapToTagMapRecord_exInfo := findVar env               ["ReifiedTy", "tagMapToTagMapRecord"];
     REIFY_typIdConSetListToConSetEnv_exInfo := findVar env         ["ReifiedTy", "typIdConSetListToConSetEnv"];

     REIFY_toReifiedTerm_exInfo := findVar env                      ["ReifyTerm", "toReifiedTerm"];

     REIFY_reifiedTermToML_exInfo := findVar env                     ["ReifiedTermToML", "reifiedTermToML"];

     REIFY_naturalJoin_exInfo := findVar env                         ["NaturalJoin", "naturalJoin"];

     REIFY_mkEXEXNIdstatus_exInfo := findVar env                     ["ReifiedTerm", "mkEXEXNIdstatus"];
     REIFY_mkEXEXNREPIdstatus_exInfo := findVar env                  ["ReifiedTerm", "mkEXEXNREPIdstatus"];
     REIFY_mkEXVarIdstatus_exInfo := findVar env                     ["ReifiedTerm", "mkEXVarIdstatus"];
     REIFY_mkENVenv_exInfo := findVar env                            ["ReifiedTerm", "mkENVenv"];
     REIFY_mkTopEnv_exInfo := findVar env                            ["ReifiedTerm", "mkTopEnv"];
     REIFY_printTopEnv_exInfo := findVar env                         ["ReifiedTerm", "printTopEnv"];

     REIFY_NaturalJoin_exExnInfo := findExExnInfo env                ["NaturalJoin", "NaturalJoin"];

 (* REIFY data end *)
  
 (* JSON data *)
     JSON_dyn_tyCon := findTy env                                  ["JSONTypes", "dyn"];
     JSON_json_tyCon := findTy env                                 ["JSONTypes", "json"];
     JSON_jsonTy_tyCon := findTy env                               ["JSONTypes", "jsonTy"];
     JSON_void_tyCon := findTy env                                 ["JSONTypes", "void"];
     JSON_null_tyCon := findTy env                                 ["JSONTypes", "null"];

     JSON_RuntimeTypeError_exExnInfo := findExExnInfo env          ["JSON", "RuntimeTypeError"];
     JSON_NaturalJoin_exExnInfo := findExExnInfo env               ["JSON", "NaturalJoin"];
  
     JSON_DYN_conInfo := findCon env                               ["JSON", "DYN"];
  
     JSON_ARRAYty_conInfo := findCon env                           ["JSON", "ARRAYty"];
     JSON_OPTIONty_conInfo := findCon env                          ["JSON", "OPTIONty"];
     JSON_BOOLty_conInfo := findCon env                            ["JSON", "BOOLty"];
     JSON_PARTIALBOOLty_conInfo := findCon env                     ["JSON", "PARTIALBOOLty"];
     JSON_INTty_conInfo := findCon env                             ["JSON", "INTty"];
     JSON_PARTIALINTty_conInfo := findCon env                      ["JSON", "PARTIALINTty"];
     JSON_NULLty_conInfo := findCon env                            ["JSON", "NULLty"];
     JSON_DYNty_conInfo := findCon env                             ["JSON", "DYNty"];
     JSON_RECORDty_conInfo := findCon env                          ["JSON", "RECORDty"];
     JSONRECORD_WITH_TERMtyconInfo := findCon env                  ["JSON", "RECORDty"];
     JSON_PARTIALRECORDty_conInfo := findCon env                   ["JSON", "PARTIALRECORDty"];
     JSON_REALty_conInfo := findCon env                            ["JSON", "REALty"];
     JSON_PARTIALREALty_conInfo := findCon env                     ["JSON", "PARTIALREALty"];
     JSON_STRINGty_conInfo := findCon env                          ["JSON", "STRINGty"];
     JSON_PARTIALSTRINGty_conInfo := findCon env                   ["JSON", "PARTIALSTRINGty"];
  
     JSON_ARRAY_conInfo := findCon env                             ["JSON", "ARRAY"];
     JSON_BOOL_conInfo := findCon env                              ["JSON", "BOOL"];
     JSON_INT_conInfo := findCon env                               ["JSON", "INT"];
     JSON_NULLObject_conInfo := findCon env                        ["JSON", "NULLObject"];
     JSON_OBJECT_conInfo := findCon env                            ["JSON", "OBJECT"];
     JSON_REAL_conInfo := findCon env                              ["JSON", "REAL"];
     JSON_STRING_conInfo := findCon env                            ["JSON", "STRING"];
  
     JSON_getJson_exInfo := findVar env                            ["JSONImpl", "getJson"];
     JSON_checkTy_exInfo := findVar env                            ["JSONImpl", "checkTy"];
     JSON_checkInt_exInfo := findVar env                           ["JSONImpl", "checkInt"];
     JSON_checkReal_exInfo := findVar env                          ["JSONImpl", "checkReal"];
     JSON_checkBool_exInfo := findVar env                          ["JSONImpl", "checkBool"];
     JSON_checkString_exInfo := findVar env                        ["JSONImpl", "checkString"];
     JSON_checkArray_exInfo := findVar env                         ["JSONImpl", "checkArray"];
     JSON_checkNull_exInfo := findVar env                          ["JSONImpl", "checkNull"];
     JSON_checkDyn_exInfo := findVar env                           ["JSONImpl", "checkDyn"]; 
     JSON_checkRecord_exInfo := findVar env                        ["JSONImpl", "checkRecord"]; 
     JSON_mapCoerce_exInfo := findVar env                          ["JSONImpl", "mapCoerce"]; 
     JSON_optionCoerce_exInfo := findVar env                       ["JSONImpl", "optionCoerce"]; 
     JSON_makeCoerce_exInfo := findVar env                         ["JSONImpl", "makeCoerce"];
     JSON_coerceJson_exInfo := findVar env                         ["JSONImpl", "coerceJson"];
     JSON_naturalJoin_exInfo := findVar env                        ["JSONImpl", "naturalJoin"];
     JSON_toJson_exInfo := findVar env                             ["JSONImpl", "toJson"];
    (* JSON data end *)
     getExternDecls ()
    )

    val SQL_toyServer_icexp = fn () => getVar "SQL_toyServer_exInfo" SQL_toyServer_exInfo
    val SQL_exp_tyCon = fn () => get "SQL_exp_tyCon" SQL_exp_tyCon
    val SQL_whr_tyCon = fn () => get "SQL_whr_tyCon" SQL_whr_tyCon
    val SQL_from_tyCon = fn () => get "SQL_from_tyCon" SQL_from_tyCon
    val SQL_orderby_tyCon = fn () => get "SQL_orderby_tyCon" SQL_orderby_tyCon
    val SQL_offset_tyCon = fn () => get "SQL_offset_tyCon" SQL_offset_tyCon
    val SQL_limit_tyCon = fn () => get "SQL_limit_tyCon" SQL_limit_tyCon
    val SQL_select_tyCon = fn () => get "SQL_select_tyCon" SQL_select_tyCon
    val SQL_query_tyCon = fn () => get "SQL_query_tyCon" SQL_query_tyCon
    val SQL_command_tyCon = fn () => get "SQL_command_tyCon" SQL_command_tyCon
    val SQL_db_tyCon = fn () => get "SQL_db_tyCon" SQL_db_tyCon


    val FOREACH_ForeachArray_exInfo = fn () => getVarInfo "FOREACH_ForeachArray_exInfo" FOREACH_ForeachArray_exInfo
    val FOREACH_ForeachData_exInfo = fn () => getVarInfo "FOREACH_ForeachData_exInfo" FOREACH_ForeachData_exInfo
    val FOREACH_index_tyCon = fn () => get "FOREACH_index_tyCon" FOREACH_index_tyCon

    val REIFY_BoundTypeVarIDMapMap_tyCon = fn () => get "REIFY_BoundTypeVarIDMapMap_tyCon" REIFY_BoundTypeVarIDMapMap_tyCon
    val REIFY_RecordLabelMapMap_tyCon = fn () => get "REIFY_RecordLabelMapMap_tyCon"  REIFY_RecordLabelMapMap_tyCon
    val REIFY_SEnvMap_tyCon = fn () => get "REIFY_SEnvMap_tyCon" REIFY_SEnvMap_tyCon
    val REIFY_TypIDMapMap_tyCon = fn () => get "REIFY_TypIDMapMap_tyCon" REIFY_TypIDMapMap_tyCon
    val REIFY_btvId_tyCon = fn () => get "REIFY_btvId_tyCon" REIFY_btvId_tyCon
    val REIFY_label_tyCon = fn () => get "REIFY_label_tyCon" REIFY_label_tyCon
    val REIFY_pos_tyCon = fn () => get "REIFY_pos_tyCon" REIFY_pos_tyCon
    val REIFY_reifiedTy_tyCon = fn () => get "REIFY_reifiedTy_tyCon" REIFY_reifiedTy_tyCon
    val REIFY_symbol_tyCon = fn () => get "REIFY_symbol_tyCon" REIFY_symbol_tyCon
    val REIFY_typId_tyCon = fn () => get "REIFY_typId_tyCon" REIFY_typId_tyCon
    val REIFY_idstatus_tyCon = fn () => get "REIFY_idstatus_tyCon" REIFY_idstatus_tyCon
    val REIFY_env_tyCon = fn () => get "REIFY_env_tyCon" REIFY_env_tyCon
    val REIFY_reifiedTerm_tyCon = fn () => get "REIFY_reifiedTerm_tyCon" REIFY_reifiedTerm_tyCon

    val REIFY_ARRAYty_conInfo = fn () => get "REIFY_ARRAYty_conInfo" REIFY_ARRAYty_conInfo
    val REIFY_BOOLty_conInfo = fn () => get "REIFY_BOOLty_conInfo" REIFY_BOOLty_conInfo
    val REIFY_BOUNDVARty_conInfo = fn () => get "REIFY_BOUNDVARty_conInfo" REIFY_BOUNDVARty_conInfo
    val REIFY_CHARty_conInfo = fn () => get "REIFY_CHARty_conInfo" REIFY_CHARty_conInfo
    val REIFY_CODEPTRty_conInfo = fn () => get "REIFY_CODEPTRty_conInfo" REIFY_CODEPTRty_conInfo
    val REIFY_ERRORty_conInfo = fn () => get "REIFY_ERRORty_conInfo" REIFY_ERRORty_conInfo
    val REIFY_EXNTAGty_conInfo = fn () => get "REIFY_EXNTAGty_conInfo" REIFY_EXNTAGty_conInfo
    val REIFY_EXNty_conInfo = fn () => get "REIFY_EXNty_conInfo" REIFY_EXNty_conInfo
    val REIFY_FUNty_conInfo = fn () => get "REIFY_FUNty_conInfo" REIFY_FUNty_conInfo
    val REIFY_INT64ty_conInfo = fn () => get "REIFY_INT64ty_conInfo" REIFY_INT64ty_conInfo
    val REIFY_INTERNALty_conInfo = fn () => get "REIFY_INTERNALty_conInfo" REIFY_INTERNALty_conInfo
    val REIFY_INTINFty_conInfo = fn () => get "REIFY_INTINFty_conInfo" REIFY_INTINFty_conInfo
    val REIFY_INTty_conInfo = fn () => get "REIFY_INTty_conInfo" REIFY_INTty_conInfo
    val REIFY_INT8ty_conInfo = fn () => get "REIFY_INT8ty_conInfo" REIFY_INT8ty_conInfo
    val REIFY_INT16ty_conInfo = fn () => get "REIFY_INT16ty_conInfo" REIFY_INT16ty_conInfo
    val REIFY_LAYOUT_ARG_OR_NULL_conInfo = fn () => get "REIFY_LAYOUT_ARG_OR_NULL_conInfo" REIFY_LAYOUT_ARG_OR_NULL_conInfo
    val REIFY_LAYOUT_CHOICE_conInfo = fn () => get "REIFY_LAYOUT_CHOICE_conInfo" REIFY_LAYOUT_CHOICE_conInfo
    val REIFY_LAYOUT_SINGLE_ARG_conInfo = fn () => get "REIFY_LAYOUT_SINGLE_ARG_conInfo" REIFY_LAYOUT_SINGLE_ARG_conInfo
    val REIFY_LAYOUT_SINGLE_conInfo = fn () => get "REIFY_LAYOUT_SINGLE_conInfo" REIFY_LAYOUT_SINGLE_conInfo
    val REIFY_LAYOUT_TAGGED_conInfo = fn () => get "REIFY_LAYOUT_TAGGED_conInfo" REIFY_LAYOUT_TAGGED_conInfo
    val REIFY_LISTty_conInfo = fn () => get "REIFY_LISTty_conInfo" REIFY_LISTty_conInfo
    val REIFY_OPAQUEty_conInfo = fn () => get "REIFY_OPAQUEty_conInfo" REIFY_OPAQUEty_conInfo
    val REIFY_OPTIONty_conInfo = fn () => get "REIFY_OPTIONty_conInfo" REIFY_OPTIONty_conInfo
    val REIFY_PTRty_conInfo = fn () => get "REIFY_PTRty_conInfo" REIFY_PTRty_conInfo
    val REIFY_REAL32ty_conInfo = fn () => get "REIFY_REAL32ty_conInfo" REIFY_REAL32ty_conInfo
    val REIFY_REALty_conInfo = fn () => get "REIFY_REALty_conInfo" REIFY_REALty_conInfo
    val REIFY_REFty_conInfo = fn () => get "REIFY_REFty_conInfo" REIFY_REFty_conInfo
    val REIFY_STRINGty_conInfo = fn () => get "REIFY_STRINGty_conInfo" REIFY_STRINGty_conInfo
    val REIFY_TAGGED_OR_NULL_conInfo = fn () => get "REIFY_TAGGED_OR_NULL_conInfo" REIFY_TAGGED_OR_NULL_conInfo
    val REIFY_TAGGED_RECORD_conInfo = fn () => get "REIFY_TAGGED_RECORD_conInfo" REIFY_TAGGED_RECORD_conInfo
    val REIFY_TAGGED_TAGONLY_conInfo = fn () => get "REIFY_TAGGED_TAGONLY_conInfo" REIFY_TAGGED_TAGONLY_conInfo
    val REIFY_TYVARty_conInfo = fn () => get "REIFY_TYVARty_conInfo" REIFY_TYVARty_conInfo
    val REIFY_UNITty_conInfo = fn () => get "REIFY_UNITty_conInfo" REIFY_UNITty_conInfo
    val REIFY_VECTORty_conInfo = fn () => get "REIFY_VECTORty_conInfo" REIFY_VECTORty_conInfo
    val REIFY_WORD8ty_conInfo =  fn () => get "REIFY_WORD8ty_conInfo" REIFY_WORD8ty_conInfo
    val REIFY_WORD16ty_conInfo = fn () => get "REIFY_WORD16ty_conInfo" REIFY_WORD16ty_conInfo
    val REIFY_WORD64ty_conInfo = fn () => get "REIFY_WORD64ty_conInfo" REIFY_WORD64ty_conInfo
    val REIFY_WORDty_conInfo = fn () => get "REIFY_WORDty_conInfo" REIFY_WORDty_conInfo
    val REIFY_BUILTIN_conInfo = fn () => get "REIFY_BUILTIN_conInfo" REIFY_BUILTIN_conInfo
    val REIFY_UNPRINTABLE_conInfo = fn () => get "REIFY_UNPRINTABLE_conInfo" REIFY_UNPRINTABLE_conInfo

    val REIFY_RecordLabelFromString_exInfo = fn () => getVarInfo "REIFY_RecordLabelFromString_exInfo" REIFY_RecordLabelFromString_exInfo
    val REIFY_SymbolMkLongSymbol_exInfo = fn () => getVarInfo "REIFY_SymbolMkLongSymbol_exInfo" REIFY_SymbolMkLongSymbol_exInfo
    val REIFY_TyRep_exInfo = fn () => getVarInfo "REIFY_TyRep_exInfo" REIFY_TyRep_exInfo
    val REIFY_boolToWrapRecord_exInfo = fn () => getVarInfo "REIFY_boolToWrapRecord_exInfo" REIFY_boolToWrapRecord_exInfo
    val REIFY_boundenvReifiedTyToPolyTy_exInfo = fn () => getVarInfo "REIFY_boundenvReifiedTyToPolyTy_exInfo" REIFY_boundenvReifiedTyToPolyTy_exInfo
    val REIFY_makeDummyTy_exInfo = fn () => getVarInfo "REIFY_makeDummyTy_exInfo" REIFY_makeDummyTy_exInfo
    val REIFY_btvIdBtvIdListToBoundenv_exInfo = fn () => getVarInfo "REIFY_btvIdBtvIdListToBoundenv_exInfo" REIFY_btvIdBtvIdListToBoundenv_exInfo
    val REIFY_longsymbolIdArgsLayoutListToDatatypeTy_exInfo = fn () => getVarInfo "REIFY_longsymbolIdArgsLayoutListToDatatypeTy_exInfo" REIFY_longsymbolIdArgsLayoutListToDatatypeTy_exInfo
    val REIFY_longsymbolIdArgsToOpaqueTy_exInfo = fn () => getVarInfo "REIFY_longsymbolIdArgsToOpaqueTy_exInfo" REIFY_longsymbolIdArgsToOpaqueTy_exInfo
    val REIFY_makePos_exInfo = fn () => getVarInfo "REIFY_makePos_exInfo" REIFY_makePos_exInfo
    val REIFY_stringIntListToTagMap_exInfo = fn () => getVarInfo "REIFY_stringIntListToTagMap_exInfo" REIFY_stringIntListToTagMap_exInfo
    val REIFY_stringReifiedTyListToRecordTy_exInfo = fn () => getVarInfo "REIFY_stringReifiedTyListToRecordTy_exInfo" REIFY_stringReifiedTyListToRecordTy_exInfo
    val REIFY_stringReifiedTyOptionListToConSet_exInfo = fn () => getVarInfo "REIFY_stringReifiedTyOptionListToConSet_exInfo" REIFY_stringReifiedTyOptionListToConSet_exInfo
    val REIFY_stringToFalseNameRecord_exInfo = fn () => getVarInfo "REIFY_stringToFalseNameRecord_exInfo" REIFY_stringToFalseNameRecord_exInfo
    val REIFY_tagMapStringToTagMapNullNameRecord_exInfo = fn () => getVarInfo "REIFY_tagMapStringToTagMapNullNameRecord_exInfo" REIFY_tagMapStringToTagMapNullNameRecord_exInfo
    val REIFY_tagMapToTagMapRecord_exInfo = fn () => getVarInfo "REIFY_tagMapToTagMapRecord_exInfo" REIFY_tagMapToTagMapRecord_exInfo
    val REIFY_typIdConSetListToConSetEnv_exInfo = fn () => getVarInfo "REIFY_typIdConSetListToConSetEnv_exInfo" REIFY_typIdConSetListToConSetEnv_exInfo

    val REIFY_toReifiedTerm_exInfo = fn () => getVarInfo "REIFY_toReifiedTerm_exInfo" REIFY_toReifiedTerm_exInfo

    val REIFY_reifiedTermToML_exInfo = fn () => getVarInfo "REIFY_reifiedTermToML_exInfo" REIFY_reifiedTermToML_exInfo

    val REIFY_naturalJoin_exInfo = fn () => getVarInfo "REIFY_naturalJoin_exInfo" REIFY_naturalJoin_exInfo

    val REIFY_mkEXEXNIdstatus_exInfo = fn () => getVarInfo "REIFY_mkEXEXNIdstatus_exInfo" REIFY_mkEXEXNIdstatus_exInfo
    val REIFY_mkEXEXNREPIdstatus_exInfo = fn () => getVarInfo "REIFY_mkEXEXNREPIdstatus_exInfo" REIFY_mkEXEXNREPIdstatus_exInfo
    val REIFY_mkEXVarIdstatus_exInfo = fn () => getVarInfo "REIFY_mkEXVarIdstatus_exInfo" REIFY_mkEXVarIdstatus_exInfo
    val REIFY_mkENVenv_exInfo = fn () => getVarInfo "REIFY_mkENVenv_exInfo" REIFY_mkENVenv_exInfo
    val REIFY_mkTopEnv_exInfo = fn () => getVarInfo "REIFY_mkTopEnv_exInfo" REIFY_mkTopEnv_exInfo
    val REIFY_printTopEnv_exInfo = fn () => getVarInfo "REIFY_printTopEnv_exInfo" REIFY_printTopEnv_exInfo

    val REIFY_NaturalJoin_exExnInfo = fn () => getExExnInfo "REIFY_NaturalJoin_exExnInfo" REIFY_NaturalJoin_exExnInfo

 (* JSON data *)
    (* types *)
    val JSON_dyn_tyCon = fn () => get "JSON_dyn_tyCon" JSON_dyn_tyCon
    val JSON_json_tyCon = fn () => get "JSON_json_tyCon" JSON_json_tyCon
    val JSON_jsonTy_tyCon = fn () => get "JSON_jsonTy_tyCon" JSON_jsonTy_tyCon
    val JSON_void_tyCon = fn () => get "JSON_void_tyCon" JSON_void_tyCon
    val JSON_null_tyCon = fn () => get "JSON_null_tyCon" JSON_null_tyCon

    (* exception *)
    val JSON_RuntimeTypeError_exExnInfo = 
     fn () => getExExnInfo "JSON_RuntimeTypeError_exExnInfo" JSON_RuntimeTypeError_exExnInfo
    val JSON_NaturalJoin_exExnInfo = 
     fn () => getExExnInfo "JSON_NaturalJoin_exExnInfo" JSON_NaturalJoin_exExnInfo

    (* constructor expression *)
    val JSON_DYN_conInfo = fn () => get "JSON_DYN_conInfo" JSON_DYN_conInfo
    val JSON_ARRAYty_conInfo = fn () => get "JSON_ARRAYty_conInfo" JSON_ARRAYty_conInfo
    val JSON_OPTIONty_conInfo = fn () => get "JSON_OPTIONty_conInfo" JSON_OPTIONty_conInfo
    val JSON_BOOLty_conInfo = fn () => get "JSON_BOOLty_conInfo" JSON_BOOLty_conInfo
    val JSON_PARTIALBOOLty_conInfo = fn () => get "JSON_PARTIALBOOLty_conInfo" JSON_PARTIALBOOLty_conInfo
    val JSON_INTty_conInfo = fn () => get "JSON_INTty_conInfo" JSON_INTty_conInfo
    val JSON_PARTIALINTty_conInfo = fn () => get "JSON_PARTIALINTty_conInfo" JSON_PARTIALINTty_conInfo
    val JSON_NULLty_conInfo = fn () => get "JSON_NULLty_conInfo" JSON_NULLty_conInfo
    val JSON_DYNty_conInfo = fn () => get "JSON_DYNty_conInfo" JSON_DYNty_conInfo
    val JSON_RECORDty_conInfo = fn () => get "JSON_RECORDty_conInfo" JSON_RECORDty_conInfo
    val JSONRECORD_WITH_TERMtyconInfo = fn () => get "JSONRECORD_WITH_TERMtyconInfo" JSONRECORD_WITH_TERMtyconInfo
    val JSON_PARTIALRECORDty_conInfo = fn () => get "JSON_PARTIALRECORDty_conInfo" JSON_PARTIALRECORDty_conInfo
    val JSON_REALty_conInfo = fn () => get "JSON_REALty_conInfo" JSON_REALty_conInfo
    val JSON_PARTIALREALty_conInfo = fn () => get "JSON_PARTIALREALty_conInfo" JSON_PARTIALREALty_conInfo
    val JSON_STRINGty_conInfo = fn () => get "JSON_STRINGty_conInfo" JSON_STRINGty_conInfo
    val JSON_PARTIALSTRINGty_conInfo = fn () => get "JSON_PARTIALSTRINGty_conInfo" JSON_PARTIALSTRINGty_conInfo
    val JSON_ARRAY_conInfo = fn () => get "JSON_ARRAY_conInfo" JSON_ARRAY_conInfo
    val JSON_BOOL_conInfo = fn () => get "JSON_BOOL_conInfo" JSON_BOOL_conInfo
    val JSON_INT_conInfo = fn () => get "JSON_INT_conInfo" JSON_INT_conInfo
    val JSON_NULLObject_conInfo = fn () => get "JSON_NULLObject_conInfo" JSON_NULLObject_conInfo
    val JSON_OBJECT_conInfo = fn () => get "JSON_OBJECT_conInfo" JSON_OBJECT_conInfo
    val JSON_REAL_conInfo = fn () => get "JSON_REAL_conInfo" JSON_REAL_conInfo
    val JSON_STRING_conInfo = fn () => get "JSON_STRING_conInfo" JSON_STRING_conInfo

    (* variable informations *)
    val JSON_getJson_exVarInfo = fn () => getVarInfo "JSON_getJson_exInfo" JSON_getJson_exInfo
    val JSON_checkTy_exVarInfo = fn () => getVarInfo "JSON_checkTy_exInfo" JSON_checkTy_exInfo
    val JSON_checkInt_exVarInfo = fn () => getVarInfo "JSON_checkInt_exInfo" JSON_checkInt_exInfo
    val JSON_checkReal_exVarInfo = fn () => getVarInfo "JSON_checkReal_exInfo" JSON_checkReal_exInfo
    val JSON_checkBool_exVarInfo = fn () => getVarInfo "JSON_checkBool_exInfo" JSON_checkBool_exInfo
    val JSON_checkString_exVarInfo = fn () => getVarInfo "JSON_checkString_exInfo" JSON_checkString_exInfo
    val JSON_checkArray_exVarInfo = fn () => getVarInfo "JSON_checkArray_exInfo" JSON_checkArray_exInfo
    val JSON_checkNull_exVarInfo = fn () => getVarInfo "JSON_checkNull_exInfo" JSON_checkNull_exInfo
    val JSON_checkDyn_exVarInfo = fn () => getVarInfo "JSON_checkDyn_exInfo" JSON_checkDyn_exInfo
    val JSON_checkRecord_exVarInfo = fn () => getVarInfo "JSON_checkRecord_exInfo" JSON_checkRecord_exInfo
    val JSON_mapCoerce_exVarInfo = fn () => getVarInfo "JSON_mapCoerce_exInfo" JSON_mapCoerce_exInfo
    val JSON_optionCoerce_exVarInfo = fn () => getVarInfo "JSON_optionCoerce_exInfo" JSON_optionCoerce_exInfo
    val JSON_makeCoerce_exVarInfo = fn () => getVarInfo "JSON_makeCoerce_exInfo" JSON_makeCoerce_exInfo
    val JSON_coerceJson_exVarInfo = fn () => getVarInfo "JSON_coerceJson_exInfo" JSON_coerceJson_exInfo
    val JSON_naturalJoin_exVarInfo = fn () => getVarInfo "JSON_naturalJoin_exInfo" JSON_naturalJoin_exInfo
    val JSON_toJson_exVarInfo = fn () => getVarInfo "JSON_toJson_exInfo" JSON_toJson_exInfo
 (* JSON data end *)

 (* PolyDynamic data *)
    (* types *)
    val DYNAMIC_dynamic_tyCon = fn () => get "DYNAMIC_dynamic_tyCon" DYNAMIC_dynamic_tyCon
 (* PolyDynamic data end *)
  end
end
