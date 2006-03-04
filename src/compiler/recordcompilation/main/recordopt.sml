(**
 * This is obsolue, and is  not used.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: recordopt.sml,v 1.4 2006/02/28 16:11:04 kiyoshiy Exp $
 *)
structure RecordCalcOpt = struct
local 
    open RecordCalc
    open Types
in
    fun freeVars exp =
	case exp of
             TLCONSTANT _ => SSet.empty
	   | TLVAR {name, ty} => SSet.singleton name
	   | TLPRIMAPPLY (_, _, SOME exp) => freeVars exp
	   | TLPRIMAPPLY (_,_, NONE) => SSet.empty 
	   | TLCONSTRUCT (_,_,SOME exp) => freeVars exp
	   | TLCONSTRUCT (_,_,NONE) =>  SSet.empty 
	   | TLAPP (exp1,exp2) => SSet.union(freeVars exp1,freeVars exp2)
	   | TLLET (decls,exps) => SSet.difference(foldr (fn (e,S) => SSet.union(S,freeVars e)) SSet.empty exps,boundVarsInDecs decls)
	   | TLRECORD fields => SEnv.foldr (fn (e,S) => SSet.union(S,freeVars e)) SSet.empty fields
	   | TLSELECT (e,_,_) => freeVars e
	   | TLRAISE e  => freeVars e
	   | TLHANDLE (e1,handlers,e2) =>
		 foldr (fn ((_,_,e),S) => SSet.union(S,freeVars e)) (SSet.union(freeVars e1,freeVars e2)) handlers
           | TLFN ({name,ty},e) => SSet.delete(freeVars e,name)
	   | TLPOLY (tenv,exp) => freeVars exp
	   | TLTAPP (e,_) => freeVars e
	   | TLCASE (e1,rules,e2) =>
		 foldr (fn ((_,_,e),S) => SSet.union(S,freeVars e)) (SSet.union(freeVars e1,freeVars e2)) rules
           | TLSWITCH (e1,rules,e2) =>
		 foldr (fn ((_,e),S) => SSet.union(S,freeVars e)) (SSet.union(freeVars e1,freeVars e2)) rules
           | TLLETTERM (termdecl,e) => freeVars e
	   | TLTERMVAL (_,vars) =>  foldr (fn ({name,ty},S) => SSet.add(S,name)) SSet.empty vars
   and boundVarsInDec decl = 
       case decl of
          TLVAL vallist => foldr (fn (({name,ty},_),S) => SSet.add(S,name))  SSet.empty vallist
	| TLVALREC reclist => foldr (fn (({name,ty},_),S) => SSet.add(S,name))  SSet.empty reclist
	| TLLOCALDEC (decls1,decls2) => boundVarsInDecs decls2
	| TLDATADEC _ => SSet.empty
   and boundVarsInDecs declList = 
       foldr (fn (d,S) => SSet.union(S,boundVarsInDec d))  SSet.empty declList
   and freeVarsInDec decl = 
       case decl of
          TLVAL vallist => foldr (fn ((_,exp),S) => SSet.union(S,freeVars exp))  SSet.empty vallist
	| dec as TLVALREC reclist => 
	  let val bvars = boundVarsInDec dec
	  in foldr (fn ((_,exp),S) => SSet.union(S,SSet.difference(freeVars exp,bvars))) SSet.empty reclist
	  end
	| TLLOCALDEC (decls1,decls2) => SSet.union(freeVarsInDecs decls1,freeVarsInDecs decls2)
	| TLDATADEC _ => SSet.empty
   and freeVarsInDecs decls = 
       foldr (fn (d,S) => SSet.union(S,freeVarsInDec d))  SSet.empty decls
end
end
