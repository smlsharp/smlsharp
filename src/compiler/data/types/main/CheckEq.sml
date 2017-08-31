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
      | T.DUMMYty _ => raise Eqcheck
      | T.TYVARty
          (r
             as
             ref(T.TVAR {lambdaDepth,id, kind = T.KIND {tvarKind, eqKind, dynKind, reifyKind, subkind}, utvarOpt = NONE}))
        => 
        (case eqKind  of
           T.NONEQ =>
             r :=
             T.TVAR{
                  lambdaDepth = lambdaDepth, 
                  id = id, 
                  kind = T.KIND {tvarKind = tvarKind, 
                                 eqKind = T.EQ, 
                                 dynKind=dynKind,
                                 reifyKind=reifyKind,
                                 subkind = subkind},
                  utvarOpt = NONE
                  }
           | T.EQ => ();
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
                         kind = T.KIND {tvarKind = T.OCONSTkind newL,
                                        eqKind = T.EQ, 
                                        dynKind = dynKind,
                                        reifyKind = reifyKind,
                                        subkind = subkind},
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
                         kind = T.KIND
                                  {tvarKind = T.OPRIMkind
                                                {instances = instances,
                                                 operators = operators},
                                   eqKind = T.EQ, 
                                   dynKind = dynKind,
                                   reifyKind = reifyKind,
                                   subkind = subkind},
                         utvarOpt = NONE
                         }
              end
           | _ => ()
        )
      | T.TYVARty (ref(T.TVAR {kind = T.KIND {eqKind = T.EQ, ...}, utvarOpt = SOME _, ...})) => ()
      | T.TYVARty (ref(T.TVAR {kind = T.KIND {eqKind = T.NONEQ, ...}, utvarOpt = SOME _, ...})) =>
        (*
          We cannot coerce user specified noneq type variable.
        *)
           raise Eqcheck
      | T.TYVARty (ref(T.SUBSTITUTED ty)) => checkEq ty
      | T.BOUNDVARty tid => ()
      | T.FUNMty _ => raise Eqcheck
      | T.RECORDty fl => RecordLabel.Map.foldr (fn (ty,()) => checkEq ty) () fl
      | T.CONSTRUCTty {tyCon={id,iseq,...},args} =>
        if TypID.eq(id, #id BT.arrayTyCon) then ()
        else if TypID.eq(id, #id BT.refTyCon) then ()
        else if iseq then List.app checkEq args
        else raise Eqcheck
      | T.POLYty {boundtvars, constraints, body} =>
        (
          BoundTypeVarID.Map.app 
              (fn T.KIND {eqKind, ...} =>
                  (case eqKind of T.NONEQ => raise Eqcheck | T.EQ => ()))
              boundtvars;
          checkEq body
        )
  end
end
