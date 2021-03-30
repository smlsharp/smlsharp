(**
 * ReifiedTermToML
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsuhi Ohori
 * @author Katsuhiro Ueno
 * @author Tomohiro Sasaki
 *)

structure ReifiedTermToML =
struct
  local
    structure BP = SMLSharp_Builtin.Pointer
    structure D = SMLSharp_Builtin.Dynamic
    (* structure P = Pointer *)
    structure R = ReifiedTerm
    structure RTy = ReifiedTy
    (* structure RTU = ReifiedUtils *)
    (* structure A = Array *)
    structure BA = SMLSharp_Builtin.Array
    structure S = SMLSharp_Builtin.String
    structure V = SMLSharp_Builtin.Vector
    fun bug s = Bug.Bug s
    fun printRty reifiedTy = print (RTy.reifiedTyToString reifiedTy ^ "\n")
  in
    exception UnsupportedTerm of R.reifiedTerm
    exception Undetermined
    exception AttemptToConvertNullValue
    exception AttemptToConvertVoidValue

    (* See also TypeLayout2.sml and RuntimeTypes.ppg and DatatypeLayout.sml. *)
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
        | RTy.BOTTOMty => UNBOXED
        | RTy.BOXEDty => BOXED
        | RTy.BOUNDVARty BoundTypeVarIDid => raise Undetermined
        | RTy.CHARty => UNBOXED
        | RTy.CODEPTRty => UNBOXED
        | RTy.CONSTRUCTty {longsymbol, id, args, conSet, layout, size} => layoutTag layout
        | RTy.DATATYPEty {longsymbol, id, args, layout, size} => layoutTag layout
        | RTy.DUMMYty {boxed, size} => if boxed then BOXED else UNBOXED
        | RTy.EXISTty {boxed = SOME true, size, id} => BOXED
        | RTy.EXISTty {boxed = SOME false, size, id} => UNBOXED
        | RTy.EXISTty {boxed = NONE, size, id} => raise Undetermined
        | RTy.DYNAMICty _ => BOXED
        | RTy.ERRORty => raise Undetermined
        | RTy.EXNTAGty => BOXED
        | RTy.EXNty => BOXED
        | RTy.FUNMty _ => BOXED
        | RTy.IENVMAPty _ => BOXED
        | RTy.INT16ty => UNBOXED
        | RTy.INT64ty => UNBOXED
        | RTy.INT8ty => UNBOXED
        | RTy.INTERNALty => raise Undetermined
        | RTy.INTINFty => BOXED
        | RTy.INT32ty => UNBOXED
        | RTy.LISTty reifiedTy => BOXED
        | RTy.OPAQUEty {size,id, boxed, ...} => if boxed then BOXED else UNBOXED
        | RTy.OPTIONty reifiedTy => BOXED
        | RTy.POLYty {boundenv, body} => raise Undetermined
        | RTy.PTRty reifiedTy => BOXED
        | RTy.REAL32ty => UNBOXED
        | RTy.REAL64ty => UNBOXED
        | RTy.RECORDty reifiedTyLabelMap => BOXED
        | RTy.RECORDLABELty => BOXED
        | RTy.RECORDLABELMAPty _ => BOXED
        | RTy.REFty reifiedTy => BOXED
        | RTy.SENVMAPty _ => BOXED
        | RTy.STRINGty => BOXED
        | RTy.VOIDty => UNBOXED
        | RTy.TYVARty => raise Undetermined
        | RTy.UNITty => UNBOXED
        | RTy.VECTORty reifiedTy => BOXED
        | RTy.WORD16ty => UNBOXED
        | RTy.WORD64ty => UNBOXED
        | RTy.WORD8ty => UNBOXED
        | RTy.WORD32ty => UNBOXED

    fun isBoxed ty = case constTag ty of BOXED => true | _ => false 

    fun constSize reifiedTy =
        RecordLayoutCalc.WORD (RTy.sizeOf reifiedTy)

    (* copied from Dynamic.sml *)
    fun toWord (RecordLayoutCalc.WORD w) = w
      | toWord (RecordLayoutCalc.VAR _) = raise Undetermined
    (* copy end *)

    fun toBoxed x = BP.refToBoxed (ref x)
    fun fromBoxed x = ! (BP.boxedToRef x)

    val nullTerm = R.PTR 0w0
    val nullTy = RTy.PTRty RTy.UNITty

    (* copied from Dynamic.sml *)
    fun checkNoExtraComputation accum =
        case RecordLayout.extractDecls accum of
          nil => ()
        | _::_ => raise Undetermined

    fun computeRecordLayout tyList =
        let
          val fieldSizes =
              map (fn ty => {tag = RecordLayoutCalc.WORD (tagToWord (constTag ty)),
                             size = constSize ty}) 
                  tyList
          val accum = RecordLayout.newComputationAccum ()
          val ret = RecordLayout.computeRecord accum fieldSizes
          val _ = checkNoExtraComputation accum
        in
          (fieldSizes, ret)
        end
        handle Undetermined => (print "computeRecordLayout\n"; raise Undetermined)

    fun toML (reifiedTerm, {conSetEnv, reifiedTy}) = 
        let
          fun getConstructTy reifiedTy = 
              #reifiedTy (RTy.getConstructTy {conSetEnv = conSetEnv, reifiedTy = reifiedTy})

          fun makeRecord (nil,_) = toBoxed {}
            | makeRecord (termList, tyList) =
              let
                val (fieldSizes, {allocSize, fieldIndexes, bitmaps, ...}) =
                    computeRecordLayout tyList
                val allocSize = toWord allocSize
                val fields =
                    ListPair.mapEq
                      (fn (({tag, size}, index), (term, ty))  =>
                          {tag = toWord tag,
                           size = toWord size,
                           dstIndex = toWord index,
                           src = toMLValue (term, ty),
                           srcIndex = 0w0})
                      (ListPair.zipEq (fieldSizes, fieldIndexes),
                       ListPair.zipEq (termList, tyList))
                val bitmaps =
                    map (fn {index, bitmap} =>
                            {index = toWord index, bitmap = toWord bitmap})
                        bitmaps
                val payloadSize =
                    case bitmaps of {index,...}::_ => index | _ => raise Undetermined
                val record = D.allocRecord (payloadSize, allocSize)
              in
                app (fn {index, bitmap} => D.writeWord32 (record, index, bitmap))
                    bitmaps;
                app (fn {tag, size, dstIndex, src, srcIndex} =>
                        D.copy (record, dstIndex, src, srcIndex, tag, size))
                    fields;
                toBoxed record
              end

          and toMLDatatype ((con,termopt,ty1), 
                            {longsymbol, id, args, conSet, layout, size}) =
              case layout of
                RTy.LAYOUT_TAGGED (RTy.TAGGED_RECORD {tagMap}) =>
                let
                  val tag = SEnv.find (tagMap, con)
                  val argTy = SEnv.find (conSet, con)
                in
                  case (termopt, tag, argTy) of
                    (NONE, SOME tag, SOME NONE) =>
                    makeRecord ([R.WORD32 (Word32.fromInt tag)],[RTy.WORD32ty])
                  | (SOME arg, SOME tag, SOME (SOME ty)) =>
                    makeRecord ([R.WORD32 (Word32.fromInt tag), arg], [RTy.WORD32ty, ty])
                  | _ => raise bug "RTy.LAYOUT_TAGGED RTy.TAGGED_RECORD"
                end
              | RTy.LAYOUT_TAGGED (RTy.TAGGED_OR_NULL {tagMap, nullName}) =>
                if con = nullName 
                then toMLValue (nullTerm,  nullTy)
                else
                  let
                    val tag = SEnv.find (tagMap, con)
                    val argTy = SEnv.find (conSet, con)
                  in
                    case (termopt, tag, argTy) of
                      (SOME arg, SOME tag, SOME (SOME ty)) =>
                      makeRecord ([R.WORD32 (Word.fromInt tag), arg], [RTy.WORD32ty, ty])
                    | _ => raise bug "RTy.LAYOUT_TAGGED RTy.TAGGED_OR_NULL"
                  end
              | RTy.LAYOUT_TAGGED (RTy.TAGGED_TAGONLY {tagMap}) =>
                (case SEnv.find (tagMap, con) of
                   SOME tag => toMLValue (R.WORD32 (Word32.fromInt tag),RTy.WORD32ty)
                 | NONE => raise bug "RTy.LAYOUT_TAGGED RTy.TAGGED_ONLY"
                )
              | RTy.LAYOUT_ARG_OR_NULL {wrap=false} =>
                (case (termopt, SEnv.find (conSet, con)) of
                   (NONE, SOME NONE) => toMLValue (nullTerm, nullTy)
                 | (SOME arg, SOME (SOME argTy)) =>
                   toMLValue (arg, argTy)
                 | _ => raise Bug.Bug "RTy.LAYOUT_ARG_OR_NULL {wrap=false}"
                )
              | RTy.LAYOUT_ARG_OR_NULL {wrap=true} =>
                (case (termopt, SEnv.find (conSet, con)) of
                   (NONE, SOME NONE) => 
                   toMLValue (nullTerm, nullTy)
                 | (SOME arg, SOME (SOME argTy)) =>
                   makeRecord ([arg], [argTy])
                 | _ => raise Bug.Bug "Rty.LAYOUT_ARG_OR_NULL {wrap=true}"
                )
              | RTy.LAYOUT_SINGLE_ARG {wrap=false} =>
                (case (termopt, SEnv.find (conSet, con)) of
                   (SOME arg, SOME (SOME argTy)) =>
                   toMLValue (arg, argTy)
                 | _ => raise Bug.Bug "RTy.LAYOUT_SINGLE_ARG {wrap=false}"
                )
              | RTy.LAYOUT_SINGLE_ARG {wrap=true} =>
                (case (termopt, SEnv.find (conSet, con)) of
                   (SOME arg, SOME (SOME argTy)) =>
                   makeRecord ([arg], [argTy])
                 | _ => raise Bug.Bug "RTy.LAYOUT_SINGLE_ARG {wrap=true}"
                )
              | RTy.LAYOUT_CHOICE {falseName} =>
                toMLValue (R.WORD32 (if con = falseName then 0w0 else 0w1), RTy.WORD32ty)
              | RTy.LAYOUT_SINGLE =>
                toMLValue (R.WORD32 0w0, RTy.WORD32ty)
        
          and toMLList (l, elemTy) =
              let
                (* LAYOUT_ARG_OR_NULL {wrap=false} *)
                (* transrate list to nested record *)
                val (term, reifiedTy) = 
                    List.foldr
                      (fn (rt, (nextTerm, nextTy)) => 
                          (R.RECORD (RecordLabel.tupleMap [rt, nextTerm]),
                           RTy.RECORDty  (RecordLabel.tupleMap [elemTy, nextTy])))
                      (nullTerm, nullTy)
                      l
              in
                toMLValue (term, reifiedTy)
              end
              
          and toMLOption (rtopt, ty1, ty2) = 
              if ReifiedTy.reifiedTyEq(ty1, ty2) then 
                case rtopt of 
                  NONE => toMLValue (nullTerm,  nullTy)
                | SOME rt => 
                  (* LAYOUT_ARG_OR_NULL {wrap=true} *)
                  toMLValue (R.RECORD (RecordLabel.tupleMap [rt]), 
                             RTy.RECORDty (RecordLabel.Map.singleton (RecordLabel.fromInt 1,ty2)))
              else 
                (print "case option\n";
                 print (RTy.reifiedTyToString reifiedTy);
                 print "\n";
                 print (R.reifiedTermToString (R.OPTION (rtopt, ty1)));
                 print "\n";
                 raise Bug.Bug "Type of term and designated type does not match."
                )
          and toMLValue (term, reifiedTy) =
              case (term, reifiedTy) of
                (R.ARRAY (ty1, boxed), RTy.ARRAYty elemTy) => toBoxed boxed
              | (R.ARRAY_PRINT arr, RTy.ARRAYty elemTy) => raise Bug.Bug "R.ARRAY_PRINT to toML"
              | (R.BOOL b, RTy.BOOLty) => toBoxed b
              | (R.BOUNDVAR, RTy.BOUNDVARty id) => raise UnsupportedTerm term
              | (R.CHAR c, RTy.CHARty) => toBoxed c
              | (R.CODEPTR word64, RTy.CODEPTRty) => raise UnsupportedTerm term
              | (R.DATATYPE _, RTy.DATATYPEty _) =>  toMLValue (term, getConstructTy reifiedTy)
              | (R.DATATYPE d, RTy.CONSTRUCTty tyInfo) => toMLDatatype (d, tyInfo)
              | (R.DYNAMIC (_,boxed), RTy.DYNAMICty ty) => toBoxed boxed
              | (_, RTy.DYNAMICty ty) => toBoxed term
              | (R.EXNTAG, RTy.EXNTAGty) => raise UnsupportedTerm term
              | (R.EXN _, RTy.EXNty) => raise UnsupportedTerm term
              | (R.INT8 i, RTy.INT8ty) => toBoxed i
              | (R.INT16 i, RTy.INT16ty) => toBoxed i
              | (R.INT64 i, RTy.INT64ty) => toBoxed i
              | (R.INTERNAL, RTy.INTERNALty) => raise UnsupportedTerm term
              | (R.INTINF i, RTy.INTINFty) => toBoxed i
              | (R.INT32 i, RTy.INT32ty) => toBoxed i
              | (R.LIST l, RTy.LISTty elemTy) => toMLList (l, elemTy)
              | (R.NULL, _) =>  raise AttemptToConvertNullValue
              | (R.NULL_WITHTy _, _) =>  raise AttemptToConvertNullValue
              | (R.OPAQUE, RTy.OPAQUEty _) => raise UnsupportedTerm term
              | (R.OPTION (rtopt, ty1), RTy.OPTIONty ty2) => toMLOption (rtopt, ty1, ty2)
              | (R.PTR address, RTy.PTRty ty) => toBoxed address
              | (R.REAL32 r, RTy.REAL32ty) => toBoxed r
              | (R.REAL64 r, RTy.REAL64ty) => toBoxed r
              | (R.RECORDLABEL l, RTy.RECORDLABELty) => toBoxed l
              | (R.RECORD termFields, RTy.RECORDty tyFields) =>
                makeRecord (RecordLabel.Map.listItems termFields, 
                            RecordLabel.Map.listItems tyFields)
              | (R.REF (ty, boxed), RTy.REFty reifiedTy) => toBoxed boxed
              | (R.REF_PRINT term, RTy.REFty reifiedTy) => toBoxed (toMLValue (term, reifiedTy))
              | (R.STRING s, RTy.STRINGty) => toBoxed s
              | (_, RTy.VOIDty) => toBoxed (0w0)
              | (R.VOID, _) =>  raise AttemptToConvertVoidValue
              | (R.VOID_WITHTy _, _) =>  raise AttemptToConvertVoidValue
              | (R.UNIT, RTy.UNITty) => toBoxed (0w0 : Word32.word)
              | (R.VECTOR (ty, boxed), RTy.VECTORty elemTy) => toBoxed boxed
              | (R.VECTOR_PRINT v, RTy.VECTORty elemTy) => raise bug "R.VECTOR_PRINT to toMLValue"
              | (R.WORD64 w, RTy.WORD64ty) => toBoxed w
              | (R.WORD8 w, RTy.WORD8ty) => toBoxed w
              | (R.WORD16 w, RTy.WORD16ty) => toBoxed w
              | (R.WORD32 w, RTy.WORD32ty) => toBoxed w
              | (R.BUILTIN, _) => raise UnsupportedTerm term
              | (R.FUN {closure=f, ty=ty}, specTy as RTy.FUNMty _) => 
                if RTy.reifiedTyEq (ty, specTy) then toBoxed f
                else 
                  (print "case of FUN\n";
                   print (RTy.reifiedTyToString ty);
                   print "\n";
                   print (RTy.reifiedTyToString specTy);
                   print "\n";
                   raise Bug.Bug "Type of term and designated type does not match."
                  )
              | (R.UNPRINTABLE, _) => raise UnsupportedTerm term
              | _ => 
                (print "case others\n";
                 print (RTy.reifiedTyToString reifiedTy);
                 print "\n";
                 print (R.reifiedTermToString term);
                 print "\n";
                 raise Bug.Bug "Type of term and designated type does not match."
                )
        in
          toMLValue (reifiedTerm, reifiedTy)
        end
    
    fun ('a#reify) reifiedTermToML reifiedTerm : 'a =
        (
         RuntimeTypes.init 
           {pointerSize =
            (Word.toInt (SMLSharp_Builtin.Dynamic.sizeToWord _sizeof(boxed)))
           };
         fromBoxed (toML (reifiedTerm, _reifyTy('a)))
        )

    fun ('a#reify) reifiedTermToMLWithTy reifiedTerm tyRep : 'a =
        (
         RuntimeTypes.init 
           {pointerSize =
            (Word.toInt (SMLSharp_Builtin.Dynamic.sizeToWord _sizeof(boxed)))
           };
         fromBoxed (toML (reifiedTerm, tyRep))
        )

  end (* local *)
end (* struct *)
