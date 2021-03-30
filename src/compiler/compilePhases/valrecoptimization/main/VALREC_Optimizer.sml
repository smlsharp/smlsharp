(**
 * @copyright (C) 2021 SML# Development Team.
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_Optimizer.sml,v 1.39.6.6 2010/01/29 06:41:35 hiro-en Exp $
 *)
structure VALREC_Optimizer :> VALREC_OPTIMIZER = struct
local
  structure U = VALREC_Utils
in
  
  open IDCalc
  open Graph
(* open  VALREC_Utils *)

  type recNodeinfo = {functionId : VarID.id,
                      dependentIds : VarID.Set.set,
                      functionDecl : {varInfo:varInfo,tyList:ty list,body:icexp}}
		     
  type funNodeinfo = {functionId : VarID.id,
                      dependentIds : VarID.Set.set,
                      functionDecl : {funVarInfo:varInfo,
                                      tyList:ty list,
				      rules:{args:icpat list,body:icexp} list}}
    
  fun optimizeExp icexp =
      case icexp of
	ICERROR => icexp
      | ICCONSTANT _ => icexp
      | ICSIZEOF _ => icexp
      | ICVAR _ => icexp
      | ICEXVAR _ => icexp 
      | ICEXVAR_TOBETYPED _ => icexp 
      | ICBUILTINVAR _ => icexp
      | ICCON _ => icexp
      | ICEXN _ => icexp
      | ICEXEXN _ => icexp
      | ICEXN_CONSTRUCTOR _ => icexp
      | ICEXEXN_CONSTRUCTOR _ => icexp
      | ICOPRIM _ => icexp
      | ICTYPED (icexp,ty,loc) =>
        ICTYPED (optimizeExp icexp, ty, loc)
      | ICINTERFACETYPED {icexp,path,ty,loc} =>
        ICINTERFACETYPED {icexp=optimizeExp icexp,
                          path=path,
                          ty=ty,
                          loc=loc}
      | ICAPPM (funExp, argExpList, loc) => 
	ICAPPM (optimizeExp funExp,
		map optimizeExp argExpList,
		loc)
      | ICAPPM_NOUNIFY (funExp, argExpList, loc) => 
	ICAPPM_NOUNIFY (optimizeExp funExp,
		        map optimizeExp argExpList,
		        loc)
      | ICLET (localDeclList, mainExp, loc) =>
        let
          val newLocalDeclList = 
	      optimizeDeclList localDeclList
        in
          ICLET (newLocalDeclList,
                 optimizeExp mainExp,
                 loc)
        end
      | ICTYCAST (tycastList, icexp, loc) =>
	  ICTYCAST (tycastList, optimizeExp icexp, loc)
      | ICRECORD (elementList, loc) =>
        ICRECORD
            (map 
		 (fn (label, icexp) => (label, optimizeExp icexp))
		 elementList,
             loc)
      | ICRAISE (icexp,loc) => 
        ICRAISE (optimizeExp icexp, loc) 
      | ICHANDLE  (handler, matchList, loc) =>
        ICHANDLE
            (optimizeExp handler,
             map 
		 (fn (icpat,icexp) => (icpat, optimizeExp icexp))
		 matchList,
             loc)
      | ICFNM (matchList, loc) =>
        ICFNM
            (map 
		 (fn ({args:icpat list, body:icexp})
                     => {args=args, body=optimizeExp body})
		 matchList,
             loc)
      | ICFNM1 (varInfoTyListList,icexp,loc)=>
	ICFNM1 (varInfoTyListList,optimizeExp icexp,loc)
      | ICFNM1_POLY (varInfoTyList,icexp,loc)=>
	ICFNM1_POLY (varInfoTyList,optimizeExp icexp,loc)
      | ICCASEM (selectorList, matchList, kind, loc) =>
        ICCASEM
            (map optimizeExp selectorList,
             map
		 (fn ({args:icpat list, body:icexp}) =>
                     {args=args, body=optimizeExp body})
		 matchList,
             kind,
             loc)
      | ICDYNAMICCASE (selector, matchList, loc) =>
        ICDYNAMICCASE
            (optimizeExp selector,
             map
		 (fn ({tyvars, arg:icpat, body:icexp}) =>
                     {tyvars=tyvars, arg=arg, body=optimizeExp body})
		 matchList,
             loc)
      | ICRECORD_UPDATE (icexp, elementList, loc) =>
        ICRECORD_UPDATE
            (optimizeExp icexp,
             map (fn (label, icexp) => (label, optimizeExp icexp))
		 elementList,
             loc)
      | ICRECORD_UPDATE2 (icexp, icexp2, loc) =>
        ICRECORD_UPDATE2
          (optimizeExp icexp,
           optimizeExp icexp2,
           loc)
      | ICRECORD_SELECTOR (str, loc) => icexp
      | ICSELECT (label,icexp,loc) =>
        ICSELECT (label, optimizeExp icexp, loc)
      | ICSEQ (icexpList, loc) =>
        ICSEQ (map optimizeExp icexpList, loc)
      | ICFFIIMPORT (icexp,ty,loc) =>
        ICFFIIMPORT (optimizeFFIFun icexp, ty, loc)
      | ICSQLSCHEMA {tyFnExp, ty, loc} =>
        ICSQLSCHEMA {tyFnExp = optimizeExp tyFnExp,
                     ty = ty,
                     loc = loc}
      | ICJOIN (bool, icexp1, icexp2, loc) =>
        ICJOIN (bool, optimizeExp icexp1, optimizeExp icexp2, loc)
      | ICDYNAMIC (icexp, ty, loc) => 
        ICDYNAMIC (optimizeExp icexp, ty, loc)
      | ICDYNAMICIS (icexp, ty, loc) => 
        ICDYNAMICIS (optimizeExp icexp, ty, loc)
      | ICDYNAMICNULL (ty, loc) => icexp
      | ICDYNAMICTOP (ty, loc) => icexp
      | ICDYNAMICVIEW (icexp, ty, loc) => 
        ICDYNAMICVIEW (optimizeExp icexp, ty, loc)
      | ICREIFYTY (ty, loc) => icexp

  and optimizeFFIFun ffiFun =
      case ffiFun of
        ICFFIFUN exp => ICFFIFUN (optimizeExp exp)
      | ICFFIEXTERN _ => ffiFun
  
  and optimizeRule patListExpList =
      map (fn {args,body} => {args=args, body=optimizeExp body})
	  patListExpList

  and optimizeDecl icdecl  =
      case icdecl of 
        ICVAL (tvarList, declList, loc) =>  
	[ICVAL (tvarList, (map (fn (icpat,icexp) => 
				   (icpat, optimizeExp icexp))) declList,
		loc)]
      | ICVAL_OPAQUE_SIG {var, exp, ty, revealKey, loc} =>  
        [ICVAL_OPAQUE_SIG {var = var, 
                           exp = optimizeExp exp, 
                           ty = ty, 
                           revealKey = revealKey, 
                           loc = loc}]
      | ICVAL_TRANS_SIG {var, exp, ty, loc} => 
        [ICVAL_TRANS_SIG {var = var, 
                           exp = optimizeExp exp, 
                           ty = ty, 
                           loc = loc}]
      | ICDECFUN {guard, funbinds, loc} =>
        let
          val boundIDList = 
              map (fn ({funVarInfo, tyList, rules})=> (#id funVarInfo)) 
                  funbinds
          val g = Graph.empty :  funNodeinfo Graph.graph
          val g =
              foldl 
                  (fn ({funVarInfo, tyList, rules},g) =>
                      let 
			val fid = (#id funVarInfo)
			val dependentIds =
                            U.getFreeIdsInRule rules
                      in
			#1
			    (Graph.addNode
				 g
				 {functionId=fid,
				  dependentIds=dependentIds,
				  functionDecl=
				  {funVarInfo=funVarInfo,
                                   tyList=tyList,
				   rules=optimizeRule rules}})
                      end)
                  (Graph.empty : funNodeinfo Graph.graph)
                  funbinds
          val nodeList = Graph.listNodes g
          val g = 
              foldl
                  (fn ((nid1,{dependentIds as dids1 , ... }), g) =>
                      foldl 
                          (fn ((nid2,{functionId as fid2,... }),g) =>
                              if VarID.Set.member(dids1, fid2)
                              then Graph.addEdge g (nid1, nid2)
                           (* 2012-8-4 bug 231_refFunOrder.sml
                              In order to preserve the non-connected component.
                              then Graph.addEdge g (nid2,nid1)
                            *)
                              else g)
                          g
                          nodeList)
                  g
                  nodeList
          val scc = Graph.scc g          
          (* 2012-8-4 bug 231_refFunOrder.sml
             In order to preserve the non-connected component. *)
          val sccRevRev = map List.rev (List.rev scc)
        in
          map 
              (fn nidList =>
                  case nidList of 
                    [] => raise Bug.Bug "recval"
                  | [nid] =>
                    let
                      val {functionId,dependentIds,functionDecl} =
                          case Graph.getNodeInfo g nid of
                            NONE => raise Bug.Bug "val rec"
                          | SOME info => info
                    in
                      if VarID.Set.member(dependentIds,functionId)
                      then ICDECFUN {guard=guard,
				     funbinds=[functionDecl],
				     loc=loc}
                      else ICNONRECFUN 
			       {
				guard=guard,
				funVarInfo=(#funVarInfo functionDecl),
                                tyList= #tyList functionDecl,
				rules=(#rules functionDecl),
				loc=loc
			       }
                    end
                  | _ => 
                    let
                      val functionDeclList =
                          foldr 
                              (fn (nid,S) =>
                                  case Graph.getNodeInfo g nid of
                                    NONE => raise Bug.Bug "val rec"
                                  | SOME info => (#functionDecl info)::S)
                              []
                              nidList
                    in
                      ICDECFUN {guard=guard,funbinds=functionDeclList,loc=loc}
                    end
              )
              sccRevRev
        end 
      | ICNONRECFUN {guard, funVarInfo, tyList, rules, loc} =>
	raise Bug.Bug "invalid declaration"
      | ICVALREC {guard, recbinds, loc} =>
        let
          val boundIDList = 
              map (fn ({varInfo,tyList,body})=>(#id varInfo)) recbinds
          val g = Graph.empty :  recNodeinfo Graph.graph
          val g =
	      foldl 
                  (fn ({varInfo,tyList,body},g) =>
		      let 
			val fid = (#id varInfo) 
			val dependentIds = U.getFreeIdsInExp body
		      in
			#1
			    (Graph.addNode
				 g
				 {functionId=fid,
				  dependentIds=dependentIds,
				  functionDecl=
				  {varInfo=varInfo,
                                   tyList=tyList,
                                   body=optimizeExp body}})
		      end)
                  (Graph.empty : recNodeinfo Graph.graph)
                  recbinds
	  val nodeList = Graph.listNodes g
          val g = 
	      foldl
                  (fn ((nid1,{dependentIds as dids1 , ... }), g) =>
		      foldl 
			  (fn ((nid2,{functionId as fid2,... }),g) =>
			      if VarID.Set.member(dids1, fid2)
			      then Graph.addEdge g (nid1, nid2)
                             (* 2012-8-4 bug 231_refFunOrder.sml
                                In order to preserve the non-connected component.
			      then Graph.addEdge g (nid2, nid1)
                              *)
			      else g)
			  g
			  nodeList)
                  g
                  nodeList
          val scc = Graph.scc g 
          (* 2012-8-4 bug 231_refFunOrder.sml
             In order to preserve the non-connected component. *)
          val sccRevRev = map List.rev (List.rev scc)
        in
	  map 
	      (fn nidList =>
		  case nidList of 
		    [] => raise Bug.Bug "recval"
		  | [nid] =>
		    let
		      val {functionId,dependentIds,functionDecl} =
			  case Graph.getNodeInfo g nid of
			    NONE => raise Bug.Bug "val rec"
			  | SOME info => info
		    in
		      if VarID.Set.member(dependentIds,functionId)
		      then ICVALREC {guard=guard,
				     recbinds=[functionDecl],
				     loc=loc}
		      else 
                        let
                          val pat = 
                              foldr
                                (fn (ty, pat) => ICPATTYPED(pat, ty, loc))
                                (ICPATVAR_TRANS (#varInfo functionDecl))
                                (#tyList functionDecl)
                        in
                          ICVAL (guard,
				 [(pat, #body functionDecl)],
				 loc)
                        end
		    end
		  | _ => 
		    let
		      val functionDeclList =
			  foldr 
			      (fn (nid,S) =>
				  case Graph.getNodeInfo g nid of
				    NONE => raise Bug.Bug "val rec"
				  | SOME info => (#functionDecl info)::S)
			      []
			      nidList
		    in
		      ICVALREC {guard=guard,recbinds=functionDeclList,loc=loc}
		    end
	      )
	      sccRevRev
	end
      | ICVALPOLYREC (polyrecbinds, loc) =>
        [ICVALPOLYREC 
           (map (fn {varInfo, ty, body} => {varInfo=varInfo, ty=ty, body=optimizeExp body}) polyrecbinds, 
            loc)
        ]
      | ICEXND (_, loc) => [icdecl]
      | ICEXNTAGD (_, loc) => [icdecl]
      | ICEXPORTVAR _ => [icdecl]
      | ICEXPORTTYPECHECKEDVAR _ => [icdecl]
      | ICEXPORTFUNCTOR _ => [icdecl]
      | ICEXPORTEXN _ => [icdecl]
      | ICEXTERNVAR _ => [icdecl]
      | ICEXTERNEXN _ => [icdecl]
      | ICBUILTINEXN _ => [icdecl]
      | ICTYCASTDECL (tycastList, icdeclList, loc) => [icdecl]
      | ICOVERLOADDEF _ => [icdecl]

  and optimizeDeclList icdeclList = List.concat (map optimizeDecl icdeclList)

  fun optimize decls =
      let 
	val newTopdecs = optimizeDeclList decls
      in
	newTopdecs
      end
end
end
