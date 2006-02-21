(**
 * Copyright (c) 2006, Tohoku University.
 *
Utility functions which traverse and transduce a type expression.

<h3>consideration of efficiency</h3>
<p>
Functions in TypeTransducer are designed for general puropose.
As a side effect, it accompanies possibility of inefficiency in some 
cases mainly due to unnecessary traversal.
</p>
<p>
To avoid unnecessary traversal, two ways are available.
(But this does not mean a complete solution.)
</p>

<h4>(1) stop visit of type expressions</h4>
<p>
If no more visit is necessary, a visitor should throw an exception.
For example, 
<pre>
  val monoTy : ty -> bool

  local exception FALSE 
  in
  fun monoTy ty =
      TypeTransducer.foldTyPreOrder
          (fn (POLYty _, _) => raise FALSE
            | (BOUNDVARty _, _) => raise FALSE
            | _ => (true, true))
          true
          ty
          handle FALSE => false
  end
</pre>
is a function which returns true if the ty is a mono type, false otherwise.
If any poly-type term is found in the ty, no more visit is necessary.
So, the monoTy exits instantly by raising an local exception.
</p>

<h4>(2) skip visit of inner type expressions</h4>
<p>
If no visit to 'sub-terms' of a term is necessary, a pre-order visitor 
should return false.
</p>
<p>
XXXTyPreOrder takes a visitor function as its first argument.
This visitor function should return a bool value in its result value.
This bool value indicates whether to go inside the term or not.
<pre>
  val mapTyPreOrder
      : (Types.ty -> Types.ty * bool) -> Types.ty -> Types.ty
  val foldTyPreOrder
      : (Types.ty * 'a -> 'a * bool) -> 'a -> Types.ty -> 'a
</pre>
For example, 
<pre>
  val applyMatch : ty IEnv.map -> ty -> ty

  fun applyMatch subst ty =
      if IEnv.isEmpty subst
      then ty
      else 
        TypeTransducer.mapTyPreOrder
            (fn (ty as BOUNDVARty n) =>
                ((valOf (IEnv.find(subst, n))) handle Option => ty, true)
              | (ty as POLYty _) => (ty, false)
              | ty => (ty, true))
            ty
</pre>
is a function which substitutes bound type variables in the ty.
But bound type variables inside a POLYty is not substituted.
The applyMatch passes to the mapTyPreOrder a visitor function which returns 
false when visiting POLYty.
This indicates that body of POLYty should not be visited.
</p>
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypeTransducer.sml,v 1.10 2006/02/18 04:59:36 ohori Exp $
 *)
