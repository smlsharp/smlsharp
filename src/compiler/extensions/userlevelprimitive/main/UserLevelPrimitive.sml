(**
 * UserLevelPrimitive
 * @copyright (c) 2016 - 2020 Tohoku University.
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
    structure UE = UserLevelPrimitiveError

    fun longsymbolLocString longsymbol =
        Loc.locToString (S.longsymbolToLoc longsymbol)
    fun symbolLocString longsymbol =
        Loc.locToString (S.symbolToLoc longsymbol)

    fun tfunLocString tfun =
        longsymbolLocString (I.tfunLongsymbol tfun)

    val analyzeIdRefOptRef = ref NONE
        : (Symbol.longsymbol * (Symbol.symbol * IDCalc.idstatus) -> unit) 
            option ref
    val analyzeTstrRefOptRef = ref NONE
        : (Symbol.longsymbol * (Symbol.symbol * NameEvalEnv.tstr) -> unit)
            option ref

    val requireEnvOpt = ref NONE : NameEvalEnv.env option ref
 
    val requireEnv = 
     fn () => case !requireEnvOpt of 
                   SOME f => f 
                 | NONE => raise Bug.Bug "requireEnv in UserLevelPrimitive not set"

    val stack = ref LongsymbolEnv.empty 
                : IDCalc.exInfo LongsymbolEnv.map ref

    fun insert exInfo = 
        stack := LongsymbolEnv.insert (!stack, #longsymbol exInfo, exInfo)

    fun printInfo s = Bug.printError (s ^ "\n")

    fun mkLongsymbol longid = S.mkLongsymbol longid Loc.noloc
    fun mkLongsymbolWithLoc loc longid = S.mkLongsymbol longid loc

    exception UserLevelPrimError of Loc.loc * exn
    exception IDNotFound
  in
    exception UserLevelPrimError = UserLevelPrimError

    fun initExternalDecls () = stack := L.empty
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
     analyzeTstrRefOptRef := SOME analyzeTstrRef;
     ()
    )
   
    fun analyzeIdRef (longsym, (sym, idstatus)) =
        case !analyzeIdRefOptRef of
          NONE => ()
        | SOME analyzeIdRef => 
          analyzeIdRef (longsym, (sym, idstatus))
          handle _ => ()
    fun analyzeTstrRef (longsym, (sym, tstr)) =
        case !analyzeTstrRefOptRef of
          NONE => ()
        | SOME analyzeTstrRef => 
          analyzeTstrRef (longsym, (sym, tstr))
          handle _ => ()

    fun init {env = env as {Env,...} : N.topEnv} =
    (requireEnvOpt := SOME Env;
     initExternalDecls ();
     ()
    )

    fun getTyCon (path:string list) =
     fn (loc:Loc.loc) => 
        let
            val refLongsymbol = mkLongsymbolWithLoc loc path
        in
          (case N.findTstr (requireEnv(), refLongsymbol) of
             NONE =>  
             raise
               UserLevelPrimError
                 (loc, UE.TyConNotFound("002", {longsymbol = refLongsymbol}))
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
                     (loc, UE.TyConNotFound("003", {longsymbol = refLongsymbol}))
        end : Types.tyCon

    fun findIdstatus longsymbol =
        case N.findId (requireEnv(), longsymbol) of
          SOME (sym, idstatus) => (sym, idstatus)
        | _ => raise IDNotFound
        
    fun getCon (path:string list) =
     fn (loc:Loc.loc) => 
        let
            val refLongsymbol = mkLongsymbolWithLoc loc path
            val (sym, idstatus) = findIdstatus refLongsymbol
		handle IDNotFound =>
                       raise        
			   UserLevelPrimError
                               (loc, UE.IdNotFound("002", {longsymbol = refLongsymbol}))
        in
          case idstatus of
            I.IDCON {id, longsymbol, ty, defRange} =>
            (analyzeIdRef (refLongsymbol, (sym, idstatus));
            {id = id, path = longsymbol,
             ty = E.evalIty E.emptyContext ty}
            )
          | _ => 
            (
             Bug.printError "not a con id (findCon):";
             Bug.printError (String.concatWith "." path);
             Bug.printError "\n";
             Bug.printError (Bug.prettyPrint (I.format_idstatus idstatus));
             Bug.printError "\n";
             raise
               UserLevelPrimError
                 (loc, UE.IdNotFound("002", {longsymbol = refLongsymbol}))
            )
        end : Types.conInfo

    fun getExInfo (path:string list) =
        fn (loc:Loc.loc) =>
        let
          val refLongsymbol = mkLongsymbolWithLoc loc path
          val (sym, idstatus) = findIdstatus refLongsymbol
              handle IDNotFound =>
                     raise        
                       UserLevelPrimError
                         (loc, UE.IdNotFound("002", {longsymbol = refLongsymbol}))
        in
          case idstatus of
             I.IDEXVAR {exInfo= exInfo as {used,ty,longsymbol,...},...} => 
             (if !used then () else (used := true; insert exInfo);
              analyzeIdRef (refLongsymbol, (sym, idstatus));
              exInfo)
           | _ => 
             (Bug.printError "not an exvar id (getExInfo):";
              Bug.printError (String.concatWith "." path);
              Bug.printError "\n";
              Bug.printError (Bug.prettyPrint (I.format_idstatus idstatus));
              Bug.printError "\n";
              raise
                UserLevelPrimError
                  (loc, UE.IdNotFound("002", {longsymbol = refLongsymbol}))
              )
        end 

    fun getExExnInfo (path:string list) =
        fn (loc:Loc.loc) =>
        let
          val refLongsymbol = mkLongsymbolWithLoc loc path
          val (sym, idstatus) = findIdstatus refLongsymbol
              handle IDNotFound =>
                     raise        
                       UserLevelPrimError
                         (loc, UE.IdNotFound("002", {longsymbol = refLongsymbol}))
        in
          case idstatus of
          I.IDEXEXN {used, longsymbol,version, ty, defRange} => 
          (analyzeIdRef (refLongsymbol, (sym, idstatus));
           {path = longsymbol, ty = E.evalIty E.emptyContext ty}
          )
        | I.IDEXEXNREP {used, longsymbol,version, ty, defRange} => 
          (analyzeIdRef (refLongsymbol, (sym, idstatus));
           {path = longsymbol, ty = E.evalIty E.emptyContext ty}
          )
        | _ => 
          (Bug.printError "not an expected id (getExExnInfo):";
           Bug.printError (String.concatWith "." path);
           Bug.printError "\n";
           Bug.printError (Bug.prettyPrint (I.format_idstatus idstatus));
           Bug.printError "\n";
           raise
             UserLevelPrimError
               (loc, UE.IdNotFound("002", {longsymbol = refLongsymbol})))
        end
        : Types.exExnInfo

    fun getIcexp (path:string list) =
     fn (loc:Loc.loc) => 
        let
          val exInfo = getExInfo path loc
        in
          I.ICEXVAR {exInfo = exInfo, longsymbol = #longsymbol exInfo}
        end : I.icexp

    fun getExVar (path:string list) =
     fn (loc:Loc.loc) => 
        let
          val exInfo = getExInfo path loc
        in
          {path = #longsymbol exInfo, ty = E.evalIty E.emptyContext (#ty exInfo)}
        end : Types.exVarInfo


    val SQL_tyCon_command =        ["SMLSharp_SQL_Prim","command"];
    val SQL_tyCon_db =             ["SMLSharp_SQL_Prim","db"];
    val SQL_tyCon_exp =            ["SMLSharp_SQL_Prim","exp"];
    val SQL_tyCon_from =           ["SMLSharp_SQL_Prim","from"];
    val SQL_tyCon_limit =          ["SMLSharp_SQL_Prim","limit"];
    val SQL_tyCon_offset =         ["SMLSharp_SQL_Prim","offset"];
    val SQL_tyCon_orderby =        ["SMLSharp_SQL_Prim","orderby"];
    val SQL_tyCon_query =          ["SMLSharp_SQL_Prim","query"];
    val SQL_tyCon_select =         ["SMLSharp_SQL_Prim","select"];
    val SQL_tyCon_whr =            ["SMLSharp_SQL_Prim","whr"];

    val REIFY_tyCon_BoundTypeVarIDMapMap = ["BoundTypeVarID", "Map", "map"];
    val REIFY_tyCon_RecordLabelMapMap    = ["RecordLabel", "Map", "map"];
    val REIFY_tyCon_RECORDLABELty        = ["RecordLabel", "label"];
    val REIFY_tyCon_SENVMAPty            = ["SEnv", "map"];
    val REIFY_tyCon_IENVMAPty            = ["IEnv", "map"];
    val REIFY_tyCon_TypIDMapMap          = ["TypID", "Map", "map"];
    val REIFY_tyCon_void                 = ["ReifiedTy", "void"];
    val REIFY_tyCon_btvId                = ["BoundTypeVarID", "id"];
    val REIFY_tyCon_dyn                  = ["ReifiedTerm", "dyn"];
    val REIFY_tyCon_env                  = ["ReifiedTerm", "env"];
    val REIFY_tyCon_idstatus             = ["ReifiedTerm", "idstatus"];
    val REIFY_tyCon_label                = ["RecordLabel", "label"];
    val REIFY_tyCon_reifiedTerm          = ["ReifiedTerm", "reifiedTerm"];
    val REIFY_tyCon_reifiedTy            = ["ReifiedTy", "reifiedTy"];
    val REIFY_tyCon_typId                = ["TypID", "id"];
    val REIFY_tyCon_existInstMap         = ["PartialDynamic", "existInstMap"];

    val SQL_tyCon_command = getTyCon SQL_tyCon_command
    val SQL_tyCon_db =      getTyCon SQL_tyCon_db
    val SQL_tyCon_exp =     getTyCon SQL_tyCon_exp
    val SQL_tyCon_from =    getTyCon SQL_tyCon_from
    val SQL_tyCon_limit =   getTyCon SQL_tyCon_limit
    val SQL_tyCon_offset =  getTyCon SQL_tyCon_offset
    val SQL_tyCon_orderby = getTyCon SQL_tyCon_orderby
    val SQL_tyCon_query =   getTyCon SQL_tyCon_query
    val SQL_tyCon_select =  getTyCon SQL_tyCon_select
    val SQL_tyCon_whr =     getTyCon SQL_tyCon_whr

    val REIFY_tyCon_BoundTypeVarIDMapMap = getTyCon REIFY_tyCon_BoundTypeVarIDMapMap
    val REIFY_tyCon_RecordLabelMapMap =    getTyCon REIFY_tyCon_RecordLabelMapMap
    val REIFY_tyCon_RECORDLABELty =        getTyCon REIFY_tyCon_RECORDLABELty
    val REIFY_tyCon_SENVMAPty =            getTyCon REIFY_tyCon_SENVMAPty
    val REIFY_tyCon_IENVMAPty =            getTyCon REIFY_tyCon_IENVMAPty
    val REIFY_tyCon_TypIDMapMap =          getTyCon REIFY_tyCon_TypIDMapMap
    val REIFY_tyCon_void =                 getTyCon REIFY_tyCon_void
    val REIFY_tyCon_btvId =                getTyCon REIFY_tyCon_btvId
    val REIFY_tyCon_dyn =                  getTyCon REIFY_tyCon_dyn
    val REIFY_tyCon_env =                  getTyCon REIFY_tyCon_env
    val REIFY_tyCon_idstatus =             getTyCon REIFY_tyCon_idstatus
    val REIFY_tyCon_label =                getTyCon REIFY_tyCon_label
    val REIFY_tyCon_reifiedTerm =          getTyCon REIFY_tyCon_reifiedTerm
    val REIFY_tyCon_reifiedTy =            getTyCon REIFY_tyCon_reifiedTy
    val REIFY_tyCon_typId =                getTyCon REIFY_tyCon_typId
    val REIFY_tyCon_existInstMap =         getTyCon REIFY_tyCon_existInstMap

    val REIFY_conInfo_ARRAYty =                           ["ReifiedTy", "ARRAYty"];
    val REIFY_conInfo_BOOLty =                            ["ReifiedTy", "BOOLty"];
    val REIFY_conInfo_BOTTOMty =                          ["ReifiedTy", "BOTTOMty"];
    val REIFY_conInfo_BOXEDty =                           ["ReifiedTy", "BOXEDty"];
    val REIFY_conInfo_BOUNDVARty =                        ["ReifiedTy", "BOUNDVARty"];
    val REIFY_conInfo_BUILTIN =                           ["ReifiedTerm", "BUILTIN"];
    val REIFY_conInfo_CHARty =                            ["ReifiedTy", "CHARty"];
    val REIFY_conInfo_CODEPTRty =                         ["ReifiedTy", "CODEPTRty"];
    val REIFY_conInfo_DYNAMICty =                         ["ReifiedTy", "DYNAMICty"];
    val REIFY_conInfo_ERRORty =                           ["ReifiedTy", "ERRORty"];
    val REIFY_conInfo_EXNTAGty =                          ["ReifiedTy", "EXNTAGty"];
    val REIFY_conInfo_EXNty =                             ["ReifiedTy", "EXNty"];
    val REIFY_conInfo_INT16ty =                           ["ReifiedTy", "INT16ty"];
    val REIFY_conInfo_INT64ty =                           ["ReifiedTy", "INT64ty"];
    val REIFY_conInfo_INT8ty =                            ["ReifiedTy", "INT8ty"];
    val REIFY_conInfo_INTERNALty =                        ["ReifiedTy", "INTERNALty"];
    val REIFY_conInfo_INTINFty =                          ["ReifiedTy", "INTINFty"];
    val REIFY_conInfo_INT32ty =                           ["ReifiedTy", "INT32ty"];
    val REIFY_conInfo_LAYOUT_ARG_OR_NULL =                ["ReifiedTy", "LAYOUT_ARG_OR_NULL"];
    val REIFY_conInfo_LAYOUT_CHOICE =                     ["ReifiedTy", "LAYOUT_CHOICE"];
    val REIFY_conInfo_LAYOUT_SINGLE =                     ["ReifiedTy", "LAYOUT_SINGLE"];
    val REIFY_conInfo_LAYOUT_SINGLE_ARG =                 ["ReifiedTy", "LAYOUT_SINGLE_ARG"];
    val REIFY_conInfo_LAYOUT_TAGGED =                     ["ReifiedTy", "LAYOUT_TAGGED"];
    val REIFY_conInfo_LISTty =                            ["ReifiedTy", "LISTty"];
    val REIFY_conInfo_IENVMAPty =                         ["ReifiedTy", "IENVMAPty"];
    val REIFY_conInfo_SENVMAPty =                         ["ReifiedTy", "SENVMAPty"];
    val REIFY_conInfo_OPTIONty =                          ["ReifiedTy", "OPTIONty"];
    val REIFY_conInfo_PTRty =                             ["ReifiedTy", "PTRty"];
    val REIFY_conInfo_RECORDLABELty =                     ["ReifiedTy", "RECORDLABELty"];
    val REIFY_conInfo_RECORDLABELMAPty =                  ["ReifiedTy", "RECORDLABELMAPty"];
    val REIFY_conInfo_REAL32ty =                          ["ReifiedTy", "REAL32ty"];
    val REIFY_conInfo_REAL64ty =                          ["ReifiedTy", "REAL64ty"];
    val REIFY_conInfo_REFty =                             ["ReifiedTy", "REFty"];
    val REIFY_conInfo_STRINGty =                          ["ReifiedTy", "STRINGty"];
    val REIFY_conInfo_TAGGED_OR_NULL =                    ["ReifiedTy", "TAGGED_OR_NULL"];
    val REIFY_conInfo_TAGGED_RECORD =                     ["ReifiedTy", "TAGGED_RECORD"];
    val REIFY_conInfo_TAGGED_TAGONLY =                    ["ReifiedTy", "TAGGED_TAGONLY"];
    val REIFY_conInfo_VOIDty =                            ["ReifiedTy", "VOIDty"];
    val REIFY_conInfo_TYVARty =                           ["ReifiedTy", "TYVARty"];
    val REIFY_conInfo_UNITty =                            ["ReifiedTy", "UNITty"];
    val REIFY_conInfo_VECTORty =                          ["ReifiedTy", "VECTORty"];
    val REIFY_conInfo_WORD16ty =                          ["ReifiedTy", "WORD16ty"];
    val REIFY_conInfo_WORD64ty =                          ["ReifiedTy", "WORD64ty"];
    val REIFY_conInfo_WORD8ty =                           ["ReifiedTy", "WORD8ty"];
    val REIFY_conInfo_WORD32ty =                          ["ReifiedTy", "WORD32ty"];

    val REIFY_conInfo_ARRAYty = getCon REIFY_conInfo_ARRAYty
    val REIFY_conInfo_BOOLty = getCon REIFY_conInfo_BOOLty
    val REIFY_conInfo_BOTTOMty = getCon REIFY_conInfo_BOTTOMty
    val REIFY_conInfo_BOXEDty = getCon REIFY_conInfo_BOXEDty
    val REIFY_conInfo_BOUNDVARty = getCon REIFY_conInfo_BOUNDVARty
    val REIFY_conInfo_BUILTIN = getCon REIFY_conInfo_BUILTIN
    val REIFY_conInfo_CHARty = getCon REIFY_conInfo_CHARty
    val REIFY_conInfo_CODEPTRty = getCon REIFY_conInfo_CODEPTRty
    val REIFY_conInfo_DYNAMICty = getCon REIFY_conInfo_DYNAMICty
    val REIFY_conInfo_ERRORty = getCon REIFY_conInfo_ERRORty
    val REIFY_conInfo_EXNTAGty = getCon REIFY_conInfo_EXNTAGty
    val REIFY_conInfo_EXNty = getCon REIFY_conInfo_EXNty
    val REIFY_conInfo_INT16ty = getCon REIFY_conInfo_INT16ty
    val REIFY_conInfo_INT64ty = getCon REIFY_conInfo_INT64ty
    val REIFY_conInfo_INT8ty = getCon REIFY_conInfo_INT8ty
    val REIFY_conInfo_INTERNALty = getCon REIFY_conInfo_INTERNALty
    val REIFY_conInfo_INTINFty = getCon REIFY_conInfo_INTINFty
    val REIFY_conInfo_INT32ty = getCon REIFY_conInfo_INT32ty
    val REIFY_conInfo_LAYOUT_ARG_OR_NULL = getCon REIFY_conInfo_LAYOUT_ARG_OR_NULL
    val REIFY_conInfo_LAYOUT_CHOICE = getCon REIFY_conInfo_LAYOUT_CHOICE
    val REIFY_conInfo_LAYOUT_SINGLE = getCon REIFY_conInfo_LAYOUT_SINGLE
    val REIFY_conInfo_LAYOUT_SINGLE_ARG = getCon REIFY_conInfo_LAYOUT_SINGLE_ARG
    val REIFY_conInfo_LAYOUT_TAGGED = getCon REIFY_conInfo_LAYOUT_TAGGED
    val REIFY_conInfo_LISTty = getCon REIFY_conInfo_LISTty
    val REIFY_conInfo_IENVMAPty = getCon REIFY_conInfo_IENVMAPty
    val REIFY_conInfo_SENVMAPty = getCon REIFY_conInfo_SENVMAPty
    val REIFY_conInfo_OPTIONty = getCon REIFY_conInfo_OPTIONty
    val REIFY_conInfo_PTRty = getCon REIFY_conInfo_PTRty
    val REIFY_conInfo_RECORDLABELty = getCon REIFY_conInfo_RECORDLABELty
    val REIFY_conInfo_RECORDLABELMAPty = getCon REIFY_conInfo_RECORDLABELMAPty
    val REIFY_conInfo_REAL32ty = getCon REIFY_conInfo_REAL32ty
    val REIFY_conInfo_REAL64ty = getCon REIFY_conInfo_REAL64ty
    val REIFY_conInfo_REFty = getCon REIFY_conInfo_REFty
    val REIFY_conInfo_STRINGty = getCon REIFY_conInfo_STRINGty
    val REIFY_conInfo_TAGGED_OR_NULL = getCon REIFY_conInfo_TAGGED_OR_NULL
    val REIFY_conInfo_TAGGED_RECORD = getCon REIFY_conInfo_TAGGED_RECORD
    val REIFY_conInfo_TAGGED_TAGONLY = getCon REIFY_conInfo_TAGGED_TAGONLY
    val REIFY_conInfo_VOIDty = getCon REIFY_conInfo_VOIDty
    val REIFY_conInfo_TYVARty = getCon REIFY_conInfo_TYVARty
    val REIFY_conInfo_UNITty = getCon REIFY_conInfo_UNITty
    val REIFY_conInfo_VECTORty = getCon REIFY_conInfo_VECTORty
    val REIFY_conInfo_WORD16ty = getCon REIFY_conInfo_WORD16ty
    val REIFY_conInfo_WORD64ty = getCon REIFY_conInfo_WORD64ty
    val REIFY_conInfo_WORD8ty = getCon  REIFY_conInfo_WORD8ty
    val REIFY_conInfo_WORD32ty = getCon REIFY_conInfo_WORD32ty

    val REIFY_exExnInfo_NaturalJoin =      ["NaturalJoin", "NaturalJoin"];
    val REIFY_exExnInfo_RuntimeTypeError = ["PartialDynamic", "RuntimeTypeError"];

    val REIFY_exExnInfo_NaturalJoin = getExExnInfo REIFY_exExnInfo_NaturalJoin
    val REIFY_exExnInfo_RuntimeTypeError = getExExnInfo REIFY_exExnInfo_RuntimeTypeError

    val SQL_exInfo_toyServer =     ["SMLSharp_SQL_Prim", "toyServer"];
    val SQL_icexp_toyServer = getIcexp SQL_exInfo_toyServer

    val REIFY_exInfo_RecordLabelFromString                  = ["RecordLabel", "fromString"];
    val REIFY_exInfo_SymbolMkLongSymbol                     = ["Symbol", "mkLongsymbol"];
    val REIFY_exInfo_TyRep                                  = ["ReifiedTy", "TyRep"];
    val REIFY_exInfo_TyRepToReifiedTy                       = ["ReifiedTy", "TyRepToReifiedTy"];
    val REIFY_exInfo_MergeConSetEnvWithTyRepList            = ["ReifiedTy", "MergeConSetEnvWithTyRepList"];
    val REIFY_exInfo_boolToWrapRecord                       = ["ReifiedTy", "boolToWrapRecord"];
    val REIFY_exInfo_boundenvReifiedTyToPolyTy              = ["ReifiedTy", "boundenvReifiedTyToPolyTy"];
    val REIFY_exInfo_btvIdBtvIdListToBoundenv               = ["ReifiedTy", "btvIdBtvIdListToBoundenv"];
    val REIFY_exInfo_coerceTermGeneric                      = ["PartialDynamic", "coerceTermGeneric"];
    val REIFY_exInfo_checkTermGeneric                       = ["PartialDynamic", "checkTermGeneric"];
    val REIFY_exInfo_viewTermGeneric                        = ["PartialDynamic", "viewTermGeneric"];
    val REIFY_exInfo_null                                   = ["PartialDynamic", "null"];
    val REIFY_exInfo_void                                   = ["PartialDynamic", "void"];
    val REIFY_exInfo_dynamicTypeCase                        = ["PartialDynamic", "dynamicTypeCase"];
    val REIFY_exInfo_dynamicExistInstance                   = ["PartialDynamic", "dynamicExistInstance"];
    val REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy = ["ReifiedTy", "longsymbolIdArgsLayoutListToDatatypeTy"];
    val REIFY_exInfo_longsymbolIdArgsToOpaqueTy             = ["ReifiedTy", "longsymbolIdArgsToOpaqueTy"];
    val REIFY_exInfo_makeDummyTy                            = ["ReifiedTy", "makeDummyTy"];
    val REIFY_exInfo_makeExistTy                            = ["ReifiedTy", "makeExistTy"];
    val REIFY_exInfo_makeFUNMty                             = ["ReifiedTy", "makeFUNMty"];
    val REIFY_exInfo_makePos                                = ["ReifiedTy", "makePos"];
    val REIFY_exInfo_mkENVenv                               = ["ReifiedTerm", "mkENVenv"];
    val REIFY_exInfo_mkEXEXNIdstatus                        = ["ReifiedTerm", "mkEXEXNIdstatus"];
    val REIFY_exInfo_mkEXEXNREPIdstatus                     = ["ReifiedTerm", "mkEXEXNREPIdstatus"];
    val REIFY_exInfo_mkEXVarIdstatus                        = ["ReifiedTerm", "mkEXVarIdstatus"];
    val REIFY_exInfo_mkTopEnv                               = ["ReifiedTerm", "mkTopEnv"];
    val REIFY_exInfo_naturalJoin                            = ["NaturalJoin", "naturalJoin"];
    val REIFY_exInfo_extend                                 = ["NaturalJoin", "extend"];
    val REIFY_exInfo_printTopEnv                            = ["ReifiedTerm", "printTopEnv"];
    val REIFY_exInfo_reifiedTermToML                        = ["ReifiedTermToML", "reifiedTermToML"];
    val REIFY_exInfo_stringIntListToTagMap                  = ["ReifiedTy", "stringIntListToTagMap"];
    val REIFY_exInfo_stringReifiedTyListToRecordTy          = ["ReifiedTy", "stringReifiedTyListToRecordTy"];
    val REIFY_exInfo_stringReifiedTyOptionListToConSet      = ["ReifiedTy", "stringReifiedTyOptionListToConSet"];
    val REIFY_exInfo_stringToFalseNameRecord                = ["ReifiedTy", "stringToFalseNameRecord"];
    val REIFY_exInfo_tagMapStringToTagMapNullNameRecord     = ["ReifiedTy", "tagMapStringToTagMapNullNameRecord"];
    val REIFY_exInfo_tagMapToTagMapRecord                   = ["ReifiedTy", "tagMapToTagMapRecord"];
    val REIFY_exInfo_toReifiedTerm                          = ["ReifyTerm", "toReifiedTerm"];
    val REIFY_exInfo_toReifiedTermPrint                     = ["ReifyTerm", "toReifiedTermPrint"];
    val REIFY_exInfo_typIdConSetListToConSetEnv             = ["ReifiedTy", "typIdConSetListToConSetEnv"];

    val REIFY_exInfo_RecordLabelFromString = getExVar REIFY_exInfo_RecordLabelFromString
    val REIFY_exInfo_SymbolMkLongSymbol = getExVar  REIFY_exInfo_SymbolMkLongSymbol
    val REIFY_exInfo_TyRep =  getExVar  REIFY_exInfo_TyRep
    val REIFY_exInfo_TyRepToReifiedTy =  getExVar  REIFY_exInfo_TyRepToReifiedTy
    val REIFY_exInfo_MergeConSetEnvWithTyRepList =  getExVar  REIFY_exInfo_MergeConSetEnvWithTyRepList
    val REIFY_exInfo_boolToWrapRecord =  getExVar  REIFY_exInfo_boolToWrapRecord
    val REIFY_exInfo_boundenvReifiedTyToPolyTy =  getExVar  REIFY_exInfo_boundenvReifiedTyToPolyTy
    val REIFY_exInfo_btvIdBtvIdListToBoundenv =  getExVar  REIFY_exInfo_btvIdBtvIdListToBoundenv
    val REIFY_exInfo_coerceTermGeneric =  getExVar  REIFY_exInfo_coerceTermGeneric
    val REIFY_exInfo_checkTermGeneric =  getExVar  REIFY_exInfo_checkTermGeneric
    val REIFY_exInfo_viewTermGeneric =  getExVar  REIFY_exInfo_viewTermGeneric
    val REIFY_exInfo_null =  getExVar  REIFY_exInfo_null
    val REIFY_exInfo_void =  getExVar  REIFY_exInfo_void
    val REIFY_exInfo_dynamicTypeCase =  getExVar  REIFY_exInfo_dynamicTypeCase
    val REIFY_exInfo_dynamicExistInstance =  getExVar  REIFY_exInfo_dynamicExistInstance
    val REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy =  getExVar  REIFY_exInfo_longsymbolIdArgsLayoutListToDatatypeTy
    val REIFY_exInfo_longsymbolIdArgsToOpaqueTy =  getExVar  REIFY_exInfo_longsymbolIdArgsToOpaqueTy
    val REIFY_exInfo_makeDummyTy =  getExVar  REIFY_exInfo_makeDummyTy
    val REIFY_exInfo_makeExistTy =  getExVar  REIFY_exInfo_makeExistTy
    val REIFY_exInfo_makeFUNMty =  getExVar  REIFY_exInfo_makeFUNMty
    val REIFY_exInfo_makePos =  getExVar  REIFY_exInfo_makePos
    val REIFY_exInfo_mkENVenv =  getExVar  REIFY_exInfo_mkENVenv
    val REIFY_exInfo_mkEXEXNIdstatus =  getExVar  REIFY_exInfo_mkEXEXNIdstatus
    val REIFY_exInfo_mkEXEXNREPIdstatus =  getExVar  REIFY_exInfo_mkEXEXNREPIdstatus
    val REIFY_exInfo_mkEXVarIdstatus =  getExVar  REIFY_exInfo_mkEXVarIdstatus
    val REIFY_exInfo_mkTopEnv =  getExVar  REIFY_exInfo_mkTopEnv
    val REIFY_exInfo_naturalJoin =  getExVar  REIFY_exInfo_naturalJoin
    val REIFY_exInfo_extend =  getExVar  REIFY_exInfo_extend
    val REIFY_exInfo_printTopEnv =  getExVar  REIFY_exInfo_printTopEnv
    val REIFY_exInfo_reifiedTermToML =  getExVar  REIFY_exInfo_reifiedTermToML
    val REIFY_exInfo_stringIntListToTagMap =  getExVar  REIFY_exInfo_stringIntListToTagMap
    val REIFY_exInfo_stringReifiedTyListToRecordTy =  getExVar  REIFY_exInfo_stringReifiedTyListToRecordTy
    val REIFY_exInfo_stringReifiedTyOptionListToConSet =  getExVar  REIFY_exInfo_stringReifiedTyOptionListToConSet
    val REIFY_exInfo_stringToFalseNameRecord =  getExVar  REIFY_exInfo_stringToFalseNameRecord
    val REIFY_exInfo_tagMapStringToTagMapNullNameRecord =  getExVar  REIFY_exInfo_tagMapStringToTagMapNullNameRecord
    val REIFY_exInfo_tagMapToTagMapRecord =  getExVar  REIFY_exInfo_tagMapToTagMapRecord
    val REIFY_exInfo_toReifiedTerm =  getExVar  REIFY_exInfo_toReifiedTerm
    val REIFY_exInfo_toReifiedTermPrint =  getExVar  REIFY_exInfo_toReifiedTermPrint
    val REIFY_exInfo_typIdConSetListToConSetEnv =  getExVar  REIFY_exInfo_typIdConSetListToConSetEnv

  end
end

