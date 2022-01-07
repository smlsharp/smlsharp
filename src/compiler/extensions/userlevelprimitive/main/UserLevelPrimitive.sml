(**
 * UserLevelPrimitive
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Tomohiro Sasaki
 *)

structure UserLevelPrimitive =
struct

  structure N = NameEvalEnv
  structure I = IDCalc
  structure S = Symbol
  structure T = Types
  structure E = EvalIty
  structure L = LongsymbolEnv
  structure UE = UserLevelPrimitiveError

  val analyzeIdRefOptRef =
      ref NONE
      : (Symbol.longsymbol * (Symbol.symbol * IDCalc.idstatus) -> unit)
          option ref

  val analyzeTstrRefOptRef =
      ref NONE
      : (Symbol.longsymbol * (Symbol.symbol * NameEvalEnv.tstr) -> unit)
          option ref

  val requireEnvOpt =
      ref NONE
      : NameEvalEnv.env option ref

  fun requireEnv () =
      case !requireEnvOpt of
        SOME f => f
      | NONE => raise Bug.Bug "requireEnv in UserLevelPrimitive not set"

  val stack =
      ref LongsymbolEnv.empty
      : IDCalc.exInfo LongsymbolEnv.map ref

  fun insert exInfo =
      stack := LongsymbolEnv.insert (!stack, #longsymbol exInfo, exInfo)

  exception UserLevelPrimError of Loc.loc * exn
  exception IDNotFound

  fun initExternalDecls () =
      stack := L.empty

  fun getExternDecls () =
      let
        val exInfoList = L.listItems (!stack)
      in
        case exInfoList of
          nil => nil
        | _ =>
          let
            val decls =
                map (fn {used, longsymbol, version, ty} =>
                        ({path = longsymbol, ty = E.evalIty E.emptyContext ty},
                         version))
                    exInfoList
            val _ = initExternalDecls ()
          in
            decls
          end
      end

  fun initAnalyze {analyzeIdRef, analyzeTstrRef} =
      (
        analyzeIdRefOptRef := SOME analyzeIdRef;
        analyzeTstrRefOptRef := SOME analyzeTstrRef
      )

  fun analyzeIdRef (longsym, (sym, idstatus)) =
      case !analyzeIdRefOptRef of
        NONE => ()
      | SOME analyzeIdRef =>
        analyzeIdRef (longsym, (sym, idstatus)) handle _ => ()

  fun analyzeTstrRef (longsym, (sym, tstr)) =
      case !analyzeTstrRefOptRef of
        NONE => ()
      | SOME analyzeTstrRef =>
        analyzeTstrRef (longsym, (sym, tstr)) handle _ => ()

  fun init {env = env as {Env,...} : N.topEnv} =
      (
        requireEnvOpt := SOME Env;
        initExternalDecls ()
      )

  fun getTyCon (path : string list) (loc : Loc.loc) : T.tyCon =
      let
        val refLongsymbol = S.mkLongsymbol path loc
      in
        (
          case N.findTstr (requireEnv (), refLongsymbol) of
            NONE =>
            raise
              UserLevelPrimError
              (loc, UE.TyConNotFound ("002", {longsymbol = refLongsymbol}))
          | SOME (sym, tstr as N.TSTR {tfun, defRange}) =>
            (analyzeTstrRef (refLongsymbol, (sym, tstr));
             E.evalTfun E.emptyContext tfun)
          | SOME (sym, tstr as N.TSTR_DTY {tfun,defRange, ...}) =>
            (analyzeTstrRef (refLongsymbol, (sym, tstr));
             E.evalTfun E.emptyContext tfun)
        )
        handle E.EVALTFUN _ =>
               raise
                 UserLevelPrimError
                 (loc, UE.TyConNotFound ("003", {longsymbol = refLongsymbol}))
      end

  fun findIdstatus longsymbol =
      case N.findId (requireEnv (), longsymbol) of
        SOME (sym, idstatus) => (sym, idstatus)
      | _ => raise IDNotFound

  fun getCon (path : string list) (loc : Loc.loc) : T.conInfo =
      let
        val refLongsymbol = S.mkLongsymbol path loc
        val (sym, idstatus) =
            findIdstatus refLongsymbol
	    handle IDNotFound =>
                   raise
		     UserLevelPrimError
                     (loc, UE.IdNotFound ("002", {longsymbol = refLongsymbol}))
      in
        case idstatus of
          I.IDCON {id, longsymbol, ty, defRange} =>
          (analyzeIdRef (refLongsymbol, (sym, idstatus));
           {id = id, path = longsymbol, ty = E.evalIty E.emptyContext ty})
        | _ =>
          (
            Bug.printError "not a con id (findCon):";
            Bug.printError (String.concatWith "." path);
            Bug.printError "\n";
            Bug.printError (Bug.prettyPrint (I.format_idstatus idstatus));
            Bug.printError "\n";
            raise
              UserLevelPrimError
              (loc, UE.IdNotFound ("002", {longsymbol = refLongsymbol}))
          )
      end

  fun getExInfo (path : string list) (loc : Loc.loc) : I.exInfo =
      let
        val refLongsymbol = S.mkLongsymbol path loc
        val (sym, idstatus) =
            findIdstatus refLongsymbol
            handle IDNotFound =>
                   raise
                     UserLevelPrimError
                     (loc, UE.IdNotFound ("002", {longsymbol = refLongsymbol}))
      in
        case idstatus of
          I.IDEXVAR {exInfo = exInfo as {used, ty, longsymbol, ...}, ...} =>
          (if !used then () else (used := true; insert exInfo);
           analyzeIdRef (refLongsymbol, (sym, idstatus));
           exInfo)
        | _ =>
          (
            Bug.printError "not an exvar id (getExInfo):";
            Bug.printError (String.concatWith "." path);
            Bug.printError "\n";
            Bug.printError (Bug.prettyPrint (I.format_idstatus idstatus));
            Bug.printError "\n";
            raise
              UserLevelPrimError
              (loc, UE.IdNotFound ("002", {longsymbol = refLongsymbol}))
          )
      end

  fun getExExnInfo (path : string list) (loc : Loc.loc) : T.exExnInfo =
      let
        val refLongsymbol = S.mkLongsymbol path loc
        val (sym, idstatus) =
            findIdstatus refLongsymbol
            handle IDNotFound =>
                   raise
                     UserLevelPrimError
                     (loc, UE.IdNotFound ("002", {longsymbol = refLongsymbol}))
      in
        case idstatus of
          I.IDEXEXN {used, longsymbol,version, ty, defRange} =>
          (analyzeIdRef (refLongsymbol, (sym, idstatus));
           {path = longsymbol, ty = E.evalIty E.emptyContext ty})
        | I.IDEXEXNREP {used, longsymbol,version, ty, defRange} =>
          (analyzeIdRef (refLongsymbol, (sym, idstatus));
           {path = longsymbol, ty = E.evalIty E.emptyContext ty})
        | _ =>
          (
            Bug.printError "not an expected id (getExExnInfo):";
            Bug.printError (String.concatWith "." path);
            Bug.printError "\n";
            Bug.printError (Bug.prettyPrint (I.format_idstatus idstatus));
            Bug.printError "\n";
            raise
              UserLevelPrimError
              (loc, UE.IdNotFound ("002", {longsymbol = refLongsymbol})))
      end

  fun getIcexp (path : string list) (loc : Loc.loc) : I.icexp =
      let
        val exInfo = getExInfo path loc
      in
        I.ICEXVAR {exInfo = exInfo, longsymbol = #longsymbol exInfo}
      end

  fun getExVar (path : string list) (loc : Loc.loc) : T.exVarInfo =
      let
        val exInfo = getExInfo path loc
      in
        {path = #longsymbol exInfo, ty = E.evalIty E.emptyContext (#ty exInfo)}
      end

  val SQL_tyCon_command =
      getTyCon ["SMLSharp_SQL_Prim", "command"]
  val SQL_tyCon_db =
      getTyCon ["SMLSharp_SQL_Prim", "db"]
  val SQL_tyCon_exp =
      getTyCon ["SMLSharp_SQL_Prim", "exp"]
  val SQL_tyCon_from =
      getTyCon ["SMLSharp_SQL_Prim", "from"]
  val SQL_tyCon_limit =
      getTyCon ["SMLSharp_SQL_Prim", "limit"]
  val SQL_tyCon_offset =
      getTyCon ["SMLSharp_SQL_Prim", "offset"]
  val SQL_tyCon_orderby =
      getTyCon ["SMLSharp_SQL_Prim", "orderby"]
  val SQL_tyCon_query =
      getTyCon ["SMLSharp_SQL_Prim", "query"]
  val SQL_tyCon_select =
      getTyCon ["SMLSharp_SQL_Prim", "select"]
  val SQL_tyCon_whr =
      getTyCon ["SMLSharp_SQL_Prim", "whr"]

  val REIFY_tyCon_BoundTypeVarIDMapMap =
      getTyCon ["BoundTypeVarID", "Map", "map"]
  val REIFY_tyCon_RecordLabelMapMap =
      getTyCon ["RecordLabel", "Map", "map"]
  val REIFY_tyCon_RECORDLABELty =
      getTyCon ["RecordLabel", "label"]
  val REIFY_tyCon_SENVMAPty =
      getTyCon ["SEnv", "map"]
  val REIFY_tyCon_IENVMAPty =
      getTyCon ["IEnv", "map"]
  val REIFY_tyCon_TypIDMapMap =
      getTyCon ["TypID", "Map", "map"]
  val REIFY_tyCon_void =
      getTyCon ["ReifiedTy", "void"]
  val REIFY_tyCon_btvId =
      getTyCon ["BoundTypeVarID", "id"]
  val REIFY_tyCon_dyn =
      getTyCon ["ReifiedTerm", "dyn"]
  val REIFY_tyCon_env =
      getTyCon ["ReifiedTerm", "env"]
  val REIFY_tyCon_idstatus =
      getTyCon ["ReifiedTerm", "idstatus"]
  val REIFY_tyCon_label =
      getTyCon ["RecordLabel", "label"]
  val REIFY_tyCon_reifiedTerm =
      getTyCon ["ReifiedTerm", "reifiedTerm"]
  val REIFY_tyCon_reifiedTy =
      getTyCon ["ReifiedTy", "reifiedTy"]
  val REIFY_tyCon_typId =
      getTyCon ["TypID", "id"]
  val REIFY_tyCon_existInstMap =
      getTyCon ["PartialDynamic", "existInstMap"]

  val REIFY_conInfo_ARRAYty =
      getCon ["ReifiedTy", "ARRAYty"]
  val REIFY_conInfo_BOOLty =
      getCon ["ReifiedTy", "BOOLty"]
  val REIFY_conInfo_BOTTOMty =
      getCon ["ReifiedTy", "BOTTOMty"]
  val REIFY_conInfo_BOXEDty =
      getCon ["ReifiedTy", "BOXEDty"]
  val REIFY_conInfo_BOUNDVARty =
      getCon ["ReifiedTy", "BOUNDVARty"]
  val REIFY_conInfo_BUILTIN =
      getCon ["ReifiedTerm", "BUILTIN"]
  val REIFY_conInfo_CHARty =
      getCon ["ReifiedTy", "CHARty"]
  val REIFY_conInfo_CODEPTRty =
      getCon ["ReifiedTy", "CODEPTRty"]
  val REIFY_conInfo_DYNAMICty =
      getCon ["ReifiedTy", "DYNAMICty"]
  val REIFY_conInfo_ERRORty =
      getCon ["ReifiedTy", "ERRORty"]
  val REIFY_conInfo_EXNTAGty =
      getCon ["ReifiedTy", "EXNTAGty"]
  val REIFY_conInfo_EXNty =
      getCon ["ReifiedTy", "EXNty"]
  val REIFY_conInfo_INT16ty =
      getCon ["ReifiedTy", "INT16ty"]
  val REIFY_conInfo_INT64ty =
      getCon ["ReifiedTy", "INT64ty"]
  val REIFY_conInfo_INT8ty =
      getCon ["ReifiedTy", "INT8ty"]
  val REIFY_conInfo_INTERNALty =
      getCon ["ReifiedTy", "INTERNALty"]
  val REIFY_conInfo_INTINFty =
      getCon ["ReifiedTy", "INTINFty"]
  val REIFY_conInfo_INT32ty =
      getCon ["ReifiedTy", "INT32ty"]
  val REIFY_conInfo_LAYOUT_ARG_OR_NULL =
      getCon ["ReifiedTy", "LAYOUT_ARG_OR_NULL"]
  val REIFY_conInfo_LAYOUT_CHOICE =
      getCon ["ReifiedTy", "LAYOUT_CHOICE"]
  val REIFY_conInfo_LAYOUT_SINGLE =
      getCon ["ReifiedTy", "LAYOUT_SINGLE"]
  val REIFY_conInfo_LAYOUT_SINGLE_ARG =
      getCon ["ReifiedTy", "LAYOUT_SINGLE_ARG"]
  val REIFY_conInfo_LAYOUT_TAGGED =
      getCon ["ReifiedTy", "LAYOUT_TAGGED"]
  val REIFY_conInfo_LISTty =
      getCon ["ReifiedTy", "LISTty"]
  val REIFY_conInfo_IENVMAPty =
      getCon ["ReifiedTy", "IENVMAPty"]
  val REIFY_conInfo_SENVMAPty =
      getCon ["ReifiedTy", "SENVMAPty"]
  val REIFY_conInfo_OPTIONty =
      getCon ["ReifiedTy", "OPTIONty"]
  val REIFY_conInfo_PTRty =
      getCon ["ReifiedTy", "PTRty"]
  val REIFY_conInfo_RECORDLABELty =
      getCon ["ReifiedTy", "RECORDLABELty"]
  val REIFY_conInfo_RECORDLABELMAPty =
      getCon ["ReifiedTy", "RECORDLABELMAPty"]
  val REIFY_conInfo_REAL32ty =
      getCon ["ReifiedTy", "REAL32ty"]
  val REIFY_conInfo_REAL64ty =
      getCon ["ReifiedTy", "REAL64ty"]
  val REIFY_conInfo_REFty =
      getCon ["ReifiedTy", "REFty"]
  val REIFY_conInfo_STRINGty =
      getCon ["ReifiedTy", "STRINGty"]
  val REIFY_conInfo_TAGGED_OR_NULL =
      getCon ["ReifiedTy", "TAGGED_OR_NULL"]
  val REIFY_conInfo_TAGGED_RECORD =
      getCon ["ReifiedTy", "TAGGED_RECORD"]
  val REIFY_conInfo_TAGGED_TAGONLY =
      getCon ["ReifiedTy", "TAGGED_TAGONLY"]
  val REIFY_conInfo_VOIDty =
      getCon ["ReifiedTy", "VOIDty"]
  val REIFY_conInfo_TYVARty =
      getCon ["ReifiedTy", "TYVARty"]
  val REIFY_conInfo_UNITty =
      getCon ["ReifiedTy", "UNITty"]
  val REIFY_conInfo_VECTORty =
      getCon ["ReifiedTy", "VECTORty"]
  val REIFY_conInfo_WORD16ty =
      getCon ["ReifiedTy", "WORD16ty"]
  val REIFY_conInfo_WORD64ty =
      getCon ["ReifiedTy", "WORD64ty"]
  val REIFY_conInfo_WORD8ty =
      getCon ["ReifiedTy", "WORD8ty"]
  val REIFY_conInfo_WORD32ty =
      getCon ["ReifiedTy", "WORD32ty"]

  val REIFY_exExnInfo_NaturalJoin =
      getExExnInfo ["NaturalJoin", "NaturalJoin"]
  val REIFY_exExnInfo_RuntimeTypeError =
      getExExnInfo ["PartialDynamic", "RuntimeTypeError"]

  val SQL_icexp_toyServer =
      getIcexp ["SMLSharp_SQL_Prim", "toyServer"]

  val REIFY_exInfo_RecordLabelFromString =
      getExVar ["RecordLabel", "fromString"]
  val REIFY_exInfo_SymbolMkLongSymbol =
      getExVar ["Symbol", "mkLongsymbol"]
  val REIFY_exInfo_TyRep =
      getExVar ["ReifiedTy", "TyRep"]
  val REIFY_exInfo_TyRepToReifiedTy =
      getExVar ["ReifiedTy", "TyRepToReifiedTy"]
  val REIFY_exInfo_MergeConSetEnvWithTyRepList =
      getExVar ["ReifiedTy", "MergeConSetEnvWithTyRepList"]
  val REIFY_exInfo_boolToWrapRecord =
      getExVar ["ReifiedTy", "boolToWrapRecord"]
  val REIFY_exInfo_boundenvReifiedTyToPolyTy =
      getExVar ["ReifiedTy", "boundenvReifiedTyToPolyTy"]
  val REIFY_exInfo_btvIdBtvIdListToBoundenv =
      getExVar ["ReifiedTy", "btvIdBtvIdListToBoundenv"]
  val REIFY_exInfo_coerceTermGeneric =
      getExVar ["PartialDynamic", "coerceTermGeneric"]
  val REIFY_exInfo_checkTermGeneric =
      getExVar ["PartialDynamic", "checkTermGeneric"]
  val REIFY_exInfo_viewTermGeneric =
      getExVar ["PartialDynamic", "viewTermGeneric"]
  val REIFY_exInfo_null =
      getExVar ["PartialDynamic", "null"]
  val REIFY_exInfo_void =
      getExVar ["PartialDynamic", "void"]
  val REIFY_exInfo_dynamicTypeCase =
      getExVar ["PartialDynamic", "dynamicTypeCase"]
  val REIFY_exInfo_dynamicExistInstance =
      getExVar ["PartialDynamic", "dynamicExistInstance"]
  val REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy =
      getExVar ["ReifiedTy", "longsymbolIdArgsLayoutListToDatatypeTy"]
  val REIFY_exInfo_longsymbolIdArgsToOpaqueTy =
      getExVar ["ReifiedTy", "longsymbolIdArgsToOpaqueTy"]
  val REIFY_exInfo_makeDummyTy =
      getExVar ["ReifiedTy", "makeDummyTy"]
  val REIFY_exInfo_makeExistTy =
      getExVar ["ReifiedTy", "makeExistTy"]
  val REIFY_exInfo_makeFUNMty =
      getExVar ["ReifiedTy", "makeFUNMty"]
  val REIFY_exInfo_makePos =
      getExVar ["ReifiedTy", "makePos"]
  val REIFY_exInfo_mkENVenv =
      getExVar ["ReifiedTerm", "mkENVenv"]
  val REIFY_exInfo_mkEXEXNIdstatus =
      getExVar ["ReifiedTerm", "mkEXEXNIdstatus"]
  val REIFY_exInfo_mkEXEXNREPIdstatus =
      getExVar ["ReifiedTerm", "mkEXEXNREPIdstatus"]
  val REIFY_exInfo_mkEXVarIdstatus =
      getExVar ["ReifiedTerm", "mkEXVarIdstatus"]
  val REIFY_exInfo_mkTopEnv =
      getExVar ["ReifiedTerm", "mkTopEnv"]
  val REIFY_exInfo_naturalJoin =
      getExVar ["NaturalJoin", "naturalJoin"]
  val REIFY_exInfo_extend =
      getExVar ["NaturalJoin", "extend"]
  val REIFY_exInfo_printTopEnv =
      getExVar ["ReifiedTerm", "printTopEnv"]
  val REIFY_exInfo_reifiedTermToML =
      getExVar ["ReifiedTermToML", "reifiedTermToML"]
  val REIFY_exInfo_stringIntListToTagMap =
      getExVar ["ReifiedTy", "stringIntListToTagMap"]
  val REIFY_exInfo_stringReifiedTyListToRecordTy =
      getExVar ["ReifiedTy", "stringReifiedTyListToRecordTy"]
  val REIFY_exInfo_stringReifiedTyOptionListToConSet =
      getExVar ["ReifiedTy", "stringReifiedTyOptionListToConSet"]
  val REIFY_exInfo_stringToFalseNameRecord =
      getExVar ["ReifiedTy", "stringToFalseNameRecord"]
  val REIFY_exInfo_tagMapStringToTagMapNullNameRecord =
      getExVar ["ReifiedTy", "tagMapStringToTagMapNullNameRecord"]
  val REIFY_exInfo_tagMapToTagMapRecord =
      getExVar ["ReifiedTy", "tagMapToTagMapRecord"]
  val REIFY_exInfo_toReifiedTerm =
      getExVar ["ReifyTerm", "toReifiedTerm"]
  val REIFY_exInfo_toReifiedTermPrint =
      getExVar ["ReifyTerm", "toReifiedTermPrint"]
  val REIFY_exInfo_typIdConSetListToConSetEnv =
      getExVar ["ReifiedTy", "typIdConSetListToConSetEnv"]

end
