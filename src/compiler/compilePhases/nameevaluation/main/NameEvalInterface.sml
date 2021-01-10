(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : EI-001 *)
structure NameEvalInterface =
struct
local
  structure I = IDCalc
  structure T = Types
  structure V = NameEvalEnv
  structure VP = NameEvalEnvPrims
  structure BT = BuiltinTypes
  structure PI = PatternCalcInterface
  (* structure PC = PatternCalc *)
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure AI = AbsynInterface
  structure N = NormalizeTy
  structure Ty = EvalTy
  (* structure ITy = EvalIty *)
  structure Sig = EvalSig
  structure SC = SigCheck
  structure L = SetLiftedTys
  structure S = Subst
  structure FU = FunctorUtils
  structure RL = RenameLongsymbol
  structure IN = InterfaceName
                 
  type renameEnv = I.tfun TypID.Map.map
  val emptyRenameEnv =  TypID.Map.empty : renameEnv

  val mkSymbol = Symbol.mkSymbol
  val mkLongsymbol = Symbol.mkLongsymbol
  val symbolToLoc = Symbol.symbolToLoc
  val longsymbolToLoc = Symbol.longsymbolToLoc

  fun bug s = Bug.Bug ("NameEvalInterface: " ^ s)
  val nilPath = nil

  (* FIXME factor out this def into some unique plcae *)
  val FUNCORPREFIX = "_"

  fun addExSet (externSet:LongsymbolSet.set, {used, longsymbol, ty, version}:I.exInfo) =
      LongsymbolSet.add(externSet, longsymbol)

  fun exSetMember (externSet:LongsymbolSet.set, {used, longsymbol, ty, version}:I.exInfo) =
      LongsymbolSet.member(externSet, longsymbol)

  val emptyExSet = LongsymbolSet.empty

in
  val revealKey = RevealID.generate() (* global reveal key *)

  type interfaceEnv = {decls: IDCalc.icdecl list,
                       source: PatternCalcInterface.pitopdec list,
                       topEnv: NameEvalEnv.topEnv} InterfaceID.Map.map

  (* change exception status to EXREP; copied from NameEval.sml *)
  fun exceptionRepVarE varE =
      SymbolEnv.map
      (fn (I.IDEXN info) => I.IDEXNREP info
        (* 2012-9-25 ohori added to fix 241_functorExn bug *)
        | (I.IDEXEXN info) => I.IDEXEXNREP info
        | (idstatus as I.IDEXVAR {exInfo={used, ...},...}) =>
          (used := true; idstatus)
        | idstatus => idstatus)
      varE
  fun exceptionRepStrEntryWithSymbol (strEntry as {env=V.ENV {varE, tyE, strE}, ...}) = 
      let
        val varE = exceptionRepVarE varE
        val strE = exceptionRepStrE strE
      in
        strEntry # {env=V.ENV{varE = varE, tyE = tyE, strE=strE}}
      end
  and exceptionRepStrE (V.STR envMap) =
      let
        val envMap = SymbolEnv.map exceptionRepStrEntryWithSymbol envMap
      in
        V.STR envMap
      end

  (* bug 245 *)
  fun exceptionExternVarE provider loc path varE =
      SymbolEnv.mapi
      (fn (name, I.IDEXN {id, longsymbol, ty, defRange}) =>
          let
            val longsymbol = Symbol.prefixPath(path,name)
          in
            I.IDEXEXN {longsymbol=longsymbol, ty=ty, version=provider, 
                       defRange = defRange,
                       used = ref false}
          end
        | (name, I.IDEXNREP {id, longsymbol, ty, defRange}) => 
          let
            val longsymbol = Symbol.prefixPath(path,name)
          in
            I.IDEXEXNREP {longsymbol=longsymbol, ty=ty, version=provider, defRange=defRange,                          
                          used = ref false}
          end
        | (name, idstatus) => idstatus)
      varE
  fun exceptionExternEnv provider loc path (V.ENV {varE, tyE, strE}) = 
      let
        val varE = exceptionExternVarE provider loc path varE
        val strE = exceptionExternStrE provider loc path strE
      in
        V.ENV{varE = varE, tyE = tyE, strE=strE}
      end
  and exceptionExternStrEntryWithSymbol provider loc path (strEntry as {env,...}) = 
      strEntry # {env=exceptionExternEnv provider loc path env}
  and exceptionExternStrE provider loc path (V.STR envMap) =
      let
        val envMap = 
            SymbolEnv.mapi 
              (fn (name, strEntryWithSymbol) => 
                  exceptionExternStrEntryWithSymbol 
                    provider
                    loc
                    (Symbol.prefixPath(path , name))
                    strEntryWithSymbol
              )
              envMap
      in
        V.STR envMap
      end

