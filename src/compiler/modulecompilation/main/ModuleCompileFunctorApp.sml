(**
 *
 * Module compiler expands functor application.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompileFunctorApp.sml,v 1.46 2007/02/28 15:31:25 katsu Exp $
 *)
structure ModuleCompileFunctorApp  = 
struct
local

  structure T  = Types
  structure P = Path
  structure TO = TopObject
  structure PT = PredefinedTypes
  structure FAU = FunctorApplyUtils
  structure TFCU = TypedFlatCalcUtils
  structure PE =  PathEnv 
  structure MCU = ModuleCompileUtils
  datatype valIdent = datatype Types.valIdent
  open TypedCalc TypedFlatCalc 

in

   (****************************************************************************)
   (* functor template substitution for hole
    * pathHoleIdEnv : holeId |-> ((actualStrPath,name), actualId)
    * pathIdEnv : oldId |-> (path,freshId)  
    *)
   fun substituteHoleTfpdecs 
         pathHoleIdEnv pathIdEnv
         substTyEnv exnTagSubst nil 
     =        
        (nil, PE.emptyPathIdEnv)
     | substituteHoleTfpdecs 
         pathHoleIdEnv pathIdEnv
         substTyEnv exnTagSubst (tfpdec :: rem)  
     = 
       let
         val (tfpdec1, pathIdEnv1) = 
             substituteHoleTfpdec 
               pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpdec
         val newPathIdEnv = PE.mergePathIdEnv (pathIdEnv,pathIdEnv1)
         val (tfpdecs,pathIdEnv2) = 
             substituteHoleTfpdecs
               pathHoleIdEnv newPathIdEnv substTyEnv exnTagSubst rem
       in
         (
          tfpdec1 :: tfpdecs,
          PE.mergePathIdEnv (pathIdEnv2,pathIdEnv1)
         )
       end

   and substituteHoleTfpdec 
         pathHoleIdEnv pathIdEnv
         substTyEnv exnTagSubst tfpdec 
     = 
     case tfpdec of
       TFPVAL (valdecs, loc) =>
       let
         val (newValDecs, pathIdEnv) = 
             foldr ( 
                    fn ((valId,tfpexp),(newValDecs, incPathIdEnv)) =>
                       let
                         val newTfpexp =
                             substituteHoleTfpexp 
                               pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp
                         val (newValId, pathIdEnv1) = 
                             case valId of
                               VALIDENT (varIdInfo as {id = oldId, displayName, ty}) => 
                               let
                                 val newId = T.newVarId()
                                 val newTy = FAU.instantiateTy substTyEnv ty
                               in
                                 (
                                  VALIDENT { 
                                               id = newId,
                                               displayName = displayName,
                                               ty = newTy
                                               },
                                  ID.Map.singleton (oldId,(displayName, newId))
                                  )
                               end
                             | VALIDENTWILD ty => 
                               let
                                 val newTy = FAU.instantiateTy substTyEnv ty
                               in
                                 (VALIDENTWILD newTy, PE.emptyPathIdEnv)
                               end
                       in
                         (
                          (newValId,newTfpexp) :: newValDecs,
                          PE.mergePathIdEnv (pathIdEnv1, incPathIdEnv)
                          )
                       end
                         )
                   (nil, ID.Map.empty)
                   valdecs
       in
         (TFPVAL (newValDecs, loc), pathIdEnv) 
       end
     | TFPVALREC (valRecDecs, loc) =>
       let
         val incPathIdEnv = 
             foldr (
                    fn ((varIdInfo as {id = oldId,displayName,ty}, _, _), newPathIdEnv) => 
                       let
                         val newId = T.newVarId()
                       in
                         ID.Map.insert(newPathIdEnv, oldId,(displayName, newId))
                       end
                   )
                   PE.emptyPathIdEnv
                   valRecDecs
         val updatedPathIdEnv = PE.mergePathIdEnv (incPathIdEnv, pathIdEnv)
         val newValRecDecs =
             foldr ( 
                    fn (({id,displayName,ty=ty1}, ty, tfpexp),
                        newValRecDecs) =>
                       let
                         val (_, newId) = 
                             case PE.lookupPathIdEnv(incPathIdEnv, id) of
                               SOME (varPath, newId) => (varPath, newId)
                             | NONE => raise Control.Bug ("unbound var:"^displayName)
                         val newTy = FAU.instantiateTy substTyEnv ty1
                         val newValInfo = {
                                           id = newId,
                                           displayName = displayName,
                                           ty = newTy
                                           }
                         val newTfpexp = 
                             substituteHoleTfpexp
                               pathHoleIdEnv updatedPathIdEnv substTyEnv exnTagSubst tfpexp
                       in
                         (newValInfo,newTy,newTfpexp) :: newValRecDecs
                       end
                   )
                   nil
                   valRecDecs
       in
         (TFPVALREC (newValRecDecs, loc), incPathIdEnv)
       end
     | TFPVALPOLYREC (btvKind,valPolyRecDecs,loc) =>
       let
         val incPathIdEnv = 
             foldr (
                    fn ((varIdentInfo as {id = oldId, displayName, ty}, _, _), newPathIdEnv) => 
                       let
                         val newId = T.newVarId()
                       in
                         ID.Map.insert(newPathIdEnv, oldId, (displayName, newId))
                       end
                   )
                   PE.emptyPathIdEnv
                   valPolyRecDecs
         val updatedPathIdEnv = PE.mergePathIdEnv (incPathIdEnv, pathIdEnv)
         val newValPolyRecDecs =
             foldr ( 
                    fn (({id,displayName,ty=ty1}, ty, tfpexp), newValRecDecs) =>
                       let
                         val (_, newId) = 
                             case PE.lookupPathIdEnv(incPathIdEnv, id) of
                               SOME (varPath, newId) =>
                               (varPath, newId)
                             | NONE => raise Control.Bug ("unbound"^displayName)
                         val newTy = FAU.instantiateTy substTyEnv ty1
                         val newValInfo = {
                                           id = newId,
                                           displayName = displayName,
                                           ty = newTy
                                           }
                         val newTfpexp = 
                             substituteHoleTfpexp
                               pathHoleIdEnv updatedPathIdEnv substTyEnv exnTagSubst tfpexp
                       in
                         (newValInfo,newTy,newTfpexp) :: newValRecDecs
                       end
                         )
                   nil
                   valPolyRecDecs
       in
         (TFPVALPOLYREC(btvKind,newValPolyRecDecs,loc), incPathIdEnv)
       end
     | TFPLOCALDEC (tfpdecs1,tfpdecs2,loc) =>
       let
         val (tfpdecs1, pathIdEnv1) = 
             substituteHoleTfpdecs 
               pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpdecs1
         val newPathIdEnv = PE.mergePathIdEnv (pathIdEnv1,pathIdEnv)
         val (tfpdecs2, pathIdEnv2) = 
             substituteHoleTfpdecs 
               pathHoleIdEnv newPathIdEnv substTyEnv exnTagSubst tfpdecs2
       in
         (
          TFPLOCALDEC (tfpdecs1,tfpdecs2,loc),
          pathIdEnv2
          )
       end
     | TFPSETGLOBALVALUE (arrayIndex, offset, tfpexp, ty, loc) =>
       let
         val newTfpexp =
             substituteHoleTfpexp 
               pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp
         val newTy = FAU.instantiateTy substTyEnv ty
       in
         (
          TFPSETGLOBALVALUE (arrayIndex, offset, newTfpexp, ty, loc),
          PE.emptyPathIdEnv
          )
       end
     | TFPINITARRAY (arrayIndex, offset, ty, loc) =>
       (
        TFPINITARRAY (arrayIndex, 
                      offset, 
                      FAU.instantiateTy substTyEnv ty, 
                      loc),
        PE.emptyPathIdEnv
        )
     | _ => (tfpdec, PE.emptyPathIdEnv)

         
   and substituteHoleTfpexpList (pathHoleIdEnv : PE.pathHoleIdEnv)
                                (pathIdEnv : PE.pathIdEnv) 
                                substTyEnv 
                                exnTagSubst 
                                tfpexpList 
     =
     map (fn tfpexp => 
             substituteHoleTfpexp 
               pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp
             )
         tfpexpList
         
   and substituteHoleTfpexp (pathHoleIdEnv : PE.pathHoleIdEnv)
                            (pathIdEnv : PE.pathIdEnv) 
                            substTyEnv 
                            exnTagSubst 
                            tfpexp =
       case tfpexp of
         TFPFOREIGNAPPLY {funExp=foreignFunInfo, funTy, instTyList=tyList, 
                          argExpList=tfpexpList, argTyList=argTys, convention, loc} => 
         let
           val newForeignFunInfo =
               substituteHoleTfpexp
                 pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst foreignFunInfo
           val newTfpexpList =
               substituteHoleTfpexpList
                 pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexpList
         in
           TFPFOREIGNAPPLY {funExp=newForeignFunInfo, 
                            funTy=funTy,
                            instTyList=tyList, 
                            argExpList=newTfpexpList, 
                            argTyList=argTys,
                            convention=convention,
                            loc=loc}
         end
       | TFPEXPORTCALLBACK {funExp, instTyList, argTyList, resultTy, loc} =>
         let
           val tfpFunExp =
               substituteHoleTfpexp
                 pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst funExp
         in
           TFPEXPORTCALLBACK {funExp=funExp,
                              instTyList=instTyList, 
                              argTyList=argTyList,
                              resultTy=resultTy,
                              loc=loc}
         end
       | TFPSIZEOF _ => tfpexp
       | TFPCONSTANT _ => tfpexp
       | TFPVAR (varIdInfo as {id,displayName,ty}, loc) => 
         let
           val newTfpexp = 
               case PE.lookupPathHoleIdEnv(pathHoleIdEnv, id) of  
                 (* functor argument *)
                 SOME (PE.TopItem (pathVar, index, _)) =>
                 TFPGETGLOBALVALUE(TO.getPageArrayIndex index,
                                   TO.getOffset index, 
                                   FAU.instantiateTy substTyEnv ty, 
                                   loc)
               | SOME (PE.CurItem (pathVar, mappedId, _, _)) =>
                 TFPVAR
                   ({
                     id = mappedId,
                     displayName = displayName,
                     ty = FAU.instantiateTy substTyEnv ty
                     },
                    loc)
               (* inside body or outside body variable reference *)
               | NONE => 
                 case PE.lookupPathIdEnv(pathIdEnv, id) of  
                   (* variable inside body *)
                   SOME (_, id) => 
                   TFPVAR
                     ({id = id, 
                       displayName = displayName,
                       ty = FAU.instantiateTy substTyEnv ty},
                      loc)
                 | NONE => 
                   (* local variable *)
                   TFPVAR
                     ({id = id, 
                       displayName = displayName, 
                       ty = FAU.instantiateTy substTyEnv ty
                       },
                      loc)
         in
           newTfpexp
         end 
       | TFPGETGLOBAL _ => tfpexp
       | TFPGETFIELD (tfpexp, int, ty, loc) => 
         TFPGETFIELD (substituteHoleTfpexp 
                        pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp, 
                      int, 
                      FAU.instantiateTy substTyEnv ty, 
                      loc) 
       | TFPGETGLOBALVALUE (arrayIndex, offset, ty, loc) => 
         TFPGETGLOBALVALUE (arrayIndex, offset, FAU.instantiateTy substTyEnv ty, loc) 
       | TFPARRAY _ => tfpexp
       | TFPPRIMAPPLY {primOp=primInfo,instTyList=tys, argExpOpt=tfpexpopt,loc=loc} =>
         let
           val newTfpexpopt = 
               case tfpexpopt of
                 NONE => NONE
               | SOME exp =>
                 let
                   val newTfpexp = 
                       substituteHoleTfpexp 
                         pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst exp
                 in
                   SOME newTfpexp
                 end
         in
           TFPPRIMAPPLY{primOp=primInfo,
                         instTyList=map (FAU.instantiateTy substTyEnv) tys,
                         argExpOpt=newTfpexpopt,
                         loc=loc}
         end
       | TFPOPRIMAPPLY {oprimOp=oprimInfo, instances=tys, argExpOpt=tfpexpopt,loc=loc} =>
         let
           val newTfpexpopt = 
               case tfpexpopt of
                 NONE => NONE
               | SOME exp => 
                 let
                   val newTfpexp = 
                       substituteHoleTfpexp 
                         pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst exp
                 in
                   SOME newTfpexp
                 end
         in
           TFPOPRIMAPPLY{oprimOp=oprimInfo,
                         instances=map (FAU.instantiateTy substTyEnv) tys,
                         argExpOpt=newTfpexpopt,
                         loc=loc}
         end
       | TFPCONSTRUCT {con=conInfo as {displayName,funtyCon,ty,tag,tyCon},
                       instTyList=tys,
                       argExpOpt=tfpexpopt,
                       loc=loc} =>
         let 
           val newTag = 
               if ID.eq(#id tyCon, PT.exnTyConid) then
                 case IEnv.find(exnTagSubst,tag) of
                   NONE => tag
                 | SOME newTag => newTag
               else tag
           val newConInfo = {
                             displayName = displayName,
                             funtyCon = funtyCon, 
                             ty = FAU.instantiateTy substTyEnv ty, 
                             tag = newTag, 
                             tyCon = FAU.instantiateTyCon substTyEnv tyCon
                            }
           val newTfpexpopt = 
               case tfpexpopt of
                 NONE => NONE
               | SOME exp => 
                 let
                   val newTfpexp = 
                       substituteHoleTfpexp
                         pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst exp
                 in
                   SOME newTfpexp
                 end
         in
           TFPCONSTRUCT{con=newConInfo,
                        instTyList=map (FAU.instantiateTy substTyEnv) tys,
                        argExpOpt=newTfpexpopt,
                        loc=loc}
         end
       | TFPAPPM{funExp=tfpexp1, funTy=ty, argExpList=tfpexpList2, loc=loc} =>
          let
            val newTfpexp1 = 
                substituteHoleTfpexp 
                  pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp1
            val newTfpexpList2 = 
                substituteHoleTfpexpList
                  pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexpList2
          in
            TFPAPPM {funExp=newTfpexp1,
                     funTy=FAU.instantiateTy substTyEnv ty,
                     argExpList=newTfpexpList2,
                     loc=loc}
          end
       | TFPMONOLET {binds, bodyExp=tfpexp, loc=loc} =>
         let
           val (newBinds, newPathIdEnv) = 
               foldl ( fn ((varInfo as {id, displayName, ty}, tfpexp), 
                           (newBinds, pathIdEnv)) => 
                          let
                            val newVar as {id = newId, ...} = 
                                { 
                                 id = T.newVarId(),
                                 displayName = displayName,
                                 ty = FAU.instantiateTy substTyEnv ty
                                 }
                            val newPathIdEnv = 
                                ID.Map.insert (pathIdEnv, id, (displayName, newId))
                            val newTy = FAU.instantiateTy substTyEnv ty
                            val newTfpexp =
                                substituteHoleTfpexp
                                  pathHoleIdEnv newPathIdEnv substTyEnv 
                                  exnTagSubst tfpexp
                          in
                            (newBinds @ 
                             [(newVar, newTfpexp)],
                             newPathIdEnv)
                          end
                      )
                     (nil, pathIdEnv)
                     binds
           val newTfpexp = 
               substituteHoleTfpexp
                 pathHoleIdEnv newPathIdEnv substTyEnv exnTagSubst tfpexp
         in
           TFPMONOLET {binds=newBinds, bodyExp=newTfpexp, loc=loc}
         end
       | TFPLET(tfpdecs, tfpexps, tys, loc) =>
         let
           val (newTfpdecs,pathIdEnv1) = 
               substituteHoleTfpdecs 
                 pathHoleIdEnv
                 pathIdEnv 
                 substTyEnv 
                 exnTagSubst 
                 tfpdecs
           val newPathIdEnv = PE.mergePathIdEnv (pathIdEnv1,pathIdEnv)
           val newTfpexps = 
               map (fn tfpexp =>
                       substituteHoleTfpexp 
                         pathHoleIdEnv newPathIdEnv substTyEnv 
                         exnTagSubst tfpexp
                   )
                   tfpexps
         in
           TFPLET(newTfpdecs,
                  newTfpexps,
                  map (FAU.instantiateTy substTyEnv) tys,
                  loc)
         end
       | TFPRECORD {fields, recordTy=ty, loc=loc} =>
         let
           val newFields = 
               SEnv.map (fn tfpexp => 
                            substituteHoleTfpexp 
                              pathHoleIdEnv pathIdEnv substTyEnv
                              exnTagSubst tfpexp
                        )
                        fields
         in
           TFPRECORD {fields=newFields, 
                      recordTy=FAU.instantiateTy substTyEnv ty, 
                      loc=loc}
         end
       | TFPSELECT {label=string, exp=tfpexp, expTy=ty, loc=loc} =>
          let
            val newTfpexp =
                substituteHoleTfpexp
                  pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp
          in
            TFPSELECT{label=string, exp=newTfpexp, expTy=FAU.instantiateTy substTyEnv ty, loc=loc}
          end
       | TFPMODIFY {label=string, 
                    recordExp=tfpexp1, 
                    recordTy=ty1, 
                    elementExp=tfpexp2, 
                    elementTy=ty2,
                    loc=loc} =>
          let
            val newTfpexp1 = 
                substituteHoleTfpexp 
                  pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp1
            val newTfpexp2 =
                substituteHoleTfpexp 
                  pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp2
          in
            TFPMODIFY {label=string,
                       recordExp=newTfpexp1,
                       recordTy=FAU.instantiateTy substTyEnv ty1,
                       elementExp=newTfpexp2,
                       elementTy=FAU.instantiateTy substTyEnv ty2,
                       loc=loc}
          end
       | TFPRAISE (tfpexp,ty,loc) => 
         let
           val newTfpexp = 
               substituteHoleTfpexp 
                 pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp
         in
           TFPRAISE (newTfpexp,FAU.instantiateTy substTyEnv ty,loc)
         end
       | TFPHANDLE {exp=tfpexp1, 
                    exnVar=varInfo as {id, displayName, ty}, 
                    handler=tfpexp2, 
                    loc=loc} =>
         let
           val newTfpexp1 = 
               substituteHoleTfpexp 
                 pathHoleIdEnv pathIdEnv substTyEnv exnTagSubst tfpexp1
           val newVar as {id = newId, ...} = 
               { 
                id = T.newVarId(),
                displayName = displayName,
                ty = FAU.instantiateTy substTyEnv ty
                }
           val newPathIdEnv = 
               ID.Map.insert (
                              pathIdEnv, 
                              id,
                              (displayName, newId)
                              )
           val newTfpexp2 =
               substituteHoleTfpexp 
                 pathHoleIdEnv newPathIdEnv substTyEnv exnTagSubst tfpexp2
         in
           TFPHANDLE {exp=newTfpexp1,
                      exnVar={
                              id = newId,
                              displayName = displayName,
                              ty = FAU.instantiateTy substTyEnv ty},
                      handler=newTfpexp2,
                      loc=loc}
         end
       | TFPCASEM {expList=tfpexpList1,
                   expTyList=tyList1,
                   ruleList=cases,
                   ruleBodyTy=ty2,
                   caseKind=caseKind,
                   loc=loc} =>
         let
           val newTfpexpList1 =
               substituteHoleTfpexpList
                 pathHoleIdEnv pathIdEnv substTyEnv 
                 exnTagSubst tfpexpList1
           val newCases = 
               map (fn (tfppatList,tfpexp) =>
                       let
                         val (tfppatList1, pathIdEnv1) = 
                             substituteHoleTfppatList
                               pathHoleIdEnv substTyEnv  
                               exnTagSubst tfppatList
                         val newPathIdEnv =
                             PE.mergePathIdEnv(pathIdEnv1,pathIdEnv)
                         val newTfpexp = 
                             substituteHoleTfpexp 
                               pathHoleIdEnv newPathIdEnv substTyEnv 
                               exnTagSubst tfpexp
                       in
                         (tfppatList1,newTfpexp)
                       end
                     )
                   cases
         in
           TFPCASEM {expList=newTfpexpList1,
                     expTyList=map (FAU.instantiateTy substTyEnv) tyList1,
                     ruleList=newCases,
                     ruleBodyTy=FAU.instantiateTy substTyEnv ty2,
                     caseKind=caseKind,
                     loc=loc}
         end
       | TFPFNM {argVarList=varList,
                 bodyTy=ty1,
                 bodyExp=tfpexp,
                 loc=loc} => 
         let
           val idAndNewArglist = 
               map (fn {id, displayName, ty} =>
                       (id,
                        { 
                         id = T.newVarId(),
                         displayName = displayName,
                         ty = FAU.instantiateTy substTyEnv ty
                         })
                       )
                   varList
           val newPathIdEnv = 
               foldl 
                 (fn ((id, {id=newId, displayName, ty}), pathIdEnv) =>
                     ID.Map.insert (pathIdEnv, 
                                    id,
                                    (displayName, newId)
                                    )
                     )
                 pathIdEnv
                 idAndNewArglist
           val newTfpexp =
               substituteHoleTfpexp
                 pathHoleIdEnv newPathIdEnv substTyEnv 
                 exnTagSubst tfpexp
         in
           TFPFNM {argVarList=map #2 idAndNewArglist,
                   bodyTy=FAU.instantiateTy substTyEnv ty1,
                   bodyExp=newTfpexp,
                   loc=loc}
         end
       | TFPPOLYFNM {btvEnv=btvKind,
                     argVarList=varList,
                     bodyTy=ty1,
                     bodyExp=tfpexp,
                     loc=loc} =>
         let
           val idAndNewArglist = 
             map (fn {id, displayName, ty} =>
                  (id,
                   { 
                    id = T.newVarId(),
                    displayName = displayName,
                    ty = FAU.instantiateTy substTyEnv ty
                    })
                  )
                 varList
           val newPathIdEnv = 
               foldl 
                 (fn ((id, {id=newId, displayName, ty}), pathIdEnv) =>
                     ID.Map.insert (pathIdEnv, 
                                    id,
                                    (displayName, newId)
                                    )
                     )
                 pathIdEnv
                 idAndNewArglist
           val newTfpexp =
               substituteHoleTfpexp
                 pathHoleIdEnv newPathIdEnv substTyEnv 
                 exnTagSubst tfpexp
         in
           TFPPOLYFNM
             {btvEnv=IEnv.map (FAU.instantiateBtvKind substTyEnv) btvKind,
              argVarList=map #2 idAndNewArglist,
              bodyTy=FAU.instantiateTy substTyEnv ty1,
              bodyExp=newTfpexp,
              loc=loc}
         end
       | TFPPOLY {btvEnv=btvKind,
                  expTyWithoutTAbs=ty,
                  exp=tfpexp,
                  loc=loc} =>
         let
           val newTfpexp =
               substituteHoleTfpexp 
                 pathHoleIdEnv pathIdEnv substTyEnv
                 exnTagSubst tfpexp
         in                    
           TFPPOLY {btvEnv=IEnv.map (FAU.instantiateBtvKind substTyEnv) btvKind,
                    expTyWithoutTAbs=FAU.instantiateTy substTyEnv ty,
                    exp=newTfpexp,
                    loc=loc}
         end
       | TFPTAPP {exp=tfpexp, expTy=ty, instTyList=tys, loc=loc} =>
         let
           val newTfpexp =
               substituteHoleTfpexp 
                 pathHoleIdEnv pathIdEnv substTyEnv 
                 exnTagSubst tfpexp
           val newty = FAU.instantiateTy substTyEnv ty
           val newtys = map (FAU.instantiateTy substTyEnv) tys
         in           
           TFPTAPP {exp=newTfpexp,
                    expTy=newty,
                    instTyList=newtys,
                    loc=loc}
         end
       | TFPSEQ {expList=tfpexps, expTyList=tys,loc=loc} =>
         let
           val newTfpexps =
               map ( fn tfpexp =>
                        substituteHoleTfpexp 
                          pathHoleIdEnv pathIdEnv substTyEnv 
                          exnTagSubst tfpexp
                        )
                   tfpexps
         in           
           TFPSEQ {expList=newTfpexps, expTyList=map (FAU.instantiateTy substTyEnv) tys, loc=loc}
         end
       | TFPCAST (tfpexp,ty,loc) => 
         let
           val newTfpexp = 
               substituteHoleTfpexp 
                 pathHoleIdEnv pathIdEnv substTyEnv
                 exnTagSubst tfpexp
         in
           TFPCAST (newTfpexp,FAU.instantiateTy substTyEnv ty,loc)
         end

   and substituteHoleTfppatList 
         pathHoleIdEnv substTyEnv exnTagSubst tfppatList =
       foldl (fn (pat, (newPats, newPathIdEnv)) => 
            let
              val (tfppat, pathIdEnv) =
                substituteHoleTfppat 
                  pathHoleIdEnv substTyEnv exnTagSubst pat
            in
              (newPats @ [tfppat] ,
               PE.mergePathIdEnv(pathIdEnv, newPathIdEnv)
               )
            end
            )
     (nil, PE.emptyPathIdEnv) 
     tfppatList

   and substituteHoleTfppat pathHoleIdEnv substTyEnv exnTagSubst tfppat =
       case tfppat of
         TFPPATWILD (ty,loc) => 
         (TFPPATWILD (FAU.instantiateTy substTyEnv ty,loc), PE.emptyPathIdEnv)
       | TFPPATVAR ({id,displayName,ty},loc) =>
         let
           val newTy = FAU.instantiateTy substTyEnv ty
           val newId = T.newVarId()
         in
           (
            TFPPATVAR({id = newId,
                       displayName = displayName,
                       ty = newTy
                       },
                      loc
                      ),
            ID.Map.singleton (id, (displayName, newId))
            )
         end
       | TFPPATCONSTANT _ => (tfppat, PE.emptyPathIdEnv)
       | TFPPATCONSTRUCT {
                          conPat=conIdInfo as {displayName,funtyCon,ty,tag,tyCon},
                          instTyList=tys,
                          argPatOpt=tfppatopt,
                          patTy=ty1,
                          loc=loc
                          } =>
         let
           val newTag = 
               if ID.eq(#id tyCon, PT.exnTyConid) then 
                 case IEnv.find(exnTagSubst, tag) of
                   NONE => tag
                 | SOME newTag => newTag
               else tag
           val newTyCon = FAU.instantiateTyCon substTyEnv tyCon
           val newConIdInfo = {
                               displayName = displayName,
                               funtyCon = funtyCon, 
                               ty = FAU.instantiateTy substTyEnv ty, 
                               tag = newTag, 
                               tyCon= newTyCon
                               }
           val (newTfppatopt, newPathIdEnv) =
               case tfppatopt of
                 NONE => (NONE, PE.emptyPathIdEnv) 
               | SOME tfppat => 
                 let
                   val (newTfppat, newPathIdEnv) =
                       substituteHoleTfppat 
                         pathHoleIdEnv substTyEnv exnTagSubst tfppat
                 in
                   (SOME newTfppat, newPathIdEnv)
                 end
         in
           (
            TFPPATCONSTRUCT {
                             conPat=newConIdInfo,
                             instTyList=map (FAU.instantiateTy substTyEnv) tys,
                             argPatOpt=newTfppatopt,
                             patTy=FAU.instantiateTy substTyEnv ty1,
                             loc=loc
                             },
            newPathIdEnv
            )
         end
       | TFPPATRECORD {fields=patfields,recordTy=ty,loc=loc} =>
         let
           val (newPatFields, pathIdEnv) = 
               SEnv.foldli (fn (label, pat, (newPats, newPathIdEnv)) => 
                              let
                                val (tfppat, pathIdEnv) =
                                    substituteHoleTfppat 
                                      pathHoleIdEnv substTyEnv exnTagSubst pat
                              in
                                (SEnv.insert(newPats, label, tfppat),
                                 PE.mergePathIdEnv(pathIdEnv, newPathIdEnv)
                                 )
                              end
                                )
                           (SEnv.empty,PE.emptyPathIdEnv)
                           patfields
         in
           (
            TFPPATRECORD{fields=newPatFields,
                         recordTy=FAU.instantiateTy substTyEnv ty,
                         loc=loc},
            pathIdEnv
            )
         end
       | TFPPATLAYERED {varPat=tfppat1,asPat=tfppat2,loc=loc} =>
         let
           val(tfppat1', pathIdEnv1) =
              substituteHoleTfppat 
                pathHoleIdEnv substTyEnv exnTagSubst tfppat1
           val(tfppat2', pathIdEnv2) =
              substituteHoleTfppat 
                pathHoleIdEnv substTyEnv exnTagSubst tfppat2
         in
           (
            TFPPATLAYERED {varPat=tfppat1', asPat=tfppat2',loc=loc},
            PE.mergePathIdEnv(pathIdEnv2, pathIdEnv1)
           )
         end
end
end
