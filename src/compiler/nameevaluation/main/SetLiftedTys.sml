(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : L-001 *)
structure SetLiftedTys :
sig
  val getId : IDCalc.tfunkind ref -> IDCalc.typId
  val setLiftedTysEnv : NameEvalEnv.env
                        -> (Symbol.symbol list * IDCalc.tfunkind ref) list list
  val setLiftedTysSpecEnv : NameEvalEnv.env
                        -> (Symbol.symbol list * IDCalc.tfunkind ref) list list
end
=
struct
local
  fun bug s = Bug.Bug ("SetLiftedTys: " ^ s)
  structure I = IDCalc
  structure IV = NameEvalEnv
  structure TF = TfunVars
  structure U = NameEvalUtils
  structure SCC = SCCFun(TfvMap)
  fun dtysTy tfvKind (ty,set) =
      let
        fun dtys arg = dtysTy tfvKind arg
      in
        case ty of
          I.TYWILD => set
        | I.TYVAR _ => set
        | I.TYRECORD fields =>
          LabelEnv.foldl
            (fn (ty, set) => dtys (ty, set))
            set
            fields
        | I.TYCONSTRUCT {tfun, args} =>
          let
            val set =
                case I.derefTfun tfun of
                  I.TFUN_VAR tfv =>
                  if tfvKind tfv then TfvSet.singleton tfv 
                  else TfvSet.empty
                | _ => TfvSet.empty
          in
            foldl dtys set args
          end
        | I.TYFUNM (tyList, ty2) => foldl dtys (dtys (ty2, set)) tyList
        | I.TYPOLY (kindedTvarList, ty) => dtys (ty, set)
        | I.TYERROR => set
        | I.INFERREDTY _ => set
      end
  fun dtysConSpec tfvKind (conSpec, set) =
      SymbolEnv.foldl
        (fn (tyOpt, set) => 
            case tyOpt of
              NONE => set
            | SOME ty => dtysTy tfvKind (ty, set)
        )
        set
        conSpec
  fun getId tfv =
      case !tfv of
        I.TFUN_DTY{id,...} => id
      | I.TFV_DTY{id,...} => id
      | _ => raise bug "getId: not tfv"
  fun SCCTfvs tfvKind tfvMap =
      let
        fun dependMapTfv (tfv, _, map) =
            case !tfv of
              I.TFV_DTY {conSpec,...} =>
              let
                val targetTfvs = dtysConSpec tfvKind (conSpec, TfvSet.empty)
                val dependSet =
                    TfvSet.foldr
                      (fn (tfv', dependSet) =>
                          if not (TfvMap.inDomain(tfvMap, tfv')) orelse
                             TypID.eq(getId tfv, getId tfv')
                          then dependSet
                          else TfvSet.add(dependSet, tfv')
                      )
                      TfvSet.empty
                      targetTfvs
              in
                TfvMap.insert(map, tfv, dependSet)
              end
(* 2012-7-19 ohori: bug 210_functor.sml:
    dtyKind must be processed
*)
            | I.TFUN_DTY {dtyKind=I.OPAQUE{tfun=I.TFUN_VAR tfv',...},...} =>
              let
                val dependSet = 
                    if TfvMap.inDomain(tfvMap, tfv')
                    then TfvSet.add(TfvSet.empty, tfv')
                    else TfvSet.empty
              in
                TfvMap.insert(map, tfv, dependSet)
              end
            | I.TFUN_DTY {conSpec,...} =>
              let
                val targetTfvs = dtysConSpec tfvKind (conSpec, TfvSet.empty)
                val dependSet = 
                    TfvSet.foldr
                      (fn (tfv', dependSet) =>
                          if not (TfvMap.inDomain(tfvMap, tfv')) orelse
                             TypID.eq(getId tfv, getId tfv')
                          then dependSet
                          else TfvSet.add(dependSet, tfv')
                      )
                      TfvSet.empty
                      targetTfvs
              in
                TfvMap.insert(map, tfv, dependSet)
              end
            | _ =>  raise bug "non dty tfv (1)"
        val dependMap = TfvMap.foldri dependMapTfv TfvMap.empty tfvMap
        fun addEdge (tfv1,dependSet,graph) =
            TfvSet.foldr
              (fn (tfv2, graph) => SCC.addEdge(graph, tfv1, tfv2))
              graph
              dependSet
        val graph =
            TfvMap.foldri
              (fn (tfv,_,graph) =>SCC.addNode(graph, tfv))
              SCC.empty
              tfvMap
        val graph = TfvMap.foldri addEdge graph dependMap
        val tfvListList = SCC.scc graph
      in
        tfvListList
      end

  fun liftedTysTfun (tfun, liftedTys) =
      case I.derefTfun tfun of
        I.TFUN_DEF {longsymbol, iseq, formals=nil, realizerTy=I.TYVAR tvar} =>
        TvarSet.add(liftedTys, tvar)
      | I.TFUN_DEF {longsymbol, iseq, formals, realizerTy} => liftedTys
      | I.TFUN_VAR (ref tfunkind) => liftedTysTfunkind (tfunkind, liftedTys)
  and liftedTysTfunkind (tfunkind, liftedTys) =
      case tfunkind of
        I.TFV_SPEC _ => liftedTys
      | I.TFV_DTY {liftedTys=newLiftedTys,...} =>
        I.liftedTysUnion(liftedTys,newLiftedTys)
      | I.TFUN_DTY {liftedTys=newLiftedTys,...} =>
        I.liftedTysUnion(liftedTys,newLiftedTys)
(* 
      | I.FUN_TOTVAR {tvar,...} => TvarSet.add(liftedTys, tvar)
*)
      | _ => liftedTys
  and liftedTysTy (ty, liftedTys) =
      case ty of
        I.TYWILD => liftedTys
      | I.TYVAR (tvar as {lifted,...}) =>
        if lifted then TvarSet.add(liftedTys, tvar)
        else liftedTys
      | I.TYRECORD fields => 
        LabelEnv.foldl
          (fn (ty, liftedTys) => liftedTysTy (ty, liftedTys))
          liftedTys
          fields
      | I.TYCONSTRUCT {tfun, args} =>
        liftedTysTyList (args, liftedTysTfun (tfun,liftedTys))
      | I.TYFUNM (tyList, ty2) => 
        liftedTysTyList(tyList, liftedTysTy (ty2, liftedTys))
      | I.TYPOLY (kindedTvarList, ty) => liftedTysTy (ty, liftedTys)
      | I.TYERROR => liftedTys
      | I.INFERREDTY _ => liftedTys
  and liftedTysTyList (tyList, liftedTys) = foldr liftedTysTy liftedTys tyList
  fun liftedTysConSpec (conSpec, liftedTys) =
      SymbolEnv.foldl
        (fn (tyOpt, liftedTys) => 
            case tyOpt of
              NONE => liftedTys
            | SOME ty => liftedTysTy(ty, liftedTys))
        liftedTys
        conSpec

  fun setLiftedTysTfvList tfvList =
      let
        val conSpecList =
            map
            (fn tfv =>
                 case !tfv of
                  I.TFV_DTY {conSpec,...} => 
                   conSpec
                | I.TFUN_DTY {conSpec,...} => 
                   conSpec
                | _ =>  raise bug "non dty tfv (2)"
            )
            tfvList
        val liftedTys = foldr liftedTysConSpec I.emptyLiftedTys conSpecList
      in
        app
          (fn (tfv as (ref (I.TFV_DTY{longsymbol, id, iseq, formals, conSpec,...}))) =>
              tfv := I.TFV_DTY{longsymbol=longsymbol,id=id, iseq=iseq, formals=formals,
                               conSpec=conSpec, liftedTys=liftedTys}
            |  (tfv as (ref (I.TFUN_DTY{id,iseq,formals,
                                        dtyKind,
					runtimeTy,
                                        longsymbol,
                                        conIDSet,
                                        conSpec,...}))) =>
               tfv := I.TFUN_DTY{id=id,
                                 iseq=iseq,
				 runtimeTy=runtimeTy,
                                 formals=formals,
                                 longsymbol=longsymbol,
                                 conSpec=conSpec,
                                 conIDSet = conIDSet,
                                 dtyKind=dtyKind,
                                 liftedTys=liftedTys
                                }
            | _ => raise bug "non tfv_dty"
          )
        tfvList
      end

  fun setLiftedTysEnv tfvKind env =
      let
        val IV.ENV{tyE, varE, strE} = env
        val freeTfvs = TF.tfvsEnv tfvKind nil (env, TfvMap.empty)
        val _ = 
            TfvMap.appi
              (fn (tfv as (ref (I.TFV_DTY{longsymbol, id,iseq,formals,conSpec,...})),
                   path) =>
                   tfv := I.TFV_DTY{id=id,
                                    longsymbol=longsymbol,
                                    iseq=iseq,
                                    formals=formals,
                                    conSpec=conSpec,
                                    liftedTys=I.emptyLiftedTys}
                |  (tfv as (ref (I.TFUN_DTY{id,iseq,runtimeTy, formals,
                                            dtyKind,longsymbol,conIDSet,
                                            conSpec,...})),path) =>
                   tfv := I.TFUN_DTY{id=id,
                                     iseq=iseq,
                                     formals=formals,
                                     conSpec=conSpec,
                                     conIDSet = conIDSet,
                                     longsymbol=longsymbol,
				     runtimeTy=runtimeTy,
                                     dtyKind=dtyKind,
                                     liftedTys=I.emptyLiftedTys
                                    }
                | _ => raise bug "non tfv_dty"
              )
              freeTfvs
        val tfvListList = List.rev (SCCTfvs tfvKind freeTfvs)
        val _ = app setLiftedTysTfvList tfvListList
        val pathTfvListList =
            map
              (fn tvfList =>
                  map 
                    (fn tfv => case TfvMap.find(freeTfvs, tfv) of
                                 SOME path => (path, tfv)
                               | _ => raise bug "tfvPathListList"
                    )
                    tvfList
              )
              tfvListList
      in
        pathTfvListList
      end

  fun dtyLists tfvKind env =
      let
        val IV.ENV{tyE, varE, strE} = env
        val freeTfvs = TF.tfvsEnv tfvKind nil (env, TfvMap.empty)
        val tfvListList = List.rev (SCCTfvs tfvKind freeTfvs)
        val pathTfvListList =
            map
              (fn tvfList =>
                  map 
                    (fn tfv => case TfvMap.find(freeTfvs, tfv) of
                                 SOME path => (path, tfv)
                               | _ => raise bug "tfvPathListList"
                    )
                    tvfList
              )
              tfvListList
      in
        pathTfvListList
      end
in
  val getId = getId
  val setLiftedTysEnv = setLiftedTysEnv TF.dtyKind
  and setLiftedTysSpecEnv = setLiftedTysEnv TF.sigDtyKind
  val dtyListsEnv = dtyLists TF.dtyKind
  and dtyListsSpecEnv = dtyLists TF.sigDtyKind
end
end
