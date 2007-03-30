(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Summarizer.sml,v 1.3 2004/11/06 16:15:03 kiyoshiy Exp $
 *)
structure Summarizer : SUMMARIZER =
struct

  (***************************************************************************)

  structure EA = ElaboratedAst
  structure DG = DependencyGraph
  structure L = Linkage
  structure B = Binds
  structure U = Utility

  (***************************************************************************)

  type linkage = (B.bind list * L.moduleLinkType list DG.graph)

  datatype traceDirection = SRCTODEST | DESTTOSRC

  (***************************************************************************)

  fun mapVisit visit list =
      let
        val pairList = map visit list
        val (bindsList, linksList) = ListPair.unzip pairList
      in (List.concat bindsList, List.concat linksList) end

  fun visitSigConst visit currentFQN sigConst =
      case sigConst of
        EA.NoSig => ([], [])
      | EA.Transparent element => visit currentFQN element
      | EA.Opaque element => visit currentFQN element

  fun visitStrExp linkType currentFQN strExp =
      case strExp of
        EA.VarStr strRef =>
        (case strRef of
           EA.ModuleRef(ABSFQN, _) => ([], [(linkType, currentFQN, ABSFQN)])
         | _ => ([], []))
      | EA.BaseStr decSet =>
        (* ToDo : deal with anonymous structure parameter *)
        visitDecSet currentFQN decSet
      | EA.ConstrainedStr (strExp, sigConst) =>
        let
          val (binds1, links1) = visitStrExp linkType currentFQN strExp
          val (binds2, links2) =
              visitSigConst (visitSigExp L.ConstraintLink) currentFQN sigConst
        in (binds1 @ binds2, links1 @ links2) end
      | EA.AppStr (fctRef, params) =>
        let
          val links1 =
              case fctRef of
                EA.ModuleRef(ABSFQN, _) => [(L.AppLink, currentFQN, ABSFQN)]
              | _ => []
          val (binds2list, links2list) = ([], [])
(* ToDo : arguments to functor application should be treated carefully. *)
(*
              (mapVisit
               (fn (strExp, _) => visitStrExp L.ArgLink currentFQN strExp)
               params)
*)
        in
          (binds2list, links1 @ links2list)
        end

  and visitFctExp linkType currentFQN fctExp =
      case fctExp of
        EA.VarFct(fctRef, sigConst) =>
        let
          val (binds1, links1) =
              case fctRef of
                EA.ModuleRef(ABSFQN, _) =>
                ([], [(linkType, currentFQN, ABSFQN)])
              | _ => ([], [])
          (* NOTE : ignore bindings in constraint *)
          val (_, links2) =
              visitSigConst (visitFsigExp L.ConstraintLink) currentFQN sigConst
        in (binds1, links1 @ links2) end
      | EA.BaseFct{params, body, constraint} =>
        let
          val (binds1list, links1list) =
              (mapVisit
               (fn (nameOpt, sigExp) => ([], []))
                   (* ToDo : treat with functor argument *)
(*
                   visitSigExp L.FormalArgLink currentFQN sigExp)
*)
               params)
          val (binds2, links2) = visitStrExp L.ModuleDefLink currentFQN body
          (* NOTE : ignore bindings in constraint *)
          val (_, links3) =
              visitSigConst
                  (visitSigExp L.ConstraintLink) currentFQN constraint
        in (binds1list @ binds2, links1list @ links2 @ links3) end
      | EA.AppFct(fctRef, params, sigConst) =>
        let
          val (binds1, links1) =
              case fctRef of
                EA.ModuleRef(ABSFQN, _) =>
                ([], [(L.AppLink, currentFQN, ABSFQN)])
              | _ => ([], [])
          val (binds2, links2) = ([], [])
