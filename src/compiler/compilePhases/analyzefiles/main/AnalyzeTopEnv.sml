structure AnalyzeTopEnv =
struct
local
  structure V = NameEvalEnv
  structure IM = InfoMaps
  structure DB = AnalyzerDB
  structure ATy = AnalyzerTy
  exception Skip
in
  type analyzers = Analyzers.analyzers
  fun analyzeTopEnv analyzers (evalTopEnv as {Env=referenceEnv,...}) ({fileId,...}, {Env, FunE, SigE}) =
    let
      type key = {fileId:int, startPos:int}
      fun analyzeEnv (V.ENV{varE, tyE, strE = V.STR strEntryMap}) =
          (SymbolEnv.appi
             (#idstatus analyzers fileId)
             varE;
           SymbolEnv.appi
             (#tstr analyzers fileId)
             tyE;
           SymbolEnv.appi
             (fn (symbol, strEntry as {env, ...}) => 
                 (#strEntry analyzers fileId (symbol, strEntry);
                  analyzeEnv env
                 )
             )
             strEntryMap)
      val _ = analyzeEnv Env
      val _ =
          SymbolEnv.appi
            (fn (symbol, funEEntry as {bodyEnv, ...}) =>
                (#funEEntry analyzers fileId (symbol, funEEntry);
                 analyzeEnv bodyEnv))
            FunE
      val _ =
          SymbolEnv.appi 
            (fn (symbol, sigEntry as {env, ...}) =>
                (#sigEntry analyzers fileId (symbol, sigEntry);
                 analyzeEnv env))
            SigE
    in
      ()
    end

end
end
