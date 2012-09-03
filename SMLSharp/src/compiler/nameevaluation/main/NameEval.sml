(* the initial error code of this file : 001 *)
structure NameEval =
struct
local
  structure I = IDCalc
  structure IT = IDTypes
  structure BV = BuiltinEnv
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure V = NameEvalEnv
  structure BV = BuiltinEnv
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

  fun bug s = Control.Bug ("NameEval: " ^ s)

  val DUMMYIDFUN = "id"

 (* This is to avoid name conflict in functor names and variable names
 *)

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
  exception SIGCHECK

  type path = string list
  val nilPath = nil : string list
  fun pathToString nil = ""
    | pathToString (h::t) = h ^ pathToString t

  fun generateFunVar path funIdPat
    =
    let
(*
      fun stripTypes (P.PLPATTYPED(plpat,ty,loc)) tyListRev =
          stripTypes plpat (ty::tyListRev)
        | stripTypes plpat tyListRev  = (plpat, List.rev tyListRev)
      val (funIdPat, tyList) = stripTypes funpat nil
*)
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
  type tfvSubst = (IT.tfunkind ref) TfvMap.map

  fun refreshEnv (typidSet, exnIdSubst) specEnv
      : (S.tfvSubst * S.conIdSubst) * V.env =
    let
      val tfvMap = TF.tfvsEnv TF.allTfvKind nil (specEnv, TfvMap.empty)
      fun printTfvSubst tfvSubst =
          TfvMap.appi
          (fn (tfv1,tfv2) =>
              (U.printTfun (IT.TFUN_VAR tfv1);
               U.print "=>";
               U.printTfun (IT.TFUN_VAR tfv2);
               U.print "\n"
              )
          )
          tfvSubst
          handle exn => raise exn

      val (tfvSubst, conIdSubst) = 
          TfvMap.foldri
          (fn (tfv as ref (IT.TFV_SPEC {iseq, formals,...}),path,
               (tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    IT.mkTfv (IT.TFV_SPEC{id=id,iseq=iseq,formals=formals})
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as ref (IT.TFV_DTY {iseq,formals,conSpec,liftedTys,...}),
               _, (tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    IT.mkTfv (IT.TFV_DTY{id=id,
                                     iseq=iseq,
                                     conSpec=conSpec,
                                     liftedTys=liftedTys,
                                     formals=formals}
                          )
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as
                   ref(IT.TFUN_DTY{id,iseq,formals,conSpec,liftedTys,dtyKind}),
               path, (tfvSubst, conIdSubst)) =>
              if TypID.Set.member(typidSet, id) then
                let
                  val (name, path) = case List.rev path of
                                       h::tl => (h, List.rev tl)
                                     | _ => raise bug "nil path"
                  val id = TypID.generate()
                  val newTfv =
                      IT.mkTfv (IT.TFUN_DTY {id=id,
                                             iseq=iseq,
                                             formals=formals,
                                             conSpec=conSpec,
                                             liftedTys=liftedTys,
                                             dtyKind=dtyKind
                                            }
                            )
                  val conIdSubst =
                      SEnv.foldri
                      (fn (name, _, conIdSubst) =>
                          case V.findId(specEnv, path@[name]) of
                            SOME (IT.IDCON {id, ty}) =>
                            let
                              val newId = ConID.generate()
                            in
                              ConID.Map.insert(conIdSubst, id, 
                                               IT.IDCON{id=newId, ty=ty}
                                              )
                            end
                          | _ => conIdSubst
                            (* in the case of TSTR tfun, CONs are not
                               exported.
                              (U.print "conid not found (1)\n";
                               U.print "path\n";
                               U.printPath path;
                               U.print "\nname\n";
                               U.print name;
                               U.print "\n";
                               raise bug "conid not found (1)"
                               )
                            *)
                      )
                      conIdSubst
                      conSpec
                in 
                  (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
                end
              else (tfvSubst, conIdSubst)
            | _ => raise bug "non tfv (11)"
          )
          (TfvMap.empty, ConID.Map.empty)
          tfvMap
          handle exn => raise exn
      val _ =
          TfvMap.app
          (fn (tfv as ref (IT.TFV_DTY {iseq,formals,conSpec,liftedTys,id})) =>
              let
                val conSpec =
                    SEnv.map
                    (fn tyOpt =>
                        Option.map (Subst.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    IT.TFV_DTY
                      {iseq=iseq,
                       formals=formals,
                       conSpec=conSpec,
                       liftedTys=liftedTys,
                       id=id}
              end
            | (tfv as ref (IT.TFUN_DTY {iseq,
                                       formals,
                                       conSpec,
                                       liftedTys,
                                       id,
                                       dtyKind
                                      })) =>
              let
                val dtyKind =
                    case dtyKind of
                      IT.OPAQUE{tfun, revealKey} => 
                      IT.OPAQUE{tfun=Subst.substTfvTfun tfvSubst tfun,
                                revealKey=revealKey}
                    | _ => dtyKind
                val conSpec =
                    SEnv.map
                    (fn tyOpt =>
                        Option.map (Subst.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    IT.TFUN_DTY
                      {iseq=iseq,
                       formals=formals,
                       conSpec=conSpec,
                       liftedTys=liftedTys,
                       dtyKind=dtyKind,
                       id=id}
              end
            | _ => ())
          tfvSubst
          handle exn => raise exn
      val subst = {tvarS=S.emptyTvarSubst,
                   tfvS=S.emptyTfvSubst,
                   exnIdS=exnIdSubst,
                   conIdS=conIdSubst} 
      val env =Subst.substTfvEnv tfvSubst specEnv
      val env =Subst.substEnv subst env
    in
      ((tfvSubst, conIdSubst), env)
    end

  fun evalPlpat path (tvarEnv:Ty.tvarEnv) (env:V.env) plpat : V.env * I.icpat =
      let
        val evalPat = evalPlpat path tvarEnv env
        fun evalTy' ty = Ty.evalTy tvarEnv env ty
        fun isVar NONE = true
          | isVar (SOME (IT.IDVAR _)) = true
          | isVar (SOME (IT.IDEXVAR _)) = true
          | isVar (SOME (IT.IDBUILTINVAR _)) = true
          | isVar (SOME (IT.IDCON _)) = false
          | isVar (SOME (IT.IDEXN _)) = false
          | isVar (SOME (IT.IDEXNREP _)) = false
          | isVar (SOME (IT.IDEXEXN _)) = false
          | isVar (SOME (IT.IDOPRIM _)) = true
          | isVar (SOME (IT.IDSPECVAR _)) = raise bug "spec idstatus"
          | isVar (SOME (IT.IDSPECEXN _)) = raise bug "spec idstatus"
          | isVar (SOME IT.IDSPECCON) = raise bug "spec idstatus"
      in
        case plpat of
          P.PLPATWILD loc => (V.emptyEnv, I.ICPATWILD loc)
        | P.PLPATID (longid, loc) =>
          let
            fun makeCon identry =
                case identry of
                  SOME (IT.IDCON {id, ty}) =>
                  I.ICPATCON ({id=id,path=longid, ty=ty}, loc)
                | SOME (IT.IDEXN {id,ty})=>
                  I.ICPATEXN ({id=id,ty=ty, path=longid}, loc)
                | SOME (IT.IDEXNREP {id,ty})=>
                  I.ICPATEXN ({id=id,ty=ty, path=longid}, loc)
                | SOME (IT.IDEXEXN {path,ty})=>
                  I.ICPATEXEXN ({path=path, ty=ty}, loc)
                | SOME (IT.IDBUILTINVAR _) =>
                  raise bug "IDBUILTINVAR to makeCon"
                | SOME (IT.IDVAR _) => raise bug "IDVAR to makeCon"
                | SOME (IT.IDEXVAR _) => raise bug "IDEXVAR to makeCon"
                | SOME (IT.IDOPRIM _) => raise bug "IDOPRIM to makeCon"
                | SOME (IT.IDSPECVAR _)=> raise bug "spec status to makeCon"
                | SOME (IT.IDSPECEXN _)=> raise bug "spec status to makeCon"
                | SOME IT.IDSPECCON=> raise bug "spec status to makeCon"
                | NONE => raise bug "NONE to makeCon"
          in
            case longid of
              nil => raise bug "empty longid"
            | [name] =>
              let
                val identry = V.findId (env, longid)
              in
                if isVar identry then
                  let
                    val varId = VarID.generate()
                    val varInfo = {path=path@longid, id=varId}
                    val env = V.rebindId(V.emptyEnv, name, IT.IDVAR varId)
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
                if isVar identry then
                  (
(*
U.print "ConNotFound ****\n";
U.printPath (path@longid);
U.print "\n";
U.printEnv env;
*)
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
                if isVar identry then VarID.generate()
                else
                  (EU.enqueueError
                     (loc, E.VarPatExpected("090", {longid = [string]}));
                   VarID.generate())
            val varInfo = {path = path@[string], id = varId}
            val returnEnv = V.rebindId(V.emptyEnv, string, IT.IDVAR varId)
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

  (* P.PLCOREDEC (pdecl, loc) *)
  fun evalPdecl (path:IT.path) (tvarEnv:Ty.tvarEnv) (env:V.env) pdecl
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
                      val (newEnv, icpat) = evalPlpat path tvarEnv env plpat
                      val icexp = evalPlexp tvarEnv env plexp
                      val returnEnv = V.unionEnv "203" loc (returnEnv, newEnv)
                    in
                      (returnEnv, (icpat, icexp)::icpatIcexpListRev)
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
                    V.rebindId(returnEnv, name, IT.IDVAR (#id varInfo))
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
                    (V.rebindId(returnEnv, name, IT.IDVAR (#id varInfo)))
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
                                  IT.TFUN_DEF {iseq=iseq,
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
                 | V.TSTR_TOTVAR tvar => SEnv.empty
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
                              IT.TYFUNM([Ty.evalTy tvarEnv env ty],
                                        BV.exnTy)
                        val newExnId = ExnID.generate()
                        val exnInfo = {path=path@[string], ty=ty, id=newExnId}
                        val exEnv =
                            V.rebindId(exEnv,
                                       string,
                                       IT.IDEXN {id=newExnId,ty=ty})
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
                      | SOME(IT.IDEXN exnInfo) =>
                        (V.rebindId(exEnv, string, IT.IDEXNREP exnInfo),
                         exdeclList)
                      | SOME(IT.IDEXNREP exnInfo) =>
                        (V.rebindId(exEnv, string, IT.IDEXNREP exnInfo),
                         exdeclList)
                      | SOME(exentry as IT.IDEXEXN _) =>
                        (V.rebindId(exEnv, string, exentry), exdeclList)
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
                      val env1 = V.lookupStr env longid
                    in
                      V.envWithEnv (returnEnv, env1)
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

  and evalPdeclList (path:IT.path) (tvarEnv:Ty.tvarEnv) (env:V.env) pdeclList
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
               IT.IDVAR id =>     I.ICVAR  (mkInfo id)
             | IT.IDEXVAR {path, ty} => I.ICEXVAR ({path=path, ty=ty},loc)
             | IT.IDBUILTINVAR {primitive, ty} =>
               I.ICBUILTINVAR {primitive=primitive, ty=ty, loc=loc}
             | IT.IDOPRIM id => I.ICOPRIM (mkInfo id)
             | IT.IDCON {id,ty} => I.ICCON ({id=id, path=path, ty=ty}, loc)
             | IT.IDEXN {id,ty} => I.ICEXN ({id=id,ty=ty, path=path}, loc)
             | IT.IDEXNREP {id,ty} => I.ICEXN ({id=id,ty=ty, path=path}, loc)
             | IT.IDEXEXN {path,ty} => I.ICEXEXN ({path=path,ty=ty}, loc)
             | IT.IDSPECVAR _ => raise bug "SPEC id status"
             | IT.IDSPECEXN _ => raise bug "SPEC id status"
             | IT.IDSPECCON => raise bug "SPEC id status"
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
(*
        | P.PLLIST (plexpList, loc) => I.ICLIST(map evalExp plexpList, loc)
*)
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
          in
            I.ICSQLDBI(icpat, evalPlexp tvarEnv newEnv plexp, loc)
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


  datatype mode = Opaque | Trans
  type sigCheckParam =
       {mode:mode,loc:Loc.loc,strPath:string list,strEnv:V.env,specEnv:V.env}
  type sigCheckResult = V.env * I.icdecl list 
  fun sigCheck (param as {mode, loc, ...} : sigCheckParam) : sigCheckResult =
    let
      val revealKey = RevealID.generate() (* for each sigCheck instance *)
      fun instantiateEnv path (specEnv, strEnv) =
        let
          fun instantiateTstr name (specTstr, strTstr) =
              case specTstr of
                V.TSTR_TOTVAR _ => ()
              | _ => 
                let
                  val tfun = 
                      case specTstr of
                        V.TSTR tfun => tfun
                      | V.TSTR_DTY {tfun, ...} => tfun
                      | V.TSTR_TOTVAR _ => raise bug "impossible totvar (1)"
                in
                  case IT.derefTfun tfun of
                    IT.TFUN_DEF _ => ()
                  | IT.TFUN_VAR (tfv as (ref (IT.REALIZED _))) => 
                    raise bug "REALIZED"
                  | IT.TFUN_VAR (tfv as (ref (IT.INSTANTIATED _))) => ()
                  | IT.TFUN_VAR (tfv as (ref (IT.FUN_TOTVAR _))) => ()
                  | IT.TFUN_VAR (tfv as (ref (IT.FUN_DTY _))) => ()
                  | IT.TFUN_VAR (tfv as (ref (IT.TFUN_DTY _))) => ()
                  | IT.TFUN_VAR (tfv as (ref (tfunkind as IT.TFV_SPEC _))) =>
                    (case strTstr of
                       V.TSTR_TOTVAR {id, iseq, tvar} => 
                       tfv := IT.FUN_TOTVAR {tfunkind=tfunkind, tvar=tvar}
                     | V.TSTR tfun => 
                       tfv := IT.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                     | V.TSTR_DTY {tfun, ...} =>
                       tfv := IT.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                    )
                  | IT.TFUN_VAR (tfv as (ref (tfunkind as IT.TFV_DTY _))) =>
                    (case strTstr of
                       V.TSTR_TOTVAR {id, iseq, tvar} => 
                       tfv := IT.FUN_TOTVAR {tfunkind=tfunkind, tvar=tvar}
                     | V.TSTR tfun => 
                       tfv := IT.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                     | V.TSTR_DTY {tfun, ...} =>
                       tfv := IT.INSTANTIATED {tfunkind=tfunkind, tfun=tfun}
                    )
                end                                           
          fun instantiateTyE (specTyE, strTyE) =
              SEnv.appi
                (fn (string, specTstr) =>
                    case SEnv.find (strTyE, string) of
                      NONE => ()
                    | SOME strTstr => 
                      instantiateTstr string (specTstr, strTstr)
                )
                specTyE
          fun instantiateStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SEnv.appi
              (fn (name, specEnv) =>
                  case SEnv.find(strEnvMap, name) of
                    NONE => () (* error will be checked in checkStrE *)
                  | SOME strEnv =>
                    instantiateEnv (path@[name]) (specEnv, strEnv)
              )
              specEnvMap
          val V.ENV{tyE=specTyE, strE=specStrE, ...} = specEnv
          val V.ENV{tyE=strTyE, strE=strStrE, ...} = strEnv
        in
          instantiateTyE (specTyE, strTyE);
          instantiateStrE (specStrE, strStrE)
        end

      fun checkEnv path (specEnv, strEnv) : sigCheckResult =
        let
          val V.ENV{varE=specVarE,tyE=specTyE, strE=specStrE} = specEnv
          val V.ENV{varE=strVarE,tyE=strTyE, strE=strStrE} = strEnv
          fun checkTfun name (specTfun, strTfun) =
              let
                val specTfun =
                    IT.pruneTfun(N.reduceTfun(IT.pruneTfun specTfun))
                val strTfun =
                    IT.derefTfun (N.reduceTfun (IT.pruneTfun strTfun))
              in
                case (specTfun, strTfun) of
                  (IT.TFUN_DEF {formals=specFormals, realizerTy=specTy,...},
                   IT.TFUN_DEF {formals=strFormals, realizerTy=strTy,...}) =>
                  if List.length specFormals <> List.length strFormals then
                     EU.enqueueError
                       (loc,E.SIGArity("200",{longid=path@[name]}))
                  else if N.eqTfun((specFormals,specTy),(strFormals,strTy))
                  then ()
                  else
                    (
                     EU.enqueueError
                       (loc,E.SIGDtyMismatch
                              ("210",{longid=path@[name ^ "(1)"]}))
                    )
                | (IT.TFUN_VAR (ref (IT.TFUN_DTY {id=id1,...})),
                   IT.TFUN_VAR (ref (IT.TFUN_DTY {id=id2,...}))) =>
                  if TypID.eq(id1,id2) then ()
                  else 
                    (
                     EU.enqueueError
                       (loc,
                        E.SIGDtyMismatch("220",{longid=path@[name ^ "(2)"]}))
                    )
                | _ => 
                  (
                   EU.enqueueError
                     (loc,E.SIGDtyMismatch("230",{longid=path@[name ^ "(3)"]}))
                  )
              end

          fun checkTstr name (specTstr, strTstr) =
              let
                fun checkVarE varE =
                    SEnv.appi
                      (fn (name, idstatus) => 
                          case SEnv.find(strVarE, name) of
                            NONE => 
                            EU.enqueueError
                              (loc,
                               E.SIGConNotFound
                                 ("240",{longid=path@[name ^ ":(1)"]}))
                          | SOME strIdstatus =>
                            (case (idstatus, strIdstatus) of
                               (IT.IDCON {id=conid1,ty=ty1},
                                IT.IDCON {id=conid2,ty=ty2}) =>
                               if ConID.eq(conid1, conid2) then ()
                               else
                                 (
                                  EU.enqueueError
                                    (loc,
                                     E.SIGConNotFound
                                       ("250",{longid=path@[name ^ ":(2)"]}))
                                 )
                             | (IT.IDCON _, _) => 
                               EU.enqueueError
                                 (loc,
                                  E.SIGConNotFound
                                    ("260",{longid=path@[name ^ ":(3)"]}))
                             | _ => raise bug "non conid"
                            )
                      )
                      varE
              in
                case specTstr of
                  V.TSTR specTfun =>
                  (case strTstr of
                     V.TSTR strTfun => checkTfun name (specTfun, strTfun) 
                   | V.TSTR_DTY {tfun=strTfun, ...} =>
                     checkTfun name (specTfun, strTfun) 
                   | V.TSTR_TOTVAR {tvar={id=id1,...},...} =>
                     (case IT.derefTfun specTfun of
                       IT.TFUN_VAR(ref (IT.FUN_TOTVAR{tvar={id=id2,...},...}))
                        => if TvarID.eq(id1,id2) then ()
                           else
                             (U.print "\nTSTR_TOTVAR (1)\n";
                              U.print "specTstr\n";
                              U.printTstr specTstr;
                              U.print "strTstr\n";
                              U.printTstr strTstr;
                              U.print "name:\n";
                              U.print name;
                              U.print "\n";
                              U.print "specEnv:\n";
                              U.printEnv specEnv;
                              U.print "\n";
                              U.print "strEnv:\n";
                              U.printEnv strEnv;
                              U.print "\n";
                              raise bug "TSTR_TOTVAR (2)"
                             )
                      | IT.TFUN_DEF {formals, realizerTy,...} =>
                        let
                          val ty = N.reduceTy TvarMap.empty realizerTy
                        in
                          case ty of 
                            IT.TYVAR {id=id2,...} =>
                            if TvarID.eq(id1,id2) then ()
                            else
                              (U.print "TSTR_TOTVAR (4)\n";
                               U.print "name:\n";
                               U.print name;
                               U.print "\n";
                               U.print "specTstr\n";
                               U.printTstr specTstr;
                               U.print "\n";
                               U.print "strTstr\n";
                               U.printTstr strTstr;
                               U.print "strTstr\n";
                               raise bug "TSTR_TOTVAR (4)"
                              )
                          | _ => 
                            (U.print "TSTR_TOTVAR (4-2)\n";
                             U.printTy ty;
                             U.print "\n";
                             raise bug "TSTR_TOTVAR (4-2)"
                            )
                        end
                      | _ =>  
                        (U.print "TSTR_TOTVAR (5)\n";
                         U.print "name:\n";
                         U.print name;
                         U.print "\n";
                         U.print "specTstr\n";
                         U.printTstr specTstr;
                         U.print "\n";
                         U.print "strTstr\n";
                         U.printTstr strTstr;
                         U.print "strTstr\n";
                         raise bug "TSTR_TOTVAR (5)"
                        )
                     )
                  )
                | V.TSTR_DTY {tfun=specTfun,formals, conSpec,...} =>
                  (case strTstr of
                     V.TSTR strTfun =>
                     EU.enqueueError
                       (loc,E.SIGDtyRequired("270",{longid=path@[name]}))
                   | V.TSTR_DTY {tfun=strTfun,
                                 varE=strVarE,
                                 formals=strFormals,
                                 conSpec=strConSpec,...} =>
                     (checkTfun name (specTfun, strTfun);
                      let
                        val result = N.checkConSpec 
                                       ((formals, conSpec),
                                        (strFormals, strConSpec))
                      in
                        case result of
                          N.SUCCESS => ()
                        | _ =>
                          EU.enqueueError
                            (loc,E.SIGDtyMismatch
                                   ("280",{longid=path@[name ^ "(4)"]}))
                      end;
                      checkVarE strVarE)
                   | V.TSTR_TOTVAR _ => raise bug "TSTR_TOTVAR (6)"
                  )
                | V.TSTR_TOTVAR _ => raise bug "TSTR_TOTVAR (7)"
              end
                
          fun checkTyE (specTyE, strTyE) =
               SEnv.foldri
                (fn (name, specTstr, tyE) =>
                     case SEnv.find (strTyE, name) of
                       NONE => 
                       (EU.enqueueError
                          (loc,E.SIGTypUndefined("290",{longid=path@[name]}));
                        tyE)
                     | SOME strTstr => 
                       (checkTstr name (specTstr, strTstr);
                        SEnv.insert(tyE, name, specTstr))
                )
                SEnv.empty
                specTyE

          fun checkVarE (specVarE, strVarE) =
              SEnv.foldri
                (fn (name, specIdStatus, (varE, icdeclList)) =>
                    case specIdStatus of
                      IT.IDSPECVAR ty =>
                      let
                        fun makeTypdecl icexp =
                            let
                              val icexp = I.ICSIGTYPED
                                            {path=path@[name],
                                             icexp=icexp,
                                             revealKey=revealKey,
                                             ty=ty,
                                             loc=loc}
                              val newId = VarID.generate()
                              val icpat =
                                  I.ICPATVAR ({path=path@[name],id=newId}, loc)
                            in
                              (SEnv.insert(varE, name, IT.IDVAR newId),
                               I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                               :: icdeclList)
                            end
                      in
                        case SEnv.find(strVarE, name) of
                          NONE =>
                          (EU.enqueueError
                             (loc, E.SIGVarUndefined
                                     ("300",{longid = path@[name]}));
                           (varE, icdeclList)
                          )
                        | SOME (IT.IDVAR id) => 
                          makeTypdecl (I.ICVAR ({path=path@[name],id=id},loc))
                        | SOME (IT.IDEXVAR {path, ty}) => 
                          makeTypdecl (I.ICEXVAR ({path=path,ty=ty},loc))
                        | SOME (IT.IDBUILTINVAR {primitive, ty}) => 
                          makeTypdecl
                            (I.ICBUILTINVAR {primitive=primitive,ty=ty,loc=loc})
                        | SOME (IT.IDCON {id, ty}) => 
                          makeTypdecl
                            (I.ICCON ({path=path@[name],ty=ty, id=id}, loc))
                        | SOME (IT.IDEXN {id, ty}) => 
                          makeTypdecl
                            (I.ICEXN ({path=path@[name],ty=ty, id=id},loc))
                        | SOME (IT.IDEXNREP {id, ty}) => 
                          makeTypdecl
                            (I.ICEXN ({path=path@[name],ty=ty, id=id},loc))
                        | SOME (IT.IDEXEXN {path, ty}) => 
                          makeTypdecl (I.ICEXEXN ({path=path,ty=ty},loc))
                        | SOME (IT.IDOPRIM id) => 
                          makeTypdecl (I.ICOPRIM ({path=path@[name],id=id},loc))
                        | SOME (IT.IDSPECVAR _) => raise bug "IDSPECVAR"
                        | SOME (IT.IDSPECEXN _) => raise bug "IDSPECEXN"
                        | SOME IT.IDSPECCON => raise bug "IDSPECCON"
                      end
                    | IT.IDSPECEXN ty1 => 
                      (case SEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (loc,
                             E.SIGVarUndefined("310",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as IT.IDEXN {id, ty=ty2}) => 
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           (* we must return ty1 instead of ty2 here,
                              since ty1 may be abstracted *)
                           if N.equalTy TvarID.Map.empty (ty1, ty2) then
                             (SEnv.insert(varE,
                                          name,
                                          IT.IDEXN {id=id, ty=ty1}),
                              icdeclList)
                           else 
                             (EU.enqueueError
                                (loc,
                                 E.SIGExnType("320",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as IT.IDEXNREP {id, ty=ty2}) =>
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy TvarID.Map.empty (ty1, ty2) then
                             (SEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (loc,
                                 E.SIGExnType("330",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as IT.IDEXEXN {path, ty=ty2}) => 
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy TvarID.Map.empty (ty1, ty2) then
                             (SEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (loc, E.SIGExnType
                                        ("340",{longid = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | _ =>
                         (EU.enqueueError
                            (loc, E.SIGExnExpected
                                    ("350",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                      )
                    | IT.IDSPECCON =>
                      (case SEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (loc,
                             E.SIGVarUndefined("360",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as IT.IDCON {id,ty}) => 
                         (SEnv.insert(varE, name, idstatus), icdeclList)
                       | SOME _ => 
                         (EU.enqueueError
                            (loc, E.SIGConNotFound
                                    ("370",{longid = path@[name ^ ":(4)"]}));
                          (varE, icdeclList)
                         )
                      )
                    | IT.IDCON {id, ty} =>
                      (case SEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (loc, E.SIGVarUndefined
                                    ("380",{longid = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as IT.IDCON {id=id2, ty=ty2}) => 
                         if ConID.eq(id, id2) then 
                           (SEnv.insert(varE, name, idstatus), icdeclList)
                         else 
                           (EU.enqueueError
                              (loc, E.SIGConNotFound
                                      ("390",{longid = path@[name ^ ":(5)"]}));
                            (varE, icdeclList)
                           )
                       | SOME _ => 
                         (EU.enqueueError
                            (loc, E.SIGConNotFound
                                    ("400",{longid = path@[name ^ ":(6)"]}));
                          (varE, icdeclList)
                         )
                      )
                    | _ =>
                      (U.print "\ncheckVarE\n";
                       U.printIdstatus specIdStatus;
                       U.print "\n";
                       raise bug "illeagal idstatus"
                      )
                )
                (SEnv.empty, nil)
                specVarE

          fun checkStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SEnv.foldri
                (fn (name, specEnv, (strE, icdeclList)) =>
                    case SEnv.find(strEnvMap, name) of
                      NONE => 
                      (EU.enqueueError
                         (loc, E.SIGStrUndefined("410",{longid=path@[name]}));
                       (strE, icdeclList))
                    | SOME strEnv =>
                      let
                        val (env, icdeclList1) =
                            checkEnv (path@[name]) (specEnv, strEnv)
                      in
                        (SEnv.insert(strE, name, env), icdeclList@icdeclList1)
                      end
                )
                (SEnv.empty, nil)
                specEnvMap

          val tyE = checkTyE (specTyE, strTyE)
          val (varE, icdeclList1) = checkVarE(specVarE, strVarE)
          val (strE, icdeclList2) = checkStrE (specStrE, strStrE)
          val env = V.ENV{varE=varE, tyE=tyE, strE=V.STR strE}
        in
          if EU.isAnyError () then raise SIGCHECK
          else (env, icdeclList1@icdeclList2)
        end

      fun makeOpaqueInstanceEnv path env =
        let
          fun makeOpaqueInstanceTstr name (tstr, (env, icdeclList)) =
              (
              case tstr of 
                V.TSTR tfun =>
                (case IT.derefTfun tfun of
                   IT.TFUN_VAR(tfv as ref (IT.INSTANTIATED {tfunkind,tfun})) =>
                   (case tfunkind of
                      IT.TFV_SPEC {id, iseq, ...} => 
                      let
                        val formals = IT.tfunFormals tfun
                        val liftedTys = IT.tfunLiftedTys tfun
                        val newTfunkind =
                            IT.TFUN_DTY {id=id,
                                         iseq=iseq,
                                         formals=formals,
                                         conSpec=SEnv.empty,
                                         liftedTys=liftedTys,
                                         dtyKind=IT.OPAQUE
                                           {tfun=tfun,
                                            revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val env =
                            V.rebindTstr(env, name, V.TSTR (IT.TFUN_VAR tfv))
                      in
                        (env, icdeclList)
                      end
                    | IT.TFV_DTY {id, iseq, ...} => 
                      let
                        val formals = IT.tfunFormals tfun
                        val liftedTys = IT.tfunLiftedTys tfun
                        val newTfunkind =
                            IT.TFUN_DTY {id=id,
                                        iseq=iseq,
                                        formals=formals,
                                        conSpec=SEnv.empty,
                                        liftedTys=liftedTys,
                                        dtyKind=
                                          IT.OPAQUE
                                          {tfun=tfun, revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val newTfun = IT.TFUN_VAR tfv
                        val env = V.rebindTstr(env, name,V.TSTR newTfun)
                      in
(*
                        (env,
                         I.ICOPAQUETYPE {tfun=newTfun, refTfun=tfun}::
                         icdeclList)
*)
                        (env,icdeclList)
                      end
                    | _ => 
                      (U.print "non tfv (5)\n";
                       U.print "name\n";
                       U.print name;
                       U.print "\ntstr\n";
                       U.printTstr tstr;
                       U.print "\n";
                       raise bug "non tfv (5)"
                      )
                   )
                 | IT.TFUN_VAR _ =>
                   let
                   in
                     (V.rebindTstr(env, name, tstr),icdeclList)
                   end
                 | IT.TFUN_DEF _ =>
                   let
                   in
                     (V.rebindTstr(env, name, tstr),icdeclList)
                   end
                )
              | V.TSTR_DTY {tfun, varE, ...} =>
                (case IT.derefTfun tfun of
                   IT.TFUN_VAR
                     (tfv as ref (IT.INSTANTIATED{tfunkind,tfun=strTfun})) =>
                      (case tfunkind of
                         IT.TFV_DTY {id, iseq, formals, conSpec, liftedTys} =>
                         let
                           val newTfunkind =
                               IT.TFUN_DTY {id=id,
                                           iseq=iseq,
                                           formals=formals,
                                           conSpec=conSpec,
                                           liftedTys=liftedTys,
                                           dtyKind=
                                             IT.OPAQUE
                                             {tfun=strTfun,revealKey=revealKey}
                                          }
                           val _ = tfv := newTfunkind
                           val returnTy =
                               IT.TYCONSTRUCT
                                 {typ={path=path@[name],tfun=tfun},
                                  args= map (fn tv=>IT.TYVAR tv) formals}
                           val (varE, conbind) =
                               SEnv.foldri
                                 (fn (name, tyOpt, (varE, conbind)) =>
                                     let
                                       val conId = ConID.generate()
                                       val conTy =
                                           case tyOpt of
                                             NONE => 
                                             (case formals of 
                                                nil => returnTy
                                              | _ => 
                                                IT.TYPOLY
                                                  (
                                                   map 
                                                     (fn tv=>(tv,IT.UNIV))
                                                     formals,
                                                   returnTy
                                                  )
                                             )
                                           | SOME ty => 
                                             case formals of 
                                               nil =>
                                               IT.TYFUNM([ty], returnTy)
                                             | _ => 
                                               IT.TYPOLY
                                                 (
                                                  map
                                                    (fn tv =>(tv,IT.UNIV))
                                                    formals,
                                                  IT.TYFUNM([ty], returnTy)
                                                 )
                                       val conInfo =
                                           {path=path@[name],ty=conTy,id=conId}
                                       val idstatus =
                                           IT.IDCON{id=conId,ty=conTy}
                                     in
                                       (SEnv.insert(varE, name, idstatus),
                                        {datacon=conInfo,tyOpt=tyOpt}
                                        :: conbind)
                                     end
                                 )
                                 (SEnv.empty, nil)
                                 conSpec
                           val newTstr = V.TSTR_DTY
                                           {tfun=IT.TFUN_VAR tfv,
                                            varE=varE,
                                            formals=formals,
                                            conSpec=conSpec}
                           val env = V.rebindTstr(env, name, newTstr)
                           val env = V.envWithVarE(env, varE)
                         in
                           (env, icdeclList)
                         end
                       | _ => raise bug "non dty tfv (1)"
                      )
                 | _ => (V.rebindTstr(env, name, tstr),icdeclList)
                )
              | V.TSTR_TOTVAR {id, iseq, tvar} => raise bug "totvar"
              )

          fun makeOpaqueInstanceTyE tyE env =
              (
              SEnv.foldri
                (fn (name, tstr, (env, icdeclList)) =>
                    makeOpaqueInstanceTstr name (tstr, (env, icdeclList))
                )
                (env, nil)
                tyE
              )

          fun makeOpaqueInstanceStrE (V.STR strEnvMap) env =
              let
                val (env, icdeclList) =
                    SEnv.foldri
                      (fn (name, strEnv, (env, icdeclList)) =>
                          let
                            val (strEnv, icdeclList1) =
                                makeOpaqueInstanceEnv (path@[name]) strEnv
                          in
                            (V.rebindStr(env, name, strEnv), 
                             icdeclList@icdeclList1)
                          end
                      )
                      (env, nil)
                      strEnvMap
              in
                (env, icdeclList)
              end

          val V.ENV {varE, tyE, strE} = env
          val env = V.envWithVarE(env, varE)
          val (env, icdeclList1) = makeOpaqueInstanceTyE tyE env
          val (env, icdeclList2) = makeOpaqueInstanceStrE strE env
        in
          (env, icdeclList1@icdeclList2)
        end

      fun makeTransInstanceEnv path env =
        let
          val V.ENV {varE, tyE, strE} = env
          fun makeTransInstanceTstr name (tstr, tyE) =
              case tstr of 
                V.TSTR tfun =>
                (case IT.derefTfun tfun of
                   IT.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      IT.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := IT.REALIZED{tfun=tfun,id=IT.tfunkindId tfunkind};
                       SEnv.insert(tyE, name, V.TSTR tfun)
                      )
                    | IT.FUN_TOTVAR {tvar, tfunkind} =>
                      (case tfunkind of
                         IT.TFV_SPEC {id, iseq,...} =>
                         SEnv.insert(tyE,
                                     name,
                                     V.TSTR_TOTVAR {id=id,iseq=iseq,tvar=tvar}
                                    )
                       | _ => raise bug "non tvspec totvar"
                      )
                    | IT.TFV_SPEC _ =>
                      (U.print "non instantiated tfv (3)";
                       U.print "tstr\n";
                       U.printTstr tstr;
                       raise bug "non instantiated tfv (3)"
                      )
                    | IT.TFV_DTY _ =>
                      (U.print "non instantiated tfv (3)";
                       U.print "tstr\n";
                       U.printTstr tstr;
                       raise bug "non instantiated tfv (3)"
                      )
                    | IT.TFUN_DTY _ => SEnv.insert(tyE, name, tstr)
                    | _ =>
                      (U.print "non instantiated tfv (3)";
                       U.print "tstr\n";
                       U.printTstr tstr;
                       raise bug "non instantiated tfv (3)"
                      )
                   )
                 | _ => SEnv.insert(tyE, name, tstr)
                )
              | V.TSTR_DTY {tfun=specTfun, varE=tstrVarE, ...} =>
                (case IT.derefTfun specTfun of
                   IT.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      IT.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := IT.REALIZED{tfun=tfun,id=IT.tfunkindId tfunkind};
                       case IT.derefTfun tfun of 
                        IT.TFUN_VAR
                          (ref (IT.TFUN_DTY {id,iseq,formals,conSpec,liftedTys,
                                            dtyKind})) =>
                        let
                          val varE =
                              SEnv.mapi
                                (fn (name, _) =>
                                    case SEnv.find(varE, name) of
                                      SOME idstatus => idstatus
                                    | NONE =>
                                      (U.print "id not found";
                                       U.print "\n";
                                       U.print name;
                                       U.print "\n";
                                       U.print "tfun\n";
                                       U.printTfun tfun;
                                       U.print "\n";
                                       U.print "specTfun\n";
                                       U.printTfun specTfun;
                                       U.print "\n";
                                       raise bug "id not found"
                                      )
                                )
                                tstrVarE
                        in
                          SEnv.insert
                            (tyE,
                             name,
                             V.TSTR_DTY {tfun=tfun,
                                         varE=varE,
                                         formals=formals,
                                         conSpec=conSpec}
                            )
                        end
                      | _ => 
                        (
                         U.print "non dty instance\n";
                         U.print "tstr\n";
                         U.printTstr tstr;
                         raise bug "non dty instance"
                        )
                      )
                    | IT.TFV_SPEC _ =>
                      (U.print "non instantiated tfv (3)";
                       U.print "tstr\n";
                       U.printTstr tstr;
                       raise bug "non instantiated tfv (3)"
                      )
                    | IT.TFV_DTY _ =>
                      (U.print "non instantiated tfv (3)";
                       U.print "tstr\n";
                       U.printTstr tstr;
                       raise bug "non instantiated tfv (3)"
                      )
                    | IT.TFUN_DTY _ => SEnv.insert(tyE, name, tstr)
                    | _ => 
                      (
                       U.print "non instantiated tfv (4)\n";
                       U.print "tfun\n";
                       U.printTfun specTfun;
                       U.print "\n";
                       raise bug "non instantiated tfv (4)"
                      )
                   )
                 | _ => SEnv.insert(tyE, name, tstr)
                )
              | V.TSTR_TOTVAR {id, iseq, tvar} => raise bug "totvar"

          fun makeTransInstanceTyE tyE =
              SEnv.foldri
                (fn (name, tstr, tyE) =>
                    makeTransInstanceTstr name (tstr, tyE)
                )
                SEnv.empty
                tyE
          fun makeTransInstanceStrE (V.STR strEnvMap) =
              let
                val strEnvMap =
                    SEnv.foldri
                      (fn (name, env, strEnvMap) =>
                          let
                            val env =
                                makeTransInstanceEnv (path@[name]) env
                          in
                            SEnv.insert(strEnvMap, name, env)
                          end
                      )
                      SEnv.empty
                      strEnvMap
              in
                V.STR strEnvMap
              end
          val tyE = makeTransInstanceTyE tyE
          val strE = makeTransInstanceStrE strE
        in
          V.ENV {varE=varE, tyE=tyE, strE=strE}
        end

      fun makeInstanceEnv path env =
          case mode of 
            Opaque => makeOpaqueInstanceEnv path env
          | Trans => (makeTransInstanceEnv path env, nil)

      (* sigCheck body *)
      val path = #strPath param
      val specEnv = #specEnv param
      val strEnv = #strEnv param
      val _ = instantiateEnv path (specEnv, strEnv)
      val specEnv = N.reduceEnv specEnv
      val (env, icdeclList1) = checkEnv path (specEnv, strEnv)
      val (env, icdeclList2) = makeInstanceEnv path env
    in
      (env, icdeclList1@icdeclList2)
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
      : V.env * I.icdecl list =
      case plstrexp of
        (* struct ... end *)
        P.PLSTREXPBASIC (plstrdecList, loc) =>
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
      | P.PLSTRID (longid, loc) =>
        ((V.lookupStr env longid, nil)
         handle V.LookupStr =>
                (EU.enqueueError (loc, E.StrNotFound("430",{longid = longid}));
                 (V.emptyEnv, nil)
                )
        )
      | P.PLSTRTRANCONSTRAINT (plstrexp, plsigexp, loc) =>
        (
        let
          val (strEnv, icdeclList1) = evalPlstrexp topEnv path plstrexp
          val specEnv = Sig.evalPlsig topEnv plsigexp
          val specEnv = #2 (Sig.refreshSpecEnv specEnv)
          val (returnEnv, specDeclList2) =
              sigCheck
                {mode = Trans,
                 strPath = path,
                 strEnv = strEnv,
                 specEnv = specEnv,
                 loc = loc
                }
        in
          (returnEnv, icdeclList1 @ specDeclList2)
        end
        handle SIGCHECK => (V.emptyEnv, nil)
        )

      | P.PLSTROPAQCONSTRAINT (plstrexp, plsigexp, loc) =>
        (
        let
           val (strEnv, icdeclList1) = evalPlstrexp topEnv path plstrexp
           val specEnv = Sig.evalPlsig topEnv plsigexp
           val specEnv = #2 (Sig.refreshSpecEnv specEnv)
           val (returnEnv, specDeclList2) =
               sigCheck
                 {mode = Opaque,
                  strPath = path,
                  strEnv = strEnv,
                  specEnv = specEnv,
                  loc = loc
                  }
        in
          (returnEnv, icdeclList1 @ specDeclList2)
        end
        handle SIGCHECK => (V.emptyEnv, nil)
        )

      | P.PLFUNCTORAPP (string, argPath, loc) =>
        applyFunctor topEnv (path, string, argPath, loc)

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
          val (returnEnv2, icdeclList2) = evalPlstrexp evalEnv path plstrexp
        in
          (returnEnv2, icdeclList1 @ icdeclList2)
        end

  and applyFunctor (topEnv as {Env = env, FunE, SigE})
                   (copyPath, funName, argPath, loc)
      : V.env * I.icdecl list = 
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

val _ = U.print "annpyFunctor\n"
val _ = U.print "funName\n"
val _ = U.print funName
val _ = U.print "\n"
val _ = U.print "copyPath\n"
val _ = U.printPath copyPath
val _ = U.print "\n"

        fun instVarE (varE,actualVarE)
                     {tvarS, tfvS, conIdS, exnIdS} =
            let
              val conIdS =
                  SEnv.foldri
                    (fn (name, idstatus, conIdS) =>
                      case idstatus of
                        IT.IDCON {id, ty} =>
                        (case SEnv.find(actualVarE, name) of
                           SOME (idstatus as IT.IDCON _) =>
                           ConID.Map.insert(conIdS, id, idstatus)
                         | _ => raise bug "non conid"
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
              val tfun = IT.derefTfun tfun
              val actualTfun = IT.derefTfun actualTfun
            in
              case tfun of
                IT.TFUN_VAR (tfv1 as ref (IT.TFUN_DTY {dtyKind,...})) =>
                (case actualTfun of
                   IT.TFUN_VAR(tfv2 as ref (tfunkind as IT.TFUN_DTY _)) =>
                   (tfv1 := tfunkind;
                    {tfvS=TfvMap.insert (tfvS, tfv1, tfv2)
                          handle e => raise e,
                     tvarS=tvarS,
                     exnIdS=exnIdS,
                     conIdS=conIdS}
                   )
                 | IT.TFUN_DEF _ =>
                   (case dtyKind of
                      IT.FUNPARAM => 
                      (EU.enqueueError
                         (loc, E.FunctorParamRestriction("440",{longid=path}));
                       subst)
                    | _ => raise bug "tfun def"
                   )
                 | IT.TFUN_VAR _ => raise bug "tfun var"
                )
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
               | V.TSTR_TOTVAR {id, iseq, tvar} => 
                 raise bug "tfvSubst to totvar"
              )
            | V.TSTR_DTY {tfun,varE,...} =>
              (
               case actualTstr of
                 V.TSTR actualTfun => raise bug "TSTR_DTY vs TSTR"
               | V.TSTR_DTY {tfun=actualTfun,varE=actualVarE,...} =>
                 let
                   val subst = instTfun path (tfun, actualTfun) subst
                 in
                   instVarE (varE, actualVarE) subst
                 end
               | V.TSTR_TOTVAR {id, iseq, tvar} => 
                 raise bug "tfvSubst to totvar"
              )
            | V.TSTR_TOTVAR {tvar,...} => 
              let
                val ty =
                    case actualTstr of
                      V.TSTR tfun => 
                      IT.TYCONSTRUCT{typ={tfun=tfun,path=path},args=nil}
                    | V.TSTR_DTY {tfun,...} =>
                      IT.TYCONSTRUCT{typ={tfun=tfun,path=path},args=nil}
                    | V.TSTR_TOTVAR {tvar,...} => IT.TYVAR tvar
                val ty = N.reduceTy TvarMap.empty ty
              in
                {tvarS=TvarMap.insert(tvarS,tvar,ty),
                 tfvS=tfvS,
                 conIdS=conIdS,
                 exnIdS=exnIdS
                }
              end
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
            (fn (name, env, subst) =>
                let
                  val actualEnv = case SEnv.find(actualEnvMap, name) of
                                    SOME env => env 
                                  | NONE => raise bug "actualEnv not found"
                in
                  instEnv (path@[name]) (env, actualEnv) subst
                end
            )
            subst
            envMap

        val funEEntry as
           {argSig,
             argStrName,
             argEnv,
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

        val (actualArgEnv, actualArgDecls) =
            let
              val argSig = #2 (Sig.refreshSpecEnv argSig)
                           handle e => raise e
              val (argStrEnv,_) =
                  evalPlstrexp topEnv nilPath (P.PLSTRID(argPath,loc))
                  handle e => raise e
            in
              sigCheck
                {mode = Trans,
                 strPath = argPath,
                 strEnv = argStrEnv,
                 specEnv = argSig,
                 loc = loc
                }
              handle e => raise e
            end
        val _ = if EU.isAnyError () then raise SIGCHECK else ()
        val tempEnv =
            V.ENV{varE=SEnv.empty,
                  tyE=SEnv.empty,
                  strE=
                    V.STR
                    (
                     SEnv.insert
                       (SEnv.insert(SEnv.empty, "arg", argEnv),
                        "body",
                        bodyEnv)
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
            refreshEnv (typidSet, exnIdSubst) tempEnv
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
        val argEnv = case V.findStr(tempEnv, ["arg"]) of
                       SOME env => env
                     | NONE => raise bug "impossible"
        val bodyEnv = case V.findStr(tempEnv, ["body"]) of
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
(*
              val liftedTys = 
                  case !fromTfv of
                    IT.TFUN_DTY {liftedTys,...} => liftedTys
                  | _ => IT.emptyLiftedTys
              val liftedTysInst =
                  TvarSet.foldr
                  (fn (tvar, liftedTysInst) =>
                      case TvarMap.find(tvarS, tvar) of
                        SOME ty => TvarMap.insert(liftedTysInst, tvar, ty)
                      | _ => liftedTysInst
                  )
                  TvarMap.empty
                  liftedTys
*)
            in
              {from=IT.TFUN_VAR fromTfv,
(*
               liftedTysInst=liftedTysInst,
*)
               to=IT.TFUN_VAR toTfv}
              :: castList
            end
        val castList = TfvMap.foldri makeCast nil tfvSubst
                       handle e => raise e
        val bodyVarExp = I.ICTYCAST (castList, bodyVarExp, loc)
        val (bodyVarList,_) =
            FunctorUtils.varsInEnv
              ExnID.Set.empty 
              loc (* copyPath *) nil nil bodyEnv

(*
val _ = U.print "annpyFunctor\n"
val _ = U.print "bodyVarList\n"
val _ = map (fn x => (U.printExp x; U.print "\n")) bodyVarList
val _ = U.print "\n"
val _ = U.print "bodyEnv\n"
val _ = U.printEnv bodyEnv
val _ = U.print "\n"
*)
        val (_, returnEnv, patFields, exntagDecls) =
            foldl
              (fn ((bindPath, I.ICVAR ({path, id=_},loc)),
                   (n, returnEnv, patFields, exntagDecls)) =>
                  let
(*
val _ = U.print "bodyVarList; ICVAR\n"
*)
                    val newId = VarID.generate()
                    val varInfo = {id=newId, path=path}
                    val newIdstatus = IT.IDVAR newId
                    val newPat = I.ICPATVAR(varInfo, loc)
                    val returnEnv =
                        V.rebindIdLongid(returnEnv, bindPath, newIdstatus)
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
(*
val _ = U.print "bodyVarList; ICEXN\n"
*)
                    (* FIXME: here we generate env with IDEXN env and
                       exception tag E = x decl.
                     *)
                    val newVarId = VarID.generate()
                    val newExnId = ExnID.generate()
                    val exnInfo = {id=newExnId, path=path, ty=ty}
                    val varInfo = {id=newVarId, path=path}
                    val newIdstatus = IT.IDEXN {id=newExnId, ty=ty}
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
(*
val _ = U.print "bodyVarList; ICEXVAR\n"
*)
                    val newId = VarID.generate()
                    val newVarInfo = {id=newId, path=path}
                    val newIdstatus = IT.IDVAR newId
                    val newPat = I.ICPATVAR({path=path, id=newId}, loc)
                    val returnEnv =
                        V.rebindIdLongid(returnEnv, bindPath, newIdstatus)
(*
val _ = U.print "returnEnv for ICEXVAR\n"
val _ = U.printEnv returnEnv
val _ = U.print "\n"
*)
                  in
                    (n + 1,
                     returnEnv,
                     patFields @[(Int.toString n, newPat)],
                     exntagDecls
                    )
                  end
                | (* see: bug 061_functor.sml *)
                  ((bindPath, I.ICEXN_CONSTRUCTOR (exnInfo as {path,...},loc)),
                   (n, returnEnv, patFields, exntagDecls)) =>
                  let
(*
val _ = U.print "bodyVarList; ICEXN_CONSTRUCTOR\n"
*)
                    val newId = VarID.generate()
                    val newVarInfo = {id=newId, path = path}
                    val newIdstatus = IT.IDVAR newId
                    val newPat = I.ICPATVAR({path=path, id=newId}, loc)
(*
 This is the case of con. We should not revind id to
 its tag variable.
                    val returnEnv =
                        V.rebindIdLongid(returnEnv, path, newIdstatus)
*)
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

(*
        val argExpList =
            actualDummyIdfun :: (varsInEnv loc argPath nil actualArgEnv)
*)
        val (argExpList, _) =
            FunctorUtils.varsInEnv ExnID.Set.empty loc argPath nil actualArgEnv
        val argExpList = map #2 argExpList
        val argTerm = I.ICRECORD(Utils.listToTuple argExpList, loc)
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

val _ = U.print "applyfunctor bodyEnv***\n"
val _ = U.printEnv bodyEnv
val _ = U.print "\n"

val _ = U.print "applyfunctor returnEnv (1) ***\n"
val _ = U.printEnv returnEnv
val _ = U.print "\n"

(* FIXE: We must be slim down the bodyEnv below
        val returnEnv = V.envWithEnv(bodyEnv, returnEnv)
 *)

val _ = U.print "applyfunctor returnEnv (2) ***\n"
val _ = U.printEnv returnEnv
val _ = U.print "\n"

      in (* applyFunctor *)
        (returnEnv, actualArgDecls @ [functorAppDecl] @ exntagDecls)
      end
      handle 
      SIGCHECK => (V.emptyEnv, nil)
    | FunIDUndefind  =>
      (EU.enqueueError
         (loc, E.FunIdUndefined("450",{name = funName}));
       (V.emptyEnv, nil)
      )

  fun evalFunctor topEnv {name, argStrName, argSig, body, loc} =
      let
val _ = U.print "argplsig in nameeval main\n"
val _ = U.printPlsigexp argSig
val _ = U.print "\n"
        val 
        {
         argSig=argSig,
         argEnv=argEnv,
         extraTvars=extraTvars,
         polyArgPats=polyArgPats,
         exnTagDecls=exnTagDecls,
         dummyIdfunArgTy=dummyIdfunArgTy,
         firstArgPat=firstArgPat,
         tfvDecls = tfvDecls
        } = FunctorUtils.evalFunArg (topEnv, argSig, loc)

val _ = U.print "argSig in nameeval\n"
val _ = U.printEnv argSig
val _ = U.print "\n"
val _ = U.print "extraTvars in nameeval\n"
val _ = map U.printTvar extraTvars
val _ = U.print "\n"

        val topArgEnv = V.ENV {varE=SEnv.empty,
                            tyE=SEnv.empty,
                            strE=V.STR (SEnv.singleton(argStrName, argEnv))
                            }
        val evalEnv = V.topEnvWithEnv (topEnv, topArgEnv)

        val startTypid = TypID.generate()

        val (returnEnv, bodyDecls) = evalPlstrexp evalEnv nilPath body

        val
        {
         allVars = allVars,
         typidSet = typidSet,
         exnIdSet = exnIdSet
        } = FunctorUtils.makeBodyEnv returnEnv loc
  
        val allVars = map #2 allVars
val _ = U.print "allVars************\n"
val _ = map (fn x => (U.printExp x; U.print "\n")) allVars
val _ = U.print "\n"

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
                (polyArgPats,
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
        val functorDecl =
            I.ICVAL(map (fn tvar=>(tvar, IT.UNIV)) extraTvars,
                    [(I.ICPATVAR(functorExpVar, loc),functorExp)],
                    loc)
        val funEEntry:V.funEEntry =
            {argSig = argSig,
             argEnv = argEnv,
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

  fun evalPltopdec topEnv pltopdec =
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
                      evalFunctor topEnv functordecl
                  val returnTopEnv =
                      V.topEnvWithTopEnv(returnTopEnv, topEnv1)
                in
                  (returnTopEnv, icdecList@icdecList1)
                end
            )
            (V.emptyTopEnv, nil)
            functordeclList
        end

  fun evalPltopdecList topEnv pltopdecList =
      foldl
        (fn (pltopdec, (returnTopEnv, icdecList)) =>
          let
            val evalTopEnv = V.topEnvWithTopEnv (topEnv, returnTopEnv)
            val (returnTopEnv1, icdecList1) =
                evalPltopdec evalTopEnv pltopdec
            val returnTopEnv = V.topEnvWithTopEnv(returnTopEnv, returnTopEnv1)
          in
            (returnTopEnv, icdecList @ icdecList1)
          end
        )
        (V.emptyTopEnv, nil)
        pltopdecList

in (* local *)

  fun nameEval topEnv ({interface={decls,requires,topdecs=provideDecs,...},
                        topdecs}:PI.compileUnit) =
      let

val _ = U.print "nameEval main\n"

        val _ = EU.initializeErrorQueue()
        val loc = 
            case topdecs of
              nil => Loc.noloc
            | dec::_ => (#1 (P.getLocTopDec dec),
                         #2 (P.getLocTopDec (List.last topdecs)))
        val interfaceEnv = EI.evalInterfaces topEnv decls
        val (evalTopEnv, interfaceDecls) =
            foldl
            (fn ({id,loc}, (evalTopEnv, icdecls)) =>
                case InterfaceID.Map.find(interfaceEnv, id) of
                  SOME {topEnv, decls=newDecls,...} => 
                  let
                    val evalTopEnv =
                        V.unionTopEnv "205" loc (evalTopEnv, topEnv)
                  in
                    (evalTopEnv, icdecls @ newDecls)
                  end
                | NONE => raise bug "unbound interface id"
            )
            (topEnv, nil)
            requires

        val (returnTopEnv, topdecList) =
            evalPltopdecList evalTopEnv topdecs
            handle e => raise e

val _ = U.print "returnTopEnv\n"
val _ = U.printTopEnv returnTopEnv
val _ = U.print "\n"
val _ = U.print "topdecList\n"
val _ = map (fn decl => (U.printDecl decl; U.print "\n")) topdecList
val _ = U.print "\n"


val _ = U.print "provideDecs\n"
val _ = map (fn decl => (U.printPitopdec decl; U.print "\n")) provideDecs
val _ = U.print "\n"

(*
        (* the following is for errorcheimg provideDecs *)
        val (tempTopEnv,_) = EI.evalPitopdecList evalTopEnv provideDecs
*)
        val exportList =
          if EU.isAnyError () then nil
          else
            let
              val (_, _, exportList) =
                    CP.checkPitopdecList
                      ExnID.Set.empty
                      evalTopEnv (returnTopEnv, provideDecs)
            in
              exportList
            end
            handle e => raise e

val _ = U.print "exportList\n"
val _ = map (fn decl => (U.printDecl decl; U.print "\n")) exportList
val _ = U.print "\n"

        val topdecs = interfaceDecls @ topdecList @ exportList
      in
        case EU.getErrors () of
          [] => (topdecs, EU.getWarnings())
        | errors => raise UserError.UserErrors (EU.getErrorsAndWarnings ())
      end
      handle exn => raise exn

  fun evalBuiltin topdecList =
      let
        fun varEToPrimConExnEnv varE =
            SEnv.foldli
            (fn (name, idstate, (primEnv, conEnv, exnEnv)) =>
                case idstate of 
                  IT.IDVAR varId => (primEnv, conEnv, exnEnv)
                | IT.IDEXVAR {path, ty} => (primEnv, conEnv, exnEnv)
                | IT.IDBUILTINVAR {primitive, ty} =>
                  (SEnv.insert(primEnv,
                               name,
                               {primitive=primitive,
                                ty= ITy.evalIty EI.emptyContext ty}),
                   conEnv, exnEnv) 
                | IT.IDCON {id, ty} =>
                  (primEnv,
                   SEnv.insert(conEnv,
                               name,
                               {path=[name],
                                id=id,
                                ty= ITy.evalIty EI.emptyContext ty}
                              ),
                   exnEnv
                  )
                | IT.IDEXN {id, ty} => (primEnv, conEnv, exnEnv)
                | IT.IDEXNREP {id, ty} => (primEnv, conEnv, exnEnv)
                | IT.IDEXEXN {path, ty} =>
                  (primEnv, conEnv,
                   SEnv.insert (exnEnv, name,
                                {path=path, ty=ITy.evalIty EI.emptyContext ty}))
                | IT.IDOPRIM oprimId => (primEnv, conEnv, exnEnv)
                | IT.IDSPECVAR ty => raise bug "IDSPECVAR in evalBuiltin"
                | IT.IDSPECEXN ty => raise bug "IDSPECEXN in evalBuiltin"
                | IT.IDSPECCON => raise bug "IDSPECCON in evalBuiltin"
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
                      | _ => raise bug "non dty tfun in Interface TyE"
                  val tyCon = ITy.evalTfun EI.emptyContext [name] tfun
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
              val strEnv = SEnv.map envToBuiltinEnv envMap
            in
              BuiltinName.ENV
                {env = {tyConEnv = tyConEnv,
                        primEnv = primEnv,
                        conEnv = conEnv,
                        exnEnv = exnEnv},
                 strEnv = strEnv}
            end
        val _ = EU.initializeErrorQueue()
        val (topEnv as {Env, FunE, SigE}, icdecls) =
            EI.evalPitopdecList V.emptyTopEnv topdecList
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

end
end
