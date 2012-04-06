(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_Optimizer.sml,v 1.39.6.6 2010/01/29 06:41:35 hiro-en Exp $
 *)
structure VALREC_Optimizer :> VALREC_OPTIMIZER = struct
  open IDCalc
  open Graph
  open VALREC_Utils

  type recNodeinfo = {functionId : VarID.id,
                      dependentIds : VarID.Set.set,
                      functionDecl : {varInfo:varInfo,body:icexp}}
		     
  type funNodeinfo = {functionId : VarID.id,
                      dependentIds : VarID.Set.set,
                      functionDecl : {funVarInfo:varInfo,
				      rules:{args:icpat list,body:icexp} list}}
    
  fun optimizeExp icexp =
      case icexp of
	ICERROR loc => icexp
      | ICCONSTANT (const, loc) => icexp
      | ICGLOBALSYMBOL (str, symbol, loc) => icexp
      | ICVAR (varInfo, loc) => icexp
      | ICEXVAR ({path, ty}, loc) => icexp 
      | ICEXVAR_TOBETYPED ({path, id}, loc) => icexp 
      | ICBUILTINVAR {primitive, ty, loc} => icexp
      | ICCON (conInfo, loc) => icexp
      | ICEXN (exnInfo, loc) => icexp
      | ICEXEXN ({path, ty}, loc) => icexp
      | ICEXN_CONSTRUCTOR (exnInfo, loc) => icexp
      | ICEXEXN_CONSTRUCTOR (_, loc) => icexp
      | ICOPRIM (oprimInfo, loc) => icexp
      | ICTYPED (icexp,ty,loc) =>
        ICTYPED (optimizeExp icexp, ty, loc)
      | ICSIGTYPED {path,icexp,ty,loc,revealKey} =>
        ICSIGTYPED {path=path,
                    icexp=optimizeExp icexp,
                    ty=ty,
                    revealKey=revealKey,
                    loc=loc}
      | ICAPPM (funExp, argExpList, loc) => 
	ICAPPM (optimizeExp funExp,
		map optimizeExp argExpList,
		loc)
      | ICAPPM_NOUNIFY (funExp, argExpList, loc) => 
	ICAPPM_NOUNIFY (optimizeExp funExp,
		        map optimizeExp argExpList,
		        loc)
      | ICLET (localDeclList, mainExpList, loc) =>
        let
          val newLocalDeclList = 
	      optimizeDeclList localDeclList
        in
          ICLET (newLocalDeclList,
                 map optimizeExp mainExpList,
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
      | ICRECORD_UPDATE (icexp, elementList, loc) =>
        ICRECORD_UPDATE
            (optimizeExp icexp,
             map (fn (label, icexp) => (label, optimizeExp icexp))
		 elementList,
             loc)
      | ICRECORD_SELECTOR (str, loc) => icexp
      | ICSELECT (label,icexp,loc) =>
        ICSELECT (label, optimizeExp icexp, loc)
      | ICSEQ (icexpList, loc) =>
        ICSEQ (map optimizeExp icexpList, loc)
      | ICCAST (icexp, loc) =>
        ICCAST (optimizeExp icexp, loc)
      | ICFFIIMPORT (icexp,ty,loc) =>
        ICFFIIMPORT (optimizeExp icexp, ty, loc)
      | ICFFIEXPORT (icexp,ty,loc) =>
        ICFFIEXPORT (optimizeExp icexp, ty, loc)
      | ICFFIAPPLY (cconv, funExp, args, retTy, loc) =>
        ICFFIAPPLY
            (cconv,
             optimizeExp funExp,
             map (fn ICFFIARG (icexp, ty, loc) =>
                     ICFFIARG (optimizeExp icexp, ty, loc)
                   | ICFFIARGSIZEOF (ty, SOME icexp, loc) =>
                     ICFFIARGSIZEOF
			 (ty, SOME (optimizeExp icexp), loc)
                   | ICFFIARGSIZEOF (ty, NONE, loc) =>
                     ICFFIARGSIZEOF (ty, NONE, loc))
		 args,
             retTy, loc)
      | ICSQLSERVER (str, schema, loc) =>
          ICSQLSERVER
              (map (fn (x,y) => (x, optimizeExp y)) str,
               schema, loc)
      | ICSQLDBI (icpat, icexp, loc) =>
        ICSQLDBI (icpat, optimizeExp icexp, loc)
  
  and optimizeRule patListExpList =
      map (fn {args,body} => {args=args, body=optimizeExp body})
	  patListExpList

  and optimizeDecl icdecl  =
      case icdecl of 
        ICVAL (tvarList, declList, loc) =>  
	[ICVAL (tvarList, (map (fn (icpat,icexp) => 
				   (icpat, optimizeExp icexp))) declList,
		loc)]
      | ICDECFUN {guard, funbinds, loc} =>
        let
          val boundIDList = map (fn ({funVarInfo,rules})=>
				    (#id funVarInfo)) funbinds
          val g = Graph.empty :  funNodeinfo Graph.graph
          val g =
              foldl 
                  (fn ({funVarInfo,rules},g) =>
                      let 
			val fid = (#id funVarInfo)
			val dependentIds =
                            getFreeIdsInRule rules
                      in
			#1
			    (Graph.addNode
				 g
				 {functionId=fid,
				  dependentIds=dependentIds,
				  functionDecl=
				  {funVarInfo=funVarInfo,
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
                              then Graph.addEdge g (nid2,nid1)
                              else g)
                          g
                          nodeList)
                  g
                  nodeList
          val scc = Graph.scc g          
        in
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
                      if VarID.Set.member(dependentIds,functionId)
                      then ICDECFUN {guard=guard,
				     funbinds=[functionDecl],
				     loc=loc}
                      else ICNONRECFUN 
			       {
				guard=guard,
				funVarInfo=(#funVarInfo functionDecl),
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
                                    NONE => raise Control.Bug "val rec"
                                  | SOME info => (#functionDecl info)::S)
                              []
                              nidList
                    in
                      ICDECFUN {guard=guard,funbinds=functionDeclList,loc=loc}
                    end
              )
              scc
        end 
      | ICNONRECFUN {guard, funVarInfo, rules, loc} =>
	raise Control.Bug "invalid declaration"
      | ICVALREC {guard, recbinds, loc} =>
        let
          val boundIDList = map (fn ({varInfo,body})=>(#id varInfo)) recbinds
          val g = Graph.empty :  recNodeinfo Graph.graph
          val g =
	      foldl 
                  (fn ({varInfo,body},g) =>
		      let 
			val fid = (#id varInfo) 
			val dependentIds = getFreeIdsInExp body
		      in
			#1
			    (Graph.addNode
				 g
				 {functionId=fid,
				  dependentIds=dependentIds,
				  functionDecl=
				  {varInfo=varInfo,body=optimizeExp body}})
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
			      then Graph.addEdge g (nid2,nid1)
			      else g)
			  g
			  nodeList)
                  g
                  nodeList
          val scc = Graph.scc g 
        in
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
		      if VarID.Set.member(dependentIds,functionId)
		      then ICVALREC {guard=guard,
				     recbinds=[functionDecl],
				     loc=loc}
		      else ICVAL (guard,
				  [(ICPATVAR (#varInfo functionDecl,loc),
				    #body functionDecl)],
				  loc)
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
		      ICVALREC {guard=guard,recbinds=functionDeclList,loc=loc}
		    end
	      )
	      scc
	end
      | ICABSTYPE {tybinds, body, loc} =>
	raise Control.Bug "abstype"
      | ICEXND (_, loc) => [icdecl]
      | ICEXNTAGD (_, loc) => [icdecl]
      | ICEXPORTVAR (varInfo, ty, loc) => [icdecl]
      | ICEXPORTTYPECHECKEDVAR (varInfo, loc) => [icdecl]
      | ICEXPORTFUNCTOR _ => [icdecl]
      | ICEXPORTEXN (exnInfo, loc) => [icdecl]
      | ICEXTERNVAR ({path, ty}, loc) => [icdecl]
      | ICEXTERNEXN ({path, ty}, loc) => [icdecl]
      | ICOVERLOADDEF {boundtvars, id, path, overloadCase, loc} => [icdecl]

  and optimizeDeclList icdeclList = List.concat (map optimizeDecl icdeclList)

  fun optimize topdecs =
      let 
	val newTopdecs = optimizeDeclList topdecs
      in
	newTopdecs
      end
end