(*
  exception EvalRuntimeTy
  fun evalRuntimeTy loc tvarEnv evalEnv runtimeTy =
      case runtimeTy of
        PI.BUILTINty ty => I.BUILTINty ty
      | PI.LIFTEDty longsymbol => 
        let
          val aty = Absyn.TYCONSTRUCT(nil, longsymbol, loc)
          val ity = Ty.evalTy tvarEnv evalEnv aty
        in
          case ity of
            I.TYVAR (tvar as {lifted,...}) => 
            if lifted then I.LIFTEDty tvar
            else raise EvalRuntimeTy
          | _ => 
            (case I.runtimeTyOfIty ity of
               SOME ty =>  ty
             | NONE => raise EvalRuntimeTy
            )
        end
*)

  fun genTypedExternVarsIdstatus path idstatus (externSet, icdecls) =
      case idstatus of
        I.IDVAR _  => (externSet,  icdecls)
      | I.IDVAR_TYPED _ => (externSet, icdecls)
      | I.IDEXVAR {exInfo, internalId, defRange} =>
        if exSetMember(externSet, exInfo) 
        then (externSet, icdecls)
        else
          (addExSet(externSet, exInfo),
           I.ICEXTERNVAR exInfo ::icdecls)
      | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
      | I.IDBUILTINVAR _ => (externSet, icdecls)
      | I.IDCON _ => (externSet, icdecls)
      | I.IDEXN _ => (externSet, icdecls)
      | I.IDEXNREP _ => (externSet, icdecls)
      | I.IDEXEXN idInfo => 
        let
          val exExnInfo = I.idInfoToExExnInfo idInfo
        in
        if exSetMember(externSet, exExnInfo) 
        then (externSet, icdecls)
        else
          (addExSet(externSet, exExnInfo), 
           I.ICEXTERNEXN exExnInfo ::icdecls)
        end
      | I.IDEXEXNREP _ => (externSet, icdecls)
      | I.IDOPRIM _ => (externSet, icdecls)
      | I.IDSPECVAR _ => raise bug "IDSPECVAR in genTypedExternVars"
      | I.IDSPECEXN _ => raise bug "IDSPECEXN in genTypedExternVars"
      | I.IDSPECCON _ => raise bug "IDSPECCON in genTypedExternVars"
  fun genTypedExternVarsVarE path varE (externSet, icdecls) =
      SymbolEnv.foldli
      (fn (name, idstatus, (externSet, icdecls)) =>
          let
            val (externSet, icdecls) = 
                genTypedExternVarsIdstatus 
                  (Symbol.prefixPath(path,name))
                  idstatus
                  (externSet, icdecls)
          in
            (externSet, icdecls)
          end
      )
      (externSet, icdecls)
      varE
  fun genTypedExternVarsEnv path (V.ENV{varE, tyE, strE}) (externSet, icdecls) =
      let
        val (externSet, icdecls) = genTypedExternVarsVarE path varE (externSet, icdecls)
        val (extdenSet, icdecls) = genTypedExternVarsStrE path strE (externSet, icdecls)
      in
        (externSet, icdecls)
      end
  and genTypedExternVarsStrE path (V.STR strEntryMap) (externSet, icdecls) =
      let
        val (externSet, icdecls) =
            SymbolEnv.foldli
              (fn (name, {env, ...}, (externSet, icdecls)) =>
                  let
                    val (externSet, icdecls) =
                        genTypedExternVarsEnv 
                          (Symbol.prefixPath(path,name)) 
                          env 
                          (externSet, icdecls)
                  in
                    (externSet, icdecls)
                  end
              )
              (externSet, icdecls)
              strEntryMap
      in
        (externSet, icdecls)
      end

  fun evalPidec provider (renameEnv:renameEnv) path
                (topEnv as {Env=env, FunE, SigE}) (externSet, pidec) =
      case pidec of
        PI.PIVAL {scopedTvars, symbol=symbol, body, loc} =>
        let
          (* val (scopedTvars) symbol = body *)
          val (tvarEnv, kindedTvars) =
              Ty.evalScopedTvars Ty.emptyTvarEnv env scopedTvars
          fun evalOverloadCase {tyvar, expTy, matches, loc} =
              let
                val tvar = Ty.evalTvar tvarEnv tyvar
                val expTy = Ty.evalTy tvarEnv env expTy
                val matches = map evalMatch matches
              in
                {tvar=tvar, expTy=expTy, matches=matches, loc=loc}
              end
          and evalMatch {instTy, instance} =
              let
                val instTy = Ty.evalTy tvarEnv env instTy
                val instance = evalInstance instance
              in
                {instTy=instTy, instance=instance}
              end
          and evalInstance instance =
              case instance of
                AI.INST_OVERLOAD overloadCase =>
                I.INST_OVERLOAD (evalOverloadCase overloadCase)
              | AI.INST_LONGVID {longsymbol=longsymbol} =>
                let
                  val loc = longsymbolToLoc longsymbol
                  fun error e =
                      (EU.enqueueError (loc, e);
                       I.INST_EXVAR
                         ({exInfo={used = ref false, 
                                   longsymbol=longsymbol, version=provider, ty=I.TYERROR}, 
                           loc=Loc.noloc}))
                in
                  case VP.findId(env, longsymbol) of
                     SOME(sym, I.IDEXVAR {exInfo, internalId, defRange}) =>
                     I.INST_EXVAR {exInfo=exInfo, loc=loc}
                   | SOME(sym, I.IDEXVAR_TOBETYPED _) => raise bug "IDEXVAR_TOBETYPED"
                   | SOME(sym, I.IDBUILTINVAR {primitive, ty, defRange}) =>
                     I.INST_PRIM ({primitive=primitive, ty=ty}, loc)
                   | SOME(sym, I.IDVAR id) =>
                     error (E.InvalidOverloadInst("EI-010", {longsymbol = longsymbol}))
                   | SOME(sym, I.IDVAR_TYPED _) =>
                     error (E.InvalidOverloadInst("EI-010", {longsymbol = longsymbol}))
                   | SOME(sym, I.IDOPRIM _) =>
                     error (E.InvalidOverloadInst("EI-020", {longsymbol=longsymbol}))
                   | SOME(sym, I.IDCON _) =>
                     error (E.InvalidOverloadInst("EI-030", {longsymbol=longsymbol}))
                   | SOME(sym, I.IDEXN _) =>
                     error (E.InvalidOverloadInst("EI-040", {longsymbol=longsymbol}))
                   | SOME(sym, I.IDEXNREP _) =>
                     error (E.InvalidOverloadInst("EI-050", {longsymbol=longsymbol}))
                   | SOME(sym, I.IDEXEXN _) =>
                     error (E.InvalidOverloadInst("EI-060", {longsymbol=longsymbol}))
                   | SOME(sym, I.IDEXEXNREP _) =>
                     error (E.InvalidOverloadInst("EI-060", {longsymbol=longsymbol}))
                   | SOME(sym, I.IDSPECVAR _) => raise bug "SPEC id status"
                   | SOME(sym, I.IDSPECEXN _) => raise bug "SPEC id status"
                   | SOME(sym, I.IDSPECCON _) => raise bug "SPEC id status"
                   | NONE => error (E.VarNotFound("EI-070",{longsymbol=longsymbol}))
                end
          val longsymbol= Symbol.prefixPath(path, symbol)
        in
          case body of
            AI.VAL_EXTERN {ty} =>
            let
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => I.TYPOLY(kindedTvars,ty)
              val exInfo = {longsymbol=longsymbol, 
                            ty=ty,
                            used = ref false,
                            version=provider}
              val idstatus = I.IDEXVAR {exInfo=exInfo, internalId=NONE, defRange = loc}
              val icdecl = I.ICEXTERNVAR exInfo
              val externSet = addExSet(externSet, exInfo)
            in
              (renameEnv, externSet, VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, idstatus), [icdecl])
            end
          | AI.VALALIAS_EXTERN longsymbol =>
            let
              val loc = longsymbolToLoc longsymbol
            in
              case VP.findId(env, longsymbol) of
                 SOME(sym, 
                      idstatus 
                        as 
                        I.IDEXVAR (exVarInfo as {exInfo, internalId, defRange=originalDefLoc})) => 
                 if exSetMember(externSet, exInfo) then
                   (renameEnv, 
                    externSet, 
                    VP.rebindId VP.INTERFACE
                                (V.emptyEnv, symbol, I.IDEXVAR (exVarInfo # {defRange = loc})),
                    nil)
                 else 
                   let
                     val icdecl = I.ICEXTERNVAR exInfo
                     val externSet = addExSet(externSet, exInfo)
                   in
                     (renameEnv, externSet, 
                      VP.rebindId VP.INTERFACE
                                  (V.emptyEnv, symbol, I.IDEXVAR (exVarInfo # {defRange = loc})),
                      [icdecl])
                   end
               | SOME(sym, idstatus as I.IDBUILTINVAR _) => 
                 (renameEnv, externSet, VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, idstatus), nil)
               | SOME(sym, _) => 
                 (EU.enqueueError
                    (loc, E.ProvideVarIDExpected("EI-080", {longsymbol = longsymbol}));
                  (renameEnv, externSet, V.emptyEnv, nil))
               | NONE => 
                 (EU.enqueueError
                    (loc, E.ProvideUndefinedID("EI-080", {longsymbol = longsymbol}));
                  (renameEnv, externSet, V.emptyEnv, nil))
            end
          | AI.VAL_BUILTIN {builtinSymbol, ty} =>
            let
              val loc = symbolToLoc builtinSymbol
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => I.TYPOLY(kindedTvars,ty)
            in
              case BuiltinPrimitive.findPrimitive (Symbol.symbolToString builtinSymbol) of
                SOME primitive => 
                let
                  val idstatus = I.IDBUILTINVAR {primitive=primitive, ty=ty, defRange = loc}
                in
                  (renameEnv, externSet, VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, idstatus), nil)
                end
              | NONE => 
                (EU.enqueueError
                   (loc, E.PrimitiveNotFound("EI-080", {symbol = builtinSymbol}));
                 (renameEnv, externSet, V.emptyEnv, nil))
            end
          | AI.VAL_OVERLOAD overloadCase =>
            let
              val id = OPrimID.generate()
              val overloadCase = evalOverloadCase overloadCase
              val decl = I.ICOVERLOADDEF {boundtvars=kindedTvars,
                                          id=id,
                                          longsymbol=longsymbol,
                                          overloadCase=overloadCase,
                                          loc = loc}
              val idstatus = 
                  I.IDOPRIM {id=id, overloadDef=decl, used=ref false, 
                             longsymbol=longsymbol, defRange = loc}
              in
              (renameEnv, externSet, VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, idstatus), [decl])
            end
        end
      | PI.PITYPE {tyvars, symbol, ty, loc} =>
        let
          val longsymbol = Symbol.prefixPath(path , symbol)
          val _ = EU.checkSymbolDuplication
                    (fn {symbol, isEq} => symbol) tyvars
                    (fn s => E.DuplicateTypParms("EI-090",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv env ty
          val (tfun, renameEnv) =
              case N.tyForm tvarList ty of
                N.TYNAME tfun => 
                (tfun, renameEnv)
(*
                RL.replaceLongsymbolTfun renameEnv (Symbol.prefixPath (path, symbol)) tfun
                RL.replacePathTfun renameEnv path tfun
*)
              | N.TYTERM ty =>
                let
                  val admitsEq = N.admitEq tvarList ty
                  val tfun =
                      I.TFUN_DEF {admitsEq=admitsEq,
                                  longsymbol=longsymbol,
                                  formals=tvarList,
                                  realizerTy=ty
                                 }
                in
                  (tfun, renameEnv)
                end
          val tstr = V.TSTR {tfun = tfun, defRange = loc}
        in
          (renameEnv, externSet, 
           VP.rebindTstr VP.INTERFACE (V.emptyEnv, symbol, tstr), nil)
        end               

      | PI.PIOPAQUE_TYPE {eq, tyvars, symbol=tycon, runtimeTy, loc} =>
        (let
           val _ = EU.checkSymbolDuplication
                     (fn {symbol, isEq} => symbol)
                     tyvars
                     (fn s => E.DuplicateTypParms("EI-090",s))
           val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
           val id = TypID.generate()
           val property = Ty.getProperty tvarEnv env runtimeTy loc
           val longsymbol = Symbol.prefixPath (path, tycon)
           val absTfun =
               case property of
                 I.PROP property =>
                 I.TFUN_VAR
                   (I.mkTfv
                      (I.TFUN_DTY {id=id,
                                   admitsEq=eq,
                                   formals=tvarList,
                                   conSpec=SymbolEnv.empty,
                                   conIDSet=ConID.Set.empty,
                                   longsymbol=longsymbol,
                                   (* bug foud in asai zemi *)
                                   liftedTys=I.emptyLiftedTys,
                                   dtyKind= I.DTY_INTERFACE property
                                  }
                      )
                   )
               | I.LIFTED tvar =>
                 (EU.enqueueError
                    (loc, E.LIFTEDPropNotAllowedInOpaqueInterface("EI-201", {symbol = tycon}));
                  let
                   val tfun = 
                       I.TFUN_DEF
                         {admitsEq = eq,
                          formals = tvarList,
                          realizerTy = I.TYVAR tvar,
                          longsymbol = longsymbol}
                 in
                   I.TFUN_VAR
                     (I.mkTfv
                        (I.TFUN_DTY {id=id,
                                     admitsEq=eq,
                                     formals=tvarList,
                                     conSpec=SymbolEnv.empty,
                                     conIDSet=ConID.Set.empty,
                                     longsymbol=longsymbol,
                                     liftedTys=I.emptyLiftedTys,
                                     dtyKind= I.INTERFACE tfun
                                    }
                        )
                     )
                  end
                 )
(*
                 I.TFUN_DEF
                   {admitsEq = eq,
                    formals = tvarList,
                    realizerTy = I.TYVAR tvar,
                    longsymbol = longsymbol}
*)
           val tstr = V.TSTR {tfun = absTfun, defRange = loc}
         in
           (renameEnv, externSet, 
            VP.rebindTstr VP.INTERFACE (V.emptyEnv, tycon, tstr), nil)
         end
        )

      | PI.PITYPEBUILTIN {symbol, builtinSymbol, loc} =>
        (case BuiltinTypes.findTstrInfo builtinSymbol of
           NONE => 
           (EU.enqueueError
              (loc, E.BuiltinTyNotFound("EI-100", {symbol = builtinSymbol}));
            (renameEnv, externSet, V.emptyEnv, nil)
           )
         | SOME (tstrInfo as {varE, ...}) => 
           let
             val tstr = V.TSTR_DTY (tstrInfo # {defRange = loc})
             val env = VP.rebindTstr VP.INTERFACE (V.emptyEnv, symbol, tstr)
             val env = VP.envWithVarE (env, varE)
           in
             (renameEnv, externSet, env, nil)
           end
        )
      | PI.PIDATATYPE {datbind, loc} => 
        let
(*
          val datbind =
              map (fn {conbind, tycon, tyvars} =>
                      {conbind = map (fn {symbol, ty} => 
                                         {symbol= #string vid, ty=ty}
                                         )
                                     conbind,
                       tycon= #string tycon,
                       tyvars = tyvars
                      }
                  )
              datbind
*)
          val (env, icdecls) = Ty.evalDatatype path env (datbind, loc)
        in
          (renameEnv, externSet, env, icdecls)
        end

      | PI.PITYPEREP {symbol=tycon, longsymbol=refPath, loc} =>
        (* datatype foo = datatype bar *)
        (
         case VP.findTstr(env, refPath) of
           NONE => (EU.enqueueError
                      (loc, E.DataTypeNameUndefined("EI-110", {longsymbol = refPath}));
                    (renameEnv, externSet, V.emptyEnv, nil))
         | SOME (sym, tstr) =>
           let
             val (tstr, varE) = 
                 case tstr of 
                   V.TSTR_DTY {tfun, varE, formals, conSpec, ...} => 
                   let
                     val (tfun, renameEnv) = 
(*
                         RL.replaceLongsymbolTfun 
                           renameEnv (Symbol.prefixPath (path, symbol)) tfun
                         RL.replacePathTfun renameEnv path tfun
*)
                         RL.replaceLongsymbolTfun 
                           emptyRenameEnv (Symbol.prefixPath (path, tycon)) tfun
                     val varE = RL.renameLongsymbolVarE renameEnv varE
                   in
                     (V.TSTR_DTY {tfun= tfun,
                                  varE= varE,
                                  defRange = loc,
                                  conSpec=conSpec, 
                                  formals=formals},
                      varE)
                   end
                 | _ => 
                   (EU.enqueueError
                      (loc, E.DataTypeNameExpected("EI-130", {longsymbol = refPath}));
                    (tstr, SymbolEnv.empty))
             val env = VP.rebindTstr VP.INTERFACE (V.emptyEnv, tycon, tstr)
             val env = SymbolEnv.foldri
                         (fn (name, idstatus, env) =>
                             VP.rebindId VP.INTERFACE (env, name, idstatus))
                         env
                         varE
           in
             (renameEnv, externSet, env, nil)
           end
        )
      | PI.PIEXCEPTION {symbol, ty=tyOpt, loc} =>
        let
          val longsymbol = Symbol.prefixPath(path,symbol)
          val ty =
              case tyOpt of
                NONE => BT.exnITy
              | SOME ty => 
                I.TYFUNM([Ty.evalTy Ty.emptyTvarEnv env ty],
                          BT.exnITy)
          val idInfo = {longsymbol=longsymbol, ty=ty, defRange = loc,
                        used = ref false, version=provider}
          val exExnInfo = I.idInfoToExExnInfo idInfo
          val idstatus = I.IDEXEXN idInfo
          val icdecl = I.ICEXTERNEXN exExnInfo
          val externSet = addExSet(externSet, exExnInfo)
        in
          (renameEnv, externSet, 
           VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, idstatus), [icdecl])
        end

      | PI.PIEXCEPTIONREP {symbol, longsymbol, loc} =>
         (case VP.findId (env, longsymbol) of
           SOME(sym, idstatus as I.IDEXN idInfo) => 
           (renameEnv, externSet, 
            VP.rebindId VP.INTERFACE
                        (V.emptyEnv, symbol, 
                          I.IDEXNREP (idInfo # {defRange = loc})), 
            nil)
         | SOME(sym, idstatus as I.IDEXNREP idInfo) =>
           (renameEnv, externSet, 
            VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, 
                          I.IDEXNREP (idInfo # {defRange = loc})),
            nil)
         | SOME(sym, idstatus as I.IDEXEXN idInfo) => 
           let
             val exInfo = I.idInfoToExExnInfo idInfo
           in
           if exSetMember(externSet, exInfo) then
             (renameEnv, externSet, 
              VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, I.IDEXEXNREP (idInfo # {defRange = loc})), 
              nil)
           else 
             let
               val icdecl = I.ICEXTERNEXN exInfo
               val externSet = addExSet(externSet, exInfo)
             in
               (renameEnv, 
                externSet, 
                VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, 
                              I.IDEXEXNREP (idInfo # {defRange = loc})), 
                [icdecl])
             end
           end
         | SOME(sym, idstatus as I.IDEXEXNREP idInfo) => 
           let
             val exInfo = I.idInfoToExExnInfo idInfo
           in
           if exSetMember(externSet, exInfo) then
             (renameEnv, externSet, 
              VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, 
                            I.IDEXEXNREP (idInfo # {defRange = loc})), nil)
           else 
             let
               val icdecl = I.ICEXTERNEXN exInfo
               val externSet = addExSet(externSet, exInfo)
             in
               (renameEnv, 
                externSet, 
                VP.rebindId VP.INTERFACE (V.emptyEnv, symbol, 
                             I.IDEXEXNREP (idInfo # {defRange = loc})), 
                [icdecl])
             end
           end
         | SOME (sym, _) => 
           (EU.enqueueError
              (loc, E.ExceptionExpected("EI-150", {longsymbol = longsymbol}));
            (renameEnv, externSet, V.emptyEnv, nil))
         | NONE => 
           (EU.enqueueError
              (loc, E.ExceptionNameUndefined("EI-140", {longsymbol = longsymbol}));
            (renameEnv, externSet, V.emptyEnv, nil))
        )
      | PI.PISTRUCTURE {symbol, strexp, loc} =>
        let
          val (renameEnv, externSet, strEntry, icdecls) = 
              evalPistr 
                provider
                (renameEnv:renameEnv) 
                (Symbol.prefixPath(path,symbol)) topEnv (externSet, strexp)
          val env = VP.rebindStr VP.INTERFACE (V.emptyEnv, symbol, strEntry)
        in
          (renameEnv, externSet, env, icdecls)
        end
          
  and evalPistr provider (renameEnv:renameEnv) path topEnv (externSet, pistrexp) = 
      case pistrexp of
        PI.PISTRUCT {decs, loc} =>
        let
          val strKind = V.STRENV (StructureID.generate())
          val (renameEnv, externSet, env, icdecls) = 
              foldl
                (fn (decl, (renameEnv, externSet, env, icdecls)) =>
                    let
                      val evalTopEnv = VP.topEnvWithEnv (topEnv,env)
                      val (renameEnv, externSet, newEnv, newicdecls) = 
                          evalPidec 
                            provider (renameEnv:renameEnv) path evalTopEnv (externSet, decl)
                    in
                      (renameEnv, externSet, VP.unionEnv "210" (env, newEnv), icdecls@newicdecls)
                    end
                )
                (renameEnv, externSet, V.emptyEnv, nil)
                decs
        in
          (renameEnv, 
           externSet, 
           {env=env, strKind=strKind, loc = loc, definedSymbol = path}, 
           icdecls)
        end
      | PI.PISTRUCTREP{longsymbol, loc} => 
        let
          val {Env,...} = topEnv
        in
          case VP.findStr(Env, longsymbol) of
            NONE => 
            (
             EU.enqueueError
               (loc, E.StructureNameUndefined("EI-140", {longsymbol = longsymbol}));
             (renameEnv, 
              externSet, 
              {env=V.emptyEnv, 
               strKind=V.STRENV(StructureID.generate()),
               definedSymbol = path,
               loc = loc               
              },
              nil)
            )
          | SOME {env, strKind=V.FUNARG _, loc, definedSymbol} => 
            (
             EU.enqueueError
               (loc, E.StructureRepOfFuncrorArgInInterface("EI-141", {longsymbol = path}));
             (renameEnv, 
              externSet, 
              {env=V.emptyEnv, strKind=V.STRENV(StructureID.generate()), 
               definedSymbol = definedSymbol,
               loc = Loc.noloc},
              nil)
            )
          | SOME strEntryWithSymbol => 
            let
              val {strKind, env, loc, definedSymbol} = 
                  exceptionRepStrEntryWithSymbol strEntryWithSymbol
(*
              val env = V.replaceLocEnv loc env
*)
            in
              (renameEnv, externSet, 
               {strKind=strKind, env=env, loc=loc, definedSymbol = definedSymbol}, nil)
            end
        end
      | PI.PIFUNCTORAPP{functorSymbol, argument, loc} => 
        let
          val copyPath = path
          val {Env, FunE,...} = topEnv
        in
          case (VP.findFunETopEnv(topEnv, functorSymbol), VP.findStr(Env, argument)) of
            (NONE, _) => 
            (EU.enqueueError
               (loc, E.FunctorNameUndefined("EI-140", {symbol = functorSymbol}));
             (renameEnv, externSet, 
              {env=V.emptyEnv, strKind=V.STRENV(StructureID.generate()), 
               definedSymbol = path,
               loc = loc},
              nil)
            )
          | (_, NONE) => 
            (EU.enqueueError
               (loc, E.StructureNameUndefined("EI-140", {longsymbol = argument}));
             (renameEnv,  externSet, 
              {env=V.emptyEnv, strKind=V.STRENV(StructureID.generate()), 
               definedSymbol = path,
               loc = loc},
              nil))
          | (SOME funEEntry, SOME {env=argStrEnv, strKind, loc, definedSymbol}) =>
            let
              val {id=funId,loc=funLoc, version, 
                   argSigEnv,argStrName,argStrEntry,dummyIdfunArgTy,polyArgTys,
                   typidSet,exnIdSet,bodyEnv,bodyVarExp}
                  = funEEntry
              val argId = case strKind of
                            V.STRENV id => id
                          | V.FUNAPP{id,...} => id
                          | _ => raise bug "non strenv in functor arg"
              val structureId = StructureID.generate()
              fun instVarE (varE,actualVarE) {typIdS, tvarS, conIdS, exnIdS, newProvider} =
                let
                  val conIdS =
                        SymbolEnv.foldri
                          (fn (name, idstatus, conIdS) =>
                              case idstatus of
                                I.IDCON {id, longsymbol, ty, defRange} =>
                                (case SymbolEnv.find(actualVarE, name) of
                                   SOME (idstatus as I.IDCON _) =>
                                   (* defRangeの妥当性？ *)
                                   ConID.Map.insert(conIdS, id, idstatus)
                                 | SOME actualIdstatus => raise bug "non conid"
                                 | NONE => raise bug "conid not found in instVarE"
                                )
                              | _ => conIdS)
                          conIdS
                          varE
                  in
                    {typIdS = typIdS, 
                     tvarS=tvarS,exnIdS=exnIdS, conIdS=conIdS, newProvider=newProvider}
                  end
              fun instTfun path (tfun, actualTfun)
                           (subst as {typIdS, tvarS, conIdS, exnIdS, newProvider}) =
                  let
                    val tfun = I.derefTfun tfun
                    val actualTfun = I.derefTfun actualTfun
                  in
                    case tfun of
                      I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {dtyKind = I.FUNPARAM rty,...})) =>
                      (case actualTfun of
                         I.TFUN_VAR(ref (tfunkind as I.TFUN_DTY _)) =>
                         if case I.tfunProperty actualTfun of
                              NONE => false
                            | SOME ty2 =>
                              Ty.compatProperty
                                {abs = I.PROP rty, impl = ty2}
                         then tfv1 := tfunkind
                         else EU.enqueueError
                                (loc, E.FunctorParamRestriction
                                        ("440", {longsymbol=path}))
                       | I.TFUN_VAR _ => raise bug "tfun var"
                       | I.TFUN_DEF _ =>
                         EU.enqueueError
                           (loc, E.FunctorParamRestriction
                                   ("440", {longsymbol=path}));
                       subst)
                    | I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {dtyKind,...})) =>
                      (case actualTfun of
                         I.TFUN_VAR(tfv2 as ref (tfunkind as I.TFUN_DTY _)) =>
                         (tfv1 := tfunkind;
                          subst
                         )
                       | I.TFUN_DEF _ => raise bug "tfun def"
                       | I.TFUN_VAR _ => raise bug "tfun var"
                      )
                    | I.TFUN_DEF{longsymbol, admitsEq, formals=nil, realizerTy= I.TYVAR tvar} =>
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
                        V.TSTR _ => raise bug "TSTR_DTY vs TST"
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
                          instTstr (Symbol.prefixPath(path,name)) (tstr, actualTstr) subst
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
                    (fn (name, {env, strKind, loc, definedSymbol}, subst) =>
                        let
                          val actualEnv = case SymbolEnv.find(actualEnvMap, name) of
                                            SOME {env, strKind, ...} => env 
                                          | NONE => raise bug "actualEnv not found"
                        in
                          instEnv (Symbol.prefixPath(path,name)) (env, actualEnv) subst
                        end
                    )
                    subst
                    envMap

              fun setPathIdstatus copyPath idstatus =
                  (* defRangeの妥当性? *)
                  case idstatus of
                    I.IDVAR varId => idstatus
                  | I.IDVAR_TYPED _ => idstatus
                  | I.IDEXVAR {exInfo={used, longsymbol, version, ty}, internalId, defRange} =>
                    I.IDEXVAR
                      {exInfo={longsymbol= Symbol.concatPath(copyPath , longsymbol),
                               ty=ty,
                               used = used, 
                               version=version},
                       defRange = defRange,
                       internalId=internalId}
                  | I.IDEXVAR_TOBETYPED {longsymbol, id, version, defRange} =>
                    I.IDEXVAR_TOBETYPED
                      {longsymbol= Symbol.concatPath(copyPath, longsymbol), 
                       defRange = defRange,
                       id=id, version=version}
                  | I.IDBUILTINVAR _ => idstatus
                  | I.IDCON _ => idstatus
                  | I.IDEXN _ => idstatus
                  | I.IDEXNREP _ => idstatus
                  | I.IDEXEXN  {used, longsymbol, ty, version, defRange} =>
                    I.IDEXEXN  
                      {used = used, 
                       defRange = defRange,
                       longsymbol= Symbol.concatPath(copyPath,longsymbol), ty=ty, version=version}
                  | I.IDEXEXNREP {used, longsymbol, ty, version, defRange} =>
                    I.IDEXEXNREP
                      {used = used, 
                       defRange = defRange,
                       longsymbol = Symbol.concatPath(copyPath,longsymbol), 
                       ty=ty, version=version}
                  | I.IDOPRIM _ => idstatus
                  | I.IDSPECVAR _ => idstatus
                  | I.IDSPECEXN _ => idstatus
                  | I.IDSPECCON _ => idstatus
              fun setPathVarE copyPath varE =
                  SymbolEnv.map (setPathIdstatus copyPath) varE
              fun setPathEnv copyPath (V.ENV{tyE, strE, varE}) =
                  let
                    val strE = setPathStrE copyPath strE
                    val varE = setPathVarE copyPath varE
                  in
                    V.ENV{tyE=tyE, strE=strE, varE=varE}
                  end
              and setPathStrE copyPath (V.STR envMap) =
                  V.STR
                    (
                     SymbolEnv.map
                       (fn {env, strKind, loc, definedSymbol} => 
                           {env=setPathEnv copyPath env, strKind=strKind, 
                            definedSymbol = definedSymbol,
                            loc = loc})
                       envMap
                    )

              val (actualArgEnv, actualArgDecls) =
                  let
                    val argSigEnv = #2 (Sig.refreshSpecEnv argSigEnv)
                        handle e => raise e
(*
                    val argId = case strKind of
                                  V.STRENV id => id
                                | V.FUNAPP{id,...} => id
                                | _ => raise bug "non strenv in functor arg"
*)
                  in
                    SC.sigCheck
                       {mode = SC.Trans,
                        strPath = argument,
                        strEnv = argStrEnv,
                        specEnv = argSigEnv,
                        loc = loc
                       }
                    handle e => raise e
                  end
              val _ = if EU.isAnyError () then raise SC.SIGCHECK else ()
              val argStrSymbol = Symbol.mkSymbol "arg" Loc.noloc
              val argStrLongsymbol = Symbol.mkLongsymbol ["arg"] Loc.noloc
              val bodyStrSymbol = Symbol.mkSymbol "body" Loc.noloc
              val bodyStrLongsymbol = Symbol.mkLongsymbol ["body"] Loc.noloc
              val tempEnv =
                  VP.reinsertStr(VP.reinsertStr(V.emptyEnv, argStrSymbol, argStrEntry),
                                bodyStrSymbol,
                                {env=bodyEnv, 
                                 loc = Loc.noloc,
                                 definedSymbol = path @ [bodyStrSymbol],
                                 strKind=V.STRENV(StructureID.generate())})
(*
              val tempEnv =
                  V.ENV{varE=SymbolEnv.empty,
                        tyE=SymbolEnv.empty,
                        strE=
                        V.STR
                          (
                           SymbolEnv.insert
                             (SymbolEnv.insert(SymbolEnv.empty, "arg", argStrEntry),
                              "body",
                              {env=bodyEnv, strKind=V.STRENV(StructureID.generate())})
                          )
                       }
*)
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
              val ((tfvSubst, conIdSubst), tempEnv) =
                  SC.refreshEnv copyPath (typidSet, exnIdSubst) tempEnv
                  handle e => raise e
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
              val {env=argEnv, strKind=_, loc, definedSymbol} = 
                  case VP.checkStr(tempEnv, argStrLongsymbol) of
                    SOME strEntry => strEntry
                  | NONE => raise bug "impossible (2)"
              val {env=bodyEnv, ...} = 
                  case VP.checkStr(tempEnv, bodyStrLongsymbol) of
                    SOME env => env
                  | NONE => raise bug "impossible (3)"
(*
              val {env=argEnv, strKind} = 
                  case V.findStr(tempEnv, ["arg"]) of
                    SOME strEntry => strEntry
                  | NONE => raise bug "impossible"
              val {env=bodyEnv, ...} = 
                  case V.findStr(tempEnv, ["body"]) of
                    SOME env => env
                  | NONE => raise bug "impossible"
*)
              val subst = instEnv nil (argEnv, actualArgEnv) S.emptySubst
              val subst = subst # {newProvider = SOME provider}
              val bodyEnv = S.substEnv subst bodyEnv
                  handle e => raise e
              val bodyEnv = N.reduceEnv bodyEnv 
                  handle e => raise e
              val bodyEnv = exceptionExternEnv provider loc nil bodyEnv
              val bodyEnv = setPathEnv copyPath bodyEnv
(*
              val bodyEnv = V.replaceLocEnv loc bodyEnv
*)
              (* bug 243? *)
              val pathTfvListList = L.setLiftedTysEnv bodyEnv
                  handle e => raise e
              val (externSet, icdecls) = genTypedExternVarsEnv path bodyEnv (externSet, nil)
              val strKind = V.FUNAPP {id=structureId, funId=funId, argId=argId}
            in
              (renameEnv, externSet, 
               {env=bodyEnv, strKind=strKind, definedSymbol = path, loc = loc}, 
               icdecls)
            end
            handle SC.SIGCHECK => 
                   (renameEnv, 
                    externSet, 
                    {env=V.emptyEnv, loc = Loc.noloc, 
                     definedSymbol = path,
                     strKind=V.STRENV (StructureID.generate())}, nil)
        end (* end of pidec *)
      handle exn => raise bug "uncaught exception in evalPistr"

  fun internalizeIdstatus (pathEnv,idstatus) =
      (* defRangeの妥当性 *)
      case idstatus of
        I.IDEXEXN (exInfo as {used, longsymbol, ty, version, defRange}) =>
        (case LongsymbolEnv.find(pathEnv, longsymbol) of
           SOME idstatus => (pathEnv, idstatus)
         | NONE => 
           let
             val newId = ExnID.generate() (* dummy *)
             val idstatus = I.IDEXN {id=newId, longsymbol=longsymbol, ty= ty, defRange=defRange}
             val pathEnv = LongsymbolEnv.insert(pathEnv, longsymbol, idstatus)
           in
              (pathEnv, idstatus)
            end
        )
      | I.IDEXEXNREP (exInfo as {used, longsymbol, ty, version, defRange}) =>
        (case LongsymbolEnv.find(pathEnv, longsymbol) of
           SOME idstatus => (pathEnv, idstatus)
         | NONE => (pathEnv, idstatus)
        )
      | _ => (pathEnv, idstatus)

  fun internalizeEnv (pathEnv, V.ENV {tyE, varE, strE=V.STR envMap}) =
      (* defRangeの妥当性 *)
      let
        val (pathEnv, varE) = 
            SymbolEnv.foldri
              (fn (name, idstatus, (pathEnv, varE)) =>
                  let
                    val (pathEnv, idstatus)=  internalizeIdstatus (pathEnv, idstatus)
                    val varE = SymbolEnv.insert(varE, name, idstatus)
                  in
                    (pathEnv, varE)
                  end
              )
              (pathEnv, SymbolEnv.empty)
              varE
        val (pathEnv, strE) = 
            let
              val (pathEnv, envMap) =
                  SymbolEnv.foldri
                    (fn (name, {env, strKind, loc, definedSymbol}, (pathEnv, envMap)) => 
                        let
                          val (pathEnv, env) = internalizeEnv (pathEnv, env)
                          val envMap = 
                              SymbolEnv.insert
                                (envMap, name, 
                                 {env=env, loc=loc, strKind=strKind, definedSymbol = definedSymbol})
                        in
                          (pathEnv, envMap)
                        end
                    )
                    (pathEnv, SymbolEnv.empty)
                    envMap
            in
              (pathEnv, V.STR envMap)
            end
      in
        (pathEnv, V.ENV{tyE=tyE, varE=varE, strE=strE})
      end
  fun internalizeIdstatusRep pathEnv idstatus =
      (* defRangeの妥当性 *)
      case idstatus of
        I.IDEXEXNREP (exInfo as {used, longsymbol, ty, version, defRange}) =>
        (case LongsymbolEnv.find(pathEnv, longsymbol) of
           SOME (I.IDEXN exInfo) => I.IDEXNREP exInfo
         | _ => idstatus
        )
      | _ => idstatus

  fun internalizeEnvRep pathEnv (V.ENV {tyE, varE, strE=V.STR envMap}) =
      (* defRangeの妥当性 *)
      let
        val varE = 
            SymbolEnv.foldri
              (fn (name, idstatus, varE) =>
                  let
                    val idstatus=  internalizeIdstatusRep pathEnv idstatus
                  in
                   SymbolEnv.insert(varE, name, idstatus)
                  end
              )
              SymbolEnv.empty
              varE
        val strE = 
            let
              val envMap =
                  SymbolEnv.foldri
                    (fn (name, {env, strKind, loc, definedSymbol}, envMap) => 
                        let
                          val env = internalizeEnvRep pathEnv env
                          val envMap = SymbolEnv.insert
                                         (envMap, name, 
                                          {env=env, loc = loc, definedSymbol =  definedSymbol,
                                           strKind=strKind})
                        in
                          envMap
                        end
                    )
                    SymbolEnv.empty
                    envMap
            in
              V.STR envMap
            end
      in
        V.ENV{tyE=tyE, varE=varE, strE=strE}
      end

  val internalizeEnv = 
   fn env => 
      let
        val (pathEnv, env) = internalizeEnv (LongsymbolEnv.empty, env)
      in
        internalizeEnvRep pathEnv env
      end
                          
  fun evalFunDecl provider (renameEnv:renameEnv)
                  topEnv {functorSymbol,
                          param={strSymbol, sigexp=argSig},
                          strexp=bodyStr, loc} =
      let
        val 
        {
         argSigEnv=argSigEnv,
         argStrEntry=argStrEntry,
         extraTvars=extraTvars,
         polyArgPats=polyArgPats,
         exnTagDecls=exnTagDecls,
         dummyIdfunArgTy=dummyIdfunArgTy,
         firstArgPat=firstArgPat,
         tfvDecls = tfvDecls
        } = FunctorUtils.evalFunArg (topEnv, argSig, loc)

        val topArgEnv = VP.rebindStr VP.FUNCTOR_ARG (V.emptyEnv, strSymbol, argStrEntry)
(*
        val topArgEnv = 
            V.ENV {varE=SymbolEnv.empty,
                   tyE=SymbolEnv.empty,
                   strE=V.STR (SymbolEnv.singleton(argStrName, argStrEntry))
                  }
*)
        val evalEnv = VP.topEnvWithEnv (topEnv, topArgEnv)

        val startTypid = TypID.generate()

        val (renameEnv, _, {env=bodyInterfaceEnv,strKind, loc, definedSymbol}, _) = 
            evalPistr provider (renameEnv:renameEnv) nil evalEnv (emptyExSet, bodyStr)
(*
        val (_, bodyInterfaceEnv,_) = evalPistr [functorName] evalEnv (emptyExSet, bodyStr)
*)

        val bodyEnv = internalizeEnv bodyInterfaceEnv

        val typidSet = FU.typidSet bodyEnv
        val (allVars, exnIdSet) = FU.varsInEnv (bodyEnv, loc)

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

        fun varToTy (_,var) =
            case var of
              I.ICEXVAR {exInfo={ty,...},...} => ty
            | I.ICEXN {ty,...} => ty
            | I.ICEXN_CONSTRUCTOR _ => BT.exntagITy
(* 2016-11-06 ohori: structure replicationの対象がfunctor argumentの場合，ICVAR等があり得る
            | I.ICVAR {exInfo={ty,...},...} => ty
            | I.ICEXN {ty,...} => ty
            | I.ICEXN_CONSTRUCTOR _ => BT.exntagITy
*)
            | _ => 
              (
               raise bug "*** VARTOTY ***"
              )

        val bodyTy =
            case allVars of
              nil => BT.unitITy
            | _ => I.TYRECORD {ifFlex=false, fields=RecordLabel.tupleMap (map varToTy allVars)}
        val polyArgTys = map (fn (x,ty) => ty) polyArgPats 
        val firstArgTy =
            case dummyIdfunArgTy of
              SOME ty => SOME(I.TYFUNM([ty],ty))
            | NONE => NONE
        val functorTy1 =
            case polyArgTys of
              nil => bodyTy
            | _ => I.TYFUNM(polyArgTys, bodyTy)
        val functorTy2 =
            case firstArgTy of
              NONE => functorTy1
            | SOME ty  => 
              I.TYPOLY(map (fn x => (x, I.UNIV T.emptyProperties)) extraTvars,
                        I.TYFUNM([ty], functorTy1))
        val functorTy =
            case functorTy2 of
              I.TYPOLY _ => functorTy2
            | I.TYFUNM _ => functorTy2
            | _ => I.TYFUNM([BT.unitITy], functorTy2)
        val longsymbol = [mkSymbol FUNCORPREFIX loc, functorSymbol]
        val exInfo = {used = ref false, longsymbol=longsymbol, ty=functorTy, version=provider}
        val decl = I.ICEXTERNVAR exInfo
        val functorExp = I.ICEXVAR {longsymbol=longsymbol,
                                    exInfo=exInfo}

        val funEEntry:V.funEEntry =
            {id = FunctorID.generate(),
             loc = loc,
             version = provider,
             argSigEnv = argSigEnv,
             argStrName = strSymbol,
             argStrEntry = argStrEntry,
             dummyIdfunArgTy = dummyIdfunArgTy,
             polyArgTys = polyArgTys,
             typidSet=typidSet,  (* FIXME: is this right? *)
             exnIdSet=exnIdSet,  (* FIXME: is this right? *)
             bodyEnv = bodyEnv,
             bodyVarExp = functorExp
            }
            
        val funE =  VP.rebindFunE VP.INTERFACE (SymbolEnv.empty, functorSymbol, funEEntry)
        val returnTopEnv = VP.topEnvWithFunE(V.emptyTopEnv, funE)
      in
        (returnTopEnv, [decl])
      end

  fun evalPitopdec provider (renameEnv:renameEnv) topEnv (externSet, pitopDec) =
      case pitopDec of
        PI.PIDEC pidec => 
        let
          val (renameEnv, _, returnEnv, icdecls) = 
              evalPidec provider (renameEnv:renameEnv) nilPath topEnv (externSet, pidec)
        in
          (renameEnv, externSet, VP.topEnvWithEnv(V.emptyTopEnv, returnEnv), icdecls)
        end
      | PI.PIFUNDEC fundec =>
        let
          val (returnTopEnv, icdecls) = 
              evalFunDecl provider (renameEnv:renameEnv) topEnv fundec
        in
          (renameEnv, externSet, returnTopEnv, icdecls)
        end

  fun evalPitopdecList provider (renameEnv:renameEnv) topEnv (externSet, pitopdecList) =
      (foldl
         (fn (pitopdec, (renameEnv, externSet, returnTopEnv, icdecls)) =>
             let
               val evalTopEnv = VP.topEnvWithTopEnv (topEnv, returnTopEnv)
               val (renameEnv, externSet, newTopEnv, newicdecls) = 
                   evalPitopdec provider (renameEnv:renameEnv) evalTopEnv (externSet, pitopdec)
               val loc = PI.pitopdecLoc pitopdec
             in
               (renameEnv, externSet, 
                VP.unionTopEnv "211" (returnTopEnv,newTopEnv), icdecls @ newicdecls)
             end
         )
         (renameEnv, externSet, V.emptyTopEnv, nil)
         pitopdecList
      )
      handle exn => raise exn
             (* raise bug "uncaught exception in evalPitopdecList" *)

  fun evalInterfaceDec env ({interfaceId,
                             interfaceName,
                             requiredIds=idLocList,
                             provideTopdecs}
                            :PI.interfaceDec, IntEnv) =
      let
        val provider = I.OTHER interfaceName
        val evalTopEnv =
            foldl
            (fn ({id,loc}, evalTopEnv) =>
                let
                  val newTopEnv = 
                      case InterfaceID.Map.find (IntEnv, id) of
                        NONE => raise bug "InterfaceID undefined"
                      | SOME {topEnv,...} => topEnv
                in
                  VP.unionTopEnv "212" (evalTopEnv, newTopEnv)
                end
            )
            env
            idLocList
        val source = #source interfaceName

        val _ = Analyzers.pushInterfaceTracer source

        val (renameEnv, _, topEnv, icdecls) = 
            evalPitopdecList provider emptyRenameEnv evalTopEnv (emptyExSet, provideTopdecs)

(*
        val _ = 
            if !Control.doNameAnalysis  then
              AnalyzeSource.analyzeInterface (Loc.FILE (#source interfaceName)) evalTopEnv topEnv
            else ()
*)

        val _ = Analyzers.popInterfaceTracer source

      in
        case InterfaceID.Map.find(IntEnv, interfaceId) of
          NONE => InterfaceID.Map.insert
                    (IntEnv,
                     interfaceId,
                     {source=provideTopdecs, topEnv=topEnv, decls=icdecls}
                    )
        | SOME _ => raise bug "duplicate interfaceid"
      end

  fun evalInterfaces env interfaceDecList =
      foldl (evalInterfaceDec env) InterfaceID.Map.empty interfaceDecList
      handle exn => raise exn
             (* raise bug "uncaught exception in evalInterfaces" *)
  val evalPistr = 
      fn provider => fn path =>  fn topEnv => fn (externSet, pistrexp) =>
         let
           val (renameEnv, externSet, returnEnv, icdecls) = 
               evalPistr provider (emptyRenameEnv:renameEnv) path topEnv (externSet, pistrexp)
         in
           (externSet, returnEnv, icdecls)
         end

  val evalPitopdecList = 
      fn provider => fn topEnv => fn (externSet, pitopdecList) =>
         let
           val (renameEnv, externSet, newTopEnv, newicdecls) = 
               evalPitopdecList provider (emptyRenameEnv:renameEnv) topEnv (externSet, pitopdecList)
         in
           (externSet, newTopEnv, newicdecls)
         end
end
end
