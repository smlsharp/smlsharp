(**
 * @copyright (c) 2018 Tohoku University.
 * @author Atsushi Ohori
 *)
structure NameEvalEnvPrims =
struct
local
  structure I = IDCalc
  structure E = NameEvalError 
  structure V = NameEvalEnv
  structure EU = UserErrorUtils
  fun bug s = Bug.Bug ("NameEvalEnv: " ^ s)
in
  datatype category  = datatype DBSchema.category

  (* find function *)
  fun findId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to findId"
      | symbol :: nil => 
        (case SymbolEnv.findi(varE, symbol) of
           SOME (sym, idstatus) => 
           (Analyzers.analyzeIdRef (longsymbol, (sym, idstatus));
            SOME (sym, idstatus))
         | NONE => NONE)
      | strsymbol :: path =>
        (case SymbolEnv.findi(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME (sym, strEntry as {env,...}) => 
           (Analyzers.analyzeStrRef ([strsymbol], (sym, strEntry));
            findId (env, path))
        )

  (* find function for those that returns an idstatus *)
  fun findCon (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to findCon"
      | symbol :: nil => 
        let
          val idstatusOpt = SymbolEnv.findi(varE, symbol)
        in
          case idstatusOpt of
            (SOME (sym, idstatus as I.IDCON _)) => 
            (Analyzers.analyzeIdRef (longsymbol, (sym, idstatus));
             SOME (sym, idstatus))
          | (SOME (sym, idstatus as I.IDEXN _)) => 
            (Analyzers.analyzeIdRef (longsymbol, (sym, idstatus));
             SOME (sym, idstatus))
          | (SOME (sym, idstatus as I.IDEXNREP _)) =>
            (Analyzers.analyzeIdRef (longsymbol, (sym, idstatus));
             SOME (sym, idstatus))
          | (SOME (sym, idstatus as I.IDEXEXN _)) =>
            (Analyzers.analyzeIdRef (longsymbol, (sym, idstatus));
             SOME (sym, idstatus))
          | (SOME (sym, idstatus as I.IDEXEXNREP _)) =>
            (Analyzers.analyzeIdRef (longsymbol, (sym, idstatus));
             SOME (sym, idstatus))
          | (SOME (sym, I.IDVAR _)) => NONE
          | (SOME (sym, I.IDVAR_TYPED _)) => NONE
          | (SOME (sym, I.IDEXVAR _)) => NONE
          | (SOME (sym, I.IDBUILTINVAR _)) => NONE
          | (SOME (sym, I.IDOPRIM _)) => NONE
          | (SOME (sym, I.IDEXVAR_TOBETYPED _)) => raise bug "IDEXVAR_TOBETYPED to findCon"
          | (SOME (sym, I.IDSPECVAR _)) => raise bug "IDSPECVAR to findCon"
          | (SOME (sym, I.IDSPECEXN _)) => raise bug "IDSPECEXN to findCon"
          | (SOME (sym, I.IDSPECCON _)) => raise bug "IDSPECCON to findCon"
          | NONE => NONE
        end
      | strsymbol :: path =>
        (case SymbolEnv.findi(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME (smbolInEnv, strEntry as {env,...}) => 
           (Analyzers.analyzeStrRef ([strsymbol], (smbolInEnv, strEntry));
            findCon (env, path))
        )

 (* check sig id *)
  fun checkSigId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to checkSigId"
      | symbol :: nil => SymbolEnv.find(varE, symbol)
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkSigId (env, path)
        )

 (* check function *)
  fun checkProvideId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, symbol) =
      case SymbolEnv.findi(varE, symbol) of
        NONE => NONE
      | SOME (sym, idstatus) => 
        (Analyzers.provideId (symbol, (sym, idstatus));
         SOME idstatus)

 (* check function *)
  fun checkProvideAliasId (symbol, V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to checkProvideAliasId"
      | symbol :: nil => SymbolEnv.find(varE, symbol)
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkProvideAliasId (symbol, env, path)
        )

  (* bind function *)
  fun rebindId context (V.ENV{varE, tyE, strE}, symbol, idstatus) =
      (Analyzers.rebindId context (symbol, idstatus);
       V.ENV
         {varE = SymbolEnv.insert(varE, symbol, idstatus),
          tyE = tyE,
          strE = strE
         }
      )
  (* bind function *)
  fun rebindIdLongsymbol context
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, idstatus) : V.env =
    case path of
      nil => raise bug "nil to rebindTypLongid"
    | symbol::nil =>
      (Analyzers.rebindId context (symbol, idstatus);
      V.ENV
        {
         varE = SymbolEnv.insert(varE, symbol, idstatus),
         tyE = tyE,
         strE = strE
        })
    | strsymbol::path =>
      let
        val strEntry as {env,...} = 
            case SymbolEnv.find(envMap, strsymbol) of
              SOME strEntry => strEntry
            | NONE => raise bug "env not found in rebindIdLongsymbol"
        val newEnv = rebindIdLongsymbol context (env, path, idstatus)
      in
        V.ENV
          {
           varE = varE,
           tyE = tyE,
           strE = 
           V.STR (SymbolEnv.insert
                    (envMap, 
                     strsymbol, 
                     strEntry # {env=newEnv}))
          }
      end

  fun findTstr (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "*** nil to findTstr *** "
      | symbol :: nil => 
        (case SymbolEnv.findi(tyE, symbol) of
           SOME (sym, tstr) =>
           (Analyzers.analyzeTstrRef ([symbol], (sym, tstr));
            SOME (sym, tstr))
         | NONE => NONE)
      | strsymbol :: path =>
        (case SymbolEnv.findi(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME (symbolInEnv, strEntry as {env,...}) => 
           (Analyzers.analyzeStrRef ([strsymbol], (symbolInEnv, strEntry));
            findTstr (env, path))
        )

  fun checkProvideAliasTstr (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "*** nil to lookupTy *** "
      | symbol :: nil => SymbolEnv.find(tyE, symbol) 
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkProvideAliasTstr (env, path)
        )

  fun checkProvideTstr (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, symbol) =
      case SymbolEnv.findi(tyE, symbol) of
        NONE => NONE
      | SOME (sym, tstr) => 
        (Analyzers.provideTstr (symbol, (sym, tstr));
         SOME tstr)

  fun rebindTstr context (V.ENV{varE,tyE,strE}, symbol, tstr) =
      (Analyzers.rebindTstr context (symbol, tstr);
       V.ENV
         {
          varE = varE,
          tyE = SymbolEnv.insert(tyE, symbol, tstr),
          strE = strE
         }
      )

  fun rebindTstrLongsymbol context
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, tstr) =
      case path of
        nil => raise bug "nil to rebindTypLongid"
      | symbol::nil =>
        (Analyzers.rebindTstr context (symbol, tstr);
        V.ENV
          {
           varE = varE,
           tyE = SymbolEnv.insert(tyE, symbol, tstr),
           strE = strE
          })
      | strsymbol::path =>
        let
          val strEntry as {env, ...} = 
              case SymbolEnv.find(envMap, strsymbol) of
                SOME strEntry =>strEntry
              | NONE => raise bug "strenv not found in rebindStrLongsymbol"
          val newEnv = rebindTstrLongsymbol context (env, path, tstr)
        in
          V.ENV
            {
             varE = varE,
             tyE = tyE,
             strE = 
             V.STR
               (SymbolEnv.insert
                  (envMap, strsymbol, strEntry # {env=newEnv}))
            }
        end

  (* find function *)
  fun findStr (V.ENV {varE, tyE, strE = V.STR strMap}, longsymbol) = 
      case longsymbol of 
        nil => raise bug "nil to lookupStrId"
      | symbol :: nil =>  
        (case SymbolEnv.findi(strMap, symbol) of
           NONE => NONE
         | SOME (sym, strEntry) => 
           (Analyzers.analyzeStrRef ([symbol], (sym, strEntry));
            SOME strEntry)
        )
      | strsymbol :: path =>
        (case SymbolEnv.findi(strMap, strsymbol) of
           NONE => NONE
         | SOME (symbolInEnv, strEntry as {env,...}) => 
           (Analyzers.analyzeStrRef ([strsymbol], (symbolInEnv, strEntry));
            findStr (env, path))
        )

  (* find function *)
  fun checkProvideAliasStr (V.ENV {varE, tyE, strE = V.STR strMap}, longsymbol) = 
      case longsymbol of 
          nil => raise bug "nil to lookupStrId"
        | symbol :: nil =>  SymbolEnv.find(strMap, symbol) 
        | strsymbol :: path =>
          (case SymbolEnv.find(strMap, strsymbol) of
             NONE => NONE
           | SOME {env,...} => checkProvideAliasStr (env, path)
          )

  (* find function *)
  fun checkProvideStr (V.ENV {varE, tyE, strE = V.STR strMap}, symbol) = 
      case SymbolEnv.findi(strMap, symbol) of
        NONE => NONE
      | SOME (defSymbol, strEntry) => 
        (Analyzers.provideStr (symbol, (defSymbol, strEntry));
         SOME strEntry)

  fun rebindStr context (V.ENV{varE,tyE,strE=V.STR envMap}, symbol, strEntry) =
      (Analyzers.rebindStr context (symbol, strEntry);
      V.ENV {varE = varE,
             tyE = tyE,
             strE = V.STR (SymbolEnv.insert(envMap, symbol, strEntry))
            }
      )

  (* 以下２つは、例外としてサポート *)
  fun checkStr (V.ENV {varE, tyE, strE = V.STR strMap}, longsymbol) = 
      case longsymbol of 
          nil => raise bug "nil to lookupStrId"
        | symbol :: nil =>  SymbolEnv.find(strMap, symbol) 
        | strsymbol :: path =>
          (case SymbolEnv.find(strMap, strsymbol) of
             NONE => NONE
           | SOME {env,...} => checkStr (env, path)
          )
  fun reinsertStr (V.ENV{varE,tyE,strE=V.STR envMap}, symbol, strEntry) =
      V.ENV {varE = varE,
             tyE = tyE,
             strE = V.STR (SymbolEnv.insert(envMap, symbol, strEntry))
            }

  (* bind function *)
  fun singletonStr context (symbol, strEntry) = 
      rebindStr context (V.emptyEnv, symbol, strEntry)

  (* find function *)
  fun findFunETopEnv ({Env, FunE, SigE}, symbol) =
      case SymbolEnv.findi(FunE, symbol) of
        SOME (sym, funEEntry) =>
        (Analyzers.analyzeFunRef (symbol, (sym, funEEntry));
         SOME funEEntry)
      | NONE => NONE

  (* check function *)
  fun checkFunETopEnv ({Env, FunE, SigE}, symbol) =
      SymbolEnv.find(FunE, symbol) 

  (* check function *)
  fun checkProvideFunETopEnv ({Env, FunE, SigE}, symbol) =
      case SymbolEnv.findi(FunE, symbol) of
        SOME (sym, funEEntry) =>
        (Analyzers.provideFun (symbol, (sym, funEEntry));
         SOME funEEntry)
      | NONE => NONE

  (* bind function *)
  fun rebindFunE context (FunE, symbol, funEEntry) =
      (Analyzers.rebindFun context (symbol, funEEntry);
       SymbolEnv.insert(FunE, symbol, funEEntry))


  (* find function *)
  fun findSigETopEnv ({Env, FunE, SigE}, symbol) =
      let
        val sigEntrySymOpt =
            SymbolEnv.findi(SigE, symbol) 
        val sigEntryOpt = 
            case sigEntrySymOpt of
              SOME (sym, sigEntry) =>
              (Analyzers.analyzeSigRef (symbol, (sym, sigEntry));
               SOME (sym, sigEntry))
            | NONE => NONE
      in
        sigEntryOpt
      end

  (* check function *)
  fun checkSigETopEnv ({Env, FunE, SigE}, symbol) =
      SymbolEnv.find(SigE, symbol) 

  (* bind function *)
  fun rebindSigE context (SigE, symbol, sigEntry) =
      (Analyzers.rebindSig context (symbol, sigEntry);
       SymbolEnv.insert(SigE, symbol, sigEntry))

  fun preferSecond arg =
      case arg of
        (NONE, SOME (key2, v2)) => (key2, v2)
      | (SOME (key1, v1), NONE) => (key1, v1)
      | (SOME _, SOME (key2, v2)) => (key2, v2)
      | (NONE, NONE) => raise bug "none in unionWith3"

  (* insert function *)
  fun varEWithVarE (varE1, varE2) = 
      SymbolEnv.unionWith #2 (varE1, varE2)

  (* bind functions *)
  fun bindVarEWithVarE (varE1, varE2) = 
      (
       SymbolEnv.unionWithi3
         preferSecond
         (varE1, varE2)
      )

  (* insert functions *)
  fun tyEWithTyE (tyE1, tyE2) = 
      SymbolEnv.unionWith #2 (tyE1, tyE2)

  (* binding functions *)
  fun bindTyEWithTyE (tyE1, tyE2) = 
      (
       SymbolEnv.unionWithi3
         preferSecond
         (tyE1, tyE2)
      )

  (* insert functions *)
  fun strEWithStrE (V.STR envMap1, V.STR envMap2) = 
      V.STR (SymbolEnv.unionWith #2 (envMap1, envMap2))

  (* binding functions *)
  fun bindStrEWithStrE (V.STR envMap1, V.STR envMap2) = 
      V.STR (SymbolEnv.unionWithi3
                preferSecond
                (envMap1, envMap2))

  (* insert function *)
  fun envWithVarE (V.ENV {varE, strE, tyE}, varE1 : I.varE) =
      V.ENV {varE = varEWithVarE (varE, varE1),
           strE = strE,
           tyE = tyE}

  (* bind functions *)
  fun bindEnvWithVarE (V.ENV {varE, strE, tyE}, varE1 : I.varE) =
      V.ENV {varE = bindVarEWithVarE (varE, varE1),
           strE = strE,
           tyE = tyE}

  (* insert function *)
  fun envWithEnv (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                  V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      V.ENV {varE = varEWithVarE (varE1, varE2),
             strE = strEWithStrE (strE1, strE2),
             tyE = tyEWithTyE (tyE1,tyE2)
            }

  (* bind function *)
  fun bindEnvWithEnv (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                      V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      V.ENV {varE = bindVarEWithVarE (varE1, varE2),
             strE = bindStrEWithStrE (strE1, strE2),
             tyE = bindTyEWithTyE (tyE1,tyE2)
            }

  (* insert function *)
  fun sigEWithSigE (sigE1, sigE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, sigE1) => SymbolEnv.insert(sigE1, symbol, entry))
      sigE1
      sigE2

  (* bind function *)
  fun bindSigEWithSigE (sigE1, sigE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, sigE1) => 
          SymbolEnv.insert(sigE1, symbol, entry))
      sigE1
      sigE2

  (* insert function *)
  fun funEWithFunE (funE1, funE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, funE1) => SymbolEnv.insert(funE1, symbol, entry))
      funE1
      funE2

  (* insert function *)
  fun bindFunEWithFunE (funE1, funE2) =
      SymbolEnv.foldli
      (fn (symbol, entry, funE1) => SymbolEnv.insert(funE1, symbol, entry))
      funE1
      funE2

  (* insert function *)
  fun topEnvWithSigE ({Env, FunE, SigE}, sige) : V.topEnv =
      {Env = Env,
       FunE = FunE,
       SigE = sigEWithSigE (SigE, sige)
      }

  (* bind function *)
  fun bindTopEnvWithSigE ({Env, FunE, SigE}, sige) : V.topEnv =
      {Env = Env,
       FunE = FunE,
       SigE = bindSigEWithSigE (SigE, sige)
      }

  (* insert function *)
  fun topEnvWithFunE ({Env, FunE, SigE}, funE) : V.topEnv =
      {Env = Env,
       FunE = funEWithFunE (FunE, funE),
       SigE = SigE
      }

  (* bind function *)
  fun bindTopEnvWithFunE ({Env, FunE, SigE}, funE) : V.topEnv =
      {Env = Env,
       FunE = funEWithFunE (FunE, funE),
       SigE = SigE
      }

  (* insert function *)
  fun topEnvWithEnv ({Env, FunE, SigE}, env1) : V.topEnv =
      {Env = envWithEnv (Env, env1), FunE = FunE, SigE = SigE}

  (* bind function *)
  fun bindTopEnvWithEnv ({Env, FunE, SigE}, env1) : V.topEnv =
      {Env = envWithEnv (Env, env1), FunE = FunE, SigE = SigE}

  (* insert function *)
  fun topEnvWithTopEnv
        ({Env=env1,FunE=funE1,SigE=sige1},{Env=env2,FunE=funE2,SigE=sige2})
      : V.topEnv
      =
      {Env = envWithEnv (env1, env2),
       FunE = funEWithFunE (funE1, funE2),
       SigE = sigEWithSigE (sige1, sige2)
      }

  (* bind function *)
  fun bindTopEnvWithTopEnv
        ({Env=env1,FunE=funE1,SigE=sige1},{Env=env2,FunE=funE2,SigE=sige2})
      : V.topEnv
      =
      {Env = bindEnvWithEnv (env1, env2),
       FunE = bindFunEWithFunE (funE1, funE2),
       SigE = bindSigEWithSigE (sige1, sige2)
      }

  fun unionVarE code (varE1, varE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol1, v1), (symbol2,v2)) =>
            (case (v1, v2) of
               (I.IDCON {id=id1, ...}, I.IDCON {id = id2,...}) =>
               if ConID.eq(id1, id2) then ()
               else 
                 EU.enqueueError 
                   (Symbol.symbolToLoc symbol2,
                    E.DuplicateVar(code ^ "v", symbol2))
             | _ => 
               EU.enqueueError 
                 (Symbol.symbolToLoc symbol2, 
                  E.DuplicateVar(code ^ "v", symbol2));
             (symbol2, v2))
        )
        (varE1, varE2)

  fun unionTyE code (tyE1, tyE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol1,v1), (symbol2,v2)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc symbol2, 
                E.DuplicateTypName(code ^ "v", symbol2)); 
             (symbol2, v2))
        )
        (tyE1, tyE2)
            
  fun unionStrE code (V.STR map1, V.STR map2) =
      V.STR
        (
         SymbolEnv.unionWithi2
           (fn ((symbol1,v1), (symbol2,v2)) =>
               (EU.enqueueError
                  (Symbol.symbolToLoc symbol2, 
                   E.DuplicateStrName(code ^ "v", symbol2)); 
                (symbol2, v2))
           )
           (map1, map2)
        )
            
  fun unionFunE code (funE1, funE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol,v1),(symbol2,v2)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc symbol2, 
                E.DuplicateFunctor(code ^ "f", symbol2));
             (symbol2, v2))
        )
      (funE1, funE2)

  fun unionSigE code (sigE1, sigE2) =
      SymbolEnv.unionWithi2
        (fn ((symbol1,v1),(symbol2,v2)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc symbol2, 
                E.DuplicateSigname(code ^ "s", symbol2));
             (symbol2,v2))
        )
        (sigE1, sigE2)

  fun unionEnv code (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                     V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      let
        val varE = unionVarE code (varE1, varE2)
        val tyE = unionTyE code (tyE1, tyE2)
        val strE = unionStrE code (strE1, strE2)
      in
        V.ENV{varE=varE, strE=strE, tyE=tyE}
      end

  fun unionTopEnv code
        ({Env=env1,FunE=funE1,SigE=sige1},{Env=env2,FunE=funE2,SigE=sige2})
      : V.topEnv =
      {Env = unionEnv code (env1, env2),
       FunE = unionFunE code (funE1, funE2),
       SigE = unionSigE code (sige1, sige2)
      }
end
end

(* 以下は削除
  (* bind function *)
  fun bindId (env, symbol, idstate) =
      let
        val V.ENV{varE, tyE, strE} = env
        val varE =
            SymbolEnv.insertWithi
              (fn (symbol,_) =>
                  (EU.enqueueError (Symbol.symbolToLoc symbol,E.DuplicateIdInSpec("054",symbol))))
              (varE, symbol, idstate)
      in
        V.ENV {varE=varE, tyE=tyE, strE=strE}
      end
  (* indsert function *)
  fun insertId (env, symbol, idstate) =
      let
        val V.ENV{varE, tyE, strE} = env
        val varE =
            SymbolEnv.insertWithi
              (fn (symbol,_) =>
                  (EU.enqueueError (Symbol.symbolToLoc symbol,E.DuplicateIdInSpec("054",symbol))))
              (varE, symbol, idstate)
      in
        V.ENV {varE=varE, tyE=tyE, strE=strE}
      end
 (* check function *)
  fun checkId (V.ENV {varE, tyE, strE = V.STR envSymbolEnvMap}, longsymbol) =
      case longsymbol of 
        nil => raise bug "nil to checkId"
      | symbol :: nil => SymbolEnv.find(varE, symbol)
      | strsymbol :: path =>
        (case SymbolEnv.find(envSymbolEnvMap, strsymbol) of
           NONE => NONE
         | SOME {env,...} => checkId (env, path)
        )

  (* check function *)
  fun searchId env longsymbol : I.idstatus =
      case checkId(env, longsymbol) of
        NONE => raise LookupId
      | SOME idstatus => idstatus

  (* insert function *)
  fun reinsertId (V.ENV{varE, tyE, strE}, symbol, idstatus) =
      V.ENV
        {varE = SymbolEnv.insert(varE, symbol, idstatus),
         tyE = tyE,
         strE = strE
        }

  (* insert function *)
  fun reinsertIdLongsymbol
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, idstatus) : V.env =
      case path of
        nil => raise bug "nil to rebindTypLongid"
      | symbol::nil =>
        V.ENV
          {
           varE = SymbolEnv.insert(varE, symbol, idstatus),
           tyE = tyE,
           strE = strE
          }
      | strsymbol::path =>
        let
          val strEntry as {env,...} = 
              case SymbolEnv.find(envMap, strsymbol) of
                SOME strEntry => strEntry
              | NONE => raise bug "env not found in rebindIdLongsymbol"
          val newEnv = reinsertIdLongsymbol(env, path, idstatus)
        in
          V.ENV
            {
             varE = varE,
             tyE = tyE,
             strE = 
             V.STR (SymbolEnv.insert
                    (envMap, 
                     strsymbol,
                     strEntry # {env=newEnv}))
            }
        end
  (* find function *)
  exception LookupId
  fun lookupId env longsymbol : I.idstatus =
      case findId(env, longsymbol) of
        NONE => raise LookupId
      | SOME (sym, idstatus) => 
        (Analyzers.analyzeNameRef (longsymbol, (sym, idstatus));
         idstatus)


  (* insert function *)
  fun insertTstr (env, symbol, tstr) =
      let
        val V.ENV{varE, tyE, strE} = env
        val tyE =
            SymbolEnv.insertWithi
            (fn (symbol, _) =>
                (EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateTypInSpec("055", symbol))))
            (tyE, symbol, tstr)
      in
        V.ENV {tyE=tyE, varE=varE, strE=strE}
      end

  (* bind function *)
  fun bindTstr (env, symbol, tstr) =
      let
        val V.ENV{varE, tyE, strE} = env
        val _ = 
            case SymbolEnv.find(tyE, symbol) of
              NONE => ()
            | SOME _ =>
              EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateTypInSpec("055", symbol))
        val tyE = SymbolEnv.insert(tyE, symbol, tstr)
      in
        V.ENV {tyE=tyE, varE=varE, strE=strE}
      end

  (* insert function *)
  fun reinsertTstr (V.ENV{varE,tyE,strE}, symbol, tstr) =
      V.ENV
        {
         varE = varE,
         tyE = SymbolEnv.insert(tyE, symbol, tstr),
         strE = strE
        }

  (* insert function *)
  fun reinsertTstrLongsymbol
        (V.ENV{varE, tyE, strE = strE as V.STR envMap},
         path, tstr) =
      case path of
        nil => raise bug "nil to rebindTypLongid"
      | symbol::nil =>
        V.ENV
          {
           varE = varE,
           tyE = SymbolEnv.insert(tyE, symbol, tstr),
           strE = strE
          }
      | strsymbol::path =>
        let
          val strEntry as  {env,...} = 
              case SymbolEnv.find(envMap, strsymbol) of
                SOME strEntry =>strEntry
              | NONE => raise bug "strenv not found in rebindStrLongsymbol"
          val newEnv = reinsertTstrLongsymbol(env, path, tstr)
        in
          V.ENV
            {
             varE = varE,
             tyE = tyE,
             strE = 
             V.STR
               (SymbolEnv.insert
                  (envMap, strsymbol, strEntry # {env=newEnv}))
            }
        end

  (* bind function *)
  fun bindStr (V.ENV{varE, tyE, strE = V.STR envMap}, symbol, strEntry) =
      let
        val envMap =
            case SymbolEnv.findi(envMap, symbol) of
              NONE => SymbolEnv.insert(envMap, symbol, strEntry)
            | SOME (symbol, _) => 
              (EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateIdInSpec("050", symbol));
               envMap
              )
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR envMap}
      end
  (* insert function *)
  fun insertStr (V.ENV{varE, tyE, strE = V.STR envMap}, symbol, strEntry) =
      let
        val envMap =
            case SymbolEnv.findi(envMap, symbol) of
              NONE => SymbolEnv.insert(envMap, symbol, strEntry)
            | SOME (symbol, _) => 
              (EU.enqueueError (Symbol.symbolToLoc symbol, E.DuplicateIdInSpec("050", symbol));
               envMap
              )
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR envMap}
      end

  (* insert function
     この関数は要チェック。なぜ、env1を使うのか。
   *)
  fun updateStrE (V.STR envMap1, V.STR envMap2) = 
      let
        fun strEWithStrE ({env=env1, strKind=_, loc=_}, 
                          {env=env2, strKind, loc}) =
            {env=updateEnv(env1,env2), strKind=strKind, loc=loc}
      in
        V.STR (SymbolEnv.unionWith strEWithStrE (envMap1, envMap2))
      end

  (* insert function *)
  and updateEnv (V.ENV {varE=varE1, strE=strE1, tyE=tyE1},
                  V.ENV {varE=varE2, strE=strE2, tyE=tyE2}) =
      V.ENV {varE = varEWithVarE (varE1, varE2),
             strE = updateStrE (strE1, strE2),
             tyE = tyEWithTyE (tyE1,tyE2)
            }

  (* insert function *)
  fun reinsertSigE (SigE, symbol, env) =
      SymbolEnv.insert(SigE, symbol, env) 

*)
