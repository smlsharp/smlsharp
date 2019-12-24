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
(*
  structure BT = BuiltinTypes
*)
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
      if TU.admitEqTy ty then ()
      else
        case ty of
          T.TYVARty
            (r
               as
               ref(T.TVAR {lambdaDepth,
                           id, 
                           kind = T.KIND {tvarKind, properties, dynamicKind}, 
                           utvarOpt = NONE}))
          => 
          (case tvarKind of 
             T.UNIV =>
               r :=
               T.TVAR
                 {
                  lambdaDepth = lambdaDepth, 
                  id = id, 
                  kind = T.KIND {tvarKind = tvarKind,
                                 properties = T.addProperties T.EQ properties,
                                 dynamicKind = dynamicKind},
                  utvarOpt = NONE
                 }
           | T.REC tyRecordLabelMap  => 
             (checkEq (T.RECORDty tyRecordLabelMap);
              r :=
              T.TVAR
                {
                 lambdaDepth = lambdaDepth, 
                 id = id, 
                 kind = T.KIND {tvarKind = tvarKind,
                                properties = T.addProperties T.EQ properties,
                                dynamicKind = dynamicKind
                               },
                 utvarOpt = NONE
                }
             )
           | T.OCONSTkind L =>
             let
               val newL = List.filter TU.admitEqTy L 
             in
               case newL of
                 nil => raise Eqcheck
               | _ =>
                 r :=
                 T.TVAR
                   {
                    lambdaDepth = lambdaDepth, 
                    id = id, 
                    kind = T.KIND {tvarKind = T.OCONSTkind newL,
                                   properties = T.addProperties T.EQ properties,
                                   dynamicKind = dynamicKind
                                  },
                    utvarOpt = NONE
                   }
             end
           | _ => raise Eqcheck
          )
      | T.TYVARty (ref(T.SUBSTITUTED ty)) => checkEq ty
      | T.BOUNDVARty tid => ()
      | T.RECORDty fl => RecordLabel.Map.foldr (fn (ty,()) => checkEq ty) () fl
      | T.CONSTRUCTty {tyCon={id,admitsEq,...},args} =>
        if TypID.eq(id, T.arrayTypId) then ()
        else if TypID.eq(id, T.refTypId) then ()
        else if admitsEq then List.app checkEq args
        else raise Eqcheck
(*
        if TypID.eq(id, #id BT.arrayTyCon) then ()
        else if TypID.eq(id, #id BT.refTyCon) then ()
        else if admitsEq then List.app checkEq args
        else raise Eqcheck
*)
      | T.POLYty {boundtvars, constraints, body} =>
        (
          BoundTypeVarID.Map.app 
            (fn T.KIND {properties, ...} =>
                if T.isProperties T.EQ properties then () else raise Eqcheck)
            boundtvars;
          checkEq body
        )
      | T.DUMMYty (dummyTyID, T.KIND {tvarKind, properties, dynamicKind}) =>
        if T.isProperties T.EQ properties then () else raise Eqcheck
      | _ => raise Eqcheck
  end
end
