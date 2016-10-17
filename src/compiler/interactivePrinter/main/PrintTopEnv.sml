(**
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 *
 * Adopted from ReifiedTerm.ppg and Reify.sml
 *)
structure PrintTopEnv =
struct
local
  structure C = Control
  structure I = IDCalc
  structure T = Types
  structure ITy = EvalIty
  structure V = NameEvalEnv
  structure R = ReifiedTerm

  val idstatusWidth = 60
  val tstrWidth = 70
  val sigWidth = 75

  (* this is a copy from Control
   *)
  fun prettyPrint width expressions =
      let
        val ppgenParameter = [SMLFormat.Columns width]
      in
        SMLFormat.prettyPrint ppgenParameter expressions
      end
in

  (* copied from the orginal main/main/PrintBind.sml *)
  fun externSymbol {longsymbol, version} =
      let
        (* InferTypes2 *)
        val lsym = Symbol.setVersion (longsymbol, version)
        (* MacthCompile *)
        val path = Symbol.longsymbolToLongid lsym
        (* ClosureConversion *)
        val exid = ExternSymbol.touch path
      in
        (* LLVMGen *)
        "_SMLZ" ^ ExternSymbol.toString exid
      end

  fun reifyIdstatus (name, idstatus) =
      case idstatus of
      I.IDEXVAR {exInfo=exInfo as {longsymbol, ty=ity, version}, used, internalId} =>
      let
        val tyTerm = prettyPrint idstatusWidth (I.print_ty (nil,nil) ity)
        val ty = ITy.evalIty ITy.emptyContext ity
        val lib = DynamicLink.default ()
        val instantiatedLongsymbol = Reify.instantiatedLongsymbol longsymbol
        val (ty, ptr) = 
            if Reify.needInstantiattion ty then 
              (TypedCalcUtils.groundInstTy ty,
               DynamicLink.dlsym' (lib, externSymbol {longsymbol = instantiatedLongsymbol, version = version}))
              handle SMLSharp_Runtime.SysErr _ =>
                     (ty, DynamicLink.dlsym' (lib, externSymbol {longsymbol = longsymbol, version = version}))
             else
               (ty, DynamicLink.dlsym' (lib, externSymbol {longsymbol = longsymbol, version = version}))
        val reifiedTerm = DynamicPrinter.dynamicToReifiedTerm (Dynamic.load (ptr, ty))
      in
        SOME (R.EXVAR{name=name, term=reifiedTerm, ty=tyTerm})
      end
    | I.IDBUILTINVAR {primitive, ty} => 
      let
        val tyTerm = prettyPrint idstatusWidth (I.print_ty (nil,nil) ty)
        val reifiedTerm = R.BUILTINRep
      in
        SOME (R.EXVAR{name=name, term=reifiedTerm, ty=tyTerm})
      end
    | I.IDEXEXN ({longsymbol, ty, version}, used) =>
      let
        val ty = ITy.evalIty ITy.emptyContext ty
        val exnArgTy = 
            case ty of 
              T.FUNMty([argTy], _) => SOME argTy
            | _ => NONE
        val argTyTerm = 
            Option.map (fn argTy => prettyPrint idstatusWidth (T.format_ty nil argTy)) exnArgTy
      in
        SOME (R.EXEXN {name=name, ty=argTyTerm})
      end
    | I.IDEXEXNREP ({longsymbol, ty, version}, used) =>
      let
        val ty = ITy.evalIty ITy.emptyContext ty
        val pathTerm = Symbol.longsymbolToString longsymbol
      in
        SOME (R.EXEXNREP {name=name, path = pathTerm})
      end
    | I.IDVAR varId => NONE
    | I.IDVAR_TYPED _ => NONE
    | I.IDEXVAR_TOBETYPED _ => NONE
    | I.IDCON _ => NONE
    | I.IDEXN _ => NONE
    | I.IDEXNREP _ => NONE
    | I.IDOPRIM _ => NONE
    | I.IDSPECVAR _ => NONE
    | I.IDSPECEXN _ => NONE
    | I.IDSPECCON _ => NONE

  fun reifyTstr  (symbol, tstr) =
      let
        val name = Symbol.symbolToString symbol
        val name = SmlppgUtil.makeToken name
        val tyVal = 
            case tstr of
              V.TSTR tfun => prettyPrint tstrWidth (I.print_tfun (nil,name) tfun)
            | V.TSTR_DTY {tfun, varE, formals, conSpec} => 
              prettyPrint tstrWidth (I.print_tfun (SmlppgUtil.makeToken "DTY",name) tfun)
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
         used,
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
         used = used,
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

  fun reifyFunEntry (symbol, funEEntry) =
      let
        (* 2012-8-7 ohori ad-hoc fix for bug 232_functorSigNewLines.sml
         *)
        val funEEntry = filterSpecCon funEEntry
        val name = "functor " ^ (Symbol.symbolToString symbol)
        val funE = name ^ (prettyPrint tstrWidth (V.printTy_funEEntry funEEntry))
      in
        funE
      end

  fun reifyEnv env = 
      let
        val env = NormalizeTy.reduceEnv env
        val V.ENV {varE, tyE, strE=V.STR strE} = env

        (* tyE *)
        val tyE = map reifyTstr (SymbolEnv.listItemsi tyE)

        (* strE *)
        val strE =
            map (fn (name, {env, strKind}) => 
                    (Symbol.symbolToString name, reifyEnv env))
                (SymbolEnv.listItemsi strE)

        (* varE *)
        val varE =
            SymbolEnv.foldri
            (fn (name, idstatus, varE) =>
                let
                  val name = Symbol.symbolToString name
                  val termIdstatusOpt = reifyIdstatus (name, idstatus)
                in
                  case termIdstatusOpt of
                    NONE => varE
                  | SOME term => term::varE
                end
            )
            nil
            varE
      in
        R.ENV{varE=varE, tyE=tyE, strE=strE}
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

  fun reifySigE (sigE:V.sigE) =
      let
        val sigE = SymbolEnv.map (fn env => filterEnv env) sigE
        val sigE = SymbolEnv.listItemsi sigE
      in
        prettyPrint sigWidth (V.printTy_sigEList sigE)
      end

  fun reifyFunE (funE:V.funE) =
      let
        val symbolFunEntryList = SymbolEnv.listItemsi funE
        val termList = map reifyFunEntry symbolFunEntryList
      in
        termList
      end

  fun reifyTopEnv (topEnv:V.topEnv as {Env, SigE, FunE}) =
      let
        val env = reifyEnv Env
        val sigE = reifySigE SigE
        val funE = reifyFunE FunE
      in
        {Env=env, SigE=sigE, FunE=funE}
      end

  fun printTopEnv (topEnv:V.topEnv) = ReifiedTerm.printTopEnv (reifyTopEnv topEnv)

end
end
