(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : Sig-001 *)
structure EvalSig  :
sig
  val refreshSpecEnv : NameEvalEnv.env -> Subst.tfvSubst * NameEvalEnv.env
  val evalPlsig : NameEvalEnv.topEnv -> PatternCalc.plsigexp -> NameEvalEnv.env
end
=
struct
local
  structure I = IDCalc
  structure TF = TfunVars
  structure TFR = TfunVarsRefresh
  structure V = NameEvalEnv
  structure BT = BuiltinTypes
  structure L = SetLiftedTys
  structure Ty = EvalTy
  structure S = Subst
  structure P = PatternCalc
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = Absyn
  structure N = NormalizeTy
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
  fun bug s = Bug.Bug ("NameEval: " ^ s)

  val symbolToString = Symbol.symbolToString
  val symbolToLoc = Symbol.symbolToLoc
  val longsymbolToLongid = Symbol.longsymbolToLongid
  val longsymbolToLoc = Symbol.longsymbolToLoc
  val mkSymbol = Symbol.mkSymbol
  val mkLongsymbol = Symbol.mkLongsymbol
  
 (* the following three functions are copied from IDTypes
    and slightly changed to fix the bug 152
  *)
  fun tfunkindId tfunkind = 
      (case tfunkind of
        I.TFV_SPEC {id,...} => id
      | I.TFV_DTY {id,...} => id
      | I.TFUN_DTY {id,...} => id
      | I.REALIZED {id,...}  => id
      | I.INSTANTIATED {tfunkind,...} => tfunkindId tfunkind
      | I.FUN_DTY {tfun,...} => tfunId tfun
      )
      handle exn => raise  exn

  and tfvId tfv =
      case !tfv of
        I.TFV_SPEC {id,...} => id
      | I.TFV_DTY {id,...} => id
      | I.TFUN_DTY {id,...} => id
      | (* raise bug "tfvid: ReALIZED" 
           This case is needed for multiple sharing constraint 
           processing
         *)
         I.REALIZED {tfun,...} => tfunId tfun
      | I.INSTANTIATED {tfun,...} => tfunId tfun
      | I.FUN_DTY {tfun,...} => raise bug "FUN_DTY"

  and tfunId tfun =
      case tfun of 
        I.TFUN_DEF _ => raise bug "TFUN_DEF to TFUNID"
      | I.TFUN_VAR tfv => (tfvId tfv handle exn => raise exn)

  fun refreshSpecEnv path specEnv : S.tfvSubst * V.env =
  (* 2013-3-3 ohori: path parameter added to fix the bug 252_sigPath.sml *)
    let
      val tfvMap = TFR.tfvsEnv TFR.sigTfvKind nil (specEnv, TfvMap.empty)
      fun printTfvSubst tfvSubst =
          (TfvMap.appi
             (fn (tfv1,tfv2) =>
                 (U.printTfun (I.TFUN_VAR tfv1);
                  U.print "=>";
                  U.printTfun (I.TFUN_VAR tfv2);
                  U.print "\n"
                 )
             )
             tfvSubst
          )
          handle exn => raise exn
      fun printTfvMap tfvMap =
          (TfvMap.appi
             (fn (tfv1,path) =>
                 (U.printTfun (I.TFUN_VAR tfv1);
                  U.print "=>";
                  U.printLongsymbol path;
                  U.print "\n"
                 )
             )
             tfvMap
          )
          handle exn => raise exn
      val tfvSubst = 
          TfvMap.foldri
          (fn (tfv as ref (I.TFV_SPEC {longsymbol, iseq, formals,...}), _, tfvSubst) =>
              let
                val longsymbol =  path @ longsymbol
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_SPEC{longsymbol=longsymbol, id=id,iseq=iseq,formals=formals})
              in 
                TfvMap.insert(tfvSubst, tfv, newTfv)
              end
            | (tfv as ref (I.TFV_DTY {longsymbol, iseq,formals,conSpec,liftedTys,...}), _,
               tfvSubst) =>
              let
                val longsymbol = path @ longsymbol
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_DTY{id=id,
                                       longsymbol=longsymbol,
                                       iseq=iseq,
                                       conSpec=conSpec,
                                       liftedTys=liftedTys,
                                       formals=formals}
                          )
              in 
                TfvMap.insert(tfvSubst, tfv, newTfv)
              end
            | (tfv, _, _) => 
              (U.print "\nnon tfv (1)\n";
               U.printTfv tfv;
               U.print "\n";
               printTfvMap tfvMap;
               U.print "\n";
               raise bug "non tfv (1)"
              )
          )
          TfvMap.empty
          tfvMap
          handle exn => raise exn
      val _ =
          TfvMap.app
          (fn (tfv as ref (I.TFV_DTY {longsymbol, iseq,formals,conSpec,liftedTys,id})) =>
              let
                val conSpec =
                    SymbolEnv.map
                    (fn tyOpt =>
                        Option.map (S.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFV_DTY
                      {iseq=iseq,
                       longsymbol=longsymbol,
                       formals=formals,
                       conSpec=conSpec,
                       liftedTys=liftedTys,
                       id=id}
              end
            | _ => ())
          tfvSubst
          handle exn => raise exn
      val env =S.substTfvEnv tfvSubst specEnv
    in
      (tfvSubst, env)
    end
    handle exn => raise bug "uncaught exception in refreshSpecEnv"

  fun processShare (specEnv, longsymbolListList, loc) = 
      let
        (* sig
             datatype foo = A of int -> int
             eqtype bar
           end
           sharing type foo = bar
           will be rejected.
        *) 
        fun processShareList typIdEquiv (specEnv,pathTfvList,loc) = 
            let
              val pathTypIdDtyTfvList = 
                  foldr
                    (fn ((path, tfv as (ref (I.TFV_DTY{id,...}))), pathTypIdDtyTfvList) =>
                        (path, id, tfv)::pathTypIdDtyTfvList
                      | (_,pathTypIdDtyTfvList) => pathTypIdDtyTfvList)
                    nil
                    pathTfvList
              fun getArityTfv tfv =
                  case !tfv of
                    I.TFV_SPEC {formals, ...} => List.length formals
                  | I.TFV_DTY {formals, ...} => List.length formals
                  | I.REALIZED {id, tfun} => I.tfunArity tfun  (* bug 173_sharing.smk *)
                  | _ => raise bug "non tfv (2)"
              fun checkEqtypeTfv tfv =
                  case !tfv of 
                    I.TFV_SPEC {iseq,...} => iseq
                  | I.TFV_DTY _ => false
                  | I.REALIZED {id, tfun} => I.tfunIseq tfun (* bug 173_sharing.smk *)
                  | _ => raise bug "impossible"
              fun checkEqtypeTfvList nil = false
                | checkEqtypeTfvList (h::t) = 
                  checkEqtypeTfv h orelse checkEqtypeTfvList t
              val _ = case pathTfvList of nil => raise ProcessShare | _ => ()
              val (longsymbolList, tfvList) = ListPair.unzip pathTfvList
              val arityList = map getArityTfv tfvList
              val _ =
                  case arityList of
                    nil => ()
                  | [h] => ()
                  | h::t =>
                    if List.all (fn x => x = h) t then ()
                    else (EU.enqueueError
                            (loc,
                             E.ArityErrorInSigShare("Sig-030",
                                                    {longsymbolList=longsymbolList}));
                          raise ProcessShare)
              val isEqtype = checkEqtypeTfvList tfvList
              val _ =
                  if isEqtype then
                    case pathTypIdDtyTfvList of
                      nil => ()
                    | (_, _, ref (I.TFV_DTY{iseq, ...}))::_ => 
                      if iseq then ()
                      else
                        (EU.enqueueError
                           (loc, E.EqtypeInSigShare("Sig-040",
                                                    {longsymbolList=longsymbolList}));
                         raise ProcessShare)
                    | _ => raise bug "impossible"
                  else ()
              val errorPathList =
                  case pathTypIdDtyTfvList of
                    nil => nil
                  | [_] => nil
                  | (path, _, ref (I.TFV_DTY {formals, conSpec, ...})) :: rest =>
                    foldl
                      (fn ((path2, _,
                            (ref(I.TFV_DTY{formals=formals2,conSpec=conSpec2,...}))),
                           errorPathList) =>
                          let
                            val result =
                                N.checkConSpec 
                                  typIdEquiv ((formals,conSpec), (formals2,conSpec2))
                          in
                            case result of
                              N.SUCCESS => errorPathList
                            | N.FAIL _ => errorPathList @ [path2]
                          end
                        | _ => raise bug "non tfv (3)"
                      )
                      nil
                      rest
                  | _ => raise bug "non tfv (4)"
              val _ =
                  case errorPathList of
                    nil => ()
                  | _ => 
                    (EU.enqueueError
                       (loc, E.SigErrorInSigShare("Sig-050",
                                                  {longsymbolList=errorPathList}));
                     raise ProcessShare)
              val firstTfv =
                  case pathTypIdDtyTfvList of
                    nil => 
                    (case pathTfvList of
                       nil => raise bug "no share list2"
                     | (path,tfv)::tl => tfv
                    )
                  | (path, id, tfv)::rest => tfv
              val firstId = tfvId firstTfv handle exn => raise exn
              val _ = 
                  app (fn (path,tfv) =>
                          let
                            val id = tfvId tfv  handle exn => raise exn
                          in
                            if TypID.eq(id, firstId) then ()
                            else tfv:=I.REALIZED {id=id, tfun=I.TFUN_VAR firstTfv}
                          end
                      )
                      pathTfvList
            in
              ()
            end
      
        fun getTfvTfun tfun =
            case tfun of 
              I.TFUN_DEF _ => raise Rigid
            | I.TFUN_VAR (tfv as (ref tfunkind)) => 
              (case tfunkind of
                 I.REALIZED {id, tfun} => getTfvTfun tfun
               | I.TFV_SPEC {id,...} => (id, tfv)
               | I.TFV_DTY {id,...} => (id, tfv)
               | I.TFUN_DTY _ => raise Rigid
               | I.INSTANTIATED _ =>  raise bug "INSTANTIATED in spec"
               | I.FUN_DTY _ => raise bug "FUN_DTY in spec"
              )
        fun getTfv longsymbol =
            case V.findTstr (specEnv, longsymbol) of
              NONE => raise Undef
            | SOME tstr => 
              (case tstr of
                 V.TSTR tfun => getTfvTfun tfun
               | V.TSTR_DTY{tfun,...} => getTfvTfun tfun
              )
        val (pathTfvListList, idListList) =
            foldr
              (fn (longsymbolList, (pathTfvListList, idListList)) =>
                  let
                    val (pathTfvList, idList) =
                        foldr
                          (fn (longsymbol, (pathTfvList, idList)) =>
                              let
                                val (id, tfv) = getTfv longsymbol
                                    handle
                                    Rigid =>
                                    (EU.enqueueError
                                       (loc, E.ImproperSigshare("Sig-010",{longsymbol=longsymbol}));
                                     raise ProcessShare)
                                  | Undef =>
                                    (EU.enqueueError
                                       (loc,
                                        E.TypUndefinedInSigshare("Sig-020",{longsymbol=longsymbol}));
                                     raise ProcessShare)
                              in
                                ((longsymbol,tfv)::pathTfvList, id::idList)
                              end
                          )
                          (nil,nil)
                          longsymbolList
                  in
                    (pathTfvList::pathTfvListList, idList::idListList)
                  end
              )
            (nil, nil)
            longsymbolListList
        val typIdEquiv = N.makeTypIdEquiv idListList
      in
        app 
          (fn pathTfvList => processShareList typIdEquiv (specEnv, pathTfvList, loc))
          pathTfvListList
      end
      handle ProcessShare  => ()

  fun evalSig (topEnv:V.topEnv) path plsigexp : V.env =
      case plsigexp of
        P.PLSIGEXPBASIC (plspec, loc) => evalPlspec topEnv path plspec
      | P.PLSIGID symbol =>
        (case V.findSigETopEnv(topEnv, symbol) of
           NONE => (EU.enqueueError
                      (symbolToLoc symbol,
                       E.SigIdUndefined("Sig-060", {symbol = symbol}));
                    V.emptyEnv
                   )
         | SOME specEnv => #2 (refreshSpecEnv path specEnv)
        )
      | P.PLSIGWHERE (plsigexp, typbind, loc) =>
        let
          val specEnv = evalSig topEnv path plsigexp
          val freeTfvs = TF.tfvsEnv TF.sigTfvKind nil (specEnv, TfvMap.empty)
          fun setRealizer ((tyvarList, longsymbol, ty), returnEnv) =
              let
                val _ = EU.checkSymbolDuplication
                          (fn {symbol, eq} => symbol)
                          tyvarList
                          (fn s => E.DuplicateTypParms("Sig-070",s))
                val (tvarEnv, tvarList) =
                    Ty.genTvarList Ty.emptyTvarEnv tyvarList
                fun strPath nil = nil
                  | strPath [name] = nil
                  | strPath (h::t) = h::(strPath t)
                val realizeePath = strPath longsymbol
                val realizerPath =
                      case ty of
                        A.TYCONSTRUCT (tyList, path, loc) => 
                        strPath path
                      | _ => nil
                  val ty = Ty.evalTy tvarEnv (#Env topEnv) ty
  
                  fun getTfunTfun tfun =
                      case tfun of
                        I.TFUN_DEF _ => tfun
                      | I.TFUN_VAR (ref tfunkind) =>
                        (case tfunkind of 
                           I.TFV_SPEC _ => tfun
                         | I.TFV_DTY _ => tfun
                         | I.TFUN_DTY _ => tfun
                         | I.REALIZED {tfun,...} => getTfunTfun tfun
                         | I.INSTANTIATED {tfun,...} => getTfunTfun tfun
                         | I.FUN_DTY _ => raise bug "FUN_DTY in sig"
                        )
                  val realizeeTstr = 
                      case V.findTstr (specEnv, longsymbol) of
                        SOME tstr => tstr
                      | NONE => raise Undef
                  val realizerTfun =
                      case N.tyForm tvarList ty of
                        N.TYNAME tfun => getTfunTfun tfun
                      | N.TYTERM ty =>
                        I.TFUN_DEF {iseq=N.admitEq tvarList ty,
                                    longsymbol=longsymbol,
                                     (* eq attrib of extras is inherited
                                                            from its decl. *)
                                    formals=tvarList,
                                    realizerTy=ty
                                   }
                  val realizerVarE =
                      case realizeeTstr of
                        V.TSTR _ => SymbolEnv.empty
                      | V.TSTR_DTY _=> 
                        (case I.derefTfun realizerTfun of
                           I.TFUN_VAR(ref (I.TFUN_DTY {conSpec,...})) =>
                           SymbolEnv.foldri
                             (fn (name, _, varE) =>
                                 case V.findId((#Env topEnv),
                                               realizerPath@[name]) of
                                   SOME idstatus =>
                                   SymbolEnv.insert(varE, name,idstatus)
                                 | _ =>
                                   (U.print "setRealizer\n";
                                    U.print "realizerTfun\n";
                                    U.printTfun realizerTfun;
                                    U.print "\n";
                                    U.print "con name\n";
                                    U.printSymbol name;
                                    U.print "\n";
                                    raise bug "realizer Con not found 1"
                                   )
                             )
                             SymbolEnv.empty
                             conSpec
                         | _ => SymbolEnv.empty
                        )
                  fun getTfvTfun tfun =
                      case tfun of 
                        I.TFUN_DEF _ => raise Rigid
                      | I.TFUN_VAR (tfv as ref tfunkind) =>
                        (case tfunkind of 
                           I.TFV_SPEC _ => (tfv, tfunkind)
                         | I.TFV_DTY _ => (tfv, tfunkind)
                         | I.TFUN_DTY _ => raise Rigid
                         | I.REALIZED {tfun,...} => getTfvTfun tfun
                         | I.INSTANTIATED _ => raise bug "INSTANTIATED"
                         | I.FUN_DTY _ => raise bug "FUN_DTY"
                        )
                  fun getTfvTstr tstr = 
                      case tstr of
                        V.TSTR tfun => getTfvTfun tfun
                      | V.TSTR_DTY {tfun,...} => getTfvTfun tfun
                  val realizerArity = I.tfunArity realizerTfun
                  val realizeeArity = V.tstrArity realizeeTstr
                  val _ = if realizeeArity = realizerArity then ()
                          else raise Arity
                  val (tfv, tfunkind) = getTfvTstr realizeeTstr
                  val _ = if TfvMap.inDomain(freeTfvs, tfv) then ()
                          else raise Rigid
                  val _ =
                  case tfunkind of
                    I.TFV_SPEC {iseq=eq1,...} =>
                    (
                     case realizerTfun of
                       I.TFUN_DEF {iseq=eq2,...} =>
                       if eq1 andalso not eq2 then raise Eq
                       else tfv := 
                                 let
                                   val id = tfvId tfv  handle exn => raise exn
                                 in
                                   I.REALIZED {id=id, tfun=realizerTfun}
                                 end
                     | I.TFUN_VAR
                         (ref (I.TFV_SPEC {longsymbol,id=id2,iseq=eq2,formals})) =>
                       tfv := I.REALIZED {id=id2, tfun=realizerTfun}
                     | I.TFUN_VAR (ref (I.TFV_DTY {iseq=eq2,...})) =>
                       if eq1 andalso not eq2 then raise Eq
                       else tfv :=
                                 let
                                   val id = tfvId tfv  handle exn => raise exn
                                 in
                                   I.REALIZED {id=id, tfun=realizerTfun}
                                 end
                     | I.TFUN_VAR(ref (I.TFUN_DTY {iseq=eq2,...})) =>
                       if eq1 andalso not eq2 then raise Eq
                       else tfv :=
                                 let
                                   val id = tfvId tfv  handle exn => raise exn
                                 in
                                   I.REALIZED {id=id, tfun=realizerTfun}
                                 end
                     | I.TFUN_VAR (ref (I.REALIZED _)) => raise bug "REALIZED"
                     | I.TFUN_VAR (ref (I.INSTANTIATED _)) =>
                       raise bug "INSTANTIATED"
                     | I.TFUN_VAR (ref (I.FUN_DTY _)) => raise bug "FUN_DTY"
                    )
                  | I.TFV_DTY {id=id1, iseq=eq1, formals, conSpec,...} => 
                    (case realizerTfun of
                       I.TFUN_DEF _ => raise Type1
                     | I.TFUN_VAR (tfv2 as ref(I.TFV_SPEC {iseq=eq2,...}))=>
                       if eq2 andalso not eq1 then raise Eq
                       else tfv2 :=
                                 let
                                   val id = tfvId tfv  handle exn => raise exn
                                 in
                                   I.REALIZED {id=id, tfun=I.TFUN_VAR tfv}
                                 end
                     | I.TFUN_VAR (ref (I.TFV_DTY {id=id2,
                                                   formals=formals2,
                                                   conSpec=conSpec2,...})) =>
                       let
                         val typIdEquiv = N.makeTypIdEquiv [[id1,id2]]
                         val _ =
                           tfv :=
                                 let
                                   val id = tfvId tfv  handle exn => raise exn
                                 in
                                   I.REALIZED {id=id, tfun=realizerTfun}
                                 end
                         val result = N.checkConSpec 
                                        typIdEquiv
                                        ((formals, conSpec), (formals2, conSpec2))
                       in
                         case result of
                           N.SUCCESS => ()
                         | _ => raise Type2
                       end
                     | I.TFUN_VAR (ref (I.TFUN_DTY {id=id2,
                                                    formals=formals2,
                                                    conSpec=conSpec2,...})) =>
                       let
                         val typIdEquiv = N.makeTypIdEquiv [[id1,id2]]
                         val _ =
                             tfv :=
                                  let
                                    val id = tfvId tfv  handle exn => raise exn
                                  in
                                    I.REALIZED {id=id, tfun=realizerTfun}
                                  end
                         val result = N.checkConSpec 
                                        typIdEquiv
                                        ((formals, conSpec), (formals2, conSpec2))
                       in
                         case result of
                           N.SUCCESS => ()
                         | _ => raise Type3
                       end
  
                     | I.TFUN_VAR (ref (I.REALIZED _)) => raise bug "REALIZED"
                     | I.TFUN_VAR (ref (I.INSTANTIATED _)) =>
                       raise bug "INSTANTIATEDE"
                     | I.TFUN_VAR (ref (I.FUN_DTY _)) => raise bug "FUN_DTY"
                    )
                  | I.TFUN_DTY _ => raise bug "TFUN_DTY in setRealizer"
                  | I.REALIZED _ => raise bug "REALIZED"
                  | I.INSTANTIATED _ => raise bug "INSTANTIATEd"
                  | I.FUN_DTY _ => raise bug "FUN_DTY"
                in
                  case (realizeeTstr, realizerTfun) of
                    (V.TSTR_DTY {varE, tfun,...},
                     (I.TFUN_VAR(ref (I.TFUN_DTY {formals, conSpec,...})))) =>
                    let
                      val returnEnv = 
                          SymbolEnv.foldri
                            (fn (name, _, returnEnv) =>
                                case V.findId((#Env topEnv),
                                              realizerPath@[name]) of
                                  SOME idstatus =>
                                  V.rebindIdLongsymbol
                                    (returnEnv, realizeePath@[name], idstatus)
                                | _ =>
                                  (U.print "setRealizer\n";
                                   U.print "realizeeTstr\n";
                                   U.printTstr realizeeTstr;
                                   U.print "\n";
                                   U.print "realizerTfun\n";
                                   U.printTfun realizerTfun;
                                   U.print "\n";
                                  raise bug "realizer Con not found 2"
                                  )
                            )
                            returnEnv
                            varE
                    in
                      V.rebindTstrLongsymbol(returnEnv,
                                             longsymbol,
                                             V.TSTR_DTY{tfun=tfun,
                                                        varE=realizerVarE,
                                                        formals=formals,
                                                        conSpec=conSpec}
                                            )
                    end
                  | _ => returnEnv
                end
                handle
                Rigid =>
                (EU.enqueueError
                   (loc, E.ImproperSigwhere("Sig-080",{longsymbol=longsymbol}));
                 specEnv)
              | Type =>
                (EU.enqueueError
                   (loc,E.TypeErrorInSigwhere("Sig-090",{longsymbol=longsymbol}));
                 specEnv)
              | Type1 =>
                (EU.enqueueError
                   (loc,E.TypeErrorInSigwhere("Sig-100",
                                              {longsymbol=longsymbol}));
                 specEnv)
              | Type2 =>
                (EU.enqueueError
                   (loc,E.TypeErrorInSigwhere("Sig-110",
                                              {longsymbol=longsymbol}));
                 specEnv)
              | Type3 =>
                (EU.enqueueError
                   (loc,E.TypeErrorInSigwhere("Sig-120",
                                              {longsymbol=longsymbol}));
                 specEnv)
              | Eq =>
                (EU.enqueueError
                   (loc, E.EqtypeInSigwhere("Sig-130",{longsymbol=longsymbol}));
                 specEnv)
              | Arity =>
                (EU.enqueueError
                   (loc, E.ArityErrorInSigwhere("Sig-140",
                                                {longsymbolList=[longsymbol]}));
                 specEnv)
              | Undef =>
                (EU.enqueueError
                   (loc, E.TypUndefinedInSigwhere("Sig-150",{longsymbol=longsymbol}));
                 specEnv)
            val specEnv = setRealizer (typbind, specEnv)
        in
          specEnv
        end

  and evalPlspec (topEnv as {Env=env, FunE, SigE}) path plspec : V.env =
      case plspec of
        (* val x : ty and y : ty ... *)
        P.PLSPECVAL (scopedTvars, symbol, ty, loc) =>
        let
          val (tvarEnv, kindedTyars) =
              Ty.evalScopedTvars Ty.emptyTvarEnv env scopedTvars
          val ty = Ty.evalTy tvarEnv env ty
          val ty = 
              case kindedTyars of
                nil => ty
              | _ => I.TYPOLY(kindedTyars,ty)
          val specEnv = V.insertId (V.emptyEnv, symbol, I.IDSPECVAR {ty=ty, symbol=symbol})
        in
          specEnv
        end

      | P.PLSPECTYPE {tydecls=tvarListStringList, iseq, loc} =>
      (* type 'a foo and ...*)
        let
          val specEnv =
              foldl
                (fn ((tvarList, symbol), specEnv) =>
                    let
                      val _ = EU.checkSymbolDuplication
                                (fn {symbol, eq} => symbol)
                                tvarList
                                (fn s => E.DuplicateTypParms("Sig-160",s))
                      val (_, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tvarList
                      val id = TypID.generate()
                      val longsymbol = path @ [symbol]
                      val tfunvar =
                          I.mkTfv (I.TFV_SPEC{longsymbol=longsymbol, 
                                              id=id,iseq=iseq, 
                                              formals=tvarList})
                      val tfun = I.TFUN_VAR tfunvar
                      val specEnv =
                          V.bindTstr (specEnv,symbol,V.TSTR tfun)
                    in
                      specEnv
                    end
                )
                V.emptyEnv
                tvarListStringList
        in
          specEnv
        end

      (* type 'a foo = 'a * 'a *)
      | P.PLSPECTYPEEQUATION ((tvarList, symbol, ty), loc) =>
        let
          val longsymbol = [symbol]
          val _ = EU.checkSymbolDuplication
                    (fn {symbol, eq} => symbol)
                    tvarList
                    (fn s => E.DuplicateTypParms("Sig-170",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tvarList
          val ty = Ty.evalTy tvarEnv env ty
          val iseq = N.admitEq tvarList ty
          val formals = tvarList
          val tfun =
              case N.tyForm formals ty of
                N.TYNAME tfun => tfun
              | N.TYTERM ty =>
                I.TFUN_DEF {longsymbol=longsymbol,iseq=iseq,formals=formals,realizerTy=ty}
        in
          V.bindTstr (V.emptyEnv, symbol, V.TSTR tfun)
        end

      | P.PLSPECDATATYPE (datadeclList, loc) =>
      (* datatype 'a foo = A of ... *)
        let
          val _ = EU.checkSymbolDuplication
                    (fn (tvarList, symbol, conbinds) => symbol)
                    datadeclList
                    (fn s => E.DuplicateTypInDty("Sig-180",s))
          val _ = EU.checkSymbolDuplication
                    (fn (symbol, tyOption) => symbol)
                    (foldl
                       (fn ((tvarList, string, conbinds), allCons) =>
                           allCons@conbinds)
                       nil
                       datadeclList)
                    (fn s => E.DuplicateConNameInDty("Sig-190",s))
          val (specEnv, datadeclListRev) =
              foldl
                (fn ((tvarList,symbol,conbinds), (specEnv, datadeclListRev)) =>
                    let
                      val _ = EU.checkSymbolDuplication
                                (fn {symbol, eq} => symbol)
                                tvarList
                                (fn s => E.DuplicateTypParms("Sig-200", s))
                      val (tvarEnv, tvarList)=
                          Ty.genTvarList Ty.emptyTvarEnv tvarList
                      val id = TypID.generate()
                      val iseqRef = ref true
                      val longsymbol = Symbol.prefixPath(path , symbol)
                      val tfv =
                          I.mkTfv(I.TFV_DTY{id=id,
                                            longsymbol=longsymbol,
                                            iseq=true,
                                            formals=tvarList,
                                            conSpec=SymbolEnv.empty,
                                            liftedTys=I.emptyLiftedTys
                                           }
                               )
                      val tfun = I.TFUN_VAR tfv
                      val specEnv =
                          V.insertTstr (specEnv, symbol,V.TSTR tfun)
                      val datadeclListRev =
                          {name=symbol,
                           longsymbol=longsymbol,
                           id=id,
                           tfv=tfv,
                           tfun=tfun,
                           iseqRef=iseqRef,
                           args=tvarList,
                           conbinds = conbinds,
                           tvarEnv=tvarEnv
                          } :: datadeclListRev
                    in
                      (specEnv, datadeclListRev)
                    end
                )
                (V.emptyEnv, nil)
                datadeclList
          val evalEnv = V.envWithEnv (env, specEnv)
          val datadeclList =
              foldl
                (fn ({name, longsymbol, id, tfv, tfun, iseqRef, args, tvarEnv, conbinds},
                     datadeclList) =>
                    let
                      val (conVarE, conSpec) =
                          foldl
                            (fn ((symbol, tyOption), (conVarE, conSpec)) =>
                                let
                                  val tyOption =
                                      case tyOption of
                                        NONE => NONE
                                      | SOME ty => 
                                        let
                                          val ty = Ty.evalTy tvarEnv evalEnv ty
                                        in
                                          SOME ty
                                        end
                                in
                                  (SymbolEnv.insert(conVarE, symbol, I.IDSPECCON {symbol=symbol}),
                                   SymbolEnv.insert(conSpec, symbol, tyOption)
                                  )
                                end
                            )
                            (SymbolEnv.empty, SymbolEnv.empty)
                            conbinds
                    in
                      {name=name,
                       longsymbol=longsymbol,
                       id=id,
                       tfv=tfv,
                       conVarE=conVarE,
                       conSpec=conSpec,
                       iseqRef=iseqRef,
                       conbinds=conbinds,
                       args=args
                      } :: datadeclList
                    end
                )
                nil
                datadeclListRev
          val _ = N.setEq
                  (map 
                     (fn {id, args, conSpec, iseqRef,...} =>
                         {id=id, args=args, conSpec=conSpec, iseqRef=iseqRef})
                     datadeclList
                  )
          val (specEnv, nameListRev) =
              foldl
                (fn ({name,longsymbol, id,tfv,conVarE,conSpec,iseqRef,args,conbinds},
                     (specEnv, nameListRev)) =>
                    let
                      val _ =
                          tfv :=
                               I.TFV_DTY
                                 {id=id,
                                  longsymbol=longsymbol,
                                  iseq = !iseqRef,
                                  conSpec=conSpec,
                                  formals=args,
                                  liftedTys=I.emptyLiftedTys
                                 }
                      val tfun = I.TFUN_VAR tfv
                      val specEnv =
                          V.bindTstr
                            (specEnv,
                             name,
                             V.TSTR_DTY{tfun=tfun,
                                        varE=conVarE,
                                        formals=args,
                                        conSpec=conSpec}
                            )
                      val specEnv = V.bindEnvWithVarE (specEnv, conVarE)
                    in
                      (specEnv, name::nameListRev)
                    end
                )
                (V.emptyEnv, nil)
                datadeclList
        in
          specEnv
        end

      (* datatype foo = datatype bar *)
      | P.PLSPECREPLIC (symbol, longsymbol, loc) =>
        (case V.findTstr (env, longsymbol) of
           NONE =>
           (EU.enqueueError(loc,E.DtyUndefinedInSpec
                                  ("Sig-210", {longsymbol = longsymbol}));
            V.emptyEnv
           )
         | SOME tstr =>
           (case tstr of
              V.TSTR tfun => V.bindTstr (V.emptyEnv, symbol, tstr)
            | V.TSTR_DTY {tfun, varE, formals, conSpec} =>
              let
                val specEnv = V.bindTstr (V.emptyEnv, symbol, tstr)
                val varE = V.replaceLocVarE loc varE
                val specEnv = V.bindEnvWithVarE(specEnv, varE)
              in
                specEnv
              end
           )
        )

      (* exception foo of 'a ... *)
      | P.PLSPECEXCEPTION (symbolTyOptionList, loc) =>
        let
          val specEnv =
              foldl
                (fn ((symbol, tyOption), specEnv) =>
                    let
                      val ty =
                          case tyOption of
                            NONE => BT.exnITy
                          | SOME ty => 
                            I.TYFUNM([Ty.evalTy Ty.emptyTvarEnv env ty],
                                     BT.exnITy)
                    in
                      V.bindId (specEnv, symbol, I.IDSPECEXN {ty=ty, symbol=symbol})
                    end
                )
                V.emptyEnv
                symbolTyOptionList
        in
          specEnv
        end

      (* structure A : sig and ... *)
      | P.PLSPECSTRUCT (symbolPlsigexpList, loc) =>
        let
          val specEnv =
              foldl
                (fn ((symbol, sigexp), specEnv) =>
                    let
                      val strSpecEnv = evalSig topEnv (path@[symbol]) sigexp
                      val specEnv =
                          V.bindStr (specEnv, symbol, {env=strSpecEnv, strKind=V.SIGENV})
                    in
                      specEnv
                    end
                )
                V.emptyEnv
                symbolPlsigexpList
        in
          specEnv
        end

      (* include A *)
      | P.PLSPECINCLUDE (plsigexp, loc) =>
        let
          val specEnv = evalSig topEnv path plsigexp
          val specEnv = #2 (refreshSpecEnv path specEnv)
        in
          V.replaceLocEnv loc specEnv
        end

      (* spec; spec *)
      | P.PLSPECSEQ (plspec1, plspec2, loc) =>
        let
          val specEnv1 = evalPlspec topEnv path plspec1
          val evalEnv = V.topEnvWithEnv (topEnv,specEnv1)
          val specEnv2 = evalPlspec evalEnv path plspec2
          val specEnv = V.unionEnv "220" (specEnv1,specEnv2)
        in
          specEnv
        end

      (* <spec> sharing type path1 = path2 = path3 ... *)
      | P.PLSPECSHARE (plspec, longsymbolList, loc) =>
       let
          val specEnv = evalPlspec topEnv path plspec
          val _ = processShare (specEnv, [longsymbolList], loc)
          val specEnv = N.reduceEnv specEnv
       in
         specEnv
       end

      (* spec sharing path1 = b ... *)
      | P.PLSPECSHARESTR (plspec, longsymbolList, loc) =>
        let
          fun addToListEnv (pathEnv, key, x) =
              LongsymbolEnv.unionWith
                (fn (x,y) => x @ y)
                (pathEnv, LongsymbolEnv.singleton(key, [x]))

          and addTyE path key tyE pathEnv =
              SymbolEnv.foldli
              (fn (name, tstr, pathEnv) => 
                  addToListEnv (pathEnv, (key@[name]), path@[name])
              )
              pathEnv
              tyE
              
          and addSpecEnv path
                         key
                         (V.ENV {tyE, strE=V.STR envMap,...})
                         pathEnv =
              let
                val pathEnv = addTyE path key tyE pathEnv
              in
                SymbolEnv.foldli
                (fn (name, {env=specEnv, strKind}, pathEnv) =>
                    addSpecEnv (path@[name]) (key@[name]) specEnv pathEnv
                )
                pathEnv
                envMap
              end
          val specEnv = evalPlspec topEnv path plspec
          val pathEnv =
              foldl
                (fn (longsymbol, pathEnv) =>
                    let
                      val envEntry = V.findStr(specEnv, longsymbol)
                    in
                      case envEntry
                       of NONE =>
                          (EU.enqueueError
                             (loc,E.StrUndefinedInSpec ("Sig-220", {longsymbol=longsymbol}));
                           pathEnv
                          )
                        | SOME {env=specEnv, strKind} =>
                          addSpecEnv longsymbol nil specEnv pathEnv
                    end
                )
                LongsymbolEnv.empty
                longsymbolList
          val idListList = LongsymbolEnv.listItems pathEnv
          val _ = processShare (specEnv, idListList, loc)
        in
          specEnv
        end

      | P.PLSPECEMPTY => V.emptyEnv

in
  val refreshSpecEnv = fn specEnv => refreshSpecEnv nil specEnv
  fun evalPlsig topEnv plsig =
      let
        val env = evalSig topEnv nil plsig
        val env = N.reduceEnv env
        val _ = L.setLiftedTysEnv env
      in
        env
      end
      handle exn => (print "uncaught exception in evalPlsig"; raise exn)
end
end
