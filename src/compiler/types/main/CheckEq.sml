(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: checkeq.sml,v 1.30 2008/08/06 12:59:09 ohori Exp $
 *)
structure CheckEq =
struct
local
  structure T = Types
  structure A = Absyn
  structure TU = TypesUtils
  structure BT = BuiltinTypes
in

  (** raised when checkEq fails *)
  exception Eqcheck

  (**
   * Coerce a type to an equality type
   * @params compileContext ty
   * @param compileContext compile context
   * @param ty the type to be coereced
   * @return nil
   *)
  fun checkEq ty =
      case ty of
        T.SINGLETONty _ => raise Eqcheck
      | T.BACKENDty _ => raise Eqcheck
      | T.ERRORty  => raise Eqcheck
      | T.DUMMYty _  => raise Eqcheck
      | T.TYVARty
          (r
             as
             ref(T.TVAR {lambdaDepth,id,tvarKind,eqKind,occurresIn, utvarOpt = NONE}))
        => 
        (case eqKind  of
           A.NONEQ =>
             r :=
             T.TVAR{
                  lambdaDepth = lambdaDepth, 
                  id = id, 
                  tvarKind = tvarKind, 
                  eqKind = A.EQ, 
                  occurresIn = occurresIn,
                  utvarOpt = NONE
                  }
           | A.EQ => ();
          case tvarKind of 
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
                         tvarKind = T.OCONSTkind newL,
                         eqKind = A.EQ, 
                         occurresIn = occurresIn,
                         utvarOpt = NONE
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
                         tvarKind = T.OPRIMkind {instances = instances,
                                                 operators = operators},
                         occurresIn = occurresIn,
                         eqKind = A.EQ, 
                         utvarOpt = NONE
                         }
              end
           | _ => ()
        )
      | T.TYVARty (ref(T.TVAR {eqKind = A.EQ, utvarOpt = SOME _, ...})) => ()
      | T.TYVARty (ref(T.TVAR {eqKind = A.NONEQ, utvarOpt = SOME _, ...})) =>
        (*
          We cannot coerce user specified noneq type variable.
        *)
           raise Eqcheck
      | T.TYVARty (ref(T.SUBSTITUTED ty)) => checkEq ty
      | T.BOUNDVARty tid => ()
      | T.FUNMty _ => raise Eqcheck
      | T.RECORDty fl => LabelEnv.foldr (fn (ty,()) => checkEq ty) () fl
      | T.CONSTRUCTty {tyCon={id,iseq,...},args} =>
        if TypID.eq(id, #id BT.arrayTyCon) then ()
        else if TypID.eq(id, #id BT.refTyCon) then ()
        else if iseq then List.app checkEq args
        else raise Eqcheck
      | T.POLYty {boundtvars, body} =>
        (
          BoundTypeVarID.Map.app 
              (fn {eqKind, ...} =>
                  (case eqKind of A.NONEQ => raise Eqcheck | A.EQ => ()))
              boundtvars;
          checkEq body
        )
  end
end
