(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: checkeq.sml,v 1.30 2008/08/06 12:59:09 ohori Exp $
 *)
structure CheckEq =
struct
local
  structure T = Types
  structure TU = TypesUtils
  structure PT = PredefinedTypes
in

  (** raised when checkEq fails *)
  exception Eqcheck

  (***************************************************************************)
  fun checkEqTyConArgs (tyCon : Types.tyCon) args =
      if TyConID.eq(#id tyCon, #id (PT.refTyCon)) then ()
      else if TyConID.eq(#id tyCon, #id(PT.arrayTyCon)) then ()
      else
          (
           case #eqKind tyCon of ref T.NONEQ => raise Eqcheck | _ => ();
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
        T.INSTCODEty _ => raise Eqcheck
      | T.ERRORty  => raise Eqcheck
      | T.DUMMYty _  => raise Eqcheck
      | T.TYVARty
          (r
             as
             ref(T.TVAR {lambdaDepth, id,recordKind,eqKind,tyvarName = NONE}))
        => 
        (case eqKind  of
           T.NONEQ =>
             r :=
             T.TVAR{
                  lambdaDepth = lambdaDepth, 
                  id = id, 
                  recordKind = recordKind, 
                  eqKind = T.EQ, 
                  tyvarName = NONE
                  }
           | T.EQ => ();
          case recordKind of 
            T.OCONSTkind L =>
              let
                val newL = List.filter TU.admitEqTy L 
              in
                case newL of
                  nil => raise Eqcheck
                | _ =>
                    r :=
                    T.TVAR{
                         lambdaDepth = lambdaDepth, 
                         id = id, 
                         recordKind = T.OCONSTkind newL,
                         eqKind = T.EQ, 
                         tyvarName = NONE
                         }
              end
          | T.OPRIMkind {instances, operators} =>
              let
                val instances = List.filter TU.admitEqTy instances
              in
                case instances of
                  nil => raise Eqcheck
                | _ =>
                    r :=
                    T.TVAR{
                         lambdaDepth = lambdaDepth, 
                         id = id, 
                         recordKind = T.OPRIMkind {instances = instances,
                                                   operators = operators},
                         eqKind = T.EQ, 
                         tyvarName = NONE
                         }
              end
           | _ => ()
        )
      | T.TYVARty (ref(T.TVAR {eqKind = T.EQ, tyvarName = SOME _, ...})) => ()
      | T.TYVARty (ref(T.TVAR {eqKind = T.NONEQ, tyvarName = SOME _, ...})) =>
        (*
          We cannot coerce user specified noneq type variable.
        *)
           raise Eqcheck
      | T.TYVARty (ref(T.SUBSTITUTED ty)) => checkEq ty
      | T.BOUNDVARty tid => ()
      | T.FUNMty _ => raise Eqcheck
      | T.RECORDty fl => SEnv.foldr (fn (ty,()) => checkEq ty) () fl
      | T.RAWty {tyCon, args} =>
        checkEqTyConArgs tyCon args
      | T.POLYty {boundtvars, body} =>
        (
          IEnv.app 
              (fn {eqKind, ...} =>
                  (case eqKind of T.NONEQ => raise Eqcheck | T.EQ => ()))
              boundtvars;
          checkEq body
        )
      | T.ALIASty(_,ty)  => checkEq ty
      | T.OPAQUEty {spec = {tyCon, args}, ...} => 
        checkEqTyConArgs tyCon args
      | T.SPECty {tyCon, args} => checkEqTyConArgs tyCon args
  end
end
