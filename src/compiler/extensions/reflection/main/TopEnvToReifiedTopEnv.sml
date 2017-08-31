(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure TopEnvToReifiedTopEnv =
struct
local
  fun bug s = Bug.Bug ("ReiyTopEnv:" ^ s)
  structure I = IDCalc
  structure T = Types
  structure V = NameEvalEnv
  structure R = ReifiedTerm


  fun eqTyCon ({id=id1,...}:T.tyCon, {id=id2,...}:T.tyCon) =
      TypID.eq(id1,id2)

  val idstatusWidth = 60
  val tstrWidth = 70
  val sigWidth = 75

  fun prettyPrint width expressions =
      let
        val ppgenParameter = [SMLFormat.Columns width]
      in
        SMLFormat.prettyPrint ppgenParameter expressions
      end
in

  fun reifyIdstatus symbol idstatus =
      case idstatus of
      I.IDVAR id => NONE
    | I.IDVAR_TYPED _ => NONE
    | I.IDEXVAR {exInfo=exInfo as {used, longsymbol, ty, version}, internalId = SOME id} =>
      let
        val tyString = prettyPrint idstatusWidth (I.print_ty (nil,nil,nil,nil) ty)
        val name = Symbol.symbolToString symbol
      in
        SOME (R.EXVARTY {name=name, ty = tyString})
      end
    | I.IDEXVAR {exInfo={used, longsymbol, ty, version}, internalId = NONE,...} =>
      let
        val name = Symbol.symbolToString symbol
        val tyTerm = prettyPrint idstatusWidth (I.print_ty (nil, nil, nil,nil) ty)
      in
        SOME(R.EXVARTY {name=name, ty = tyTerm})
      end
    | I.IDEXVAR_TOBETYPED _ => NONE
    | I.IDBUILTINVAR {primitive, ty} => 
      let
        val tyTerm = prettyPrint idstatusWidth (I.print_ty (nil, nil, nil,nil) ty)
        val name = Symbol.symbolToString symbol
      in
        SOME(R.EXVARTY {name=name, ty = tyTerm})
      end
    | I.IDCON _ => NONE
    | I.IDEXN _ => NONE
    | I.IDEXNREP _ => NONE
    | I.IDEXEXN {used, longsymbol, ty, version} =>
      let
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
        val exnArgTy = 
            case ty of 
              T.FUNMty([argTy], _) => SOME argTy
            | _ => NONE
        val tyOpt =
            case exnArgTy of 
              NONE => NONE
            | SOME argTy => SOME (prettyPrint idstatusWidth (T.format_ty nil argTy))
        val name = Symbol.symbolToString symbol
      in
        SOME (R.EXEXN {name = name, ty = tyOpt})
      end
    | I.IDEXEXNREP {used, longsymbol, ty, version} =>
      let
        val path = Symbol.longsymbolToString longsymbol
        val name = Symbol.symbolToString symbol
      in
        SOME (R.EXEXNREP {name = name, path = path})
      end
    | I.IDOPRIM _ => NONE
    | I.IDSPECVAR _ => NONE
    | I.IDSPECEXN _ => NONE
    | I.IDSPECCON _ => NONE

  fun reifyTstr (symbol, tstr) =
      let
        val name = Symbol.symbolToString symbol
        val name = SmlppgUtil.makeToken name
        val tyVal = 
            case tstr of
              V.TSTR tfun => prettyPrint tstrWidth (I.print_tfun (nil,nil,nil,name) tfun)
            | V.TSTR_DTY {tfun, varE, formals, conSpec} => 
              prettyPrint tstrWidth (I.print_tfun (nil,nil,SmlppgUtil.makeToken "DTY",name) tfun)
      in
        ("", tyVal)
      end

  fun filterSpecConVarE varE =
      SymbolEnv.foldri
        (fn (name, I.IDSPECCON _, varE) => varE
          | (name, idstatus, varE) => SymbolEnv.insert(varE, name, idstatus))
      SymbolEnv.empty
      varE

  fun filterSpecConEnv (V.ENV {varE, tyE, strE}) =
      let
        val varE = filterSpecConVarE varE
      in
        V.ENV{varE=varE, tyE=tyE, strE=strE}
      end

  fun filterSpecCon 
        {id,
         version,
         argSigEnv,
         argStrEntry,
         argStrName,
         dummyIdfunArgTy,
         polyArgTys,
         typidSet,
         exnIdSet,
         bodyEnv,
         bodyVarExp
        } =
        {id = id,
         version = version,
         argSigEnv = filterSpecConEnv argSigEnv,
         argStrEntry = argStrEntry,
         argStrName = argStrName,
         dummyIdfunArgTy = dummyIdfunArgTy,
         polyArgTys = polyArgTys,
         typidSet = typidSet,
         exnIdSet = exnIdSet,
         bodyEnv = bodyEnv,
         bodyVarExp = bodyVarExp
        }


  fun envToReifiedEnv env = 
      let
        val env = NormalizeTy.reduceEnv env
        val V.ENV {varE, tyE, strE=V.STR strE} = env

        (* tyE *)
        val tyE = map reifyTstr (SymbolEnv.listItemsi tyE)

        (* strE *)
        val strE =
            map (fn (name, {env, strKind}) => 
                       (Symbol.symbolToString name,
                        envToReifiedEnv env))
                (SymbolEnv.listItemsi strE)

        (* varE *)
        val varE =
            SymbolEnv.foldri
            (fn (symbol, idstatus, varE) =>
                let
                  val name = Symbol.symbolToString symbol
                  val termIdstatusOpt = reifyIdstatus symbol idstatus
                in
                  case termIdstatusOpt of
                    NONE => varE
                  | SOME term => term::varE
                end
            )
            nil
            varE
      in
        R.ENV {varE = varE, tyE = tyE, strE = strE}
      end

  fun printableIdstatus idstatus =
      case idstatus of
        I.IDVAR _ => false
      | I.IDVAR_TYPED  _ => false
      | I.IDEXVAR  _ => false
      | I.IDEXVAR_TOBETYPED  _ => false
      | I.IDBUILTINVAR  _ => false
      | I.IDCON  _ => false
      | I.IDEXN  _ => false
      | I.IDEXNREP  _ => false
      | I.IDEXEXN  _ => false
      | I.IDEXEXNREP  _ => false
      | I.IDOPRIM  _ => false
      | I.IDSPECVAR  _ => true
      | I.IDSPECEXN  _ => true
      | I.IDSPECCON _ => false

  fun filterVarE varE = 
      SymbolEnv.foldri 
      (fn (name, idstatus, varE) => 
          if printableIdstatus idstatus then SymbolEnv.insert(varE, name, idstatus)
          else varE
      )
      SymbolEnv.empty
      varE

  fun filterEnv (V.ENV {varE, tyE, strE=V.STR strE}) =
      let
        val varE = filterVarE varE
        val strE = SymbolEnv.map
                     (fn {env, strKind} => {env=filterEnv env, strKind=strKind}) strE
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR strE}
      end

  fun sigEToTeifeidSigE (sigE:V.sigE) =
      let
        val sigE = SymbolEnv.map (fn env => filterEnv env) sigE
        val sigE = SymbolEnv.listItemsi sigE
        val sigE = prettyPrint sigWidth (V.printTy_sigEList sigE)
      in
        sigE
      end

  fun reifyFunEntry (symbol, funEEntry) =
      let
        (* 2012-8-7 ohori ad-hoc fix for bug 232_functorSigNewLines.sml *)
        val funEEntry = filterSpecCon funEEntry
        val name = "functor " ^ (Symbol.symbolToString symbol)
        val funE = name ^ (prettyPrint tstrWidth (V.printTy_funEEntry funEEntry))
      in
        funE
      end

  fun funEToReifiedFunE (funE:V.funE) =
      let
        val symbolFunEntryList = SymbolEnv.listItemsi funE
        val termList = map reifyFunEntry symbolFunEntryList
      in
        termList
      end

  fun topEnvToReifiedTopEnv (topEnv as {Env, SigE, FunE}) =
      let
        val Env = envToReifiedEnv Env
        val SigE = sigEToTeifeidSigE SigE
        val FunE = funEToReifiedFunE FunE
      in
        {Env = Env, SigE = SigE, FunE = FunE}
      end
end
end
