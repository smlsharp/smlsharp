(**
 * type context manipulation utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TypeContextUtils.sml,v 1.47 2006/03/02 12:51:54 bochao Exp $
 *)
structure TypeContextUtils =
struct
  (****************************************)
 local 
   open Types TypesUtils
   structure TC = TypeContext
(*
   structure TCalcU = TypedCalcUtils 
   structure TCalc  = TypedCalc
*)
 in
  type tyConSubst = tyBindInfo ID.Map.map
  exception ExTySpecInstantiatedWithNonEqTyBindInfo of string

  fun substTyConIdInId tyConIdSubst id = 
      case ID.Map.find(tyConIdSubst,id) of
        SOME newId => newId
      | NONE => id

  fun substTyConIdInTy visited tyConIdSubst ty =
      TypeTransducer.transTyPreOrder
      (fn (ty, visited) =>
          case ty of
            TYVARty (tvar as ref (TVAR tvKind)) => 
            let
              val (visited, tvKind) =
                  substTyConIdInTvKind visited tyConIdSubst tvKind
              val _  = tvar := TVAR tvKind
            in
              (ty, visited, true)
            end
          | CONty {tyCon, args} => 
            let
              val (visited, tyCon) =
                  substTyConIdInTyCon visited tyConIdSubst tyCon
            in (CONty {tyCon=tyCon, args = args}, visited, true)
            end
          | POLYty {boundtvars, body} => 
            let
              val (visited, boundtvars) = 
                  IEnv.foldli
                      (fn (index, btvKind, (visited, boundtvars)) =>
                          let
                            val (visited, btvKind) =
                                substTyConIdInBtvKind
                                    visited tyConIdSubst btvKind
                          in
                            (visited, IEnv.insert(boundtvars, index, btvKind))
                          end)
                      (visited, IEnv.empty)
                      boundtvars
            in
              (POLYty{boundtvars = boundtvars, body = body}, visited, true)
            end
          | _ => (ty, visited, true))
      visited
      ty

  and substTyConIdInTvKind visited tyConIdSubst {id, recKind, eqKind, tyvarName} = 
    let
      val (visited, recKind) =
        case recKind of 
          UNIV => (visited, UNIV)
        | REC tySEnvMap => 
          let
              val (visited,tySEnvMap) = 
                  (SEnv.foldli
                       (fn (label, ty, (visited, tySEnvMap)) =>
                           let
                               val (ty, visited) = substTyConIdInTy visited tyConIdSubst ty
                           in
                               (visited, SEnv.insert(tySEnvMap, label, ty))
                           end)
                       (visited, SEnv.empty)
                       tySEnvMap)
          in 
              (visited,REC tySEnvMap)
          end
        | OVERLOADED tys => 
          let
              val (visited,tys) = 
                  (foldr
                       (fn (ty, (visited, tys)) =>
                           let
                               val (ty, visited) = substTyConIdInTy visited tyConIdSubst ty
                           in
                               (visited, ty :: tys)
                           end)
                       (visited, nil)
                       tys)
          in 
              (visited,OVERLOADED tys)
          end
    in
      (
       visited,
       {id=id, 
        recKind = recKind,
        eqKind = eqKind,
        tyvarName = tyvarName}
       )
    end

  and substTyConIdInBtvKind visited tyConIdSubst {index, recKind, eqKind} = 
    let
      val (visited, recKind) =
        case recKind of 
          UNIV => (visited, UNIV)
        | REC tySEnvMap => 
          let
              val (visited,tySEnvMap) = 
                  (SEnv.foldli
                       (fn (label, ty, (visited, tySEnvMap)) =>
                           let
                               val (ty, visited) = substTyConIdInTy visited tyConIdSubst ty
                           in
                               (visited, SEnv.insert(tySEnvMap, label, ty))
                           end)
                       (visited, SEnv.empty)
                       tySEnvMap)
          in
              (visited, REC tySEnvMap)
          end
        | OVERLOADED tys => 
          let
              val (visited,tys) = 
                  (foldr
                       (fn (ty, (visited, tys)) =>
                           let
                               val (ty, visited) = substTyConIdInTy visited tyConIdSubst ty
                           in
                               (visited, ty :: tys)
                           end)
                       (visited, nil)
                       tys)
          in
              (visited, OVERLOADED tys)
          end
    in
      (
       visited,
       {
        index=index, 
        recKind = recKind,
        eqKind = eqKind
        }
       )
    end

  and substTyConIdInTyCon visited 
                          tyConIdSubst 
                          (tyCon as {name, strpath, abstract, 
                                     tyvars, id, eqKind, 
                                     boxedKind, datacon}) 
    =
      let 
        val visited = 
            if ID.Set.member(visited, id) then
              visited
            else
              let 
                val visited = ID.Set.add(visited,id)
                val (visited, varEnv) = substTyConIdInVarEnv visited tyConIdSubst (!datacon)
              in
                (datacon := varEnv;
                 visited)
              end
       in
          (visited,
           {
            name = name, 
            strpath = strpath,
            abstract = abstract,
            tyvars = tyvars,
            id = substTyConIdInId tyConIdSubst id,
            eqKind = eqKind,
            boxedKind = boxedKind,
            datacon = datacon
            }
           )
      end

  and substTyConIdInTyFun visited tyConIdSubst {name, tyargs, body} =
    let
      val (visited, tyargs) =
           IEnv.foldri
           (fn (index, btvKind, (visited, tyargs)) =>
               let
                 val (visited, btvKind) = substTyConIdInBtvKind visited tyConIdSubst btvKind
               in
                 (visited, IEnv.insert(tyargs, index, btvKind))
               end)
           (visited, IEnv.empty)
           tyargs
      val (body, visited) = substTyConIdInTy visited tyConIdSubst body
    in
      (visited,
       {
        name = name, 
        tyargs = tyargs, 
        body = body
        }
       )
    end

  and substTyConIdInSpec tyConIdSubst 
                         (tyspec as {name, id, strpath, eqKind, tyvars, boxedKind}) =
       {name=name, 
        id= substTyConIdInId tyConIdSubst id, 
        strpath = strpath, 
        eqKind = eqKind, 
        tyvars = tyvars,
        boxedKind = boxedKind
        }

  and substTyConIdInTyBindInfo visited tyConIdSubst tyBindInfo =
    case tyBindInfo of
      TYCON (tyCon as {name,...})  => 
        let
          val (visited, tyCon) = substTyConIdInTyCon visited tyConIdSubst tyCon
        in
          (visited, TYCON tyCon)
        end
    | TYFUN tyFun => 
        let
          val (visited, tyFun) = substTyConIdInTyFun visited tyConIdSubst tyFun
        in
          (visited, TYFUN tyFun)
        end
    | TYSPEC {spec = spec , impl = impl}=> 
      case impl of
        NONE => (visited, TYSPEC {spec = substTyConIdInSpec tyConIdSubst spec, impl = NONE})
      | SOME tyBindInfo => 
        let
          val (visited,tyBindInfo) = substTyConIdInTyBindInfo visited tyConIdSubst tyBindInfo
        in
          (visited, TYSPEC {spec = substTyConIdInSpec tyConIdSubst spec, impl = SOME tyBindInfo})
        end

  and substTyConIdInTyConEnv visited tyConIdSubst tyConEnv =
    let
      val (visited, tyConEnv) =
          SEnv.foldli
          (fn (label, tyCon, (visited, tyConEnv)) =>
              let
                val (visited, tyCon) = substTyConIdInTyBindInfo visited tyConIdSubst tyCon
              in
                (visited, SEnv.insert(tyConEnv, label, tyCon))
              end)
          (visited, SEnv.empty)
          tyConEnv
    in
      (visited, tyConEnv)
    end

  and substTyConIdInVarEnv visited tyConIdSubst varEnv =
      SEnv.foldli
      (fn (label, idstate, (visited, varEnv)) =>
          case idstate of
            CONID {name, strpath, funtyCon, ty, tag, tyCon} =>
              let
                val (ty, visited) = substTyConIdInTy visited tyConIdSubst ty
                val (visited, tyCon) = substTyConIdInTyCon visited tyConIdSubst tyCon
              in
                (visited,
                 SEnv.insert(
                             varEnv,
                             label,
                             CONID{name=name, 
                                   strpath=strpath, 
                                   funtyCon=funtyCon, 
                                   ty = ty,
                                   tag = tag,
                                   tyCon = tyCon}
                             )
                 )
              end
          | VARID {name,ty,strpath} =>
            let
                val (ty, visited) = substTyConIdInTy visited tyConIdSubst ty
            in
                (visited,
                 SEnv.insert(
                             varEnv,
                             label,
                             VARID{name=name,
                                   strpath=strpath,
                                   ty=ty}
                             )
                 )
            end
          | x => (visited, SEnv.insert(varEnv,label,x))
      )
      (visited, SEnv.empty)
      varEnv

  and substTyConIdInEnv visited tyConIdSubst (tyConEnv, varEnv, strEnv) =
    let
      val (visited, tyConEnv) = substTyConIdInTyConEnv visited tyConIdSubst tyConEnv
      val (visited, varEnv) = substTyConIdInVarEnv visited tyConIdSubst varEnv
      val (visited, strEnv) = substTyConIdInStrEnv visited tyConIdSubst strEnv
    in
      (
       visited,
       (tyConEnv, 
        varEnv,
        strEnv)
       )
    end

  and substTyConIdInStrEnv visited tyConIdSubst strEnv =
    SEnv.foldri
    (fn
     (label, STRUCTURE {id, name, strpath, env = Env, ...}, (visited, strEnv))
     =>
     let
       val (visited, Env) = substTyConIdInEnv visited tyConIdSubst Env
       val strPathInfo = {id = id, name = name, strpath = strpath, env = Env}
     in
       (visited, SEnv.insert(strEnv, label, STRUCTURE strPathInfo))
     end)
    (visited, SEnv.empty)
    strEnv

  fun substTyConInTy (visited:ID.Set.set) (tyConSubst : tyConSubst) ty =
      TypeTransducer.transTyPreOrder
        (fn (ty,visited) =>
            case ty of
              TYVARty (tvar as ref (TVAR tvKind)) =>
              let
                val (visited,tvKind) =
                    substTyConInTvKind visited tyConSubst tvKind
                val _ = tvar := TVAR tvKind
              in
                (ty,visited,true)
              end
            | CONty {tyCon as {name, strpath, id, ...}, args} => 
              let
                val newArgs = 
                    map (fn arg =>
                            let
                              val (newTy,visited) =
                                  substTyConInTy visited tyConSubst arg
                            in
                              newTy
                            end)
                        args
              in
                case ID.Map.find(tyConSubst,id) of
                  SOME (TYFUN tyFun) => 
                  let
                    val newTy = betaReduceTy (tyFun,newArgs)
                  in
                    (newTy,visited,false)
                  end
                | SOME _ => 
                  let
                    val (visited,tyCon) = 
                        substTyConInTyCon visited tyConSubst tyCon
                  in
                    (CONty {tyCon=tyCon, args = newArgs},visited,true)
                  end
                | NONE => (ty,visited,true)
              end
            | ABSSPECty (specTy as CONty{tyCon as {name,strpath,id,...},...}, implTy) =>
              (
               case specTy of
                 CONty {tyCon as {name,strpath,id,...},args} =>
                 ( 
                  let
                    val (newArgs,visited) =
                        foldl (fn (arg,(newArgs,visited)) =>
                                  let
                                    val (newTy,visited) =
                                        substTyConInTy visited tyConSubst arg
                                  in
                                    (newArgs @ [newTy],visited)
                                  end)
                              (nil,visited)
                              args
                  in
                    case ID.Map.find(tyConSubst, #id tyCon) of
                      SOME (TYSPEC {spec = {name, id, strpath, eqKind, tyvars, boxedKind},
                                    impl = implOpt}) 
                      => 
                      let
                        val newSpecTy = CONty {tyCon = {
                                                        name = name,
                                                        strpath = strpath,
                                                        abstract = false, 
                                                        tyvars = tyvars,
                                                        id = id,
                                                        eqKind = ref eqKind,
                                                        boxedKind = ref boxedKind,
                                                        datacon = ref SEnv.empty
                                                        },
                                               args = newArgs}
                      in 
                        case implOpt of
                          NONE => (SPECty(newSpecTy), visited, false)
                        | SOME impl =>
                          case (peelTySpec impl) of
                            TYFUN tyFun =>
                            (
                             ABSSPECty(newSpecTy, (betaReduceTy (tyFun,newArgs))), 
                             visited, 
                             false
                             )
                          | TYCON tyCon =>
                            (
                             ABSSPECty(
                                       newSpecTy,
                                       (CONty {tyCon = tyCon,args = newArgs})
                                       ), 
                             visited, 
                             false
                             )
                          | TYSPEC _ => raise Control.Bug "TYSPEC should disappear"
                      end
                    | SOME (TYFUN tyFun) => (* type function, type con : instantiate to real type*)
                      let
                        val newTy = betaReduceTy (tyFun,newArgs)
                      in
                        (newTy, visited, false)
                      end
                    | SOME (TYCON tyCon) =>
                      let
                        val newTy = CONty{tyCon = tyCon, args = newArgs}
                      in
                        (newTy, visited, false)
                      end
                    | NONE => 
                      let
                        val (implTy', visited) = substTyConInTy visited tyConSubst implTy
                      in
                        (ABSSPECty (CONty{tyCon = tyCon, args = newArgs}, implTy'), visited, false)
                      end
                  end
                 )
               | _ => raise Control.Bug "illegal ABSSPECty"
               )
            | SPECty ty =>
              (case ty of
                 CONty {tyCon as {name, strpath, id, ...}, args} =>
                 let
                   val (newArgs, visited) =
                       foldl (fn (arg,(newArgs,visited)) =>
                                 let
                                   val (newTy,visited) =
                                       substTyConInTy visited tyConSubst arg
                                 in
                                   (newArgs @ [newTy],visited)
                                 end)
                             (nil,visited)
                             args
                 in
                   case ID.Map.find(tyConSubst, id) of
                     SOME (TYSPEC {spec = {name, id, strpath, eqKind, tyvars, boxedKind},
                                   impl = implOpt}) 
                     => 
                     let
                       val newSpecTy = CONty {tyCon = {
                                                       name = name,
                                                       strpath = strpath,
                                                       abstract = false, 
                                                       tyvars = tyvars,
                                                       id = id,
                                                       eqKind = ref eqKind,
                                                       boxedKind = ref boxedKind,
                                                       datacon = ref SEnv.empty
                                                       },
                                              args = newArgs}
                     in 
                       case implOpt of
                         NONE => (SPECty(newSpecTy), visited, false)
                       | SOME impl =>
                         case (peelTySpec impl) of
                           TYFUN tyFun =>
                           (
                            ABSSPECty(newSpecTy, (betaReduceTy (tyFun,newArgs))), 
                            visited, 
                            false
                            )
                         | TYCON tyCon =>
                           (
                            ABSSPECty(
                                      newSpecTy,
                                      (CONty {tyCon = tyCon,args = newArgs})
                                      ), 
                            visited, 
                            false
                            )
                         | TYSPEC _ => raise Control.Bug "TYSPEC should disappear"
                     end
                   | SOME (TYFUN tyFun) => 
                     let
                       val newTy = betaReduceTy (tyFun,newArgs)
                     in
                       (newTy, visited, false)
                     end
                   | SOME (TYCON tyCon) =>
                     let
                       val newTy = CONty{tyCon = tyCon, args = newArgs}
                     in
                       (newTy, visited, false)
                     end
                   | NONE => 
                     (SPECty(CONty{tyCon = tyCon, args = newArgs}), visited, false)
                 end
               | _ => 
                 raise 
                   Control.Bug 
                     "illegal SPECty: should be SPECty(CONty..)"
            )
            | POLYty {boundtvars, body} =>
              let
                val (visited, boundtvars) = 
                    IEnv.foldli
                      (fn (index, btvKind, (visited, boundtvars)) =>
                          let
                            val (visited, btvKind) =
                                substTyConInBtvKind visited 
                                                    tyConSubst
                                                    btvKind
                          in
                            (visited, IEnv.insert(boundtvars, index, btvKind))
                          end)
                      (visited, IEnv.empty)
                      boundtvars
              in
                (POLYty{boundtvars = boundtvars, body = body}, visited, true)
              end
            | _ => (ty,visited,true))
        visited
        ty
        
  and substTyConInTvKind visited (tyConSubst : tyConSubst) {id, recKind, eqKind, tyvarName} = 
    let
      val (visited, recKind) =
        case recKind of 
          UNIV => (visited, UNIV)
        | REC tySEnvMap => 
          let
              val (visited,tySEnvMap) = 
                  (SEnv.foldli
                       (fn (label, ty, (visited, tySEnvMap)) =>
                           let
                             val (ty, visited) = substTyConInTy visited tyConSubst ty
                           in
                               (visited, SEnv.insert(tySEnvMap, label, ty))
                           end)
                       (visited, SEnv.empty)
                       tySEnvMap)
          in 
              (visited,REC tySEnvMap)
          end
        | OVERLOADED tys => 
          let
              val (visited,tys) = 
                  (foldr
                       (fn (ty, (visited, tys)) =>
                           let
                             val (ty, visited) = substTyConInTy visited tyConSubst ty
                           in
                               (visited, ty :: tys)
                           end)
                       (visited, nil)
                       tys)
          in 
              (visited,OVERLOADED tys)
          end
    in
      (
       visited,
       {id=id, 
        recKind = recKind,
        eqKind = eqKind,
        tyvarName = tyvarName}
       )
    end
  and substTyConInBtvKind visited (tyConSubst:tyConSubst) {index, recKind, eqKind} = 
    let
      val (visited, recKind) =
        case recKind of 
          UNIV => (visited, UNIV)
        | REC tySEnvMap => 
          let
              val (visited,tySEnvMap) = 
                  (SEnv.foldli
                       (fn (label, ty, (visited, tySEnvMap)) =>
                           let
                             val (ty, visited) = substTyConInTy visited tyConSubst ty
                           in
                               (visited, SEnv.insert(tySEnvMap, label, ty))
                           end)
                       (visited, SEnv.empty)
                       tySEnvMap)
          in
              (visited, REC tySEnvMap)
          end
        | OVERLOADED tys => 
          let
              val (visited, tys) = 
                  (foldr
                       (fn (ty, (visited, tys)) =>
                           let
                             val (ty, visited) = substTyConInTy visited tyConSubst ty
                           in
                               (visited, ty :: tys)
                           end)
                       (visited, nil)
                       tys)
          in
              (visited, OVERLOADED tys)
          end
    in
      (
       visited,
       {
        index=index, 
        recKind = recKind,
        eqKind = eqKind
        }
       )
    end

  and substTyConInTyFun visited (tyConSubst:tyConSubst) {name, tyargs, body} =
    let
      val (visited, tyargs) =
           IEnv.foldri
           (fn (index, btvKind, (visited, tyargs)) =>
               let
                 val (visited, btvKind) = substTyConInBtvKind visited tyConSubst btvKind
               in
                 (visited, IEnv.insert(tyargs, index, btvKind))
               end)
           (visited, IEnv.empty)
           tyargs
      val (body, visited) = substTyConInTy visited tyConSubst body
    in
      (visited,
       {
        name = name, 
        tyargs = tyargs, 
        body = body
        }
       )
    end

  and substTyConInTyBindInfo visited (tyConSubst:tyConSubst) tyBindInfo =
    case tyBindInfo of
      TYCON (tyCon) => 
      let
        val (visited,tyCon) = substTyConInTyCon visited tyConSubst tyCon
      in 
        (visited,TYCON (tyCon))
      end
    | TYFUN tyFun => 
      let
        val (visited,tyFun) = substTyConInTyFun visited tyConSubst tyFun
      in 
        (visited,TYFUN tyFun)
      end
    | TYSPEC {spec = spec as {name, id, strpath, eqKind, tyvars, boxedKind},
              impl = implOpt
              }
      => 
      let
        val newImplOpt = 
            case implOpt of
              NONE => NONE 
            | SOME impl => 
              let
                val (visited, impl) = 
                    substTyConInTyBindInfo visited tyConSubst impl
              in
                SOME impl
              end
      in
        case ID.Map.find(tyConSubst, id) of
          NONE => (visited, TYSPEC{spec = spec, impl = newImplOpt})
        | SOME tyBindInfo2 => 
          (visited,
           if (eqKind = EQ) andalso not (admitEqTyBindInfo tyBindInfo2) then
             raise ExTySpecInstantiatedWithNonEqTyBindInfo(name)
           else
             tyBindInfo2
          )
      end

  and substTyConInTyCon 
        (visited:ID.Set.set)
        (tyConSubst : tyConSubst) 
        (tyCon as {name,strpath,abstract,tyvars,id=originId,eqKind,boxedKind,datacon} : tyCon) 
        =
        case ID.Map.find(tyConSubst, originId) of
          NONE => 
          if ID.Set.member(visited,originId) then
            (visited,tyCon)
          else
            let
              val visited = ID.Set.add(visited,originId)
              val (visited,data) = substTyConInVarEnv visited tyConSubst (!datacon)
              val _ = datacon := data
            in
              (visited,tyCon)
            end
        | SOME (TYFUN (tyFun as {name,tyargs,body})) =>
          let
            val tyName as {name,tyvars,id,eqKind,...} = tyFunToTyName tyFun
            val newTyCon : tyCon = 
                {name = name, strpath = strpath, abstract = abstract, tyvars = tyvars,
                 id = id, eqKind = eqKind, boxedKind = ref (boxedKindOptOfType body), 
                 datacon = ref SEnv.empty}
            val tyConSubst = ID.Map.insert(tyConSubst,originId,TYCON newTyCon)
            val (visited,data) = substTyConInVarEnv visited tyConSubst (!datacon)
            val _ = (#datacon newTyCon := data)
          in
            (visited,newTyCon)
          end 
        | SOME (TYCON tyCon) => (visited,tyCon)
        | SOME (TYSPEC {
                        spec = {name, id, strpath, eqKind, tyvars, boxedKind},
                        impl = impl
                        }
                ) 
          =>
          let
            val newTyCon : tyCon =
                {
                 name = name,
                 strpath = strpath,
                 abstract = abstract,
                 tyvars = tyvars,
                 id = id,
                 eqKind = ref eqKind,
                 boxedKind = ref boxedKind,
                 datacon = ref SEnv.empty
                 }
            val tyConSubst = ID.Map.singleton(originId, TYCON newTyCon)
            val (_, data) = substTyConInVarEnv ID.Set.empty tyConSubst (!datacon)
            val _ = #datacon newTyCon := data
          in
            (visited, newTyCon)
          end
                                
  and substTyConInTyConEnv  visited (tyConSubst:tyConSubst) tyConEnv =
      SEnv.foldli (fn (tyConName,tyBindInfo,(visited,newTyConEnv)) =>
                      let
                        val (visited,tyBindInfo) = 
                            substTyConInTyBindInfo  visited tyConSubst tyBindInfo
                      in
                        (visited,
                         SEnv.insert(newTyConEnv,
                                     tyConName,
                                     tyBindInfo)
                         )
                      end
                  )
                  (visited,SEnv.empty)
                  tyConEnv

  and substTyConInVarEnv visited (tyConSubst:tyConSubst) varEnv =
      SEnv.foldli
        (fn (label, idstate, (visited, varEnv)) =>
          case idstate of
            CONID {name, strpath, funtyCon, ty, tag, tyCon} =>
              let
                val (ty, visited) = substTyConInTy visited tyConSubst ty
                val (visited, tyCon) = substTyConInTyCon visited tyConSubst tyCon
              in
                (visited,
                 SEnv.insert(
                             varEnv,
                             label,
                             CONID{name=name, 
                                   strpath=strpath, 
                                   funtyCon=funtyCon, 
                                   ty = ty,
                                   tag = tag,
                                   tyCon = tyCon}
                             )
                 )
              end
          | VARID {name,ty,strpath} =>
            let
              val (ty, visited) = substTyConInTy visited tyConSubst ty
            in
                (visited,
                 SEnv.insert(
                             varEnv,
                             label,
                             VARID{name=name,
                                   strpath=strpath,
                                   ty=ty}
                             )
                 )
            end
          | x => (visited, SEnv.insert(varEnv,label,x))
      )
      (visited, SEnv.empty)
      varEnv

                  
  and substTyConInStrEnv  visited (tyConSubst:tyConSubst) strEnv =
        SEnv.foldri
          (fn
           (label, STRUCTURE {id, name, strpath, env = Env, ...}, (visited, strEnv))
           =>
           let
             val (visited, Env) = substTyConInEnv visited tyConSubst Env
             val strPathInfo = {id = id, name = name, strpath = strpath, env = Env}
           in
             (visited, SEnv.insert(strEnv, label, STRUCTURE strPathInfo))
           end)
          (visited, SEnv.empty)
          strEnv
      
  and substTyConInEnv  visited (tyConSubst:tyConSubst) (tyConEnv, varEnv, strEnv) =
      let
        val (visited,tyConEnv) = substTyConInTyConEnv visited tyConSubst tyConEnv
        val (visited,varEnv) = substTyConInVarEnv visited tyConSubst varEnv
        val (visited,strEnv) = substTyConInStrEnv  visited tyConSubst strEnv
      in
        (visited,(tyConEnv,varEnv,strEnv))
      end

  (* this utility function makes sense only when applied to Env *)
  and substTyConInContext 
        (tyConSubst : tyConSubst)
        ({tyConEnv, varEnv, strEnv, sigEnv, funEnv} : TC.context) = 
        let
          val (visited,tyConEnv) = substTyConInTyConEnv ID.Set.empty tyConSubst tyConEnv
          val (visited,varEnv) = substTyConInVarEnv visited tyConSubst varEnv
          val (visited,strEnv) = substTyConInStrEnv visited tyConSubst strEnv
        in
          {
           tyConEnv =  tyConEnv,
           varEnv =  varEnv,
           strEnv =  strEnv,
           sigEnv =  sigEnv,
           funEnv =  funEnv
           } : TC.context
        end

  fun substTyConInSizeTagEnv visited tyConSubst (Env as (tyConSizeTagEnv, varEnv, strSizeTagEnv)) = 
      let
        val (visited,tyConSizeTagEnv) = 
            substTyConInTyConSizeTagEnv visited tyConSubst tyConSizeTagEnv
        val (visited,varEnv) = 
            substTyConInVarEnv visited tyConSubst varEnv
        val (visited,strSizeTagEnv) = 
            substTyConInStrSizeTagEnv  visited tyConSubst strSizeTagEnv
      in
        (visited,(tyConSizeTagEnv, varEnv, strSizeTagEnv))
      end

  and substTyConInTyConSizeTagEnv visited tyConSubst tyConSizeTagEnv =
      SEnv.foldli (fn (tyConName,{tyBindInfo, sizeInfo, tagInfo}, (visited, newTyConSizeTagEnv)) =>
                      let
                        val (visited,tyBindInfo) = 
                            substTyConInTyBindInfo  visited tyConSubst tyBindInfo
                      in
                        (visited,
                         SEnv.insert(newTyConSizeTagEnv,
                                     tyConName,
                                     {tyBindInfo = tyBindInfo,
                                      sizeInfo = sizeInfo,
                                      tagInfo = tagInfo})
                         )
                      end
                  )
                  (visited,SEnv.empty)
                  tyConSizeTagEnv

  and substTyConInStrSizeTagEnv visited tyConSubst strSizeTagEnv = 
        SEnv.foldri
          (fn
           (label, STRSIZETAG {id, name, strpath, env = Env, ...}, (visited, strEnv))
           =>
           let
             val (visited, Env) = substTyConInSizeTagEnv visited tyConSubst Env
             val strPathInfo = {id = id, name = name, strpath = strpath, env = Env}
           in
             (visited, SEnv.insert(strEnv, label, STRSIZETAG strPathInfo))
           end)
          (visited, SEnv.empty)
          strSizeTagEnv

  fun substTyConInTypeEnv tyConSubst (typeEnv as {tyConSizeTagEnv, varEnv, strSizeTagEnv}) =
      let
        val (visited,tyConSizeTagEnv) = 
            substTyConInTyConSizeTagEnv ID.Set.empty tyConSubst tyConSizeTagEnv
        val (visited,varEnv) = substTyConInVarEnv visited tyConSubst varEnv
        val (visited,strSizeTagEnv) = 
            substTyConInStrSizeTagEnv visited tyConSubst strSizeTagEnv
      in
        {tyConSizeTagEnv = tyConSizeTagEnv, 
         varEnv = varEnv,
         strSizeTagEnv = strSizeTagEnv}
      end

  (*********** update strpath field ***********************************************************)
  local
        structure PathOrd:ordsig =
        struct 
            local 
              open Path
            in
              type ord_key = path
              fun compare (p1,p2) = 
                  case (p1,p2) of
                    (NilPath,NilPath) => EQUAL
                  | (PStructure _ ,NilPath) => GREATER
                  | (NilPath,PStructure _ ) => LESS
                  | (PStructure(id1,name1,p1),PStructure(id2,name2,p2)) =>
                    case String.compare(name1,name2) of
                      EQUAL => compare (p1,p2)
                    | other => other
            end
        end
        structure PathMap = BinaryMapFn(PathOrd)
        type pathMap = path PathMap.map
  in
       (*
        * accumulate all the tyCon ID defined in the introduced Env;
        * accumulate all the possible StrPath mappings
        *)
       fun computeUpdateStrpathCandidateSet (strPathPair as {newStrpath,currentStrpath}) E =
           let
             fun computeTyConIdSetForTyConEnv tyConEnv =
                 SEnv.foldl (
                             fn (tyBindInfo,tyConIdSet) =>
                                case tyBindInfo of
                                  TYCON ({id,...}) =>
                                  ID.Set.add(tyConIdSet,id)
                                | TYFUN ({body = ty,...}) => 
                                  ( case ty of
                                      ALIASty(CONty({tyCon = {id,...},...}),_) =>
                                      ID.Set.add(tyConIdSet,id)
                                    | _ => 
                                      raise Control.Bug
                                              "typesutils:computeTyConIdSetForTyConEnv:AliasTy ill-formed."
                                  )
                                | TYSPEC ({spec = {id,...},impl}) =>
                                  ID.Set.add(tyConIdSet,id)
                            )
                            ID.Set.empty
                            tyConEnv
             fun computeContextForStrEnv ({newStrpath,currentStrpath}) strEnv =
                 SEnv.foldl (
                             fn ((STRUCTURE {id,name,strpath,env}),(tyConIdSet,strPathMap)) =>
                                let
                                  val (tyConEnv,varEnv,strEnv) = env
                                  val tyConIdSet1 = computeTyConIdSetForTyConEnv tyConEnv
                                  val newStrpathPair =
                                      { 
                                       newStrpath = Path.appendPath(newStrpath,id,name),
                                       currentStrpath = Path.appendPath(currentStrpath,id,name) 
                                       }
                                  val strPathMap1 = PathMap.singleton
                                                      (#currentStrpath newStrpathPair,
                                                       #newStrpath  newStrpathPair)
                                  val (tyConIdSet2,strPathMap2) =
                                      computeContextForStrEnv newStrpathPair strEnv
                                  val newTyConIdSet = ID.Set.union (tyConIdSet1,tyConIdSet2)
                                  val newStrPathMap = PathMap.unionWith #1 (strPathMap1,
                                                                            strPathMap2)
                                in
                                  (ID.Set.union(newTyConIdSet,tyConIdSet),
                                   PathMap.unionWith #1 (newStrPathMap,
                                                         strPathMap)
                                   )
                                end
                                  )
                            (ID.Set.empty,PathMap.empty)
                            strEnv
             val (tyConEnv,varEnv,strEnv) = E
             val strPathMap1 = PathMap.singleton(currentStrpath,newStrpath)
             val tyConIdSet1 = computeTyConIdSetForTyConEnv tyConEnv
             val (tyConIdSet2,strPathMap2) = computeContextForStrEnv strPathPair strEnv
           in
             {
              tyConIdSet = ID.Set.union (tyConIdSet1,tyConIdSet2),
              strPathMap = PathMap.unionWith #1 (strPathMap1,strPathMap2)
              }
           end
             
       (* Several cases need the update:
        * 1. include sigid
        * 2. open strid
        * 3. structure strid1 = strid2
        * 
        * newStrpath : strpath field of introduced type definition will be updated to this.
        * currentStrpath : represents the structure path of the introduced 
        *                  structure or signature by above phrases.
        *) 
       fun updateStrpathInTopEnv 
             (strPathPair as {newStrpath,currentStrpath}) (E as (tyConEnv,varEnv,strEnv)) 
         =
         let
(*           val _ = print "\n **** newStrpath :***\n"
           val _ = print (Path.pathToString(newStrpath))
           val _ = print "\n **** currentStrpath :***\n"
           val _ = print (Path.pathToString(currentStrpath))
           val _ = print "\n"
*)
           val updateCandidateSet = 
               computeUpdateStrpathCandidateSet strPathPair E
           val (tyConSubst,E) = 
               updateStrpathInEnv updateCandidateSet ID.Map.empty E
         in
           E
         end
           
       and updateStrpathInEnv 
             updateCandidateSet tyConSubst (E as (tyConEnv,varEnv,strEnv)) =
           let
             val (tyConSubst,newTyConEnv) =
                 updateStrpathInTyConEnv updateCandidateSet ID.Map.empty tyConEnv
             val (tyConSubst,newVarEnv) = 
                 updateStrpathInVarEnv updateCandidateSet ID.Map.empty varEnv
             val (tyConSubst,newStrEnv) =
                 updateStrpathInStrEnv updateCandidateSet ID.Map.empty strEnv
           in
             (tyConSubst,(newTyConEnv,newVarEnv,newStrEnv))
           end
             
       and updateStrpathInTyConEnv 
             (updateCandidateSet as {tyConIdSet,strPathMap}) tyConSubst tyConEnv =
           SEnv.foldli ( fn (tyCon,tyBindInfo,(tyConSubst,tyConEnv)) =>
                            case tyBindInfo of
                              TYCON (tycon as {name,tyvars,id,eqKind,datacon,...}) =>
                              let
                                val (tyConSubst,newTyCon) = 
                                    updateStrpathInTyCon 
                                      updateCandidateSet tyConSubst tycon
                              in
                                (ID.Map.empty,
                                 SEnv.insert(tyConEnv,tyCon,TYCON newTyCon)
                                )
                              end
                                
                            | TYFUN tyfun => 
                              let
                                val (tyConSubst1,newTyFun) = 
                                    updateStrpathInTyfun 
                                      updateCandidateSet tyConSubst tyfun
                              in
                                (ID.Map.empty,
                                 SEnv.insert(tyConEnv,tyCon,TYFUN newTyFun))
                              end
                            | TYSPEC ({spec = tyspec as {name, id, eqKind, tyvars,
                                                         strpath, boxedKind},
                                       impl}) =>
                              let
                                val updatable = 
                                    isUpdatableTyCon 
                                      updateCandidateSet
                                      {
                                       name = name,
                                       strpath = strpath,
                                       abstract = false,(* dummy tyCon to check updatable*)
                                       tyvars = tyvars,
                                       id = id,
                                       eqKind = ref eqKind,
                                       boxedKind = ref NONE,
                                       datacon = ref SEnv.empty
                                       } 
                                val newStrpath = 
                                    if updatable then
                                      valOf(PathMap.find(strPathMap,strpath))
                                    else strpath
                                val newTySpec = 
                                      {
                                       name = name,
                                       id = id,
                                       strpath = newStrpath, 
                                       tyvars = tyvars,
                                       eqKind = eqKind,
                                       boxedKind = boxedKind
                                       }
                                (* impl need not be touched,
                                 * not used for printing,
                                 * only used for later phases to know the implementation type
                                 *)
                                val newTyConSubst = 
                                    ID.Map.insert(tyConSubst,id,TYSPEC {spec = newTySpec,
                                                                      impl = impl})
                              in
                                (ID.Map.empty,SEnv.insert(tyConEnv, 
                                                           tyCon, 
                                                           TYSPEC {spec = newTySpec,
                                                                   impl = impl}))
                              end 
                        )
                       (tyConSubst,SEnv.empty)
                       tyConEnv
                       
       and updateStrpathInTyfun updateCandidateSet tyConSubst {name, tyargs, body} =
           let
             val (tyConSubst,newTyargs) = 
                 IEnv.foldli (fn (key,tyarg,(tyConSubst,newTyargs)) =>
                                 let
                                   val (deltaTyConSubst,newTyarg) =
                                       updateStrpathInBtvKind updateCandidateSet tyConSubst tyarg
                                 in
                                   (ID.Map.unionWith #1 (deltaTyConSubst,tyConSubst),
                                    IEnv.insert(newTyargs,key,newTyarg))
                                 end
                                   )
                             (tyConSubst,IEnv.empty)
                             tyargs
             val (newBody,tyConSubst) =
                 updateStrpathInTy updateCandidateSet tyConSubst body
           in
             (tyConSubst,
              {name = name,
               tyargs = newTyargs,
               body = newBody}
              )
           end
             
       and updateStrpathInBtvKind updateCandidateSet tyConSubst  {index, recKind, eqKind} =
           let
             val (tyConSubst, recKind) =
                 case recKind of 
                   UNIV => (tyConSubst, UNIV)
                 | REC tySEnvMap => 
                   let
                     val (tyConSubst,tySEnvMap) = 
                         (SEnv.foldli
                            (fn (label, ty, (tyConSubst, tySEnvMap)) =>
                                let
                                  val (ty,tyConSubst) = updateStrpathInTy updateCandidateSet tyConSubst ty
                                in
                                  (tyConSubst, SEnv.insert(tySEnvMap, label, ty))
                                end)
                            (tyConSubst, SEnv.empty)
                            tySEnvMap)
                   in
                     (tyConSubst, REC tySEnvMap)
                   end
                 | OVERLOADED tys =>
                   let
                     val (tyConSubst,tys) = 
                         (foldr
                            (fn (ty, (tyConSubst, tys)) =>
                                let
                                  val (ty, tyConSubst) = 
                                      updateStrpathInTy updateCandidateSet tyConSubst ty
                                in
                                  (tyConSubst, ty :: tys)
                                end)
                            (tyConSubst, nil)
                            tys
                         )
                   in 
                     (tyConSubst,OVERLOADED tys)
                   end
           in
             (
              tyConSubst,
              {
               index=index, 
               recKind = recKind,
               eqKind = eqKind
               }
              )
           end
             
       and updateStrpathInTy updateCandidateSet tyConSubst ty =
           TypeTransducer.transTyPreOrder
             (fn (ty, tyConSubst) =>
                 case ty of
                   TYVARty (tvar as ref (TVAR tvKind)) => 
                   let
                     val (tyConSubst, tvKind) =
                         updateStrpathInTvKind updateCandidateSet tyConSubst tvKind
                     val _  = tvar := TVAR tvKind
                   in
                     (ty, tyConSubst, true)
                   end
                 | CONty {tyCon, args} => 
                   let
                     val (tyConSubst, tyCon) =
                         updateStrpathInTyCon updateCandidateSet tyConSubst tyCon
                   in (CONty {tyCon=tyCon, args = args}, tyConSubst, true)
                   end
                 | ABSSPECty (specTy,implTy) =>
                   let
                     val (specTy',tyConSubst) = 
                         updateStrpathInTy updateCandidateSet tyConSubst specTy
                   in
                     (ABSSPECty(specTy',implTy), tyConSubst, false)
                   end
                 | POLYty {boundtvars, body} => 
                   let
                     val (tyConSubst, boundtvars) = 
                         IEnv.foldli
                           (fn (index, btvKind, (tyConSubst, boundtvars)) =>
                               let
                                 val (tyConSubst, btvKind) =
                                     updateStrpathInBtvKind
                                       updateCandidateSet tyConSubst btvKind
                               in
                                 (tyConSubst, IEnv.insert(boundtvars, index, btvKind))
                               end)
                           (tyConSubst, IEnv.empty)
                           boundtvars
                   in
                     (POLYty{boundtvars = boundtvars, body = body}, tyConSubst, true)
                   end
                 | _ => (ty, tyConSubst, true))
             tyConSubst
             ty
             
       and updateStrpathInTvKind updateCandidateSet tyConSubst {id, recKind, eqKind, tyvarName} = 
           let
             val (tyConSubst, recKind) =
                 case recKind of 
                   UNIV => (tyConSubst, UNIV)
                 | REC tySEnvMap => 
                   let
                     val (tyConSubst,tySEnvMap) = 
                         (SEnv.foldli
                            (fn (label, ty, (tyConSubst, tySEnvMap)) =>
                                let
                                  val (ty, tyConSubst) = 
                                      updateStrpathInTy updateCandidateSet tyConSubst ty
                                in
                                  (tyConSubst, SEnv.insert(tySEnvMap, label, ty))
                                end)
                            (tyConSubst, SEnv.empty)
                            tySEnvMap)
                   in 
                     (tyConSubst,REC tySEnvMap)
                   end
                 | OVERLOADED tys =>
                   let
                     val (tyConSubst,tys) = 
                         (foldr
                            (fn (ty, (tyConSubst, tys)) =>
                                let
                                  val (ty, tyConSubst) = 
                                      updateStrpathInTy updateCandidateSet tyConSubst ty
                                in
                                  (tyConSubst, ty :: tys)
                                end)
                            (tyConSubst, nil)
                            tys
                         )
                   in 
                     (tyConSubst,OVERLOADED tys)
                   end
           in
             (
              tyConSubst,
              {id=id, 
               recKind = recKind,
               eqKind = eqKind,
               tyvarName = tyvarName}
              )
           end
             
       and isUpdatableTyCon 
             (updateCandidateSet as {tyConIdSet,strPathMap})
             (tyCon as {id,name,strpath,...}:tyCon) =
             let
               val tyConIdMemberShip = ID.Set.member(tyConIdSet,id)
               val strPathMemberShip = PathMap.inDomain(strPathMap,strpath)
             in
               tyConIdMemberShip andalso strPathMemberShip
             end
               
       (*
        * 1. compare strpath with the currentStrpath
        *      if true then => defined in the introduced Env, goto 2.
        *              else => untouched, end.
        * 2. lookup tyConSubst.
        *      if exist then => return newTyCon
        *               else => update and get newTyCon, add to tyConSubst.
        * 
        *)
       and updateStrpathInTyCon 
             (updateCandidateSet as {tyConIdSet,strPathMap})
             tyConSubst
             (tyCon as {name, strpath = tyConStrpath, abstract,
                        tyvars, id, eqKind, boxedKind, datacon}) 
             =
             let
               (*      val _ = print "\n *** entering updatetycon ***\n"
                       val _ = print ("currentstrpath="^Path.pathToString(currentStrpath))
                       val _ = print (",tyconstrpath="^Path.pathToString(tyConStrpath))*)
               
               val updatable = isUpdatableTyCon updateCandidateSet tyCon
               val (tyConSubst,newTyCon : tyCon) =
                   if updatable then
                     case ID.Map.find(tyConSubst,id) of
                       SOME (TYCON tyCon) => (tyConSubst,tyCon)
                     | SOME (TYSPEC {spec = {name, id, eqKind, tyvars,
                                     strpath, boxedKind},
                                     impl})    =>
                       let
                         val newTyCon = 
                             {
                              name = name,
                              strpath = strpath,
                              abstract = abstract,
                              tyvars = tyvars,
                              id = id,
                              eqKind = ref eqKind,
                              boxedKind = ref boxedKind,
                              datacon = ref SEnv.empty (* new *)
                              }
                         val tyConSubst = ID.Map.insert(tyConSubst,id,TYCON newTyCon)
                         val (tyConSubst,newDatacon) = 
                             updateStrpathInVarEnv updateCandidateSet tyConSubst (!datacon)
                         val _ = (#datacon newTyCon) := newDatacon
                       in
                         (tyConSubst,newTyCon)
                       end
                     | SOME (TYFUN _) => raise Control.Bug "updateStrpathInTyCon:should be no tyFun"
                     | NONE =>
                       let
                         val newStrpath = valOf(PathMap.find(strPathMap,tyConStrpath))
                         val newTyCon : tyCon = 
                             {
                              name = name,
                              strpath = newStrpath,
                              abstract = abstract,
                              tyvars = tyvars,
                              id = id,
                              eqKind = eqKind,
                              boxedKind = boxedKind,
                              datacon = ref SEnv.empty (* new *)
                              }
                         val tyConSubst = ID.Map.insert(tyConSubst,id,TYCON newTyCon)
                         val (tyConSubst,newDatacon) = 
                             updateStrpathInVarEnv updateCandidateSet tyConSubst (!datacon)
                         val _ = (#datacon newTyCon) := newDatacon
                       in
                         (tyConSubst,newTyCon)
                       end
                   else 
                     (tyConSubst,tyCon)
             in
               (tyConSubst,newTyCon)
             end
               
       and updateStrpathInVarEnv 
             (updateCandidateSet as {tyConIdSet,strPathMap}) tyConSubst varEnv 
         =
         SEnv.foldli
           (fn (label, idstate, (tyConSubst, varEnv)) =>
               case idstate of
                 CONID {name, strpath = conStrpath, funtyCon, ty, tag, tyCon} =>
                 let
                   val conStrpath =
                       case PathMap.find(strPathMap,conStrpath) of 
                         NONE => conStrpath
                       | SOME newStrpath => newStrpath
                   val (ty, tyConSubst) = 
                       updateStrpathInTy updateCandidateSet tyConSubst ty
                   val (tyConSubst, tyCon) = 
                       updateStrpathInTyCon updateCandidateSet tyConSubst tyCon
                 in
                   (tyConSubst,
                    SEnv.insert(
                                varEnv,
                                label,
                                CONID{
                                      name = name, 
                                      strpath = conStrpath, 
                                      funtyCon = funtyCon, 
                                      ty = ty,
                                      tag = tag,
                                      tyCon = tyCon}
                                )
                    )
                 end
               | VARID {name,ty,strpath = varStrpath} =>
                 let
                   val varStrpath = 
                       case (PathMap.find(strPathMap,varStrpath)) of
                         NONE => varStrpath
                       | SOME newStrpath => newStrpath
                   val (ty, tyConSubst) = 
                       updateStrpathInTy updateCandidateSet tyConSubst ty
                 in
                   (tyConSubst,
                    SEnv.insert(
                                varEnv,
                                label,
                                VARID{
                                      name = name,
                                      strpath = varStrpath,
                                      ty=ty
                                      }
                                )
                    )
                 end
               | x => (tyConSubst, SEnv.insert(varEnv,label,x))
                      )
           (tyConSubst, SEnv.empty)
           varEnv
           
       and updateStrpathInStrEnv 
             (updateCandidateSet as {tyConIdSet,strPathMap}) tyConSubst strEnv
         =
         SEnv.foldri
           (fn
            (label, STRUCTURE {id, name, strpath, env = Env}, (tyConSubst, strEnv))
            =>
            let
              val (tyConSubst, Env) = 
                  updateStrpathInEnv updateCandidateSet tyConSubst Env
              val newStrpath = 
                  case (PathMap.find(strPathMap,strpath)) of
                    NONE => strpath
                  | SOME newStrpath => newStrpath
              val strPathInfo = {
                                 id = id, 
                                 name = name, 
                                 strpath = newStrpath,
                                 env = Env
                                 }
            in
              (tyConSubst, SEnv.insert(strEnv, label, STRUCTURE strPathInfo))
            end)
           (tyConSubst, SEnv.empty)
           strEnv
  end (* end local *)

  fun getTyConTyvar tyCon = 
      let
          val {datacon,...} = tyCon
      in
          tyvarsVE (!datacon)
      end
  and getTyFunTyvar (tyFun as {body,...}) =
      EFTV body
          
  and getIdStateTyvars idState = 
      case idState of
          VARID({ty,...}) => EFTV ty
        | CONID({ty,...}) => EFTV ty
        | PRIM({ty,...}) => EFTV ty
        | OPRIM({ty,...}) => EFTV ty
        | FFID({ty,...}) => EFTV ty
        | RECFUNID({ty,...},_) => EFTV ty

  and tyvarsTE tyConEnv =
      SEnv.foldl
          (fn(tystr,T) => 
             case tystr of 
                 TYCON(tyCon) => OTSet.union (T, getTyConTyvar tyCon)
               | TYFUN(tyFun) => OTSet.union (T, getTyFunTyvar tyFun)
               | TYSPEC _ => OTSet.empty
               )
          OTSet.empty 
          tyConEnv

  and tyvarsVE varEnv =
      SEnv.foldl  
          (fn(idState, T) =>OTSet.union (T, (getIdStateTyvars idState)))
          OTSet.empty
          varEnv

  and tyvarsSE strEnv =
      SEnv.foldl
          (fn(STRUCTURE{env = E, ...}, T) => OTSet.union (T, tyvarsE E))
          OTSet.empty strEnv

  and tyvarsE (tyConEnv,varEnv,strEnv) =
      OTSet.union (tyvarsTE tyConEnv,OTSet.union(tyvarsVE varEnv,tyvarsSE strEnv))

  and tyvarsG sigEnv =
      SEnv.foldl
          (fn(SIGNATURE(T,{env = E, ...}), V) => OTSet.union(V,tyvarsE E))
          OTSet.empty 
          sigEnv
          
  and tyvarsContext (cc :TypeContext.context) = 
      OTSet.union (tyvarsG (#sigEnv cc),
                   tyvarsE (#tyConEnv cc,
                            #varEnv   cc,
                            #strEnv   cc))

  fun substTyConIdInSizeTagExp tyConIdSubst sizeTagExp =
      case sizeTagExp of
          ST_CONST _ => sizeTagExp
        | ST_VAR id => ST_VAR (substTyConIdInId tyConIdSubst id)
        | ST_BDVAR _ => sizeTagExp
        | ST_APP {stfun = sizeTagExp, args = sizeTagExps} =>
          ST_APP {stfun = substTyConIdInSizeTagExp tyConIdSubst sizeTagExp, 
                  args = map (substTyConIdInSizeTagExp tyConIdSubst) sizeTagExps}
        | ST_FUN {args, body} => ST_FUN {args = args, body = substTyConIdInSizeTagExp tyConIdSubst body}
          
          
  fun substTyConIdInTyConSizeTagEnv visited tyConIdSubst tyConSizeTagEnv =
      let
          val (visited, tyConSizeTagEnv) =
              SEnv.foldli
                  (fn (label, {tyBindInfo, sizeInfo, tagInfo}, (visited, tyConSizeTagEnv)) =>
                      let
                          val (visited, tyBindInfo) = 
                              substTyConIdInTyBindInfo visited tyConIdSubst tyBindInfo
                          val sizeInfo =
                              substTyConIdInSizeTagExp tyConIdSubst sizeInfo
                          val tagInfo =
                              substTyConIdInSizeTagExp tyConIdSubst tagInfo
                      in
                          (visited, SEnv.insert(tyConSizeTagEnv, 
                                                label,
                                                {tyBindInfo = tyBindInfo,
                                                 sizeInfo = sizeInfo,
                                                 tagInfo = tagInfo}))
                      end)
                  (visited, SEnv.empty)
                  tyConSizeTagEnv
      in
          (visited, tyConSizeTagEnv)
      end

  fun substTyConIdInStrSizeTagEnv visited tyConIdSubst strSizeTagEnv =
      SEnv.foldri
          (fn
           (label, STRSIZETAG {id, name, strpath, env = Env}, (visited, strSizeTagEnv))
           =>
           let
               val (visited, Env) = substTyConIdInSizeTagEnv visited tyConIdSubst Env
               val strPathSizeTagInfo = {id = id, name = name, strpath = strpath, env = Env}
           in
               (visited, SEnv.insert(strSizeTagEnv, label, STRSIZETAG strPathSizeTagInfo))
           end)
          (visited, SEnv.empty)
          strSizeTagEnv

  and substTyConIdInSizeTagEnv visited tyConIdSubst (tyConSizeTagEnv, varEnv, strSizeTagEnv) =
      let
          val (visited, tyConSizeTagEnv) = 
              substTyConIdInTyConSizeTagEnv ID.Set.empty tyConIdSubst tyConSizeTagEnv
          val (visited, varEnv) = 
              substTyConIdInVarEnv visited tyConIdSubst varEnv 
          val (visited, strSizeTagEnv) = 
              substTyConIdInStrSizeTagEnv visited tyConIdSubst strSizeTagEnv
      in
          (visited, (tyConSizeTagEnv, varEnv, strSizeTagEnv))
      end
          
  fun substTyConIdInTypeEnv tyConIdSubst (typeEnv:TC.typeEnv) =
      let
          val (visited, tyConSizeTagEnv) = 
              substTyConIdInTyConSizeTagEnv ID.Set.empty tyConIdSubst (#tyConSizeTagEnv typeEnv)
          val (visited, varEnv) = 
              substTyConIdInVarEnv visited tyConIdSubst (#varEnv typeEnv)
          val (visited, strSizeTagEnv) = 
              substTyConIdInStrSizeTagEnv visited tyConIdSubst (#strSizeTagEnv typeEnv)
      in
          {tyConSizeTagEnv = tyConSizeTagEnv,
           varEnv = varEnv,
           strSizeTagEnv =  strSizeTagEnv}
      end

  (**********************************************************************)         

  fun sizeTagSubstFromTyConSizeTagEnv (importTyConSizeTagEnv, implTyConSizeTagEnv) =
      SEnv.foldli 
          (fn (tyConName, {tyBindInfo, sizeInfo, tagInfo}, sizeTagSubst) =>
              case tyBindInfo of
                  TYSPEC {spec = {id,...}, impl = NONE} =>
                  (case SEnv.find (implTyConSizeTagEnv, tyConName) of
                       NONE => sizeTagSubst
                     | SOME {tyBindInfo, sizeInfo, tagInfo} =>
                       ID.Map.insert(sizeTagSubst, id, (sizeInfo, tagInfo)))
                | _ => sizeTagSubst)
          ID.Map.empty
          importTyConSizeTagEnv

  fun sizeTagSubstFromStrSizeTagEnv (importStrSizeTagEnv, implStrSizeTagEnv) =
      SEnv.foldli
      (fn (strName, 
           STRSIZETAG {env = (subTyConSizeTagEnv1, subVarEnv1, subStrSizeTagEnv1),...}, 
           sizeTagSubst) =>
          case SEnv.find(implStrSizeTagEnv, strName) of
              SOME (STRSIZETAG {env = (subTyConSizeTagEnv2, subVarEnv2, subStrSizeTagEnv2),...}) =>
                   let
                       val sizeTagSubst1 = 
                           sizeTagSubstFromTyConSizeTagEnv (subTyConSizeTagEnv1, subTyConSizeTagEnv2)
                       val sizeTagSubst2 =
                           sizeTagSubstFromStrSizeTagEnv (subStrSizeTagEnv1, subStrSizeTagEnv2)
                   in
                       ID.Map.unionWithi (fn _ => raise Control.Bug "duplicate tyConId")
                                         (sizeTagSubst,
                                          ID.Map.unionWithi (fn _ => raise Control.Bug "duplicate tyConId")
                                                            (sizeTagSubst1,sizeTagSubst2))
                   end
            | NONE => sizeTagSubst)
      ID.Map.empty
      importStrSizeTagEnv
                  

  fun sizeTagSubstFromEnv (importTypeEnv:TC.typeEnv, implTypeEnv:TC.typeEnv) =
      let
          val sizeTagSubst1 = 
              sizeTagSubstFromTyConSizeTagEnv (#tyConSizeTagEnv importTypeEnv,
                                               #tyConSizeTagEnv implTypeEnv)
          val sizeTagSubst2 =
              sizeTagSubstFromStrSizeTagEnv (#strSizeTagEnv importTypeEnv,
                                             #strSizeTagEnv implTypeEnv)
      in
          ID.Map.unionWithi (fn _ => raise Control.Bug "duplicate tyConId") 
                            (sizeTagSubst1, sizeTagSubst2)
      end

  (***********************************************************************************)
  local
      fun substSizeTagExp sizeFlag sizeTagSubst sizeTagExp =
          case sizeTagExp of
              ST_CONST _ => sizeTagExp
            | ST_VAR id => 
              (case ID.Map.find(sizeTagSubst, id) of
                   NONE => sizeTagExp
                 | SOME (sizeInfo, TagInfo) => 
                   if sizeFlag then sizeInfo else TagInfo)
            | ST_BDVAR _ => sizeTagExp
            | ST_APP {stfun, args} => ST_APP {stfun = substSizeTagExp sizeFlag sizeTagSubst stfun,
                                              args = map (substSizeTagExp sizeFlag sizeTagSubst) args}
            | ST_FUN {args, body} => ST_FUN {args = args,
                                             body = substSizeTagExp sizeFlag sizeTagSubst body}
  in
      fun substSizeInfo sizeTagSubst sizeExp =
          substSizeTagExp true sizeTagSubst sizeExp
      fun substTagInfo sizeTagSubst tagExp =
          substSizeTagExp false sizeTagSubst tagExp
  end
          
  fun substSizeTagTyConSizeTagEnv sizeTagSubst tyConSizeTagEnv =
      SEnv.map (fn {tyBindInfo, sizeInfo, tagInfo} =>
                   {tyBindInfo = tyBindInfo,
                    sizeInfo = substSizeInfo sizeTagSubst sizeInfo,
                    tagInfo = substSizeInfo sizeTagSubst tagInfo})
               tyConSizeTagEnv

  fun substSizeTagStrSizeTagEnv sizeTagSubst strSizeTagEnv =
      SEnv.map (fn STRSIZETAG {id, 
                               name, 
                               strpath, 
                               env = (subTyConSizeTagEnv, subVarEnv, subStrSizeTagEnv)} =>
                   let
                       val subTyConSizeTagEnv =
                           substSizeTagTyConSizeTagEnv sizeTagSubst subTyConSizeTagEnv
                       val subStrSizeTagEnv =
                           substSizeTagStrSizeTagEnv sizeTagSubst subStrSizeTagEnv
                   in
                       STRSIZETAG{id = id,
                                  name = name,
                                  strpath = strpath,
                                  env = (subTyConSizeTagEnv, subVarEnv, subStrSizeTagEnv)}
                   end)
               strSizeTagEnv

  fun substSizeTagTypeEnv sizeTagSubst (typeEnv:TC.typeEnv) =
      {
       tyConSizeTagEnv = 
       substSizeTagTyConSizeTagEnv sizeTagSubst (#tyConSizeTagEnv typeEnv),
       varEnv = #varEnv typeEnv,
       strSizeTagEnv =
       substSizeTagStrSizeTagEnv sizeTagSubst (#strSizeTagEnv typeEnv)
       }
 end
end
