(**
 * ReifiedTermToML
 * @copyright (c) 2017- Tohoku University.
 * @author Atsuhi Ohori
 * @author Katsuhiro Ueno
 * @author Tomohiro Sasaki
 *)

structure ReifiedTermToML =
struct
  local
    structure BP = SMLSharp_Builtin.Pointer
    structure D = SMLSharp_Builtin.Dynamic
    structure P = Pointer
    structure R = ReifiedTerm
    structure RTy = ReifiedTy
    structure A = Array
    structure BA = SMLSharp_Builtin.Array
    structure S = SMLSharp_Builtin.String
    structure V = SMLSharp_Builtin.Vector
  in
    exception UnsupportedTerm of R.reifiedTerm
    exception Undetermined

    (* See also TypeLayout2.sml and BuiltinTypeNames.ppg and DatatypeLayout.sml. *)
    datatype tag = UNBOXED | BOXED

    fun tagToWord UNBOXED = 0w0
      | tagToWord BOXED = 0w1

    fun layoutTag layout =
        case layout of
          RTy.LAYOUT_TAGGED (RTy.TAGGED_TAGONLY _) => UNBOXED
        | RTy.LAYOUT_TAGGED _ => BOXED
        | RTy.LAYOUT_ARG_OR_NULL _ => BOXED
        | RTy.LAYOUT_SINGLE_ARG _ => BOXED
        | RTy.LAYOUT_CHOICE _ => UNBOXED
        | RTy.LAYOUT_SINGLE => UNBOXED

    fun constTag reifiedTy =
        case reifiedTy of
          RTy.ARRAYty reifiedTy => BOXED
        | RTy.BOOLty => UNBOXED
        | RTy.BOUNDVARty BoundTypeVarIDid => raise Undetermined
        | RTy.CHARty => UNBOXED
        | RTy.CODEPTRty => UNBOXED
        | RTy.CONSTRUCTty {longsymbol, id, args, conSet, layout, size} => 
          layoutTag layout
        | RTy.DATATYPEty {longsymbol, id, args, layout, size} => 
          layoutTag layout
        | RTy.EXNTAGty => BOXED
        | RTy.EXNty => BOXED
        | RTy.INT64ty => UNBOXED
        | RTy.INTERNALty size => raise Undetermined
        | RTy.INTINFty => BOXED
        | RTy.INTty => UNBOXED
        | RTy.INT8ty => UNBOXED
        | RTy.INT16ty => UNBOXED
        | RTy.LISTty reifiedTy => BOXED
        | RTy.OPAQUEty {size,...} => raise Undetermined
        | RTy.OPTIONty reifiedTy => BOXED
        | RTy.POLYty {boundenv, body} => raise Undetermined
        | RTy.PTRty reifiedTy => BOXED
        | RTy.ERRORty => raise Undetermined
        | RTy.DUMMYty {boxed, size} => if boxed then BOXED else UNBOXED
        | RTy.FUNMty _ => BOXED
        | RTy.TYVARty => raise Undetermined
        | RTy.REAL32ty => UNBOXED
        | RTy.REALty => UNBOXED
        | RTy.RECORDty reifiedTyLabelMap => BOXED
        | RTy.REFty reifiedTy => BOXED
        | RTy.STRINGty => BOXED
        | RTy.UNITty => UNBOXED
        | RTy.VECTORty reifiedTy => BOXED
        | RTy.WORD64ty => UNBOXED
        | RTy.WORD8ty => UNBOXED
        | RTy.WORD16ty => UNBOXED
        | RTy.WORDty => UNBOXED

    (* TODO: sizeOf関数はReifyTermに同様の定義あり，まとめるべき． *)
    val intSize = 0w4
    val int8Size = 0w1
    val int16Size = 0w2
    val int64Size = 0w8
    val word16Size = 0w2
    val wordSize = 0w4
    val word64Size = 0w8
    val tagSize = 0w4
    val charSize = 0w1
    val realSize = 0w8
    val real32Size = 0w4
    val ptrSize = Word.fromInt (!SMLSharp_PointerSize.pointerSize)      
    fun sizeOf reifiedTy =
        case reifiedTy of
          RTy.ARRAYty reifiedTy => ptrSize
        | RTy.BOOLty => intSize
        | RTy.BOUNDVARty BoundTypeVarIDid => raise Undetermined
        | RTy.CHARty => charSize
        | RTy.CODEPTRty => ptrSize
        | RTy.CONSTRUCTty {longsymbol, id, args, conSet, layout, size} => Word.fromInt size
        | RTy.DATATYPEty {longsymbol, id, args, layout, size} => Word.fromInt size
        | RTy.EXNTAGty => ptrSize
        | RTy.EXNty => ptrSize
        | RTy.INTty => intSize
        | RTy.INT8ty => int8Size
        | RTy.INT16ty => int16Size
        | RTy.INT64ty => int64Size
        | RTy.INTERNALty size => Word.fromInt size
        | RTy.INTINFty => ptrSize
        | RTy.LISTty reifiedTy => ptrSize
        | RTy.OPAQUEty {size,...} => Word.fromInt size
        | RTy.OPTIONty reifiedTy => ptrSize
        | RTy.POLYty {boundenv, body} => sizeOf body
        | RTy.PTRty reifiedTy  => ptrSize
        | RTy.ERRORty => raise Undetermined
        | RTy.DUMMYty {boxed, size} => size
        | RTy.FUNMty _ => ptrSize
        | RTy.TYVARty => raise Undetermined
        | RTy.REAL32ty => real32Size
        | RTy.REALty => realSize
        | RTy.RECORDty reifiedTyLabelMap => ptrSize
        | RTy.REFty reifiedTy => ptrSize
        | RTy.STRINGty => ptrSize
        | RTy.UNITty => intSize
        | RTy.VECTORty reifiedTy => ptrSize
        | RTy.WORD64ty => word64Size
        | RTy.WORD8ty => charSize
        | RTy.WORD16ty => word16Size
        | RTy.WORDty => wordSize

    fun constSize reifiedTy =
        SingletonTyEnv2.CONST (sizeOf reifiedTy)

    (* copied from Dynamic.sml *)
    fun toWord (SingletonTyEnv2.CONST w) = w
      | toWord (SingletonTyEnv2.TAG (_, tag)) =
        Word.fromInt (TypeLayout2.tagValue tag)
      | toWord (SingletonTyEnv2.SIZE (_, n)) = Word.fromInt n
      | toWord _ = raise Undetermined
    (* copy end *)

    fun toBoxed x = BP.refToBoxed (ref x)
    fun fromBoxed x = ! (BP.boxedToRef x)

    val nullTerm = R.PTR 0w0
    val nullTy = RTy.PTRty RTy.UNITty

    (* copied from Dynamic.sml *)
    fun checkNoExtraComputation accum =
        case RecordLayout2.extractDecls accum of
          nil => ()
        | _::_ => raise Undetermined

    fun computeRecordLayout tyFields =
        let
          val fieldSizes =
              map (fn (l, ty) => {tag = SingletonTyEnv2.CONST (tagToWord (constTag ty)), 
                                  size = constSize ty}) 
                  tyFields
          val accum = RecordLayout2.newComputationAccum ()
          val ret = RecordLayout2.computeRecord accum fieldSizes
          val _ = checkNoExtraComputation accum
        in
          (fieldSizes, ret)
        end

    fun makeRecord (termFields, tyFields, conSetEnv) =
        let
          val (fieldSizes, {allocSize, fieldIndexes, bitmaps, ...}) =
              computeRecordLayout tyFields
          val allocSize = toWord allocSize
          val fields =
              ListPair.mapEq
                (fn (({tag, size}, index), ((l, term), (l', ty)))  =>
                    {tag = toWord tag,
                     size = toWord size,
                     dstIndex = toWord index,
                     src = toMLValue (term, {conSetEnv = conSetEnv, reifiedTy = ty}),
                     srcIndex = 0w0})
                (ListPair.zipEq (fieldSizes, fieldIndexes),
                 ListPair.zipEq (termFields, tyFields))
          val bitmaps =
              map (fn {index, bitmap} =>
                      {index = toWord index, bitmap = toWord bitmap})
                  bitmaps
          val payloadSize =
              case bitmaps of {index,...}::_ => index | _ => raise Undetermined
          val record =
              D.allocRecord (payloadSize, allocSize)
        in
          app (fn {index, bitmap} => D.writeWord32 (record, index, bitmap))
              bitmaps;
          app (fn {tag, size, dstIndex, src, srcIndex} =>
                  D.copy (record, dstIndex, src, srcIndex, tag, size))
              fields;
          toBoxed record
        end
    (* copy end *)

    and toMLValue (reifiedTerm, {conSetEnv, reifiedTy}) =
      case (reifiedTerm, reifiedTy) of
        (R.ARRAY {dummyPrinter, contentsFn}, RTy.ARRAYty elemTy) =>
        raise UnsupportedTerm reifiedTerm
      | (R.ARRAY2 arr, RTy.ARRAYty elemTy) =>
        (* TODO: コピー部分のコード確認 *)
        let
          val len = A.length arr
          val boxedListRev = A.foldl (fn (elem, boxedListRev) => 
                                         toMLValue (elem, {conSetEnv = conSetEnv, 
                                                           reifiedTy = elemTy})
                                         :: boxedListRev)
                                     nil
                                     arr
          val boxedList = List.rev boxedListRev
          val boxedArray = A.fromList boxedList
          val size = sizeOf elemTy
        in
          (
            case constTag elemTy of
              UNBOXED =>
              let
                (* HACK: SMLSharp_Builtin.String.alloc allocates char array
                 *       that length is parameter of length + 1 for 
                 *       null terminated string.
                 *       And we use char array for BOXED tagged array.
                 *)
                val buf = S.castToBoxed (S.alloc (len * Word.toInt size - 1))
                val tag = tagToWord UNBOXED
                val _ = A.appi (fn (i, elem) => 
                                   D.copy (buf, 
                                           Word.fromInt i * size,
                                           elem,
                                           0w0,
                                           size,
                                           tag)
                               )
                               boxedArray
              in 
                toBoxed buf
              end
            | BOXED =>
              let
                val buf = BA.alloc len : boxed array
                val _ = A.appi (fn (i, elem) =>
                                   A.update (buf, i, fromBoxed elem : boxed))
                               boxedArray
              in
                toBoxed buf
              end
          )
        end
      | (R.BOOL b, RTy.BOOLty) =>
        toBoxed b
      | (R.BOUNDVAR, RTy.BOUNDVARty id) =>
        raise UnsupportedTerm reifiedTerm
      | (R.CHAR c, RTy.CHARty) =>
        toBoxed c
      | (R.CODEPTR word64, RTy.CODEPTRty) =>
        raise UnsupportedTerm reifiedTerm
      | (R.DATATYPE (con, termopt), 
         RTy.DATATYPEty {longsymbol, id, args, layout, size}) =>
        toMLValue (reifiedTerm, 
                   ReifiedTy.getConstructTy 
                     {conSetEnv = conSetEnv,
                      reifiedTy = reifiedTy})
      | (R.DATATYPE (con, termopt),
         RTy.CONSTRUCTty {longsymbol, id, args, conSet, layout, size}) =>
        (
          case layout of
            RTy.LAYOUT_TAGGED (RTy.TAGGED_RECORD {tagMap}) =>
            let
              val tag = SEnv.find (tagMap, con)
              val argTy = SEnv.find (conSet, con)
            in
              case (termopt, tag, argTy) of
                (NONE, SOME tag, SOME NONE) =>
                toMLValue (R.TUPLE [R.WORD (Word.fromInt tag)],
                           {conSetEnv = conSetEnv,
                            reifiedTy =
                            RTy.RECORDty (RecordLabel.tupleMap [RTy.WORDty])})
              | (SOME arg, SOME tag, SOME (SOME ty)) =>
                toMLValue (R.TUPLE ([R.WORD (Word.fromInt tag), arg]),
                           {conSetEnv = conSetEnv,
                            reifiedTy = 
                            RTy.RECORDty (RecordLabel.tupleMap [RTy.WORDty, ty])})
              | _ => raise Bug.Bug "RTy.LAYOUT_TAGGED RTy.TAGGED_RECORD"
            end
          | RTy.LAYOUT_TAGGED (RTy.TAGGED_OR_NULL {tagMap, nullName}) =>
            if con = nullName 
            then toMLValue (nullTerm, {conSetEnv = conSetEnv, reifiedTy = nullTy})
            else
              let
                val tag = SEnv.find (tagMap, con)
                val argTy = SEnv.find (conSet, con)
              in
                case (termopt, tag, argTy) of
                  (SOME arg, SOME tag, SOME (SOME ty)) =>
                  toMLValue (R.TUPLE ([R.WORD (Word.fromInt tag), arg]),
                             {conSetEnv = conSetEnv,
                              reifiedTy = 
                              RTy.RECORDty (RecordLabel.tupleMap [RTy.WORDty, ty])})
                | _ => raise Bug.Bug "RTy.LAYOUT_TAGGED RTy.TAGGED_OR_NULL"
              end
          | RTy.LAYOUT_TAGGED (RTy.TAGGED_TAGONLY {tagMap}) =>
            (
              case SEnv.find (tagMap, con) of
                SOME tag =>
                toMLValue (R.WORD (Word.fromInt tag),
                           {conSetEnv = conSetEnv,
                            reifiedTy = RTy.WORDty})
              | NONE => raise Bug.Bug "RTy.LAYOUT_TAGGED RTy.TAGGED_ONLY"
           )
          | RTy.LAYOUT_ARG_OR_NULL {wrap=false} =>
            (
              case (termopt, SEnv.find (conSet, con)) of
                (NONE, SOME NONE) => toMLValue (nullTerm, {conSetEnv = conSetEnv, 
                                                           reifiedTy = nullTy})
              | (SOME arg, SOME (SOME argTy)) =>
                toMLValue (arg, {conSetEnv = conSetEnv, reifiedTy = argTy})
              | _ => raise Bug.Bug "RTy.LAYOUT_ARG_OR_NULL {wrap=false}"
            )
          | RTy.LAYOUT_ARG_OR_NULL {wrap=true} =>
            (
              case (termopt, SEnv.find (conSet, con)) of
                (NONE, SOME NONE) => 
                toMLValue (nullTerm, {conSetEnv = conSetEnv, 
                                      reifiedTy = nullTy})
              | (SOME arg, SOME (SOME argTy)) =>
                toMLValue (R.TUPLE [arg],
                           {conSetEnv = conSetEnv,
                            reifiedTy = RTy.RECORDty 
                                          (RecordLabel.tupleMap [argTy])})
              | _ => raise Bug.Bug "Rty.LAYOUT_ARG_OR_NULL {wrap=true}"
            )
          | RTy.LAYOUT_SINGLE_ARG {wrap=false} =>
            (
              case (termopt, SEnv.find (conSet, con)) of
                (SOME arg, SOME (SOME argTy)) =>
                toMLValue (arg, {conSetEnv = conSetEnv, reifiedTy = argTy})
              | _ => raise Bug.Bug "RTy.LAYOUT_SINGLE_ARG {wrap=false}"
            )
          | RTy.LAYOUT_SINGLE_ARG {wrap=true} =>
            (
              case (termopt, SEnv.find (conSet, con)) of
                (SOME arg, SOME (SOME argTy)) =>
                toMLValue (R.TUPLE [arg],
                           {conSetEnv = conSetEnv,
                            reifiedTy = 
                            RTy.RECORDty (RecordLabel.tupleMap [argTy])})
              | _ => raise Bug.Bug "RTy.LAYOUT_SINGLE_ARG {wrap=true}"
            )
          | RTy.LAYOUT_CHOICE {falseName} =>
            toMLValue (R.WORD (if con = falseName then 0w0 else 0w1),
                       {conSetEnv = conSetEnv,
                        reifiedTy = RTy.WORDty})
          | RTy.LAYOUT_SINGLE =>
            toMLValue (R.WORD 0w0,
                       {conSetEnv = conSetEnv,
                        reifiedTy = RTy.WORDty})
        )
      | (R.EXNTAG, RTy.EXNTAGty) =>
        raise UnsupportedTerm reifiedTerm
      | (R.EXN _, RTy.EXNty) =>
        raise UnsupportedTerm reifiedTerm
      | (R.INT8 i, RTy.INT8ty) =>
        toBoxed i
      | (R.INT16 i, RTy.INT16ty) =>
        toBoxed i
      | (R.INT64 i, RTy.INT64ty) =>
        toBoxed i
      | (R.INTERNAL, RTy.INTERNALty size) =>
        raise UnsupportedTerm reifiedTerm
      | (R.INTINF i, RTy.INTINFty) =>
        toBoxed i
      | (R.INT i, RTy.INTty) => 
        toBoxed i
      | (R.LIST l, RTy.LISTty elemTy) =>
        let
          (* LAYOUT_ARG_OR_NULL {wrap=false} *)
          (* transrate list to nested record *)
          val (reifiedTerm, reifiedTy) = 
              List.foldr
                (fn (rt, (nextTerm, nextTy)) => 
                    (R.TUPLE [rt, nextTerm],
                     RTy.RECORDty 
                       (RecordLabel.tupleMap [elemTy, nextTy])))
                (nullTerm, nullTy)
                l
        in
          toMLValue (reifiedTerm, {conSetEnv = conSetEnv, reifiedTy = reifiedTy})
        end
      | (R.OPAQUE, RTy.OPAQUEty {longsymbol, id, args, size}) =>
        raise UnsupportedTerm reifiedTerm
      | (R.OPTION rtopt, RTy.OPTIONty ty) =>
        toMLValue
          (
            case rtopt of 
              NONE => (nullTerm, {conSetEnv = conSetEnv, reifiedTy = nullTy})
            | SOME rt => 
              (* LAYOUT_ARG_OR_NULL {wrap=true} *)
              (R.TUPLE [rt], 
               {conSetEnv = conSetEnv,
                reifiedTy = 
                RTy.RECORDty (RecordLabel.Map.singleton
                                (RecordLabel.fromInt 1,
                                 ty))})
          )
      | (R.OPTIONNONE, RTy.OPTIONty ty) => 
        toMLValue (nullTerm, {conSetEnv = conSetEnv, reifiedTy = nullTy})
      | (R.OPTIONSOME rt, RTy.OPTIONty ty) =>
        (* LAYOUT_ARG_OR_NULL {wrap=true} *)
        toMLValue
          (R.TUPLE [rt], 
           {conSetEnv = conSetEnv,
            reifiedTy = RTy.RECORDty (RecordLabel.Map.singleton
                                        (RecordLabel.fromInt 1,
                                         ty))})
      | (R.POLY rt, RTy.POLYty {boundenv, body}) =>
        raise UnsupportedTerm reifiedTerm
      | (R.PTR address, RTy.PTRty ty) =>
        toBoxed address
      | (R.REAL32 r, RTy.REAL32ty) =>
        toBoxed r
      | (R.REAL r, RTy.REALty) =>
        toBoxed r
      | (R.RECORD termFields, RTy.RECORDty tyFields) =>
        makeRecord (List.map (fn (l, rt) => (RecordLabel.fromString l, rt))
                             termFields, 
                    RecordLabel.Map.listItemsi tyFields,
                    conSetEnv)
      | (R.REF reifiedTerm, RTy.REFty reifiedTy) =>
        toBoxed (toMLValue (reifiedTerm, 
                            {conSetEnv = conSetEnv, 
                             reifiedTy = reifiedTy}))
      | (R.STRING s, RTy.STRINGty) =>
        toBoxed s
      | (R.TUPLE termFields, RTy.RECORDty tyFields) =>
        makeRecord (RecordLabel.tupleList termFields, 
                    RecordLabel.Map.listItemsi tyFields,
                    conSetEnv)
      | (R.UNIT, RTy.UNITty) =>
        toBoxed (0w0 : Word32.word)
      | (R.VECTOR {dummyPrinter, contentsFn}, RTy.VECTORty elemTy) =>
        raise UnsupportedTerm reifiedTerm
      | (R.VECTOR2 v, RTy.VECTORty elemTy) =>
        (* TODO: このコードは安全か？ 要確認 *)
        toMLValue (R.ARRAY2 (V.castToArray v),
                   {conSetEnv = conSetEnv,
                    reifiedTy = RTy.ARRAYty elemTy})
      | (R.WORD64 w, RTy.WORD64ty) =>
        toBoxed w
      | (R.WORD8 w, RTy.WORD8ty) =>
        toBoxed w
      | (R.WORD16 w, RTy.WORD16ty) =>
        toBoxed w
      | (R.WORD w, RTy.WORDty) =>
        toBoxed w
      | (R.BUILTIN, _) =>
        raise UnsupportedTerm reifiedTerm
      | (R.ELIPSIS, _) =>
        raise UnsupportedTerm reifiedTerm
      | (R.FUN {closure=f, ty=ty}, specTy as RTy.FUNMty _) =>
        if RTy.reifiedTyEq (ty, specTy) then
          toBoxed f
        else 
          (print "case of FUN\n";
           print (RTy.reifiedTyToString ty);
           print "\n";
           print (RTy.reifiedTyToString specTy);
           print "\n";
           raise Bug.Bug "Type of term and designated type does not match."
          )
      | (R.UNPRINTABLE, _) =>
        raise UnsupportedTerm reifiedTerm
      | _ => raise Bug.Bug "Type of term and designated type does not match."

    fun ('a#reify) reifiedTermToML reifiedTerm : 'a =
        fromBoxed (toMLValue (reifiedTerm, _reifyTy('a)))

  end (* local *)
end (* struct *)
