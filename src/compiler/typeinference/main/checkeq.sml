(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: checkeq.sml,v 1.21 2007/01/28 12:39:56 ohori Exp $
 *)
structure CheckEq =
struct

  local
    open Types TypesUtils Basics
    structure PT = PredefinedTypes
  in

  (***************************************************************************)

  (** raised when checkEq fails *)
  exception Eqcheck

  (***************************************************************************)

  (**
   * Coerce a type to an equality type
   * @params compileContext ty
   * @param compileContext compile context
   * @param ty the type to be coereced
   * @return nil
   *)
  fun checkEq ty =
      case ty of
        ERRORty  => raise Eqcheck
      | DUMMYty _  => raise Eqcheck
      | TYVARty (r as ref(TVAR {lambdaDepth, id,recKind,eqKind,tyvarName = NONE})) => 
        (case eqKind  of
           NONEQ =>
             r :=
             TVAR{
                  lambdaDepth = lambdaDepth, 
                  id = id, 
                  recKind = recKind, 
                  eqKind = EQ, 
                  tyvarName = NONE
                  }
           | EQ => ();
          case recKind of 
            OVERLOADED L =>
              let
                val newL = List.filter admitEqTy L 
              in
                case newL of
                  nil => raise Eqcheck
                | _ =>
                    r :=
                    TVAR{
                         lambdaDepth = lambdaDepth, 
                         id = id, 
                         recKind = OVERLOADED newL,
                         eqKind = EQ, 
                         tyvarName = NONE
                         }
              end
           | _ => ()
             )
      | TYVARty (ref(TVAR {eqKind = EQ, tyvarName = SOME _, ...})) => ()
      | TYVARty (ref(TVAR {eqKind = NONEQ, tyvarName = SOME _, ...})) =>
        (*
          We cannot coerce user specified noneq type variable.
        *)
           raise Eqcheck
      | TYVARty (ref(SUBSTITUTED ty)) => checkEq ty
      | BOUNDVARty tid => ()
      | FUNMty _ => raise Eqcheck
      | RECORDty fl => SEnv.foldr (fn (ty,()) => checkEq ty) () fl
      | CONty {tyCon = tyCon, args} =>
         if ID.eq(#id tyCon, PT.refTyConid) then ()
         else if ID.eq(#id tyCon, PT.arrayTyConid) then ()
         else
           (
            case #eqKind tyCon of ref NONEQ => raise Eqcheck | _ => ();
              foldr (fn (ty, ()) => checkEq ty) () args
           )
      | POLYty {boundtvars, body} =>
        (
          IEnv.app 
              (fn {eqKind, ...} =>
                  (case eqKind of NONEQ => raise Eqcheck | EQ => ()))
              boundtvars;
          checkEq body
        )
      | BOXEDty => raise Eqcheck
      | ATOMty => raise Eqcheck
      | GENERICty => raise Eqcheck
      | INDEXty (ty, l) => raise Eqcheck
      | BMABSty _ => raise Eqcheck
      | BITMAPty _ => raise Eqcheck
      | ALIASty(_,ty)  => checkEq ty
      | BITty _ => raise Eqcheck
      | UNBOXEDty => raise Eqcheck
      | DBLUNBOXEDty => raise Eqcheck
      | OFFSETty _  => raise Eqcheck
      | TAGty _ => raise Eqcheck
      | SIZEty _ => raise Eqcheck
      | DOUBLEty => raise Eqcheck
      | PADty _ => raise Eqcheck
      | PADCONDty _ => raise Eqcheck
      | FRAMEBITMAPty intList => raise Eqcheck
      | ABSSPECty(ty,_) => checkEq ty
      | SPECty ty => checkEq ty
      | ABSTRACTty => raise Eqcheck
  (***************************************************************************)

  end
end
