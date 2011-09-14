(* the initial error code of this file : L-001 *)
structure SetLiftedTys =
struct
local
  fun bug s = Control.Bug ("SetLiftedTys: " ^ s)
  structure I = IDCalc
  structure IV = NameEvalEnv
  structure TF = TfunVars
  structure T = IDTypes
  structure U = NameEvalUtils
  structure SCC = SCCFun(TfvMap)
  fun dtysTy tfvKind (ty,set) =
      let
        fun dtys arg = dtysTy tfvKind arg
      in
        case ty of
          T.TYWILD => set
        | T.TYVAR _ => set
        | T.TYRECORD fields =>
          SEnv.foldl
            (fn (ty, set) => dtys (ty, set))
            set
            fields
        | T.TYCONSTRUCT {typ={tfun,...}, args} =>
          let
            val set =
                case T.derefTfun tfun of
                  T.TFUN_VAR tfv =>
                  if tfvKind tfv then TfvSet.singleton tfv 
                  else TfvSet.empty
                | _ => TfvSet.empty
          in
            foldl dtys set args
          end
        | T.TYFUNM (tyList, ty2) => foldl dtys (dtys (ty2, set)) tyList
        | T.TYPOLY (kindedTvarList, ty) => dtys (ty, set)
        | T.TYERROR => set
      end
  fun dtysConSpec tfvKind (conSpec, set) =
      SEnv.foldl
        (fn (tyOpt, set) => 
            case tyOpt of
              NONE => set
            | SOME ty => dtysTy tfvKind (ty, set)
        )
        set
        conSpec
  fun getId tfv =
      case !tfv of
        T.TFUN_DTY{id,...} => id
      | T.TFV_DTY{id,...} => id
      | _ => raise bug "getId: not tfv"
  fun SCCTfvs tfvKind tfvMap =
      let
        fun dependMapTfv (tfv, _, map) =
            case !tfv of
              T.TFV_DTY {conSpec,...} =>
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
            | T.TFUN_DTY {conSpec,...} =>
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
      case T.derefTfun tfun of
        T.TFUN_DEF {iseq, formals, realizerTy} => raise bug "DEF"
      | T.TFUN_VAR (ref tfunkind) =>
        liftedTysTfunkind (tfunkind, liftedTys)
  and liftedTysTfunkind (tfunkind, liftedTys) =
      case tfunkind of
        T.TFV_SPEC _ => liftedTys
      | T.TFV_DTY {liftedTys=newLiftedTys,...} =>
        T.liftedTysUnion(liftedTys,newLiftedTys)
      | T.TFUN_DTY {liftedTys=newLiftedTys,...} =>
        T.liftedTysUnion(liftedTys,newLiftedTys)
      | T.FUN_TOTVAR {tvar,...} => TvarSet.add(liftedTys, tvar)
      | _ => liftedTys
  and liftedTysTy (ty, liftedTys) =
      case ty of
        T.TYWILD => liftedTys
      | T.TYVAR (tvar as {lifted,...}) =>
        if lifted then TvarSet.add(liftedTys, tvar)
        else liftedTys
      | T.TYRECORD fields => 
        SEnv.foldl
          (fn (ty, liftedTys) => liftedTysTy (ty, liftedTys))
          liftedTys
          fields
      | T.TYCONSTRUCT {typ={tfun,...}, args} =>
        liftedTysTyList (args, liftedTysTfun (tfun,liftedTys))
      | T.TYFUNM (tyList, ty2) => 
        liftedTysTyList(tyList, liftedTysTy (ty2, liftedTys))
      | T.TYPOLY (kindedTvarList, ty) => liftedTysTy (ty, liftedTys)
      | T.TYERROR => liftedTys
  and liftedTysTyList (tyList, liftedTys) = foldr liftedTysTy liftedTys tyList
  fun liftedTysConSpec (conSpec, liftedTys) =
      SEnv.foldl
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
                  T.TFV_DTY {conSpec,...} => 
                   conSpec
                | T.TFUN_DTY {conSpec,...} => 
                   conSpec
                | _ =>  raise bug "non dty tfv (2)"
            )
            tfvList
        val liftedTys = foldr liftedTysConSpec T.emptyLiftedTys conSpecList
      in
        app
          (fn (tfv as (ref (T.TFV_DTY{id, iseq, formals, conSpec,...}))) =>
              tfv := T.TFV_DTY{id=id, iseq=iseq, formals=formals,
                               conSpec=conSpec, liftedTys=liftedTys}
            |  (tfv as (ref (T.TFUN_DTY{id,iseq,formals,
                                        dtyKind,
                                        conSpec,...}))) =>
               tfv := T.TFUN_DTY{id=id,
                                 iseq=iseq,
                                 formals=formals,
                                 conSpec=conSpec, 
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
(*
        val _ = U.print "freeTfvs in setLiftedTysEnv\n"
        val _ = TfvMap.appi
                  (fn (tfv,path) => (U.printPath path;
                                     U.print ":";
                                     U.printTfv tfv
                                    )
                  )
                  freeTfvs
        val _ = U.print "\n"
*)
        val _ = 
            TfvMap.appi
              (fn (tfv as (ref (T.TFV_DTY{id,iseq,formals,conSpec,...})),
                   path) =>
                   tfv := T.TFV_DTY{id=id,
                                    iseq=iseq,
                                    formals=formals,
                                    conSpec=conSpec,
                                    liftedTys=T.emptyLiftedTys}
                |  (tfv as (ref (T.TFUN_DTY{id,iseq,formals,
                                            dtyKind,
                                            conSpec,...})),path) =>
                   tfv := T.TFUN_DTY{id=id,
                                     iseq=iseq,
                                     formals=formals,
                                     conSpec=conSpec, 
                                     dtyKind=dtyKind,
                                     liftedTys=T.emptyLiftedTys
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
