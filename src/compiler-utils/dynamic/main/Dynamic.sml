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
  type dynamic = boxed * word * Types.ty

(*
  (* for debug *)
  fun printDynamic ((x,y,z):dynamic) =
      let
        val 'a#boxed p = _import "printf" : (string,...('a,word,string)) -> int
      in
        p ("%p + %u : %s\n", x, y, Bug.prettyPrint (T.format_ty nil z))
      end
*)

  datatype value =
      CHAR of char
    | INT8 of Int8.int
    | INT16 of Int16.int
    | INT32 of Int32.int
    | INDEX of index
    | INT64 of Int64.int
    | WORD8 of Word8.word
    | WORD16 of Word16.word
    | WORD32 of Word32.word
    | WORD64 of Word64.word
    | REAL64 of real
    | REAL32 of Real32.real
    | PTR of unit ptr
    | RECORD of (RecordLabel.label * dynamic) list
    | VARIANT of Types.typId * Symbol.symbol * value option
    | LIST of dynamic_list
    | ARRAY of dynamic_array
    | VECTOR of dynamic_array
    | REF of value  (*TODO: use value instead of dynamic to avoid compiler's bug*)
    | INTINF of IntInf.int
    | STRING of string
    | EXN of exn
    | FUN
    | UNIT
    | OPTION_NONE
    | OPTION_SOME of value
    | BOOL of bool
    | OPAQUE of value
    | OTHER
  and dynamic_list =
      NIL
    | CONS of dynamic * dynamic
  withtype dynamic_array =
      {length : int, sub : int -> dynamic}

  fun variantOf (VARIANT (_, con, arg)) =
      SOME (Symbol.symbolToString con, arg)
    | variantOf _ = NONE

  fun eqTy ({id=id1,...}:T.tyCon, {id=id2,...}:T.tyCon) =
      TypID.eq (id1, id2)

  exception Undetermined

  fun single [x] = x
    | single _ = raise Undetermined

  fun constTag' ty =
      case SingletonTyEnv2.constTag SingletonTyEnv2.emptyEnv ty of
        NONE => raise Undetermined
      | SOME x => x

  fun constTag ty =
      SingletonTyEnv2.TAG (ty, constTag' ty)

  fun constSize' ty =
      case SingletonTyEnv2.constSize SingletonTyEnv2.emptyEnv ty of
        NONE => raise Undetermined
      | SOME x => x

  fun constSize ty =
      SingletonTyEnv2.SIZE (ty, constSize' ty)

  fun toWord (SingletonTyEnv2.CONST w) = w
    | toWord (SingletonTyEnv2.TAG (_, tag)) =
      Word.fromInt (TypeLayout2.tagValue tag)
    | toWord (SingletonTyEnv2.SIZE (_, n)) = Word.fromInt n
    | toWord _ = raise Undetermined

  fun checkNoExtraComputation accum =
      case RecordLayout2.extractDecls accum of
        nil => ()
      | _::_ => raise Undetermined

  fun computeRecordLayout fieldTys =
      let
        val fieldSizes =
            map (fn ty => {tag = constTag ty, size = constSize ty}) fieldTys
        val accum = RecordLayout2.newComputationAccum ()
        val ret = RecordLayout2.computeRecord accum fieldSizes
        val _ = checkNoExtraComputation accum
      in
        (fieldSizes, ret)
      end

  fun readRecord (p, i, fieldTys) =
      let
        val (_, {fieldIndexes, ...}) = computeRecordLayout fieldTys
        val fieldIndexes = map toWord fieldIndexes
        val r = Dynamic.readBoxed (p, i)
      in
        ListPair.mapEq
          (fn (ty, i) => (r, i, ty))
          (fieldTys, fieldIndexes)
      end

  fun readRecordWithLabels (p, i, fields) =
      let
        val (labels, fieldTys) = ListPair.unzip fields
      in
        ListPair.zipEq (labels, readRecord (p, i, fieldTys))
      end

  fun readArray con (p, i, elemTy) =
      let
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

  fun invertTagMap tagMap =
      SymbolEnv.foldli
        (fn (conName, (tag, ty), z) => IEnv.insert (z, tag, (conName, ty)))
        IEnv.empty
        tagMap

  fun mergeSymbolEnv (map1, map2) =
      SymbolEnv.mergeWith
        (fn (SOME x1, SOME x2) => SOME (x1, x2)
          | _ => raise Bug.Bug "mergeSymbolEnv")
        (map1, map2)

  fun makeConMap (tagMap, conSet) =
      invertTagMap (mergeSymbolEnv (tagMap, conSet))

  fun readTag conMap (p, i) =
      let
        val tag = Dynamic.readInt32 (Dynamic.readBoxed (p, i), 0w0)
      in
        case IEnv.find (conMap, tag) of
          SOME (conName, NONE) => (conName, NONE)
        | SOME (conName, SOME ty) => (conName, SOME (ty ()))
        | NONE => raise Bug.Bug ("readTag " ^ Int.toString tag)
      end

  fun isNull (p, i) =
      Pointer.identityEqual (Dynamic.readBoxed (p, i), _NULL)

  fun unwrap {wrap} (p, i, ty) =
      if wrap
      then (Dynamic.readBoxed (p, i), 0w0, ty)
      else (p, i, ty)

  fun readTaggedValue conMap (p, i, instTys) =
      case readTag conMap (p, i) of
        (conName, NONE) => (conName, NONE)
      | (conName, SOME ty) =>
        let
val _ = print "readTaggedValue\n"
          val fields = [BuiltinTypes.contagTy,
                        TypesBasics.tpappTy (ty, instTys)]
        in
          case readRecord (p, i, fields) of
            [_, dyn] => (conName, SOME (read dyn))
          | _ => raise Bug.Bug "readTaggedValue: non-inlined"
        end

  and readTaggedLayout tagMap (tyCon as {id, conSet, ...}:T.tyCon) src =
      let
        val (conName, arg) = readTaggedValue (makeConMap (tagMap, conSet)) src
      in
        VARIANT (id, conName, arg)
      end

  (* See also DatatypeCompilation.sml *)
  and readDty (p, i, tyCon as {id, conSet, ...}, instTys) =
      if SymbolEnv.isEmpty conSet then OTHER else
      case DatatypeLayout.datatypeLayout tyCon of
        D.LAYOUT_TAGGED (D.TAGGED_RECORD {tagMap}) =>
        readTaggedLayout tagMap tyCon (p, i, instTys)
      | D.LAYOUT_TAGGED (D.TAGGED_OR_NULL {tagMap, nullName}) =>
        if isNull (p, i)
        then VARIANT (id, nullName, NONE)
        else readTaggedLayout tagMap tyCon (p, i, instTys)
      | D.LAYOUT_TAGGED (D.TAGGED_TAGONLY {tagMap}) =>
        let
          val tag = Dynamic.readInt32 (p, i)
        in
          case IEnv.find (makeConMap (tagMap, conSet), tag) of
            SOME (conName, NONE) => VARIANT (id, conName, NONE)
          | _ => raise Bug.Bug "readDty: TAGGED_TAGONLY"
        end
      | D.LAYOUT_CHOICE {falseName} =>
        let
          val trueName =
              case SymbolEnv.listItemsi conSet of
                [(c1, NONE), (c2, NONE)] =>
                if Symbol.eqSymbol (c1, falseName) then c2 else c1
              | _ => raise Bug.Bug "readDty: LAYOUT_BOOL"
        in
          if Dynamic.readInt32 (p, i) = 0
          then VARIANT (id, falseName, NONE)
          else VARIANT (id, trueName, NONE)
        end
      | D.LAYOUT_SINGLE =>
        (case SymbolEnv.listItemsi conSet of
           [(conName, NONE)] => VARIANT (id, conName, NONE)
         | _ => raise Bug.Bug "readDty: LAYOUT_UNIT")
      | D.LAYOUT_SINGLE_ARG w =>
        (case SymbolEnv.listItemsi conSet of
           [(con, SOME tyFn)] =>
           let
             val ty = tyFn ()
             val instTy = TypesBasics.tpappTy (ty, instTys)
           in
             VARIANT (id, con, SOME (read (unwrap w (p, i, instTy))))
           end
         | _ => raise Bug.Bug "readDty: LAYOUT_ARGONLY")
      | D.LAYOUT_ARG_OR_NULL w =>
        let
          val (argCon, argTy, nullCon) =
              case SymbolEnv.listItemsi conSet of
                [(c1, SOME ty), (c2, NONE)] => (c1, ty (), c2)
              | [(c1, NONE), (c2, SOME ty)] => (c2, ty (), c1)
              | _ => raise Bug.Bug "readDty: LAYOUT_ARG_OR_NULL"
          val instTy = TypesBasics.tpappTy (argTy, instTys)
        in
          if isNull (p, i)
          then VARIANT (id, nullCon, NONE)
          else VARIANT (id, argCon, SOME (read (unwrap w (p, i, instTy))))
        end
      | D.LAYOUT_REF => raise Bug.Bug "readDty: LAYOUT_REF"

  and readPrim (p, i, bty, argTys) =
      case bty of
        B.INT8ty => INT8 (Dynamic.readInt8 (p, i))
      | B.INT16ty => INT16 (Dynamic.readInt16 (p, i))
      | B.INT32ty => INT32 (Dynamic.readInt32 (p, i))
      | B.INDEXty => INDEX (Dynamic.readIndex (p, i))
      | B.INT64ty => INT64 (Dynamic.readInt64 (p, i))
      | B.INTINFty => INTINF (Dynamic.readIntInf (p, i))
      | B.WORD8ty => WORD8 (Dynamic.readWord8 (p, i))
      | B.WORD16ty => WORD16 (Dynamic.readWord16 (p, i))
      | B.WORD32ty => WORD32 (Dynamic.readWord32 (p, i))
      | B.WORD64ty => WORD64 (Dynamic.readWord64 (p, i))
      | B.CHARty => CHAR (Dynamic.readChar (p, i))
      | B.STRINGty => STRING (Dynamic.readString (p, i))
      | B.REAL64ty => REAL64 (Dynamic.readReal64 (p, i))
      | B.REAL32ty => REAL32 (Dynamic.readReal32 (p, i))
      | B.UNITty => UNIT
      | B.PTRty => PTR (Dynamic.readPtr (p, i))
      | B.CODEPTRty => PTR (Dynamic.readPtr (p, i))
      | B.ARRAYty => readArray ARRAY (p, i, single argTys)
      | B.VECTORty => readArray VECTOR (p, i, single argTys)
      | B.EXNty => EXN (Dynamic.readExn (p, i))
      | B.BOXEDty => OTHER
      | B.EXNTAGty => OTHER
      | B.CONTAGty => OTHER
      | B.REFty => REF (read (Dynamic.readBoxed (p, i), 0w0, single argTys))

  and read ((p, i, ty):dynamic) =
      case ty of
        T.SINGLETONty _ => OTHER
      | T.BACKENDty _ => OTHER
      | T.ERRORty => OTHER
      | T.DUMMYty _ => OTHER
      | T.TYVARty (ref (T.TVAR _)) => OTHER
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => read (p, i, ty)
      | T.BOUNDVARty _ => OTHER
      | T.FUNMty _ => FUN
      | T.POLYty {boundtvars, constraints, body} =>
        (
          case TypesBasics.derefTy body of
            T.FUNMty _ => FUN
          | _ => OTHER  (* FIXME: cannot print NONE *)
        )
      | T.RECORDty fields =>
        (RECORD (readRecordWithLabels (p, i, RecordLabel.Map.listItemsi fields))
         handle Undetermined => OTHER)
      | T.CONSTRUCTty {tyCon, args} =>
        case #dtyKind tyCon of
          T.BUILTIN bty => readPrim (p, i, bty, args)
        | T.DTY =>
          (* FIXME: workaround for standalone user programs.
           * A standalone program cannot access to the conSet of a tyCon
           * since conSet includes function closures whose code pointers
           * are available only in the compiler.
           * The following conditions are needed to avoid the illegal
           * access to the function closures.
           *)
          if eqTy (tyCon, BuiltinTypes.listTyCon) then
            case variantOf (readDty (p, i, BuiltinTypes.listTyCon, args)) of
              SOME ("nil", NONE) => LIST NIL
            | SOME ("::", SOME (RECORD [(_, car), (_, cdr)])) =>
              LIST (CONS (car, cdr))
            | _ => raise Bug.Bug "CONSTRUCTty:list"
          else if eqTy (tyCon, BuiltinTypes.optionTyCon) then
            case variantOf (readDty (p, i, BuiltinTypes.optionTyCon, args)) of
              SOME ("NONE", NONE) => OPTION_NONE
            | SOME ("SOME", SOME x) => OPTION_SOME x
            | _ => raise Bug.Bug "CONSTRUCTty:option"
          else if eqTy (tyCon, BuiltinTypes.boolTyCon) then
            case variantOf (readDty (p, i, BuiltinTypes.boolTyCon, args)) of
              SOME ("true", NONE) => BOOL true
            | SOME ("false", NONE) => BOOL false
            | _ => raise Bug.Bug "CONSTRUCTty:bool"
                         (* FIXME: workaround ends here *)
          else
            readDty (p, i, tyCon, args)
        | T.OPAQUE {opaqueRep, revealKey} =>
          case opaqueRep of
            T.TYCON tyCon =>
            OPAQUE (read (p, i, T.CONSTRUCTty {tyCon=tyCon, args=args}))
          | T.TFUNDEF {iseq, arity, polyTy} =>
            OPAQUE (read (p, i, TypesBasics.tpappTy (polyTy, args)))

  fun readList NIL = nil
    | readList (CONS (car, cdr)) =
      case read cdr of
        LIST cdr => car :: readList cdr
      | _ => raise Bug.Bug "readList"

  fun readArray ({length, sub}:dynamic_array) =
      Vector.tabulate (length, sub)

  fun load (p, ty) =
      let
        val (fieldIndexes, {allocSize, bitmaps, ...}) =
            computeRecordLayout [ty]
        val (tag, size) =
            case fieldIndexes of
              [{tag, size}] => (toWord tag, toWord size)
            | _ => raise Undetermined
        val (bitmapIndex, bitmap) =
            case bitmaps of
              [{index,bitmap}] => (toWord index, toWord bitmap)
            | _ => raise Undetermined
        val record = Dynamic.allocRecord (bitmapIndex, toWord allocSize)
        val _ = Dynamic.writeWord32 (record, bitmapIndex, bitmap)
        val _ = Dynamic.copyFromPtr (record, 0w0, p, 0w0, tag, size)
      in
        (record, 0w0, ty)
      end
      handle Undetermined => (Pointer.refToBoxed (ref 0), 0w0, ty)

  fun makeRecord fields =
      let
        val fieldTys = RecordLabel.Map.map (fn (p, i, ty) => ty) fields
        val recordTy = T.RECORDty fieldTys
        val (fieldSizes, {allocSize, fieldIndexes, bitmaps, ...}) =
            computeRecordLayout (RecordLabel.Map.listItems fieldTys)
        val allocSize = toWord allocSize
        val fields =
            ListPair.mapEq
              (fn (({tag, size}, index), (p, i, ty)) =>
                  {tag = toWord tag,
                   size = toWord size,
                   dstIndex = toWord index,
                   src = p,
                   srcIndex = i})
              (ListPair.zipEq (fieldSizes, fieldIndexes),
               RecordLabel.Map.listItems fields)
        val bitmaps =
            map (fn {index, bitmap} =>
                    {index = toWord index, bitmap = toWord bitmap})
                bitmaps
        val payloadSize =
            case bitmaps of {index,...}::_ => index | _ => raise Undetermined
        val record =
            Dynamic.allocRecord (payloadSize, allocSize)
      in
        app (fn {index, bitmap} => Dynamic.writeWord32 (record, index, bitmap))
            bitmaps;
        app (fn {tag, size, dstIndex, src, srcIndex} =>
                Dynamic.copy (record, dstIndex, src, srcIndex, tag, size))
            fields;
        (Pointer.refToBoxed (ref record), 0w0, recordTy)
      end

  fun makeTuple fields =
      makeRecord (RecordLabel.tupleMap fields)

end
