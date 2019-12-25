(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : N-001 
 *)
structure NormalizeTy =
struct
local
  structure I = IDCalc
  structure IU = IDCalcUtils
  structure V = NameEvalEnv
  (* structure U = NameEvalUtils *)
  (* structure E = NameEvalError *)
  (* structure EU = UserErrorUtils *)
  (* structure A = AbsynTy *)
  exception Rigid
  fun bug s = Bug.Bug ("NormalizeTy: " ^ s)
in
  fun emptyTypIdEquiv (id1, id2) = TypID.eq(id1, id2)
  (* makes an equivalence relation on type ids for 
    processing sharing constraints in EvalSig *)
  fun makeTypIdEquiv typIdListList = 
      let
        val typIdEnv =
            foldl
            (fn (typIdList, typIdEnv) =>
                case typIdList of
                  nil => typIdEnv
                | [_] => typIdEnv
                | (id0::rest) =>
                  foldl 
                    (fn (id, typIdEnv) => TypID.Map.insert(typIdEnv, id, id0)) 
                    typIdEnv
                    rest
            )
            TypID.Map.empty
            typIdListList
      in
        if TypID.Map.isEmpty typIdEnv then TypID.eq
        else
          fn (id1, id2) =>
             let
               val id1Rep = case TypID.Map.find(typIdEnv, id1) of
                              SOME idRep => idRep | NONE => id1
               val id2Rep = case TypID.Map.find(typIdEnv, id2) of
                              SOME idRep => idRep | NONE => id2
             in
               TypID.eq(id1Rep, id2Rep)
             end
      end
             
  val emptyArgEnv = TvarMap.empty : I.ty TvarMap.map
  
  datatype normalForm = TYNAME of I.tfun | TYTERM of I.ty

  (* to generate TFUN_DEF in NameEvalInterface, CheckProvide, EvalSig *)
  fun tyForm formals ty  =
      let
        fun tyToTvars tyList =
            map (fn (I.TYVAR tvar) => tvar | _ => raise Rigid) tyList
        fun equalTuple (nil,nil) = true
          | equalTuple ({id=id1, symbol=_, isEq=_, lifted=_}::tvarList1,
                        {id=id2, symbol=_, isEq=_, lifted=_}::tvarList2) =
            TvarID.eq(id1,id2) andalso equalTuple (tvarList1, tvarList2) 
          | equalTuple _ =  false
      in
        case ty of
          I.TYWILD => TYTERM ty
        | I.TYERROR => TYTERM ty
        | I.TYVAR _ => TYTERM ty
        | I.TYFREE_TYVAR _ => TYTERM ty
        | I.TYRECORD _ => TYTERM ty
        | I.TYCONSTRUCT {tfun, args} =>
          (let
             val tvarList = tyToTvars args
           in
             if equalTuple (formals, tvarList) then TYNAME tfun
             else TYTERM ty
           end
             handle Rigid => TYTERM ty
          )
        | I.TYFUNM _ => TYTERM ty
        | I.TYPOLY _ => TYTERM ty
        | I.INFERREDTY _ => TYTERM ty
      end

  local
    val visitedSet = ref (TfvSet.empty)
    fun resetSet () = visitedSet := TfvSet.empty
    fun visit tfv = visitedSet := TfvSet.add(!visitedSet, tfv)
    fun isVisited tfv = TfvSet.member(!visitedSet, tfv)
    fun redTyWithInterface ifInterface tvarEnv ty =
        case ty of
          I.TYWILD => ty
        | I.TYERROR => ty
        | I.TYVAR tvar =>
          (case TvarMap.find(tvarEnv, tvar) of
             NONE => I.TYVAR tvar
           | SOME ty => ty)
        | I.TYFREE_TYVAR tvar => ty
        | I.TYRECORD {ifFlex, fields=fields} => 
          I.TYRECORD {ifFlex=ifFlex, fields=RecordLabel.Map.map (redTyWithInterface ifInterface tvarEnv) fields}
        | I.TYCONSTRUCT {tfun, args} =>
          let
            val realTfun = 
                case tfun of
                  I.TFUN_VAR (ref (I.TFUN_DTY 
                                     {id=id1,
                                      dtyKind=I.INTERFACE tfun1,...})) 
                  => if ifInterface then tfun1 else tfun
                | _ => tfun
               val args = map (redTyWithInterface ifInterface tvarEnv) args
               val tfun = redTfunWithInterface ifInterface tvarEnv realTfun
             in
