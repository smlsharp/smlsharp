(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_Optimizer.sml,v 1.25 2006/02/18 16:04:07 duchuu Exp $
 *)
structure VALREC_Optimizer :> VALREC_OPTIMIZER = struct

  open PatternCalc
  open Graph
  open VALREC_Utils

  type recNodeinfo = {functionId : string,
                      dependentIds : SSet.set,
                      functionDecl : plpat * plexp }
  
  type funNodeinfo = {functionId : string,
                      dependentIds : SSet.set,
                      functionDecl : plpat * (plpat list * plexp) list}
  
  fun optimizeExp globalContext context plexp =
      case plexp of
        PLCONSTANT _ => plexp
      | PLVAR _ => plexp
      | PLTYPED (exp,ty,loc) =>
        PLTYPED (optimizeExp globalContext context exp, ty, loc)
      | PLAPPM (funExp, argExpList, loc) =>
        PLAPPM (optimizeExp globalContext context funExp,
                map (optimizeExp globalContext context) argExpList,
               loc)
      | PLLET (localDeclList, mainExpList, loc) =>
        let
          val (_,newLocalDeclList) = 
              optimizeDeclList globalContext context localDeclList
        in
          PLLET (newLocalDeclList,
                 map (optimizeExp globalContext context) mainExpList,
                 loc)
        end
      | PLRECORD (elementList, loc) =>
        PLRECORD (map 
                      (fn (label, exp) => (label, optimizeExp globalContext context exp))
                      elementList,
                  loc)
      | PLRECORD_UPDATE (exp, elementList, loc) =>
        PLRECORD_UPDATE (optimizeExp globalContext context exp,
                         map (fn (label, exp) => (label, optimizeExp globalContext context exp))
                             elementList,
                         loc)
      | PLTUPLE (elementList,loc) =>
        PLTUPLE (map (optimizeExp globalContext context) elementList,loc)
      | PLRAISE (exp,loc) => 
        PLRAISE (optimizeExp globalContext context exp, loc)
      | PLHANDLE (handler, matchList, loc) =>
        PLHANDLE (optimizeExp globalContext context handler,
                  map 
                      (fn (pat,exp) => (pat, optimizeExp globalContext context exp))
                      matchList,
                  loc)
      | PLFNM (matchList, loc) =>
        PLFNM (map 
                  (fn (patList,exp) => (patList, optimizeExp globalContext context exp))
                  matchList,
              loc)
      | PLCASEM (selectorList, matchList, kind, loc) =>
        PLCASEM (map (optimizeExp globalContext context) selectorList,
                map
                    (fn (patList,exp) => (patList, optimizeExp globalContext context exp))
                    matchList,
                kind,
                loc)
      | PLRECORD_SELECTOR _ => plexp
      | PLSELECT (label,exp,loc) =>
        PLSELECT (label, optimizeExp globalContext context exp, loc)
      | PLSEQ (expList, loc) =>
        PLSEQ (map (optimizeExp globalContext context) expList, loc)
      | PLCAST (exp, loc) =>
        PLCAST (optimizeExp globalContext context exp, loc)

  and optimizeRule globalContext (context:context) patListExpList =
     map (fn (patList,exp) => (patList, optimizeExp globalContext context exp))
     patListExpList
    
  and optimizeDecl globalContext (context:context) pdecl  =
      case pdecl of 
        PDVAL(tvarList,declList,loc) =>
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [PDVAL(tvarList,
                (map (fn (pat,exp) => (pat,optimizeExp globalContext context exp))) declList,
                loc)]
         )
      | PDDECFUN (tvarList, declList, loc) =>
        let
          fun getUniqueID pat =
              case pat of
                PLPATID (fid,_) => Absyn.longidToString(fid)
              | PLPATTYPED(pat',_,_) => getUniqueID pat'
              | _ => raise Control.Bug "incorrect function name"
          val boundIDList = map (getUniqueID o #1) declList
          val g = Graph.empty :  funNodeinfo Graph.graph
          val g =
              foldl 
                  (fn ((fidpat, rules),g) =>
                      let 
                        val fid = getUniqueID fidpat
                        val dependentIds = getFreeIdsInRule globalContext context rules
                      in
                        #1 (Graph.addNode
                                g
                                {functionId=fid,
                                 dependentIds=dependentIds,
                                 functionDecl=(fidpat, optimizeRule globalContext context rules)})
                      end)
                  (Graph.empty : funNodeinfo Graph.graph)
                  declList
          val nodeList = Graph.listNodes g
          val g = 
              foldl
                  (fn ((nid1,{dependentIds as dids1 , ... }), g) =>
                      foldl 
                          (fn ((nid2,{functionId as fid2,... }),g) =>
                              if SSet.member(dids1, fid2)
                              then Graph.addEdge g (nid2,nid1)
                              else g)
                          g
                          nodeList)
                  g
                  nodeList
          val scc = Graph.scc g          
        in
          (
           injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
           [PDVALRECGROUP
              (
               boundIDList,
               map 
                 (fn nidList =>
                     case nidList of 
                       [] => raise Control.Bug "recval"
                     | [nid] =>
                       let
                         val {functionId,dependentIds,functionDecl} =
                             case Graph.getNodeInfo g nid of
                               NONE => raise Control.Bug "val rec"
                             | SOME info => info
                       in
                         if SSet.member(dependentIds,functionId)
                         then PDDECFUN (tvarList, [functionDecl], loc)
                         else PDNONRECFUN (tvarList, functionDecl, loc)
                       end
                     | _ => 
                       let
                         val functionDeclList =
                             foldr 
                               (fn (nid,S) =>
                                   case Graph.getNodeInfo g nid of
                                     NONE => raise Control.Bug "val rec"
                                   | SOME info => (#functionDecl info)::S)
                               []
                               nidList
                       in
                         PDDECFUN (tvarList,functionDeclList,loc)
                       end
                         )
                 scc,
                 loc
                 )]
           )
        end
      | PDVALREC (tvarList,declList,loc) =>
        let
          fun getUniqueID pat =
              case pat of
                PLPATID (fid,_) => Absyn.longidToString(fid)
              | PLPATTYPED(pat',_,_) => getUniqueID pat'
              | _ => raise Control.Bug "incorrect function name"
          val boundIDList = map (getUniqueID o #1) declList
          val g = Graph.empty :  recNodeinfo Graph.graph
          val g =
              foldl 
                  (fn ((pat,exp),g) =>
                      let 
                        val fid = getUniqueID pat
                        val dependentIds = getFreeIdsInExp globalContext context exp
                      in
                        #1 (Graph.addNode
                                g
                                {functionId=fid,
                                 dependentIds=dependentIds,
                                 functionDecl=(pat,optimizeExp globalContext context exp)})
                      end)
                  (Graph.empty : recNodeinfo Graph.graph)
                  declList
          val nodeList = Graph.listNodes g
          val g = 
              foldl
                  (fn ((nid1,{dependentIds as dids1 , ... }), g) =>
                      foldl 
                          (fn ((nid2,{functionId as fid2,... }),g) =>
                              if SSet.member(dids1, fid2)
                              then Graph.addEdge g (nid2,nid1)
                              else g)
                          g
                          nodeList)
                  g
                  nodeList
          val scc = Graph.scc g          
        in
          (
           injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
           [PDVALRECGROUP
              (
               boundIDList,
               map 
                 (fn nidList =>
                     case nidList of 
                       [] => raise Control.Bug "recval"
                     | [nid] =>
                       let
                         val {functionId,dependentIds,functionDecl} =
                             case Graph.getNodeInfo g nid of
                               NONE => raise Control.Bug "val rec"
                             | SOME info => info
                       in
                         if SSet.member(dependentIds,functionId)
                         then PDVALREC (tvarList,[functionDecl],loc)
                         else PDVAL (tvarList,[functionDecl],loc)
                       end
                     | _ => 
                       let
                         val functionDeclList =
                             foldr 
                               (fn (nid,S) =>
                                   case Graph.getNodeInfo g nid of
                                     NONE => raise Control.Bug "val rec"
                                   | SOME info => (#functionDecl info)::S)
                               []
                               nidList
                       in
                         PDVALREC (tvarList,functionDeclList,loc)
                       end
                         )
                 scc,
                 loc
                 )]
           )
        end
      | PDOPEN (longids,loc) => 
        let
          val incContext = 
              foldl (
                     fn (longid,incContext) =>
                        let
                          val (varSet,strMap) = 
                              lookupStructure (globalContext, context, longid)
                          val newContext = (varSet,strMap,SEnv.empty)
                        in
                          extendContextWithContext(incContext,newContext)
                        end
                    )
                    emptyContext
                    longids
        in
          (incContext,[pdecl])
        end
      | PDTYPE _ => (emptyContext,[pdecl])
      | PDDATATYPE _ => 
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDABSTYPE _ => 
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDREPLICATEDAT _ => 
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDEXD _ => 
        (         
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDLOCALDEC (localDeclList,mainDeclList,loc) =>
        let
          val (context1,newLocalDeclList) =
              optimizeDeclList globalContext context localDeclList
          val (context2,newMainDeclList) =
              optimizeDeclList globalContext
                               (extendContextWithContext(context,context1))
                               mainDeclList
        in
          (
           extendContextWithContext(context1,context2),
           [PDLOCALDEC (newLocalDeclList,
                        newMainDeclList,
                        loc)]
           )
        end
      | PDINFIXDEC _ => (emptyContext,[pdecl])
      | PDINFIXRDEC _ => (emptyContext,[pdecl])
      | PDNONFIXDEC _ => (emptyContext,[pdecl])
      | PDEMPTY => (emptyContext,[pdecl])
      | PDFFIVAL{name, funExp, libExp, argTyList, resultTy, loc} =>
        (
          injectVarSetInEmptyContext (SSet.singleton name),
          [PDFFIVAL
               {
                 name=name,
                 funExp = optimizeExp globalContext context funExp,
                 libExp = optimizeExp globalContext context libExp,
                 argTyList = argTyList,
                 resultTy = resultTy,
                 loc = loc
               }]
        )
      | _ => raise Control.Bug "invalid declaration"

  and optimizeDeclList globalContext context pdeclList =
      foldl ( fn (pdecl,(incContext, result)) =>
                 let
                   val (context1, newPdecl) =
                       optimizeDecl globalContext context pdecl
                 in
                   (
                    extendContextWithContext(incContext,context1),
                    result @ newPdecl
                    )
                 end
                   )
            (emptyContext, nil)
            pdeclList

(*      foldr 
        (fn (pdecl,result) => (optimizeDecl pdecl) @ result)
          []
          pdeclList*)

  
  (***************module language *******************)
 fun optimizestrdec (globalContext:globalContext) (context:context) (plstrdec:plstrdec) =
     case plstrdec of
       PLCOREDEC (pdecl,loc) => 
       let
         val (context1, newPdecls) = optimizeDecl globalContext context pdecl
         val coredec  =
             map (fn dec => PLCOREDEC(dec,loc)) newPdecls 
       in
         (context1,coredec :plstrdec list)
       end 
     | PLSTRUCTBIND (plstrbinds,loc) =>
       let
         val (context1,bindpairs) =
             foldl (fn ((string,plstrexp),(incContext,bindpair)) =>
                       let
                         val (context1,newPlstrexp) =
                             optimizestrexp globalContext context plstrexp
                         val (varSet,strMap) =
                             extractMapFromContext context1
                       in
                         (
                          bindStrInContext(incContext, string, (varSet,strMap)),
                          bindpair @ [(string,newPlstrexp)]
                          )
                       end
                         )
                   (emptyContext,nil)
                   plstrbinds
       in
         (
          context1,
          [PLSTRUCTBIND(bindpairs,loc)]
          )
       end
     | PLSTRUCTLOCAL(plstrdecs1,plstrdecs2,loc) =>
       let
         val (incContext1, newContext1, newPlstrdecs1) =
             foldl (fn (plstrdec1,(incContext,context,Plstrdecs)) =>
                       let
                         val (context1,plstrdec :plstrdec list) =
                             optimizestrdec globalContext context plstrdec1
                       in
                         (
                          extendContextWithContext(incContext,context1),
                          extendContextWithContext(context,context1),
                          Plstrdecs @ plstrdec
                          )
                       end
                         )
                   (emptyContext, context, nil)
                   plstrdecs1
         val (incContext2, newContext2, newPlstrdecs2) =
             foldl (fn (plstrdec2,(incContext,context,Plstrdecs)) =>
                       let
                         val (context1,plstrdec:plstrdec list) =
                             optimizestrdec globalContext context plstrdec2
                       in
                         (
                          extendContextWithContext(incContext,context1),
                          extendContextWithContext(context,context1),
                          Plstrdecs @ plstrdec
                          )
                       end
                         )
                   (emptyContext, newContext1, nil)
                   plstrdecs2
       in
         (
          extendContextWithContext(incContext1,incContext2),
          [PLSTRUCTLOCAL(newPlstrdecs1, newPlstrdecs2, loc)]
          )
       end
         
 and optimizestrexp globalContext context plstrexp =
     case plstrexp of
         PLSTREXPBASIC(plstrdecs,loc) =>
         let
           val (newIncContext, newContext, newPlstrdecs) =
               foldl (fn (plstrdec,(incContext,context,newPlstrdecs)) =>
                         let
                           val (context1, newPlstrdec:plstrdec list) =
                               optimizestrdec globalContext context plstrdec
                         in
                           (
                            extendContextWithContext(incContext,context1),
                            extendContextWithContext(context,context1),
                            newPlstrdecs @ [newPlstrdec]
                            )
                         end
                           )
                     (emptyContext, context, nil)
                     plstrdecs
         in
           (
            newIncContext,
            PLSTREXPBASIC(List.concat newPlstrdecs,loc)
            )
         end
       (*PLSTREXPBASIC(List.concat(map optimizestrdec plstrdecs),loc)*)
       | PLSTRID(longid,loc) => (emptyContext,plstrexp)
       | PLSTRTRANCONSTRAINT(plstrexp,plsigexp,loc) =>
         let
           val (newContext, newPlstrexp) =
               optimizestrexp globalContext context plstrexp
         in
           (newContext,PLSTRTRANCONSTRAINT(newPlstrexp,plsigexp,loc))
         end
       | PLSTROPAQCONSTRAINT(plstrexp,plsigexp,loc) =>
         let
           val (newContext, newPlstrexp) =
               optimizestrexp globalContext context plstrexp
         in
           (newContext, PLSTROPAQCONSTRAINT(newPlstrexp,plsigexp,loc))
         end
       | PLFUNCTORAPP(string,plstrexp,loc) =>
         let
           val (varSet,strMap) = 
               lookupFunctor (globalContext, context, string)
           val (_,newPlstrexp) = 
               optimizestrexp globalContext context plstrexp
         in
           (
            (varSet,strMap,SEnv.empty),
            PLFUNCTORAPP(string,newPlstrexp,loc)
            )
         end
       | PLSTRUCTLET(plstrdecs,plstrexp,loc) =>
         let
           val (incContext1, newContext, newPlstrdecs) = 
               foldl (
                      fn (plstrdec,(incContext,context,newPlstrdecs)) =>
                         let
                           val (context1, newPlstrdec:plstrdec list) =
                               optimizestrdec globalContext context plstrdec
                         in
                           (
                            extendContextWithContext (incContext,context1),
                            extendContextWithContext (context,context1),
                            newPlstrdecs @ newPlstrdec
                            )
                         end
                     )
                     (emptyContext, context, nil)
                     plstrdecs
           val (incContext2, newPlstrexp) =
               optimizestrexp globalContext newContext plstrexp
         in
           (
            extendContextWithContext (incContext1,incContext2),
            PLSTRUCTLET(newPlstrdecs, newPlstrexp, loc)
            )
         end

 and optimizetopdec globalContext context topdec = 
     case topdec:pltopdec of 
         PLTOPDECSTR(plstrdec,loc) => 
         let
           val (context1, newPlstrdecs:plstrdec list) =
               optimizestrdec globalContext context plstrdec
           val newTopdecs = 
               map (fn plstrdec => PLTOPDECSTR (plstrdec,loc)) newPlstrdecs
         in
           (context1, newTopdecs)
         end
       | PLTOPDECSIG x=> 
         (emptyContext, [PLTOPDECSIG x])
       | PLTOPDECFUN(plfundecs,loc) => 
         let
           val (incContext, context, plfundecs) =  
               foldr (fn ((funid,strid,argSigexp,strexp,loc), (incContext, context, ptfunbinds)) => 
                         let
                           val (context1, newStrexp) = 
                               optimizestrexp globalContext context strexp
                           val map = extractMapFromContext context1
                           val context2 = 
                               bindFunInEmptyContext (funid,map)
                         in
                           (
                            extendContextWithContext(incContext,context2),
                            extendContextWithContext(context,context2),
                            (funid,strid,argSigexp,newStrexp,loc) :: ptfunbinds
                           )
                         end
                           )
                     (emptyContext, context, nil)
                     plfundecs
         in
           (incContext,[PLTOPDECFUN(plfundecs,loc)]) 
         end
             
 and optimizetopdecList globalContext context topdecs = 
     let
       val (newIncContext, newContext, newTopDecs) =
           foldl (fn (topdec,(incContext,context,newTopDecs)) =>
                     let
                       val (context1,newTopDec) = 
                           optimizetopdec globalContext context topdec
                     in
                       (extendContextWithContext(incContext,context1),
                        extendContextWithContext(context,context1),
                        newTopDecs @ [newTopDec]
                        )
                     end
                 )
                 (emptyContext,context,nil)
                 topdecs
     in
       (newIncContext, List.concat newTopDecs)
     end
 (*List.concat(map optimizetopdec topdecs)*)

 fun optimize (globalContext:VALREC_Utils.globalContext) topdecs  = 
     let
       val (newContext, newTopDecs) =
           optimizetopdecList globalContext emptyContext topdecs
     in
       newTopDecs
     end
end
