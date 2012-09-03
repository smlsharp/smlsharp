(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : 001 *)
structure NameEval :
sig
  val nameEval : {topEnv: NameEvalEnv.topEnv, version: int option,
                  systemDecls: IDCalc.icdecl list}
                 -> PatternCalcInterface.compileUnit
                    -> NameEvalEnv.topEnv * IDCalc.icdecl list * UserError.errorInfo list
  val evalRequire
      : NameEvalEnv.topEnv * IDCalc.icdecl list
        -> PatternCalcInterface.compileUnit
        -> NameEvalEnv.topEnv * IDCalc.icdecl list * UserError.errorInfo list
  val evalBuiltin : PatternCalcInterface.pitopdec list
                    -> NameEvalEnv.topEnv * 
                       {conEnv: Types.conInfo SEnv.map,
                        exnEnv: {path:IDCalc.path, ty:Types.ty} SEnv.map,
                        primEnv: Types.primInfo SEnv.map,
                        tyConEnv: Types.tyCon SEnv.map} BuiltinName.env * 
                       IDCalc.icdecl list
end
=
struct
local
  structure I = IDCalc
  structure BV = BuiltinEnv
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure V = NameEvalEnv
  structure L = SetLiftedTys
  structure S = Subst
  structure TF = TfunVars
  structure P = PatternCalc
  structure PI = PatternCalcInterface
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = Absyn
  structure N = NormalizeTy
  structure Sig = EvalSig
  structure EI = NameEvalInterface
  structure CP = CheckProvide
  structure FU = FunctorUtils
  structure SC = SigCheck

  fun bug s = Control.Bug ("NameEval: " ^ s)

  val DUMMYIDFUN = "id"

 (* This is to avoid name conflict in functor names and variable names *)
  val FUNCORPREFIX = "_"

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


  type path = string list
  val nilPath = nil : string list
  fun pathToString nil = ""
    | pathToString (h::t) = h ^ pathToString t

  fun generateFunVar path funIdPat =
    let
      val {funVarInfo, funName} =
          case funIdPat of
            P.PLPATID ([funName], loc) =>
            {funVarInfo={path=path@[funName], id=VarID.generate()},
             funName=funName}
          | _ =>
            (EU.enqueueError
               (P.getLocPat funIdPat,
                E.IlleagalFunID ("010",{pat = funIdPat}));
             {funVarInfo = {path=path @ ["_"], id = VarID.generate()},
              funName = "_"}
            )
    in
      {name = funName, varInfo = funVarInfo}
    end

  (* type function variable substitution *)
  type tfvSubst = (I.tfunkind ref) TfvMap.map

  fun evalPlpat path (tvarEnv:Ty.tvarEnv) (env:V.env) plpat : V.env * I.icpat =
      let
        val evalPat = evalPlpat path tvarEnv env
        fun evalTy' ty = Ty.evalTy tvarEnv env ty
        fun checkIdstatus NONE = true
          | checkIdstatus (SOME (I.IDVAR _)) = true
          | checkIdstatus (SOME (I.IDVAR_TYPED _)) = true
          | checkIdstatus (SOME (I.IDEXVAR {used,...})) = (used:=true; true)
          | checkIdstatus (SOME (I.IDEXVAR_TOBETYPED _)) = raise bug "IDEXVAR_TOBETYPED"
          | checkIdstatus (SOME (I.IDBUILTINVAR _)) = true
          | checkIdstatus (SOME (I.IDCON _)) = false
          | checkIdstatus (SOME (I.IDEXN _)) = false
          | checkIdstatus (SOME (I.IDEXNREP _)) = false
          | checkIdstatus (SOME (I.IDEXEXN {used,...})) = (used:=true; false)
          | checkIdstatus (SOME (I.IDEXEXNREP {used,...})) = (used:=true; false)
          | checkIdstatus (SOME (I.IDOPRIM {used,...})) = (used:=true; true)
          | checkIdstatus (SOME (I.IDSPECVAR _)) = raise bug "spec idstatus"
          | checkIdstatus (SOME (I.IDSPECEXN _)) = raise bug "spec idstatus"
          | checkIdstatus (SOME I.IDSPECCON) = raise bug "spec idstatus"
      in
        case plpat of
          P.PLPATWILD loc => (V.emptyEnv, I.ICPATWILD loc)
        | P.PLPATID (longid, loc) =>
          let
            fun makeCon identry =
                case identry of
                  SOME (I.IDCON {id, ty}) =>
                  I.ICPATCON ({id=id,path=longid, ty=ty}, loc)
                | SOME (I.IDEXN {id,ty})=>
                  I.ICPATEXN ({id=id,ty=ty, path=longid}, loc)
                | SOME (I.IDEXNREP {id,ty})=>
                  I.ICPATEXN ({id=id,ty=ty, path=longid}, loc)
                | SOME (I.IDEXEXN {path,ty, used, loc=_, version})=>
                  let
                    val path = I.setVersion(path, version)
                  in
                    (used := true;
                     I.ICPATEXEXN ({path=path, ty=ty}, loc)
                    )
                  end
                | SOME (I.IDEXEXNREP {path,ty, used, loc=_, version})=>
                  let
                    val path = I.setVersion(path, version)
                  in
                    (used := true;
                     I.ICPATEXEXN ({path=path, ty=ty}, loc)
                    )
                  end
                | SOME (I.IDBUILTINVAR _) =>
                  raise bug "IDBUILTINVAR to makeCon"
                | SOME (I.IDVAR _) => raise bug "IDVAR to makeCon"
                | SOME (I.IDVAR_TYPED _) => raise bug "IDVAR_TYPED to makeCon"
                | SOME (I.IDEXVAR _) => raise bug "IDEXVAR to makeCon"
                | SOME (I.IDEXVAR_TOBETYPED _) => raise bug "IDEXVAR_TOBETYPED to makeCon"
                | SOME (I.IDOPRIM _) => raise bug "IDOPRIM to makeCon"
                | SOME (I.IDSPECVAR _)=> raise bug "spec status to makeCon"
                | SOME (I.IDSPECEXN _)=> raise bug "spec status to makeCon"
                | SOME I.IDSPECCON=> raise bug "spec status to makeCon"
                | NONE => raise bug "NONE to makeCon"
          in
            case longid of
              nil => raise bug "empty longid"
            | [name] =>
              let
                val identry = V.findId (env, longid)
              in
                if checkIdstatus identry then
                  let
                    val varId = VarID.generate()
                    val varInfo = {path=path@longid, id=varId}
                    val env = V.rebindId(V.emptyEnv, name, I.IDVAR varId)
                  in
                    (env, I.ICPATVAR (varInfo, loc))
                  end
                else
                  (V.emptyEnv, makeCon identry)
              end
            | _ :: _ =>
              let
                val identry = V.findId (env, longid)
              in
                if checkIdstatus identry then
                  (
                   (EU.enqueueError
                      (loc,
                       E.ConNotFound("020", {longid = longid}));
                    (V.emptyEnv, I.ICPATERROR loc)
                   )
                  )
                else
                  (V.emptyEnv, makeCon identry)
              end
          end
        | P.PLPATCONSTANT (constant, loc) =>
          (V.emptyEnv, I.ICPATCONSTANT(constant,loc))
        | P.PLPATCONSTRUCT (plpat1, plpat2, loc) =>
          let
            val (env1, icpat1) = evalPat plpat1
            val (env2, icpat2) = evalPat plpat2
            val env = V.unionEnv "200"  loc (env1, env2)
            fun stripTy icpat tyList = 
                case icpat of 
                  I.ICPATTYPED (icpat, ty, loc) => stripTy icpat (tyList@[ty])
                | _ => (icpat, tyList)
            val (icpat3, _) = stripTy icpat1 nil
            val icpat1 =
                case icpat3 of
                  I.ICPATERROR loc => icpat1
                | I.ICPATWILD loc =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("030",{pat = plpat}));
                   I.ICPATERROR loc)
                | I.ICPATVAR _ =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("040", {pat = plpat}));
                   I.ICPATERROR loc)
                | I.ICPATCON (conInfo, loc) => icpat1
                | I.ICPATEXN (exnInfo, loc) => icpat1
                | I.ICPATEXEXN ({path, ty}, loc) => icpat1
                | I.ICPATCONSTANT (constant, loc) => 
                  (EU.enqueueError
                     (loc, E.NonConstructor("050", {pat = plpat}));
                   I.ICPATERROR loc)
                | I.ICPATCONSTRUCT {con, arg, loc} =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("060", {pat = plpat}));
                   I.ICPATERROR loc)
                | I.ICPATRECORD {flex, fields, loc} =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("070", {pat = plpat}));
                   I.ICPATERROR loc)
                | I.ICPATLAYERED {patVar, tyOpt, pat, loc} =>
                  (EU.enqueueError
                     (loc, E.NonConstructor("080", {pat = plpat}));
                   I.ICPATERROR loc)
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
            val (returnEnv, icpatfieldList) =
                U.evalList
                  {eval=evalField,
                   emptyEnv=V.emptyEnv,
                   unionEnv=V.unionEnv "201" loc}
                  patfieldList
          in
            (returnEnv,
             I.ICPATRECORD {flex=bool, fields=icpatfieldList, loc=loc}
            )
          end
        | P.PLPATLAYERED (string, tyOption, plpat, loc) =>
          let
            val identry = V.findId (env, [string])
            val varId =
                if checkIdstatus identry then VarID.generate()
                else
                  (EU.enqueueError
                     (loc, E.VarPatExpected("090", {longid = [string]}));
                   VarID.generate())
            val varInfo = {path = path@[string], id = varId}
            val returnEnv = V.rebindId(V.emptyEnv, string, I.IDVAR varId)
            val tyOption = Option.map evalTy' tyOption
            val (env1, icpat) = evalPat plpat
            val returnEnv = V.unionEnv "202" loc (returnEnv, env1)
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
      SEnv.map
      (fn (I.IDEXN info) => I.IDEXNREP info
        | (idstatus as I.IDEXVAR {used, ...}) =>
          (used := true; idstatus)
        | idstatus => idstatus)
      varE
  fun exceptionrepStrEntry {env=V.ENV {varE, tyE, strE}, strKind} = 
      let
        val varE = exceptionRepVarE varE
        val strE = exceptionRepStrE strE
      in
        {env=V.ENV{varE = varE, tyE = tyE, strE=strE}, strKind=strKind}
      end
  and exceptionRepStrE (V.STR envMap) =
      let
        val envMap = SEnv.map exceptionrepStrEntry envMap
      in
        V.STR envMap
      end

  fun optimizeValBind (icpat, icexp) (icpatIcexpListRev, env) = 
      let
        val _ = U.print "icpat\n"
        val _ = U.printPat icpat
        val _ = U.print "\n"
        val _ = U.print "icexp\n"
        val _ = U.printExp icexp
        val _ = U.print "\n"
        val _ = U.print "env\n"
        val _ = U.printEnv env
        val _ = U.print "\n"
      in
        case icpat of 
          I.ICPATVAR (varInfo as {path,...}, loc) => 
          let
            val name = List.last path
          in
            (case icexp of
               I.ICVAR (varInfo, loc) => 
               (icpatIcexpListRev, V.rebindId(env, name, I.IDVAR (#id varInfo)))
             | I.ICEXVAR ({path,ty},loc) => 
               (icpatIcexpListRev, 
                V.rebindId(env, 
                           name, 
                           I.IDEXVAR {path=path, ty=ty, used=ref false, loc=loc, 
                                      version=NONE, internalId=NONE} 
               (* used flag is only relevant for those in topEnv *)
               ))
             | I.ICBUILTINVAR {primitive, ty, loc} =>
               (icpatIcexpListRev, V.rebindId(env, name, I.IDBUILTINVAR {primitive=primitive, ty=ty}))
             | _ => ((icpat, icexp)::icpatIcexpListRev, env)
            )
          end
        | _ => ((icpat, icexp)::icpatIcexpListRev, env)
      end
  (* P.PLCOREDEC (pdecl, loc) *)
  fun evalPdecl (path:I.path) (tvarEnv:Ty.tvarEnv) (env:V.env) pdecl
      : V.env * I.icdecl list =
      case pdecl of
        P.PDVAL(scopedTvars, plpatPlexpList, loc) =>
        let
          val (tvarEnv, scopedTvars) =
              Ty.evalScopedTvars loc tvarEnv env scopedTvars
          val (returnEnv, icpatIcexpListRev) =
              foldl
                (fn ((plpat, plexp), (returnEnv, icpatIcexpListRev)) =>
                    let
                      val icexp = evalPlexp tvarEnv env plexp
                      val (newEnv, icpat) = evalPlpat path tvarEnv env plpat
                      val (icpatIcexpListRev, newEnv) = optimizeValBind (icpat, icexp) (icpatIcexpListRev, newEnv)
                      val returnEnv = V.unionEnv "203" loc (returnEnv, newEnv)
                    in
(*
                      (returnEnv, (icpat, icexp)::icpatIcexpListRev)
*)
                      (returnEnv, icpatIcexpListRev)
                    end
                )
                (V.emptyEnv, nil)
                plpatPlexpList
        in
          (returnEnv,[I.ICVAL (scopedTvars, List.rev icpatIcexpListRev, loc)])
        end
      | P.PDDECFUN (scopedTvars, fundeclList, loc) =>
        let
          val (tvarEnv, guard) = Ty.evalScopedTvars loc tvarEnv env scopedTvars
          val declList = map (fn (x,y)=>(generateFunVar path x,y)) fundeclList
          val _ = EU.checkNameDuplication
                    (fn ({name, varInfo}, rules) => name)
                    declList
                    loc
                    (fn s => E.DuplicateFunVarInFunDecl("100",s))
          val returnEnv =
              foldl
                (fn (({name, varInfo, ...}, _), returnEnv) =>
                    V.rebindId(returnEnv, name, I.IDVAR (#id varInfo))
                )
                V.emptyEnv
                declList
          val evalEnv = V.envWithEnv (env, returnEnv)
          val fundeclList =
              map
                (fn ({name, varInfo}, rules) =>
                    {funVarInfo = varInfo,
                     rules = map (evalRule tvarEnv evalEnv loc) rules
                    }
                )
                declList
        in
          (returnEnv, [I.ICDECFUN{guard=guard, funbinds=fundeclList, loc=loc}])
        end
      | P.PDVALREC (scopedTvars, plpatPlexpList, loc) =>
        let
          val (tvarEnv, guard) = Ty.evalScopedTvars loc tvarEnv env scopedTvars
          val recList =
              map (fn(x,y) => (generateFunVar path x,y)) plpatPlexpList
          val _ = EU.checkNameDuplication
                    (fn ({name, varInfo}, body) => name)
                    recList
                    loc
                    (fn s => E.DuplicateVarInRecDecl("110",s))
          val returnEnv =
              foldl
                (fn (({name, varInfo, ...}, _),returnEnv) =>
                    (V.rebindId(returnEnv, name, I.IDVAR (#id varInfo)))
                )
                V.emptyEnv
                recList
          val evalEnv = V.envWithEnv (env, returnEnv)
          val recbindList =
              map
                (fn ({name, varInfo}, body) =>
                    {varInfo = varInfo,
                     body = evalPlexp tvarEnv evalEnv body}
                )
                recList
        in
          (returnEnv, [I.ICVALREC {guard=guard, recbinds=recbindList, loc=loc}])
        end
      | P.PDTYPE (typbindList, loc) =>
        let
          val _ = EU.checkNameDuplication
                    (fn (tvarList, string, ty) => string)
                    typbindList
                    loc
                    (fn s => E.DuplicateTypName("120", s))
          val returnEnv =
              foldl
                (fn ((tvarList, string, ty), returnEnv) =>
                    let
                      val _ = EU.checkNameDuplication
                                (fn {name, eq} => name)
                                tvarList
                                loc
                                (fn s => E.DuplicateTypParms("130",s))
                      val (tvarEnv, tvarList) = Ty.genTvarList tvarEnv tvarList
                      val ty = Ty.evalTy tvarEnv env ty
                      val tfun =
                          case N.tyForm tvarList ty of
                            N.TYNAME {tfun,...} => tfun
                          | N.TYTERM ty =>
                            let
                              val iseq = N.admitEq tvarList ty
                              val tfun =
                                  I.TFUN_DEF {iseq=iseq,
                                              formals=tvarList,
                                              realizerTy=ty
                                             }
                            in
                              tfun
                            end
                    in
                      V.rebindTstr (returnEnv, string, V.TSTR tfun)
                    end
                )
                V.emptyEnv
                typbindList
        in
          (returnEnv, nil)
        end

      | P.PDDATATYPE (datadeclList, loc) =>
        Ty.evalDatatype path env (datadeclList, loc)

      | P.PDREPLICATEDAT (string, longid, loc) =>
        (case (V.findTstr (env, longid)) handle e => raise e of
           NONE => (EU.enqueueError
                      (loc, E.DataTypeNameUndefined("140", {longid = longid}));
                    (V.emptyEnv, nil))
         | SOME tstr => 
           let
             val returnEnv = V.rebindTstr(V.emptyEnv, string, tstr)
             val varE = 
                 case tstr of
                   V.TSTR tfun => SEnv.empty
                 | V.TSTR_DTY {varE,...} => varE
             val returnEnv = V.envWithVarE(returnEnv, varE)
           in
             (returnEnv, nil)
           end
        )
      | P.PDABSTYPE (datadeclList, pdeclList, loc) =>
        raise bug "abstype not implemented."

      | P.PDEXD (plexbindList, loc) =>
        let
          val _ = EU.checkNameDuplication
                    (fn P.PLEXBINDDEF (name, _,_) => name
                      | P.PLEXBINDREP (name,_,_) => name)
                    plexbindList
                    loc
                    (fn s => E.DuplicateExnName("150",s))
          val (exEnv, exdeclList) =
              foldl
                (fn (plexbind, (exEnv, exdeclList)) =>
                    case plexbind of
                      P.PLEXBINDDEF (string, tyOption, loc) =>
                      let
                        val ty =
                            case tyOption of
                              NONE => BV.exnTy
                            | SOME ty => 
                              I.TYFUNM([Ty.evalTy tvarEnv env ty],
                                        BV.exnTy)
                        val newExnId = ExnID.generate()
                        val exnInfo = {path=path@[string], ty=ty, id=newExnId}
                        val exEnv =
                            V.rebindId(exEnv,
                                       string,
                                       I.IDEXN {id=newExnId,ty=ty})
                      in
                        (exEnv,
                         exdeclList@[{exnInfo=exnInfo,loc=loc}]
                        )
                      end
                    | P.PLEXBINDREP (string, longid, loc) =>
                      case V.findId (env, longid) of
                        NONE =>
                        (EU.enqueueError
                           (loc,E.ExnUndefined("160",{longid = longid}));
                         (exEnv, exdeclList)
                        )
                      | SOME(I.IDEXN exnInfo) =>
                        (V.rebindId(exEnv, string, I.IDEXNREP exnInfo),
                         exdeclList)
                      | SOME(idstatus as I.IDEXNREP _) =>
                        (V.rebindId(exEnv, string, idstatus), exdeclList)
                      | SOME(idstatus as I.IDEXEXN {used,...}) =>
                        (used := true;
                         (V.rebindId(exEnv, string, idstatus), exdeclList)
                        )
                      | SOME(idstatus as I.IDEXEXNREP {used,...}) =>
                        (* FIXME 2012-1-31; This case was missing. 
                           Is this an error *)
                        (used := true;
                         (V.rebindId(exEnv, string, idstatus), exdeclList)
                        )
                      | _ =>
                        (EU.enqueueError
                           (loc, E.ExnExpected("170", {longid = longid}));
                         (exEnv, exdeclList)
                        )
                )
                (V.emptyEnv, nil)
                plexbindList
        in
          (exEnv, [I.ICEXND (exdeclList, loc)])
        end
      | P.PDLOCALDEC (pdeclList1, pdeclList2, loc) =>
        let
          val (env1, icdeclList1) = evalPdeclList path tvarEnv env pdeclList1
          val evalEnv = V.envWithEnv (env, env1)
          val (env2, icdeclList2) =
              evalPdeclList path tvarEnv evalEnv pdeclList2
        in
          (env2, icdeclList1@icdeclList2)
        end
      | P.PDOPEN (longidList, loc) =>
        let
          val returnEnv =
              foldl
                (fn (longid, returnEnv) =>
                    let
                      val strEntry = V.lookupStr env longid
                      val {env, strKind} = exceptionrepStrEntry strEntry (* bug 170_open *)
                    in
                      V.envWithEnv (returnEnv, env)
                    end
                    handle
                    V.LookupStr =>
                    (EU.enqueueError
                       (loc, E.StrNotFound("180", {longid = longid}));
                     returnEnv)
                )
                V.emptyEnv
                longidList
        in
          (returnEnv, nil)
        end
      | P.PDINFIXDEC(int, stringList, loc) => (V.emptyEnv, nil)
      | P.PDINFIXRDEC(int,stringList,loc) => (V.emptyEnv, nil)
      | P.PDNONFIXDEC(stringList, loc) => (V.emptyEnv, nil)
      | P.PDEMPTY => (V.emptyEnv, nil)

  and evalPdeclList (path:I.path) (tvarEnv:Ty.tvarEnv) (env:V.env) pdeclList
      : V.env * I.icdecl list =
      let
        val (returnEnv, icdeclList) =
            foldl
              (fn (pdecl, (returnEnv, icdeclList)) =>
                  let
                    val evalEnv = V.envWithEnv (env, returnEnv)
                    val (newEnv, icdeclList1) =
                        evalPdecl path tvarEnv evalEnv pdecl
                    val retuernEnv = V.envWithEnv (returnEnv, newEnv)
                  in
                    (retuernEnv, icdeclList@icdeclList1)
                  end
              )
              (V.emptyEnv, nil)
              pdeclList
      in
        (returnEnv, icdeclList)
      end

  and evalPlexp (tvarEnv:Ty.tvarEnv) (env:V.env) plexp : I.icexp =
      let
        val evalExp = evalPlexp tvarEnv env
        val evalPat = evalPlpat nilPath tvarEnv env
        fun evalTy' ty = Ty.evalTy tvarEnv env ty
      in
        case plexp of
          P.PLCONSTANT (constant, loc) => I.ICCONSTANT (constant, loc)
        | P.PLGLOBALSYMBOL (string, globalSymbolKind, loc) =>
          I.ICGLOBALSYMBOL (string, globalSymbolKind, loc)
        | P.PLVAR (path, loc) =>
          (let
             val idstatus = V.lookupId env path
             fun mkInfo id = ({id=id, path=path}, loc)
           in
             case idstatus of
               I.IDVAR id => I.ICVAR  (mkInfo id)
             | I.IDVAR_TYPED {id, ty} => I.ICVAR  (mkInfo id)
             | I.IDEXVAR {path, ty, used, loc=_, version, internalId} => 
               let
                 val path = I.setVersion(path, version)
               in
                 (used := true;
                  I.ICEXVAR ({path=path, ty=ty},loc)
                 )
               end
             | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
             | I.IDBUILTINVAR {primitive, ty} =>
               I.ICBUILTINVAR {primitive=primitive, ty=ty, loc=loc}
             | I.IDOPRIM {id, overloadDef, used, loc} => 
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
                     | I.INST_EXVAR ({path, used, ty}, loc) => used := true
                     | I.INST_PRIM _ => ()
                 val _ = touchDecl overloadDef 
               in
                 (used := true; I.ICOPRIM (mkInfo id))
               end
             | I.IDCON {id,ty} => I.ICCON ({id=id, path=path, ty=ty}, loc)
             | I.IDEXN {id,ty} => I.ICEXN ({id=id,ty=ty, path=path}, loc)
             | I.IDEXNREP {id,ty} => I.ICEXN ({id=id,ty=ty, path=path}, loc)
             | I.IDEXEXN {path,ty, used, loc, version} => 
               let
                 val path = I.setVersion(path, version)
               in
                 (used := true;
                  I.ICEXEXN ({path=path,ty=ty}, loc)
                 )
               end
             | I.IDEXEXNREP {path,ty, used, loc, version} => 
               let
                 val path = I.setVersion(path, version)
               in
                 (used := true;
                  I.ICEXEXN ({path=path,ty=ty}, loc)
                 )
               end
             | I.IDSPECVAR _ => raise bug "SPEC id status"
             | I.IDSPECEXN _ => raise bug "SPEC id status"
             | I.IDSPECCON => raise bug "SPEC id status"
           end
           handle V.LookupId =>
                  (EU.enqueueError
                     (loc, E.VarNotFound("190",{longid=path}));
                   I.ICVAR ({path=path, id = VarID.generate()},loc)
                  )
          )
        | P.PLTYPED (plexp, ty, loc) =>
          I.ICTYPED (evalExp plexp, evalTy' ty, loc)
        | P.PLAPPM (plexp, plexpList, loc) =>
          I.ICAPPM (evalExp plexp, map evalExp plexpList, loc)
        | P.PLLET (pdeclList, plexpList, loc) =>
          let
            val (newEnv, icdeclList) =
                evalPdeclList nilPath tvarEnv env pdeclList
            val evalEnv = V.envWithEnv (env, newEnv)
          in
            I.ICLET (icdeclList,
                     map (evalPlexp tvarEnv evalEnv) plexpList,
                     loc)
          end
        | P.PLRECORD (expfieldList, loc) =>
          I.ICRECORD (map (fn (l, exp)=>(l,evalExp exp)) expfieldList, loc)
        | P.PLRECORD_UPDATE (plexp, expfieldList, loc) =>
          I.ICRECORD_UPDATE
            (
             evalExp plexp,
             map (fn (label, exp) => (label, evalExp exp)) expfieldList,
             loc
            )
        | P.PLRAISE (plexp, loc) => I.ICRAISE (evalExp plexp, loc)
        | P.PLHANDLE (plexp, plpatPlexpList, loc) =>
          I.ICHANDLE
            (
             evalExp plexp,
             map
               (fn (plpat, plexp) =>
                   let
                     val (newEnv, icpat) = evalPat plpat
                   in
                     (
                      icpat,
                      evalPlexp tvarEnv (V.envWithEnv (env, newEnv)) plexp
                     )
                   end
               )
               plpatPlexpList,
             loc
            )
        | P.PLFNM (ruleList, loc) =>
          I.ICFNM(map (evalRule tvarEnv env loc) ruleList, loc)
        | P.PLCASEM (plexpList, ruleList, caseKind, loc) =>
          I.ICCASEM
            (
             map evalExp plexpList,
             map (evalRule tvarEnv env loc) ruleList,
             caseKind,
             loc
            )
        | P.PLRECORD_SELECTOR (string,loc) => I.ICRECORD_SELECTOR (string, loc)
        | P.PLSELECT (string,plexp,loc) => I.ICSELECT(string,evalExp plexp,loc)
        | P.PLSEQ (plexpList, loc) => I.ICSEQ (map evalExp plexpList, loc)
        | P.PLCAST (plexp, loc) => I.ICCAST (evalExp plexp, loc)
        | P.PLFFIIMPORT (plexp, ffiTy, loc) =>
          let
            val ffiTy = Ty.evalFfity tvarEnv env ffiTy
          in
            I.ICFFIIMPORT(evalPlexp tvarEnv env plexp, ffiTy, loc)
          end
        | P.PLFFIEXPORT (plexp, ffiTy, loc) =>
          let
            val ffiTy = Ty.evalFfity tvarEnv env ffiTy
          in
            I.ICFFIEXPORT(evalPlexp tvarEnv env plexp, ffiTy, loc)
          end
        | P.PLFFIAPPLY (ffiAttributes, plexp, ffiArgList, ffiTy, loc) =>
          let
            fun evalFfiArg ffiArg =
                case ffiArg of
                  P.PLFFIARG (plexp, ffiTy, loc) =>
                  I.ICFFIARG(evalExp plexp, Ty.evalFfity tvarEnv env ffiTy, loc)
                | P.PLFFIARGSIZEOF (ty, plexpOption, loc) =>
                  I.ICFFIARGSIZEOF
                    (
                     evalTy' ty,
                     Option.map evalExp plexpOption,
                     loc
                    )
          in
            I.ICFFIAPPLY
              (
               ffiAttributes,
               evalExp plexp,
               map evalFfiArg ffiArgList,
               Ty.evalFfity tvarEnv env ffiTy,
               loc
              )
          end
        | P.PLSQLSERVER (stringPlexpList, ty, loc) =>
          I.ICSQLSERVER
            (
             map (fn (string, plexp) => (string, evalExp plexp))
                 stringPlexpList,
             evalTy' ty,
             loc
            )
        | P.PLSQLDBI (plpat, plexp, loc) =>
          let
            val (newEnv, icpat) = evalPat plpat
            val evalEnv = V.envWithEnv (env, newEnv)
          in
            I.ICSQLDBI(icpat, evalPlexp tvarEnv evalEnv plexp, loc)
          end
      end

  and evalRule (tvarEnv:Ty.tvarEnv) (env: V.env) loc (plpatList, plexp) =
      let
        val (newEnv, icpatList) =
            U.evalList
            {emptyEnv=V.emptyEnv,
             eval=evalPlpat nilPath tvarEnv env,
             unionEnv=V.unionEnv "204" loc}
            plpatList
        val evalEnv = V.envWithEnv (env, newEnv)
      in
        {args=icpatList, body=evalPlexp tvarEnv evalEnv plexp}
      end

  fun evalPlstrdec (topEnv:V.topEnv) path plstrdec : V.env * I.icdecl list =
      case plstrdec of
        P.PLCOREDEC (pdecl, loc) => 
        evalPdecl path Ty.emptyTvarEnv (#Env topEnv) pdecl
      | P.PLSTRUCTBIND (stringPlstrexpList, loc) =>
        let
          val _ = EU.checkNameDuplication
                    #1
                    stringPlstrexpList
                    loc
                    (fn s => E.DuplicateStrName("420",s))
        in
          foldl
            (fn ((string, plstrexp), (returnEnv, icdeclList)) =>
                let
                  val (strEnv, icdeclList1) =
                      evalPlstrexp topEnv (path@[string]) plstrexp
                  val returnEnv = V.rebindStr (returnEnv, string, strEnv)
                in
                  (returnEnv, icdeclList@icdeclList1)
                end
            )
            (V.emptyEnv, nil)
            stringPlstrexpList
        end
      | P.PLSTRUCTLOCAL (plstrdecList1, plstrdecList2, loc) =>
        let
          fun evalList topEnv plstrdecList =
              foldl
                (fn (plstrdec, (returnEnv, icdeclList)) =>
                    let
                      val evalEnv = V.topEnvWithEnv (topEnv, returnEnv)
                      val (newEnv, icdeclList1) =
                          evalPlstrdec evalEnv path plstrdec
                    in
                      (V.envWithEnv (returnEnv, newEnv),
                       icdeclList@icdeclList1)
                    end
                )
                (V.emptyEnv, nil)
                plstrdecList
          val (returnEnv1,icdeclList1) = evalList topEnv plstrdecList1
          val evalTopEnv = V.topEnvWithEnv(topEnv, returnEnv1)
          val (returnEnv2,icdeclList2) = evalList evalTopEnv plstrdecList2
        in
          (returnEnv2, icdeclList1 @ icdeclList2)
        end

  and evalPlstrexp (topEnv as {Env = env, FunE, SigE}) path plstrexp
      : V.strEntry * I.icdecl list =
      case plstrexp of
        (* struct ... end *)
        P.PLSTREXPBASIC (plstrdecList, loc) =>
        let
          val strKind = V.STRENV (StructureID.generate())
          val (returnEnv, icdeclList) =
              foldl
                (fn (plstrdec, (returnEnv, icdeclList)) =>
                    let
                      val evalTopEnv = V.topEnvWithEnv (topEnv, returnEnv)
                      val (returnEnv1, icdeclList1) =
                          evalPlstrdec evalTopEnv path plstrdec
                    in
                      (V.envWithEnv(returnEnv, returnEnv1),
                       icdeclList @ icdeclList1
                      )
                    end
                )
                (V.emptyEnv, nil)
                plstrdecList
        in
          ({env=returnEnv, strKind=strKind}, icdeclList)
        end
      | P.PLSTRID (longid, loc) =>
        (let
           val strEntry = V.lookupStr env longid
           val strEntry = exceptionrepStrEntry strEntry
         in
          (strEntry, nil)
        end
        handle V.LookupStr =>
               (EU.enqueueError (loc, E.StrNotFound("430",{longid = longid}));
                ({env=V.emptyEnv, strKind=V.STRENV(StructureID.generate())}, nil)
               )
          )
      | P.PLSTRTRANCONSTRAINT (plstrexp, plsigexp, loc) =>
        (
        let
          val ({env=strEnv,strKind=_}, icdeclList1) = evalPlstrexp topEnv path plstrexp
          val specEnv = Sig.evalPlsig topEnv plsigexp
          val specEnv = #2 (Sig.refreshSpecEnv specEnv)
          val strKind = V.STRENV (StructureID.generate())
          val (returnEnv, specDeclList2) =
              SC.sigCheck
                {mode = SC.Trans,
                 strPath = path,
                 strEnv = strEnv,
                 specEnv = specEnv,
                 loc = loc
                }
        in
          ({env=returnEnv,strKind=strKind}, icdeclList1 @ specDeclList2)
        end
        handle SC.SIGCHECK => ({env=V.emptyEnv, strKind=V.STRENV(StructureID.generate())}, nil)
        )

      | P.PLSTROPAQCONSTRAINT (plstrexp, plsigexp, loc) =>
        (
        let
           val ({env=strEnv, strKind=_}, icdeclList1) = evalPlstrexp topEnv path plstrexp
           val specEnv = Sig.evalPlsig topEnv plsigexp
           val specEnv = #2 (Sig.refreshSpecEnv specEnv)
           val strKind = V.STRENV (StructureID.generate())
           val (returnEnv, specDeclList2) =
               SC.sigCheck
                 {mode = SC.Opaque,
                  strPath = path,
                  strEnv = strEnv,
                  specEnv = specEnv,
                  loc = loc
                  }
        in
          ({env=returnEnv,strKind=strKind}, icdeclList1 @ specDeclList2)
        end
        handle SC.SIGCHECK => ({env=V.emptyEnv, strKind=V.STRENV(StructureID.generate())}, nil)
        )

      | P.PLFUNCTORAPP (string, argPath, loc) =>
        let
          val {env, icdecls, funId, argId} = applyFunctor topEnv (path, string, argPath, loc)
          val structureId = StructureID.generate()
          val strKind = V.FUNAPP {id=structureId, funId=funId, argId=argId}
        in
          ({env=env, strKind=strKind}, icdecls)
        end

      | P.PLSTRUCTLET (plstrdecList, plstrexp, loc) =>
        let
          val (returnEnv1, icdeclList1) =
              foldl
                (fn (plstrdec, (returnEnv1, icdeclList1)) =>
                    let
                      val evalTopEnv = V.topEnvWithEnv (topEnv, returnEnv1)
                      val (newReturnEnv, newIcdeclList) =
                          evalPlstrdec evalTopEnv nilPath plstrdec
                    in
                      (V.envWithEnv (returnEnv1, newReturnEnv),
                       icdeclList1 @ newIcdeclList)
                    end
                )
              (V.emptyEnv, nil)
              plstrdecList
          val evalEnv = V.topEnvWithEnv(topEnv, returnEnv1)
          val (strEntry, icdeclList2) = evalPlstrexp evalEnv path plstrexp
        in
          (strEntry, icdeclList1 @ icdeclList2)
        end

  and applyFunctor (topEnv as {Env = env, FunE, SigE})
                   (copyPath, funName, argPath, loc)
      : {env:V.env, 
         icdecls:I.icdecl list, 
         funId:FunctorID.id, 
         argId:StructureID.id} = 
      let


val _ = U.print "applyFunctor\n"
val _ = U.print "funName\n"
val _ = U.print funName
val _ = U.print "\n"
val _ = U.print "argPath\n"
val _ = U.printPath argPath
val _ = U.print "\n"
 
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
                     {tvarS, tfvS, conIdS, exnIdS} =
            let
              val conIdS =
                  SEnv.foldri
                    (fn (name, idstatus, conIdS) =>
                      case idstatus of
                        I.IDCON {id, ty} =>
                        (case SEnv.find(actualVarE, name) of
                           SOME (idstatus as I.IDCON _) =>
                           ConID.Map.insert(conIdS, id, idstatus)
                         | SOME actualIdstatus => raise bug "non conid"
                         | NONE => raise bug "conid not found in instVarE"
                        )
                      | _ => conIdS)
                  conIdS
                  varE
            in
              {tvarS=tvarS,tfvS=tfvS,exnIdS=exnIdS, conIdS=conIdS}
            end
        fun instTfun path (tfun, actualTfun)
                     (subst as {tvarS, tfvS, conIdS, exnIdS}) =
            let
              val tfun = I.derefTfun tfun
              val actualTfun = I.derefTfun actualTfun
            in
              case tfun of
                I.TFUN_VAR (tfv1 as ref (I.TFUN_DTY {dtyKind,...})) =>
                (case actualTfun of
                   I.TFUN_VAR(tfv2 as ref (tfunkind as I.TFUN_DTY _)) =>
                   (tfv1 := tfunkind;
                    {tfvS=TfvMap.insert (tfvS, tfv1, tfv2)
                          handle e => raise e,
                     tvarS=tvarS,
                     exnIdS=exnIdS,
                     conIdS=conIdS}
                   )
                 | I.TFUN_DEF _ =>
                   (case dtyKind of
                      I.FUNPARAM => 
                      (EU.enqueueError
                         (loc, E.FunctorParamRestriction("440",{longid=path}));
                       subst)
                    | _ => raise bug "tfun def"
                   )
                 | I.TFUN_VAR _ => raise bug "tfun var"
                )
              | I.TFUN_DEF{iseq, formals=nil, realizerTy= I.TYVAR tvar} =>
                let
                  val ty =I.TYCONSTRUCT{typ={tfun=actualTfun,path=path},args=nil}
                  val ty = N.reduceTy TvarMap.empty ty
                in
                  {tvarS=TvarMap.insert(tvarS,tvar,ty),
                   tfvS=tfvS,
                   conIdS=conIdS,
                   exnIdS=exnIdS
                  }
                end
              | _ => subst
            end
        fun instTstr 
              path (tstr, actualTstr)
              (subst as {tvarS,tfvS,conIdS, exnIdS}) =
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
            SEnv.foldri
              (fn (name, tstr, subst) =>
                  let
                    val actualTstr = 
                        case SEnv.find(actualTyE, name) of
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
            SEnv.foldri
            (fn (name, {env, strKind}, subst) =>
                let
                  val actualEnv = case SEnv.find(actualEnvMap, name) of
                                    SOME {env,strKind} => env 
                                  | NONE => raise bug "actualEnv not found"
                in
                  instEnv (path@[name]) (env, actualEnv) subst
                end
            )
            subst
            envMap
        val funEEntry as
            {id=functorId,
             version,
             used,
             argSig,
             argStrName,
             argStrEntry,
             bodyEnv,
             polyArgTys = _,
             dummyIdfunArgTy,
             typidSet,
             exnIdSet,
             bodyVarExp
            }
          = case SEnv.find(FunE, funName) of
              SOME funEEntry => funEEntry
            | NONE => raise FunIDUndefind

       val _ = used := true

val _ = U.print "funEEntry\n"
val _ = U.printFunEEntry funEEntry
val _ = U.print "\n"
val _ = U.print "funName\n"
val _ = U.print funName
val _ = U.print "\n"

        val ((actualArgEnv, actualArgDecls), argId) =
            let
              val argSig = #2 (Sig.refreshSpecEnv argSig)
                           handle e => raise e
              val ({env=argStrEnv,strKind},_) =
                  evalPlstrexp topEnv nilPath (P.PLSTRID(argPath,loc))
                  handle e => raise e
              val argId = case strKind of
                            V.STRENV id => id
                          | V.FUNAPP{id,...} => id
                          | _ => raise bug "non strenv in functor arg"
            in
              (SC.sigCheck
                 {mode = SC.Trans,
                  strPath = argPath,
                  strEnv = argStrEnv,
                  specEnv = argSig,
                  loc = loc
                 },
               argId
              )
              handle e => raise e
            end
        val _ = if EU.isAnyError () then raise SC.SIGCHECK else ()
        val tempEnv =
            V.ENV{varE=SEnv.empty,
                  tyE=SEnv.empty,
                  strE=
                    V.STR
                    (
                     SEnv.insert
                       (SEnv.insert(SEnv.empty, "arg", argStrEntry),
                        "body",
                        {env=bodyEnv, strKind=V.STRENV(StructureID.generate())})
                    )
                 }
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
            SC.refreshEnv (typidSet, exnIdSubst) tempEnv
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
        val {env=argEnv, strKind} = 
            case V.findStr(tempEnv, ["arg"]) of
              SOME strEntry => strEntry
            | NONE => raise bug "impossible"
        val {env=bodyEnv, ...} = 
            case V.findStr(tempEnv, ["body"]) of
              SOME env => env
            | NONE => raise bug "impossible"
        val subst = instEnv nil (argEnv, actualArgEnv) S.emptySubst
        val bodyEnv = S.substEnv subst bodyEnv
                      handle e => raise e
        val bodyEnv = N.reduceEnv bodyEnv 
                      handle e => raise e
        val pathTfvListList = L.setLiftedTysEnv bodyEnv
                handle e => raise e
        val dummyIdfunArgTy = 
            Option.map (S.substTy subst) dummyIdfunArgTy
            handle e => raise e
        val dummyIdfunArgTy = 
            Option.map (N.reduceTy TvarMap.empty) dummyIdfunArgTy
            handle e => raise e
        fun makeCast (fromTfv, toTfv, castList) =
            let
              val {tvarS,...} = subst
            in
              {from=I.TFUN_VAR fromTfv,
               to=I.TFUN_VAR toTfv}
              :: castList
            end
        val castList = TfvMap.foldri makeCast nil tfvSubst
                       handle e => raise e
        val bodyVarExp = I.ICTYCAST (castList, bodyVarExp, loc)
        (* functor body variables for generating env and for patterns to be used in bind*)
        val (bodyVarList, _) = FU.varsInEnv ExnID.Set.empty loc nil nil bodyEnv
        (*  returnEnv : env for functor generated by this functor application
            patFields : patterns used in binding of variables generated by this application
            exntagDecls : rebinding exceptions generated by this application
         *)

(*
val _ = U.print "bodyVarList ******************************************\n"
val _ = map (fn (path, v) => (U.printPath path; U.print "_"; U.printExp v; U.print "\n")) bodyVarList
val _ = U.print "\n"
*)
        val (_, returnEnv, patFields, exntagDecls) =
            foldl
              (fn ((bindPath, I.ICVAR ({path, id=_},loc)),
                   (n, returnEnv, patFields, exntagDecls)) =>
                  let
                    val newId = VarID.generate()
                    val varInfo = {id=newId, path=path}
                    val newIdstatus = I.IDVAR newId
                    val newPat = I.ICPATVAR(varInfo, loc)
                    val returnEnv = V.rebindIdLongid(returnEnv, bindPath, newIdstatus)
                  in
                    (n + 1,
                     returnEnv,
                     patFields @[(Int.toString n, newPat)],
                     exntagDecls
                    )
                  end
                | (* need to check this case *)
                  ((bindPath, I.ICEXN ({path, ty, id}, loc)),
                   (n, returnEnv, patFields,exntagDecls)) =>
                  let
                    (* FIXME: here we generate env with IDEXN env and
                       exception tag E = x decl.
                     *)
                    val newVarId = VarID.generate()
                    val newExnId = ExnID.generate()
                    val exnInfo = {id=newExnId, path=path, ty=ty}
                    val varInfo = {id=newVarId, path=path}
                    val newIdstatus = I.IDEXN {id=newExnId, ty=ty}
                    val newPat = I.ICPATVAR (varInfo, loc)
                    val returnEnv =
                        V.rebindIdLongid(returnEnv, bindPath, newIdstatus)
                    val exntagd =
                        I.ICEXNTAGD({exnInfo=exnInfo, varInfo=varInfo},loc)
                  in
                    (n + 1,
                     returnEnv,
                     patFields @[(Int.toString n, newPat)],
                     exntagDecls
                    )
                  end
                | (* see: bug 061_functor.sml *)
                  ((bindPath, I.ICEXVAR ({path,ty},loc)),
                   (n, returnEnv, patFields, exntagDecls)) =>
                  let
                    val newId = VarID.generate()
                    val newVarInfo = {id=newId, path=path}
                    val newIdstatus = I.IDVAR newId
                    val newPat = I.ICPATVAR({path=path, id=newId}, loc)
                    val returnEnv =
                        V.rebindIdLongid(returnEnv, bindPath, newIdstatus)
                  in
                    (n + 1,
                     returnEnv,
                     patFields @[(Int.toString n, newPat)],
                     exntagDecls
                    )
                  end
                | (* see: bug 061_functor.sml *)
                  ((bindPath, I.ICEXN_CONSTRUCTOR (exnInfo as {path, ty, ...},loc)),
                   (n, returnEnv, patFields, exntagDecls)) =>
                  let
                    val newId = VarID.generate()
                    val newVarInfo = {id=newId, path = path}
                    val newIdstatus = I.IDVAR newId
                    val newPat = I.ICPATVAR({path=path, id=newId}, loc)
                    val exntagDecl =
                        I.ICEXNTAGD ({exnInfo=exnInfo, varInfo=newVarInfo},
                                     loc)
                  in
                    (n + 1,
                     returnEnv,
                     patFields @[(Int.toString n, newPat)],
                     exntagDecls @ [exntagDecl]
                    )
                  end
                | ((bindPath, exp), _) =>
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
              (1, bodyEnv, nil, nil)
              bodyVarList

        val resultPat =
            case patFields of
              nil => I.ICPATCONSTANT(A.UNITCONST loc,loc)
            | _ => I.ICPATRECORD {flex=false,fields = patFields,loc = loc}

        val actualDummyIdfun =
            case dummyIdfunArgTy of
              SOME dummyIdTy =>
              let
                val id = VarID.generate()
                val funargVarinfo = {id=id, path=[DUMMYIDFUN]}
              in
                SOME
                  (
                   I.ICFNM
                     ([{args=
                          [
                           I.ICPATTYPED
                             (
                              I.ICPATVAR (funargVarinfo, loc),
                              dummyIdTy,
                              loc
                             )
                          ],
                        body=I.ICVAR (funargVarinfo, loc)}
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
            SEnv.foldli
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
                | I.IDSPECCON => exnTags
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
            SEnv.foldri
            (fn (name, {env, strKind}, exnTags) => exnTagsEnv (path@[name]) env exnTags
            )
            exnTags
            envMap
        val exnTagPathList = exnTagsEnv nil argSig nil
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
                            [I.ICCONSTANT(A.UNITCONST loc, loc)],
                            loc)
        val functorAppDecl = 
            I.ICVAL(Ty.emptyScopedTvars,[(resultPat, functorBody)],loc)

(* FIXE: We must be slim down the bodyEnv below
        val returnEnv = V.envWithEnv(bodyEnv, returnEnv)
 *)

      in (* applyFunctor *)
        {funId=functorId, 
         argId=argId,
         env=returnEnv, 
         icdecls=actualArgDecls @ [functorAppDecl] @ exntagDecls
        }
      end
      handle 
      SC.SIGCHECK => {funId=FunctorID.generate(),
                   argId = StructureID.generate(),
                   env=V.emptyEnv, 
                   icdecls=nil}
    | FunIDUndefind  =>
      (EU.enqueueError
         (loc, E.FunIdUndefined("450",{name = funName}));
       {funId=FunctorID.generate(),
        argId = StructureID.generate(),
        env=V.emptyEnv, 
        icdecls=nil}
      )

  fun evalFunctor {topEnv, version:int option} {name, argStrName, argSig, body, loc} =
      let
        val 
        {
         argSig,
         argStrEntry,
         extraTvars,
         polyArgPats,  (* functor argument variables (negative) *)
         exnTagDecls,  
         dummyIdfunArgTy,
         firstArgPat,
         tfvDecls
        } = FU.evalFunArg (topEnv, argSig, loc)
        val topArgEnv = V.ENV {varE=SEnv.empty,
                            tyE=SEnv.empty,
                            strE=V.STR (SEnv.singleton(argStrName, argStrEntry))
                            }
        val evalEnv = V.topEnvWithEnv (topEnv, topArgEnv)
        val startTypid = TypID.generate()
        val ({env=returnEnv,strKind}, bodyDecls) = evalPlstrexp evalEnv nilPath body
        val
        {
         allVars = allVars,  (* functor body expressions (positive) *)
         typidSet = typidSet,
         exnIdSet = exnIdSet
        } = FU.makeBodyEnv returnEnv loc
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
              nil => I.ICCONSTANT(A.UNITCONST loc, loc)
            | _ => I.ICRECORD (Utils.listToTuple allVars, loc)
        val functorExp1 =
            case polyArgPats of
              nil => I.ICLET (exnTagDecls @ bodyDecls, [bodyExp], loc)
            | _ => 
              I.ICFNM1_POLY
                (polyArgPats,  (* functor argument variables (negative) *)
                 I.ICLET (exnTagDecls @ bodyDecls, [bodyExp], loc),
                 loc)
        val functorExp =
            case firstArgPat of
              SOME pat => I.ICFNM1([pat], functorExp1, loc)
            | NONE => 
              (case functorExp1 of
                 I.ICLET _ =>
                 let
                   val varId = VarID.generate()
                   val patVarInfo ={path=["unitVar"], id=varId}
                 in
                   I.ICFNM1
                     (
                      [(patVarInfo, [BV.unitTy])],
                      functorExp1,
                      loc
                     )
                 end
               | _ => functorExp1
              )

        val functorExpVar = {path=[FUNCORPREFIX,name], id=VarID.generate()}
        val functorExpVarExp = I.ICVAR (functorExpVar, loc)
(*
        val version = case SEnv.find(#FunE version, name) of
                        NONE => NONE
                      | SOME {version,...} => I.incVersion version
*)
        val functorDecl =
            I.ICVAL(map (fn tvar=>(tvar, I.UNIV)) extraTvars,
                    [(I.ICPATVAR(functorExpVar, loc),functorExp)],
                    loc)
        val funEEntry:V.funEEntry =
            {id = FunctorID.generate(),
             version = version,
             used = ref false,
             argSig = argSig,
             argStrEntry = argStrEntry,
             argStrName = argStrName,
             dummyIdfunArgTy = dummyIdfunArgTy,
             polyArgTys = map (fn (pat, ty) => ty) polyArgPats,
             typidSet=typidSet,
             exnIdSet=exnIdSet,
             bodyEnv = returnEnv,
             bodyVarExp = functorExpVarExp
            }
        val funE =  SEnv.singleton(name, funEEntry)
        val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
      in (* evalFunctor *)
        (returnTopEnv, tfvDecls@[functorDecl])
      end

  fun evalPltopdec {topEnv, version:int option} pltopdec =
      case pltopdec of
        P.PLTOPDECSTR (plstrdec, loc) =>
        let
          val (env, icdeclList) = evalPlstrdec topEnv nilPath plstrdec
        in
          (V.topEnvWithEnv(V.emptyTopEnv, env), icdeclList)
        end
      | P.PLTOPDECSIG (stringPlsigexpList, loc) =>
        let
          val _ = EU.checkNameDuplication
                    #1
                    stringPlsigexpList
                    loc
                    (fn s => E.DuplicateSigname("460",s))
          val sigE =
              foldl
                (fn ((name, plsig), sigE) =>
                    SEnv.insert(sigE, name, Sig.evalPlsig topEnv plsig)
                )
                SEnv.empty
                stringPlsigexpList
        in
          (V.topEnvWithSigE(V.emptyTopEnv, sigE), nil)
        end
      | P.PLTOPDECFUN (functordeclList,loc) =>
        let
          val _ = EU.checkNameDuplication
                    #name
                    functordeclList
                    loc
                    (fn s => E.DuplicateFunctor("470",s))
        in
          foldl
            (fn (functordecl, (returnTopEnv, icdecList)) =>
                let
                  val (topEnv1, icdecList1) =
                      evalFunctor {topEnv=topEnv, version=version} functordecl
                  val returnTopEnv =
                      V.topEnvWithTopEnv(returnTopEnv, topEnv1)
                in
                  (returnTopEnv, icdecList@icdecList1)
                end
            )
            (V.emptyTopEnv, nil)
            functordeclList
        end

  fun evalPltopdecList {topEnv, version:int option} pltopdecList =
      foldl
        (fn (pltopdec, (returnTopEnv, icdecList)) =>
          let
            val evalTopEnv = V.topEnvWithTopEnv (topEnv, returnTopEnv)
            val (returnTopEnv1, icdecList1) =
                evalPltopdec {topEnv=evalTopEnv, version=version} pltopdec
            val returnTopEnv = V.topEnvWithTopEnv(returnTopEnv, returnTopEnv1)
          in
            (returnTopEnv, icdecList @ icdecList1)
          end
        )
        (V.emptyTopEnv, nil)
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
              (SEnv.listItemsi varE)
        fun exportsInStrE path (V.STR strE) =
            List.concat
              (map (fn (strid, {env,...}) => exportsInEnv (path@[strid]) env)
                   (SEnv.listItemsi strE))
        and exportsInEnv path (V.ENV {varE, tyE, strE}) =
            exportsInVarE path varE @ exportsInStrE path strE
      in
        exportsInEnv nil Env
      end
*)

  fun genExport (version, {FunE=RFunE,Env=REnv, SigE=RSigE}) loc =
      let
        fun genExportIdstatus exnSet path version idstatus icdecls = 
            case idstatus of
              I.IDVAR varId => 
              let
                val externPath=I.setVersion(path, version)
              in
                (exnSet,
                 I.IDEXVAR_TOBETYPED{path=path,version=version,id=varId,loc=loc, internalId = SOME varId}, 
                 I.ICEXPORTTYPECHECKEDVAR ({path=externPath, id=varId}, loc)::icdecls)
              end
            | I.IDVAR_TYPED {id, ty} => 
              let
                val externPath=I.setVersion(path, version)
              in
                (exnSet,
                 I.IDEXVAR{path=path,version=version, ty=ty, used=ref false, loc=loc, internalId = SOME id}, 
                 I.ICEXPORTTYPECHECKEDVAR ({path=externPath, id=id}, loc)::icdecls)
              end
            | I.IDEXVAR {path, ty, used, loc, version, internalId} => (exnSet, idstatus, icdecls)
            | I.IDEXVAR_TOBETYPED _ => (exnSet, idstatus, icdecls)  (* this should be a bug *)
            | I.IDBUILTINVAR {primitive, ty}  => (exnSet, idstatus, icdecls)
            | I.IDCON {id, ty} => (exnSet, idstatus, icdecls)
            | I.IDEXN {id, ty} =>
              if not (ExnID.Set.member(exnSet, id)) then
                let
                  val externPath=I.setVersion(path, version)
                in
                  (ExnID.Set.add(exnSet, id), 
                   I.IDEXEXN{path=path,version=version, ty=ty, used=ref false, loc=loc}, 
                   I.ICEXPORTEXN ({path=externPath, ty=ty, id=id}, loc) :: icdecls)
                end
              else (exnSet, idstatus, icdecls)
            | I.IDEXNREP {id, ty} =>
              if not (ExnID.Set.member(exnSet, id)) then
                let
                  val externPath=I.setVersion(path, version)
                in
                  (ExnID.Set.add(exnSet, id), 
                   I.IDEXEXN{path=path,version=version, ty=ty, used=ref false, loc=loc}, 
                   I.ICEXPORTEXN ({path=externPath, ty=ty, id=id}, loc) :: icdecls)
                end
              else (exnSet, idstatus, icdecls)
            | I.IDEXEXN {path, ty, used, loc, version} => (exnSet, idstatus, icdecls)
            | I.IDEXEXNREP {path, ty, used, loc, version} => (exnSet, idstatus, icdecls)
            | I.IDOPRIM {id, overloadDef, used, loc} => (exnSet, idstatus, icdecls)
            | I.IDSPECVAR ty => raise bug "IDSPECVAR in mergeIdstatus"
            | I.IDSPECEXN ty  => raise bug "IDSPECEXN in mergeIdstatus"
            | I.IDSPECCON => raise bug "IDSPECCON in mergeIdstatus"

        fun genExportVarE exnSet path (vesion, RVarE) icdecls =
            SEnv.foldri
              (fn (name, idstatus, (exnSet, varE, icdecls)) =>
                  let
                    val (exnSet, idstatus, icdecls) = 
                        genExportIdstatus exnSet (path@[name]) version idstatus icdecls
                  in
                    (exnSet, SEnv.insert(varE, name, idstatus), icdecls)
                  end
              )
              (exnSet, SEnv.empty, icdecls)
              RVarE
                
        fun genExportEnvMap exnSet path (version, REnvMap) icdecls =
            SEnv.foldri
            (fn (name, {env=REnv, strKind}, (exnSet, envMap, icdecls)) =>
                let
                  val (exnSet, env, icdecls) = 
                      genExportEnv exnSet (path@[name]) (version, REnv) icdecls
                in
                  (exnSet, 
                   SEnv.insert(envMap, name, {env=env, strKind=strKind}), 
                   icdecls)
                end
            )
            (exnSet, SEnv.empty, icdecls)
            REnvMap

        and genExportEnv exnSet path
                         (version, V.ENV{varE=RVarE, strE=V.STR REnvMap, tyE}) 
                         icdecls =
            let
              val (exnSet, varE, icdecls) = 
                  genExportVarE exnSet path (version, RVarE) icdecls
              val (exnSet, envMap, icdecls) = 
                  genExportEnvMap exnSet path (version, REnvMap) icdecls
            in
              (exnSet, V.ENV{varE=varE, strE=V.STR envMap, tyE=tyE}, icdecls)
            end

        fun genExportFunEEntry (version, RFunEntry:V.funEEntry) icdecls =
            let
              val {id,
                   version=_,
                   used,
                   argSig,
                   argStrEntry,
                   argStrName,
                   dummyIdfunArgTy,
                   polyArgTys,
                   typidSet,
                   exnIdSet,
                   bodyEnv,
                   bodyVarExp
                  }  = RFunEntry
              val bodyVarExp = 
                  case bodyVarExp of
                    I.ICVAR ({path, id}, loc) =>
                    let
                      val externPath = I.setVersion(path, version)
                    in
                      I.ICEXVAR_TOBETYPED ({path=externPath, id=id}, loc)
                    end
                  | _ => raise bug "non var bodyVarExp"
              val funEEntry=
                  {id=id,
                   version = version,
                   used = used,
                   argSig = argSig,
                   argStrEntry = argStrEntry,
                   argStrName = argStrName,
                   dummyIdfunArgTy = dummyIdfunArgTy,
                   polyArgTys = polyArgTys,
                   typidSet = typidSet,
                   exnIdSet = exnIdSet,
                   bodyEnv = bodyEnv,
                   bodyVarExp = bodyVarExp
                  }
              val icdecl =
                  case bodyVarExp of 
                    I.ICVAR ({id, path}, loc) => 
                    let
                      val externPath = I.setVersion(path, version)
                    in
                      I.ICEXPORTTYPECHECKEDVAR ({path=externPath, id=id}, loc)
                    end
                  | _ => raise bug "nonvar in bodyVarExp"
            in
              (funEEntry, icdecl::icdecls)
            end

        fun genExportFunE (version, RFunE) icdecls =
            SEnv.foldri
            (fn (name, RFunEEntry, (funE, icdecls)) =>
                let
                  val (funEEntry, icdecls) =
                         genExportFunEEntry (version, RFunEEntry) icdecls
                in
                  (SEnv.insert(funE, name, funEEntry), icdecls)
                end
            )
            (SEnv.empty, icdecls)
            RFunE

        val (FunE, icdecls) = genExportFunE (version, RFunE) nil
        val (_, Env, icdecls) = genExportEnv ExnID.Set.empty nil (version, REnv) icdecls
      in
        ({FunE=FunE, Env=Env, SigE=RSigE}, icdecls)
      end

  fun clearUsedflagIdstatus idstatus = 
      case idstatus of
        I.IDEXVAR {used,...} => used := false
      | I.IDOPRIM {used,...} => used := false
      | I.IDEXEXN {used,...} => used := false
      | I.IDEXEXNREP {used,...} => used := false
      | _ => ()
  fun clearUsedflagVarE varE = 
      SEnv.app clearUsedflagIdstatus varE
  fun clearUsedflagEnv (V.ENV {varE, tyE, strE}) = 
      (clearUsedflagVarE varE;
       clearUsedflagStrE strE)
  and clearUsedflagStrE (V.STR strEntryMap) =
      SEnv.app (fn {env, strKind} => clearUsedflagEnv env) strEntryMap

  fun clearUsedflag {Env, FunE, SigE} =
      clearUsedflagEnv Env
      
  fun genExterndeclsIdstatus externSet idstatus icdecls =
      case idstatus of
        I.IDEXVAR {path, ty, used = ref true, loc, version, internalId}  => 
        let
          val externPath = I.setVersion(path, version)
        in
          (externSet,I.ICEXTERNVAR ({path=externPath, ty=ty}, loc) :: icdecls)
        end
      | I.IDOPRIM {used = ref true, overloadDef,...} => 
        (externSet,overloadDef::icdecls)
      | I.IDEXEXN {used = ref true, path=path, ty, loc, version} => 
        let
          val externPath = I.setVersion(path, version)
        in
          if PathSet.member(externSet, externPath) 
          then (externSet, icdecls)
          else 
            (PathSet.add(externSet, externPath),
             I.ICEXTERNEXN ({path=externPath, ty=ty}, loc) :: icdecls
            )
        end
      | I.IDEXEXNREP {used = ref true, path=path, ty, loc, version} => 
        let
          val externPath = I.setVersion(path, version)
        in
          if PathSet.member(externSet, externPath) 
          then (externSet, icdecls)
          else 
            (PathSet.add(externSet, externPath),
             I.ICEXTERNEXN ({path=externPath, ty=ty}, loc) :: icdecls
            )
        end
      | _ => (externSet, icdecls)
  fun genExterndeclsVarE externSet varE icdecls =
      SEnv.foldr
      (fn (idstatus, (externSet, icdecls)) => genExterndeclsIdstatus externSet idstatus icdecls)
      (externSet,icdecls)
      varE
  fun genExterndeclsEnv externSet (V.ENV {varE, tyE, strE}) icdecls =
      let
        val (externSet, icdecls) = genExterndeclsVarE externSet varE icdecls
        val (externSet, icdecls) = genExterndeclsStrE externSet strE icdecls
      in
        (externSet, icdecls)
      end
  and genExterndeclsStrE externSet (V.STR strEntryMap) icdecls =
      SEnv.foldr
      (fn ({env, strKind}, (externSet, icdecls)) =>
           case strKind of 
             V.SIGENV => (externSet,icdecls)
           | V.FUNAPP _ => (externSet, icdecls)
           | V.STRENV _ => genExterndeclsEnv externSet env icdecls)
      (externSet, icdecls)
      strEntryMap
      
  fun genExterndeclsFunE externSet (funE:V.funE) icdecls =
      SEnv.foldr
      (fn ({used=ref true,version, bodyVarExp,...}, (externSet, icdecls)) =>
           (case bodyVarExp of
             I.ICEXVAR ({path,ty}, loc) =>
             if PathSet.member(externSet, path) 
             then (externSet, icdecls)
             else 
               (PathSet.add(externSet, path), 
                I.ICEXTERNVAR ({path=path, ty=ty},loc)  :: icdecls)
           | _ => raise bug "nonVAR bodyVarExp in funEEntry")
        | (_, (externSet, icdecls)) => (externSet, icdecls)
      )
      (externSet, icdecls)
      funE

  fun genExterndecls {Env, FunE, SigE} = 
      let
        val (externSet, icdecls) = genExterndeclsEnv PathSet.empty Env nil
        val (_, icdecls) = genExterndeclsFunE externSet FunE icdecls
      in
        icdecls
      end

in (* local *)

  fun nameEval {topEnv, version, systemDecls}
               (compileUnit
                  as
                  {interface={decls,requires,topdecs=provideDecs,...},
                   topdecs}:PI.compileUnit) =
      let
        val _ = EU.initializeErrorQueue()
        val loc = 
            case topdecs of
              nil => Loc.noloc
            | dec::_ => (#1 (P.getLocTopDec dec),
                         #2 (P.getLocTopDec (List.last topdecs)))
        val interfaceEnv = EI.evalInterfaces topEnv decls
        val evalTopEnv =
            foldl
            (fn ({id,loc}, evalTopEnv) =>
                case InterfaceID.Map.find(interfaceEnv, id) of
                  SOME {topEnv,...} => 
                  let
                    val evalTopEnv =
                        V.unionTopEnv "205" loc (evalTopEnv, topEnv)
                  in
                    evalTopEnv
                  end
                | NONE => raise bug "unbound interface id"
            )
            topEnv
            requires

        val _ = clearUsedflag evalTopEnv
        val (returnTopEnv, topdecList) =
            evalPltopdecList {topEnv=evalTopEnv, version=version} topdecs
            handle e => raise e


        val (returnTopEnv, exportList) =
          if !Control.interactiveMode
          then genExport (version, returnTopEnv) Loc.noloc
          else if EU.isAnyError () then (returnTopEnv, nil)
          else (returnTopEnv, CP.checkPitopdecList evalTopEnv (returnTopEnv, provideDecs))
               handle e => raise e

        val interfaceDecls = genExterndecls evalTopEnv

        val topdecs = systemDecls @ interfaceDecls @ topdecList @ exportList

      in
        case EU.getErrors () of
          [] => (returnTopEnv, topdecs, EU.getWarnings())
        | errors => raise UserError.UserErrors (EU.getErrorsAndWarnings ())
      end
      handle exn as UserError.UserErrors _ => raise exn
           | exn => raise bug "uncaught exception in NameEval"

  fun evalRequire (topEnv, systemDecls) 
                  (compileUnit 
                     as
                     {interface={decls,requires,topdecs=provideDecs,...},
                      topdecs}:PI.compileUnit) =
      let
        val _ = EU.initializeErrorQueue()
        val interfaceEnv = EI.evalInterfaces topEnv decls
        val requireTopEnv =
            foldl
            (fn ({id,loc}, evalTopEnv) =>
                case InterfaceID.Map.find(interfaceEnv, id) of
                  SOME {topEnv,...} => 
                  let
                    val evalTopEnv =
                        V.unionTopEnv "205" loc (evalTopEnv, topEnv)
                  in
                    evalTopEnv
                  end
                | NONE => raise bug "unbound interface id"
            )
            V.emptyTopEnv
            requires
        val warnings1 =
            case EU.getErrors () of
              nil => EU.getWarnings()
            | _::_ => raise UserError.UserErrors (EU.getErrorsAndWarnings ())
        (* ignore errors during unionTopEnv;
         * this intends extension of requireTopEnv with topEnv. *)
        val topEnv =
            V.unionTopEnv "205" Loc.noloc (topEnv, requireTopEnv)
        val compileUnit =
            {interface = {decls = nil, requires = nil, topdecs = provideDecs,
                          interfaceName = NONE},
             topdecs = topdecs} : PI.compileUnit
        val (newTopEnv, topdecs, warnings2) =
            nameEval {topEnv=topEnv, version=NONE, systemDecls=systemDecls}
                     compileUnit
        (* ignore errors during unionTopEnv;
         * this intends extension of requireTopEnv with topEnv. *)
        val returnTopEnv =
            V.unionTopEnv "206" Loc.noloc (requireTopEnv, newTopEnv)
      in
        (returnTopEnv, topdecs, warnings1 @ warnings2)
      end

  fun evalBuiltin topdecList =
      let
        fun varEToPrimConExnEnv varE =
            SEnv.foldli
            (fn (name, idstate, (primEnv, conEnv, exnEnv)) =>
                case idstate of 
                  I.IDVAR varId => (primEnv, conEnv, exnEnv)
                | I.IDVAR_TYPED varId => (primEnv, conEnv, exnEnv)
                | I.IDEXVAR {path, ty, used, loc, version, internalId} => (primEnv, conEnv, exnEnv)
                | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
                | I.IDBUILTINVAR {primitive, ty} =>
                  (SEnv.insert(primEnv,
                               name,
                               {primitive=primitive,
                                ty= ITy.evalIty ITy.emptyContext ty}),
                   conEnv, exnEnv) 
                | I.IDCON {id, ty} =>
                  (primEnv,
                   SEnv.insert(conEnv,
                               name,
                               {path=[name],
                                id=id,
                                ty= ITy.evalIty ITy.emptyContext ty}
                              ),
                   exnEnv
                  )
                | I.IDEXN {id, ty} => (primEnv, conEnv, exnEnv)
                | I.IDEXNREP {id, ty} => (primEnv, conEnv, exnEnv)
                | I.IDEXEXN {path, ty, used, loc, version} =>
                  (primEnv, conEnv,
                   SEnv.insert (exnEnv, name,
                                {path=path, ty=ITy.evalIty ITy.emptyContext ty}))
                | I.IDEXEXNREP {path, ty, used, loc, version} =>
                  (primEnv, conEnv,
                   SEnv.insert (exnEnv, name,
                                {path=path, ty=ITy.evalIty ITy.emptyContext ty}))
                | I.IDOPRIM {id, overloadDef, used, loc} => (primEnv, conEnv, exnEnv)
                | I.IDSPECVAR ty => raise bug "IDSPECVAR in evalBuiltin"
                | I.IDSPECEXN ty => raise bug "IDSPECEXN in evalBuiltin"
                | I.IDSPECCON => raise bug "IDSPECCON in evalBuiltin"
            )
            (SEnv.empty,SEnv.empty,SEnv.empty)
            varE
        fun tyEToTyConEnv tyE = 
            SEnv.foldli
            (fn (name, tstr, tyConEnv) =>
                let
                  val tfun =
                      case tstr of
                        V.TSTR tfun  => tfun
                      | V.TSTR_DTY{tfun,...} => tfun
                  val tyCon = ITy.evalTfun ITy.emptyContext [name] tfun
                              handle e => raise e
                in
                  SEnv.insert(tyConEnv, name, tyCon)
                end
            )
            SEnv.empty
            tyE
        fun envToBuiltinEnv (V.ENV {varE, tyE, strE = V.STR envMap})
            =
            let
              val tyConEnv = tyEToTyConEnv tyE 
              val (primEnv, conEnv, exnEnv) = varEToPrimConExnEnv varE
              val strEnv = SEnv.map (fn {env, strKind} => envToBuiltinEnv env) envMap
            in
              BuiltinName.ENV
                {env = {tyConEnv = tyConEnv,
                        primEnv = primEnv,
                        conEnv = conEnv,
                        exnEnv = exnEnv},
                 strEnv = strEnv}
            end
        val _ = EU.initializeErrorQueue()
        val (_, topEnv as {Env, FunE, SigE}, icdecls) =
            EI.evalPitopdecList V.emptyTopEnv (PathSet.empty, topdecList)
        val builtinEnv = envToBuiltinEnv Env
      in
        case EU.getErrors () of
          [] => (topEnv, builtinEnv, icdecls)
        | errors => 
          let
            val errors = EU.getErrorsAndWarnings ()
            val msgs =
                map (Control.prettyPrint o UserError.format_errorInfo) errors
            val _ = map (fn x => (print x; print "\n")) msgs
          in
            raise bug "builtin compilation failed"
          end
      end 
      handle exn => raise bug "uncaught exception in evalBuiltin"
end
end
