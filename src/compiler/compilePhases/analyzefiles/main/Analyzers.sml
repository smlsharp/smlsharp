structure Analyzers =
struct
local
  structure D = Dynamic 
  structure I = IDCalc 
  structure S = Symbol 
  structure L = Loc
  structure P = PrintUtils
  structure B = BuiltinPrimitive
  structure V = NameEvalEnv
  structure U = AnalyzerUtils

  open AnalyzerTy 
  open DBSchema 
  exception IlleagalLoc
  structure IM = InfoMaps
  exception SYSTEMPATH

  fun locToKey (L.POS{source = L.FILE s, pos,...},_) = 
      ({fileId = #fileId (IM.findSourceMap s), startPos = pos}
       handle x => raise x)
    | locToKey _ = {fileId = ~1, startPos = ~1}
  fun locRange loc = 
      case loc of 
        (L.POS{source = L.FILE s, pos=startPos, ...}, 
         L.POS{pos=endPos, ...}) => 
        (startPos, endPos, #fileId (IM.findSourceMap s))
  |  _ => (~1, ~1, ~1)
  fun defRangeInfo loc =
      let
        val (s,e, f) = locRange loc
      in
        {defRangeStartPos = s,
         defRangeEndPos = e,
         defRangeFileId = f
        }
      end
  fun defSymLocInfo symbol =
      let
        val loc = S.symbolToLoc symbol
        val symbol = S.symbolToString symbol
        val (s, e, f) = locRange loc
      in
        {locKey = locToKey loc,
         defSymInfo = 
           {defSymbolStartPos = s, 
            defSymbolEndPos = e,
            defSymbolFileId = f,
            defSymbol = symbol
           }
        }
      end
  fun refLongSymLocInfo longsymbol =
      let
        val loc = S.longsymbolToLoc longsymbol
        val symbol = S.longsymbolToString longsymbol
        val (s, e, f) = locRange loc
      in
        {locKey = locToKey loc,
         refSymInfo =
          {refSymbolStartPos = s, 
           refSymbolEndPos = e,
           refSymbolFileId = f,
           refSymbol = symbol
          }
        }
      end
  fun refSymLocInfo symbol =
      let
        val loc = S.symbolToLoc symbol
        val symbol = S.symbolToString symbol
        val (s, e, f) = locRange loc
      in
        {locKey = locToKey loc,
         refSymInfo =
          {refSymbolStartPos = s, 
           refSymbolEndPos = e,
           refSymbolFileId = f,
           refSymbol = symbol
          }
        }
      end
  fun handlerSymbol symbol code =
      (print (S.symbolToString symbol ^ "(" ^ code ^ ")\n"); ())
  fun handlerLongsymbol longsymbol code =
      (print (S.longsymbolToString longsymbol^ "(" ^ code ^ ")\n"); ())

  val idInfo =
      {kind  = "",
       definedSymbol = "",
       internalId = ~1,
       defRangeStartPos = ~1, 
       defRangeEndPos = ~1,
       defRangeFileId = ~1
       }

  val nameRefTracing = ref false
  val nameRefTracingSave = ref false
  val sourceFileIdStack = ref nil
  val provideTracing = ref false
  val provideTracingSave = ref false
  val bindTracing = ref false
  val bindTracingSave = ref false

in
  type symbol = Symbol.symbol
  type longsymbol = Symbol.longsymbol
  type idstatus = IDCalc.idstatus

  type analyzers =
    {
     idstatus: int -> Symbol.symbol * IDCalc.idstatus -> unit, 
     tstr : int -> Symbol.symbol * NameEvalEnv.tstr -> unit,
     strEntry: int -> Symbol.symbol * NameEvalEnv.strEntry -> unit,
     funEEntry: int -> Symbol.symbol * NameEvalEnv.funEEntry -> unit,
     sigEntry: int -> Symbol.symbol * NameEvalEnv.sigEntry -> unit
    }

  fun startNameRefTracing () = 
      (nameRefTracing := true; 
       bindTracing := true;
       provideTracing := true
      )
  fun stopNameRefTracing () = 
      (nameRefTracing := false; 
       bindTracing := false;
       provideTracing := false
      )

  fun stopBindTracing () = 
       bindTracing := false

  fun pushSourceFileId id =
      sourceFileIdStack := (id :: !sourceFileIdStack)
  fun popSourceFileId () =
      case !sourceFileIdStack of
        nil => ()
      | h::t =>  sourceFileIdStack := t
  fun topSourceFileId () =
      case !sourceFileIdStack of
        nil => ~3
      | h::_ => h

  fun pushInterfaceTracer source =
    if !Control.doNameAnalysis then
      let
        val fileId = IM.findSourceMap source
               handle x => (print "a2\n";raise x)
        val _ = if InfoMaps.memberProcessedFiles fileId then 
                  (nameRefTracingSave := !nameRefTracing;
                   bindTracingSave := !bindTracing;
                   provideTracingSave := !provideTracing;
                   stopNameRefTracing ())
                else 
                  (nameRefTracingSave := !nameRefTracing;
                   provideTracing := !provideTracingSave;
                   bindTracingSave := !bindTracing;
                   startNameRefTracing ())
      in
        ()
      end
    else ()

  fun popInterfaceTracer source =
    if !Control.doNameAnalysis then
      let
        val fileId = IM.findSourceMap source
               handle x => (print "a3\n";raise x)
        val _ = if InfoMaps.memberProcessedFiles fileId then 
                  (nameRefTracing := !nameRefTracingSave;
                   bindTracingSave := !bindTracing;
                   provideTracingSave := !provideTracing
                  )
                else 
                  (InfoMaps.insertProcessedFiles fileId;
                   bindTracing := !bindTracingSave;
                   provideTracing := !provideTracingSave;
                   nameRefTracing := !nameRefTracingSave
                  )
      in
        ()
      end
    else ()


  fun nameTracing () = !nameRefTracing

  fun idstatusInfo idstatus =
      case idstatus of
        I.IDVAR {defRange, id, longsymbol, ...} =>
        idInfo
          # {{kind = "IDVAR",
             internalId = VarID.toInt id,
             definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDVAR_TYPED {defRange, id, ty, longsymbol, ...} =>
        idInfo
          # {{kind = "IDVAR_TYPED",
             internalId = VarID.toInt id,
             definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDEXVAR {defRange, exInfo = {longsymbol, ty, ...}, ...} =>
        idInfo
          # {{kind = "IDEXVAR",
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDEXVAR_TOBETYPED {defRange, longsymbol,id:VarID.id, ...} =>
        idInfo
          # {{kind = "IDEXVAR_TOBETYPED",
              internalId = VarID.toInt id,
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDBUILTINVAR {defRange, primitive, ty, ...} =>
        idInfo
          # {{kind = "IDBUILTINVAR",
              definedSymbol = P.primitiveToString primitive
             }}
          # {(defRangeInfo defRange)}
      | I.IDCON {defRange, id:ConID.id, ty, longsymbol,...} =>
        idInfo
          # {{kind = "IDCON",
              internalId = ConID.toInt id,
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDEXN {defRange, id:ExnID.id, ty, longsymbol, ...} =>
        idInfo
          # {{kind = "IDEXN",
              internalId = ExnID.toInt id,
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDEXNREP {defRange, id:ExnID.id, ty, longsymbol, ...} =>
        idInfo
          # {{kind = "IDEXNREP",
              internalId = ExnID.toInt id,
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDEXEXN {defRange, used, longsymbol, version, ty, ...} =>
        idInfo
          # {{kind = "IDEXEXN",
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDEXEXNREP {defRange, used, ty, version, longsymbol, ...} =>
        idInfo
          # {{kind = "IDEXEXNREP",
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDOPRIM {defRange, id:OPrimID.id, longsymbol,...} =>
        idInfo
          # {{kind = "IDOPRIM",
              internalId = OPrimID.toInt id, 
              definedSymbol = S.longsymbolToString longsymbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDSPECVAR {defRange, ty, symbol, ...} =>
        idInfo
          # {{kind = "IDSPECVAR",
              definedSymbol = S.symbolToString symbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDSPECEXN {defRange, ty, symbol, ...} =>
        idInfo
          # {{kind = "IDSPECEXN",
              definedSymbol = S.symbolToString symbol
             }}
          # {(defRangeInfo defRange)}
      | I.IDSPECCON {defRange, symbol, ...} =>
        idInfo
          # {{kind = "IDSPECCON",
              definedSymbol = S.symbolToString symbol
             }}
          # {(defRangeInfo defRange)}
  fun tstrInfo tstr = 
    let
      val (tfun, kind, defRange) = 
          case tstr of 
            V.TSTR {tfun, defRange} => (tfun, "TSTR", defRange)
          | V.TSTR_DTY {tfun, defRange, ...} => (tfun, "TSTR_DTY", defRange)
      val definedSymbol =
          Symbol.longsymbolToString
            (IDCalc.tfunLongsymbol tfun)
    in
      {tstrInfo = idInfo
                   # {{kind = kind}}
                   # {(defRangeInfo defRange)}
                   # {definedSymbol = definedSymbol},
       tfun = tfun,
       defRange = defRange}
      end