(*
                 case I.derefTfun tfun of
*)
               case I.pruneTfun tfun of  (* bug 143 *)
                 I.TFUN_DEF {formals, realizerTy,...}  =>
                 let
                   val formalArgList = ListPair.zip(formals, args) 
                   val tvarEnv = 
                       foldr
                         (fn ((tvar, ty), tvarEnv) =>
                             TvarMap.insert(tvarEnv, tvar, ty))
                         tvarEnv
                         formalArgList
                 in
                   redTyWithInterface ifInterface tvarEnv realizerTy
                 end
               | I.TFUN_VAR(tfv as (ref tfunkind)) => 
                 (case tfunkind of
                    I.TFV_SPEC _ => I.TYCONSTRUCT {tfun=tfun, args=args}
                  | I.TFV_DTY _ => I.TYCONSTRUCT {tfun=tfun, args=args}
                  | I.TFUN_DTY _ => I.TYCONSTRUCT {tfun=tfun, args=args}
                  | I.REALIZED _ => raise bug "REALIZED tfun"
                  | I.INSTANTIATED {tfunkind, tfun} =>
                    I.TYCONSTRUCT {tfun=tfun, args=args}
                  | I.FUN_DTY {tfun,...} => 
                    (* raise bug "FUN_DTY(2)\n"
                    This case happnes when a structure in a functor argument
                    is replicated in the functor body *)
                    I.TYCONSTRUCT {tfun=tfun, args=args}
                 )
             end
        | I.TYFUNM (tyList,ty2) =>
          let
            val tyList = map (redTyWithInterface ifInterface tvarEnv) tyList
            val ty2 = redTyWithInterface ifInterface tvarEnv ty2
          in
            I.TYFUNM (tyList, ty2)
          end
        | I.TYPOLY (kindedTvarList, ty) => 
          let
            val ty = redTyWithInterface ifInterface tvarEnv ty
          in
            I.TYPOLY (kindedTvarList, ty)
          end
        | I.INFERREDTY ty => I.INFERREDTY ty

    and redTyFieldWithInterface ifInterface tvarEnv (l,ty) = (l, redTyWithInterface ifInterface tvarEnv ty)
    and redTfunWithInterface ifInterface tvarEnv tfun =
        case tfun of
          I.TFUN_DEF {longsymbol, admitsEq, formals, realizerTy} =>
          let
            val realizerTy = redTyWithInterface ifInterface tvarEnv realizerTy
            val res = tyForm formals realizerTy
          in
            case res of
              TYTERM ty =>
              I.TFUN_DEF {longsymbol=longsymbol, admitsEq=admitsEq, formals=formals, realizerTy=realizerTy}
            | TYNAME tfun => tfun
          end
        | I.TFUN_VAR tfv => 
          case !tfv of
            I.TFV_SPEC _ => tfun
          | I.TFUN_DTY {id, admitsEq, formals, longsymbol,
                        conSpec, conIDSet, liftedTys, dtyKind} =>
            if isVisited tfv then tfun 
            else
            let
              val _ = visit tfv
              val conSpec = redConSpecWithInterface ifInterface tvarEnv conSpec
              val _ =
                  tfv :=
                       I.TFUN_DTY {id=id,
                                   admitsEq=admitsEq,
                                   formals=formals,
                                   conSpec=conSpec,
                                   conIDSet = conIDSet,
                                   longsymbol=longsymbol,
                                   liftedTys=liftedTys,
                                   dtyKind=dtyKind
                                  }
            in
              tfun
            end
          | I.TFV_DTY {longsymbol, id, admitsEq, formals, conSpec, liftedTys} =>
            if isVisited tfv then tfun 
            else
              let
                val _ = visit tfv
                val conSpec = redConSpecWithInterface ifInterface tvarEnv conSpec
                val _ = 
                    tfv := I.TFV_DTY{id=id,
                                     longsymbol=longsymbol,
                                     admitsEq=admitsEq,
                                     formals=formals,
                                     conSpec=conSpec,
                                     liftedTys=liftedTys}
              in
                tfun
              end
          | I.REALIZED {tfun=newTfun,id} =>
            let
              val newTfun = redTfunWithInterface ifInterface tvarEnv newTfun
              val _ = tfv:= I.REALIZED {id=id,tfun=newTfun}
            in
              newTfun
            end
          | I.INSTANTIATED {tfunkind, tfun=newTfun} => 
            let
              val newTfun = redTfunWithInterface ifInterface tvarEnv newTfun
              val _ = tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=newTfun}
            in
              tfun (* newTfun ? *)
            end
          | _ => tfun

    and redConSpecWithInterface ifInterface tvarEnv conSpec =
        SymbolEnv.mapi
          (fn (name, tyOpt) => (Option.map (redTyWithInterface ifInterface tvarEnv) tyOpt)
          )
          conSpec

    val redConSpec = fn x => redConSpecWithInterface false x
    val redTfun = fn x => redTfunWithInterface false x
    fun redTstr tstr =
         case tstr of
           V.TSTR tfun => V.TSTR (redTfun TvarMap.empty tfun)
         | V.TSTR_DTY {tfun, varE, formals, conSpec} =>
           let
             val tfun = redTfun TvarMap.empty tfun
             val conSpec = redConSpec TvarMap.empty conSpec
           in
             V.TSTR_DTY {tfun=tfun,
                         varE=varE,
                         formals=formals,
                         conSpec=conSpec}
           end
    val redTy = fn x => redTyWithInterface false x
    fun redIdstatus idstatus =
        case idstatus of
          I.IDVAR _ => idstatus
        | I.IDVAR_TYPED {id, longsymbol, ty} => 
          I.IDVAR_TYPED {id=id, longsymbol=longsymbol, ty= redTy TvarMap.empty ty}
        | I.IDEXVAR {exInfo={used, longsymbol, version, ty}, internalId} =>
          I.IDEXVAR {exInfo={used=used, longsymbol=longsymbol, version=version, ty=redTy TvarMap.empty ty},
                     internalId = internalId
                    }
        | I.IDEXVAR_TOBETYPED {longsymbol, id, version} => idstatus
        | I.IDBUILTINVAR {primitive, ty} =>
          I.IDBUILTINVAR {primitive=primitive, ty=redTy TvarMap.empty ty}
        | I.IDCON {id, longsymbol, ty} =>
          I.IDCON {id=id, longsymbol=longsymbol, ty=redTy TvarMap.empty ty}
        | I.IDEXN {id, longsymbol, ty} =>
          I.IDEXN {id=id, longsymbol=longsymbol,ty=redTy TvarMap.empty ty}
        | I.IDEXNREP {id, longsymbol, ty} =>
          I.IDEXNREP {id=id, longsymbol=longsymbol, ty=redTy TvarMap.empty ty}
        | I.IDEXEXN {used, longsymbol, ty, version} =>
          I.IDEXEXN {used = used, longsymbol=longsymbol, ty=redTy TvarMap.empty ty, version=version}
        | I.IDEXEXNREP {used, longsymbol, ty, version} =>
          I.IDEXEXNREP {used = used, longsymbol=longsymbol, ty=redTy TvarMap.empty ty, version=version}
        | I.IDOPRIM _ => idstatus
        | I.IDSPECVAR {ty, symbol} => I.IDSPECVAR {ty=redTy TvarMap.empty ty, symbol=symbol}
        | I.IDSPECEXN {ty, symbol} => I.IDSPECEXN {ty=redTy TvarMap.empty ty, symbol=symbol}
        | I.IDSPECCON {symbol} => I.IDSPECCON {symbol=symbol}

    fun redEnv env =
        let
          val V.ENV{tyE, varE, strE=V.STR envMap} = env
          val tyE = SymbolEnv.map redTstr tyE
          val envMap = 
              SymbolEnv.map
                (fn {env, strKind} => 
                    {env=redEnv env, strKind=strKind}) envMap
          val varE = SymbolEnv.map redIdstatus varE
        in
          V.ENV{tyE=tyE, varE=varE, strE=V.STR envMap} 
        end
  in
    fun reduceTyWithInterface ifInterface tvarEnv ty = (resetSet(); redTyWithInterface ifInterface tvarEnv ty)
    val reduceTy = fn x => reduceTyWithInterface false x
    fun reduceEnv env = (resetSet(); redEnv env)
    fun reduceTfunWithInterface ifInterface tfun = (resetSet(); redTfunWithInterface ifInterface TvarMap.empty tfun)
    val reduceTfun = fn x => reduceTfunWithInterface false x
  end

  fun tvequiv eqEnv (id1,id2) =
      TvarID.eq(id1, id2) orelse
      let
        val id1Rep = case TvarID.Map.find(eqEnv,id1) of
                       SOME id => id | NONE => id1
        val id2Rep = case TvarID.Map.find(eqEnv,id2) of
                       SOME id => id | NONE => id2
      in
        TvarID.eq(id1Rep, id2Rep) 
      end

  fun equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun2) =
      case (tfun1, tfun2) of
        (I.TFUN_VAR(ref(I.REALIZED{tfun,...})),_) => equalTfunWithInterface ifInterface typIdEquiv (tfun, tfun2)
      | (_, I.TFUN_VAR(ref(I.REALIZED{tfun,...}))) => equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun) 
      | (I.TFUN_VAR(ref(I.INSTANTIATED{tfun,...})),_) => equalTfunWithInterface ifInterface typIdEquiv (tfun, tfun2)
      | (_,I.TFUN_VAR(ref(I.INSTANTIATED{tfun,...}))) => equalTfunWithInterface ifInterface typIdEquiv (tfun1,tfun) 
      | (I.TFUN_DEF {formals=formals1,realizerTy=ty1,...},
         I.TFUN_DEF {formals=formals2,realizerTy=ty2,...}) =>
        eqTydefWithInterface ifInterface typIdEquiv ((formals1, ty1),(formals2, ty2))
      | (I.TFUN_VAR (ref (I.TFV_SPEC {id=id1,...})),
         I.TFUN_VAR (ref (I.TFV_SPEC {id=id2,...}))) => typIdEquiv(id1,id2)
      | (I.TFUN_VAR (ref (I.TFV_DTY {id=id1,...})),
         I.TFUN_VAR (ref (I.TFV_DTY {id=id2,...}))) =>  typIdEquiv(id1,id2)
      | (I.TFUN_VAR (ref (I.TFUN_DTY 
                            {id=id1,
                             dtyKind=I.INTERFACE tfun1,...})),
         I.TFUN_VAR (ref (I.TFUN_DTY {id=id2,...}))
        )
        => typIdEquiv(id1,id2) orelse 
           (ifInterface andalso equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun2))

      | (I.TFUN_VAR (ref (I.TFUN_DTY 
                            {id=id1,
                             dtyKind=I.INTERFACE tfun1,...})),
         _
        ) => ifInterface andalso equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun2)
      | (I.TFUN_VAR (ref (I.TFUN_DTY {id=id1,...})),
         I.TFUN_VAR (ref (I.TFUN_DTY 
                            {id=id2,
                             dtyKind=I.INTERFACE tfun2,...})))
        => typIdEquiv(id1,id2) orelse  
           (ifInterface andalso equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun2))
      | (_, 
         I.TFUN_VAR (ref (I.TFUN_DTY 
                            {id=id2,
                             dtyKind=I.INTERFACE tfun2,...})))
        => ifInterface andalso equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun2)
      | (I.TFUN_VAR (ref (I.TFUN_DTY {id=id1,...})),
         I.TFUN_VAR (ref (I.TFUN_DTY {id=id2,...}))) => typIdEquiv (id1,id2)
