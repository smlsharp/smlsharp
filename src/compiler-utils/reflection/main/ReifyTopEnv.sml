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
  structure TB = TypesBasics
  structure V = NameEvalEnv
  structure UP = UserLevelPrimitive
  structure RCU = RecordCalcUtils

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

  fun --> (argTy, retTy) = T.FUNMty ([argTy], retTy)
  fun ** (ty1, ty2) = T.RECORDty (RecordLabel.tupleMap [ty1, ty2])
  infixr 4 -->
  infix 5 **

  open ReifiedTyData ReifyUtils 
in

  fun reifyIdstatus loc symbol idstatus =
      case idstatus of
      I.IDVAR id => NONE
    | I.IDVAR_TYPED _ => NONE
    | I.IDEXVAR {exInfo=exInfo as {used, longsymbol, ty, version}, internalId = SOME id} =>
      let
        val TyTerm = String loc (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
(*
        val Name = String loc (Symbol.longsymbolToString longsymbol)
*)
        val Name = String loc (Symbol.symbolToString symbol)
        val VarExp = Var {path = Symbol.setVersion(longsymbol, version), ty = ty, id = id}
        val InstVarExp = RCU.groundInst VarExp
        val ReifyFun = InstVar {exVarInfo=UP.REIFY_toReifiedTerm_exInfo(), instTy = #ty InstVarExp}
        val ReifiedTerm = Apply loc ReifyFun InstVarExp
                          handle exn as TypeMismatch => raise exn
        val IdstatusFun = MonoVar (UP.REIFY_mkEXVarIdstatus_exInfo()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, ReifiedTerm, TyTerm]
                          handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDEXVAR {exInfo={used, longsymbol, ty, version}, internalId = NONE,...} =>
      let
        val accessLongsymbol = Symbol.setVersion(longsymbol, version)
        val Name = String loc (Symbol.symbolToString symbol)
        val TyTerm = String loc (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
        val VarExp = MonoVar {path=accessLongsymbol, ty=ty}
        val InstVarExp = RCU.groundInst VarExp
        val ReifyFun = InstVar {exVarInfo=UP.REIFY_toReifiedTerm_exInfo(), instTy = #ty InstVarExp}
        val Term = Apply loc ReifyFun InstVarExp
            handle exn as TypeMismatch => raise exn
        val IdstatusFun = MonoVar (UP.REIFY_mkEXVarIdstatus_exInfo()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, Term, TyTerm]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDEXVAR_TOBETYPED _ => NONE
    | I.IDBUILTINVAR {primitive, ty} => 
      let
        val TyTerm = String loc (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val Name = String loc (Symbol.symbolToString symbol)
        val Term = Con loc (UP.REIFY_BUILTIN_conInfo()) NONE
        val IdstatusFun = MonoVar (UP.REIFY_mkEXVarIdstatus_exInfo()) 
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
        val ty = EvalIty.evalIty EvalIty.emptyContext ty
        val exnArgTy = 
            case ty of 
              T.FUNMty([argTy], _) => SOME argTy
            | _ => NONE
        val ArgTyTerm =
            case exnArgTy of 
              NONE => Option loc StringTy NONE
            | SOME argTy => 
              Option loc StringTy (SOME (String loc (prettyPrint idstatusWidth (T.format_ty nil argTy))))
        val Name = String loc (Symbol.symbolToString symbol)
        val IdstatusFun = MonoVar (UP.REIFY_mkEXEXNIdstatus_exInfo()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, ArgTyTerm]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDEXEXNREP {used, longsymbol, ty, version} =>
      let
        val Path = String loc (Symbol.longsymbolToString longsymbol)
        val Name = String loc (Symbol.symbolToString symbol)
        val IdstatusFun = MonoVar (UP.REIFY_mkEXEXNREPIdstatus_exInfo()) 
        val ReifiedTerm = ApplyList loc IdstatusFun [Name, Path]
            handle exn as TypeMismatch => raise exn
      in
        SOME ReifiedTerm
      end
    | I.IDOPRIM _ => NONE
    | I.IDSPECVAR _ => NONE
    | I.IDSPECEXN _ => NONE
    | I.IDSPECCON _ => NONE

  fun reifyTstr loc  (symbol, tstr) =
      let
        val name = Symbol.symbolToString symbol
        val name = SmlppgUtil.makeToken name
        val tyVal = 
            case tstr of
              V.TSTR tfun => prettyPrint tstrWidth (I.print_tfun (nil,name) tfun)
            | V.TSTR_DTY {tfun, varE, formals, conSpec} => 
              prettyPrint tstrWidth (I.print_tfun (SmlppgUtil.makeToken "DTY",name) tfun)
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


  fun reifyEnv loc env = 
      let
        val env = NormalizeTy.reduceEnv env
        val V.ENV {varE, tyE, strE=V.STR strE} = env

        (* tyE *)
        val tyE = map (reifyTstr loc) (SymbolEnv.listItemsi tyE)
        val TyE = List loc (StringTy ** StringTy) tyE

        (* strE *)
        val strE =
            map (fn (name, {env, strKind}) => 
                    (Pair 
                       loc
                       (String loc (Symbol.symbolToString name))
                       (reifyEnv loc env)))
                (SymbolEnv.listItemsi strE)
        val StrE = List loc (StringTy ** EnvTy()) strE

        (* varE *)
        val varE =
            SymbolEnv.foldri
            (fn (symbol, idstatus, varE) =>
                let
                  val name = Symbol.symbolToString symbol
                  val termIdstatusOpt = reifyIdstatus loc symbol idstatus
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
          (MonoVar (UP.REIFY_mkENVenv_exInfo()))
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

  fun reifySigE loc (sigE:V.sigE) =
      let
        val sigE = SymbolEnv.map (fn env => filterEnv env) sigE
        val sigE = SymbolEnv.listItemsi sigE
        val sigE = prettyPrint sigWidth (V.printTy_sigEList sigE)
      in
        String loc sigE
      end

  fun reifyFunEntry loc (symbol, funEEntry) =
      let
        (* 2012-8-7 ohori ad-hoc fix for bug 232_functorSigNewLines.sml *)
        val funEEntry = filterSpecCon funEEntry
        val name = "functor " ^ (Symbol.symbolToString symbol)
        val funE = name ^ (prettyPrint tstrWidth (V.printTy_funEEntry funEEntry))
      in
        String loc funE
      end

  fun reifyFunE loc (funE:V.funE) =
      let
        val symbolFunEntryList = SymbolEnv.listItemsi funE
        val termList = map (reifyFunEntry loc) symbolFunEntryList
      in
        List loc StringTy termList
      end

  fun reifyTopEnv (topEnv as {Env, SigE, FunE}) =
      let
        val Env = reifyEnv Loc.noloc Env
        val SigE = reifySigE Loc.noloc SigE
        val FunE = reifyFunE Loc.noloc FunE
        val TopEnvExp = 
            ApplyList 
              Loc.noloc 
              (MonoVar (UP.REIFY_mkTopEnv_exInfo()))
              [Env, FunE, SigE]
            handle exn as TypeMismatch => raise exn
        val PrintExp =
            Apply
              Loc.noloc
              (MonoVar (UP.REIFY_printTopEnv_exInfo()))
              TopEnvExp
            handle exn as TypeMismatch => raise exn
        val varInfo = newVar (#ty PrintExp)
      in
        [Val Loc.noloc varInfo PrintExp]
      end
end
end
