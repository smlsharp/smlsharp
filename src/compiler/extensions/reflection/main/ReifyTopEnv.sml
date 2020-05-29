(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReifyTopEnv =
struct
local
  fun bug s = Bug.Bug ("ReiyTopEnv:" ^ s)
  structure I = IDCalc
  structure T = Types
  (* structure TB = TypesBasics *)
  structure V = NameEvalEnv
  structure VP = NameEvalEnvPrims
  structure UP = UserLevelPrimitive
  structure TCU = TypedCalcUtils
  structure TC = TypedCalc

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

  fun setVersion (sym, I.STEP n) = Symbol.setVersion (sym, n)
    | setVersion (sym, I.OTHER _) = sym
    | setVersion (sym, I.SELF) = sym

  fun --> (argTy, retTy) = T.FUNMty ([argTy], retTy)
  fun ** (ty1, ty2) = T.RECORDty (RecordLabel.tupleMap [ty1, ty2])
  infixr 4 -->
  infix 5 **

  open ReifiedTyData ReifyUtils 
in

  fun sname envList =
      {env = envList,
       tfunName = NameEvalUtils.staticTfunName,
       tyConName = NameEvalUtils.staticTyConName}

  fun reifyIdstatus envList loc symbol idstatus =
      case idstatus of
      I.IDVAR id => NONE
    | I.IDVAR_TYPED _ => NONE
    | I.IDEXVAR {exInfo=exInfo as {used, longsymbol, ty, version}, internalId = SOME id} =>
      let
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
        val TyTerm = String loc (prettyPrint idstatusWidth (T.formatTyForUser (sname envList) ty))
        val Name = String loc (Symbol.symbolToString symbol)
        val VarExp = Var {path = setVersion(longsymbol, version), ty = ty, id = id, opaque = false}
        val InstVarExp = TCU.groundInst VarExp
        val ReifyFun = InstVar {exVarInfo=UP.REIFY_exInfo_toReifiedTermPrint(), instTy = #ty InstVarExp}
        val ReifiedTerm = Apply loc ReifyFun InstVarExp
                          handle exn as TypeMismatch => raise exn
        val IdstatusFun = MonoVar (UP.REIFY_exInfo_mkEXVarIdstatus()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, ReifiedTerm, TyTerm]
                          handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDEXVAR {exInfo={used, longsymbol, ty, version}, internalId = NONE,...} =>
      let
        val accessLongsymbol = setVersion(longsymbol, version)
        val Name = String loc (Symbol.symbolToString symbol)
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
        val TyTerm = String loc (prettyPrint idstatusWidth (T.formatTyForUser (sname envList) ty))
        val VarExp = MonoVar {path=accessLongsymbol, ty=ty}
        val InstVarExp = TCU.groundInst VarExp
        val ReifyFun = InstVar {exVarInfo=UP.REIFY_exInfo_toReifiedTermPrint(), instTy = #ty InstVarExp}
        val Term = Apply loc ReifyFun InstVarExp
            handle exn as TypeMismatch => raise exn
        val IdstatusFun = MonoVar (UP.REIFY_exInfo_mkEXVarIdstatus()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, Term, TyTerm]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDEXVAR_TOBETYPED _ => NONE
    | I.IDBUILTINVAR {primitive, ty} => 
      let
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
        val TyTerm = String loc (prettyPrint idstatusWidth (T.formatTyForUser (sname envList) ty))
        val Name = String loc (Symbol.symbolToString symbol)
        val Term = Con loc (UP.REIFY_conInfo_BUILTIN()) NONE
        val IdstatusFun = MonoVar (UP.REIFY_exInfo_mkEXVarIdstatus()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, Term, TyTerm]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDCON _ => NONE
    | I.IDEXN _ => NONE
    | I.IDEXNREP _ => NONE
    | I.IDEXEXN {used, longsymbol, ty, version} =>
      let
        val exnArgTy =
            case ty of
              I.TYFUNM ([argTy], _) => SOME argTy
            | _ => NONE
        val ArgTyTerm =
            case exnArgTy of
              NONE => Option loc StringTy NONE
            | SOME argTy =>
              Option loc StringTy
                (SOME (String loc (prettyPrint idstatusWidth
                   (T.formatTyForUser
                      (sname envList)
                      (EvalIty.evalIty EvalIty.emptyContext argTy)))))
        val Name = String loc (Symbol.symbolToString symbol)
        val IdstatusFun = MonoVar (UP.REIFY_exInfo_mkEXEXNIdstatus()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, ArgTyTerm]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDEXEXNREP {used, longsymbol, ty, version} =>
      let
        val Path = String loc (Symbol.longsymbolToString longsymbol)
        val Name = String loc (Symbol.symbolToString symbol)
        val IdstatusFun = MonoVar (UP.REIFY_exInfo_mkEXEXNREPIdstatus()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, Path]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDOPRIM _ => NONE
    | I.IDSPECVAR _ => NONE
    | I.IDSPECEXN _ => NONE
    | I.IDSPECCON _ => NONE

  fun reifyTstr envList loc  (symbol, tstr) =
      let
        val name = Symbol.symbolToString symbol
        val name = SmlppgUtil.makeToken name
        val tyVal = 
            case tstr of
              V.TSTR tfun => prettyPrint tstrWidth (I.print_tfun (sname envList, nil, name) tfun)
            | V.TSTR_DTY {tfun, varE, formals, conSpec} => 
              prettyPrint tstrWidth (I.print_tfun (sname envList, SmlppgUtil.makeToken "DTY",name) tfun)
      in
        Pair loc (String loc "")  (String loc tyVal)
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


  fun reifyEnv envList loc env = 
      let
        val env = NormalizeTy.reduceEnv env
        val V.ENV {varE, tyE, strE=V.STR strE} = env

        (* tyE *)
        val tyE = map (reifyTstr envList loc) 
                      (ListSorter.sort 
                         (fn ((s1, _), (s2, _)) => Symbol.compare(s1,s2))
                         (SymbolEnv.listItemsi tyE))
        val TyE = List loc (StringTy ** StringTy) tyE

        (* strE *)
        val strE =
            map (fn (name, {env, strKind}) => 
                    (Pair 
                       loc
                       (String loc (Symbol.symbolToString name))
                       (reifyEnv (env::envList) loc env)))
                (ListSorter.sort 
                   (fn ((s1, _), (s2, _)) => Symbol.compare(s1,s2))
                   (SymbolEnv.listItemsi strE))
        val StrE = List loc (StringTy ** EnvTy()) strE

        (* varE *)
        val varE = 
            (ListSorter.sort 
               (fn ((s1, _), (s2, _)) => Symbol.compare(s1,s2))
               (SymbolEnv.listItemsi varE))
        val varE =
            foldr
            (fn ((symbol, idstatus), varE) =>
                let
                  val name = Symbol.symbolToString symbol
                  val termIdstatusOpt = reifyIdstatus envList loc symbol idstatus
                in
                  case termIdstatusOpt of
                    NONE => varE
                  | SOME term => term::varE
                end
            )
            nil
            varE
        val VarE = List loc (IdstatusTy()) varE
      in
        ApplyList
          loc 
          (MonoVar (UP.REIFY_exInfo_mkENVenv()))
          [VarE, TyE, StrE]
        handle exn as TypeMismatch => raise exn
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

  fun reifySigE envList loc (sigE:V.sigE) =
      let
        val sigE = SymbolEnv.map (fn env => filterEnv env) sigE
        val sigE = (ListSorter.sort 
                      (fn ((s1, _), (s2, _)) => Symbol.compare(s1,s2))
                      (SymbolEnv.listItemsi sigE))
        val sigE = prettyPrint sigWidth (V.printTy_sigEList (sname envList,nil,nil) sigE)
      in
        String loc sigE
      end

  fun reifyFunEntry envList loc (symbol, funEEntry) =
      let
        (* 2012-8-7 ohori ad-hoc fix for bug 232_functorSigNewLines.sml *)
        val funEEntry = filterSpecCon funEEntry
        val name = "functor " ^ (Symbol.symbolToString symbol)
        val funE = name ^ (prettyPrint tstrWidth (V.printTy_funEEntry (sname envList,nil,nil) funEEntry))
      in
        String loc funE
      end

  fun reifyFunE envList loc (funE:V.funE) =
      let
        val symbolFunEntryList = 
                (ListSorter.sort 
                   (fn ((s1, _), (s2, _)) => Symbol.compare(s1,s2))
                   (SymbolEnv.listItemsi funE))
        val termList = map (reifyFunEntry envList loc) symbolFunEntryList
      in
        List loc StringTy termList
      end

  fun internalBind Exp =  
      let
        val varInfo = newVar (#ty Exp)
      in
        (Var varInfo, [Val Loc.noloc varInfo Exp])
      end

  fun externalBind loc (string, Exp) Env version = 
      let
        val ty = #ty Exp
        val symbol = Symbol.mkSymbol string loc
        val longsymbol = [symbol]
        val externalInfo = {path = setVersion(longsymbol, version), ty = ty}
        val idstatus = 
            I.IDEXVAR {exInfo = {used = ref false, longsymbol = longsymbol, ty = I.INFERREDTY ty, version = version},
                       internalId = NONE} 
        val Env = VP.rebindId (Env, symbol, idstatus)
      in
        {env = Env,
         decls = [TC.TPEXPORTVAR {var = externalInfo, exp = #exp Exp}]
        }
      end

  fun reifyTopEnv (referenceTopEnv as {Env=ReferenceEnv, ...})
                  (topEnv as {Env=StaticEnv, SigE=StaticSigE, FunE=StaticFunE}) version =
      let
        val Env = reifyEnv [ReferenceEnv]  Loc.noloc StaticEnv
        val SigE = reifySigE [ReferenceEnv] Loc.noloc StaticSigE
        val FunE = reifyFunE [ReferenceEnv] Loc.noloc StaticFunE
        val TopEnvExp = 
            ApplyList 
              Loc.noloc 
              (MonoVar (UP.REIFY_exInfo_mkTopEnv()))
              [Env, FunE, SigE]
            handle exn as TypeMismatch => raise exn
      in
        TopEnvExp
      end

  fun printTopEnv Exp =
      let
        val PrintExp =
            Apply
              Loc.noloc
              (MonoVar (UP.REIFY_exInfo_printTopEnv()))
              Exp
            handle exn as TypeMismatch => raise exn
        val (_, decls) = internalBind PrintExp
      in
        decls
      end

  fun topEnvBind {sessionTopEnv, requireTopEnv} version =
      let
        val referenceEnv = VP.topEnvWithTopEnv (requireTopEnv, sessionTopEnv)
        val sessionEnvName = "sessionEnv"
        val sessionEnvExp = reifyTopEnv referenceEnv sessionTopEnv version
        val (varSessionEnv, decls1) = internalBind sessionEnvExp
        val decls2 = printTopEnv varSessionEnv
        val {env, decls = decls3} = 
            externalBind Loc.noloc (sessionEnvName, varSessionEnv) (#Env sessionTopEnv) version
(*
        val currentEnvName = "_currentEnv"
        val currentEnv = NameEvalEnv.topEnvWithTopEnv(requireTopEnv, sessionTopEnv)
        val currentEnvExp = reifyTopEnv referenceEnv currentEnv version
        val (varCurrentEnv, decls4) = internalBind currentEnvExp
        val {env = _, decls = decls5} = 
            externalBind Loc.noloc (currentEnvName, varCurrentEnv) env version
*)
        val topEnv = {SigE = #SigE sessionTopEnv, FunE = #FunE sessionTopEnv, Env = env}
      in
        {env = topEnv,
         decls = decls1 @ decls2 @ decls3 
(*
                 @ decls4 @ decls5
*)
        }
      end
      handle UserLevelPrimitive.IDNotFound _ =>
        (* FIXME: If user does not _require "ReifiedTerm.ppg.smi",
         * skip this phase. *)
        {env = sessionTopEnv, decls = nil}
(*
  val topEnvToReifiedTopEnv = TopEnvToReifiedTopEnv.topEnvToReifiedTopEnv
*)
end
end
