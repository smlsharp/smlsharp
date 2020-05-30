(** * constant terms.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @version $Id: ConstantTerm.ppg,v 1.1 2008/11/19 19:57:44 ohori Exp $
 *)
structure ConstantTypes =
struct

(*
  structure PT = PredefinedTypes
*)
  structure BT = BuiltinTypes
  structure T = Types
  structure TL = TypedLambda
  structure TU = TypesBasics
  structure A = AbsynConst

 (* for debugging *)
  fun printType ty =
      print (Bug.prettyPrint (Types.format_ty ty) ^ "\n")

  local

    fun decomposePolyTy (T.POLYty {boundtvars, constraints, body}) = (boundtvars, body)
      | decomposePolyTy ty = (BoundTypeVarID.Map.empty, ty)

    fun polyTy (btvEnv, bodyTy) =
        if BoundTypeVarID.Map.isEmpty btvEnv
        then bodyTy else T.POLYty {boundtvars=btvEnv, constraints=nil, body=bodyTy}

    fun overloadTy tys =
        let
          val (btvEnvs, tys) = ListPair.unzip (map decomposePolyTy tys)
          val btvEnv = foldl (BoundTypeVarID.Map.unionWith
                                (fn _ => raise Bug.Bug "unionTys"))
                             BoundTypeVarID.Map.empty
                             btvEnvs
        in
          case tys of
            [ty] => polyTy (btvEnv, ty)
          | _ =>
            let
              val btv = BoundTypeVarID.generate ()
              val btvKind = T.KIND {tvarKind = T.OCONSTkind tys, 
                                    properties = T.emptyProperties,
                                    dynamicKind = NONE
                                   }
              val btvEnv = BoundTypeVarID.Map.insert (btvEnv, btv, btvKind)
            in
              T.POLYty {boundtvars = btvEnv, constraints = nil, body = T.BOUNDVARty btv}
            end
        end