(* --------------------------------------------------------------- *)
(* for defTable *)

  (* call from
     NameEvalEnvPrim.{rebindId,rebindIdLongsymbol}
   *)
  fun rebindId cat (sym, idstatus) =
   (if !Control.doNameAnalysis andalso !bindTracing andalso cat <> PROVIDE then
       let
         val {locKey, defSymInfo} = defSymLocInfo sym
         val defInfo : defTuple = 
            defTupleTemplate
              # {{category = Dynamic.tagOf cat}}
              # {(idstatusInfo idstatus)}
              # {defSymInfo}
              # {{sourceFileId = topSourceFileId()}}
        val _ = IM.insertDefMap defInfo
      in
        ()
      end
    else ()
   ) handle U.OnStdPath => ()
         
  (* called from
      NameEvalEnvPrims.{rebindTstr, rebindTstrLongsymbol}
  *)
  fun rebindTstr cat (symbol, tstr) =
    if !Control.doNameAnalysis andalso !bindTracing andalso cat <> PROVIDE then
    let
      val {locKey, defSymInfo} = defSymLocInfo symbol
      val {tstrInfo, tfun,...} = tstrInfo tstr
      val tfunKind =
          case tfun of
            I.TFUN_DEF _ => "TFUN_DEF"
          | I.TFUN_VAR (ref (I.TFUN_DTY _ )) => "TFUN_DTY"
          | I.TFUN_VAR (ref (I.TFV_SPEC _ )) => "TFV_SPEC"
          | I.TFUN_VAR (ref (I.TFV_DTY _ )) => "TFV_DTY"
          | I.TFUN_VAR (ref (I.REALIZED _ )) => "REALIZED"
          | I.TFUN_VAR (ref (I.INSTANTIATED _ )) => "INSTANTIATED"
          | I.TFUN_VAR (ref (I.FUN_DTY _ )) => "FUN_DTY"
      val internalId = (TypID.toInt (I.tfunId tfun)) handle e => ~1
      val defInfo =
          defTupleTemplate
            # {{category = Dynamic.tagOf cat}}
            # {defSymInfo}
            # {tstrInfo}
            # {{sourceFileId = topSourceFileId()}}
            # {{tfunKind = tfunKind,
                internalId = internalId}}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
    handle U.OnStdPath => ()
    else ()

  (* called from
     NameEvalEnvPrims.rebindStr
  *)
  fun rebindStr cat (sym, {loc=defRange, definedSymbol, ...}) =
    if !Control.doNameAnalysis andalso !bindTracing andalso cat <> PROVIDE then
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val definedSymbol = Symbol.longsymbolToString definedSymbol
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf cat}}
            # {defSymInfo}
            # {{kind = "STR"}}
            # {definedSymbol = definedSymbol}
            # {{sourceFileId = topSourceFileId()}}
            # {(defRangeInfo defRange)}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
    handle U.OnStdPath => ()
    else ()

  (* called from
    NameEvalEnvPrims.rebindSigE
  *)
  fun rebindSig cat (sym, {loc=defRange,...}) =
    if !Control.doNameAnalysis andalso !bindTracing then
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf cat}}
            # {defSymInfo}
            # {{kind = "SIG"}}
            # {{sourceFileId = topSourceFileId()}}
            # {(defRangeInfo defRange)}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
    handle U.OnStdPath => ()
    else ()

  (* called from
     NameEvalEnvPrims.rebindFunE
  *)
  fun rebindFun cat (sym, {loc=defRange,...}) =
    if !Control.doNameAnalysis andalso !bindTracing andalso cat <> PROVIDE then
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf cat}}
            # {defSymInfo}
            # {{kind = "FUN"}}
            # {{sourceFileId = topSourceFileId()}}
            # {(defRangeInfo defRange)}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
     handle U.OnStdPath => ()
    else ()

  (* called from
     ./analyzers
        -> AnalyzeSource.{analyzeSource, analyzeInterface}
  *)
  fun analyzeIdstatus fileId (sym, idstatus) =
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf TOPENV}}
            # {(idstatusInfo idstatus)}
            # {defSymInfo}
            # {{sourceFileId = topSourceFileId()}}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
      handle U.OnStdPath => ()

  (* called from
     ./analyzers
        -> AnalyzeSource.{analyzeSource, analyzeInterface}
  *) 
  fun analyzeTstr fileId (symbol, tstr) =
    let
      val {locKey, defSymInfo} = defSymLocInfo symbol
      val {tstrInfo, tfun,...} = tstrInfo tstr
      val tfunKind =
          case tfun of
            I.TFUN_DEF _ => "TFUN_DEF"
          | I.TFUN_VAR (ref (I.TFUN_DTY _ )) => "TFUN_DTY"
          | I.TFUN_VAR (ref (I.TFV_SPEC _ )) => "TFV_SPEC"
          | I.TFUN_VAR (ref (I.TFV_DTY _ )) => "TFV_DTY"
          | I.TFUN_VAR (ref (I.REALIZED _ )) => "REALIZED"
          | I.TFUN_VAR (ref (I.INSTANTIATED _ )) => "INSTANTIATED"
          | I.TFUN_VAR (ref (I.FUN_DTY _ )) => "FUN_DTY"
      val internalId = (TypID.toInt (I.tfunId tfun)) handle e => ~1
      val defInfo =
          defTupleTemplate
            # {{category = Dynamic.tagOf TOPENV}}
            # {defSymInfo}
            # {tstrInfo}
            # {{sourceFileId = topSourceFileId()}}
            # {{tfunKind = tfunKind,
                internalId = internalId}}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
      handle U.OnStdPath => ()

  (* called from
     ./analyzers
        -> AnalyzeSource.{analyzeSource, analyzeInterface}
  *)
  fun analyzeStr fileId (sym, {loc=defRange, definedSymbol,...}) =
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val definedSymbol = Symbol.longsymbolToString definedSymbol
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf TOPENV}}
            # {defSymInfo}
            # {definedSymbol = definedSymbol}
            # {{kind = "STR"}}
            # {(defRangeInfo defRange)}
            # {{sourceFileId = topSourceFileId()}}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
      handle U.OnStdPath => ()

 (* called from
     ./analyzers
        -> AnalyzeSource.{analyzeSource, analyzeInterface}
  *)
  fun analyzeSig fileId (sym, {loc=defRange,...}) =
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf TOPENV}}
            # {defSymInfo}
            # {{kind = "SIG"}}
            # {(defRangeInfo defRange)}
            # {{sourceFileId = topSourceFileId()}}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
      handle U.OnStdPath => ()

  (* called from
     ./analyzers
        -> AnalyzeSource.{analyzeSource, analyzeInterface}
  *)
  fun analyzeFun fileId (sym, {loc=defRange,...}) =
    let
      val {locKey, defSymInfo} = defSymLocInfo sym
      val defInfo : defTuple = 
          defTupleTemplate
            # {{category = Dynamic.tagOf TOPENV}}
            # {defSymInfo}
            # {{kind = "FUN"}}
            # {(defRangeInfo defRange)}
            # {{sourceFileId = topSourceFileId()}}
      val _ = IM.insertDefMap defInfo
    in
      ()
    end
      handle U.OnStdPath => ()

