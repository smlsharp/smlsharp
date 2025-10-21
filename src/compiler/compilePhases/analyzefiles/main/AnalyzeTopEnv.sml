(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
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
          (SymbolWithLocEnv.appi
             (#idstatus analyzers fileId)
             varE;
           SymbolWithLocEnv.appi
             (#tstr analyzers fileId)
             tyE;
           SymbolWithLocEnv.appi
             (fn (symbol, strEntry as {env, ...}) => 
                 (#strEntry analyzers fileId (symbol, strEntry);
                  analyzeEnv env
                 )
             )
             strEntryMap)
      val _ = analyzeEnv Env
      val _ =
          SymbolWithLocEnv.appi
            (fn (symbol, funEEntry as {bodyEnv, ...}) =>
                (#funEEntry analyzers fileId (symbol, funEEntry);
                 analyzeEnv bodyEnv))
            FunE
      val _ =
          SymbolWithLocEnv.appi
            (fn (symbol, sigEntry as {env, ...}) =>
                (#sigEntry analyzers fileId (symbol, sigEntry);
                 analyzeEnv env))
            SigE
    in
      ()
    end

end
end