(* 2012-12-24
     tfun may be functor arguments.
  2013-4-3 we must check the equality of the actual tfuns in FUN_DTY
      | (I.TFUN_VAR (ref (I.FUN_DTY {tfun=tfun1,...})),
         I.TFUN_VAR (ref (I.FUN_DTY {tfun=tfun2,...}))) => equalTfun typIdEquiv (tfun1,tfun2) 
*)
      | (I.TFUN_VAR (ref (I.FUN_DTY {tfun=tfun,...})), _) => equalTfunWithInterface ifInterface typIdEquiv (tfun,tfun2) 
      | (_, I.TFUN_VAR (ref (I.FUN_DTY {tfun=tfun,...}))) => equalTfunWithInterface ifInterface typIdEquiv (tfun1,tfun) 
      | _ => false

  and eqTydefWithInterface ifInterface typIdEquiv ((formals1, ty1), (formals2, ty2)) =
      let
        val tvarIdEquiv =
            foldl
            (fn (({id=tv1,symbol=_,isEq=_,lifted=_},
                  {id=tv2,symbol=_,isEq=_,lifted=_}),
                 equiv) =>
                TvarID.Map.insert(equiv, tv1, tv2))
            TvarID.Map.empty
            (ListPair.zip (formals1,formals2))
      in
        equalTyWithInterface ifInterface (typIdEquiv, tvarIdEquiv) (ty1, ty2)
      end

  and equalTyWithInterface ifInterface (typIdEquiv, tvarIdEquiv) (ty1, ty2) =
      let
        val ty1 = reduceTyWithInterface ifInterface TvarMap.empty ty1
        val ty2 = reduceTyWithInterface ifInterface TvarMap.empty ty2
      in
        case (ty1, ty2) of
          (I.TYWILD, I.TYWILD) => true
        | (I.TYERROR, _) => true
        | (_, I.TYERROR ) => true
        | (I.TYVAR {id=id1,...}, I.TYVAR {id=id2,...}) =>
          tvequiv tvarIdEquiv (id1,id2)
        | (I.TYFREE_TYVAR {id=id1,...}, I.TYFREE_TYVAR {id=id2,...}) =>
          tvequiv tvarIdEquiv (id1,id2)
        | (I.TYRECORD {ifFlex=_, fields=F1}, I.TYRECORD {ifFlex=_, fields=F2}) => 
          equalFieldsWithInterface ifInterface (typIdEquiv,tvarIdEquiv) (F1,F2)
        | (I.TYFUNM (tyList1,ty12),I.TYFUNM(tyList2,ty22)) =>
          (equalTyWithInterface ifInterface (typIdEquiv, tvarIdEquiv) (ty12, ty22)
           andalso List.length tyList1 = List.length tyList2
           andalso List.all (equalTyWithInterface ifInterface (typIdEquiv, tvarIdEquiv)) (ListPair.zip (tyList1, tyList2))
           handle exn => raise exn)
        | (I.TYPOLY(kindedTvars1, bodyTy1),I.TYPOLY(kindedTvars2, bodyTy2)) =>
          List.length kindedTvars1 = List.length kindedTvars2 andalso
          let
            val boundPairs = ListPair.zip (kindedTvars1,kindedTvars2)
            val tvarIdEquiv =
                foldl
                  (fn ((({id=tv1,...},_),({id=tv2,...},_)), tvarIdEquiv) =>
                      TvarID.Map.insert(tvarIdEquiv, tv1, tv2)
                  )
                  tvarIdEquiv
                  boundPairs
          in
            List.all
              (fn ((_, kind1), (_,kind2)) => 
                  equalKindWithInterface ifInterface (typIdEquiv, tvarIdEquiv) (kind1,kind2))
              boundPairs
              andalso
              equalTyWithInterface ifInterface (typIdEquiv, tvarIdEquiv) (bodyTy1, bodyTy2)
          end
        | (I.TYCONSTRUCT{tfun=tfun1, args=args1},
           I.TYCONSTRUCT{tfun=tfun2, args=args2}) =>
          (equalTfunWithInterface ifInterface typIdEquiv (tfun1, tfun2)
            andalso List.length args1 = List.length args2
            andalso List.all (equalTyWithInterface ifInterface (typIdEquiv, tvarIdEquiv)) (ListPair.zip (args1, args2))
           handle exn => raise exn)
      | _ => false
      end
  and equalKindWithInterface ifInterface (typIdEquiv,tvarIdEquiv) (kind1, kind2) =
      case (kind1, kind2) of
        (I.UNIV prop1, I.UNIV prop2) => IU.equalPropList (prop1, prop2)
      | (I.REC {properties=prop1, recordKind=fields1}, 
         I.REC {properties=prop2, recordKind=fields2}) => 
        IU.equalPropList (prop1,prop2) andalso
        equalFieldsWithInterface ifInterface (typIdEquiv,tvarIdEquiv) (fields1, fields2)
      | _ => false
  and equalFieldsWithInterface ifInterface (typIdEquiv,tvarIdEquiv) (fields1,fields2) =
      let exception FALSE in
        let
          val F2 =
              RecordLabel.Map.foldli
                (fn (name, ty1, F2) =>
                    case RecordLabel.Map.find(fields2, name) of
                      NONE => raise FALSE
                    | SOME ty2 => if equalTyWithInterface ifInterface (typIdEquiv,tvarIdEquiv) (ty1,ty2) then 
                                    (#1 (RecordLabel.Map.remove(F2, name)))
                                  else raise FALSE
                )
                fields2
                fields1
        in
          RecordLabel.Map.isEmpty F2
        end
        handle FALSE => false
      end

  val equalTfun = fn x => equalTfunWithInterface false x
  val eqTydef = fn x => eqTydefWithInterface false x
  val equalTy = fn x => equalTyWithInterface false x
  val equalKind = fn x => equalKindWithInterface false x
  val equalFields = fn x => equalFieldsWithInterface false x

  fun admitEqMaker tfuneq tvarList ty =
      let
        val set = TvarSet.fromList tvarList
        fun eqtvar (tvar as {symbol, isEq, id, lifted}) =
            TvarSet.member(set, tvar) orelse isEq
        fun eqFreeTvar (freetvar as {symbol, isEq, id, tvarKind}) =
            isEq
        fun eqTfun (tfun, args) =
            let
              fun tfunId tfun =
                  case tfun of
                    I.TFUN_DEF {formals=formals1,realizerTy=ty1,...} => NONE
                  | I.TFUN_VAR (ref (I.TFV_SPEC {id,...})) => SOME id
                  | I.TFUN_VAR (ref (I.TFV_DTY {id,...})) => SOME id
                  | I.TFUN_VAR (ref (I.TFUN_DTY {id,...})) => SOME id
                  | I.TFUN_VAR (ref (I.FUN_DTY {tfun,...})) => tfunId tfun
                  | I.TFUN_VAR(ref(I.REALIZED{tfun,...})) => tfunId tfun
                  | I.TFUN_VAR(ref(I.INSTANTIATED{tfun,...})) => tfunId tfun
              val typIdopt = tfunId tfun
            in
              case typIdopt of
                SOME id => TypID.eq(id, #id BuiltinTypes.arrayTyCon)
                           orelse
                           TypID.eq(id, #id BuiltinTypes.refTyCon)
                           orelse (tfuneq tfun andalso eqList args)
              | _ => tfuneq tfun andalso eqList args
            end
        and eqTy ty =
            case ty of
              I.TYWILD => false
            | I.TYERROR => false
            | I.TYVAR tvar => eqtvar tvar
            | I.TYFREE_TYVAR freeTvar => eqFreeTvar freeTvar
            | I.TYRECORD {ifFlex, fields=fields} => eqFields fields
            | I.TYCONSTRUCT {tfun, args} => eqTfun (tfun, args)
(*  2011-12-24 ohori:bug 190.
This is a temporary fix. I am going to re-write BuiltinEnv
to re-structure builtins.
              (case path of
                 ["ref"] => true
               | _ => tfuneq tfun andalso eqList args
              )
*)
            | I.TYFUNM (tyList,ty2) => false
            | I.TYPOLY (kindedTvarList, ty) => raise bug "POLYty"
            | I.INFERREDTY ty => raise bug "INFERREDTY"
        and eqFields fields =
            let exception FALSE in
              (RecordLabel.Map.app
                (fn ty => if eqTy ty then () else raise FALSE)
                fields; 
               true)
              handle FALSE => false
            end
        and eqList nil = true
          | eqList (ty::rest) = eqTy ty andalso eqList rest
      in
        eqTy ty
      end
  fun admitEq tvarList ty = admitEqMaker I.tfunAdmitsEq tvarList ty

(*
  fun substTy subst ty =
      case ty of
        I.TYWILD => ty
      | I.TYERROR => ty
      | I.TYVAR tvar => 
        (case TvarMap.find(subst, tvar) of
           NONE => I.TYVAR tvar
         | SOME ty => ty)
      | I.TYFREE_TYVAR freeTvar => 
        (case TvarMap.find(subst, tvar) of
           NONE => I.TYVAR tvar
         | SOME ty => ty)
      | I.TYRECORD {ifFlex, fields=fields} => 
        I.TYRECORD {ifFlex=ifFlex, fields=RecordLabel.Map.map (substTy subst) fields}
      | I.TYCONSTRUCT {tfun, args} =>
        I.TYCONSTRUCT {tfun=tfun, args=map (substTy subst) args}
      | I.TYFUNM (tyList1, ty2) =>
        I.TYFUNM (map (substTy subst) tyList1, substTy subst ty2)
      | I.TYPOLY (kindedTvarList, ty) => 
        I.TYPOLY (kindedTvarList, substTy subst ty)
      | I.INFERREDTY ty => I.INFERREDTY ty 
*)
  fun setEq datadeclList =
      let
        val (eqEnv, datadeclList) =
            foldr
              (fn ({id, admitsEqRef, args, conSpec}, (eqEnv, datadeclList)) =>
                  (TypID.Map.insert(eqEnv, id, admitsEqRef),
                   {id=id,
                    admitsEqRef=admitsEqRef,
                    args=args,
                    conSpec=SymbolEnv.listItems conSpec}
                   :: datadeclList
                  )
              )
              (TypID.Map.empty, nil)
              datadeclList
        fun tfunAdmitsEq tfun =
            case tfun of
              I.TFUN_DEF {admitsEq,...} => admitsEq
            | I.TFUN_VAR (ref tfunkind) => 
              (case tfunkind of
                 I.TFV_SPEC {admitsEq,...} => admitsEq
               | I.TFV_DTY {id,...} => 
                 (case TypID.Map.find(eqEnv, id) of
                    SOME eqref => !eqref
                  | NONE => I.tfunAdmitsEq tfun)
               | I.TFUN_DTY {id,...}  => 
                 (case TypID.Map.find(eqEnv, id) of
                    SOME eqref => !eqref
                  | NONE => I.tfunAdmitsEq tfun)
               | I.REALIZED {id, tfun} => tfunAdmitsEq tfun
               | I.INSTANTIATED {tfun,...} => tfunAdmitsEq tfun
               | I.FUN_DTY {tfun,...}  => 
                 (* raise bug "FUN_DTY(2)\n"
                    This case happnes when a structure in a functor argument
                    is replicated in the functor body *)
                 tfunAdmitsEq tfun
              )
        fun admitsEq tvarList ty = admitEqMaker tfunAdmitsEq tvarList ty
        val changed = ref true
        fun next {admitsEqRef, conSpec, args, id} =
            if not (!admitsEqRef) then ()
            else
              let
                fun admitEqList nil = true
                  | admitEqList (NONE::rest) = admitEqList rest
                  | admitEqList (SOME ty::rest) = 
                    admitsEq args ty andalso admitEqList rest
              in
                if admitEqList conSpec then ()
                else (admitsEqRef := false; changed:=true)
              end
        val _ = while !changed do (changed:=false; map next datadeclList)
      in
        ()
      end

  datatype checkConError =
           Arity
         | Name of (Symbol.symbol list * Symbol.symbol list)
         | Type of Symbol.symbol list
         | OK
  datatype checkConRes =
           SUCCESS
         | FAIL of checkConError list
  fun checkConSpec typIdEquiv ((formals1, conSpec1), (formals2, conSpec2)) =
      let
        val errors = if List.length formals1 <> List.length formals2 then
                       [Arity]
                     else nil
        val tvarIdEquiv =
            foldl
            (fn (({id=id1,...}:I.tvar,{id=id2,...}:I.tvar), equiv) =>
                TvarID.Map.insert(equiv, id1, id2))
            TvarID.Map.empty
            (ListPair.zip (formals1,formals2))
        val (tyerrors, nameList1, conSpec2) =
            SymbolEnv.foldli
            (fn (name, tyopt1, (tyerrors, nameList1, conSpec2)) =>
                let
                  val (conSpec2, tyopt2) = SymbolEnv.remove(conSpec2, name)
                in
                  case (tyopt1,tyopt2) of
                    (NONE, NONE) => (tyerrors, nameList1, conSpec2)
                  | (SOME _, NONE) => (name::tyerrors, nameList1, conSpec2)
                  | (NONE, SOME _) => (name::tyerrors, nameList1, conSpec2)
                  | (SOME ty1, SOME ty2) => 
                    if equalTy (typIdEquiv, tvarIdEquiv) (ty1, ty2) then 
                      (tyerrors, nameList1, conSpec2)
                    else (name::tyerrors, nameList1, conSpec2)
                end
                handle LibBase.NotFound => 
                       (tyerrors, name::nameList1, conSpec2)
            )
            (nil, nil, conSpec2)
            conSpec1
        val nameList2 = SymbolEnv.listKeys conSpec2
        val errors = case tyerrors of
                       nil => errors
                     | _ => Type tyerrors :: errors
        val errors = case (nameList1, nameList2) of
                       (nil,nil) => errors
                     | _ => Name(nameList1, nameList2):: Type tyerrors :: errors
      in
        case errors of 
          nil => SUCCESS
        | _ => FAIL errors
      end
end
end