(* --------------------------------------------------------------- *)
(* refTable *)

  (* call from
     NameEvalEnvPrim.{findId, findCon}
   *)
  fun analyzeIdRef (longsymbol, (sym, idstatus)) =
    if !Control.doNameAnalysis andalso !nameRefTracing then
      let
        val {locKey, refSymInfo} = refLongSymLocInfo longsymbol
        val refInfo =
            refTupleTemplate
              # {{category = Dynamic.tagOf FIND}}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
              # {(idstatusInfo idstatus)}
              # {{sourceFileId = topSourceFileId()}}
        val _ = IM.insertRefMap (locKey, refInfo)
      in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from
     NameEvalEnvPrim.findTstr
  *)
  fun analyzeTstrRef (longsymbol, (sym, tstr)) =
    if !Control.doNameAnalysis andalso !nameRefTracing then
      let
        val {locKey, refSymInfo} = refLongSymLocInfo longsymbol
        val {tstrInfo, tfun, ...} = tstrInfo tstr
        val refInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf FIND}}
              # {tstrInfo}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
              # {{sourceFileId = topSourceFileId()}}
        val _ = IM.insertRefMap (locKey, refInfo)
      in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from
    NameEvalEnvPrims.{findId,findCon,findTstr,findStr}
  *)
  fun analyzeStrRef (longsymbol, (sym, {loc,definedSymbol,...})) =
    if !Control.doNameAnalysis andalso !nameRefTracing then
      let
        val {locKey, refSymInfo} = refLongSymLocInfo longsymbol
        val definedSymbol = Symbol.longsymbolToString definedSymbol
        val refInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf FIND}}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
              # {{kind = "STR"}}
              # {definedSymbol = definedSymbol}
              # {(defRangeInfo loc)}
              # {{sourceFileId = topSourceFileId()}}
          val _ = IM.insertRefMap (locKey, refInfo)
        in
        ()
      end
       handle U.OnStdPath => ()
    else ()

  (* called from
     NameEvalEnvPrims.findSigETopEnv
  *)
  fun analyzeSigRef  (symbol, (sym, {loc,...})) =
    if !Control.doNameAnalysis andalso !nameRefTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val refInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf FIND}}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
              # {{kind = "SIG"}}
              # {(defRangeInfo loc)}
              # {{sourceFileId = topSourceFileId()}}
          val _ = IM.insertRefMap (locKey, refInfo)
        in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from
    NameEvalEnvPrims.rebindSigE
  *)
  fun analyzeFunRef (symbol, (sym, {loc,...})) =
    if !Control.doNameAnalysis andalso !nameRefTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val refInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf FIND}}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
              # {{kind = "FUN"}}
              # {(defRangeInfo loc)}
              # {{sourceFileId = topSourceFileId()}}
          val _ = IM.insertRefMap (locKey, refInfo)
        in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* call from
     NameEvalEnvPrim.checkProvideId
   *)
  fun provideId (symbol, (sym, idstatus)) =
    if !Control.doNameAnalysis andalso !provideTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val provideInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf PROVIDE}}
              # {(idstatusInfo idstatus)}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
              # {{sourceFileId = topSourceFileId()}}
        val _ = IM.insertRefMap (locKey, provideInfo)
      in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* call from
     NameEvalEnvPrim.checkDatbind
   *)
  fun provideCon (symbol, sym, definedSymbol) =
    if !Control.doNameAnalysis andalso !provideTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val definedSymbol = Symbol.longsymbolToString definedSymbol
        val provideInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf PROVIDE}}
              # {{kind = "IDCON"}}
              # {refSymInfo}
              # {definedSymbol = definedSymbol}
              # {(#defSymInfo (defSymLocInfo sym))}
        val _ = IM.insertRefMap (locKey, provideInfo)
      in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from
     NameEvalEnvPrims.checkProvideTstr
   *)
  fun provideTstr (symbol, (sym, tstr)) =
    if !Control.doNameAnalysis andalso !provideTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val {tstrInfo, tfun, ...} = tstrInfo tstr
        val provideInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf PROVIDE}}
              # {tstrInfo}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
        val _ = IM.insertRefMap (locKey, provideInfo)
      in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from
    NameEvalEnvPrims.checkProvideStr
  *)
  fun provideStr (symbol, (sym, {loc=defRange, definedSymbol,...})) =
    if !Control.doNameAnalysis andalso !provideTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val definedSymbol = Symbol.longsymbolToString definedSymbol
        val provideInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf PROVIDE}}
              # {{kind = "STR"}}
              # {(defRangeInfo defRange)}
              # {definedSymbol = definedSymbol}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
          val _ = IM.insertRefMap (locKey, provideInfo)
        in
        ()
      end
      handle U.OnStdPath => ()
    else ()


  (* called from NONE?
  *)
  fun provideSig (symbol, (sym, {loc=defRange,...})) =
    if !Control.doNameAnalysis andalso !provideTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val provideInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf PROVIDE}}
              # {{kind = "SIG"}}
              # {(defRangeInfo defRange)}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
          val _ = IM.insertRefMap (locKey, provideInfo)
        in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from
    NameEvalEnvPrims.checkProvideFunETopEnv
  *)
  fun provideFun (symbol, (sym, {loc=defRange,...})) =
    if !Control.doNameAnalysis andalso !provideTracing then
      let
        val {locKey, refSymInfo} = refSymLocInfo symbol
        val provideInfo = 
            refTupleTemplate
              # {{category = Dynamic.tagOf PROVIDE}}
              # {{kind = "FUN"}}
              # {(defRangeInfo defRange)}
              # {refSymInfo}
              # {(#defSymInfo (defSymLocInfo sym))}
          val _ = IM.insertRefMap (locKey, provideInfo)
        in
        ()
      end
      handle U.OnStdPath => ()
    else ()

  (* called from 
     ElaborateCore.findFixity
  *)
  fun insertUPRefMap (symbol, sym) =
      if !Control.doNameAnalysis then
        let
          val refSymbolLoc = Symbol.symbolToLoc symbol
          val refSymbol = S.symbolToString symbol
          val (refSymbolStartPos, refSymbolEndPos, refSymbolFileId) = 
              locRange refSymbolLoc
          val defSymbolLoc = Symbol.symbolToLoc sym
          val defSymbol = Symbol.symbolToString sym
          val (defSymbolStartPos, defSymbolEndPos, defSymbolFileId) = 
              locRange defSymbolLoc
        in
          if Loc.isNoloc refSymbolLoc orelse 
             Loc.isNoloc defSymbolLoc orelse 
             refSymbolFileId = defSymbolFileId
          then ()
          else
            let
              val key = {refFileId = refSymbolFileId,
                         defFileId = defSymbolFileId}
              val UPRefInfo =
                  {refSymbol = refSymbol,
                   refSymbolStartPos = refSymbolStartPos,
                   refSymbolEndPos = refSymbolEndPos, 
                   refSymbolFileId = refSymbolFileId,
                   defSymbol = defSymbol,
                   defSymbolStartPos = defSymbolStartPos,
                   defSymbolEndPos = defSymbolEndPos,
                   defSymbolFileId = defSymbolFileId}
              val _ = IM.insertUPRefMap (key, UPRefInfo)
            in
              ()
            end
        end
        handle U.OnStdPath => ()
      else ()

  (*
    called from 
    Top.compile
     -> UserLevelPrimiive.initAnalyze 
        -> UserLevelPrimiive.analyzeIdRef
           -> UserLevelPrimiive.{getCon,getExInfo,getExExInfo}
  *)
  fun analyzeIdRefForUP (longsymbol, (sym, idstatus)) =
    if !Control.doNameAnalysis then
      let
        val refLongsymbolLoc = Symbol.longsymbolToLoc longsymbol
        val (refSymbolStartPos, refSymbolEndPos, refSymbolFileId) = 
            locRange refLongsymbolLoc
        val refSymbol = S.longsymbolToString longsymbol
        val defSymbolLoc = Symbol.symbolToLoc sym
        val defSymbol = Symbol.symbolToString sym
        val (defSymbolStartPos, defSymbolEndPos, defSymbolFileId) = 
              locRange defSymbolLoc
      in
        if Loc.isNoloc refLongsymbolLoc orelse 
           Loc.isNoloc defSymbolLoc orelse 
           refSymbolFileId = defSymbolFileId
        then ()
        else
          let
            val key = {refFileId = refSymbolFileId,
                       defFileId = defSymbolFileId}
            val UPRefInfo =
                {refSymbol = refSymbol,
                 refSymbolStartPos = refSymbolStartPos,
                 refSymbolEndPos = refSymbolEndPos, 
                 refSymbolFileId = refSymbolFileId,
                 defSymbol = defSymbol,
                 defSymbolStartPos = defSymbolStartPos,
                 defSymbolEndPos = defSymbolEndPos,
                 defSymbolFileId = defSymbolFileId}
            val _ = IM.insertUPRefMap (key, UPRefInfo)
          in
            ()
          end
      end
      handle U.OnStdPath => ()
    else ()


  (*
    called from Top.compile
     -> UserLevelPrimiive.initAnalyze 
        -> UserLevelPrimiive.analyzeTstrRef
           -> UserLevelPrimiive.getTyCon
  *)
  fun analyzeTstrRefForUP (longsymbol, (sym, tstr)) =
    if !Control.doNameAnalysis then
      let
        val longsymbolLoc = Symbol.longsymbolToLoc longsymbol
      in
        if Loc.isNoloc longsymbolLoc then ()
        else
          let
            val (refSymbolStartPos, refSymbolEndPos, refSymbolFileId) = 
                locRange longsymbolLoc
            val refSymbol = S.longsymbolToString longsymbol
            val {tfun,...} = tstrInfo tstr
            val tfunLongsymbol = I.tfunLongsymbol tfun
            val tfunLoc = Symbol.longsymbolToLoc tfunLongsymbol
            val (defSymbolStartPos, defSymbolEndPos, defSymbolFileId) =
                locRange tfunLoc
            val key = {refFileId = refSymbolFileId,
                       defFileId = defSymbolFileId}
            val UPRefInfo =
                UPRefTupleTemplate
                  # {
                  defSymbolStartPos = defSymbolStartPos,
                  defSymbolEndPos = defSymbolEndPos,
                  defSymbolFileId = defSymbolFileId,
                  refSymbol = refSymbol,
                  refSymbolStartPos = refSymbolStartPos,
                  refSymbolEndPos = refSymbolEndPos, 
                  refSymbolFileId = refSymbolFileId,
                  defSymbol = Symbol.longsymbolToString tfunLongsymbol}
            val _ = IM.insertUPRefMap (key, UPRefInfo)
          in
            ()
          end
      end
      handle U.OnStdPath => ()
    else ()



  val emptyAnalyzers  : analyzers =
      {
       idstatus = fn _ => fn _ => (),
       tstr = fn _ => fn _ =>(),
       strEntry = fn _ => fn _ =>(),
       funEEntry = fn _ => fn _ =>(),
       sigEntry = fn _ => fn _ =>()
      }

  val analyzers  : analyzers =
      {
         idstatus = analyzeIdstatus,
         tstr = analyzeTstr,
         strEntry = analyzeStr,
         sigEntry = analyzeSig,
         funEEntry = analyzeFun
      }

end
end