(* ToDo : arguments to functor application should be treated carefully. *)
(*
              (mapVisit
               (fn (strExp, _) => visitStrExp L.ArgLink currentFQN strExp)
               params)
*)
          (* NOTE : ignore bindings in constraint *)
          val (_, links3) =
              visitSigConst (visitFsigExp L.ConstraintLink) currentFQN sigConst
        in (binds1 @ binds2, links1 @ links2 @ links3) end

  and visitWhereSpec currentFQN whereSpec =
      case whereSpec of
        EA.WhType _ => (* ToDo : current version ignore element level linkage*)
        ([], [])
      | EA.WhStruct(_, moduleRef) =>
        (case moduleRef of
           EA.ModuleRef(ABSFQN, _) => ([], [(L.WhereLink, currentFQN, ABSFQN)])
         | _ => ([], []))

  and visitSigExp linkType currentFQN sigExp =
      case sigExp of
        EA.VarSig sigRef =>
        (case sigRef of
           EA.ModuleRef(ABSFQN, _) => ([], [(linkType, currentFQN, ABSFQN)])
         | _ => ([], []))
      | EA.AugSig (sigExp, whereSpecListList) =>
        let
          val (binds1, links1) = visitSigExp linkType currentFQN sigExp
          val (binds2list, links2list) =
              mapVisit (mapVisit (visitWhereSpec currentFQN)) whereSpecListList
        in (binds1 @ binds2list, links1 @ links2list) end
      | EA.BaseSig specSet => visitSpecSet currentFQN specSet

  and visitFsigExp linkType currentFQN fsigExp =
      case fsigExp of
        EA.VarFsig fsigRef =>
        (case fsigRef of
           EA.ModuleRef(ABSFQN, _) => ([], [(linkType, currentFQN, ABSFQN)])
         | _ => ([], []))
      | EA.BaseFsig{params, result} =>
        let
          val (binds1, links1) =
              (mapVisit
               (fn (nameOpt, sigExp) => ([], []))
               (* ToDo : treat with functor parameter. *)
(*
                   visitSigExp L.FormalArgLink currentFQN sigExp)
*)
               params)
          val (binds2, links2) = visitSigExp linkType currentFQN result
        in
          (binds1 @ binds2, links1 @ links2)
        end

  and visitSpecSet currentFQN (EA.SpecSet specSet) =
      let
        val (strBinds, strLinks) = mapVisit visitSigBind (#strs specSet)
        val (fctBinds, fctLinks) = mapVisit visitFsigBind (#fcts specSet)
        val (includeBinds, includeLinks) =
            mapVisit (visitInclude currentFQN) (#includes specSet)
        val (typeBinds, typeLinks) = mapVisit visitTypeBind (#types specSet)
        val (datatypeBinds, datatypeLinks) =
            mapVisit visitDataTypeBind (#datatypes specSet)
        val (exceptionBinds, exceptionLinks) =
            mapVisit visitExceptionBind (#exceptions specSet)
        val (valBinds, valLinks) = mapVisit visitValBind (#vals specSet)
      in
        (
          strBinds @ fctBinds @ includeBinds @
          typeBinds @ datatypeBinds @ exceptionBinds @ valBinds,
          strLinks @ fctLinks @ includeLinks @
          typeLinks @ datatypeLinks @ exceptionLinks @ valLinks
        )
      end

  and visitDecSet currentFQN (EA.DecSet decSet) =
      let
        val (strBinds, strLinks) = mapVisit visitStrBind (#strs decSet)
        val (fctBinds, fctLinks) = mapVisit visitFctBind (#fcts decSet)
        val (sigBinds, sigLinks) = mapVisit visitSigBind (#sigs decSet)
        val (fsigBinds, fsigLinks) = mapVisit visitFsigBind (#fsigs decSet)
        val openLinks =
            List.concat
            (map
             (fn EA.ModuleRef(ABSFQN, _) => [(L.OpenLink, currentFQN, ABSFQN)]
               | _ => [])
             (#opens decSet))
        val (typeBinds, typeLinks) = mapVisit visitTypeBind (#types decSet)
        val (datatypeBinds, datatypeLinks) =
            mapVisit visitDataTypeBind (#datatypes decSet)
        val (exceptionBinds, exceptionLinks) =
            mapVisit visitExceptionBind (#exceptions decSet)
        val (valBinds, valLinks) = mapVisit visitValBind (#vals decSet)
      in
        (
          strBinds @ fctBinds @ sigBinds @ fsigBinds @ 
          typeBinds @ datatypeBinds @ exceptionBinds @ valBinds,
          strLinks @ fctLinks @ sigLinks @ fsigLinks @ openLinks @
          typeLinks @ datatypeLinks @ exceptionLinks @ valLinks
        )
      end

  and visitInclude currentFQN sigExp =
      case sigExp of
        EA.VarSig sigRef =>
        (case sigRef of
           EA.ModuleRef(ABSFQN, _) =>
           ([], [(L.IncludeLink, currentFQN, ABSFQN)])
         | _ => ([], []))
      | EA.AugSig(sigExp, whereSpecs) => (* we ignore whereSpecs *)
        visitInclude currentFQN sigExp
      | EA.BaseSig _ => ([], [])

  and visitSigBind (bind as EA.SIGB(FQN, _, _, sigExp, _, _)) =
      let val (binds1, links1) = visitSigExp L.ModuleDefLink FQN sigExp
      in (B.SigBind(bind) :: binds1, links1) end

  and visitFsigBind (bind as EA.FSIGB(FQN, _, _, fsigExp, _)) =
      let val (binds1, links1) = visitFsigExp L.ModuleDefLink FQN fsigExp
      in (B.FsigBind bind :: binds1, links1) end

  and visitStrBind (bind as EA.STRB(FQN, _, _, strExp, sigConst, _)) =
      let
        val (binds1, links1) = visitStrExp L.ModuleDefLink FQN strExp

        (* NOTE : ignore bindings in constraint. *)
        val (_, links2) =
            visitSigConst (visitSigExp L.ConstraintLink) FQN sigConst
      in
        (B.StrBind bind :: binds1, links1 @ links2)
      end

  and visitFctBind (bind as EA.FCTB(FQN, _, _, fctExp, _)) =
      let val (binds1, links1) = visitFctExp L.ModuleDefLink FQN fctExp
      in (B.FctBind bind :: binds1, links1) end

  and visitTypeBind (bind as EA.TB(FQN, _, _, _, tyOpt, _, _)) =
      let val (binds1, links1) = visitTyOpt FQN tyOpt
      in (B.TypeBind bind :: binds1, links1) end

  and visitDataTypeBind (bind as EA.DB(_, _, _, _, dbrhs, _)) =
      let val (binds1list, links1list) = visitDBRHS dbrhs
      in
        (B.DataTypeBind bind :: binds1list, links1list)
      end

  and visitDBRHS (EA.Constrs constrs) =
      (map B.ConstructorBind constrs, []) 
    | visitDBRHS (EA.Repl typeRef) = ([], [])

  and visitExceptionBind eb = ([B.ExceptionBind eb], [])

  and visitValBind bind = ([B.ValBind bind], [])

  and visitTyOpt currentFQN tyOpt =
      (* ToDo : we should implement element level summarize. *)
      ([], [])

  (****************************************)

  fun findIndex condition list =
      let
        fun find _ [] = NONE
          | find index (hd::tl) =
            if condition hd then SOME(index) else find (index + 1) tl
      in find 0 list end

  (****************************************)

  fun summarize units =
      let
        val bindAndLinks =
            map (fn EA.CompileUnit(_, decSet) => visitDecSet [] decSet) units
        val (bindsList, linksList) = ListPair.unzip bindAndLinks
        val binds = List.concat bindsList
        val links = List.concat linksList

        val moduleBindList =
            List.filter
             (fn (B.SigBind _) => true
               | (B.FsigBind _) => true
               | (B.StrBind _) => true
               | (B.FctBind _) => true
               | _ => false)
             binds
        fun findModuleIndex FQN =
              findIndex (fn bind => B.getModuleFQN bind = FQN) moduleBindList

        val graph : (L.moduleLinkType list) DG.graph =
            DG.create (List.length moduleBindList)
        val _ =
            foldl
            (fn ((linkType, srcFQN, destFQN), graph) =>
                let
                  val srcIndex = findModuleIndex srcFQN
                  val destIndex = findModuleIndex destFQN
                in
                  case (srcIndex, destIndex) of
                    (SOME srcIndex, SOME destIndex) =>
                    let
                      val linkTypes = 
                          case
                            DG.isDependsOn
                                graph {src = srcIndex, dest = destIndex}
                           of
                            (SOME linkTypes, true) => linkTypes | _ => []
                    in
                      DG.dependsOn
                      graph
                      {
                        src = srcIndex,
                        dest = destIndex,
                        attr = linkType :: linkTypes
                      };
                      graph
                    end
                  (* srcIndex or destIndex maybe not included in binding.
                   * because bindings in signature constraint are ignored.*)
                  | _ => graph
                end)
            graph
            links
      in
        (binds, (moduleBindList, graph))
      end

  fun getClosureOfLink
          traceDirection linkTypes (moduleBindList, graph) startFQN =
      case 
        findIndex (fn bind => B.getModuleFQN bind = startFQN) moduleBindList
       of
        NONE =>
        (print ("Not found: " ^ EA.moduleFQNToString startFQN ^ "\n");
         [])
      | SOME moduleIndex =>
        let
          val getClosure =
              case traceDirection of
                SRCTODEST => DG.getClosure
              | DESTTOSRC => DG.getClosureRev
          fun containTargetLinkType attrLinkTypes = 
              List.exists
              (fn linkType => List.exists (fn lt => lt = linkType) linkTypes)
              attrLinkTypes

          val closureIndexes =
              getClosure graph (containTargetLinkType, moduleIndex)
          val closureBinds =
              map (fn index => List.nth (moduleBindList, index)) closureIndexes
        in
          closureBinds
        end

  (***************************************************************************)

end