(*
    fun sqlExpTy elemTy =
        let
          val (btvEnv, elemTy) = decomposePolyTy elemTy
          val btv1 = BoundTypeVarID.generate ()
          val btv2 = BoundTypeVarID.generate ()
          val btvKind = {tvarKind = T.UNIV, eqKind = T.NONEQ, boxedKind = T.ANY, reifyKind=false}
          val btvEnv = BoundTypeVarID.Map.insert (btvEnv, btv1, btvKind)
          val btvEnv = BoundTypeVarID.Map.insert (btvEnv, btv2, btvKind)
        in
          [T.POLYty
             {boundtvars = btvEnv,
              constraints = nil,
              body = T.CONSTRUCTty
                       {tyCon = ULP.SQL_exp_tyCon (),
                        args = [T.FUNMty ([T.BOUNDVARty btv1], elemTy),
                                T.BOUNDVARty btv2]}}]
          handle ULP.IDNotFound _ => []
        end

    fun optionTy elemTy =
        let
          val (btvEnv, elemTy) = decomposePolyTy elemTy
          val tyCon = BT.optionTyCon
        in
          polyTy (btvEnv, T.CONSTRUCTty {tyCon = tyCon, args = [elemTy]})
        end

*)

    fun polyPtrTy () =
        let
          val btv = BoundTypeVarID.generate ()
          val btvKind = #kind T.univKind
          val btvEnv = BoundTypeVarID.Map.singleton (btv, btvKind)
        in
          polyTy (btvEnv, T.CONSTRUCTty {tyCon = BT.ptrTyCon,
                                         args = [T.BOUNDVARty btv]})
        end

    fun intType () =
        overloadTy
          [BT.int32Ty,
           BT.int8Ty,
           BT.int16Ty,
           BT.int64Ty,
           BT.intInfTy]

    fun wordType () =
        overloadTy
          [BT.word32Ty,
           BT.word8Ty,
           BT.word16Ty,
           BT.word64Ty]

    fun stringType () =
        BT.stringTy

    fun realType () =
        overloadTy
          [BT.real64Ty,
           BT.real32Ty]

    fun charType () =
        BT.charTy

    fun unitType () =
        BT.unitTy

  in
    fun constTy const =
        case const of
          A.INT _ => intType ()
        | A.WORD _ => wordType ()
        | A.STRING _ => stringType ()
        | A.REAL _ => realType ()
        | A.CHAR _ => charType ()
        | A.UNITCONST => unitType ()
  end

  (**
   * fix the form of constant expression according to its type.
   *)
  fun fixConst (const, ty, loc) =
      let
        datatype constTy =
                 INT8ty | INT16ty | INT32ty | INT64ty | INTINFty
               | WORD8ty | WORD16ty | WORD32ty | WORD64ty
               | REAL64ty | REAL32ty
               | CHARty | STRINGty | UNITty | PTRty | BOXEDty
        fun constTy ty =
            case TU.derefTy ty of
              T.CONSTRUCTty {tyCon={id,...}, args=[]} =>
              if TypID.eq (id, #id BT.int8TyCon) then INT8ty
              else if TypID.eq (id, #id BT.int16TyCon) then INT16ty
              else if TypID.eq (id, #id BT.int32TyCon) then INT32ty
              else if TypID.eq (id, #id BT.int64TyCon) then INT64ty
              else if TypID.eq (id, #id BT.word8TyCon) then WORD8ty
              else if TypID.eq (id, #id BT.word16TyCon) then WORD16ty
              else if TypID.eq (id, #id BT.word32TyCon) then WORD32ty
              else if TypID.eq (id, #id BT.word64TyCon) then WORD64ty
              else if TypID.eq (id, #id BT.charTyCon) then CHARty
              else if TypID.eq (id, #id BT.stringTyCon) then STRINGty
              else if TypID.eq (id, #id BT.real64TyCon) then REAL64ty
              else if TypID.eq (id, #id BT.real32TyCon) then REAL32ty
              else if TypID.eq (id, #id BT.intInfTyCon) then INTINFty
              else if TypID.eq (id, #id BT.unitTyCon) then UNITty
              else if TypID.eq (id, #id BT.boxedTyCon) then BOXEDty
              else
                (printType ty;
                 raise Bug.Bug "constTy"
                )
            | T.CONSTRUCTty {tyCon={id,...}, args=[arg]} =>
              if TypID.eq (id, #id BT.ptrTyCon)
              then PTRty
              else (printType ty; raise Bug.Bug "constTy")
            | _ =>
              (printType ty;
               raise Bug.Bug "constTy")

        fun scanInt convFn src =
            convFn src
            handle Overflow => raise ConstantError.TooLargeConstant

        fun scanWord fromLargeInt toLargeInt src =
            case fromLargeInt src of
              r => if src = toLargeInt r then r
                   else raise ConstantError.TooLargeConstant
        fun scanWord8 x = scanWord Word8.fromLargeInt Word8.toLargeInt x
        fun scanWord16 x = scanWord Word16.fromLargeInt Word16.toLargeInt x
        fun scanWord32 x = scanWord Word32.fromLargeInt Word32.toLargeInt x
        fun scanWord64 x = scanWord Word64.fromLargeInt Word64.toLargeInt x

        fun constTerm const = TL.TLCONSTANT (const, loc)
        fun stringTerm string = TL.TLSTRING (string, loc)
      in
        case (const, constTy ty) of
          (A.INT x, INT8ty) =>
          constTerm (TL.INT8 (scanInt Int8.fromLarge x))
        | (A.INT x, INT16ty) =>
          constTerm (TL.INT16 (scanInt Int16.fromLarge x))
        | (A.INT x, INT32ty) =>
          constTerm (TL.INT32 (scanInt Int32.fromLarge x))
        | (A.INT x, INT64ty) =>
          constTerm (TL.INT64 (scanInt Int64.fromLarge x))
        | (A.INT x, INTINFty) =>
          stringTerm (TL.INTINF (scanInt IntInf.fromLarge x))
        | (A.INT _, _) => raise Bug.Bug "fixConst: INT"
        | (A.WORD x, WORD8ty) =>
          constTerm (TL.WORD8 (scanWord8 x))
        | (A.WORD x, WORD16ty) =>
          constTerm (TL.WORD16 (scanWord16 x))
        | (A.WORD x, WORD32ty) =>
          constTerm (TL.WORD32 (scanWord32 x))
        | (A.WORD x, WORD64ty) =>
          constTerm (TL.WORD64 (scanWord64 x))
        | (A.WORD _, _) => raise Bug.Bug "fixConst: WORD"
        | (A.STRING x, STRINGty) => stringTerm (TL.STRING x)
        | (A.STRING _, _) => raise Bug.Bug "fixConst: STRING"
        | (A.REAL x, REAL64ty) =>
          (case Real64.fromString x of
             NONE => raise Bug.Bug "fixConst: Real64"
           | SOME x => constTerm (TL.REAL64 x))
        | (A.REAL x, REAL32ty) =>
          (case Real32.fromString x of
             NONE => raise Bug.Bug "fixConst: Real32"
           | SOME x => constTerm (TL.REAL32 x))
        | (A.REAL _, _) => raise Bug.Bug "fixConst: REAL"
        | (A.CHAR x, CHARty) => constTerm (TL.CHAR x)
        | (A.CHAR _, _) => raise Bug.Bug "fixConst: CHAR"
        | (A.UNITCONST, UNITty) => constTerm TL.UNIT
        | (A.UNITCONST, _) => raise Bug.Bug "fixConst: UNITCONST"
      end

end
