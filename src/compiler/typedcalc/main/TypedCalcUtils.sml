(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Utility functions to manipulate the typed pattern calculus.
 * @author Atsushi Ohori 
 * @version $Id: TypedCalcUtils.sml,v 1.3 2006/02/18 04:59:32 ohori Exp $
 *)
structure TypedCalcUtils : TYPEDCALCUTILS = struct
local 
    open Types StaticEnv TypedCalc TypesUtils
in

  fun getLocOfExp exp =
      case exp of
        TPFOREIGNAPPLY {loc,...} => loc
      | TPERROR => Loc.noloc
      | TPCONSTANT (_, loc) => loc
      | TPVAR (_, loc) => loc
      | TPRECFUNVAR {loc,...} => loc
      | TPPRIMAPPLY {loc,...} => loc
      | TPOPRIMAPPLY {loc,...} => loc
      | TPCONSTRUCT {loc,...} => loc
      | TPAPPM {loc,...} => loc
      | TPMONOLET {loc,...} => loc
      | TPLET(tpdecs,tpexps,tys, loc) => loc
      | TPRECORD {loc,...} => loc
      | TPSELECT {loc,...} => loc
      | TPMODIFY {loc,...} => loc
      | TPRAISE (tpexp,ty,loc) => loc
      | TPHANDLE {loc,...} => loc
      | TPCASEM {loc,...} => loc
      | TPFNM  {loc,...} => loc
      | TPPOLYFNM {loc,...} => loc
      | TPPOLY {loc,...} => loc
      | TPTAPP {loc,...} => loc
      | TPSEQ {loc,...} => loc
      | TPFFIVAL {loc,...} => loc
      | TPCAST (toexo, ty, loc) => loc

  (**
   * Make a fresh instance of a polytype and a term of that type.
   *)
  fun freshInst (ty,ex) =
      if monoTy ty then (ty,ex)
      else
        let val exLoc = getLocOfExp ex
        in
         case ty 
	   of (POLYty{boundtvars,body,...}) =>
	      let 
		  val subst = freshSubst boundtvars
		  val bty = substBTvar subst body
		  val (bodyty,ex) = freshInst (bty,
					       TPTAPP{exp=ex,
						      expTy=ty,
						      instTyList=IEnv.listItems subst,
                                                      loc=exLoc})
	      in  (bodyty, ex)
	      end
	   | FUNMty (tyList, bodyTy) =>
	      (* 
                 OLD: (fn f:ty => fn x :ty1 => inst(f x)) ex 
                 NEW   fn {x1:ty1,...,xn:tyn} => inst(ex {x1,...,xn})
               *)
	      let
		  val xList = map (fn ty => {name=Vars.newTPVarName(), strpath = NilPath, ty=ty}) tyList
		  val xexList = map (fn x => TPVAR (x, exLoc)) xList
		  val (instBodyTy, instBody) = 
                      freshInst (bodyTy,TPAPPM {funExp=ex, funTy=ty, argExpList=xexList, loc=exLoc})
	      in 
                (FUNMty(tyList, instBodyTy), 
                 TPFNM {argVarList = xList, bodyTy=instBodyTy, bodyExp=instBody, loc=exLoc})
	      end
	   | RECORDty fl => 
	      (* 
                OLD: (fn r => {...,l=inst(x.l,ty) ...}) ex 
                NEW: let val xex = ex in {...,l=inst(x.l,ty) ...}
              *)
	      (case ex of 
		  TPRECORD {fields=flex, recordTy=ty,loc=loc} =>
		      let val (newfl,newflex) =
			  SEnv.foldli
			  (fn (l,_,(newfl,newflex)) =>
			   (case (SEnv.find(fl,l),
				  SEnv.find(flex,l)) of
				(SOME ty,SOME ex) => 
				    let val (ty',ex') = freshInst(ty,ex)
				    in (SEnv.insert(newfl,l,ty'),
					SEnv.insert(newflex,l,ex'))
				    end
			      | _ => raise Control.Bug "freshInst"
				    ))
			  (SEnv.empty, SEnv.empty)
			  fl
		      in
			(
                          RECORDty newfl,
                          TPRECORD {fields=newflex, recordTy = RECORDty newfl, loc=loc}
                        )
		      end
		| _ =>
		  let 
                    fun isAtom exp =
                      case exp of
                        TPVAR v => true
                      | TPCONSTANT _ => true
                      | _ => false
                  in
                    if isAtom ex then
                      let 
                        val (flty,flex) =
                          SEnv.foldri (fn (l,a,(flty,flex)) =>
                                       let val (a,litem) = 
                                               freshInst (a,TPSELECT{label=l, exp=ex, expTy=ty, loc=exLoc})
                                       in (SEnv.insert(flty,l,a),
                                           SEnv.insert(flex,l,litem)
                                           )
                                       end)
                          (SEnv.empty,SEnv.empty)
                          fl
                      in 
                        (
                         RECORDty flty, 
                         TPRECORD {fields=flex, recordTy = RECORDty flty, loc=exLoc}
                         )
                      end
                    else
                      let 
                        val varname = Vars.newTPVarName()
                        val var = {name = varname, strpath = NilPath, ty = ty}
                        val letvar = {name = varname, ty = ty}
                        val varex = TPVAR (var, exLoc)
                        val (flty,flex) =
                          SEnv.foldri (fn (l,a,(flty,flex)) =>
                                       let val (a,litem) = 
                                               freshInst (a, TPSELECT {label=l, exp=varex, expTy=ty, loc=exLoc})
                                       in (SEnv.insert(flty,l,a),
                                           SEnv.insert(flex,l,litem)
                                           )
                                       end)
                          (SEnv.empty,SEnv.empty)
                          fl
                      in 
                        (
                         RECORDty flty, 
                         TPLET(
                               [TPVAL([(VALIDVAR letvar, ex)], exLoc)],
                               [TPRECORD {fields=flex, recordTy=RECORDty flty, loc=exLoc}],
                               [RECORDty flty],
                               exLoc
                               )
                         )
                      end
                  end
                )
	   | ty => (ty,ex)
        end
end
end
