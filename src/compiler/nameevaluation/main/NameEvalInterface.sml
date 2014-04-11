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
  structure BT = BuiltinTypes
  structure PI = PatternCalcInterface
  structure PC = PatternCalc
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure AI = AbsynInterface
  structure A = Absyn
  structure N = NormalizeTy
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure Sig = EvalSig
  structure SC = SigCheck
  structure L = SetLiftedTys
  structure S = Subst
  structure FU = FunctorUtils

  val mkSymbol = Symbol.mkSymbol
  val mkLongsymbol = Symbol.mkLongsymbol
  val symbolToLoc = Symbol.symbolToLoc
  val symbolToString = Symbol.symbolToString
  val longsymbolToLoc = Symbol.longsymbolToLoc
  val longsymbolToLongid = Symbol.longsymbolToLongid

  fun bug s = Bug.Bug ("NameEvalInterface: " ^ s)
  val nilPath = nil

  (* FIXME factor out this def into some unique plcae *)
  val FUNCORPREFIX = "_"

  fun addExSet (externSet:LongsymbolSet.set, {longsymbol, ty, version}:I.exInfo) =
      LongsymbolSet.add(externSet, longsymbol)

  fun exSetMember (externSet:LongsymbolSet.set, {longsymbol, ty, version}:I.exInfo) =
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
        | (idstatus as I.IDEXVAR {used, ...}) =>
          (used := true; idstatus)
        | idstatus => idstatus)
      varE
  fun exceptionRepStrEntryWithSymbol {env=V.ENV {varE, tyE, strE}, strKind} = 
      let
        val varE = exceptionRepVarE varE
        val strE = exceptionRepStrE strE
      in
        {env=V.ENV{varE = varE, tyE = tyE, strE=strE}, strKind=strKind}
      end
  and exceptionRepStrE (V.STR envMap) =
      let
        val envMap = SymbolEnv.map exceptionRepStrEntryWithSymbol envMap
      in
        V.STR envMap
      end

  (* bug 245 *)
  fun exceptionExternVarE loc path varE =
      SymbolEnv.mapi
      (fn (name, I.IDEXN {id, longsymbol, ty}) =>
          let
            val longsymbol = Symbol.prefixPath(path,name)
          in
            I.IDEXEXN ({longsymbol=longsymbol, ty=ty, version=NONE}, ref false)
          end
        | (name, I.IDEXNREP {id, longsymbol, ty}) => 
          let
            val longsymbol = Symbol.prefixPath(path,name)
          in
            I.IDEXEXNREP ({longsymbol=longsymbol, ty=ty, version=NONE}, ref false)
          end
        | (name, idstatus) => idstatus)
      varE
  fun exceptionExternEnv loc path (V.ENV {varE, tyE, strE}) = 
      let
        val varE = exceptionExternVarE loc path varE
        val strE = exceptionExternStrE loc path strE
      in
        V.ENV{varE = varE, tyE = tyE, strE=strE}
      end
  and exceptionExternStrEntryWithSymbol loc path {env, strKind} = 
      {env=exceptionExternEnv loc path env, strKind=strKind}
  and exceptionExternStrE loc path (V.STR envMap) =
      let
        val envMap = 
            SymbolEnv.mapi 
              (fn (name, strEntryWithSymbol) => 
                  exceptionExternStrEntryWithSymbol 
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
      | I.IDEXVAR {exInfo, used, internalId} =>
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
      | I.IDEXEXN (exInfo,used) => 
        if exSetMember(externSet, exInfo) 
        then (externSet, icdecls)
        else
          (addExSet(externSet, exInfo), 
           I.ICEXTERNEXN exInfo ::icdecls)
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
              (fn (name, {env, strKind}, (externSet, icdecls)) =>
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

  fun evalPidec path (topEnv as {Env=env, FunE, SigE}) (externSet, pidec) =
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
                         ({exInfo={longsymbol=longsymbol, version=NONE, ty=I.TYERROR}, 
                           used=ref false, loc=Loc.noloc}))
                in
                  (case V.lookupId env longsymbol of
                     I.IDEXVAR {exInfo, internalId, used} =>
                     I.INST_EXVAR {exInfo=exInfo, used = used, loc=loc}
                   | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
                   | I.IDBUILTINVAR {primitive, ty} =>
                     I.INST_PRIM ({primitive=primitive, ty=ty}, loc)
                   | I.IDVAR id =>
                     error (E.InvalidOverloadInst("EI-010", {longsymbol = longsymbol}))
                   | I.IDVAR_TYPED _ =>
                     error (E.InvalidOverloadInst("EI-010", {longsymbol = longsymbol}))
                   | I.IDOPRIM _ =>
                     error (E.InvalidOverloadInst("EI-020", {longsymbol=longsymbol}))
                   | I.IDCON _ =>
                     error (E.InvalidOverloadInst("EI-030", {longsymbol=longsymbol}))
                   | I.IDEXN _ =>
                     error (E.InvalidOverloadInst("EI-040", {longsymbol=longsymbol}))
                   | I.IDEXNREP _ =>
                     error (E.InvalidOverloadInst("EI-050", {longsymbol=longsymbol}))
                   | I.IDEXEXN _ =>
                     error (E.InvalidOverloadInst("EI-060", {longsymbol=longsymbol}))
                   | I.IDEXEXNREP _ =>
                     error (E.InvalidOverloadInst("EI-060", {longsymbol=longsymbol}))
                   | I.IDSPECVAR _ => raise bug "SPEC id status"
                   | I.IDSPECEXN _ => raise bug "SPEC id status"
                   | I.IDSPECCON _ => raise bug "SPEC id status")
                  handle V.LookupId =>
                         error (E.VarNotFound("EI-070",{longsymbol=longsymbol}))
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
                            version=NONE}
              val idstatus = I.IDEXVAR {exInfo=exInfo,
                                        used=ref false, 
                                        internalId=NONE
                                       }
              val icdecl = I.ICEXTERNVAR exInfo
              val externSet = addExSet(externSet, exInfo)
            in
              (externSet, V.rebindId (V.emptyEnv, symbol, idstatus), [icdecl])
            end
          | AI.VALALIAS_EXTERN longsymbol =>
            let
              val loc = longsymbolToLoc longsymbol
            in
              (case V.findId(env, longsymbol) of
                 SOME (idstatus as I.IDEXVAR {exInfo, used, internalId}) => 
                 if exSetMember(externSet, exInfo) then
                   (externSet, V.rebindId  (V.emptyEnv, symbol, idstatus), nil)
                 else 
                   let
                     val icdecl = I.ICEXTERNVAR exInfo
                     val externSet = addExSet(externSet, exInfo)
                   in
                     (externSet, V.rebindId  (V.emptyEnv, symbol, idstatus), [icdecl])
                   end
               | SOME (idstatus as I.IDBUILTINVAR _) => 
                 (externSet, V.rebindId (V.emptyEnv, symbol, idstatus), nil)
               | SOME _ => 
                 (EU.enqueueError
                    (loc, E.ProvideVarIDExpected("EI-080", {longsymbol = longsymbol}));
                  (externSet, V.emptyEnv, nil))
               | NONE => 
                 (EU.enqueueError
                    (loc, E.ProvideUndefinedID("EI-080", {longsymbol = longsymbol}));
                  (externSet, V.emptyEnv, nil))
              )
            end
          | AI.VAL_BUILTIN {builtinSymbol, ty} =>
            let
              val loc = symbolToLoc builtinSymbol
              val builtinName = symbolToString builtinSymbol
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => I.TYPOLY(kindedTvars,ty)
            in
              case BuiltinPrimitive.findPrimitive builtinName of
                SOME primitive => 
                let
                  val idstatus = I.IDBUILTINVAR {primitive=primitive, ty=ty}
                in
                  (externSet, V.rebindId (V.emptyEnv, symbol, idstatus), nil)
                end
              | NONE => 
                (EU.enqueueError
                   (loc, E.PrimitiveNotFound("EI-080", {symbol = builtinSymbol}));
                 (externSet, V.emptyEnv, nil))
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
              val idstatus = I.IDOPRIM {id=id, overloadDef=decl, used=ref false, longsymbol=longsymbol}
              in
              (externSet, V.rebindId (V.emptyEnv, symbol, idstatus), [decl])
            end
        end
      | PI.PITYPE {tyvars, symbol, ty, loc} =>
        let
          val longsymbol = Symbol.prefixPath(path , symbol)
          val _ = EU.checkSymbolDuplication
                    (fn {symbol, eq} => symbol)
                    tyvars
                    (fn s => E.DuplicateTypParms("EI-090",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv env ty
          val tfun =
              case N.tyForm tvarList ty of
                N.TYNAME tfun => tfun
              | N.TYTERM ty =>
                let
                  val iseq = N.admitEq tvarList ty
                  val tfun =
                      I.TFUN_DEF {iseq=iseq,
                                  longsymbol=longsymbol,
                                  formals=tvarList,
                                  realizerTy=ty
                                 }
                in
                  tfun
                end
        in
          (externSet, V.rebindTstr (V.emptyEnv, symbol, V.TSTR tfun), nil)
        end               

      | PI.PIOPAQUE_TYPE {tyvars, symbol=tycon, runtimeTy, loc} =>
        (let
           val _ = EU.checkSymbolDuplication
                     (fn {symbol, eq} => symbol)
                     tyvars
                     (fn s => E.DuplicateTypParms("EI-090",s))
           val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
           val id = TypID.generate()
           val runtimeTy = Ty.evalRuntimeTy tvarEnv env runtimeTy
               handle Ty.EvalRuntimeTy =>
                      raise bug "no runtimeTy in evalRuntimeTy"
           val absTfun =
               I.TFUN_VAR
                 (I.mkTfv
                    (I.TFUN_DTY {id=id,
                                 iseq=false,
                                 formals=tvarList,
                                 runtimeTy= runtimeTy,
                                 conSpec=SymbolEnv.empty,
                                 conIDSet=ConID.Set.empty,
                                 longsymbol= Symbol.prefixPath(path,tycon), 
                                 (* bug foud in asai zemi *)
                                 liftedTys=I.emptyLiftedTys,
                                 dtyKind= I.DTY_INTERFACE
                                }
                    )
                 )
         in
           (externSet, V.rebindTstr (V.emptyEnv, tycon, V.TSTR absTfun), nil)
         end
         handle EvalRuntimeTy =>
                (EU.enqueueError
                   (loc, E.IlleagalBuiltinTy("EI-100", {symbol = tycon}));
                 (externSet, V.emptyEnv, nil)
                )
        )
      | PI.PIOPAQUE_EQTYPE {tyvars, symbol=tycon, runtimeTy, loc} =>
        (let
           val _ = EU.checkSymbolDuplication
                     (fn {symbol, eq} => symbol)
                     tyvars
                     (fn s => E.DuplicateTypParms("EI-090",s))
           val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
           val id = TypID.generate()
           val runtimeTy = Ty.evalRuntimeTy tvarEnv env runtimeTy
               handle Ty.EvalRuntimeTy =>
                      raise bug "no runtimeTy in evalRuntimeTy"
           val absTfun =
               I.TFUN_VAR
                 (I.mkTfv(
                  I.TFUN_DTY {id=id,
                              iseq=true,
                              formals=tvarList,
                              runtimeTy= runtimeTy,
                              conSpec=SymbolEnv.empty,
                              conIDSet=ConID.Set.empty,
                              longsymbol= Symbol.prefixPath(path, tycon),
                              (* bug foud in asai zemi *)
                              liftedTys=I.emptyLiftedTys,
                              dtyKind= I.DTY_INTERFACE
                             }
                  )
                 )
         in
           (externSet, V.rebindTstr (V.emptyEnv, tycon, V.TSTR absTfun), nil)
         end
         handle EvalRuntimeTy =>
                (EU.enqueueError
                   (loc, E.IlleagalBuiltinTy("EI-100", {symbol = tycon}));
                 (externSet, V.emptyEnv, nil)
                )
        )

      | PI.PITYPEBUILTIN {symbol, builtinSymbol, loc} =>
        (case BuiltinTypes.findTstrInfo (Symbol.symbolToString builtinSymbol) of
           NONE => 
           (EU.enqueueError
              (loc, E.BuiltinTyNotFound("EI-100", {symbol = builtinSymbol}));
            (externSet, V.emptyEnv, nil)
           )
         | SOME (tstrInfo as {varE, ...}) => 
           let
             val tstr = V.TSTR_DTY tstrInfo
             val env = V.reinsertTstr (V.emptyEnv, symbol, tstr)
             val env = V.envWithVarE (env, varE)
           in
             (externSet, env, nil)
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
          (externSet, env, icdecls)
        end

      | PI.PITYPEREP {symbol=tycon, longsymbol=path, loc} =>
        (* datatype foo = datatype bar *)
        (
         case V.findTstr(env, path) of
           NONE => (EU.enqueueError
                      (loc, E.DataTypeNameUndefined("EI-110", {longsymbol = path}));
                    (externSet, V.emptyEnv, nil))
         | SOME tstr =>
           let
             val (tstr, varE) =
                 case tstr of
                   V.TSTR_DTY {tfun, varE, formals, conSpec} => (tstr, varE)
                 | _ => 
                   (EU.enqueueError
                      (loc, E.DataTypeNameExpected("EI-130", {longsymbol = path}));
                    (tstr, SymbolEnv.empty))
             val env = V.rebindTstr (V.emptyEnv, tycon, tstr)
             val env = SymbolEnv.foldri
                         (fn (name, idstatus, env) =>
                             V.rebindId(env, name, idstatus))
                         env
                         varE
           in
             (externSet, env, nil)
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
          val exInfo = {longsymbol=longsymbol, ty=ty, version=NONE}
          val idstatus = I.IDEXEXN (exInfo, ref false)
          val icdecl = I.ICEXTERNEXN exInfo
          val externSet = addExSet(externSet, exInfo)
        in
          (externSet, V.rebindId  (V.emptyEnv, symbol, idstatus), [icdecl])
        end

      | PI.PIEXCEPTIONREP {symbol, longsymbol, loc} =>
        (
         case V.findId(env, longsymbol) of
           NONE =>
           (
            EU.enqueueError
              (loc, E.ExceptionNameUndefined("EI-140", {longsymbol = longsymbol}));
            (externSet, V.emptyEnv, nil))
         | SOME (idstatus as I.IDEXN exnInfo) => 
           (externSet, V.rebindId  (V.emptyEnv, symbol, I.IDEXNREP exnInfo), nil)
         | SOME (idstatus as I.IDEXNREP exnInfo) =>
           (externSet, V.rebindId  (V.emptyEnv, symbol, I.IDEXNREP exnInfo), nil)
         | SOME (idstatus as I.IDEXEXN (exInfo,used)) => 
           if exSetMember(externSet, exInfo) then
             (externSet, V.rebindId  (V.emptyEnv, symbol, I.IDEXEXNREP (exInfo, used)), nil)
           else 
             let
               val icdecl = I.ICEXTERNEXN exInfo
               val externSet = addExSet(externSet, exInfo)
             in
               (externSet, V.rebindId  (V.emptyEnv, symbol, I.IDEXEXNREP (exInfo,used)), [icdecl])
             end
         | SOME (idstatus as I.IDEXEXNREP (exInfo, used)) => 
           if exSetMember(externSet, exInfo) then
             (externSet, V.rebindId  (V.emptyEnv, symbol, I.IDEXEXNREP (exInfo, used)), nil)
           else 
             let
               val icdecl = I.ICEXTERNEXN exInfo
               val externSet = addExSet(externSet, exInfo)
             in
               (externSet, V.rebindId  (V.emptyEnv, symbol, I.IDEXEXNREP (exInfo, used)), [icdecl])
             end
         | _ => 
           (EU.enqueueError
              (loc, E.ExceptionExpected("EI-150", {longsymbol = longsymbol}));
            (externSet, V.emptyEnv, nil))
        )

      | PI.PISTRUCTURE {symbol, strexp, loc} =>
        let
          val (externSet, strEntry, icdecls) = 
              evalPistr (Symbol.prefixPath(path,symbol)) topEnv (externSet, strexp)
          val env = V.rebindStr (V.emptyEnv, symbol, strEntry)
        in
          (externSet, env, icdecls)
        end
          
  and evalPistr path topEnv (externSet, pistrexp) = 
      case pistrexp of
        PI.PISTRUCT {decs, loc} =>
        let
          val strKind = V.STRENV (StructureID.generate())
          val (externSet, env, icdecls) = 
              foldl
                (fn (decl, (externSet, env, icdecls)) =>
                    let
                      val evalTopEnv = V.topEnvWithEnv (topEnv,env)
                      val (externSet, newEnv, newicdecls) = evalPidec path evalTopEnv (externSet, decl)
                    in
                      (externSet, V.unionEnv "210" (env, newEnv), icdecls@newicdecls)
                    end
                )
                (externSet, V.emptyEnv, nil)
                decs
        in
          (externSet, {env=env, strKind=strKind}, icdecls)
        end
      | PI.PISTRUCTREP{longsymbol, loc} => 
        let
          val {Env,...} = topEnv
        in
          case V.findStr(Env, longsymbol) of
            NONE => 
            (
             EU.enqueueError
               (loc, E.ExceptionNameUndefined("EI-140", {longsymbol = path}));
             (externSet, 
              {env=V.emptyEnv, strKind=V.STRENV(StructureID.generate())},
              nil)
            )
          | SOME strEntryWithSymbol => 
            let
              val {strKind, env} = exceptionRepStrEntryWithSymbol strEntryWithSymbol
              val env = V.replaceLocEnv loc env
            in
              (externSet, {strKind=strKind, env=env}, nil)
            end
        end
      | PI.PIFUNCTORAPP{functorSymbol, argument, loc} => 
        let
          val copyPath = path
          val {Env, FunE,...} = topEnv
        in
          case (V.findFunETopEnv(topEnv, functorSymbol), V.findStr(Env, argument)) of
            (NONE, _) => 
            (EU.enqueueError
               (loc, E.FunctorNameUndefined("EI-140", {symbol = functorSymbol}));
             (externSet, 
              {env=V.emptyEnv, strKind=V.STRENV(StructureID.generate())},
              nil)
            )
          | (_, NONE) => 
            (EU.enqueueError
               (loc, E.StructureNameUndefined("EI-140", {longsymbol = argument}));
             (externSet, 
              {env=V.emptyEnv, strKind=V.STRENV(StructureID.generate())},
              nil))
          | (SOME funEEntry, SOME {env=argStrEnv, strKind}) =>
            let
              val {id=funId,version, used,argSigEnv,argStrName,argStrEntry,dummyIdfunArgTy,polyArgTys,
                   typidSet,exnIdSet,bodyEnv,bodyVarExp}
                  = funEEntry
              val argId = case strKind of
                            V.STRENV id => id
                          | V.FUNAPP{id,...} => id
                          | _ => raise bug "non strenv in functor arg"
              val structureId = StructureID.generate()
              fun instVarE (varE,actualVarE) {tvarS, conIdS, exnIdS} =
                let
                  val conIdS =
                        SymbolEnv.foldri
                          (fn (name, idstatus, conIdS) =>
                              case idstatus of
                                I.IDCON {id, longsymbol, ty} =>
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
                    {tvarS=tvarS,exnIdS=exnIdS, conIdS=conIdS}
                  end
              fun instTfun path (tfun, actualTfun)
                           (subst as {tvarS, conIdS, exnIdS}) =
                  let
                    val tfun = I.derefTfun tfun
                    val actualTfun = I.derefTfun actualTfun
                  in
                    case tfun of
                      I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {dtyKind,...})) =>
                      (case actualTfun of
                         I.TFUN_VAR(tfv2 as ref (tfunkind as I.TFUN_DTY _)) =>
                         (tfv1 := tfunkind;
                          {tvarS=tvarS,
                           exnIdS=exnIdS,
                           conIdS=conIdS}
                         )
                       | I.TFUN_DEF _ =>
                         (case dtyKind of
                            I.FUNPARAM => 
                            (EU.enqueueError
                               (loc, E.FunctorParamRestriction("440",{longsymbol=path}));
                             subst)
                          | _ => raise bug "tfun def"
                         )
                       | I.TFUN_VAR _ => raise bug "tfun var"
                      )
                    | I.TFUN_DEF{longsymbol, iseq, formals=nil, realizerTy= I.TYVAR tvar} =>
                      let
                        val ty =I.TYCONSTRUCT{tfun=actualTfun,args=nil}
                        val ty = N.reduceTy TvarMap.empty ty
                      in
                        {tvarS=TvarMap.insert(tvarS,tvar,ty),
                         conIdS=conIdS,
                         exnIdS=exnIdS
                        }
                      end
                    | _ => subst
                  end
              fun instTstr 
                    path (tstr, actualTstr)
                    (subst as {tvarS,conIdS,exnIdS}) =
                  (
                   case tstr of
                     V.TSTR tfun =>
                     (
                      case actualTstr of
                        V.TSTR actualTfun =>
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
                    (fn (name, {env, strKind}, subst) =>
                        let
                          val actualEnv = case SymbolEnv.find(actualEnvMap, name) of
                                            SOME {env, strKind} => env 
                                          | NONE => raise bug "actualEnv not found"
                        in
                          instEnv (Symbol.prefixPath(path,name)) (env, actualEnv) subst
                        end
                    )
                    subst
                    envMap

              fun setPathIdstatus copyPath idstatus =
                  case idstatus of
                    I.IDVAR varId => idstatus
                  | I.IDVAR_TYPED _ => idstatus
                  | I.IDEXVAR {exInfo={longsymbol, version, ty},used,internalId} =>
                    I.IDEXVAR
                      {exInfo={longsymbol= Symbol.concatPath(copyPath , longsymbol),
                               ty=ty,
                               version=version},
                       used=used,
                       internalId=internalId}
                  | I.IDEXVAR_TOBETYPED {longsymbol, id, version} =>
                    I.IDEXVAR_TOBETYPED
                      {longsymbol= Symbol.concatPath(copyPath, longsymbol), id=id, version=version}
                  | I.IDBUILTINVAR _ => idstatus
                  | I.IDCON _ => idstatus
                  | I.IDEXN _ => idstatus
                  | I.IDEXNREP _ => idstatus
                  | I.IDEXEXN  ({longsymbol, ty, version}, used) =>
                    I.IDEXEXN  
                      ({longsymbol= Symbol.concatPath(copyPath,longsymbol), ty=ty, version=version}, used)
                  | I.IDEXEXNREP ({longsymbol, ty, version}, used) =>
                    I.IDEXEXNREP
                      ({longsymbol = Symbol.concatPath(copyPath,longsymbol), ty=ty, version=version}, used)
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
                       (fn {env, strKind} => 
                           {env=setPathEnv copyPath env, strKind=strKind})
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
                  V.reinsertStr(V.reinsertStr(V.emptyEnv, argStrSymbol, argStrEntry),
                                bodyStrSymbol,
                                {env=bodyEnv, strKind=V.STRENV(StructureID.generate())})
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

              val {env=argEnv, strKind=_} = 
                  case V.checkStr(tempEnv, argStrLongsymbol) of
                    SOME strEntry => strEntry
                  | NONE => raise bug "impossible (2)"
              val {env=bodyEnv, ...} = 
                  case V.checkStr(tempEnv, bodyStrLongsymbol) of
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
              val bodyEnv = S.substEnv subst bodyEnv
                  handle e => raise e
              val bodyEnv = N.reduceEnv bodyEnv 
                  handle e => raise e

              val bodyEnv = exceptionExternEnv loc nil bodyEnv
              val bodyEnv = setPathEnv copyPath bodyEnv
              val bodyEnv = V.replaceLocEnv loc bodyEnv

              (* bug 243? *)
              val pathTfvListList = L.setLiftedTysEnv bodyEnv
                  handle e => raise e

              val (externSet, icdecls) = genTypedExternVarsEnv path bodyEnv (externSet, nil)

              val strKind = V.FUNAPP {id=structureId, funId=funId, argId=argId}
            in
              (externSet, {env=bodyEnv, strKind=strKind}, icdecls)
            end
            handle SC.SIGCHECK => (externSet, {env=V.emptyEnv, strKind=V.STRENV (StructureID.generate())}, nil)
        end (* end of pidec *)
      handle exn => raise bug "uncaught exception in evalPistr"

  fun internalizeIdstatus (pathSet,idstatus) =
      case idstatus of
        I.IDEXEXN (exInfo as {longsymbol, ty, version}, used) =>
        if exSetMember(pathSet, exInfo) then (pathSet, idstatus)
          else
            let
              val pathSet = addExSet(pathSet, exInfo)
              val newId = ExnID.generate() (* dummy *)
            in
              (pathSet, I.IDEXN {id=newId, longsymbol=longsymbol, ty= ty})
            end
      | _ => (pathSet, idstatus)

  fun internalizeEnv (pathSet, V.ENV {tyE, varE, strE=V.STR envMap}) =
      let
        val (pathSet, varE) = 
            SymbolEnv.foldri
              (fn (name, idstatus, (pathSet, varE)) =>
                  let
                    val (pathSet, idstatus)=  internalizeIdstatus (pathSet, idstatus)
                    val varE = SymbolEnv.insert(varE, name, idstatus)
                  in
                    (pathSet, varE)
                  end
              )
              (pathSet, SymbolEnv.empty)
              varE
        val (pathSet, strE) = 
            let
              val (pathSet, envMap) =
                  SymbolEnv.foldri
                    (fn (name, {env, strKind}, (pathSet, envMap)) => 
                        let
                          val (pathSet, env) = internalizeEnv (emptyExSet, env)
                          val envMap = SymbolEnv.insert(envMap, name, {env=env, strKind=strKind})
                        in
                          (pathSet, envMap)
                        end
                    )
                    (pathSet, SymbolEnv.empty)
                    envMap
            in
              (pathSet, V.STR envMap)
            end
      in
        (pathSet, V.ENV{tyE=tyE, varE=varE, strE=strE})
      end
  val internalizeEnv = fn env => #2 (internalizeEnv (emptyExSet, env))
  fun evalFunDecl topEnv {functorSymbol,
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

        val topArgEnv = V.reinsertStr (V.emptyEnv, strSymbol, argStrEntry)
(*
        val topArgEnv = 
            V.ENV {varE=SymbolEnv.empty,
                   tyE=SymbolEnv.empty,
                   strE=V.STR (SymbolEnv.singleton(argStrName, argStrEntry))
                  }
*)
        val evalEnv = V.topEnvWithEnv (topEnv, topArgEnv)

        val startTypid = TypID.generate()

        val (_, {env=bodyInterfaceEnv,strKind},_) = evalPistr nil evalEnv (emptyExSet, bodyStr)
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
            | _ => 
              (
               raise bug "*** VARTOTY ***"
              )

        val bodyTy =
            case allVars of
              nil => BT.unitITy
            | _ => I.TYRECORD (Utils.listToFields (map varToTy allVars))
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
              I.TYPOLY(map (fn x => (x, I.UNIV)) extraTvars,
                        I.TYFUNM([ty], functorTy1))
        val functorTy =
            case functorTy2 of
              I.TYPOLY _ => functorTy2
            | I.TYFUNM _ => functorTy2
            | _ => I.TYFUNM([BT.unitITy], functorTy2)
        val longsymbol = [mkSymbol FUNCORPREFIX loc, functorSymbol]
        val exInfo = {longsymbol=longsymbol, ty=functorTy, version=NONE}
        val decl = I.ICEXTERNVAR exInfo
        val functorExp = I.ICEXVAR {longsymbol=longsymbol,
                                    exInfo=exInfo}

        val funEEntry:V.funEEntry =
            {id = FunctorID.generate(),
             version = NONE,
             used = ref false,
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
            
        val funE =  V.rebindFunE(SymbolEnv.empty, functorSymbol, funEEntry)
        val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
      in
        (returnTopEnv, [decl])
      end

  fun evalPitopdec topEnv (externSet, pitopDec) =
      case pitopDec of
        PI.PIDEC pidec => 
        let
          val (_, returnEnv, icdecls) = evalPidec nilPath topEnv (externSet, pidec)
        in
          (externSet, V.topEnvWithEnv(V.emptyTopEnv, returnEnv), icdecls)
        end
      | PI.PIFUNDEC fundec =>
        let
          val (returnTopEnv, icdecls) = evalFunDecl topEnv fundec
        in
          (externSet, returnTopEnv, icdecls)
        end

  fun evalPitopdecList topEnv (externSet, pitopdecList) =
      (foldl
         (fn (pitopdec, (externSet, returnTopEnv, icdecls)) =>
             let
               val evalTopEnv = V.topEnvWithTopEnv (topEnv, returnTopEnv)
               val (externSet, newTopEnv, newicdecls) = evalPitopdec evalTopEnv (externSet, pitopdec)
               val loc = PI.pitopdecLoc pitopdec
             in
               (externSet, V.unionTopEnv "211" (returnTopEnv,newTopEnv), icdecls @ newicdecls)
             end
         )
         (externSet, V.emptyTopEnv, nil)
         pitopdecList
      )
      handle exn => raise exn
             (* raise bug "uncaught exception in evalPitopdecList" *)

  fun evalInterfaceDec env ({interfaceId,requiredIds=idLocList,provideTopdecs}
                            :PI.interfaceDec, IntEnv) =
      let
        val evalTopEnv =
            foldl
            (fn ({id,loc}, evalTopEnv) =>
                let
                  val newTopEnv = 
                      case InterfaceID.Map.find (IntEnv, id) of
                        NONE => raise bug "InterfaceID undefined"
                      | SOME {topEnv,...} => topEnv
                in
                  V.unionTopEnv "212" (evalTopEnv, newTopEnv)
                end
            )
            env
            idLocList
        val (_, topEnv, icdecls) = evalPitopdecList evalTopEnv (emptyExSet, provideTopdecs)
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
end
end
