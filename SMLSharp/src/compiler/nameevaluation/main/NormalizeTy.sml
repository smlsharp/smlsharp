(* the initial error code of this file : N-001 *)
structure NormalizeTy =
struct
local
  structure T = IDTypes
  structure V = NameEvalEnv
  structure U = NameEvalUtils
  structure E = NameEvalError
  structure EU = UserErrorUtils
  structure A = Absyn
  exception Rigid
  fun bug s = Control.Bug ("EvalTfun: " ^ s)
in

  val emptyArgEnv = TvarMap.empty : T.ty TvarMap.map
  
  datatype normalForm = TYNAME of T.typInfo | TYTERM of T.ty

  fun tyForm formals ty  =
      let
        fun tyToTvars tyList =
            map
              (fn (T.TYVAR tvar) => tvar
                | _ => raise Rigid)
              tyList
        fun equalTuple (nil,nil) = true
          | equalTuple ({id=id1, name=_, eq=_, lifted=_}::tvarList1,
                        {id=id2, name=_, eq=_, lifted=_}::tvarList2) =
            TvarID.eq(id1,id2) andalso equalTuple (tvarList1, tvarList2) 
          | equalTuple _ =  false
      in
        case ty of
          T.TYWILD => TYTERM ty
        | T.TYERROR => TYTERM ty
        | T.TYVAR _ => TYTERM ty
        | T.TYRECORD _ => TYTERM ty
        | T.TYCONSTRUCT {typ= typ as {path,...}, args} =>
          (let
             val tvarList = tyToTvars args
           in
             if equalTuple (formals, tvarList) then TYNAME typ
             else TYTERM ty
           end
             handle Rigid => TYTERM ty
          )
        | T.TYFUNM _ => TYTERM ty
        | T.TYPOLY _ => TYTERM ty
      end

  fun admitEqMaker tfuneq tvarList ty =
      let
        val set = TvarSet.fromList tvarList
        fun eqtvar (tvar as {name, eq, id, lifted}) =
            TvarSet.member(set, tvar) orelse
            case eq of Absyn.EQ => true | Absyn.NONEQ => false
        fun eqTy ty = 
            case ty of
              T.TYWILD => false
            | T.TYERROR => false
            | T.TYVAR tvar => eqtvar tvar
            | T.TYRECORD fields => eqFields fields
            | T.TYCONSTRUCT {typ={tfun,...}, args} =>
              tfuneq tfun andalso eqList args
            | T.TYFUNM (tyList,ty2) => false
            | T.TYPOLY (kindedTvarList, ty) => raise bug "POLYty"
        and eqFields fields =
            let
              exception FALSE
            in
              (SEnv.app
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
  fun admitEq tvarList ty = admitEqMaker T.tfunIseq tvarList ty

  local
    val visitedSet = ref (TfvSet.empty)
    fun resetSet () = visitedSet := TfvSet.empty
    fun visit tfv = visitedSet := TfvSet.add(!visitedSet, tfv)
    fun isVisited tfv = TfvSet.member(!visitedSet, tfv)
    fun redTy tvarEnv ty =
        case ty of
          T.TYWILD => ty
        | T.TYERROR => ty
        | T.TYVAR tvar =>
          (case TvarMap.find(tvarEnv, tvar) of
             NONE => T.TYVAR tvar
           | SOME ty => ty)
        | T.TYRECORD fields => 
          T.TYRECORD (SEnv.map (redTy tvarEnv) fields)
        | T.TYCONSTRUCT {typ=typ as {tfun, path}, args} =>
          let
            val args = map (redTy tvarEnv) args
            val tfun = redTfun tvarEnv tfun
            val typ = {tfun=tfun, path=path}
          in
            case T.derefTfun tfun of
              T.TFUN_DEF {formals, realizerTy,...}  =>
              let
                val formalArgList = ListPair.zip(formals, args) 
                val tvarEnv = 
                    foldr
                      (fn ((tvar, ty), tvarEnv) =>
                          TvarMap.insert(tvarEnv, tvar, ty))
                      tvarEnv
                      formalArgList
              in
                redTy tvarEnv realizerTy
              end
            | T.TFUN_VAR(tfv as (ref tfunkind)) => 
              (case tfunkind of
                 T.TFV_SPEC _ => T.TYCONSTRUCT {typ=typ, args=args}
               | T.TFV_DTY _ => T.TYCONSTRUCT {typ=typ, args=args}
               | T.TFUN_DTY _ => T.TYCONSTRUCT {typ=typ, args=args}
               | T.REALIZED _ => raise bug "REALIZED tfun"
               | T.INSTANTIATED {tfunkind, tfun} =>
                 T.TYCONSTRUCT {typ=typ, args=args}
               | T.FUN_TOTVAR {tvar,...} => T.TYVAR tvar
(*
               | T.FUN_TODUMMY _ => raise bug "FUN_TODUMMY"
*)
               | T.FUN_DTY _ => raise bug "FUN_DTY"
              )
          end
        | T.TYFUNM (tyList,ty2) =>
          let
            val tyList = map (redTy tvarEnv) tyList
            val ty2 = redTy tvarEnv ty2
          in
            T.TYFUNM (tyList, ty2)
          end
        | T.TYPOLY (kindedTvarList, ty) => 
          let
            val ty = redTy tvarEnv ty
          in
            T.TYPOLY (kindedTvarList, ty)
          end
    and redTyField tvarEnv (l,ty) = (l, redTy tvarEnv ty)
    and redTfun tvarEnv tfun =
        case tfun of
          T.TFUN_DEF {iseq, formals, realizerTy} =>
          let
            val realizerTy = redTy tvarEnv realizerTy
            val res = tyForm formals realizerTy
          in
            case res of
              TYTERM ty =>
              T.TFUN_DEF {iseq=iseq, formals=formals,realizerTy=realizerTy}
            | TYNAME {tfun,...} => tfun
          end
        | T.TFUN_VAR tfv => 
          case !tfv of
            T.TFV_SPEC {id, iseq, formals} => tfun
          | T.TFUN_DTY {id, iseq, formals, conSpec, liftedTys, dtyKind} =>
            if isVisited tfv then tfun 
            else
            let
              val _ = visit tfv
              val conSpec = redConSpec tvarEnv conSpec
              val _ =
                  tfv :=
                       T.TFUN_DTY {id=id,
                                   iseq=iseq,
                                   formals=formals,
                                   conSpec=conSpec,
                                   liftedTys=liftedTys,
                                   dtyKind=dtyKind
                                  }
            in
              tfun
            end
          | T.TFV_DTY {id, iseq, formals, conSpec, liftedTys} =>
            if isVisited tfv then tfun 
            else
              let
                val _ = visit tfv
                val conSpec = redConSpec tvarEnv conSpec
                val _ = 
                    tfv := T.TFV_DTY{id=id,
                                     iseq=iseq,
                                     formals=formals,
                                     conSpec=conSpec,
                                     liftedTys=liftedTys}
              in
                tfun
              end
          | T.REALIZED {tfun=newTfun,id} =>
            let
              val newTfun = redTfun tvarEnv newTfun
              val _ = tfv:= T.REALIZED {id=id,tfun=newTfun}
            in
              newTfun
            end
          | T.INSTANTIATED {tfunkind, tfun=newTfun} => 
            let
              val newTfun = redTfun tvarEnv newTfun
              val _ = tfv := T.INSTANTIATED {tfunkind=tfunkind, tfun=newTfun}
            in
              tfun (* newTfun ? *)
            end
          | _ => tfun
    and redConSpec tvarEnv conSpec =
        SEnv.mapi
          (fn (name, tyOpt) => (Option.map (redTy tvarEnv) tyOpt)
          )
          conSpec
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
         | V.TSTR_TOTVAR _ => tstr

    fun redIdstatus idstatus =
        case idstatus of
          T.IDVAR varId => idstatus
        | T.IDEXVAR {path, ty} =>
          T.IDEXVAR {path=path, ty= redTy TvarMap.empty ty}
        | T.IDBUILTINVAR {primitive, ty} =>
          T.IDBUILTINVAR {primitive=primitive, ty=redTy TvarMap.empty ty}
        | T.IDCON {id, ty} =>
          T.IDCON {id=id, ty=redTy TvarMap.empty ty}
        | T.IDEXN {id, ty} =>
          T.IDEXN {id=id, ty=redTy TvarMap.empty ty}
        | T.IDEXNREP {id, ty} =>
          T.IDEXNREP {id=id, ty=redTy TvarMap.empty ty}
        | T.IDEXEXN {path, ty} =>
          T.IDEXEXN {path=path, ty=redTy TvarMap.empty ty}
        | T.IDOPRIM oprimId => idstatus
        | T.IDSPECVAR ty => T.IDSPECVAR (redTy TvarMap.empty ty)
        | T.IDSPECEXN ty => T.IDSPECEXN (redTy TvarMap.empty ty)
        | T.IDSPECCON => idstatus

    fun redEnv env =
        let
          val V.ENV{tyE, varE, strE=V.STR envMap} = env
          val tyE = SEnv.map redTstr tyE
          val envMap = SEnv.map redEnv envMap
          val varE = SEnv.map redIdstatus varE
        in
          V.ENV{tyE=tyE, varE=varE, strE=V.STR envMap} 
        end
  in
    fun reduceTy tvarEnv ty = (resetSet(); redTy tvarEnv ty)
    fun reduceEnv env = (resetSet(); redEnv env)
    fun reduceTfun tfun = (resetSet(); redTfun TvarMap.empty tfun)
  end

  fun tvequiv eqEnv (id1,id2) =
      TvarID.eq(id1, id2) orelse
      case TvarID.Map.find(eqEnv,id1) of
        SOME id11 => TvarID.eq(id11, id2) orelse
                    (case TvarID.Map.find(eqEnv,id2) of
                       SOME id22 => TvarID.eq(id1, id22)
                     | NONE => false)
      | NONE => (case TvarID.Map.find(eqEnv,id2) of
                   SOME id22 => TvarID.eq(id1, id22)
                 | NONE => false)
  fun equalTfun (tfun1, tfun2) =
      case (tfun1, tfun2) of
        (T.TFUN_VAR(ref(T.REALIZED{tfun,...})),_) => equalTfun (tfun, tfun2)
      | (_, T.TFUN_VAR(ref(T.REALIZED{tfun,...}))) => equalTfun (tfun1, tfun) 
      | (T.TFUN_VAR(ref(T.INSTANTIATED{tfun,...})),_)=> equalTfun (tfun, tfun2)
      | (_,T.TFUN_VAR(ref(T.INSTANTIATED{tfun,...}))) =>equalTfun (tfun1,tfun) 
      | (T.TFUN_DEF {formals=formals1,realizerTy=ty1,...},
         T.TFUN_DEF {formals=formals2,realizerTy=ty2,...})=>
        eqTfun((formals1, ty1),(formals2, ty2))
      | (T.TFUN_VAR (ref (T.TFV_SPEC {id=id1,...})),
         T.TFUN_VAR (ref (T.TFV_SPEC {id=id2,...}))) => TypID.eq(id1,id2)
      | (T.TFUN_VAR (ref (T.TFV_DTY {id=id1,...})),
         T.TFUN_VAR (ref (T.TFV_DTY {id=id2,...}))) => TypID.eq(id1,id2)
      | (T.TFUN_VAR (ref (T.TFUN_DTY {id=id1,...})),
         T.TFUN_VAR (ref (T.TFUN_DTY {id=id2,...}))) => TypID.eq(id1,id2)
      | _ => false

  and eqTfun ((formals1, ty1), (formals2, ty2)) =
      let
        val equiv =
            foldl
            (fn (({id=tv1,name=_,eq=_,lifted=_},
                  {id=tv2,name=_,eq=_,lifted=_}),
                 equiv) =>
                TvarID.Map.insert(equiv, tv1, tv2))
            TvarID.Map.empty
            (ListPair.zip (formals1,formals2))
      in
        equalTy equiv (ty1, ty2)
      end

  and equalTy eqEnv (ty1, ty2) =
      let
        val ty1 = reduceTy TvarMap.empty ty1
        val ty2 = reduceTy TvarMap.empty ty2
      in
        case (ty1, ty2) of
          (T.TYWILD, T.TYWILD) => true
        | (T.TYERROR, _) => true
        | (_, T.TYERROR ) => true
        | (T.TYVAR {id=id1,...}, T.TYVAR {id=id2,...}) =>
          tvequiv eqEnv (id1,id2)
        | (T.TYRECORD F1, T.TYRECORD F2) => equalFields eqEnv (F1,F2)
        | (T.TYFUNM (tyList1,ty12),T.TYFUNM(tyList2,ty22)) =>
          (equalTy eqEnv (ty12, ty22) 
           andalso List.length tyList1 = List.length tyList2
           andalso List.all (equalTy eqEnv) (ListPair.zip (tyList1, tyList2))
           handle exn => raise exn)
        | (T.TYPOLY(kindedTvars1, ty1),T.TYPOLY(kindedTvars2, ty2)) =>
          List.length kindedTvars1 = List.length kindedTvars2 andalso
          let
            val boundPairs = ListPair.zip (kindedTvars1,kindedTvars2)
            val eqEnv =
                foldl
                  (fn ((({id=tv1,...},_),({id=tv2,...},_)), eqEnv) =>
                      TvarID.Map.insert(eqEnv, tv1, tv2)
                  )
                  eqEnv
                  boundPairs
          in
            List.all
              (fn ((_, kind1), (_,kind2)) => equalKind eqEnv (kind1,kind2))
              boundPairs
              andalso
              equalTy eqEnv (ty1, ty2)
          end
        | (T.TYCONSTRUCT{typ={tfun=tfun1,...}, args=args1},
           T.TYCONSTRUCT{typ={tfun=tfun2,...}, args=args2}) =>
          (equalTfun (tfun1, tfun2)
            andalso List.length args1 = List.length args2
            andalso List.all (equalTy eqEnv) (ListPair.zip (args1, args2))
           handle exn => raise exn)
      | _ => false
      end

  and equalKind eqEnv (kind1, kind2) =
      case (kind1, kind2) of
        (T.UNIV, T.UNIV) => true
      | (T.REC fields1, T.REC fields2) => equalFields eqEnv (fields1, fields2)
      | _ => false
  and equalFields eqEnv (fields1,fields2) =
      let
        exception FALSE
      in
        let
          val F2 =
              SEnv.foldli
                (fn (name, ty1, F2) =>
                    case SEnv.find(fields2, name) of
                      NONE => raise FALSE
                    | SOME ty2 => if equalTy eqEnv (ty1,ty2) then 
                                    (#1 (SEnv.remove(F2, name)))
                                  else raise FALSE
                )
                fields2
                fields1
        in
          SEnv.isEmpty F2 
        end
        handle FALSE => false
      end
      

  fun substTy subst ty =
      case ty of
        T.TYWILD => ty
      | T.TYERROR => ty
      | T.TYVAR tvar => 
        (case TvarMap.find(subst, tvar) of
           NONE => T.TYVAR tvar
         | SOME ty => ty)
      | T.TYRECORD fields => 
        T.TYRECORD (SEnv.map (substTy subst) fields)
      | T.TYCONSTRUCT {typ, args} =>
        T.TYCONSTRUCT {typ=typ, args=map (substTy subst) args}
      | T.TYFUNM (tyList1, ty2) =>
        T.TYFUNM (map (substTy subst) tyList1, substTy subst ty2)
      | T.TYPOLY (kindedTvarList, ty) => 
        T.TYPOLY (kindedTvarList, substTy subst ty)

  fun setEq datadeclList =
      let
        val (eqEnv, datadeclList) =
            foldr
              (fn ({id, iseqRef, args, conSpec}, (eqEnv, datadeclList)) =>
                  (TypID.Map.insert(eqEnv, id, iseqRef),
                   {id=id,
                    iseqRef=iseqRef,
                    args=args,
                    conSpec=SEnv.listItems conSpec}
                   :: datadeclList
                  )
              )
              (TypID.Map.empty, nil)
              datadeclList
        fun eqTfun tfun =
            case tfun of
              T.TFUN_DEF {iseq,...} => iseq
            | T.TFUN_VAR (ref tfunkind) => 
              (case tfunkind of
                 T.TFV_SPEC {iseq,...} => iseq
               | T.TFV_DTY {id,...} => 
                 (case TypID.Map.find(eqEnv, id) of
                    SOME eqref => !eqref
                  | NONE => T.tfunIseq tfun)
               | T.TFUN_DTY {id,...}  => 
                 (case TypID.Map.find(eqEnv, id) of
                    SOME eqref => !eqref
                  | NONE => T.tfunIseq tfun)
               | T.REALIZED {id, tfun} => eqTfun tfun
               | T.INSTANTIATED {tfun,...} => eqTfun tfun
               | T.FUN_TOTVAR _ => raise bug "FUN_TOTVAR\n"
(*
               | T.FUN_TODUMMY _ => raise bug "FUN_TODUMMY\n"
*)
               | T.FUN_DTY _  => raise bug "FUN_DTY\n"
              )
        fun iseq tvarList ty = admitEqMaker eqTfun tvarList ty
        val changed = ref true
        fun next {iseqRef, conSpec, args, id} = 
            if not (!iseqRef) then ()
            else
              let
                fun admitEqList nil = true
                  | admitEqList (NONE::rest) = admitEqList rest
                  | admitEqList (SOME ty::rest) = 
                    iseq args ty andalso admitEqList rest
              in
                if admitEqList conSpec then ()
                else (iseqRef := false; changed:=true)
              end
        val _ = while !changed do (changed:=false; map next datadeclList)
      in
        ()
      end

  datatype checkConError =
           Arity
         | Name of (string list * string list)
         | Type of string list
         | OK
  datatype checkConRes =
           SUCCESS
         | FAIL of checkConError list
  fun checkConSpec ((formals1, conSpec1), (formals2, conSpec2)) =
      let
        val errors = if List.length formals1 <> List.length formals2 then
                       [Arity]
                     else nil
        val nameList1 =
            SEnv.foldli
            (fn (name,_,nameList1) => 
                case SEnv.find(conSpec2, name) of
                  SOME _ => nameList1
                | NONE => name::nameList1
            )
            nil
            conSpec1
        val nameList2 =
            SEnv.foldli
            (fn (name,_,nameList1) => 
                case SEnv.find(conSpec1, name) of
                  SOME _ => nameList1
                | NONE => name::nameList1
            )
            nil
            conSpec2
        val errors = case (nameList1,nameList2) of
                       (nil,nil) => errors
                     | _ => Name(nameList1, nameList2) :: errors
        val equiv =
            foldl
            (fn (({id=id1,...}:T.tvar,{id=id2,...}:T.tvar), equiv) =>
                TvarID.Map.insert(equiv, id1, id2))
            TvarID.Map.empty
            (ListPair.zip (formals1,formals2))
        val tyerrors =
            SEnv.foldli
            (fn (name, tyopt1, tyerrors) =>
                case SEnv.find(conSpec2, name) of
                  NONE => tyerrors
                | SOME tyopt2 => 
                  (case (tyopt1,tyopt2) of
                     (NONE, NONE) => tyerrors
                   | (SOME _, NONE) => name::tyerrors
                   | (NONE, SOME _) => name::tyerrors
                   | (SOME ty1, SOME ty2) => 
                     if equalTy equiv (ty1, ty2) then tyerrors
                     else name::tyerrors)
            )
            nil
            conSpec1
        val errors = case tyerrors of
                       nil => errors
                     | _ => Type tyerrors :: errors
      in
        case errors of 
          nil => SUCCESS
        | _ => FAIL errors
      end

end
end
