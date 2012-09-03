(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_Optimizer.sml,v 1.39.6.6 2010/01/29 06:41:35 hiro-en Exp $
 *)
structure VALREC_Optimizer :> VALREC_OPTIMIZER = struct

  open PatternCalcFlattened
  open Graph
  open VALREC_Utils

  type recNodeinfo = {functionId : string,
                      dependentIds : SSet.set,
                      functionDecl : plfpat * plfexp }
  
  type funNodeinfo = {functionId : string,
                      dependentIds : SSet.set,
                      functionDecl : plfpat * (plfpat list * plfexp) list}
  
  fun optimizeExp globalContext context plfexp =
      case plfexp of
        PLFCONSTANT _ => plfexp
      | PLFGLOBALSYMBOL _ => plfexp
      | PLFVAR _ => plfexp
      | PLFTYPED (exp,ty,loc) =>
        PLFTYPED (optimizeExp globalContext context exp, ty, loc)
      | PLFAPPM (funExp, argExpList, loc) =>
        PLFAPPM (optimizeExp globalContext context funExp,
                map (optimizeExp globalContext context) argExpList,
               loc)
      | PLFLET (localDeclList, mainExpList, loc) =>
        let
          val (_,newLocalDeclList) = 
              optimizeDeclList globalContext context localDeclList
        in
          PLFLET (newLocalDeclList,
                 map (optimizeExp globalContext context) mainExpList,
                 loc)
        end
      | PLFRECORD (elementList, loc) =>
        PLFRECORD (map 
                      (fn (label, exp) => (label, optimizeExp globalContext context exp))
                      elementList,
                  loc)
      | PLFRECORD_UPDATE (exp, elementList, loc) =>
        PLFRECORD_UPDATE (optimizeExp globalContext context exp,
                         map (fn (label, exp) => (label, optimizeExp globalContext context exp))
                             elementList,
                         loc)
      | PLFTUPLE (elementList,loc) =>
        PLFTUPLE (map (optimizeExp globalContext context) elementList,loc)
      | PLFLIST (elementList,loc) =>
        PLFLIST (map (optimizeExp globalContext context) elementList,loc)
      | PLFRAISE (exp,loc) => 
        PLFRAISE (optimizeExp globalContext context exp, loc)
      | PLFHANDLE (handler, matchList, loc) =>
        PLFHANDLE (optimizeExp globalContext context handler,
                  map 
                      (fn (pat,exp) => (pat, optimizeExp globalContext context exp))
                      matchList,
                  loc)
      | PLFFNM (matchList, loc) =>
        PLFFNM (map 
                  (fn (patList,exp) => (patList, optimizeExp globalContext context exp))
                  matchList,
              loc)
      | PLFCASEM (selectorList, matchList, kind, loc) =>
        PLFCASEM (map (optimizeExp globalContext context) selectorList,
                map
                    (fn (patList,exp) => (patList, optimizeExp globalContext context exp))
                    matchList,
                kind,
                loc)
      | PLFRECORD_SELECTOR _ => plfexp
      | PLFSELECT (label,exp,loc) =>
        PLFSELECT (label, optimizeExp globalContext context exp, loc)
      | PLFSEQ (expList, loc) =>
        PLFSEQ (map (optimizeExp globalContext context) expList, loc)
      | PLFCAST (exp, loc) =>
        PLFCAST (optimizeExp globalContext context exp, loc)
      | PLFFFIIMPORT (exp,ty,loc) =>
        PLFFFIIMPORT (optimizeExp globalContext context exp, ty, loc)
      | PLFFFIEXPORT (exp,ty,loc) =>
        PLFFFIEXPORT (optimizeExp globalContext context exp, ty, loc)
      | PLFFFIAPPLY (cconv, funExp, args, retTy, loc) =>
        PLFFFIAPPLY (cconv,
                    optimizeExp globalContext context funExp,
                    map (fn PLFFFIARG (exp, ty, loc) =>
                            PLFFFIARG (optimizeExp globalContext context exp, ty, loc)
                          | PLFFFIARGSIZEOF (ty, SOME exp, loc) =>
                            PLFFFIARGSIZEOF (ty, SOME (optimizeExp globalContext context exp), loc)
                          | PLFFFIARGSIZEOF (ty, NONE, loc) =>
                            PLFFFIARGSIZEOF (ty, NONE, loc))
                        args,
                    retTy, loc)
      | PLFSQLSERVER (str, schema, loc) =>
        PLFSQLSERVER
          (map (fn (x,y) => (x, optimizeExp globalContext context y)) str,
           schema, loc)
      | PLFSQLDBI (pat, exp, loc) =>
        PLFSQLDBI (pat, optimizeExp globalContext context exp, loc)

  and optimizeRule globalContext (context:context) patListExpList =
     map (fn (patList,exp) => (patList, optimizeExp globalContext context exp))
     patListExpList
    
  and optimizeDecl globalContext (context:context) pdecl  =
      case pdecl of 
        PDFVAL(tvarList,declList,loc) =>
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [PDFVAL(tvarList,
                (map (fn (pat,exp) => (pat,optimizeExp globalContext context exp))) declList,
                loc)]
         )
      | PDFDECFUN (tvarList, declList, loc) =>
        let
          fun getUniqueID pat =
              case pat of
                PLFPATID (fid,_) => NM.namePathToString(fid)
              | PLFPATTYPED(pat',_,_) => getUniqueID pat'
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
           [PDFVALRECGROUP
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
                         then PDFDECFUN (tvarList, [functionDecl], loc)
                         else PDFNONRECFUN (tvarList, functionDecl, loc)
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
                         PDFDECFUN (tvarList,functionDeclList,loc)
                       end
                         )
                 scc,
                 loc
                 )]
           )
        end
      | PDFVALREC (tvarList,declList,loc) =>
        let
          fun getUniqueID pat =
              case pat of
                PLFPATID (fid,_) => NM.namePathToString(fid)
              | PLFPATTYPED(pat',_,_) => getUniqueID pat'
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
           [PDFVALRECGROUP
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
                         then PDFVALREC (tvarList,[functionDecl],loc)
                         else PDFVAL (tvarList,[functionDecl],loc)
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
                         PDFVALREC (tvarList,functionDeclList,loc)
                       end
                         )
                 scc,
                 loc
                 )]
           )
        end
      | PDFTYPE _ => (emptyContext,[pdecl])
      | PDFDATATYPE _ => 
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDFABSTYPE _ => 
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDFREPLICATEDAT _ => 
        (
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDFEXD _ => 
        (         
         injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [pdecl]
         )
      | PDFLOCALDEC (localDeclList,mainDeclList,loc) =>
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
           [PDFLOCALDEC (newLocalDeclList,
                        newMainDeclList,
                        loc)]
           )
        end
      | PDFINTRO (basicNameNPEnv, strNameList, loc) =>
        (injectVarSetInEmptyContext (getBoundIdsInDecl globalContext context pdecl),
         [PDFINTRO (basicNameNPEnv, strNameList, loc)])
      | PDFINFIXDEC _ => (emptyContext,[pdecl])
      | PDFINFIXRDEC _ => (emptyContext,[pdecl])
      | PDFNONFIXDEC _ => (emptyContext,[pdecl])
      | PDFEMPTY => (emptyContext,[pdecl])
      | _ => raise Control.Bug "invalid declaration"

  and optimizeStrDecl globalContext context strDecl = 
      case strDecl of
          PDFCOREDEC (decs, loc) =>
          let
              val (context, newDecs) =
                  optimizeDeclList globalContext context decs
          in
              (context, [PDFCOREDEC (newDecs, loc)])
          end
        | PDFTRANCONSTRAINT (decs, namemap, spec, specnamemap, loc) =>
          let
              val (context, newDecs) = 
                  optimizeStrDeclList globalContext context decs
          in
              (context, [PDFTRANCONSTRAINT (newDecs, namemap, spec, specnamemap, loc)])
          end
        | PDFOPAQCONSTRAINT (decs, namemap, spec, specnamemap, loc) =>
          let
              val (context, newDecs) = optimizeStrDeclList globalContext context decs
          in 
              (context, [PDFOPAQCONSTRAINT (newDecs, namemap, spec, specnamemap, loc)])
          end
        | PDFFUNCTORAPP (prefix, funName, actualArg, loc) => 
          let
              val varSet = 
                  lookupFunctor (globalContext, context, funName)
              val newVarSet = adjustVarSet (varSet, Path.pathToString(prefix))
          in
              ((newVarSet, SEnv.empty),
               [PDFFUNCTORAPP (prefix, funName, actualArg, loc)])
          end
        | PDFANDFLATTENED (decUnits, loc) =>
          let
              val (context, newDecUnits)  =
                  foldl (fn ((printSigInfo, decUnit), (incContext, newDecUnits)) =>
                            let
                                val (newContext, newDecUnit) =
                                    optimizeStrDeclList globalContext context decUnit
                            in
                                (extendContextWithContext(incContext, newContext),
                                 newDecUnits @ [(printSigInfo, newDecUnit)])
                            end)
                        (emptyContext, nil)
                        decUnits
          in
              (context, [PDFANDFLATTENED(newDecUnits, loc)])
          end
        | PDFSTRLOCAL (localDeclList,mainDeclList, loc) =>
          let
              val (context1,newLocalDeclList) =
                  optimizeStrDeclList globalContext context localDeclList
              val (context2,newMainDeclList) =
                  optimizeStrDeclList globalContext
                                      (extendContextWithContext(context,context1))
                                      mainDeclList
          in
              (
               extendContextWithContext(context1,context2),
               [PDFSTRLOCAL (newLocalDeclList,
                             newMainDeclList,
                             loc)]
               )
          end
          
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

  and optimizeStrDeclList globalContext context pdeclList =
      foldl ( fn (pdecl,(incContext, result)) =>
                 let
                   val (context1, newPdecl) =
                       optimizeStrDecl globalContext context pdecl
                 in
                   (
                    extendContextWithContext(incContext,context1),
                    result @ newPdecl
                    )
                 end
                   )
            (emptyContext, nil)
            pdeclList

 and optimizetopdec globalContext context topdec = 
     case topdec of 
         PLFDECSTR(strDecs, loc) => 
         let
           val (context1, newDecs) =
               optimizeStrDeclList globalContext context strDecs
         in
           (context1, [PLFDECSTR(newDecs, loc)])
         end
       | PLFDECFUN(newFunBinds, loc) => 
         let
           val (incContext, context, plfundecs) =  
               foldr (fn ((funId, argSpec, (bodyDecList, bodyNameMap, bodySigExpOpt), loc), 
                          (incContext, context, ptfunbinds)) => 
                         let
                             val (context1:context, newDecs) = 
                                 optimizeStrDeclList globalContext context bodyDecList
                             val context2 = 
                                 bindFunInEmptyContext (funId, #1 context1)
                         in
                             (
                              extendContextWithContext(incContext,context2),
                              extendContextWithContext(context,context2),
                              (funId, argSpec, (newDecs, bodyNameMap, bodySigExpOpt), loc) :: ptfunbinds
                           )
                         end)
                     (emptyContext, context, nil)
                     newFunBinds
         in
           (incContext,[PLFDECFUN(plfundecs,loc)]) 
         end
       | other => (emptyContext, [other])

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

 fun optimize (globalContext:VALREC_Utils.globalContext) topdecs  = 
     let
       val (newContext, newTopDecs) =
           optimizetopdecList globalContext emptyContext topdecs
     in
       newTopDecs
     end
     handle exn => raise exn
end
