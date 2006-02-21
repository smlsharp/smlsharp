(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Module compiler flattens structure.
 * 
 * @author Liu Bochao
 * @version $Id: ModuleCompileCore.sml,v 1.35 2006/02/18 11:06:33 duchuu Exp $
 *)
structure ModuleCompileCore  = 
struct
local
  structure T  = Types
  structure P = Path
  structure TO = TopObject
  structure TU = TypesUtils
  structure SE = StaticEnv
  structure FAU = FunctorApplyUtils
  structure MCFA = ModuleCompileFunctorApp
  structure PE = PathEnv
  structure MCU = ModuleCompileUtils
  structure MC = ModuleContext
  open TypedCalc
  open TypedFlatCalc

  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")
  fun typeToString ty = TypeFormatter.tyToString ty

in

   fun tppatToTfppatList context tppatList =
        let
          val (pathVarEnv,tfppatlist) = 
              foldr (
                           fn (tppat,(pathVarEnv,tfppatlist)) =>
                              let
                                val (pathVarEnv',tfppat) = tppatToTfppat context tppat
                                val newpathVarEnv = 
                                    PE.mergePathVarEnv {newPathVarEnv = pathVarEnv',
                                                        oldPathVarEnv = pathVarEnv}
                              in
                                (newpathVarEnv, tfppat::tfppatlist)
                              end)
                          (PE.emptyPathVarEnv, nil)
                          tppatList
        in
          (
           pathVarEnv,
           tfppatlist
           )
        end
   and tppatToTfppat context tppat =
       case tppat of
         TPPATWILD args => (PE.emptyPathVarEnv,TFPPATWILD args)
       | TPPATVAR (varPathInfo as {name,ty,...},loc) =>
         let
           val freshId = SE.newVarId()
           val pathVarEnv = 
	       SEnv.singleton(name, PE.CurItem ((P.NilPath,name), freshId, ty, loc))
           val varIdInfo = {id = freshId, displayName = name, ty = ty}
         in 
           (pathVarEnv,TFPPATVAR(varIdInfo, loc))
         end
       | TPPATCONSTANT args => (PE.emptyPathVarEnv,TFPPATCONSTANT args)
       | TPPATCONSTRUCT {conPat=conPathInfo as {name,strpath,funtyCon,ty,tag,tyCon},
                         instTyList=tys,
                         argPatOpt=tppatop,
                         patTy=ty1,
                         loc=loc} =>
         let
           val newconInfo = 
               {
                displayName = PE.pathVarToString(strpath,name), 
                funtyCon=funtyCon, 
                ty=ty, 
                tag=tag, 
                tyCon=tyCon
                }
           val (pathVarEnv,tfppatop) = 
               case tppatop of 
                 NONE => (PE.emptyPathVarEnv,NONE)
               | SOME(tppat) =>
                 let
                   val (pathVarEnv',tfppat) = tppatToTfppat context tppat
                 in 
                   (pathVarEnv',SOME(tfppat))
                 end
         in
           (
            pathVarEnv,
            TFPPATCONSTRUCT{conPat=newconInfo,instTyList=tys,argPatOpt=tfppatop,patTy=ty1,loc=loc}
            ) 
         end
      | TPPATRECORD {fields=patfields, recordTy=ty,loc=loc} => 
        let
          val (pathVarEnv,tfppatfields) = 
              SEnv.foldri (
                           fn (label,tppat,(pathVarEnv,tppatfields)) =>
                              let
                                val (pathVarEnv',tfppat) = tppatToTfppat context tppat
                                val newpathVarEnv = 
                                    PE.mergePathVarEnv {newPathVarEnv = pathVarEnv',
                                                        oldPathVarEnv = pathVarEnv}
                                val newtppatfields = 
                                    SEnv.insert(tppatfields,label,tfppat)
                              in
                                (newpathVarEnv,newtppatfields)
                              end)
                          (PE.emptyPathVarEnv,SEnv.empty)
                          patfields
        in
          (
           pathVarEnv,
           TFPPATRECORD{fields=tfppatfields,recordTy=ty,loc=loc}
           )
        end
      | TPPATLAYERED {varPat=tppat1, asPat=tppat2, loc=loc} =>
        let
          val (pathVarEnv1,tfppat1) = tppatToTfppat context tppat1
          val (pathVarEnv2,tfppat2) = tppatToTfppat context tppat2
        in
          (PE.mergePathVarEnv{newPathVarEnv = pathVarEnv1,
                              oldPathVarEnv = pathVarEnv2},
           TFPPATLAYERED{varPat=tfppat1, asPat=tfppat2, loc=loc})
        end

   fun tpexpToTfpexpList context tpexpList =
       map (fn tpexp => tpexpToTfpexp context tpexp) tpexpList

   and tpexpToTfpexp context (tpexp : tpexp) =
       case tpexp of
         TPFOREIGNAPPLY {funExp=tpexp1, 
                         instTyList=tyList, 
                         argExp=tpexp2, 
                         argTyList=argTys, 
                         loc=loc} =>
         let
           val tfpexp1 = tpexpToTfpexp context tpexp1  
           val tfpexp2 = tpexpToTfpexp context tpexp2
         in 
           TFPFOREIGNAPPLY {funExp=tfpexp1, 
                            instTyList=tyList, 
                            argExp=tfpexp2, 
                            argTyList=argTys,
                            loc=loc}
         end
       | TPCONSTANT (constant, loc) => TFPCONSTANT(constant,loc)
       | TPVAR ({name = name, strpath = strpath, ty = ty}, loc) =>
         let 
           val displayName = PE.pathVarToString(strpath, name)
           val item = 
               case PE.lookupVar (#topPathBasis context ,
                                  #pathBasis context,
                                  strpath,
                                  name)
                of
                 SOME item => item
               | NONE  => 
                 raise Control.Bug ("undefined variable:"^ PE.pathVarToString(strpath,name))
           val tfpexp1 =
               case item of
                 PE.TopItem (_, index, _) =>
                 TFPGETGLOBALVALUE(TO.getPageArrayIndex index,
                                   TO.getOffset index, 
                                   ty, 
                                   loc)
               | PE.CurItem (_, id, _, _) =>
                  TFPVAR({id = id, displayName = displayName, ty = ty}, loc)
         in
           tfpexp1
         end
       | TPRECFUNVAR {var = {name,...},...} => 
           (print name;
            print "\n";
            raise Control.Bug "TPRECFUNVAR in module compiler"
              )
       | TPPRIMAPPLY {primOp=primInfo as {name,ty},
                      instTyList=tys,
                      argExpOpt=tpexpop,
                      loc=loc} =>
         let
           val tfpexpop = 
               case tpexpop of
                 NONE => NONE
               | SOME(tpexp) => 
                 let 
                   val tfpexpop = tpexpToTfpexp context tpexp
                 in
                   SOME(tfpexpop)
                 end
         in 
           TFPPRIMAPPLY{primOp=primInfo, instTyList=tys, argExpOpt=tfpexpop, loc=loc}
         end
       | TPOPRIMAPPLY {oprimOp=oprimInfo as {name,ty,instances}, 
                       instances=tys, 
                       argExpOpt=tpexpop,
                       loc=loc} =>
         let
           val tfpexpop = 
               case tpexpop of
                 NONE => NONE
               | SOME(tpexp) => 
                 let
                   val tfpexpop = tpexpToTfpexp context tpexp
                 in
                   SOME(tfpexpop)
                 end
         in 
           TFPOPRIMAPPLY{oprimOp=oprimInfo,
                         instances=tys,
                         argExpOpt=tfpexpop,
                         loc=loc}
         end
       | TPCONSTRUCT{con=conPathInfo as {name,strpath,funtyCon,ty,tag,tyCon},
                     instTyList=tys,
                     argExpOpt=tpexpop,
                     loc=loc} =>
         let
           val newconInfo = 
               {
                displayName = PE.pathVarToString(strpath,name), 
                funtyCon = funtyCon, 
                ty = ty, 
                tag = tag, 
                tyCon = tyCon
                }
           val tfpexpop = 
               case tpexpop of
                 NONE => NONE
               | SOME(tpexp) => 
                 let
                   val tfpexpop = tpexpToTfpexp context tpexp
                 in
                   SOME(tfpexpop)
                 end
         in
           TFPCONSTRUCT{con=newconInfo, instTyList=tys, argExpOpt=tfpexpop, loc=loc}
         end
       | TPAPPM {funExp=tpexp1,funTy=funty, argExpList=tpexpList2,loc} =>
         let
           val tfpexp1 = tpexpToTfpexp context tpexp1 
           val tfpexpList2 = tpexpToTfpexpList context tpexpList2
         in 
           TFPAPPM {funExp=tfpexp1, funTy=funty, argExpList=tfpexpList2, loc=loc}
         end
       | TPMONOLET {binds, bodyExp=tpexp, loc} =>
         let
           fun tpbindsToTfpbinds context nil = 
               ((PE.emptyPathVarEnv,PE.emptyPathStrEnv), nil)
             | tpbindsToTfpbinds context (tpbind::rem) =
               let
                 val (varPathInfo as {name,strpath,ty},tpexp) = tpbind
                 val id = SE.newVarId()
                 val varIdInfo = {
                                     id = id, 
                                     displayName = name, 
                                     ty = ty
                                     }
                 val tfpexp = tpexpToTfpexp context tpexp
                 val pathEnv1 = 
                     (
                      SEnv.singleton(name, PE.CurItem ((P.NilPath,name), id, ty, loc)),
                      PE.emptyPathStrEnv
                      )
                 val newContext = 
                     MC.extendContextWithPathEnv (context,pathEnv1)
                 val (pathEnv2, tfpbinds) = 
                     tpbindsToTfpbinds newContext rem
               in 
                 (
                  PE.mergePathEnv {newPathEnv=pathEnv2,
                                   oldPathEnv=pathEnv1},
                  (varIdInfo,tfpexp)::tfpbinds
                 )
               end
           val (pathEnv1, newbinds) = tpbindsToTfpbinds context binds
           val newContext = MC.extendContextWithPathEnv(context,pathEnv1)
           val tfpexp = tpexpToTfpexp newContext tpexp
         in 
           TFPMONOLET {binds=newbinds, bodyExp=tfpexp, loc=loc}
         end
       | TPLET (tpdecs,tpexps,tys,loc) =>
         let
           val newContext1 = MC.updateContextWithPrefix(context,P.NilPath)
           val (pathEnv1, tfpdecs) = 
               tpdecsToTfpdecs newContext1 tpdecs
           val newContext2 = MC.extendContextWithPathEnv (context, pathEnv1)
           val tfpexps = map (tpexpToTfpexp newContext2) tpexps
        in
           TFPLET(tfpdecs,tfpexps,tys,loc)
        end
      | TPRECORD {fields, recordTy=ty,loc} =>
        let
          val tfpfields =
              SEnv.map (fn tpexp => tpexpToTfpexp context tpexp) fields
        in 
          TFPRECORD{fields=tfpfields, recordTy=ty, loc=loc}
        end
      | TPSELECT {label=tag, exp=tpexp, expTy=ty, loc=loc} =>
        let
          val tfpexp = tpexpToTfpexp context tpexp 
        in 
          TFPSELECT{label=tag, exp=tfpexp, expTy=ty, loc=loc}
        end
      | TPMODIFY {label, 
                  recordExp=tpexp1, 
                  recordTy=ty1, 
                  elementExp=tpexp2, 
                  elementTy= ty2, 
                  loc=loc} =>
        let
          val tfpexp1 = tpexpToTfpexp context tpexp1
          val tfpexp2 = tpexpToTfpexp context tpexp2
        in
          TFPMODIFY {label=label, 
                     recordExp=tfpexp1, 
                     recordTy=ty1, 
                     elementExp=tfpexp2, 
                     elementTy=ty2, 
                     loc=loc}
        end
      | TPRAISE (tpexp,ty,loc) =>
        TFPRAISE(tpexpToTfpexp context tpexp,ty,loc)
      | TPHANDLE {exp=tpexp1, 
                  exnVar=varPathInfo as {name,ty,...}, 
                  handler=tpexp2, 
                  loc} =>
        let
          val id = SE.newVarId()
          val varIdInfo = {id = id, displayName = name, ty = ty}
          val tfpexp1 = tpexpToTfpexp context tpexp1
          val pathEnv1 = 
              (SEnv.singleton(name, PE.CurItem ((P.NilPath,name), id, ty, loc)),
               PE.emptyPathStrEnv)
          val newContext =
              MC.extendContextWithPathEnv (context, pathEnv1)
          val tfpexp2 = tpexpToTfpexp newContext tpexp2
        in 
          TFPHANDLE {exp=tfpexp1, exnVar=varIdInfo, handler=tfpexp2, loc=loc}
        end
      | TPCASEM {expList=tpexpList, 
                 expTyList=tyList1, 
                 ruleList=rules,
                 ruleBodyTy=ty2,
                 caseKind=caseKind,
                 loc=loc} =>
        let
          val tfpexpList = tpexpToTfpexpList context tpexpList
          val tfprules =
              map
                (fn (tppatList,tpexp) =>
                    let
                      val (pathVarEnv, tfppatList) = 
                          tppatToTfppatList context tppatList
                      val newContext =
                          MC.extendContextWithPathEnv
                            (context, (pathVarEnv, PE.emptyPathStrEnv))
                      val tfpexp = tpexpToTfpexp newContext tpexp
                    in 
                      (tfppatList, tfpexp)
                    end
                )
                rules
        in 
          TFPCASEM{expList=tfpexpList, 
                   expTyList=tyList1,
                   ruleList=tfprules,
                   ruleBodyTy=ty2,
                   caseKind=caseKind,
                   loc=loc}
        end
      | TPFNM {argVarList, bodyTy=ty1, bodyExp=tpexp, loc} =>
        let
          val varIdInfoList = 
              map (fn {name, strpath, ty} => 
                      {id = SE.newVarId(),
                       displayName = name, 
                       ty = ty}
                      )
                  argVarList
          val pathVarEnv = 
              foldl
                (fn ({id, displayName, ty}, pathVarEnv) =>
                    SEnv.insert(pathVarEnv, 
                                displayName, 
                                PE.CurItem ((P.NilPath,displayName),id, ty, loc))
                    )
                SEnv.empty
                varIdInfoList
          val newContext = MC.extendContextWithPathEnv(context,(pathVarEnv,PE.emptyPathStrEnv))
          val tfpexp = tpexpToTfpexp newContext tpexp
        in 
          TFPFNM {argVarList = varIdInfoList,
                  bodyTy=ty1,
                  bodyExp=tfpexp,
                  loc=loc}
        end
      | TPPOLYFNM {btvEnv=btvKind, 
                   argVarList,
                   bodyTy,
                   bodyExp=tpexp,
                   loc=loc} =>
        let
          val varIdInfoList = 
              map (fn {name, strpath, ty} => 
                      {id = SE.newVarId(),
                       displayName = name, 
                       ty = ty}
                      )
                  argVarList
          val pathVarEnv = 
              foldl
                (fn ({id, displayName, ty}, pathVarEnv) =>
                    SEnv.insert(pathVarEnv, 
                                displayName, 
                                PE.CurItem ((P.NilPath, displayName),id, ty, loc))
                    )
                SEnv.empty
                varIdInfoList
          val newContext = MC.extendContextWithPathEnv(context,(pathVarEnv,PE.emptyPathStrEnv))
          val tfpexp = tpexpToTfpexp newContext tpexp

        in 
          TFPPOLYFNM{btvEnv=btvKind, 
                     argVarList = varIdInfoList,
                     bodyTy=bodyTy,
                     bodyExp=tfpexp,
                     loc=loc}
        end
      | TPPOLY {btvEnv=btvKind, expTyWithoutTAbs=ty, exp=tpexp,loc=loc} =>
        let
          val tfpexp = tpexpToTfpexp context tpexp
        in 
          TFPPOLY {btvEnv=btvKind, expTyWithoutTAbs=ty, exp=tfpexp, loc=loc}
        end
      | TPTAPP {exp=tpexp, expTy=ty, instTyList= tys, loc=loc} => 
        let
          val tfpexp = tpexpToTfpexp context tpexp
        in 
          TFPTAPP {exp=tfpexp, expTy=ty, instTyList=tys, loc=loc}
        end
      | TPSEQ {expList=tpexps, expTyList=tys, loc=loc} =>
        let
          val tfpexps = 
              map (fn tpexp => tpexpToTfpexp context tpexp) tpexps
        in 
          TFPSEQ {expList = tfpexps, expTyList= tys, loc=loc}
        end
      | TPFFIVAL {funExp, libExp, argTyList=argTys, resultTy, funTy, loc}  =>
        let
          val newFunExp = tpexpToTfpexp context funExp
          val newLibExp = tpexpToTfpexp context libExp
        in
          TFPFFIVAL {funExp=newFunExp, 
                     libExp=newLibExp, 
                     argTyList=argTys, 
                     resultTy=resultTy, 
                     funTy=funTy, 
                     loc=loc}
        end
      | TPCAST (tpexp, ty, loc)  => TFPCAST(tpexpToTfpexp context tpexp,ty,loc)
      | TPERROR => raise Control.Bug "TPERROR passed to module compiler"
                
   and tpdecToTfpdecs context tpdec =
       case tpdec of
         TPVAL (decs,loc) => 
         let 
           fun compiledecs context nil = 
               ((PE.emptyPathVarEnv,PE.emptyPathStrEnv), nil)
             | compiledecs context (dec as (valId,tpexp)::rem) = 
               let
                 val (pathEnv1,newValId) = 
                     case valId of
                       T.VALIDVAR {name,ty} => 
                       let
                         val id = SE.newVarId()
                         val newVar = 
                             VALDECIDENT {id = id, 
                                          displayName = PE.pathVarToString(#prefix context,name),
                                          ty = ty
                                          }
                       in
                         (
                          (SEnv.singleton
                             (name, PE.CurItem ((#prefix context,name), id, ty, loc)),
                             PE.emptyPathStrEnv),
                          newVar
                          )
                       end
                     | T.VALIDWILD ty => (PE.emptyPathEnv, VALDECIDENTWILD ty)
                 val newtfpexp = tpexpToTfpexp context tpexp
                 val dec1 = (newValId,newtfpexp)
                 val (pathEnv2, decs2) = compiledecs context rem 
               in
                 (
                  PE.mergePathEnv {
                                   newPathEnv = pathEnv2, 
                                   oldPathEnv = pathEnv1
                                   }, 
                  dec1 :: decs2
                 )
               end
           val (pathEnv1, decs) = compiledecs context  decs
         in 
           (pathEnv1, [TFPVAL(decs,loc)]) 
         end
       | TPVALREC (decs,loc) =>
        let 
          val longNamePathVarEnv = 
              foldr (
                     fn ({var={name,ty},...},longNamePathVarEnv) => 
                        SEnv.insert(
                                    longNamePathVarEnv,
                                    name, 
                                    PE.CurItem ((#prefix context,name), 
                                                SE.newVarId(),
                                                ty, 
                                                loc)
                                    )
                    )
                    PE.emptyPathVarEnv
                    decs
          val longNamePathEnv = (longNamePathVarEnv, PE.emptyPathStrEnv)
          fun compiledecs context nil = nil
            | compiledecs context (dec::rem) = 
              let
                
                val {var=var as {name,ty}, expTy=ty',exp=tpexp} = dec
                val curItem = 
                    case PE.lookupVarInPathBasis(#pathBasis context, P.NilPath, name) of
                      NONE => raise Control.Bug ("undefined variable:"^ name)
                    | SOME item => item
                val newtfpexp = tpexpToTfpexp context tpexp
                val newdec = (
                              { 
                               id = PE.getIdFromCurItem curItem,
                               displayName = 
                               PE.pathVarToString(PE.getPathVarFromItem curItem),
                               ty = ty
                               },
                              ty',
                              newtfpexp
                              )
                val newdecs = compiledecs context rem
              in
                newdec::newdecs
              end
          val newContext = MC.extendContextWithPathEnv(context, longNamePathEnv)
          val decs = compiledecs newContext decs
        in 
          (
           longNamePathEnv,
           [TFPVALREC (decs,loc)]
           )
        end
      | TPVALPOLYREC (btvEnv,decs,loc) =>
        let 
          val longNamePathVarEnv = 
              foldr (
                     fn ({var={name,ty},...}, longNamePathVarEnv) => 
                        SEnv.insert(
                                    longNamePathVarEnv,
                                    name, 
                                    PE.CurItem ((#prefix context,name), 
                                                SE.newVarId(),
                                                ty,
                                                loc)
                                    )
                    )
                    PE.emptyPathVarEnv
                    decs
          val longNamePathEnv = (longNamePathVarEnv, PE.emptyPathStrEnv)
          fun compiledecs context nil = nil
            | compiledecs context (dec::rem) = 
              let
                val {var=var as {name,ty}, expTy = ty', exp = tpexp} = dec
                val curItem = 
                    case PE.lookupVarInPathBasis(#pathBasis context,P.NilPath,name) of
                      NONE => raise Control.Bug ("undefined variable:"^ name)
                    | SOME item => item
                val newtfpexp = tpexpToTfpexp context tpexp
                val newdec = (
                              {
                               id = PE.getIdFromCurItem curItem,
                               displayName = 
                               PE.pathVarToString(PE.getPathVarFromItem curItem),
                               ty = ty
                               },
                              ty',
                              newtfpexp
                              )
                val newdecs = compiledecs context rem
              in
                newdec::newdecs
              end
          val newContext =
              MC.extendContextWithPathEnv(context, longNamePathEnv)
          val localDecs = compiledecs newContext decs
        in 
          (longNamePathEnv,
           [TFPVALPOLYREC (btvEnv,localDecs,loc)])
        end
      | TPVALRECGROUP (_, decs, loc) => tpdecsToTfpdecs context decs
      | TPLOCALDEC (localDecs, decs, loc) => 
        let
          val newContext = MC.updateContextWithPrefix(context,P.NilPath)
          val (pathEnv1, tfplocalDecs) = tpdecsToTfpdecs newContext localDecs
          val newContext = MC.extendContextWithPathEnv (context,pathEnv1)
          val (pathEnv2, tfpdecs) = tpdecsToTfpdecs newContext decs
        in 
          (pathEnv2,
           [TFPLOCALDEC(tfplocalDecs, tfpdecs, loc)]) 
        end
      | TPOPEN (strPathInfos,loc) =>
         let
           val newPathEnv = 
               foldl (fn (strPathInfo,Env) => 
                         let
                           val {name,strpath,id,...} = strPathInfo
                           val path = P.appendPath(strpath, id, name)
                           val Env1 = MC.lookupStructureInContext (context,path)
                         in
                           case Env1 of
                             SOME env => PE.mergePathEnv {newPathEnv=env,oldPathEnv=Env}
                           | NONE => raise Control.Bug ("undefined:"^P.pathToString(path))
                         end)
                     PE.emptyPathEnv
                     strPathInfos
         in
           (newPathEnv,nil)
         end
      | TPDATADEC (tyCons,loc) => (PE.emptyPathEnv,nil)
      | TPABSDEC ({absTyCons, rawTyCons,  decls}, loc) => 
        tpdecsToTfpdecs context decls
      | TPTYPE args => (PE.emptyPathEnv,nil)
      | TPDATAREPDEC _ => (PE.emptyPathEnv,nil)
      | TPEXNDEC (exnBinds,loc) => (PE.emptyPathEnv,nil)
      | TPINFIXDEC args =>  (PE.emptyPathEnv,nil)
      | TPINFIXRDEC args => (PE.emptyPathEnv,nil)
      | TPNONFIXDEC args => (PE.emptyPathEnv,nil)
      | TPFUNDECL (fundecl,_) =>
           (map  (fn {funVar = {name,...},...} => (print name; print "\n"))
            fundecl;
            raise Control.Bug "TPFUNDECL in module compiler"
              )
      | TPPOLYFUNDECL (_, fundecl ,_) =>
           (map  (fn {funVar = {name,...},...} => (print name; print "\n"))
            fundecl;
            raise Control.Bug "TPPOLYFUNDECL in module compiler"
              )


   and tpdecsToTfpdecs context nil = ((SEnv.empty,SEnv.empty), nil)
     | tpdecsToTfpdecs context (tpdec::tpdecs) 
       = 
       let
         val (pathEnv1,tfpdecs1) = tpdecToTfpdecs context tpdec
         val newContext = MC.extendContextWithPathEnv (context,pathEnv1)
         val (pathEnv2, tfpdecs2) = tpdecsToTfpdecs newContext tpdecs
       in
         (
          PE.mergePathEnv {
                           newPathEnv=pathEnv2,
                           oldPathEnv=pathEnv1
                           },
          tfpdecs1 @ tfpdecs2
         )
       end
         
end
end
