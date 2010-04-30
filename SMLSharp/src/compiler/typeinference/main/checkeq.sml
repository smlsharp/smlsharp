(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: checkeq.sml,v 1.30 2008/08/06 12:59:09 ohori Exp $
 *)
structure CheckEq =
struct

  local
    open Types TypesUtils
    structure PT = PredefinedTypes
  in

  (***************************************************************************)

  (** raised when checkEq fails *)
  exception Eqcheck

  (***************************************************************************)
  fun checkEqTyConArgs (tyCon : Types.tyCon) args =
      if TyConID.eq(#id tyCon, #id (PT.refTyCon)) then ()
      else if TyConID.eq(#id tyCon, #id(PT.arrayTyCon)) then ()
      else
          (
           case #eqKind tyCon of ref NONEQ => raise Eqcheck | _ => ();
           foldr (fn (ty, ()) => checkEq ty) () args
          )

  (**
   * Coerce a type to an equality type
   * @params compileContext ty
   * @param compileContext compile context
   * @param ty the type to be coereced
   * @return nil
   *)
  and checkEq ty =
      case ty of
        ERRORty  => raise Eqcheck
      | DUMMYty _  => raise Eqcheck
      | TYVARty (r as ref(TVAR {lambdaDepth, id,recordKind,eqKind,tyvarName = NONE})) => 
        (case eqKind  of
           NONEQ =>
             r :=
             TVAR{
                  lambdaDepth = lambdaDepth, 
                  id = id, 
                  recordKind = recordKind, 
                  eqKind = EQ, 
                  tyvarName = NONE
                  }
           | EQ => ();
          case recordKind of 
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
                         recordKind = OVERLOADED newL,
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
      | RAWty {tyCon, args} =>
        checkEqTyConArgs tyCon args
      | POLYty {boundtvars, body} =>
        (
          IEnv.app 
              (fn {eqKind, ...} =>
                  (case eqKind of NONEQ => raise Eqcheck | EQ => ()))
              boundtvars;
          checkEq body
        )
      | ALIASty(_,ty)  => checkEq ty
      | OPAQUEty {spec = {tyCon, args}, ...} => 
        checkEqTyConArgs tyCon args
      | SPECty {tyCon, args} => checkEqTyConArgs tyCon args
  (***************************************************************************)

  end
end
