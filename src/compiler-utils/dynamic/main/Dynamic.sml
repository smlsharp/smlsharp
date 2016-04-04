(**
 * Dynamic
 * @copyright (c) 2015 Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Dynamic =
struct

  structure T = Types
  structure B = BuiltinTypeNames
  structure D = DatatypeLayout
  structure Dynamic = SMLSharp_Builtin.Dynamic
  structure Pointer = SMLSharp_Builtin.Pointer

  (* along with the data structure constructed by Dynamic primitive.
   * See also PrimitiveTypedLambda.sml. *)
  type dyn = boxed * word * Types.ty

  datatype value =
      WORD8 of Word8.word
    | CHAR of char
    | INT32 of Int32.int
    | INT64 of Int64.int
    | WORD32 of Word32.word
    | WORD64 of Word64.word
    | REAL of real
    | REAL32 of Real32.real
    | PTR of unit ptr
    | RECORD of (string * dyn) list
    | VARIANT of string * value option
    | LIST of dyn_list
    | ARRAY of dyn_array
    | VECTOR of dyn_array
    | REF of value  (*TODO: use value instead of dyn to avoid compiler's bug*)
    | INTINF of IntInf.int
    | STRING of string
    | EXN of exn
    | FUN
    | UNIT
    | OTHER
  and dyn_list =
      NIL
    | CONS of dyn * dyn
  withtype dyn_array =
      {length : int, sub : int -> dyn}

  exception Undetermined

  fun consL h (t, x) = (h::t, x)

  fun constTag' ty =
      case SingletonTyEnv2.constTag SingletonTyEnv2.emptyEnv ty of
        NONE => raise Undetermined
      | SOME x => x

  fun constTag ty =
      SingletonTyEnv2.TAG (ty, constTag' ty)

  fun constTagWord ty =
      case constTag' ty of
        RuntimeTypes.TAG_BOXED => 0w1
      | RuntimeTypes.TAG_UNBOXED => 0w0

  fun constSize' ty =
      case SingletonTyEnv2.constSize SingletonTyEnv2.emptyEnv ty of
        NONE => raise Undetermined
      | SOME x => x

  fun constSize ty =
      SingletonTyEnv2.SIZE (ty, constSize' ty)

  fun wordValue v =
      case v of
        SingletonTyEnv2.VAR _ => raise Undetermined
      | SingletonTyEnv2.TAG (_, RuntimeTypes.TAG_UNBOXED) => 0w0
      | SingletonTyEnv2.TAG (_, RuntimeTypes.TAG_BOXED) => 0w1
      | SingletonTyEnv2.SIZE (_, n) => Word.fromInt n
      | SingletonTyEnv2.CONST n => n
      | SingletonTyEnv2.CAST (v, _) => wordValue v

  fun checkNoExtraComputation accum =
      case RecordLayout2.extractDecls accum of
        nil => ()
      | _::_ => raise Undetermined

  fun computeRecord fields =
      let
        val accum = RecordLayout2.newComputationAccum ()
        val {fieldIndexes, ...} = RecordLayout2.computeRecord accum fields
        val _ = checkNoExtraComputation accum
      in
        map (fn SingletonTyEnv2.CONST w => w | _ => raise Undetermined)
            fieldIndexes
      end

  fun readRecord (p, i, fields) =
      let
        val fieldSizes =
            map (fn (label:string, ty) =>
                    {tag = constTag ty, size = constSize ty})
                fields
        val accum = RecordLayout2.newComputationAccum ()
        val {fieldIndexes, ...} = RecordLayout2.computeRecord accum fieldSizes
        val _ = checkNoExtraComputation accum
        val fieldIndexes =
            map (fn SingletonTyEnv2.CONST w => w | _ => raise Undetermined)
                fieldIndexes
        val r = Dynamic.readBoxed (p, i)
      in
        ListPair.mapEq
          (fn ((label, ty), i) => (label, (r, i, ty)))
          (fields, fieldIndexes)
      end

  fun readArray con (p, i, [elemTy]) =
      (let
         val ap = Dynamic.readBoxed (p, i)
         val arraySize = Dynamic.objectSize ap
         val elemSize = Word.fromInt (constSize' elemTy)
         val arrayLength = arraySize div elemSize
         fun sub i =
             if i < 0 orelse Word.fromInt i >= arrayLength
             then raise Subscript
             else (ap, elemSize * Word.fromInt i, elemTy)
       in
         con {length = Word.toInt arrayLength, sub = sub}
       end
       handle Undetermined => OTHER)
    | readArray _ _ = OTHER

  fun invertTagMap tagMap =
      SEnv.foldli
        (fn (conName, (tag, ty), z) => IEnv.insert (z, tag, (conName, ty)))
        IEnv.empty
        tagMap

  fun mergeSEnv (map1, map2) =
      SEnv.mergeWith
        (fn (SOME x1, SOME x2) => SOME (x1, x2)
          | _ => raise Bug.Bug "mergeSEnv")
        (map1, map2)

  fun makeConMap (tagMap, conSet) =
      invertTagMap (mergeSEnv (tagMap, conSet))

  fun readTag conMap (p, i) =
      let
        val tag = Dynamic.readInt (Dynamic.readBoxed (p, i), 0w0)
      in
        case IEnv.find (conMap, tag) of
          SOME (conName, NONE) => (conName, NONE)
        | SOME (conName, SOME ty) => (conName, SOME (ty ()))
        | NONE => raise Bug.Bug ("readTag " ^ Int.toString tag)
      end

  fun isNull (p, i) =
      Pointer.identityEqual (Dynamic.readBoxed (p, i), _NULL)

  fun needPack conArgTy =
      DatatypeLayout.needPack
        (case TypesBasics.derefTy conArgTy of
           T.POLYty {body, ...} => body
         | ty => ty)

  fun inlinedConArgTy conArgTy =
      case TypesBasics.derefTy conArgTy of
        T.POLYty {boundtvars, body} =>
        (case TypesBasics.derefTy body of
           T.RECORDty fieldTys =>
           T.RECORDty (LabelEnv.map
                         (fn ty => T.POLYty {boundtvars=boundtvars, body=ty})
                         fieldTys)
         | _ => conArgTy)
      | _ => conArgTy

  fun readTaggedValue conMap (p, i, instTys) =
      case readTag conMap (p, i) of
        (conName, NONE) => VARIANT (conName, NONE)
      | (conName, SOME ty) =>
        case inlinedConArgTy ty of
          T.RECORDty fieldTys =>
          let
            val fields =
                ("", BuiltinTypes.contagTy)
                :: map (fn (k, ty) => (k, TypesBasics.tpappTy (ty, instTys)))
                       (LabelEnv.listItemsi fieldTys)
            val record = readRecord (p, i, fields)
          in
            VARIANT (conName, SOME (RECORD (tl record)))
          end
        | ty =>
          let
            val fields =
                [("", BuiltinTypes.contagTy),
                 ("", TypesBasics.tpappTy (ty, instTys))]
          in
            case readRecord (p, i, fields) of
              [_, (_, dyn)] => VARIANT (conName, SOME (read dyn))
            | _ => raise Bug.Bug "readTaggedValue: non-inlined"
          end

  (* See also DatatypeCompilation.sml *)
  and readDty (p, i, tyCon as {conSet, ...}, instTys) =
      if SEnv.isEmpty conSet then OTHER else
      case DatatypeLayout.datatypeLayout tyCon of
        D.LAYOUT_TAGGED (D.TAGGED_RECORD {tagMap}) =>
        readTaggedValue (makeConMap (tagMap, conSet)) (p, i, instTys)
      | D.LAYOUT_TAGGED (D.TAGGED_OR_NULL {tagMap, nullName}) =>
        if isNull (p, i)
        then VARIANT (nullName, NONE)
        else readTaggedValue (makeConMap (tagMap, conSet)) (p, i, instTys)
      | D.LAYOUT_TAGGED (D.TAGGED_TAGONLY {tagMap}) =>
        let
          val tag = Dynamic.readInt (p, i)
        in
          case IEnv.find (makeConMap (tagMap, conSet), tag) of
            SOME (conName, NONE) => VARIANT (conName, NONE)
          | _ => raise Bug.Bug "readDty: TAGGED_TAGONLY"
        end
      | D.LAYOUT_BOOL {falseName} =>
        let
          val trueName =
              case SEnv.listItemsi conSet of
                [(c1, NONE), (c2, NONE)] =>
                if c1 = falseName then c2 else c1
              | _ => raise Bug.Bug "readDty: LAYOUT_BOOL"
        in
          if Dynamic.readInt (p, i) = 0
          then VARIANT (falseName, NONE)
          else VARIANT (trueName, NONE)
        end
      | D.LAYOUT_UNIT =>
        (case SEnv.listItemsi conSet of
           [(conName, NONE)] => VARIANT (conName, NONE)
         | _ => raise Bug.Bug "readDty: LAYOUT_UNIT")
      | D.LAYOUT_ARGONLY =>
        (case SEnv.listItemsi conSet of
           [(con, SOME tyFn)] =>
           let
             val ty = tyFn ()
             val instTy = TypesBasics.tpappTy (ty, instTys)
             val arg =
                 if needPack ty
                 then (Dynamic.readBoxed (p, i), 0w0, instTy)
                 else (p, i, instTy)
           in
             VARIANT (con, SOME (read arg))
           end
         | _ => raise Bug.Bug "readDty: LAYOUT_ARGONLY")
      | D.LAYOUT_ARG_OR_NULL =>
        let
          val (argCon, argTy, nullCon) =
              case SEnv.listItemsi conSet of
                [(c1, SOME ty), (c2, NONE)] => (c1, ty (), c2)
              | [(c1, NONE), (c2, SOME ty)] => (c2, ty (), c1)
              | _ => raise Bug.Bug "readDty: LAYOUT_ARG_OR_NULL"
          val instTy = TypesBasics.tpappTy (argTy, instTys)
        in
          if isNull (p, i)
          then VARIANT (nullCon, NONE)
          else VARIANT (argCon,
                        SOME (read (Dynamic.readBoxed (p, i), 0w0, instTy)))
        end
      | D.LAYOUT_REF => raise Bug.Bug "readDty: LAYOUT_REF"

  and readCons (p, i, tyCon, instTys) =
      case readDty (p, i, tyCon, instTys) of
        VARIANT ("nil", NONE) => LIST NIL
      | VARIANT ("::", SOME (RECORD [(_, car), (_, cdr)])) =>
        LIST (CONS (car, cdr))
      | _ => raise Bug.Bug "readCons"

  and readPrim (p, i, bty, argTys) =
      case bty of
        B.INTty => INT32 (Dynamic.readInt (p, i))
      | B.INT64ty => INT64 (Dynamic.readInt64 (p, i))
      | B.INTINFty => INTINF (Dynamic.readIntInf (p, i))
      | B.WORDty => WORD32 (Dynamic.readWord (p, i))
      | B.WORD64ty => WORD64 (Dynamic.readWord64 (p, i))
      | B.WORD8ty => WORD8 (Dynamic.readWord8 (p, i))
      | B.CHARty => CHAR (Dynamic.readChar (p, i))
      | B.STRINGty => STRING (Dynamic.readString (p, i))
      | B.REALty => REAL (Dynamic.readReal (p, i))
      | B.REAL32ty => REAL32 (Dynamic.readReal32 (p, i))
      | B.UNITty => UNIT
      | B.PTRty => PTR (Dynamic.readPtr (p, i))
      | B.CODEPTRty => PTR (Dynamic.readPtr (p, i))
      | B.ARRAYty => readArray ARRAY (p, i, argTys)
      | B.VECTORty => readArray VECTOR (p, i, argTys)
      | B.EXNty => EXN (Dynamic.readExn (p, i))
      | B.BOXEDty => OTHER
      | B.EXNTAGty => OTHER
      | B.CONTAGty => OTHER
      | B.REFty =>
        (case argTys of
           [elemTy] => REF (read (Dynamic.readBoxed (p, i), 0w0, elemTy))
         | _ => OTHER)

  and read ((p, i, ty):dyn) =
      case ty of
        T.SINGLETONty _ => OTHER
      | T.BACKENDty _ => OTHER
      | T.ERRORty => OTHER
      | T.DUMMYty _ => OTHER
      | T.TYVARty (ref (T.TVAR {tvarKind,...})) => OTHER
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => read (p, i, ty)
      | T.BOUNDVARty _ => OTHER
      | T.FUNMty _ => FUN
      | T.POLYty {boundtvars, body} =>
        (
          case TypesBasics.derefTy body of
            T.FUNMty _ => FUN
          | _ => OTHER  (* FIXME: cannot print NONE *)
        )
      | T.CONSTRUCTty {tyCon, args} =>
        (
          case #dtyKind tyCon of
            T.BUILTIN bty => readPrim (p, i, bty, args)
          | T.DTY =>
            if TypID.eq (#id tyCon, #id BuiltinTypes.listTyCon)
            then readCons (p, i, tyCon, args)
            else readDty (p, i, tyCon, args)
          | T.OPAQUE {opaqueRep, revealKey} =>
            (
              case opaqueRep of
                T.TYCON tyCon =>
                read (p, i, T.CONSTRUCTty {tyCon=tyCon, args=args})
              | T.TFUNDEF {iseq, arity, polyTy} =>
                read (p, i, TypesBasics.tpappTy (polyTy, args))
            )
        )
      | T.RECORDty fields =>
        (RECORD (readRecord (p, i, LabelEnv.listItemsi fields))
         handle Undetermined => OTHER)

  fun readList NIL = nil
    | readList (CONS (car, cdr)) =
      case read cdr of
        LIST cdr => car :: readList cdr
      | _ => raise Bug.Bug "readList"

  fun readArray ({length, sub}:dyn_array) =
      Vector.tabulate (length, sub)

  fun load (p, ty) =
      (Dynamic.dup (p, constTagWord ty, constSize' ty), 0w0, ty) : dyn
      handle Undetermined => (Dynamic.dup (p, 0w0, 0), 0w0, ty)

end
