(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypesUtils.sml,v 1.35.6.3 2009/10/10 07:05:41 katsu Exp $
 *)
(*
TODO:
  1.  ***compTy in RecordCompile.sml loop bug**** the fix is temporary
*)
structure TypesUtils =
struct
local 
  structure T = Types 
  structure TB = TypesBasics
  structure BT = BuiltinTypes
  type ty = T.ty
  type varInfo = T.varInfo

  fun bug s = Bug.Bug ("TypesUtils: " ^ s)
  fun printType ty = print (Bug.prettyPrint (T.format_ty nil ty))
  fun printKind kind = print (Bug.prettyPrint (T.format_tvarKind nil kind))
  fun printSubst subst =
      BoundTypeVarID.Map.mapi 
        (fn (i,ty) => (print (BoundTypeVarID.toString i);
                       print "=";
                       printType ty;
                       print "\n"))
        subst
in
  exception CoerceTvarKindToEQ 
  fun admitEqTy ty =
      let
        exception NonEQ
        fun visit ty = 
            case ty of
              T.SINGLETONty singletonTy => raise NonEQ
            | T.BACKENDty _ => raise NonEQ
            | T.ERRORty => raise NonEQ
            | T.DUMMYty (id, kind) => visitKind kind
            | T.TYVARty (ref(T.TVAR {kind = T.KIND {eqKind = T.NONEQ, ...}, ...})) => raise NonEQ
            | T.TYVARty (ref(T.TVAR {kind = T.KIND {eqKind = T.EQ, ...}, ...})) => ()
            | T.TYVARty (ref(T.SUBSTITUTED ty)) => visit ty
            | T.BOUNDVARty boundTypeVarID => ()
            | T.FUNMty _ => raise NonEQ 
            | T.RECORDty tySenvMap => RecordLabel.Map.app visit tySenvMap
            | T.CONSTRUCTty {tyCon={id,iseq,...},args} =>
              if TypID.eq(id, #id BT.arrayTyCon) then ()
              else if TypID.eq(id, #id BT.refTyCon) then ()
              else if iseq then List.app visit args
              else raise NonEQ
            | T.POLYty {boundtvars, constraints, body} =>
              (BoundTypeVarID.Map.app 
                 visitKind
                 boundtvars;
               visit body)
        and visitKind (T.KIND {tvarKind, subkind, eqKind, reifyKind, dynKind}) =
            case tvarKind of
              T.UNIV => ()
            | T.BOXED => ()
            | T.REC tySenvMap => RecordLabel.Map.app visit tySenvMap
            | T.OCONSTkind tyList => List.app visit tyList
            | T.OPRIMkind {instances, operators} => List.app visit instances
      in
        (visit ty; true)
        handle NonEQ => false
      end

  fun coerceTvarKindToEQ tvarKind = 
      let
        fun adjustEqKindInTy eqKind ty = 
            case eqKind of
              T.NONEQ => ()
            | T.EQ => 
              let
                val (_,tyset,_) = TB.EFTV (ty, nil)
              in
                OTSet.app
                  (fn (tyvarRef as 
                       (ref (T.TVAR
                               {lambdaDepth, id, kind = T.KIND kind, utvarOpt}
                      )))
                      =>
                      tyvarRef := T.TVAR
                                    {lambdaDepth = lambdaDepth, 
                                     id = id,
                                     kind = T.KIND (kind # {eqKind = T.EQ}),
                                     utvarOpt = utvarOpt
                                    }
                    | _ =>
                      raise
                        Bug.Bug
                          "non TVAR in adjustDepthInTy (TypesUtils.sml)"
                  )
                  tyset
              end

        fun adjustEqKindInTvarKind eqKind kind = 
            case kind of
              T.UNIV => ()
            | T.BOXED => ()
            | T.REC fields => 
              RecordLabel.Map.app (adjustEqKindInTy eqKind) fields
            | T.OCONSTkind tyList =>
              List.app (adjustEqKindInTy eqKind) tyList
            | T.OPRIMkind {instances = tyList,...} =>
              List.app (adjustEqKindInTy eqKind) tyList
      in
        (adjustEqKindInTvarKind T.EQ tvarKind;
         case tvarKind of
           T.UNIV => T.UNIV
         | T.BOXED => T.BOXED
         | T.REC fields => T.REC fields
         | T.OCONSTkind L =>  
           let
             val L = List.filter admitEqTy L
           in
             case L of 
               nil => raise CoerceTvarKindToEQ 
             | _ =>  T.OCONSTkind L
           end
         | T.OPRIMkind {instances,operators} =>  
           let
             val instances = List.filter admitEqTy instances
           in
             case instances of 
               nil => raise CoerceTvarKindToEQ 
             | _ =>  T.OPRIMkind {instances = instances, operators =operators} 
           end
        )
      end


end
end
