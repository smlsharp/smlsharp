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
(*
  structure BT = BuiltinTypes
*)
  structure R = RuntimeTypes
  type ty = T.ty
  type varInfo = T.varInfo

  fun bug s = Bug.Bug ("TypesUtils: " ^ s)
  fun printType ty = print (Bug.prettyPrint (T.format_ty ty))
  fun printKind kind = print (Bug.prettyPrint (T.format_tvarKind kind))
  fun printSubst subst =
      BoundTypeVarID.Map.mapi 
        (fn (i,ty) => (print (BoundTypeVarID.toString i);
                       print "=";
                       printType ty;
                       print "\n"))
        subst
in
  fun isBoxedTy ty =
      let
        exception NonBoxed
        fun visit ty = 
            case ty of
              T.SINGLETONty singletonTy => raise NonBoxed
            | T.BACKENDty _ => raise NonBoxed
            | T.ERRORty => raise NonBoxed
            | T.DUMMYty (id, kind) => visitKind kind
            | T.TYVARty (ref(T.TVAR {kind,...})) => visitKind kind
            | T.TYVARty (ref(T.SUBSTITUTED ty)) => visit ty
            | T.BOUNDVARty boundTypeVarID => ()
            | T.FUNMty _ => ()
            | T.RECORDty tySenvMap => RecordLabel.Map.app visit tySenvMap
            | T.CONSTRUCTty {tyCon,...} => visitTyCon tyCon
            | T.POLYty {boundtvars, constraints, body} =>
              (BoundTypeVarID.Map.app visitKind boundtvars;
               visit body)
        and visitKind (T.KIND {tvarKind, properties, dynamicKind}) =
            if T.isProperties T.BOXED properties then () else raise NonBoxed
        and visitTyCon {dtyKind, ...} =
            case dtyKind of
              T.DTY {tag = R.TAG R.BOXED, ...} => ()
            | T.DTY {tag = R.TAG R.UNBOXED, ...} => raise NonBoxed
            | T.DTY {tag = R.ANYTAG, ...} => raise NonBoxed
            | T.OPAQUE {opaqueRep = T.TYCON tyCon, ...} => visitTyCon tyCon
            | T.OPAQUE {opaqueRep = T.TFUNDEF _, ...} => raise NonBoxed
            | T.INTERFACE (T.TYCON tyCon) => visitTyCon tyCon
            | T.INTERFACE (T.TFUNDEF _) => raise NonBoxed
      in
        (visit ty; true)
        handle NonBoxed => false
      end

  fun admitEqTy ty =
      let
        exception NonEQ
        fun visit ty = 
            case ty of
              T.SINGLETONty singletonTy => raise NonEQ
            | T.BACKENDty _ => raise NonEQ
            | T.ERRORty => raise NonEQ
            | T.DUMMYty (id, kind) => visitKind kind
            | T.TYVARty (ref(T.TVAR {kind, ...})) => visitKind kind
            | T.TYVARty (ref(T.SUBSTITUTED ty)) => visit ty
            | T.BOUNDVARty boundTypeVarID => ()
            | T.FUNMty _ => raise NonEQ 
            | T.RECORDty tySenvMap => RecordLabel.Map.app visit tySenvMap
            | T.CONSTRUCTty {tyCon={id,admitsEq,...},args} =>
              if TypID.eq(id, T.arrayTypId) then ()
              else if TypID.eq(id, T.refTypId) then ()
              else if admitsEq then List.app visit args
              else raise NonEQ
(*
              if TypID.eq(id, #id BT.arrayTyCon) then ()
              else if TypID.eq(id, #id BT.refTyCon) then ()
              else if admitsEq then List.app visit args
              else raise NonEQ
*)
            | T.POLYty {boundtvars, constraints, body} =>
              (BoundTypeVarID.Map.app 
                 visitKind
                 boundtvars;
               visit body)
        and visitKind (T.KIND {tvarKind, properties, dynamicKind}) =
            if T.isProperties T.EQ properties then () else raise NonEQ
(*
            case tvarKind of
              T.UNIV => ()
            | T.REC tySenvMap => RecordLabel.Map.app visit tySenvMap
            | T.OCONSTkind tyList => List.app visit tyList
            | T.OPRIMkind {instances, operators} => List.app visit instances
*)
      in
        (visit ty; true)
        handle NonEQ => false
      end

  fun isCoercibleTyToProp prop ty =
      case prop of
        T.BOXED => isBoxedTy ty
      | T.UNBOXED => not (isBoxedTy ty)
      | T.REIFY => true
      | T.EQ => admitEqTy ty

  exception CoerceTvarKindToProp
  fun coerceTvarKindToProp prop tvarKind =
      let
        fun adjustKindInTy ty =
            let
              val (_,tyset,_) = TB.EFTV (ty, nil)
            in
              OTSet.app
                (fn (tyvarRef as
                              (ref (T.TVAR
                                      {lambdaDepth, id, 
                                       kind = T.KIND {tvarKind, properties, dynamicKind},
                                       utvarOpt}
                    )))
                    =>
                    tyvarRef := T.TVAR
                                  {lambdaDepth = lambdaDepth, 
                                   id = id,
                                   kind = T.KIND {tvarKind = tvarKind, 
                                                  properties = T.addProperties prop properties,
                                                  dynamicKind = dynamicKind
                                                 }, 
                                   utvarOpt = utvarOpt
                                  }
                  | _ =>
                    raise Bug.Bug "non TVAR in adjustDepthInTy (TypesUtils.sml)"
                )
                tyset
            end
            
        fun adjustKindInTvarKind kind =
            case kind of
              T.UNIV => ()
            | T.REC fields => 
              RecordLabel.Map.app adjustKindInTy fields
            | T.OCONSTkind tyList =>
              List.app adjustKindInTy tyList
            | T.OPRIMkind {instances = tyList,...} =>
              List.app adjustKindInTy tyList
      in
        (case prop of
           T.REIFY => adjustKindInTvarKind tvarKind
         | T.EQ => adjustKindInTvarKind tvarKind
         | T.UNBOXED => ()
         | T.BOXED => ();
         case tvarKind of
           T.UNIV => T.UNIV
         | T.REC fields => T.REC fields
         | T.OCONSTkind L =>  
           let
             val L = List.filter (isCoercibleTyToProp prop) L
           in
             case L of 
               nil => raise CoerceTvarKindToProp
             | _ =>  T.OCONSTkind L
           end
         | T.OPRIMkind {instances,operators} =>  
           let
             val instances = List.filter (isCoercibleTyToProp prop) instances
           in
             case instances of 
               nil => raise CoerceTvarKindToProp
             | _ =>  T.OPRIMkind {instances = instances, operators =operators} 
           end
        )
      end


end
end
