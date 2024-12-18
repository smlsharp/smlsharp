(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : 001 *)
structure NameEval =
struct
local
  structure I = IDCalc
  structure BT = BuiltinTypes
  structure Ty = EvalTy
  (* structure ITy = EvalIty *)
  structure V = NameEvalEnv
  structure VP = NameEvalEnvPrims
  structure L = SetLiftedTys
  structure S = Subst
  structure P = PatternCalc
  structure PI = PatternCalcInterface
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = AbsynConst
  structure N = NormalizeTy
  structure Sig = EvalSig
  structure EI = NameEvalInterface
  structure CP = CheckProvide
  structure FU = FunctorUtils
  structure SC = SigCheck
  structure T = Types
  structure RL = RenameLongsymbol
  type renameEnv = I.tfun TypID.Map.map
  val emptyRenameEnv =  TypID.Map.empty : renameEnv

  fun mkSymbol s = Symbol.mkSymbol s Loc.noloc
  fun mkLongsymbol s = Symbol.mkLongsymbol s Loc.noloc


  fun printStrKind strkind =
      case strkind of
      V.SIGENV id => print ("SIGENV" ^ SignatureID.toString id ^ "\n")
    | V.STRENV id => print ("STRENV" ^ StructureID.toString id ^ "\n")
    | V.FUNAPP  {id,...} => print ("FUNAPP" ^ StructureID.toString id ^ "\n")
    | V.FUNARG  id => print ("FUNARG" ^ StructureID.toString id ^ "\n")

  fun bug s = Bug.Bug ("NameEval: " ^ s)

  (* versionの管理を整理する必要がある．とりあえず，TypeInfからコピー *)
  fun setVersion (longsymbol, I.STEP x) = Symbol.setVersion (longsymbol, x)
    | setVersion (longsymbol, I.OTHER _) = longsymbol
    | setVersion (longsymbol, I.SELF) = longsymbol


  fun addExnExSet (externExnSet: I.exInfo LongsymbolEnv.map, 
                   exInfo as {used, longsymbol, ty, version}:I.exInfo) =
      let
        val longsymbol = setVersion(longsymbol, version)
      in
        ((*V.exnConAdd (V.EXEXN exInfo);*)
         LongsymbolEnv.insert(externExnSet, longsymbol, exInfo)
        )
      end

  fun addVarExSet (externVarSet: I.exInfo LongsymbolEnv.map, 
                   exInfo as {used, longsymbol, ty, version}:I.exInfo) =
      let
        val longsymbol = setVersion(longsymbol, version)
      in
        LongsymbolEnv.insert(externVarSet, longsymbol, exInfo)
      end

  fun exSetMember (externExnSet:I.exInfo LongsymbolEnv.map, 
                   {used, longsymbol, ty, version}:I.exInfo) =
      let
        val longsymbol = setVersion(longsymbol, version)
      in
        LongsymbolEnv.inDomain(externExnSet, longsymbol)
      end

  val emptyExternVarSet = LongsymbolEnv.empty : I.exInfo LongsymbolEnv.map

  val DUMMYIDFUN = mkLongsymbol ["id"]

 (* This is to avoid name conflict in functor names and variable names *)
  val FUNCTORPREFIX = mkSymbol "_"

  exception Arity 
  exception Eq
  exception Type 
  exception Type1
  exception Type2
  exception Type3
  exception Undef 
  exception Rigid
  exception ProcessShare
  exception FunIDUndefind

  type path = Symbol.longsymbol
  val nilPath = nil : path

  fun generateFunVar path funIdPat =
    let
      fun stripTy pat =
          case pat of
            P.PLPATTYPED(pat, ty, loc) =>
            let
              val (pat, tyList) = stripTy pat
            in
              (pat, ty::tyList)
            end
          | _ => (pat, nil)
      val (idPat, tyList) = stripTy funIdPat
      val {funVarInfo, funSymbol, tyList} =
          case idPat of
            P.PLPATID [funSymbol] =>
              let
                val longsymbol = Symbol.prefixPath(path, funSymbol)
              in
                {funVarInfo= {longsymbol=longsymbol, id=VarID.generate()},
                 funSymbol=funSymbol,
                 tyList=tyList
                }
              end
          | P.PLPATID longsymbol =>
              (EU.enqueueError
                 (Symbol.longsymbolToLoc longsymbol,
                  E.IlleagalFunID ("010",{pat = funIdPat}));
               let
                 val longsymbol = Symbol.concatPath (path, longsymbol)
               in
                 {funVarInfo = {longsymbol=longsymbol, id = VarID.generate()},
                  funSymbol = mkSymbol "_",
                  tyList=nil
                 }
               end
              )
          | _ => 
               let
                 val longsymbol = path@[mkSymbol "_"]
               in
                 (EU.enqueueError
                    (Symbol.longsymbolToLoc longsymbol,
                     E.IlleagalFunID ("010",{pat = funIdPat}));
                  {funVarInfo = {longsymbol=longsymbol, id = VarID.generate()},
                   funSymbol = mkSymbol "_",
                   tyList=nil
                  }
                 )
               end
    in
      {symbol = funSymbol, varInfo = funVarInfo, tyList=tyList}
    end

  (* type function variable substitution *)
  type tfvSubst = (I.tfunkind ref) TfvMap.map

  fun evalPlpat (defRange, context) path (tvarEnv:Ty.tvarEnv) (env:V.env) plpat : V.env * I.icpat =
      let
        val evalPat = evalPlpat (defRange, context) path tvarEnv env
        fun evalTy' ty = Ty.evalTyWithFlex tvarEnv env ty
      in
        case plpat of
          P.PLPATWILD loc => (V.emptyEnv, I.ICPATWILD loc)
        | P.PLPATID refLongsymbol =>
          (case refLongsymbol of
             nil => raise bug "nil longsymbol"
           | [symbol] => 
             (case VP.findCon(env, refLongsymbol) of
                NONE =>
                let
                  val varId = VarID.generate()
                  val newLongsymbol = Symbol.concatPath(path, refLongsymbol)
                  val varInfo = {longsymbol=newLongsymbol, id=varId}
                  val rangeLoc = case defRange of
                                   NONE => Symbol.longsymbolToLastLoc refLongsymbol
                                 | SOME loc => loc
                  val idstatus = I.IDVAR{longsymbol=newLongsymbol, id=varId, 
                                         defRange = rangeLoc}
                  val env = VP.rebindId context (V.emptyEnv, symbol, idstatus)
                in
                  (env, I.ICPATVAR_TRANS varInfo)
                end
              | SOME (sym, I.IDCON {id, ty, ...}) =>
                (V.emptyEnv, I.ICPATCON {id=id, longsymbol=refLongsymbol, ty=ty})
              | SOME (sym, I.IDEXN {id, ty,...})=>
                (V.emptyEnv, I.ICPATEXN {id=id, ty=ty, longsymbol=refLongsymbol})
              | SOME (sym, I.IDEXNREP {id, ty,...})=>
                (V.emptyEnv, I.ICPATEXN {id=id, ty=ty, longsymbol=refLongsymbol})
              | SOME (sym, I.IDEXEXN idInfo)=>
                (#used idInfo  := true;
                 (V.emptyEnv, I.ICPATEXEXN {exInfo= I.idInfoToExExnInfo idInfo, 
                                            longsymbol=refLongsymbol})
                )
              | SOME (sym, I.IDEXEXNREP idInfo)=>
                (#used idInfo := true;
                 (V.emptyEnv, I.ICPATEXEXN {exInfo=I.idInfoToExExnInfo idInfo,
                                            longsymbol=refLongsymbol})
                )
              | _ => raise bug "findCon retrun non conid"
             )
           | _ =>
             (case VP.findCon(env, refLongsymbol) of
                NONE =>
                (EU.enqueueError
                   (Symbol.longsymbolToLoc refLongsymbol,
                    E.ConNotFound("020", {longsymbol = refLongsymbol}));
                 (V.emptyEnv, I.ICPATERROR)
                )
              | SOME (sym, I.IDCON {id, ty, ...}) =>
                (V.emptyEnv, I.ICPATCON {id=id, longsymbol=refLongsymbol, ty=ty})
              | SOME (sym, I.IDEXN {id, ty,...})=>
                (V.emptyEnv, I.ICPATEXN {id=id,ty=ty, longsymbol=refLongsymbol})
              | SOME (sym, I.IDEXNREP {id, ty,...})=>
                (V.emptyEnv, I.ICPATEXN {id=id, ty=ty, longsymbol=refLongsymbol})
              | SOME (sym, I.IDEXEXN idInfo)=>
                (#used idInfo := true;
                 (V.emptyEnv, I.ICPATEXEXN {longsymbol=refLongsymbol, 
                                            exInfo = I.idInfoToExExnInfo idInfo})
                )
              | SOME (sym, I.IDEXEXNREP idInfo)=>
                (#used idInfo := true;
                 (V.emptyEnv, I.ICPATEXEXN {longsymbol=refLongsymbol, 
                                            exInfo = I.idInfoToExExnInfo idInfo})
                )
              | _ => raise bug "findCon retrun non conid"
             )
          )
        | P.PLPATCONSTANT constant => (V.emptyEnv, I.ICPATCONSTANT constant)
        | P.PLPATCONSTRUCT (plpat1, plpat2, loc) =>
          let
            val (env1, icpat1) = evalPat plpat1
            val (env2, icpat2) = evalPat plpat2
            val env = VP.unionEnv "200" (env1, env2)
            fun stripTy icpat tyList =
                case icpat of 
                  I.ICPATTYPED (icpat, ty, loc) => stripTy icpat (tyList@[ty])
                | _ => (icpat, tyList)
            val (icpat3, _) = stripTy icpat1 nil
            val icpat1 =
                case icpat3 of
                  I.ICPATERROR => icpat1
                | I.ICPATWILD loc =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("030",{pat = plpat1}));
                   I.ICPATERROR)
                | I.ICPATVAR_TRANS {longsymbol, id} =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc longsymbol, 
                      E.NonConstructor("040", {pat = plpat1}));
                   I.ICPATERROR)
                | I.ICPATVAR_OPAQUE {longsymbol, id} =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc longsymbol, 
                      E.NonConstructor("040", {pat = plpat1}));
                   I.ICPATERROR)
                | I.ICPATCON conInfo => icpat1
                | I.ICPATEXN exnInfo => icpat1
                | I.ICPATEXEXN _ => icpat1
                | I.ICPATCONSTANT (constant, loc) =>
                  (EU.enqueueError
                     (loc,
                      E.NonConstructor("050", {pat = plpat}));
                   I.ICPATERROR)
                | I.ICPATCONSTRUCT {con, arg, loc} =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("060", {pat = plpat}));
                   I.ICPATERROR)
                | I.ICPATRECORD {flex, fields, loc} =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("070", {pat = plpat}));
                   I.ICPATERROR)
                | I.ICPATLAYERED {patVar, tyOpt, pat, loc} =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("080", {pat = plpat}));
                   I.ICPATERROR)
                | I.ICPATTYPED (icpat, ty, loc) => raise bug "icpattyped again"
          in
            (env, I.ICPATCONSTRUCT {con=icpat1, arg=icpat2, loc=loc})
          end
        | P.PLPATRECORD (bool, patfieldList, loc) =>
          let
            fun evalField (l,pat) =
                let
                  val (returnEnv, icpat) = evalPat pat
                in
                  (returnEnv, (l, icpat))
                end
            val _ = EU.checkRecordLabelDuplication
                      (fn (label, _) => label)
                      patfieldList
                      loc
                      (fn s => E.DuplicateRecordLabelInPat("085",s))
            val (returnEnv, icpatfieldList) =
                U.evalList
                  {eval=evalField,
                   emptyEnv=V.emptyEnv,
                   unionEnv=VP.unionEnv "201"}
                  patfieldList
          in
            (returnEnv,
             I.ICPATRECORD {flex=bool, fields=icpatfieldList, loc=loc}
            )
          end
        | P.PLPATLAYERED (symbol, tyOption, plpat, loc) =>
          let
            fun isId (env, symbol)  =
                let
                  val V.ENV {varE,...} = env
                in
                  case SymbolEnv.find (varE, symbol) of
                    NONE => true
                  | (SOME (I.IDVAR _)) => true
                  | (SOME (I.IDVAR_TYPED _)) => true
                  | (SOME (I.IDEXVAR _)) => true
                  | (SOME (I.IDBUILTINVAR _)) => true
                  | (SOME (I.IDCON _)) => false
                  | (SOME (I.IDEXN _)) => false
                  | (SOME (I.IDEXNREP _)) => false
                  | (SOME (I.IDEXEXN _)) => false
                  | (SOME (I.IDEXEXNREP _)) => false
                  | (SOME (I.IDOPRIM {used,...})) => true
                  | (SOME (I.IDEXVAR_TOBETYPED _)) => raise bug "IDEXVAR_TOBETYPED to findCon"
                  | (SOME (I.IDSPECVAR _)) => raise bug "IDSPECVAR to findCon"
                  | (SOME (I.IDSPECEXN _)) => raise bug "IDSPECEXN to findCon"
                  | (SOME (I.IDSPECCON _)) => raise bug "IDSPECCON to findCon"
                end
            val varId =
                if isId (env, symbol) then VarID.generate()
                else
                  (EU.enqueueError
                     (Symbol.symbolToLoc symbol, 
                      E.VarPatExpected("090", {longsymbol = [symbol]}));
                   VarID.generate())
            val longsymbol =  Symbol.prefixPath (path, symbol)
            val rangeLoc = case defRange of
                             NONE => loc
                           | SOME loc => loc
            val idInfo = {longsymbol = longsymbol, id = varId, defRange = rangeLoc}
            val varInfo = {longsymbol = longsymbol, id = varId}
            val idstatus = I.IDVAR idInfo
            val returnEnv = VP.rebindId context (V.emptyEnv, symbol, idstatus)
            val tyOption = Option.map evalTy' tyOption
            val (env1, icpat) = evalPat plpat
            val returnEnv = VP.unionEnv "202" (returnEnv, env1)
          in
            (returnEnv,
             I.ICPATLAYERED {patVar=varInfo,tyOpt=tyOption,pat=icpat,loc=loc})
          end
        | P.PLPATTYPED (plpat, ty, loc) =>
          let
            val (returnEnv, icpat) = evalPat plpat
            val ty = evalTy' ty
          in
            (returnEnv, I.ICPATTYPED (icpat, ty, loc))
          end
      end

  (* change exception status to EXREP *)
  fun exceptionRepVarE varE =
      SymbolEnv.map
      (fn (I.IDEXN info) => I.IDEXNREP info
(* 2012-9-25 ohori added to fixe 241_functorExn bug *)
        | (I.IDEXEXN info) => I.IDEXEXNREP info
        | (idstatus as I.IDEXVAR {exInfo, ...}) =>
          (#used exInfo := true; idstatus)
        | idstatus => idstatus)
      varE
  fun exceptionRepStrEntry (strEntry as {env=V.ENV {varE, tyE, strE}, ...}) = 
      let
        val varE = exceptionRepVarE varE
        val strE = exceptionRepStrE strE
      in
        strEntry # {env=V.ENV{varE = varE, tyE = tyE, strE=strE}}
      end
  and exceptionRepStrE (V.STR envMap) =
      let
        val envMap = SymbolEnv.map exceptionRepStrEntry envMap
      in
        V.STR envMap
      end

  fun optimizeValBind (icpat, icexp, defRange) (icpatIcexpListRev, env) =
      case icpat of 
        I.ICPATVAR_TRANS (varInfo as {longsymbol=defLongsymbol,...}) => 
        let
          val symbol = List.last defLongsymbol 
              handle List.Empty => raise bug "empty longsymbol"
        in
          (case icexp of
             (* val x = y *)
             I.ICVAR (varInfo as {longsymbol=expLongsymbol, id}) => 
             (icpatIcexpListRev, 
              VP.rebindId VP.BIND_VAL
                          (env, symbol, 
                           I.IDVAR {longsymbol=defLongsymbol, 
                                    defRange = defRange,
                                    id=id}))
             (* 2013-07-02 ohori
                Here we use the def longsymbol for the env entry.
                Suppose:
                  val x(def) = 1
                  val y(def) = x(ref)
                  val z(def) = y(ref)
                This policy yields the edge y(ref) -> y(def); if we use expLongsymbol, 
                then we have the edge y(ref) -> x(def)
              *)
           | I.ICEXVAR {longsymbol, exInfo} =>
             (icpatIcexpListRev,
              VP.rebindId VP.BIND_VAL 
                          (env,
                         symbol, 
                         I.IDEXVAR {exInfo=exInfo, internalId=NONE, defRange = defRange}
             ))
           | I.ICBUILTINVAR {primitive, ty, loc} =>
             (icpatIcexpListRev, 
              VP.rebindId 
                VP.BIND_VAL 
                (env, symbol, I.IDBUILTINVAR {primitive=primitive, ty=ty, defRange=defRange}))
           | _ => ((icpat, icexp)::icpatIcexpListRev, env)
          )
        end
      | _ => ((icpat, icexp)::icpatIcexpListRev, env)

  fun makeCastExp (tfvSubst, icexp) loc =
      let
        val castList = 
            TfvMap.foldri 
              (fn (fromTfv, toTfv, castList) => 
                  {from=I.TFUN_VAR fromTfv,
                   to=I.TFUN_VAR toTfv}
                  :: castList
              )
            nil
            tfvSubst
      in
        I.ICTYCAST (castList, icexp, loc)
      end
  fun makeCastDec (tfvSubst, icdeclList) loc = 
      let
        val castList = 
            TfvMap.foldri 
              (fn (fromTfv, toTfv, castList) => 
                  {from=I.TFUN_VAR fromTfv,
                   to=I.TFUN_VAR toTfv}
                  :: castList
              )
            nil
            tfvSubst
      in
        [I.ICTYCASTDECL (castList, icdeclList, loc)]
      end

  (* P.PLCOREDEC (pdecl, loc) *)
  fun evalPdecl (renameEnv:renameEnv) (path:Symbol.longsymbol) 
                (tvarEnv:Ty.tvarEnv) (env:V.env) pdecl
      : renameEnv * V.env * I.icdecl list =
      case pdecl of
        P.PDVAL (scopedTvars, plpatPlexpList, loc) =>
        let
          val (tvarEnv, scopedTvars) =
              Ty.evalScopedTvars tvarEnv env scopedTvars
          val (renameEnv, returnEnv, icpatIcexpListRev) =
              foldl
                (fn ((plpat, plexp, loc), (renameEnv, returnEnv, icpatIcexpListRev)) =>
                    let
                      val icexp = evalPlexp tvarEnv env plexp
                      val (newEnv, icpat) =
                          evalPlpat (SOME loc, VP.BIND_VAL) path tvarEnv env plpat
                      val (icpatIcexpListRev, newEnv) =
                          optimizeValBind (icpat, icexp, loc) (icpatIcexpListRev, newEnv)
                      val returnEnv = VP.unionEnv "203" (returnEnv, newEnv)
                    in
(*
                      (returnEnv, (icpat, icexp)::icpatIcexpListRev)
*)
                      (renameEnv, returnEnv, icpatIcexpListRev)
                    end
                )
                (renameEnv, V.emptyEnv, nil)
                plpatPlexpList
          val icdecls = if List.null icpatIcexpListRev then nil
                        else [I.ICVAL (scopedTvars, List.rev icpatIcexpListRev, loc)]
        in
          (renameEnv, returnEnv, icdecls)
        end
      | P.PDDECFUN (scopedTvars, fundeclList, loc) =>
        let
          val (tvarEnv, guard) = Ty.evalScopedTvars tvarEnv env scopedTvars
          val declList = 
              map
                (fn {fdecl=(x,y), loc} => {fdecl=(generateFunVar path x,y), loc=loc})
                fundeclList
          val _ = EU.checkSymbolDuplication
                    (fn {fdecl=({symbol, varInfo, tyList}, rules), loc} => symbol)
                    declList
                    (fn s => E.DuplicateFunVarInFunDecl("100",s))
          val returnEnv =
              foldl
                (fn ({fdecl=({symbol, varInfo, ...}, _), loc}, returnEnv) =>
                    VP.rebindId
                      VP.BIND_FUNCTION
                      (returnEnv, symbol, I.IDVAR (I.varInfoToIdInfo varInfo loc))
                )
                V.emptyEnv
                declList
          val evalEnv = VP.envWithEnv (env, returnEnv)
          val fundeclList =
              map
                (fn {fdecl=({symbol, varInfo, tyList}, rules),loc} =>
                    {funVarInfo = varInfo,
                     tyList = map (Ty.evalTyWithFlex tvarEnv env) tyList,
                     rules = map 
                               (evalRule VP.BIND_PAT_FN tvarEnv {bodyEnv=evalEnv, argEnv=env} loc) 
                               rules
                    }
                )
                declList
        in
          (renameEnv, returnEnv, [I.ICDECFUN{guard=guard, funbinds=fundeclList, loc=loc}])
        end
      | P.PDVALREC (scopedTvars, plpatPlexpLocList, loc) =>
        let
          val (tvarEnv, guard) = Ty.evalScopedTvars tvarEnv env scopedTvars
          val recList =
              map (fn(pat, exp, loc) => (generateFunVar path pat, exp, loc)) 
                  plpatPlexpLocList
          val _ = EU.checkSymbolDuplication
                    (fn ({symbol, varInfo, tyList}, body, loc) => symbol)
                    recList
                    (fn s => E.DuplicateVarInRecDecl("110",s))
          val returnEnv =
              foldl
                (fn (({symbol, varInfo, ...}, _, loc), returnEnv) =>
                    VP.rebindId VP.BIND_FUNCTION (returnEnv, symbol, I.IDVAR (I.varInfoToIdInfo varInfo loc))
                )
                V.emptyEnv
                recList
          val evalEnv = VP.envWithEnv (env, returnEnv)
          val recbindList =
              map
                (fn ({symbol, varInfo, tyList}, body, loc) =>
                    {varInfo = varInfo,
                     tyList = map (Ty.evalTyWithFlex tvarEnv env) tyList,
                     body = evalPlexp tvarEnv evalEnv body}
                )
                recList
        in
          (renameEnv, returnEnv, [I.ICVALREC {guard=guard, recbinds=recbindList, loc=loc}])
        end
      | P.PDVALPOLYREC (symbolTyPlexpLocList, loc) =>
        let
          val _ = EU.checkSymbolDuplication
                    (fn (symbol, ty, exp, loc) => symbol)
                    symbolTyPlexpLocList
                    (fn s => E.DuplicateVarInRecDecl("110",s))
          fun generateFunVar symbol = 
              {longsymbol= Symbol.prefixPath(path, symbol), id=VarID.generate()}
          val recList =
              map 
                (fn (symbol, ty, exp, loc) => (generateFunVar symbol, symbol, ty, exp, loc))
                symbolTyPlexpLocList
          val returnEnv =
              foldl
                (fn ((varInfo, symbol, _, _, loc),returnEnv) =>
                    VP.rebindId VP.BIND_FUNCTION (returnEnv, symbol, I.IDVAR (I.varInfoToIdInfo varInfo loc))
                )
                V.emptyEnv
                recList
          val evalEnv = VP.envWithEnv (env, returnEnv)
          val recbindList =
              map
                (fn (varInfo, symbol, ty, body, loc) =>
                    {
                     varInfo = varInfo,
                     ty = Ty.evalTyWithFlex tvarEnv env ty,
                     body = evalPlexp tvarEnv evalEnv body
                    }
                )
                recList
        in
          (renameEnv, returnEnv, [I.ICVALPOLYREC (recbindList, loc)])
        end
      | P.PDTYPE (typbindList, loc) =>
        let
          val _ = EU.checkSymbolDuplication
                    (fn (tvarList, symbol, ty, loc) => symbol)
                    typbindList
                    (fn s => E.DuplicateTypName("120", s))
          val (returnEnv, renameEnv:renameEnv) =
              foldl
                (fn ((tvarList, symbol, ty, defRange), (returnEnv, renameEnv)) =>
                    let
                      val _ = EU.checkSymbolDuplication
                                (fn {symbol, isEq} => symbol)
                                tvarList
                                (fn s => E.DuplicateTypParms("130",s))

                      val (tvarEnv, tvarList) = Ty.genTvarList tvarEnv tvarList
                      val ty = Ty.evalTy tvarEnv env ty
                      val (tfun, renameEnv) =
                          case N.tyForm tvarList ty of
                            N.TYNAME tfun => 
                            (tfun, renameEnv)
(*
                            RL.replaceLongsymbolTfun renameEnv (Symbol.prefixPath (path, symbol)) tfun
                            (tfun, renameEnv)
                            RL.replacePathTfun renameEnv path tfun
*)
                          | N.TYTERM ty =>
                            let
(*
                              val longsymbol = [symbol]
*)
                              val longsymbol = Symbol.prefixPath(path, symbol)
                              val admitsEq = N.admitEq tvarList ty
                            in
                              (I.TFUN_DEF {admitsEq=admitsEq,
                                           longsymbol=longsymbol,
                                           formals=tvarList,
                                           realizerTy=ty
                                          },
                               renameEnv)
                            end
                      val tstr = V.TSTR {tfun = tfun, defRange = defRange}
                    in
                      (VP.rebindTstr VP.BIND_TSTR (returnEnv,  symbol, tstr), renameEnv)
                    end
                )
                (V.emptyEnv, renameEnv)
                typbindList
        in
          (renameEnv, returnEnv, nil)
        end

      | P.PDDATATYPE (datadeclList, loc) =>
        let
          val (returnEnv, icdecls) = Ty.evalDatatype path env (datadeclList, loc)
        in
          (renameEnv, returnEnv, icdecls)
        end
      | P.PDREPLICATEDAT (symbol, longsymbol, loc) =>
        (case (VP.findTstr (env, longsymbol)) handle e => raise e of
           NONE => (EU.enqueueError
                      (Symbol.longsymbolToLoc longsymbol, 
                       E.DataTypeNameUndefined("140", {longsymbol = longsymbol}));
                    (renameEnv, V.emptyEnv, nil))
         | SOME (sym, tstr) => 
           let
             val (tstr, renameEnv) = 
                 case tstr of 
                   V.TSTR {tfun, defRange} => 
                   let
                     val (tfun, renameEnv) = 
                         RL.replaceLongsymbolTfun renameEnv (Symbol.prefixPath (path, symbol)) tfun
(*
                         RL.replacePathTfun renameEnv path tfun
*)
                   in
                     (V.TSTR {tfun=tfun, defRange=defRange}, renameEnv)
                   end
                 | V.TSTR_DTY {tfun, varE, formals, conSpec, defRange} => 
                   let
                     val (tfun, renameEnv) = 
(*
                         RL.replaceLongsymbolTfun renameEnv (Symbol.prefixPath (path, symbol)) tfun
                         RL.replacePathTfun renameEnv path tfun
*)
                         RL.replaceLongsymbolTfun emptyRenameEnv (Symbol.prefixPath (path, symbol)) tfun
                     val varE = RL.renameLongsymbolVarE renameEnv varE
                   in
                     (V.TSTR_DTY {tfun= tfun,
                                  varE= varE,
                                  conSpec=conSpec, 
                                  defRange = defRange,
                                  formals=formals},
                      renameEnv
                     )
                   end
             val returnEnv = VP.rebindTstr VP.BIND_TSTR (V.emptyEnv, symbol, tstr)
             val varE = 
                 case tstr of
                   V.TSTR tfun => SymbolEnv.empty
                 | V.TSTR_DTY {varE,...} => varE
             val returnEnv = VP.envWithVarE(returnEnv, varE)
           in
             (renameEnv, returnEnv, nil)
           end
        )
      | P.PDABSTYPE (datadeclList, pdeclList, loc) =>
        let
          fun abstractTfun tfun tfvSubst =
              case tfun of
                I.TFUN_VAR 
                (tfv as 
                 (ref 
                    (I.TFUN_DTY
                       {id,
                        longsymbol,
                        admitsEq,
                        conSpec,
                        conIDSet,
                        formals,
                        liftedTys,
                        dtyKind
                      })
                 )
                ) =>
                if TfvMap.inDomain(tfvSubst, tfv) then tfvSubst
                else
                  let
                    val id = TypID.generate()
                    val tfunkind = 
                        I.TFUN_DTY
                          {id = id,
                           longsymbol=longsymbol,
                           admitsEq = false,
                           conSpec = SymbolEnv.empty,
                           conIDSet = ConID.Set.empty,
                           formals = formals,
                           liftedTys = liftedTys,
                           dtyKind = I.OPAQUE {tfun=tfun, revealKey = RevealID.generate()}
                          }
                    val newTfv = ref tfunkind
                  in
                    TfvMap.insert(tfvSubst, tfv, newTfv)
                  end
              | _ => raise bug "PDABSTYPE: non TFUN_DTY in evalDatatype"
          fun abstractTstr tstr tfvSubst =
              case tstr of
              V.TSTR tfun => raise bug "PDABSTYPE:TSRT in evalDatatype"
            | V.TSTR_DTY {tfun, varE, formals, conSpec, defRange} =>
              abstractTfun tfun tfvSubst
          fun abstractTyE tyE tfvSubst =
              SymbolEnv.foldl
              (fn (tstr, tfvSubst) => 
                  abstractTstr tstr tfvSubst)
              tfvSubst
              tyE
          val (env1 as V.ENV {varE, tyE, strE}, _) = Ty.evalDatatype path env (datadeclList, loc)
          val evalEnv = VP.envWithEnv (env, env1)
          val (renameEnv, newEnv, icdeclList) = evalPdeclList (renameEnv:renameEnv)  path tvarEnv evalEnv pdeclList
          val absEnv = V.ENV{varE=SymbolEnv.empty, tyE=tyE, strE=V.STR SymbolEnv.empty}
          val returnEnv = VP.envWithEnv (absEnv, newEnv)
          val tfvSubst = abstractTyE tyE TfvMap.empty
          val icdeclList = makeCastDec (tfvSubst, icdeclList) loc
          val returnEnv = S.substTfvEnv tfvSubst returnEnv
        in
          (renameEnv, returnEnv, icdeclList)
        end

      | P.PDEXD (plexbindList, loc) =>
        let
          val _ = EU.checkSymbolDuplication
                    (fn P.PLEXBINDDEF (symbol, _,_) => symbol
                      | P.PLEXBINDREP (symbol, _,_) => symbol)
                    plexbindList
                    (fn s => E.DuplicateExnName("150",s))
          val (exEnv, exdeclList) =
              foldl
                (fn (plexbind, (exEnv, exdeclList)) =>
                    case plexbind of
                      P.PLEXBINDDEF (symbol, tyOption, loc) =>
                      let
                        val ty =
                            case tyOption of
                              NONE => BT.exnITy
                            | SOME ty => 
                              I.TYFUNM([Ty.evalTy tvarEnv env ty],
                                        BT.exnITy)
                        val newExnId = ExnID.generate()
                        val longsymbol = Symbol.prefixPath(path, symbol)
                        val exnInfo = {longsymbol=longsymbol, ty=ty, id=newExnId}
(*
                        val _ = VP.exnConAdd (V.EXN exnInfo)
*)
                        val exEnv =
                            VP.rebindId 
                              VP.BIND_VAL
                              (exEnv,
                               symbol,
                               I.IDEXN {id=newExnId, defRange = loc,
                                        longsymbol=longsymbol, ty=ty})
                      in
                        (exEnv,
                         exdeclList@[{exnInfo=exnInfo,loc=loc}]
                        )
                      end
                    | P.PLEXBINDREP (symbol, longsymbol, loc) =>
                      (case VP.findId(env, longsymbol) of
                         SOME(sym, I.IDEXN exnInfo) =>
                         (VP.rebindId VP.BIND_VAL (exEnv, symbol, I.IDEXNREP (exnInfo # {defRange = loc})),
                          exdeclList)
                       | SOME(sym, I.IDEXNREP exnInfo) =>
                         (VP.rebindId VP.BIND_VAL (exEnv, symbol, I.IDEXNREP (exnInfo # {defRange = loc})), exdeclList)
                       | SOME(sym, idstatus as I.IDEXEXN exInfo) =>
  (* 2012-9-25 ohori bug 237_functorExn:
                          (used := true;
                           (VP.rebindId(exEnv, symbol, idstatus), exdeclList)
                          )
  *)
                         (#used exInfo := true;
                          (VP.rebindId VP.BIND_VAL (exEnv, symbol, I.IDEXEXNREP (exInfo # {defRange = loc})), exdeclList)
                         )
                       | SOME (sym, I.IDEXEXNREP exInfo) =>
                          (* FIXME 2012-1-31; This case was missing. 
                             Is this an error *)
                         (#used exInfo := true;
                          (VP.rebindId VP.BIND_VAL (exEnv, symbol, I.IDEXEXNREP (exInfo # {defRange = loc})), exdeclList)
                         )
                       | SOME _ =>
                         (EU.enqueueError
                            (Symbol.longsymbolToLoc longsymbol,
                             E.ExnExpected("170", {longsymbol = longsymbol}));
                          (exEnv, exdeclList)
                         )
                       | NONE => 
                         (EU.enqueueError
                            (loc,E.ExnUndefined("160",{longsymbol = longsymbol}));
                          (exEnv, exdeclList)
                         )
                      )
                )
                (V.emptyEnv, nil)
                plexbindList
        in
          (renameEnv, exEnv, [I.ICEXND (exdeclList, loc)])
        end
      | P.PDLOCALDEC (pdeclList1, pdeclList2, loc) =>
        let
          val (renameEnv, env1, icdeclList1) = evalPdeclList (renameEnv:renameEnv) path tvarEnv env pdeclList1
          val evalEnv = VP.envWithEnv (env, env1)
          val (renameEnv, env2, icdeclList2) =
              evalPdeclList (renameEnv:renameEnv) path tvarEnv evalEnv pdeclList2
        in
          (renameEnv, env2, icdeclList1@icdeclList2)
        end
      | P.PDOPEN (longsymbolList, loc) =>
        let
          val (returnEnv, renameEnv) =
              foldl
                (fn (longsymbol, (returnEnv, renameEnv)) =>
                    case VP.findStr(env, longsymbol) of
                      SOME strEntry =>
                      let
                        val {env, strKind, loc, definedSymbol} = 
                            exceptionRepStrEntry strEntry (* bug 170_open *)
                        (* bug 351_open 
                        val env = V.replaceLocEnv loc env
                         *)
                        val (env, renameEnv) = RL.replacePathEnv renameEnv path env
                      in
                        (VP.bindEnvWithEnv (returnEnv, env), renameEnv)
                      end
                    | NONE => 
                      (EU.enqueueError
                         (Symbol.longsymbolToLoc longsymbol,
                          E.StrNotFound("180", {longsymbol = longsymbol}));
                       (returnEnv, renameEnv))
                )
                (V.emptyEnv, renameEnv)
                longsymbolList
        in
          (renameEnv, returnEnv, nil)
        end
      | P.PDINFIXDEC _ => (renameEnv, V.emptyEnv, nil)
      | P.PDINFIXRDEC _ => (renameEnv, V.emptyEnv, nil)
      | P.PDNONFIXDEC _ => (renameEnv, V.emptyEnv, nil)
      | P.PDEMPTY => (renameEnv, V.emptyEnv, nil)

  and evalPdeclList (renameEnv:renameEnv) (path:Symbol.longsymbol) (tvarEnv:Ty.tvarEnv) (env:V.env) pdeclList
      : renameEnv * V.env * I.icdecl list =
      let
        val (renameEnv, returnEnv, icdeclList) =
            foldl
              (fn (pdecl, (renameEnv, returnEnv, icdeclList)) =>
                  let
                    val evalEnv = VP.envWithEnv (env, returnEnv)
                    val (renameEnv, newEnv, icdeclList1) =
                        evalPdecl (renameEnv:renameEnv) path tvarEnv evalEnv pdecl
                    val retuernEnv = VP.envWithEnv (returnEnv, newEnv)
                  in
                    (renameEnv, retuernEnv, icdeclList@icdeclList1)
                  end
              )
              (renameEnv, V.emptyEnv, nil)
              pdeclList
      in
        (renameEnv, returnEnv, icdeclList)
      end

  and evalPlexp  (tvarEnv:Ty.tvarEnv) (env:V.env) plexp : I.icexp =
      let
        val renameEnv = emptyRenameEnv
        val evalExp = evalPlexp tvarEnv env
        val evalPat = fn (defRange, context) => evalPlpat (defRange, context) nilPath tvarEnv env
        fun evalTy' ty = Ty.evalTyWithFlex tvarEnv env ty
        fun evalTyWithoutFlex' ty = Ty.evalTy tvarEnv env ty
      in
        case plexp of
          P.PLCONSTANT constant => I.ICCONSTANT constant
        | P.PLSIZEOF (ty, loc) => I.ICSIZEOF (evalTy' ty, loc)
        | P.PLVAR refLongsymbol =>
          let
            val idstatus = 
                case VP.findId (env, refLongsymbol) of
                  SOME (sym, idstatus) => idstatus
                | NONE => 
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc refLongsymbol,
                      E.VarNotFound("190",{longsymbol=refLongsymbol}));
                   I.IDVAR {longsymbol=refLongsymbol, id = VarID.generate(),
                            defRange=Loc.noloc}
                  )
            val loc = Symbol.longsymbolToLoc refLongsymbol
             (* 2013-07-02 ohori
               Let expLongsymbol be the longsymbol of PLVAR, and
                   envLongsymbol be the on in the idastatus in env.
               We need to choose one of the two for the longsymbol in the result ICEXP
               and the environment key.
               1. use expLongsymbol for the env key and keep it for the expression
               2. use envLongsymbol for the env key and replace the expression with this.
              We adopt the strategy 1. The effect of this is the following.
                val x(def) = 1
                val y(def) = x(ref)
                val z(def) = y(ref)
              The strategy 1 yields the edge y(ref) -> y(def), and
              the strategy 2 yields the edge y(ref) -> x(def).
              We adopt the strategt 1.
             *)
          in
            case idstatus of
              I.IDVAR {longsymbol=envLongsymbol, id, defRange} => 
              I.ICVAR {longsymbol=refLongsymbol, id=id}
            | I.IDVAR_TYPED {id, longsymbol=envLongsymbol, ty, defRange} => 
              I.ICVAR {longsymbol=refLongsymbol, id = id}
            | I.IDEXVAR {exInfo, internalId, defRange} => 
              (#used exInfo := true;
               I.ICEXVAR {exInfo=exInfo, longsymbol=refLongsymbol}
              (* I.ICEXVAR {longsymbol=longsymbol, exInfo=exInfo} 
                           should be better.
               *)
              )
            | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
            | I.IDBUILTINVAR {primitive, ty, defRange} =>
              I.ICBUILTINVAR {primitive=primitive, ty=ty, loc=loc}
            | I.IDOPRIM {id, overloadDef, used, longsymbol=envLongsymbol, defRange} => 
              let
                fun touchDecl decl =
                    case decl of 
                      I.ICOVERLOADDEF {overloadCase, ...} =>
                      touchOverloadCase overloadCase
                    | _ => ()
                and touchOverloadCase {tvar, expTy,matches, loc} =
                    app touchMatch matches 
                and touchMatch {instTy, instance} =
                    touchInstance instance
                and touchInstance instance =
                    case instance of 
                      I.INST_OVERLOAD overloadCase =>
                      touchOverloadCase overloadCase
                    | I.INST_EXVAR {exInfo,...} => #used exInfo := true
                    | I.INST_PRIM _ => ()
                val _ = touchDecl overloadDef 
              in
                (used := true; I.ICOPRIM {longsymbol=refLongsymbol, id=id})
              end
            | I.IDCON {longsymbol=envLongsymbol, ty, id, defRange} => 
              I.ICCON {longsymbol=refLongsymbol, ty=ty, id=id}
            | I.IDEXN {longsymbol=envLongsymbol, id, ty, defRange} => 
              I.ICEXN {longsymbol=refLongsymbol, id=id, ty=ty}
            | I.IDEXNREP {longsymbol=envLongsymbol, id, ty, defRange} => 
              I.ICEXN {longsymbol=refLongsymbol, id=id, ty=ty}
            | I.IDEXEXN idInfo => 
              (#used idInfo := true;
               I.ICEXEXN {exInfo = I.idInfoToExExnInfo idInfo, longsymbol=refLongsymbol}
              (* I.ICEXEXN {longsymbol=longsymbol, exInfo=exInfo} 
                           should be better.
               *)
              )
            | I.IDEXEXNREP idInfo => 
              (#used idInfo := true;
               I.ICEXEXN {exInfo = I.idInfoToExExnInfo idInfo, longsymbol=refLongsymbol}
              (* I.ICEXEXN {longsymbol=longsymbol, exInfo=exInfo} 
                           should be better.
               *)
              )
            | I.IDSPECVAR _ => raise bug "SPEC id status"
            | I.IDSPECEXN _ => raise bug "SPEC id status"
            | I.IDSPECCON _ => raise bug "SPEC id status"
          end
        | P.PLTYPED (plexp, ty, loc) =>
          I.ICTYPED (evalExp plexp, evalTy' ty, loc)
        | P.PLAPPM (plexp, plexpList, loc) =>
          I.ICAPPM (evalExp plexp, map evalExp plexpList, loc)
        | P.PLLET (pdeclList, plexp, loc) =>
          let
            val (renameEnv, newEnv, icdeclList) =
                evalPdeclList (renameEnv:renameEnv) nilPath tvarEnv env pdeclList
            val evalEnv = VP.envWithEnv (env, newEnv)
          in
            I.ICLET (icdeclList,
                     evalPlexp tvarEnv evalEnv plexp,
                     loc)
          end
        | P.PLRECORD (expfieldList, loc) =>
          let
            val _ = EU.checkRecordLabelDuplication
                      (fn (name, _) => name)
                       expfieldList
                      loc
                      (fn s => E.DuplicateRecordLabelInExp("192",s))
            val expfieldList = map (fn (l, exp)=>(l,evalExp exp)) expfieldList
          in
            I.ICRECORD (expfieldList, loc)
          end
        | P.PLRECORD_UPDATE (plexp, expfieldList, loc) =>
          let
            val icexp = evalExp plexp
            val _ = EU.checkRecordLabelDuplication
                      (fn (name, _) => name)
                      expfieldList
                      loc
                      (fn s => E.DuplicateRecordLabelInUpdate("194",s))
            val expfieldList = map (fn (l, exp)=>(l,evalExp exp)) expfieldList
          in
            I.ICRECORD_UPDATE (icexp, expfieldList, loc)
          end
        | P.PLRECORD_UPDATE2 (plexp, plexp2, loc) =>
          let
            val icexp = evalExp plexp
            val icexp2 = evalExp plexp2
          in
            I.ICRECORD_UPDATE2 (icexp, icexp2, loc)
          end
        | P.PLRAISE (plexp, loc) => I.ICRAISE (evalExp plexp, loc)
        | P.PLHANDLE (plexp, plpatPlexpList, loc) =>
          I.ICHANDLE
            (
             evalExp plexp,
             map
               (fn (plpat, plexp, loc) =>
                   let
                     val (newEnv, icpat) = evalPat (SOME loc, VP.BIND_PAT_CASE) plpat
                   in
                     (
                      icpat,
                      evalPlexp tvarEnv (VP.envWithEnv (env, newEnv)) plexp
                     )
                   end
               )
               plpatPlexpList,
             loc
            )
        | P.PLFNM (ruleList, loc) =>
          I.ICFNM(map (evalRule VP.BIND_PAT_FN tvarEnv {bodyEnv=env,argEnv=env} loc) ruleList, loc)
        | P.PLCASEM (plexpList, ruleList, caseKind, loc) =>
          I.ICCASEM
            (
             map evalExp plexpList,
             map (evalRule VP.BIND_PAT_CASE tvarEnv {bodyEnv=env,argEnv=env} loc) ruleList,
             caseKind,
             loc
            )
        | P.PLDYNAMIC (plexp, ty, loc) =>
          I.ICDYNAMIC (evalPlexp tvarEnv env plexp, evalTyWithoutFlex' ty, loc)
        | P.PLDYNAMICIS (plexp, ty, loc) =>
          I.ICDYNAMICIS (evalPlexp tvarEnv env plexp, evalTyWithoutFlex' ty, loc)
        | P.PLDYNAMICNULL (ty, loc) =>
          I.ICDYNAMICNULL (evalTyWithoutFlex' ty, loc)
        | P.PLDYNAMICTOP (ty, loc) =>
          I.ICDYNAMICTOP (evalTyWithoutFlex' ty, loc)
        | P.PLDYNAMICVIEW (plexp, ty, loc) =>
          I.ICDYNAMICVIEW (evalPlexp tvarEnv env plexp, evalTyWithoutFlex' ty, loc)
        | P.PLDYNAMICCASE (plexp, ruleList, loc) =>
          I.ICDYNAMICCASE
            (
             evalExp plexp,
             map (evalDynRule VP.BIND_PAT_CASE tvarEnv env loc) ruleList,
             loc
            )
        | P.PLRECORD_SELECTOR (label, loc) => 
          I.ICRECORD_SELECTOR (label, loc)
        | P.PLSELECT (string,plexp,loc) => I.ICSELECT(string,evalExp plexp,loc)
        | P.PLSEQ (plexpList, loc) => I.ICSEQ (map evalExp plexpList, loc)
        | P.PLFFIIMPORT (plexp, ffiTy, loc) =>
          let
            val ffiTy = Ty.evalFfity tvarEnv env ffiTy
          in
            I.ICFFIIMPORT(evalFfiFun tvarEnv env plexp, ffiTy, loc)
          end
        | P.PLSQLSCHEMA {tyFnExp, ty, loc} =>
          I.ICSQLSCHEMA
            {tyFnExp = evalPlexp tvarEnv env tyFnExp,
             ty = evalTy' ty,
             loc = loc}
        | P.PLJOIN (bool, plexp1, plexp2, loc) =>
          I.ICJOIN(bool, evalExp plexp1, evalExp plexp2, loc)
        | P.PLREIFYTY (ty, loc) => 
          I.ICREIFYTY (evalTy' ty, loc)
      end

  and evalFfiFun tvarEnv env ffiFun =
      case ffiFun of
        P.PLFFIFUN exp => I.ICFFIFUN (evalPlexp tvarEnv env exp)
      | P.PLFFIEXTERN s => I.ICFFIEXTERN s

  and evalRule (cnx:VP.category)
               (tvarEnv:Ty.tvarEnv) {bodyEnv:V.env, argEnv:V.env} loc
               (plpatList, plexp, defRange) =
      let
        val (newEnv, icpatList) =
            U.evalList
            {emptyEnv=V.emptyEnv,
             eval=evalPlpat (SOME defRange, cnx) nilPath tvarEnv argEnv,
             unionEnv=VP.unionEnv "204"}
            plpatList
        val evalEnv = VP.envWithEnv (bodyEnv, newEnv)
      in
        {args=icpatList, body=evalPlexp tvarEnv evalEnv plexp}
      end
  and evalDynRule (cnx:VP.category) (tvarEnv:Ty.tvarEnv) (env: V.env) loc
                  (tyvars, plpat, plexp, defRange) =
      let

        val (tvarEnv, scopedTvars) = Ty.evalScopedTvars tvarEnv env tyvars
        val (newEnv, icpat) = evalPlpat (SOME defRange, cnx) nilPath tvarEnv env plpat
        val evalEnv = VP.envWithEnv (env, newEnv)
      in
        {tyvars=scopedTvars, arg=icpat, body=evalPlexp tvarEnv evalEnv plexp}
      end

  fun evalPlstrdec (renameEnv:renameEnv) (topEnv:V.topEnv) path plstrdec 
      : renameEnv * V.env * I.icdecl list =
      case plstrdec of
        P.PLCOREDEC (pdecl, loc) => 
        evalPdecl (renameEnv:renameEnv) path Ty.emptyTvarEnv (#Env topEnv) pdecl
      | P.PLSTRUCTBIND (symbolPlstrexpLocList, loc) =>
        let
          val _ = EU.checkSymbolDuplication
                    #1
                    symbolPlstrexpLocList
                    (fn s => E.DuplicateStrName("420",s))
        in
          foldl
            (fn ((symbol, plstrexp, loc), (renameEnv, returnEnv, icdeclList)) =>
                let
                  val (renameEnv, strEntry, icdeclList1) = 
                      evalPlstrexp renameEnv topEnv (path@[symbol]) plstrexp
                  val returnEnv = VP.rebindStr VP.BIND_STR (returnEnv, symbol, strEntry)
                in
                  (renameEnv, returnEnv, icdeclList@icdeclList1)
                end
            )
            (renameEnv, V.emptyEnv, nil)
            symbolPlstrexpLocList
        end
      | P.PLSTRUCTLOCAL (plstrdecList1, plstrdecList2, loc) =>
        let
          fun evalList topEnv plstrdecList =
              foldl
                (fn (plstrdec, (renameEnv, returnEnv, icdeclList)) =>
                    let
                      val evalEnv = VP.topEnvWithEnv (topEnv, returnEnv)
                      val (renameEnv, newEnv, icdeclList1) =
                          evalPlstrdec (renameEnv:renameEnv) evalEnv path plstrdec
                    in
                      (renameEnv,
                       VP.envWithEnv (returnEnv, newEnv),
                       icdeclList@icdeclList1)
                    end
                )
                (renameEnv, V.emptyEnv, nil)
                plstrdecList
          val (renameEnv, returnEnv1,icdeclList1) = evalList topEnv plstrdecList1
          val evalTopEnv = VP.topEnvWithEnv(topEnv, returnEnv1)
          val (renameEnv, returnEnv2,icdeclList2) = evalList evalTopEnv plstrdecList2
        in
          (renameEnv, returnEnv2, icdeclList1 @ icdeclList2)
        end

  and evalPlstrexp (renameEnv:renameEnv) (topEnv as {Env = env, FunE, SigE}) path plstrexp
      : renameEnv * V.strEntry * I.icdecl list =
      case plstrexp of
        (* struct ... end *)
        P.PLSTREXPBASIC (plstrdecList, loc) =>
        let
          val strKind = V.STRENV (StructureID.generate())
          val (renameEnv, returnEnv, icdeclList) =
              foldl
                (fn (plstrdec, (renameEnv, returnEnv, icdeclList)) =>
                    let
                      val evalTopEnv = VP.topEnvWithEnv (topEnv, returnEnv)
                      val (renameEnv, returnEnv1, icdeclList1) =
                          evalPlstrdec (renameEnv:renameEnv) evalTopEnv path plstrdec
                    in
                      (renameEnv,
                       VP.envWithEnv(returnEnv, returnEnv1),
                       icdeclList @ icdeclList1
                      )
                    end
                )
                (renameEnv, V.emptyEnv, nil)
                plstrdecList
        in
          (renameEnv, {env=returnEnv, strKind=strKind, definedSymbol=path,
                       loc = loc}, icdeclList)
        end
      | P.PLSTRID longsymbol =>
        (case VP.findStr(env,longsymbol) of
           SOME strEntry =>
           let
             val strEntry = exceptionRepStrEntry strEntry
           (* bug 351_open 
             val loc = Symbol.longsymbolToLoc longsymbol
             val env = V.replaceLocEnv loc env
            *)
           in
             (renameEnv, strEntry, nil)
           end
         | NONE => 
           let
             val loc = Symbol.longsymbolToLoc longsymbol
           in
             (EU.enqueueError (loc, E.StrNotFound("430",{longsymbol = longsymbol}));
              (renameEnv, {env=V.emptyEnv, 
                           loc = Loc.noloc,
                           definedSymbol = path, 
                           strKind=V.STRENV(StructureID.generate())
                          }, nil)
             )
           end
        )
      | P.PLSTRTRANCONSTRAINT (plstrexp, plsigexp, loc1) =>
        (
        let
          val (renameEnv, {env=strEnv,strKind=strKind, definedSymbol,loc=loc2}, icdeclList1) = 
              evalPlstrexp renameEnv topEnv path plstrexp
          val {env=specEnv,...} = Sig.evalPlsig topEnv plsigexp
          val specEnv = #2 (Sig.refreshSpecEnv specEnv)
          val (returnEnv, specDeclList2) =
              SC.sigCheck
                {mode = SC.Trans,
                 strPath = path,
                 strEnv = strEnv,
                 specEnv = specEnv,
                 loc = loc1
                }
(*
          val returnEnv = V.replaceLocEnv loc1 returnEnv
*)
          fun emptyEnv (V.ENV{varE, tyE, strE=V.STR strEMap}) = 
              SymbolEnv.isEmpty varE 
              andalso SymbolEnv.isEmpty tyE 
              andalso SymbolEnv.isEmpty strEMap
          val strKind = 
              if emptyEnv (SC.removeEnv (returnEnv, strEnv)) andalso List.null specDeclList2 
              then strKind
              else V.STRENV(StructureID.generate())
        in
          (renameEnv, {env=returnEnv,loc=loc1, definedSymbol = path,  strKind=strKind}, 
           icdeclList1 @ specDeclList2)
        end
        handle SC.SIGCHECK => 
               (renameEnv, 
                {env=V.emptyEnv, loc = Loc.noloc, definedSymbol = path,
                 strKind=V.STRENV(StructureID.generate())}, nil)
        )

      | P.PLSTROPAQCONSTRAINT (plstrexp, plsigexp, loc1) =>
        (
        let
           val (renameEnv, {env=strEnv, strKind=_, loc=loc2, definedSymbol}, icdeclList1) = 
               evalPlstrexp renameEnv topEnv path plstrexp
           val {env = specEnv,...} = Sig.evalPlsig topEnv plsigexp
           val specEnv = #2 (Sig.refreshSpecEnv specEnv)
           val strKind = V.STRENV (StructureID.generate())
           val (returnEnv, specDeclList2) =
               SC.sigCheck
                 {mode = SC.Opaque,
                  strPath = path,
                  strEnv = strEnv,
                  specEnv = specEnv,
                  loc = loc1
                  }
(*
           val returnEnv = V.replaceLocEnv loc1 returnEnv
*)
        in
          (renameEnv, {env=returnEnv,loc=loc1, strKind=strKind, definedSymbol = path}, 
           icdeclList1 @ specDeclList2)
        end
        handle SC.SIGCHECK => 
               (renameEnv, 
                {env=V.emptyEnv, loc=Loc.noloc, definedSymbol = path,
                 strKind=V.STRENV(StructureID.generate())}, 
                nil)
        )

      | P.PLFUNCTORAPP (symbol, longsymbol, loc) =>
        let
          val (renameEnv, {env, icdecls, funId, argId}) = 
              applyFunctor renameEnv topEnv (path, symbol, longsymbol, loc)
          val structureId = StructureID.generate()
          val strKind = V.FUNAPP {id=structureId, funId=funId, argId=argId}
        in
          (renameEnv, {env=env, strKind=strKind, definedSymbol = path, loc=loc}, icdecls)
        end

      | P.PLSTRUCTLET (plstrdecList, plstrexp, loc) =>
        let
          val (renameEnv, returnEnv1, icdeclList1) =
              foldl
                (fn (plstrdec, (renameEnv, returnEnv1, icdeclList1)) =>
                    let
                      val evalTopEnv = VP.topEnvWithEnv (topEnv, returnEnv1)
                      val (renameEnv,newReturnEnv, newIcdeclList) =
                          evalPlstrdec (renameEnv:renameEnv) evalTopEnv nilPath plstrdec
                    in
                      (renameEnv, VP.envWithEnv (returnEnv1, newReturnEnv),
                       icdeclList1 @ newIcdeclList)
                    end
                )
              (renameEnv, V.emptyEnv, nil)
              plstrdecList
          val evalEnv = VP.topEnvWithEnv(topEnv, returnEnv1)
          val (renameEnv, strEntry, icdeclList2) = evalPlstrexp renameEnv evalEnv path plstrexp
        in
          (renameEnv, strEntry, icdeclList1 @ icdeclList2)
        end

  and applyFunctor renameEnv
                   (topEnv as {Env = env, FunE, SigE})
                   (copyPath, funName, argPath, loc)
      : renameEnv *
         {env:V.env, 
         icdecls:I.icdecl list, 
         funId:FunctorID.id, 
         argId:StructureID.id} = 
      let
      (*
          1. eliminate TSTR_TOTVAR and generate tvarSubst;
             TSTR_TOTVAR tvar vs TSTR tfun =>
             (a) tstr: TSTR tfun
             (b) tvarSubst: tvar -> TYCONSTRUCT ...
             TSTR_TOTVAR tvar vs TSTR_TOTVAR
             (a) tstr: TSTR_TOTVAR
             (b) tvarSubst: tvar -> TYVAR ...
             In the latter case, tstr becomes TSTR (TFUN_DEF ...)
          2. process TFUN_DTYs 
             (a) TFUN_DTY (not dummy) vs TFUN_DTY
                 update DTY to actual DTY
                 returns tfvSubst for generating castDecls
             (b) TFUN_DTY (dummy) vs TFUN_DTY
                 update DTY to actual DTY
                 returns tfvSubst for generating castDecls
             (b) TFUN_DTY (dummy) vs TFUN_DEF
                 check that DEF is boxed then update DTY to actual DEF
                 returns tfvSubst for generating castDecls
          3. apply tvarSubst to the updated env
         *)
        fun instVarE (varE,actualVarE)
                     {typIdS, tvarS, conIdS, exnIdS, newProvider} =
            let
              val conIdS =
                  SymbolEnv.foldri
                    (fn (name, idstatus, conIdS) =>
                      case idstatus of
                        I.IDCON {id, longsymbol, ty, defRange} =>
                        (case SymbolEnv.find(actualVarE, name) of
                           SOME (idstatus as I.IDCON _) =>
                           ConID.Map.insert(conIdS, id, idstatus)
                         | SOME actualIdstatus => raise bug "non conid"
                         | NONE => raise bug "conid not found in instVarE"
                        )
                      | _ => conIdS)
                  conIdS
                  varE
            in
              {typIdS = typIdS, 
               tvarS=tvarS, exnIdS=exnIdS, conIdS=conIdS, newProvider=newProvider}
            end
        fun instTfun path (tfun, actualTfun)
                     (subst as {typIdS, tvarS, conIdS, exnIdS, newProvider}) =
            let
(*
val _ = U.print "instTfun\n"
val _ = U.print "tfun\n"
val _ = U.printTfun tfun
val _ = U.print "\n"
val _ = U.print "actual tfun\n"
val _ = U.printTfun actualTfun
val _ = U.print "\n"
*)
              val tfun = I.derefTfun tfun
              val actualTfun = I.derefTfun actualTfun
            in
              case tfun of
                I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {id=id1, dtyKind = I.FUNPARAM rty,...})) =>
                (case actualTfun of
                   I.TFUN_VAR(ref (tfunkind as I.TFUN_DTY {id=id2, ...})) =>
                   if case I.tfunProperty actualTfun of
                        NONE => false
                      | SOME ty2 =>
                        Ty.compatProperty {abs = I.PROP rty, impl = ty2}
                   then 
                     (
(*
U.print "substitution performed\n";
*)
                      tfv1 := tfunkind;
                      (fn (x as {typIdS,...}) => x # {typIdS = TypID.Map.insert(typIdS, id1, id2)})
                        subst
                     )
                   else (EU.enqueueError
                           (loc, E.FunctorParamRestriction
                                   ("440", {longsymbol=path}));
                         subst
                        )
                 | I.TFUN_VAR _ => raise bug "tfun var"
                 | I.TFUN_DEF _ =>
                   (EU.enqueueError
                      (loc, E.FunctorParamRestriction
                              ("440", {longsymbol=path}));
                    subst)
                )
              | I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {id=id1,dtyKind,...})) =>
                (case actualTfun of
                   I.TFUN_VAR(tfv2 as ref (tfunkind as I.TFUN_DTY {id=id2,...})) =>
                   (* The tfvS generated by instEnv is the identity and
                      this does not make sense. *)
                   (
(*
U.print "propertyError in case of no FUNPARAM\n";
*)
                    tfv1 := tfunkind;
(*
U.print "tfun\n";
U.printTfun tfun;
*)
                    (fn (x as {typIdS,...}) => x # {typIdS = TypID.Map.insert(typIdS, id1, id2)})
                      subst
                   )
                 | I.TFUN_DEF _ => raise bug "tfun def"
                 | I.TFUN_VAR _ => raise bug "tfun var"
                )
              | I.TFUN_DEF{admitsEq, formals=nil, realizerTy= I.TYVAR tvar, longsymbol} =>
                let
                  val ty =I.TYCONSTRUCT{tfun=actualTfun,args=nil}
                  val ty = N.reduceTy TvarMap.empty ty
                in
                  {tvarS=TvarMap.insert(tvarS,tvar,ty),
                   conIdS=conIdS,
                   exnIdS=exnIdS,
                   typIdS=typIdS,
                   newProvider=newProvider
                  }
                end
              | _ => subst
            end
        fun instTstr 
              path (tstr, actualTstr)
              subst =
            (
            case tstr of
              V.TSTR {tfun,...} =>
              (
               case actualTstr of
                 V.TSTR {tfun = actualTfun,...} =>
                 instTfun path (tfun, actualTfun) subst
               | V.TSTR_DTY {tfun=actualTfun,...} =>
                 instTfun path (tfun, actualTfun) subst
              )
            | V.TSTR_DTY {tfun,varE,...} =>
              (
               case actualTstr of
                 V.TSTR actualTfun => raise bug "TSTR_DTY vs TST"
               | V.TSTR_DTY {tfun=actualTfun,varE=actualVarE,...} =>
                 let
                   val subst = instTfun path (tfun, actualTfun) subst
                 in
                   instVarE (varE, actualVarE) subst
                 end
              )
            )

        fun instTyE path (tyE, actualTyE) subst =
            SymbolEnv.foldri
              (fn (name, tstr, subst) =>
                  let
                    val actualTstr = 
                        case SymbolEnv.find(actualTyE, name) of
                          SOME tstr => tstr
                        | NONE =>
                          (
                          raise bug "tstr not found"
                          )
                  in 
                   instTstr (path@[name]) (tstr, actualTstr) subst
                  end
              )
              subst
              tyE
        fun instEnv path (argEnv, actualArgEnv) subst =
            let
              val V.ENV{tyE, strE,...} = argEnv
              val V.ENV{tyE=actualTyE,strE=actualStrE,...} = actualArgEnv
              val subst = instTyE path (tyE, actualTyE) subst
              val subst = instStrE path (strE, actualStrE) subst
            in
              subst
            end
        and instStrE path (V.STR envMap, V.STR actualEnvMap) subst =
            SymbolEnv.foldri
            (fn (name, {env, strKind,...}, subst) =>
                let
                  val actualEnv = case SymbolEnv.find(actualEnvMap, name) of
                                    SOME {env, ...} => env 
                                  | NONE => raise bug "actualEnv not found"
                in
                  instEnv (path@[name]) (env, actualEnv) subst
                end
            )
            subst
            envMap
        val funEEntry as
            {id=functorId,
             loc,
             version,
             argSigEnv,
             argStrName,
             argStrEntry,
             bodyEnv,
             polyArgTys = _,
             dummyIdfunArgTy,
             typidSet,
             exnIdSet,
             bodyVarExp
            }
          = case VP.findFunETopEnv(topEnv, funName) of
              SOME funEEntry => funEEntry
            | NONE => raise FunIDUndefind

        val _ = 
            case bodyVarExp of
              I.ICEXVAR {exInfo, ...} => #used exInfo := true
            | _ => ()

        val ((actualArgEnv, actualArgDecls), argId) =
            let
              val argSigEnv = #2 (Sig.refreshSpecEnv argSigEnv)
                           handle e => raise e
              val (renameEnv, {env=argStrEnv,strKind,...},_) =
                  evalPlstrexp renameEnv topEnv nilPath (P.PLSTRID argPath)
                  handle e => raise e
              val argId = case strKind of
                            V.STRENV id => id
                          | V.FUNAPP{id,...} => id
                          | V.FUNARG id => id 
                          (* ??? bug 228_abstypeInFunctor *)
                          | _ => raise bug "non strenv in functor arg"
            in
              (SC.sigCheck
                 {mode = SC.Trans,
                  strPath = argPath,
                  strEnv = argStrEnv,
                  specEnv = argSigEnv,
                  loc = loc
                 },
               argId
              )
              handle e => raise e
            end
        val _ = if EU.isAnyError () then raise SC.SIGCHECK else ()
        val argStrSymbol = mkSymbol "arg"
        val argStrLongsymbol = mkLongsymbol ["arg"]
        val bodyStrSymbol = mkSymbol "body"
        val bodyStrLongsymbol = mkLongsymbol ["body"]
        val tempEnv =
            VP.rebindStr 
              VP.SYSTEMUSE 
              (VP.rebindStr 
                 VP.SYSTEMUSE 
                 (V.emptyEnv, argStrSymbol, argStrEntry),
               bodyStrSymbol,
               {env=bodyEnv, 
                loc=Loc.noloc, 
                definedSymbol = [bodyStrSymbol],
                strKind=V.STRENV(StructureID.generate())}
              )
        val exnIdSubst = 
            ExnID.Set.foldr
            (fn (id, exnIdSubst) =>
                let
                  val newId = ExnID.generate()
                in
                  ExnID.Map.insert(exnIdSubst, id, newId)
                end
            )
            ExnID.Map.empty
            exnIdSet
(*
val _ = U.print "apply functor\n"
val _ = U.print "tempEnv before refresh\n"
val _ = U.printEnv tempEnv        
*)

        val ((tfvSubst, conIdSubst), tempEnv) =
            SC.refreshEnv copyPath (typidSet, exnIdSubst) tempEnv
            handle e => raise e
(*
val _ = U.print "tempEnv aftre refresh\n"
val _ = U.printEnv tempEnv        
*)
        val typIdSubst =
            TfvMap.foldri
            (fn (tfv1, tfv2, typIdSubst) =>
                let
                  val id1 = L.getId tfv1 
                  val id2 = L.getId tfv2
                in
                  TypID.Map.insert(typIdSubst, id1, id2)
                end
            )
            TypID.Map.empty
            tfvSubst

        val typidSet =
            TypID.Set.map
            (fn id => case TypID.Map.find(typIdSubst, id) of
                        SOME id => id
                      | NONE => id)
            typidSet

        val {env=argEnv, ...} = 
            case VP.checkStr(tempEnv, argStrLongsymbol) of
              SOME strEntry => strEntry
            | NONE => raise bug "impossible (2)"
        val {env=bodyEnv, ...} = 
            case VP.checkStr(tempEnv, bodyStrLongsymbol) of
              SOME env => env
            | NONE => raise bug "impossible (3)"

(*
        val {env=argEnv, strKind} = 
            case VP.findStr(tempEnv, ["arg"]) of
              SOME strEntry => strEntry
            | NONE => raise bug "impossible (2)"
        val {env=bodyEnv, ...} = 
            case VP.findStr(tempEnv, ["body"]) of
              SOME env => env
            | NONE => raise bug "impossible (3)"
*)

(*
val _ = U.print "before inst\n"
val _ = U.print "bodyEnv\n"
val _ = U.printEnv bodyEnv
val _ = U.print "argEnv\n"
val _ = U.printEnv argEnv
val _ = U.print "actualArgEnv\n"
val _ = U.printEnv actualArgEnv
val _ = U.print "\n"
*)
        val subst = instEnv nil (argEnv, actualArgEnv) S.emptySubst

(*
val _ = U.print "before subst\n"
val _ = U.print "bodyEnv\n"
val _ = U.printEnv bodyEnv
val _ = U.print "\n"
*)
        val bodyEnv = S.substEnv subst bodyEnv
                      handle e => raise e

(*
val _ = U.print "after inst\n"
val _ = U.print "bodyEnv\n"
val _ = U.printEnv bodyEnv
val _ = U.print "argEnv\n"
val _ = U.printEnv argEnv
val _ = U.print "actualArgEnv\n"
val _ = U.printEnv actualArgEnv
*)
        val bodyEnv = N.reduceEnv bodyEnv 
                      handle e => raise e

(*
val _ = U.print "bodyEnv after subst\n"
val _ = U.printEnv bodyEnv
*)

        val pathTfvListList = L.setLiftedTysEnv bodyEnv
                handle e => raise e

        val dummyIdfunArgTy = 
            Option.map (S.substTy subst) dummyIdfunArgTy
            handle e => raise e
        val dummyIdfunArgTy = 
            Option.map (N.reduceTy TvarMap.empty) dummyIdfunArgTy
            handle e => raise e

        val bodyVarExp = makeCastExp (tfvSubst, bodyVarExp) loc

        val (bodyVarList, _) = FU.varsInEnv  (bodyEnv, loc)
        (*  returnEnv : env for functor generated by this functor application
            patFields : patterns used in binding of variables generated by this application
            exntagDecls : rebinding exceptions generated by this application
         *)

        val (returnEnv, patFields, exntagDecls) =
            foldl
              (fn ((label, (bindPath, I.ICVAR {longsymbol, id=_})),
                   (returnEnv, patFields, exntagDecls)) =>
                  let
                    val newId = VarID.generate()
                    val varInfo = {id=newId, longsymbol=longsymbol}
(*
                    val newIdstatus = I.IDVAR (I.varInfoToIdInfo varInfo Loc.noloc)
*)
                    val loc = Symbol.longsymbolToLoc bindPath
                    val newIdstatus = I.IDVAR (I.varInfoToIdInfo varInfo loc)
                    val newPat = I.ICPATVAR_TRANS varInfo
                    val returnEnv = VP.rebindIdLongsymbol VP.SYSTEMUSE
                                      (returnEnv, bindPath, newIdstatus)
                  in
                    (returnEnv,
                     patFields @[(label, newPat)],
                     exntagDecls
                    )
                  end
                | (* need to check this case *)
                  ((label, (bindPath, I.ICEXN {longsymbol, ty, id})),
                   (returnEnv, patFields,exntagDecls)) =>
                  let
                    (* FIXME: here we generate env with IDEXN env and
                       exception tag E = x decl.
                     *)
                    val newVarId = VarID.generate()
                    val newExnId = ExnID.generate()
                    val exnInfo = {id=newExnId, longsymbol=longsymbol, ty=ty}
(*
                    val _ = VP.exnConAdd (V.EXN exnInfo)
*)
                    val varInfo = {id=newVarId, longsymbol=longsymbol}
                    val loc = Symbol.longsymbolToLoc bindPath
(*
                    val newIdstatus = I.IDEXN (I.exnInfoToIdInfo exnInfo Loc.noloc)
*)
                    val newIdstatus = I.IDEXN (I.exnInfoToIdInfo exnInfo loc)
                    val newPat = I.ICPATVAR_TRANS varInfo
                    val returnEnv =
                        VP.rebindIdLongsymbol VP.SYSTEMUSE 
                                              (returnEnv, bindPath, newIdstatus)
                    val exntagd =
                        I.ICEXNTAGD({exnInfo=exnInfo, varInfo=varInfo},loc)
                  in
                    (returnEnv,
                     patFields @[(label, newPat)],
                     exntagDecls
                    )
                  end
                | (* see: bug 061_functor.sml *)
                  ((label, (bindPath, I.ICEXVAR {longsymbol,...})),
                   (returnEnv, patFields, exntagDecls)) =>
                  let
                    val newId = VarID.generate()
                    val newVarInfo = {id=newId, longsymbol=longsymbol}
                    val loc = Symbol.longsymbolToLoc bindPath
(*
                    val newIdstatus = I.IDVAR (I.varInfoToIdInfo newVarInfo Loc.noloc)
*)
                    val newIdstatus = I.IDVAR (I.varInfoToIdInfo newVarInfo loc)
                    val newPat = I.ICPATVAR_TRANS newVarInfo
                    val returnEnv =
                        VP.rebindIdLongsymbol VP.SYSTEMUSE
                          (returnEnv, bindPath, newIdstatus)
                  in
                    (returnEnv,
                     patFields @[(label, newPat)],
                     exntagDecls
                    )
                  end
                | (* see: bug 061_functor.sml *)
                  ((label, (bindPath, I.ICEXN_CONSTRUCTOR (exnInfo as {longsymbol, ty, ...}))),
                   (returnEnv, patFields, exntagDecls)) =>
                  let
                    val newId = VarID.generate()
                    val newVarInfo = {id=newId, longsymbol = longsymbol}
                    val loc = Symbol.longsymbolToLoc bindPath
(*
                    val newIdstatus = I.IDVAR (I.varInfoToIdInfo newVarInfo Loc.noloc)
*)
                    val newIdstatus = I.IDVAR (I.varInfoToIdInfo newVarInfo loc)
                    val newPat = I.ICPATVAR_TRANS newVarInfo
                    val exntagDecl =
                        I.ICEXNTAGD ({exnInfo=exnInfo, varInfo=newVarInfo},
                                     loc)
                  in
                    (returnEnv,
                     patFields @[(label, newPat)],
                     exntagDecls @ [exntagDecl]
                    )
                  end
                | ((_, (bindPath, exp)), _) =>
                  (
                   U.print "body var\n";
                   U.printExp  exp;
                   U.print "\n";
                   raise bug "non var in bodyVarList"
                  )
              )
(*
CHECKME: bug 119            
              (1, V.emptyEnv, nil, nil)
*)
              (bodyEnv, nil, nil)
              (RecordLabel.tupleList bodyVarList)

        val resultPat =
            case patFields of
              nil => I.ICPATCONSTANT (A.UNITCONST, loc)
            | _ => I.ICPATRECORD {flex=false,fields = patFields,loc = loc}

        val actualDummyIdfun =
            case dummyIdfunArgTy of
              SOME dummyIdTy =>
              let
                val id = VarID.generate()
                val funargVarinfo = {id=id, longsymbol= DUMMYIDFUN}
              in
                SOME
                  (
                   I.ICFNM
                     ([{args=
                          [
                           I.ICPATTYPED
                             (
                              I.ICPATVAR_TRANS funargVarinfo,
                              dummyIdTy,
                              loc
                             )
                          ],
                        body=I.ICVAR funargVarinfo}
                      ],
                      loc)
                  )
              end
            | _ => NONE

        (* actual parameters passed to the functor. 
           This must corresponds to functor param polyArgPats (negative) 
           generated by evalFunArg.
         val (argExpList, _) = FU.varsInEnv ExnID.Set.empty loc argPath nil actualArgEnv
        *)

        fun exnTagsVarE path varE exnTags =
            SymbolEnv.foldli
            (fn (name, idstatus, exnTags) => 
                case idstatus of
                  I.IDVAR _ => exnTags
                | I.IDVAR_TYPED _ => exnTags
                | I.IDEXVAR _ => exnTags
                | I.IDEXVAR_TOBETYPED _ => exnTags (* this should be a bug *)
                | I.IDBUILTINVAR _ => exnTags
                | I.IDCON _ => exnTags
                | I.IDEXN _ => exnTags
                | I.IDEXNREP _ => exnTags
                | I.IDEXEXN _ => exnTags
                | I.IDEXEXNREP _ => exnTags
                | I.IDOPRIM _ => exnTags
                | I.IDSPECVAR _ => exnTags
                | I.IDSPECEXN _ => (path@[name])::exnTags
                | I.IDSPECCON _ => exnTags
            )
            exnTags
            varE
        fun exnTagsEnv path env exnTags =
            let
              val V.ENV{varE, tyE, strE} = env
              val exnTags = exnTagsVarE path varE exnTags
              val exnTags = exnTagsStrE path strE exnTags
            in
              exnTags
            end
        and exnTagsStrE path (V.STR envMap) exnTags =
            SymbolEnv.foldri
            (fn (name, {env, ...}, exnTags) => exnTagsEnv (path@[name]) env exnTags
            )
            exnTags
            envMap

        val exnTagPathList = exnTagsEnv nil argSigEnv nil
        val argExpList = FU.makeFunctorArgs loc exnTagPathList actualArgEnv
        val functorBody1 =
            case actualDummyIdfun of
              SOME dummyId => I.ICAPPM(bodyVarExp,[dummyId],loc)
            | NONE => bodyVarExp
        val functorBody2 =
            case argExpList of
              nil => functorBody1
            | _ => I.ICAPPM_NOUNIFY(functorBody1, argExpList, loc)
        val functorBody =
            case functorBody2 of
              I.ICAPPM_NOUNIFY _ => functorBody2
            | I.ICAPPM _ => functorBody2
            | _ => I.ICAPPM(functorBody2,
                            [I.ICCONSTANT (A.UNITCONST, loc)],
                            loc)
        val functorAppDecl = 
            I.ICVAL(Ty.emptyScopedTvars,[(resultPat, functorBody)],loc)

      in (* applyFunctor *)
        (renameEnv,
        {funId=functorId, 
         argId=argId,
         env=returnEnv, 
         icdecls=actualArgDecls @ [functorAppDecl] @ exntagDecls
        }
        )
      end
      handle 
      SC.SIGCHECK => 
      (renameEnv, 
       {funId=FunctorID.generate(),
        argId = StructureID.generate(),
        env=V.emptyEnv, 
        icdecls=nil}
      )
    | FunIDUndefind  =>
      (EU.enqueueError
         (loc, E.FunIdUndefined("450", {symbol = funName}));
       ( renameEnv,
         {funId=FunctorID.generate(),
          argId = StructureID.generate(),
          env=V.emptyEnv, 
          icdecls=nil}
       )
      )

(*
  fun bindBuiltinIdstatus loc path idstatus declsRev =
      case idstatus of
        I.IDBUILTINVAR {ty, primitive, defRange} =>
        let
          val icexp = I.ICBUILTINVAR{primitive=primitive,ty=ty,loc=loc}
          val newId = VarID.generate()
          val varInfo = {longsymbol=path,id=newId}
          val icpat = I.ICPATVAR_TRANS varInfo
          val valDecl = I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
          val idstatus = I.IDVAR varInfo
        in
          (idstatus, valDecl::declsRev)
        end
      | _ => (idstatus, declsRev)

  fun bindBuiltinVarE loc path varE declsRev =
      SymbolEnv.foldli
      (fn (name, idstatus, (varE, declsRev)) =>
          let
            val (idstatus, declsRev) = bindBuiltinIdstatus loc (path@[name]) idstatus declsRev
            val varE = SymbolEnv.insert(varE, name, idstatus)
          in
            (varE, declsRev)
          end
      )
      (SymbolEnv.empty, declsRev)
      varE
      
  fun bindBuiltinStrE loc path strE declsRev =
      SymbolEnv.foldli 
      (fn (name, {env, strKind}, (strE, declsRev)) =>
          let
            val (env, declsRev) = bindBuiltinEnv loc (path@[name]) env declsRev
            val strE = SymbolEnv.insert(strE, name, {env=env, strKind=strKind})
          in
            (strE, declsRev)
          end
      )
      (SymbolEnv.empty, declsRev)
      strE
      
  and bindBuiltinEnv loc path (V.ENV{varE, tyE, strE=V.STR envMap}) declsRev =
      let
        val (varE, declsRev) = bindBuiltinVarE loc path varE declsRev
        val (envMap, declsRev) = bindBuiltinStrE loc path envMap declsRev
      in
        (V.ENV{varE=varE, tyE=tyE, strE=V.STR envMap}, declsRev)
      end
*)

  fun evalFunctor renameEnv {topEnv, version} {pltopdec, pitopdec} =
      let
        val {name=nameSymbol,
             argStrName= argStrNameSymbol, 
             argSig,
             body, 
             loc=defLoc} = pltopdec
        val startTypid = TypID.generate()
        val 
        {
         argSigEnv,
         argStrEntry,
         extraTvars,
         polyArgPats,  (* functor argument variables (negative) *)
         exnTagDecls,  
         dummyIdfunArgTy,
         firstArgPat,
         tfvDecls
        } = FU.evalFunArg (topEnv, argSig, defLoc)

        val topArgEnv = VP.singletonStr VP.FUNCTOR_ARG (argStrNameSymbol, argStrEntry)

        val evalEnv = VP.topEnvWithEnv (topEnv, topArgEnv)
        val (renameEnv, {env=returnEnv,strKind, ...}, bodyDecls) = 
            evalPlstrexp renameEnv evalEnv nilPath body

(*
val _ = U.print "evalFunctor returnEnv\n"
val _ = U.printEnv returnEnv
val _ = U.print "bodyDecls\n"
val _ = map (fn x=> (U.printDecl x; U.print "\n")) bodyDecls
*)
        val (bindDecls, returnEnv) =
            case pitopdec of
              NONE => (nil, returnEnv)
            | SOME 
                {functorSymbol,
                 param={strSymbol, sigexp=specArgSig},
                 strexp=specBodyStr,
                 loc=specLoc} => 
              let
                val topArgEnv = VP.singletonStr VP.FUNCTOR_ARG (strSymbol, argStrEntry)
                val evalEnv = VP.topEnvWithEnv (topEnv, topArgEnv)
              in
                CP.checkProvideFunctorBody 
                  {functorSymbol=nameSymbol,
                   specLoc=specLoc,
                   defLoc=defLoc,
                   topEnv=topEnv,
                   evalEnv=evalEnv,
                   argSigEnv=argSigEnv, 
                   specArgSig=specArgSig,
                   returnEnv=returnEnv,
                   specBodyStr=specBodyStr}
              end
(*
val _ = U.print "evalFunctor returnEnv after checkProvideFuncgtorBody\n"
val _ = U.printEnv returnEnv
val _ = U.print "bodyDecls\n"
val _ = map (fn x=> (U.printDecl x; U.print "\n")) bodyDecls
val _ = U.print "bindDecls\n"
val _ = map (fn x=> (U.printDecl x; U.print "\n")) bindDecls
*)

(*
        (* bug 246_builtIn *)
        val (returnEnv, declsRev) = bindBuiltinEnv defLoc nil returnEnv nil
        val bodyDecls = bodyDecls @ (List.rev declsRev)
*)

(*
val _ = map (fn x=> (U.printDecl x; U.print "\n")) bodyDecls
*)

        val bodyDecls = bodyDecls @ bindDecls

        val (allVars, exnIdSet) = FU.varsInEnv (returnEnv, defLoc)

(*
val _ = U.print "evalFunctor: allVars\n"
val _ = app (fn (x,_) => (U.printLongsymbol x; U.print " \n")) allVars
val _ = U.print "\n"
*)

        val typidSetArg = FU.typidSet (#env argStrEntry)
        val typidSet = FU.typidSet returnEnv
        val typidSet = TypID.Set.union(typidSetArg, typidSet)

        val allVars = map #2 allVars
        (* FIXME (not a bug):
           The following is to restrict the typids to be refreshed
           are those that are created in the functor body.
           Not very elegant. Need to review.
         *)
        val typidSet =
            TypID.Set.filter
            (fn id => 
                case TypID.compare(id, startTypid) of
                  GREATER => true
                | _ => false)
            typidSet
        val bodyExp =
            case allVars of
              nil => I.ICCONSTANT (A.UNITCONST, defLoc)
            | _ => I.ICRECORD (RecordLabel.tupleList allVars, defLoc)
        val functorExp1 =
            case polyArgPats of
              nil => I.ICLET (exnTagDecls @ bodyDecls, bodyExp, defLoc)
            | _ => 
              I.ICFNM1_POLY
                (polyArgPats,  (* functor argument variables (negative) *)
                 I.ICLET (exnTagDecls @ bodyDecls, bodyExp, defLoc),
                 defLoc)
        val functorExp =
            case firstArgPat of
              SOME pat => I.ICFNM1([pat], functorExp1, defLoc)
            | NONE => 
              (case functorExp1 of
                 I.ICLET _ =>
                 let
                   val varId = VarID.generate()
                   val longsymbol = Symbol.mkLongsymbol ["unitVar"] defLoc
                   val patVarInfo ={longsymbol=longsymbol, id=varId}
                 in
                   I.ICFNM1
                     (
                      [(patVarInfo, [BT.unitITy])],
                      functorExp1,
                      defLoc
                     )
                 end
               | _ => functorExp1
              )

        val functorExpVar = {longsymbol= [FUNCTORPREFIX, nameSymbol],
                             id=VarID.generate()}
        val functorExpVarExp = I.ICVAR functorExpVar
(*
        val version = case SymbolEnv.find(#FunE version, name) of
                        NONE => NONE
                      | SOME {version,...} => I.incVersion version
*)
        val functorDecl =
            I.ICVAL(map (fn tvar=>(tvar, I.UNIV T.emptyProperties)) extraTvars,
                    [(I.ICPATVAR_TRANS functorExpVar,functorExp)],
                    defLoc)
        val funEEntry:V.funEEntry =
            {id = FunctorID.generate(),
             loc = defLoc,
             version = version,
             argSigEnv = argSigEnv,
             argStrEntry = argStrEntry,
             argStrName = argStrNameSymbol,
             dummyIdfunArgTy = dummyIdfunArgTy,
             polyArgTys = map (fn (pat, ty) => ty) polyArgPats,
             typidSet=typidSet,
             exnIdSet=exnIdSet,
             bodyEnv = returnEnv,
             bodyVarExp = functorExpVarExp
            }
        val funE = VP.rebindFunE VP.BIND_FUNCTOR (SymbolEnv.empty, nameSymbol, funEEntry)
        val returnTopEnv = VP.topEnvWithFunE(V.emptyTopEnv, funE)
(*
val _ = U.print "eval functor returnTopEnv\n"
val _ = U.printTopEnv returnTopEnv
val _ = U.print "\n"
*)
      in (* evalFunctor *)
        (renameEnv, returnTopEnv, tfvDecls@[functorDecl])
      end

  fun evalPltopdec (renameEnv:renameEnv) {topEnv, version} pltopdec =
      case pltopdec of
        PI.TOPDECSTR (plstrdec, loc) =>
        let
          val (renameEnv, env, icdeclList) = 
              evalPlstrdec (renameEnv:renameEnv) topEnv nilPath plstrdec
        in
          (renameEnv, VP.topEnvWithEnv(V.emptyTopEnv, env), icdeclList)
        end
      | PI.TOPDECSIG (symbolPlsigexpList, loc) =>
        let
          val _ = EU.checkSymbolDuplication
                    #1
                    symbolPlsigexpList
                    (fn s => E.DuplicateSigname("460",s))
          val sigE =
              foldl
                (fn ((symbol, plsig), sigE) =>
                    let
                      val sigEEntry = Sig.evalPlsig topEnv plsig
                    in
                      VP.rebindSigE VP.BIND_SIG (sigE, symbol, sigEEntry)
                    end
                )
                SymbolEnv.empty
                symbolPlsigexpList
        in
          (renameEnv, VP.topEnvWithSigE(V.emptyTopEnv, sigE), nil)
        end
      | PI.TOPDECFUN (functordeclList,loc) =>
        let
          val _ = EU.checkSymbolDuplication
                    (fn {pltopdec=x, pitopdec} => #name x)
                    functordeclList (fn s => E.DuplicateFunctor("470",s))
        in
          foldl
            (fn (functordecl, (renameEnv, returnTopEnv, icdecList)) =>
                let
                  val (renameEnv, topEnv1, icdecList1) =
                      evalFunctor renameEnv {topEnv=topEnv, version=version} functordecl
                  val returnTopEnv =
                      VP.topEnvWithTopEnv(returnTopEnv, topEnv1)
                in
                  (renameEnv, returnTopEnv, icdecList@icdecList1)
                end
            )
            (renameEnv, V.emptyTopEnv, nil)
            functordeclList
        end

  fun evalPltopdecList (renameEnv:renameEnv) {topEnv, version} pltopdecList =
      foldl
        (fn (pltopdec, (renameEnv, returnTopEnv, icdecList)) =>
          let
            val evalTopEnv = VP.topEnvWithTopEnv (topEnv, returnTopEnv)
            val (renameEnv, returnTopEnv1, icdecList1) =
                evalPltopdec (renameEnv:renameEnv) {topEnv=evalTopEnv, version=version} pltopdec
            val returnTopEnv = VP.topEnvWithTopEnv(returnTopEnv, returnTopEnv1)
          in
            (renameEnv, returnTopEnv, icdecList @ icdecList1)
          end
        )
        (renameEnv, V.emptyTopEnv, nil)
        pltopdecList

(*
  fun generateExportVar ({Env,FunE,...}:V.topEnv) loc =
      let
        fun exportsInVarE path varE =
            List.mapPartial
              (fn (vid, idstatus) =>
                  case idstatus of
                    I.IDVAR id =>
                    SOME (I.ICEXPORTTYPECHECKEDVAR
                            ({path=path@[vid], id=id}, loc))
                  | I.IDEXN {id,ty} =>
                    SOME (I.ICEXPORTEXN ({path=path@[vid], id=id, ty=ty}, loc))
                  | _ => NONE)
              (SymbolEnv.listItemsi varE)
        fun exportsInStrE path (V.STR strE) =
            List.concat
              (map (fn (strid, {env,...}) => exportsInEnv (path@[strid]) env)
                   (SymbolEnv.listItemsi strE))
        and exportsInEnv path (V.ENV {varE, tyE, strE}) =
            exportsInVarE path varE @ exportsInStrE path strE
      in
        exportsInEnv nil Env
      end
*)

(*
 2012-07-11 ohori: bug 205_exnExport.sml
  # exception A of int
  > exception B = A;
  exception B of int
  # exception C = A;
  Compiler bug:compileDecl: RCEXPORTEXN
This is caused due to the following:
 1. exn is exported only once.
 2. exn replication is not exported.
So the 
  exception A of int
  exception B = A
will generate:
  the decls:
    export exception B
  and environment:
     A: exn e12 (local id)
     B: external exn B
The correct output should be:
  decl:
    export exception B (or A)
  env:
     A: external exn B (or A)
     B: external exn B (or A)
To do this, we should keep track of the exported exn id with its external name.
So we change exnSet to path exnMap in genExportIdstatus
*)
  fun genExport (version, {FunE=RFunE,Env=REnv, SigE=RSigE}) =
      let
        fun genExportIdstatus exnInfoList exnPathMap exLongsymbol version idstatus icdecls = 
            case idstatus of
              I.IDVAR {id, longsymbol=_, defRange} => 
              (exnInfoList, exnPathMap,
               I.IDEXVAR_TOBETYPED 
                 {longsymbol=exLongsymbol,version=version,id=id, defRange = Loc.noloc}, 
               I.ICEXPORTTYPECHECKEDVAR
                 ({longsymbol=exLongsymbol, version=version, id=id})::icdecls)
            | I.IDVAR_TYPED {id, longsymbol, ty, defRange} => 
              (exnInfoList, exnPathMap,
               I.IDEXVAR{exInfo={used=ref false, longsymbol=exLongsymbol, version=version, ty=ty}, 
                         defRange = Loc.noloc, internalId = SOME id},
               I.ICEXPORTTYPECHECKEDVAR
                 ({longsymbol=exLongsymbol, version=version, id=id})::icdecls)
            | I.IDEXVAR _ => (exnInfoList, exnPathMap, idstatus, icdecls)
            | I.IDEXVAR_TOBETYPED _ => (exnInfoList, exnPathMap, idstatus, icdecls)
            (* this should be a bug *)
            | I.IDBUILTINVAR _  => (exnInfoList, exnPathMap, idstatus, icdecls)
            | I.IDCON _ => (exnInfoList, exnPathMap, idstatus, icdecls)
            | I.IDEXN (exnInfo as {id, longsymbol=_, ty, defRange}) =>
              (case ExnID.Map.find(exnPathMap, id) of
                 NONE => 
                 let
                   val exInfo = {used = ref false, longsymbol=exLongsymbol,version=version, ty=ty}
                 in
                   (exnInfo :: exnInfoList, 
                    ExnID.Map.insert(exnPathMap, id, {longsymbol=exLongsymbol, version=version}),
                    I.IDEXEXN (I.exInfoToIdInfo exInfo Loc.noloc),
                    I.ICEXPORTEXN {exInfo=exInfo, id=id} :: icdecls)
                 end
               | SOME {longsymbol, version} =>
                 (exnInfoList, exnPathMap,
                  I.IDEXEXNREP {used = ref false, longsymbol=longsymbol, defRange = Loc.noloc,
                                version=version, ty=ty}, 
                  icdecls)
              )
            | I.IDEXNREP (exnInfo as {id, longsymbol=_, ty, defRange}) =>
              (case ExnID.Map.find(exnPathMap, id) of
                 NONE => 
                 let
                   val exInfo = {used = ref false, longsymbol=exLongsymbol,version=version, ty=ty}
                 in
                   (exnInfo::exnInfoList, 
                    ExnID.Map.insert(exnPathMap, id, {longsymbol=exLongsymbol, version=version}), 
                    I.IDEXEXN (I.exInfoToIdInfo exInfo Loc.noloc),
                    I.ICEXPORTEXN ({exInfo=exInfo, id=id})
                    :: icdecls)
                 end
               | SOME {longsymbol=exLongsymbol, version} =>
                 (exnInfoList, exnPathMap,
                  I.IDEXEXNREP {used = ref false, longsymbol=exLongsymbol, defRange = Loc.noloc,
                                version=version, ty=ty},
                  icdecls)
              )
            | I.IDEXEXN exInfo => 
              let
                val idstatus = I.IDEXEXNREP (exInfo # {defRange = Loc.noloc})
              in
                (exnInfoList, exnPathMap, idstatus, icdecls)
              end
            | I.IDEXEXNREP _ => (exnInfoList, exnPathMap, idstatus, icdecls)
            | I.IDOPRIM _ => (exnInfoList, exnPathMap, idstatus, icdecls)
            | I.IDSPECVAR _ => raise bug "IDSPECVAR in mergeIdstatus"
            | I.IDSPECEXN _ => raise bug "IDSPECEXN in mergeIdstatus"
            | I.IDSPECCON _ => raise bug "IDSPECCON in mergeIdstatus"
        fun genExportVarE exnInfoList exnPathMap path (version, RVarE) icdecls =
            SymbolEnv.foldli
              (* we should use foldli here to give the first exn to be the one that
                    should be exported.
               *)
              (fn (name, idstatus, (exnInfoList, exnPathMap, varE, icdecls)) =>
                  let
                    val exLongsymbol = path@[name]
                    val (exnInfoList, exnPathMap, idstatus, icdecls) = 
                        genExportIdstatus 
                          exnInfoList exnPathMap exLongsymbol version idstatus icdecls
                  in
                    (exnInfoList, exnPathMap, SymbolEnv.insert(varE, name, idstatus), icdecls)
                  end
              )
              (exnInfoList, exnPathMap, SymbolEnv.empty, icdecls)
              RVarE
        fun genExportEnvMap exnInfoList exnPathMap path (version, REnvMap) icdecls =
            SymbolEnv.foldli 
              (* we should use foldli here to give the first exn to be the one that
                    should be exported.
               *) 
              (fn (name, {env=REnv, strKind, ...},
                   (exnInfoList, exnPathMap, envMap, icdecls)) =>
                  let
                    val (exnInfoList, exnPathMap, env, icdecls) = 
                        genExportEnv exnInfoList exnPathMap (path@[name]) (version, REnv) icdecls
                  in
                    (exnInfoList, exnPathMap, 
                     SymbolEnv.insert(envMap, name, 
                                      {env=env, strKind=strKind, definedSymbol = path,
                                       loc=Loc.noloc}), 
                     icdecls)
                  end
              )
              (exnInfoList, exnPathMap, SymbolEnv.empty, icdecls)
              REnvMap
        and genExportEnv exnInfoList exnPathMap path
                         (version, V.ENV{varE=RVarE, strE=V.STR REnvMap, tyE}) 
                         icdecls =
            let
              val (exnInfoList, exnPathMap, varE, icdecls) = 
                  genExportVarE exnInfoList exnPathMap path (version, RVarE) icdecls
              val (exnInfoList, exnPathMap, envMap, icdecls) = 
                  genExportEnvMap exnInfoList exnPathMap path (version, REnvMap) icdecls
            in
              (exnInfoList, exnPathMap, V.ENV{varE=varE, strE=V.STR envMap, tyE=tyE}, icdecls)
            end
        fun genExportFunEEntry (version, RFunEntry:V.funEEntry) icdecls =
            let
              val {id,
                   loc,
                   version=_,
                   argSigEnv,
                   argStrEntry,
                   argStrName,
                   dummyIdfunArgTy,
                   polyArgTys,
                   typidSet,
                   exnIdSet,
                   bodyEnv,
                   bodyVarExp
                  }  = RFunEntry
(* 2012-7-10 ohori bug 204
              val bodyVarExp = 
*)
              val exBodyVarExp = 
                  case bodyVarExp of
                    I.ICVAR {longsymbol, id} =>
                    let
                      val exInfo = {used = ref false, longsymbol=longsymbol, version=version}
                    in
                      I.ICEXVAR_TOBETYPED {exInfo=exInfo, id=id, longsymbol=longsymbol}
                    end
                  | _ => raise bug "non var bodyVarExp"
              val funEEntry=
                  {id=id,
                   loc = loc,
                   version = version,
                   argSigEnv = argSigEnv,
                   argStrEntry = argStrEntry,
                   argStrName = argStrName,
                   dummyIdfunArgTy = dummyIdfunArgTy,
                   polyArgTys = polyArgTys,
                   typidSet = typidSet,
                   exnIdSet = exnIdSet,
                   bodyEnv = bodyEnv,
                   bodyVarExp = exBodyVarExp
                  }
              val icdecl =
                  case bodyVarExp of 
                    I.ICVAR {id, longsymbol} => 
                    I.ICEXPORTTYPECHECKEDVAR
                      {longsymbol=longsymbol, version=version, id=id}
                  | _ => raise bug "nonvar in bodyVarExp"
            in
              (funEEntry, icdecl::icdecls)
            end
        fun genExportFunE (version, RFunE) icdecls =
            SymbolEnv.foldri
            (fn (name, RFunEEntry, (funE, icdecls)) =>
                let
                  val (funEEntry, icdecls) =
                         genExportFunEEntry (version, RFunEEntry) icdecls
                in
                  (SymbolEnv.insert(funE, name, funEEntry), icdecls)
                end
            )
            (SymbolEnv.empty, icdecls)
            RFunE

        val (FunE, icdecls) = genExportFunE (version, RFunE) nil
        val (exnInfoList, _, Env, icdecls) = 
            genExportEnv nil ExnID.Map.empty nil (version, REnv) icdecls
      in
        (exnInfoList, 
         {FunE=FunE, Env=Env, SigE=RSigE}, 
         List.rev icdecls
         (* icdels are const in reverse order of traversal; 
            no significance in the order. Here we take the
            alphabetical order generated by maps.
          *)
        )
      end

  fun clearUsedflagIdstatus idstatus = 
      case idstatus of
        I.IDEXVAR {exInfo,...} => #used exInfo := false
      | I.IDOPRIM {used,...} => used := false
      | I.IDEXEXN exInfo => #used exInfo := false
      | I.IDEXEXNREP exInfo  => #used exInfo := false
      | _ => ()
  fun clearUsedflagVarE varE = 
      SymbolEnv.app clearUsedflagIdstatus varE
  fun clearUsedflagEnv (V.ENV {varE, tyE, strE}) = 
      (clearUsedflagVarE varE;
       clearUsedflagStrE strE)
  and clearUsedflagStrE (V.STR strEntryMap) =
      SymbolEnv.app (fn {env, strKind, ...} => clearUsedflagEnv env) strEntryMap

  fun clearUsedflag {Env, FunE, SigE} =
      clearUsedflagEnv Env

  fun clearUsedflagOfSystemDecl ({Env,...}:V.topEnv) icdecl =
      let
        val longsymbol =
            case icdecl of 
              I.ICEXTERNVAR {longsymbol, ...} => longsymbol
            | I.ICEXTERNEXN {longsymbol, ...} => longsymbol
            | I.ICBUILTINEXN {longsymbol, ...} => longsymbol
            | _ => raise Bug.Bug "clearUsedflagOfSystemDecl"
        val idstatus = 
            case VP.findId (Env, longsymbol) of
              SOME (sym, idstatus) => idstatus
            | NONE => raise bug  (Symbol.longsymbolToString longsymbol
                                  ^
                                  "not found in clearUsedflagOfSystemDecl")
      in
        clearUsedflagIdstatus idstatus
      end
  fun externExnSetSystemdecls systemDecls externExnSet =
      foldl
        (fn (idstatus, externExnSet) =>
            case idstatus of
              I.ICEXTERNEXN (exInfo as {longsymbol,version,...}) => 
              let
                val longsymbol = setVersion(longsymbol, version)
              in
                LongsymbolEnv.insert(externExnSet, longsymbol, exInfo)
              end
            | I.ICBUILTINEXN {longsymbol, ty} => 
              LongsymbolEnv.insert
                (externExnSet, longsymbol,
                 {used = ref false, longsymbol=longsymbol, ty=ty, version=I.SELF})
            | _ => externExnSet
        )
        externExnSet
        systemDecls
  local
    fun setUsedflagInOverloadMatch (env:V.topEnv) match =
        case match of
          T.OVERLOAD_EXVAR {exVarInfo={path, ty}, instTyList} =>
          let
            val idstatus = 
                case VP.findId (#Env env, path) of
                  SOME (sym, idstatus) => idstatus
                | NONE => raise bug  (Symbol.longsymbolToString path
                                      ^
                                      ": not found in clearUsedflagOfSystemDecl")
          in
            case idstatus of
              I.IDEXVAR {exInfo = {used, ...}, ...} => used := true
            | _ => raise Bug.Bug "non idexvar in setUsedflagInOverloadMatch"
          end
        | T.OVERLOAD_PRIM {primInfo, instTyList} =>
          Option.app (app (setUsedflagInTy env)) instTyList
        | T.OVERLOAD_CASE (ty, map) =>
          (setUsedflagInTy env ty;
           TypID.Map.app (setUsedflagInOverloadMatch env) map)
    and setUsedflagInOprimSelector env {match, ...} =
        setUsedflagInOverloadMatch env match
    and setUsedflagInSingletonTy env sty =
        case sty of
          T.INSTCODEty selector => setUsedflagInOprimSelector env selector
        | T.INDEXty (label, ty) => setUsedflagInTy env ty
        | T.SIZEty ty => setUsedflagInTy env ty
        | T.TAGty ty => setUsedflagInTy env ty
        | T.REIFYty ty => setUsedflagInTy env ty
    and setUsedflagInKind env (T.KIND {tvarKind, properties, dynamicKind}) =
        case tvarKind of
          T.OCONSTkind tys => app (setUsedflagInTy env) tys
        | T.OPRIMkind {instances, operators} =>
          (app (setUsedflagInTy env) instances;
           app (setUsedflagInOprimSelector env) operators)
        | T.UNIV => ()
        | T.REC tyMap => RecordLabel.Map.app (setUsedflagInTy env) tyMap
    and setUsedflagInTy env ty =
        case ty of
          T.SINGLETONty sty => setUsedflagInSingletonTy env sty
        | T.BACKENDty _ => raise Bug.Bug "setUsedflagInTy: BACKENDty"
        | T.ERRORty => raise Bug.Bug "setUsedflagInTy: ERRORty"
        | T.DUMMYty (id, kind) => setUsedflagInKind env kind
        | T.EXISTty (id, kind) => setUsedflagInKind env kind
        | T.TYVARty (ref (T.TVAR _)) => raise Bug.Bug "setUsedflagInTy: TYVARty"
        | T.TYVARty (ref (T.SUBSTITUTED ty)) => setUsedflagInTy env ty
        | T.BOUNDVARty _ => ()
        | T.FUNMty (argTys, retTy) => app (setUsedflagInTy env) (retTy::argTys)
        | T.RECORDty tyMap => RecordLabel.Map.app (setUsedflagInTy env) tyMap
        | T.CONSTRUCTty {tyCon, args} => app (setUsedflagInTy env) args
        | T.POLYty {boundtvars, constraints, body} =>
          (BoundTypeVarID.Map.app (setUsedflagInKind env) boundtvars;
           setUsedflagInTy env body)
    fun setUsedflagsExInfo env {ty, ...} =
        case ty of
          I.INFERREDTY ty => setUsedflagInTy env ty
        | _ => ()
    fun setUsedflagsIdstatus env idstatus =
        case idstatus of
          I.IDEXVAR {exInfo =exInfo as  {used = ref true,...}, ...} =>
          setUsedflagsExInfo env exInfo
        | I.IDEXEXN (exInfo as {used = ref true,...}) => setUsedflagsExInfo env exInfo
        | I.IDEXEXNREP (exInfo as {used = ref true,...}) => setUsedflagsExInfo env exInfo
        | _ => ()
    fun setUsedflagsVarE env varE =
        SymbolEnv.app (setUsedflagsIdstatus env) varE
    and setUsedflagsEnv env (V.ENV {varE, tyE, strE}) =
        (setUsedflagsVarE env varE;
         setUsedflagsStrE env strE)
    and setUsedflagsStrE topEnv (V.STR strEntryMap) =
        SymbolEnv.app
          (fn {env, strKind = V.SIGENV _, ...} => ()
            | {env, strKind = V.FUNAPP _, ...} => setUsedflagsEnv topEnv env
            | {env, strKind = V.STRENV _, ...} => setUsedflagsEnv topEnv env
            | {env, strKind = V.FUNARG _, ...} => setUsedflagsEnv topEnv env
          )
          strEntryMap
    fun setUsedflagsFunE env (funE:V.funE) =
        SymbolEnv.app
          (fn {bodyVarExp, ...} =>
              (case bodyVarExp of
                 I.ICEXVAR {exInfo = exInfo as {used = ref true,...}, ...} => 
                 setUsedflagsExInfo env exInfo
               | _  => ()))
          funE
  in
  fun setUsedflagsOfOverloadInstances (topEnv as {Env, FunE, SigE}) =
      (setUsedflagsEnv topEnv Env;
       setUsedflagsFunE topEnv FunE)
  end (* local *)

  fun genExterndeclsIdstatus (externExnSet,externVarSet) idstatus icdecls =
      case idstatus of
        I.IDEXVAR {exInfo = exInfo as {used = ref true, ...}, internalId, defRange}  => 
        ((externExnSet, addVarExSet (externVarSet, exInfo)), icdecls)
(*
        before used := false   (* avoid duplicate declarations *)
*)
      | I.IDOPRIM {used as ref true, overloadDef,...} => 
        ((externExnSet,externVarSet), overloadDef::icdecls)
(*
        before used := false   (* avoid duplicate declarations *)
*)
      | I.IDEXEXN idInfo =>
        let
          val exInfo = I.idInfoToExExnInfo idInfo
        in
        if !Control.importAllExceptions orelse !(#used exInfo)
        then
          if exSetMember(externExnSet, exInfo) 
          then ((externExnSet,externVarSet), icdecls)
          else 
            ((addExnExSet(externExnSet, exInfo),externVarSet),
             I.ICEXTERNEXN exInfo :: icdecls
            )
(*
            before used := false   (* avoid duplicate declarations *)
*)
        else ((externExnSet,externVarSet), icdecls)
        end
      | I.IDEXEXNREP idInfo => 
        let
          val exInfo = I.idInfoToExExnInfo idInfo
        in
        if !Control.importAllExceptions orelse ! (#used exInfo)
        then
          if exSetMember(externExnSet, exInfo) 
          then ((externExnSet,externVarSet), icdecls)
          else 
            ((addExnExSet(externExnSet, exInfo),externVarSet),
             I.ICEXTERNEXN exInfo :: icdecls
            )
(*
            before used := false   (* avoid duplicate declarations *)
*)
        else ((externExnSet,externVarSet), icdecls)
        end
      | _ => ((externExnSet,externVarSet), icdecls)
  fun genExterndeclsVarE (externExnSet,externVarSet) varE icdecls =
      SymbolEnv.foldr
      (fn (idstatus, ((externExnSet,externVarSet), icdecls)) => 
          genExterndeclsIdstatus (externExnSet,externVarSet) idstatus icdecls)
      ((externExnSet,externVarSet),icdecls)
      varE
  fun genExterndeclsEnv (externExnSet,externVarSet) (V.ENV {varE, tyE, strE}) icdecls =
      let
        val ((externExnSet,externVarSet), icdecls) = 
            genExterndeclsVarE (externExnSet,externVarSet) varE icdecls
        val ((externExnSet,externVarSet), icdecls) = 
            genExterndeclsStrE (externExnSet,externVarSet) strE icdecls
      in
        ((externExnSet,externVarSet), icdecls)
      end
  and genExterndeclsStrE (externExnSet,externVarSet) (V.STR strEntryMap) icdecls =
      SymbolEnv.foldr
      (fn ({env, strKind, ...}, ((externExnSet,externVarSet), icdecls)) =>
           case strKind of 
             V.SIGENV _ => ((externExnSet,externVarSet),icdecls)
(* 2012-7-10 ohori : bug 204
           | V.FUNAPP _ => ((externExnSet,externVarSet), icdecls)
*)
           | V.FUNAPP _ => genExterndeclsEnv (externExnSet,externVarSet) env icdecls
           | V.STRENV _ => genExterndeclsEnv (externExnSet,externVarSet) env icdecls
           | V.FUNARG _ => genExterndeclsEnv (externExnSet,externVarSet) env icdecls
      )
      ((externExnSet,externVarSet), icdecls)
      strEntryMap
      
  fun genExterndeclsFunE (externExnSet,externVarSet) (funE:V.funE) icdecls =
      SymbolEnv.foldr
      (fn ({version, bodyVarExp,...}, ((externExnSet,externVarSet), icdecls)) =>
          (case bodyVarExp of
             I.ICEXVAR {exInfo = exInfo as {used = ref true,...}, longsymbol} =>
             if exSetMember(externExnSet, exInfo) 
             then ((externExnSet,externVarSet), icdecls)
             else 
               ((addExnExSet(externExnSet, exInfo), externVarSet),
                I.ICEXTERNVAR exInfo  :: icdecls)
           | _ => ((externExnSet,externVarSet), icdecls))
(*
           | _ => raise bug "nonVAR bodyVarExp in funEEntry")
*)
      )
      ((externExnSet,externVarSet), icdecls)
      funE

  fun genExterndecls (externExnSet,externVarSet) {Env, FunE, SigE} = 
      let
        val ((externExnSet,externVarSet), icdecls) = 
            genExterndeclsEnv (externExnSet,externVarSet) Env nil
        val ((externExnSet,externVarSet), icdecls) = 
            genExterndeclsFunE (externExnSet,externVarSet) FunE icdecls
      in
        ((externExnSet,externVarSet), icdecls)
      end

  fun reduceTopEnv ({Env, FunE, SigE}:V.topEnv) =
      let
        val env = N.reduceEnv Env
        val FunE = reduceFunE FunE
        val SigE = 
            SymbolEnv.map
              (fn (sigEntry as {env,...}) =>
                  sigEntry # {env = N.reduceEnv env}) 
              SigE
      in
        {Env=Env, FunE=FunE, SigE=SigE}
      end
  and reduceFunE funE =
      SymbolEnv.map reduceFunEEntry funE
  and reduceFunEEntry
        {id,
         loc,
         version,
         argSigEnv,
         argStrEntry = {env=argEnv, strKind=argStrKind, definedSymbol,
                        loc=argLoc},
         argStrName,
         dummyIdfunArgTy,
         polyArgTys,
         typidSet,
         exnIdSet,
         bodyEnv,
         bodyVarExp
        } : V.funEEntry =
       {id = id,
        loc = loc,
        version = version,
        argSigEnv = N.reduceEnv argSigEnv,
        argStrEntry = {env=N.reduceEnv argEnv, definedSymbol = definedSymbol,
                       strKind=argStrKind, loc=argLoc},
        argStrName = argStrName,
        dummyIdfunArgTy = dummyIdfunArgTy,
        polyArgTys = polyArgTys,
        typidSet = typidSet,
        exnIdSet = exnIdSet,
        bodyEnv = N.reduceEnv bodyEnv,
        bodyVarExp = bodyVarExp
       } : V.funEEntry

in (* local *)

  fun unionRequiredTopEnv interfaceEnv topEnv requiredIds =
      foldl
        (fn ({id,loc}, evalTopEnv) =>
            case InterfaceID.Map.find(interfaceEnv, id) of
              SOME {topEnv,...} => 
              VP.unionTopEnv "205" (evalTopEnv, topEnv)
            | NONE => raise bug "unbound interface id"
        )
        topEnv
        requiredIds

(*
  datatype exnCon = EXN of I.exnInfo | EXEXN of I.exInfo
*)

  fun nameEval source {topEnv, version, systemDecls} compileUnit =
      let
        val _ = EU.initializeErrorQueue ()
        val _ = Ty.resetFreeTvarEnv ()
(*
val _ = U.print "*** nameEval\n"
val _ = U.print "compileUnit\n"
val _ = U.printCompileUnit compileUnit
val _ = U.print "\n"
*)
        val compileUnitSpliced 
         as {interface,
             topdecsInclude,
             topdecsSource} =
            SpliceProvicdeFundecl.spliceProvideFundecl compileUnit
(*
val _ = U.print "compileUnitSpliced\n"
val _ = U.printCompileUnitSpliced compileUnitSpliced
val _ = U.print "\n"
*)
        val {interfaceDecs, requiredIds, locallyRequiredIds, provideTopdecs} =
            case interface of
              SOME x => x
            | NONE => {interfaceDecs = nil,
                       requiredIds = nil,
                       locallyRequiredIds = nil,
                       provideTopdecs = nil}

        val interfaceEnv = EI.evalInterfaces topEnv interfaceDecs

        (* for error checking *)
        val totalTopEnv =
            InterfaceID.Map.foldl
            (fn ({topEnv,...}, totalEnv) => 
                VP.unionTopEnv "206" (totalEnv, topEnv)
            )
            V.emptyTopEnv
            interfaceEnv

        val evalTopEnvProvide =
            unionRequiredTopEnv interfaceEnv topEnv requiredIds
        val evalTopEnv =
            unionRequiredTopEnv interfaceEnv evalTopEnvProvide locallyRequiredIds

        (* for error checking *)
        val (_, topEnv, _) =
            EI.evalPitopdecList I.SELF evalTopEnvProvide (LongsymbolSet.empty, provideTopdecs)
        val _ = VP.unionTopEnv "210" (totalTopEnv, topEnv)

        val _ = clearUsedflag evalTopEnv
        val (renameEnv, returnTopEnvInclude, topdecListInclude) =
            evalPltopdecList
              (emptyRenameEnv:renameEnv) 
              {topEnv=evalTopEnv, version=version} 
              topdecsInclude
            handle e => raise e

        val evalTopEnv = VP.topEnvWithTopEnv(evalTopEnv, returnTopEnvInclude)

        val _ = Analyzers.startNameRefTracing ()

        val (renameEnv, returnTopEnvSource, topdecListSource) =
            evalPltopdecList
              (renameEnv:renameEnv) {topEnv=evalTopEnv, version=version} topdecsSource
            handle e => raise e

(*
        val _ = 
            if !Control.doNameAnalysis  then
              AnalyzeSource.analyzeSouce source evalTopEnv returnTopEnvSource
            else ()
*)
        val returnTopEnv = VP.topEnvWithTopEnv(returnTopEnvInclude, returnTopEnvSource)

(*
val _ = U.print "*** before checkPitopdecList\n"
*)

        val _ = Analyzers.stopBindTracing ()

        val (exnInfoList, returnTopEnv, exportList) =
          if !Control.interactiveMode
          then genExport (version, returnTopEnv)
          else if EU.isAnyError () then (nil, returnTopEnv, nil)
          else 
            let
              val {exportDecls, bindDecls} = 
                  CP.checkPitopdecList evalTopEnvProvide (returnTopEnv, provideTopdecs)
            in
              (nil, returnTopEnv, bindDecls@exportDecls)
            end
               handle e => raise e

        val _ = Analyzers.stopNameRefTracing ()

(*
val _ = U.print "*** after checkPitopdecList\n"
*)
        (* generate ICEXTERN of overload instances *)
        val _ = setUsedflagsOfOverloadInstances evalTopEnv

        (* avoid duplicate declarations *)
        val _ = app (clearUsedflagOfSystemDecl evalTopEnv) systemDecls

        val externExnSet = externExnSetSystemdecls systemDecls LongsymbolEnv.empty
        val ((externExnSet, externVarSet), interfaceDecls) = 
            genExterndecls (externExnSet, emptyExternVarSet) evalTopEnv

        val externVarDecls = map I.ICEXTERNVAR (LongsymbolEnv.listItems externVarSet)

(*
        val topdecs = 
            systemDecls @ interfaceDecls @ topdecListInclude
            @ externVarDecls @ topdecListSource @ exportList
*)

        val systemDecls = systemDecls @ interfaceDecls @ topdecListInclude @ externVarDecls
        val icdecls = systemDecls @ topdecListSource @ exportList

        val returnTopEnv = reduceTopEnv returnTopEnv
(*
        val exnConList = 
            (map EXN exnInfoList) @ (map EXEXN (LongsymbolEnv.listItems externExnSet))
*)
(*
        val returnTopEnv = RL.renameLomgsymbolTopEnv renameEnv returnTopEnv
*)
      in
        case EU.getErrors () of
          [] => {requireTopEnv = evalTopEnv,
                 returnTopEnv = returnTopEnv,
                 icdecls = icdecls,
                 warnings = EU.getWarnings()}
        | errors => raise UserError.UserErrors (EU.getErrorsAndWarnings ())
      end
      handle exn as UserError.UserErrors _ => raise exn

  fun nameEvalInterface
        topEnv
        ({interfaceDecs, requiredIds, topdecsInclude}:PI.interface_unit) =
      let
        val _ = EU.initializeErrorQueue()
        val topdecsInclude =
            map (fn P.PLTOPDECSIG x => PI.TOPDECSIG x
                  | _ => raise Bug.Bug "non sig entry in topdecsInclude")
                topdecsInclude
        val interfaceEnv = EI.evalInterfaces topEnv interfaceDecs
        val _ = (* for error checking *)
            InterfaceID.Map.foldl
              (fn ({topEnv,...}, totalEnv) =>
                  VP.unionTopEnv "207" (totalEnv, topEnv))
              V.emptyTopEnv
              interfaceEnv

        val topEnvRequire =
            unionRequiredTopEnv interfaceEnv V.emptyTopEnv requiredIds
        val (renameEnv, topEnvInclude, itopdecsInclude) =
            evalPltopdecList
              emptyRenameEnv
              {topEnv = VP.unionTopEnv "208" (topEnv, topEnvRequire),
               version = I.SELF}
              topdecsInclude
        val _ = (* for error checking *)
            case itopdecsInclude of
              nil => ()
            | _::_ => raise Bug.Bug "non empty itopdecsInclude"

        (* return topEnv for codes requiring this interface *)
        val returnTopEnv = VP.topEnvWithTopEnv (topEnvRequire, topEnvInclude)
        val returnTopEnv = reduceTopEnv returnTopEnv
        val returnTopEnv = RL.renameLomgsymbolTopEnv renameEnv returnTopEnv
      in
        case EU.getErrors () of
          nil => (returnTopEnv, EU.getWarnings ())
        | _::_ => raise UserError.UserErrors (EU.getErrorsAndWarnings ())
      end

  fun evalBuiltin topdecList =
      let
        val _ = EU.initializeErrorQueue()
        val (_, topEnv, icdecls) =
            EI.evalPitopdecList I.SELF V.emptyTopEnv (LongsymbolSet.empty, topdecList)
        val icdecls =
            map (fn I.ICEXTERNEXN {used, longsymbol, ty, version} =>
                    I.ICBUILTINEXN {longsymbol=longsymbol, ty=ty}
                  | x => x)
                icdecls
      in
        case EU.getErrors () of
          [] => (topEnv, icdecls)
        | _::_ => raise UserError.UserErrors (EU.getErrorsAndWarnings ())
      end 

end
end