structure TypeTransducer : TYPE_TRANSDUCER =
struct

  (***************************************************************************)

  structure TY = Types

  (***************************************************************************)

  fun derefTy (TY.TYVARty(ref (TY.SUBSTITUTED ty))) = derefTy ty
    | derefTy ty = ty

  fun transTy preVisitor postVisitor initial =
      let
        (* visit type list from left to right. *)
        fun visitTys accum tys =
            let
              val (reversedTys, accum') =
                  foldl
                    (fn (ty, (tys, accum)) =>
                        let val (ty', accum') = visit accum ty
                        in (ty' :: tys, accum')
                        end)
                    ([], accum)
                    tys
            in (List.rev reversedTys, accum') end

        and visit accum ty =
            let
              val ty = derefTy ty
              val (ty, accum, goInside) = preVisitor (ty, accum)
              val (ty, accum) =
                  if goInside
                  then
                    case ty of
                      TY.ERRORty => (ty, accum)
                    | TY.DUMMYty _ => (ty, accum)
                    | TY.TYVARty(ref(TY.TVAR _)) => (ty, accum)
                    | TY.TYVARty(ref(TY.SUBSTITUTED realTy)) =>
                      visit accum realTy
(* The original type expression should not be updated.
                    | TY.TYVARty(r as ref(TY.SUBSTITUTED realTy)) =>
                      let val (realTy', accum') = visit accum realTy
                      in
                        r := TY.SUBSTITUTED(realTy');
                        (ty, accum')
                      end
*)
                    | TY.BOUNDVARty _ => (ty, accum)
                    | TY.FUNMty(argTys, bodyTy) =>
                      let
                        val (argTys', accum') = visitTys accum argTys
                        val (bodyTy', accum'') = visit accum' bodyTy
                      in (TY.FUNMty(argTys', bodyTy'), accum'') end
                    | TY.RECORDty fieldMap =>
                      let
                        fun visitField (label, fieldTy, (newMap, accum)) =
                            let
                              val (fieldTy', accum') = visit accum fieldTy
                              val newMap' =
                                  SEnv.insert (newMap, label, fieldTy')
                            in (newMap', accum')
                            end
                        val (fieldMap', accum') = 
                            SEnv.foldli visitField (SEnv.empty, accum) fieldMap
                      in (TY.RECORDty fieldMap', accum') end
                    | TY.CONty{tyCon, args} =>
                      let val (args', accum') = visitTys accum args
                      in (TY.CONty{tyCon = tyCon, args = args'}, accum') end
                    | TY.POLYty{boundtvars, body} =>
                      let val (body', accum') = visit accum body
                      in
                        (
                          TY.POLYty{boundtvars = boundtvars, body = body'},
                          accum'
                        )
                      end
                    | TY.BOXEDty => (ty, accum)
                    | TY.ATOMty => (ty, accum)
                    | TY.INDEXty(blockTy, label) =>
                      let val (blockTy', accum') = visit accum blockTy
                      in (TY.INDEXty(blockTy', label), accum') end
                    | TY.BMABSty(argTys, bodyTy) =>
                      let
                        val (argTys', accum') = visitTys accum argTys
                        val (bodyTy', accum'') = visit accum' bodyTy
                      in (TY.BMABSty(argTys', bodyTy'), accum'') end
                    | TY.BITMAPty argTys =>
                      let val (argTys', accum') = visitTys accum argTys
                      in (TY.BITMAPty argTys', accum') end
                    | TY.ALIASty(aliasTy, realTy) =>
                      let
                        val ([aliasTy', realTy'], accum') =
                            visitTys accum [aliasTy, realTy]
                      in (TY.ALIASty(aliasTy', realTy'), accum') end
                    | TY.BITty _ => (ty, accum)
                    | TY.UNBOXEDty => (ty, accum)
                    | TY.DBLUNBOXEDty => (ty, accum)
                    | TY.OFFSETty _ => (ty, accum)
                    | TY.TAGty _ => (ty, accum)
                    | TY.SIZEty _ => (ty, accum)
                    | TY.DOUBLEty => (ty, accum)
                    | TY.PADty _ => (ty, accum)
                    | TY.PADCONDty _ => (ty, accum)
                    | TY.FRAMEBITMAPty _ => (ty, accum)
		    | TY.ABSSPECty(specTy,implTy) =>
                      let
		        val (implTy', accum') = visit accum implTy
			val (specTy',accum'') = visit accum' specTy
                      in 
			(TY.ABSSPECty(specTy', implTy'), accum') 
		      end
                    | TY.SPECty ty =>
                      let
                        val (ty', accum') = visit accum ty
                      in
                        (TY.SPECty ty', accum')
                      end
(*
                | _ => raise Control.Bug "unknown ty"
*)
                  else (ty, accum) (* if goInside = false *)
            in
              postVisitor (ty, accum)
            end
      in
        visit initial
      end

  fun transTyPreOrder visitor = transTy visitor (fn arg => arg)
  fun transTyPostOrder visitor =
      transTy (fn (ty, accum) => (ty, accum, true)) visitor

  fun mapTyPreOrder visitor ty =
      let
        fun preVisitor (ty, ()) =
            let val (newTy, goInside) = visitor ty in (newTy, (), goInside) end
        val (ty', _) = transTyPreOrder preVisitor () ty
      in ty' end

  fun mapTyPostOrder visitor ty =
      let
        fun postVisitor (ty, ()) = (visitor ty, ())
        val (ty', _) = transTyPostOrder postVisitor () ty
      in ty' end

  (* NOTE: foldTyXXX can be optimized by using custom visitor, not transTyXXX.
   * Because they do not need to reconstruct new type expressions, the custom
   * visitor can be written in the form of tail recursion.
   *)
  fun foldTyPreOrder visitor initial ty =
      let
        fun preVisitor (ty, accum) =
            let val (newAccum, goInside) = visitor (ty, accum)
            in (ty, newAccum, goInside) end
        val (_, accum) = transTyPreOrder preVisitor initial ty
      in accum end

  fun foldTyPostOrder visitor initial ty =
      let
        fun postVisitor (ty, accum) = (ty, visitor (ty, accum))
        val (_, accum) = transTyPostOrder postVisitor initial ty
      in accum end

  (***************************************************************************)

end;
