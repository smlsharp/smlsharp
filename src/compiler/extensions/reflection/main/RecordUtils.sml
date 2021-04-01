(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure RecordUtils =
struct
local
  structure RTy = ReifiedTy
  structure R = ReifiedTerm
  fun dynamic x = ReifiedTerm.toDynamic (ReifyTerm.toReifiedTerm x)
  fun dynamicToTerm dyn = ReifiedTerm.toReifiedTerm dyn 
  fun eqBaseTerm (t1, t2) =
      case (t1, t2) of
        (R.BOOL x1, R.BOOL x2) => x1 = x2
      | (R.CHAR x1, R.CHAR x2) => x1 = x2
      | (R.INT32 x1, R.INT32 x2) =>  x1 = x2
      | (R.INT16 x1, R.INT16 x2) =>  x1 = x2
      | (R.INT64 x1, R.INT64 x2) =>  x1 = x2
      | (R.INT8 x1, R.INT8 x2) =>  x1 = x2
      | (R.REAL64 x1, R.REAL64 x2) => Real64.== (x1,x2)
      | (R.REAL32 x1, R.REAL32 x2) => Real32.== (x1,x2)
      | (R.STRING x1, R.STRING x2) => x1 = x2
      | (R.UNIT, R.UNIT) => true
      | (R.WORD32 x1, R.WORD32 x2) => x1 = x2
      | (R.WORD16 x1, R.WORD16 x2) => x1 = x2
      | (R.WORD64 x1, R.WORD64 x2) => x1 = x2
      | (R.WORD8 x1, R.WORD8 x2) => x1 = x2
      |  _ => false
  exception RuntimeTypeError = PartialDynamic.RuntimeTypeError
in
  fun ('term#reify#{}, 'ty#reify#{}) project (record:'term) : 'ty =
    let
      val tyTyRep = _reifyTy('ty)
      val tyTy = #reifiedTy tyTyRep
      val termTyRep = _reifyTy('term)
      val termTy = #reifiedTy termTyRep
      val (termTyFields, tyTyFields) =
          case (termTy, tyTy) of
            (RTy.RECORDty termTyFields, RTy.RECORDty tyTyFields) =>
            (termTyFields, tyTyFields)
          | _ => raise RuntimeTypeError
      val _ =
          RecordLabel.Map.appi
            (fn (l,tyTy) =>
                case RecordLabel.Map.find(termTyFields, l) of
                  SOME termTy => if RTy.reifiedTyEq (termTy, tyTy) 
                                 then ()
                                 else raise RuntimeTypeError
                | NONE => raise RuntimeTypeError)
            tyTyFields
      val term = dynamicToTerm (dynamic record)
      val projectedRecord =
          case term of 
            R.RECORD fields =>
            R.RECORD
              (RecordLabel.Map.intersectWith
                 (fn (a,b) => a)
                 (fields, tyTyFields)
              )
          | _ => raise RuntimeTypeError
    in
      ReifiedTermToML.reifiedTermToMLWithTy projectedRecord tyTyRep : 'ty
    end
  fun ('rel#reify, 'nestedRel#reify) nest (R:'rel) : 'nestedRel =
    let
      val relTyRep = _reifyTy('rel)
      val relTy = #reifiedTy relTyRep
      val nestedRelTyRep = _reifyTy('nestedRel)
      val nestedRelTy = #reifiedTy nestedRelTyRep
      val (relTyFields, nestedRelTyFields) =
          case (relTy, nestedRelTy) of
            (RTy.LISTty (RTy.RECORDty relTyFields),
             RTy.LISTty (RTy.RECORDty nestedRelTyFields))
            => (relTyFields, nestedRelTyFields)
          | _ => raise RuntimeTypeError
      val (flatFields, labelNestedFieldsOpt) =
          RecordLabel.Map.foldli
          (fn (l, RTy.LISTty elemTy, (flatFields, NONE)) =>
              (case elemTy of
                (RTy.RECORDty nestFileds) =>
                (RecordLabel.Map.app
                   (fn ty => if not (RTy.isBaseTy ty) then
                               raise RuntimeTypeError
                             else ())
                   nestFileds;
                 (flatFields, SOME (l, nestFileds))
                 )
              | _ => raise RuntimeTypeError
              )
            | (l, ty, (flatFields, labelNestedFieldsOpt)) =>
              (if not (RTy.isBaseTy ty) then 
                 raise RuntimeTypeError
               else ();
               (RecordLabel.Map.insert(flatFields, l, ty),
                labelNestedFieldsOpt)
              )
          )
          (RecordLabel.Map.empty, NONE)
          nestedRelTyFields
      val (label, nestedField) = 
          case labelNestedFieldsOpt of
            SOME (label, nestedField) => (label, nestedField)
          | _ => raise RuntimeTypeError
      val term = dynamicToTerm (dynamic R)
      val recordTupleList = case term of
                              R.LIST recordTupleList => recordTupleList
                            | _ => raise RuntimeTypeError
      fun flatField tuple = 
          RecordLabel.Map.intersectWith #1 (tuple, flatFields)
      fun nestField tuple = 
          RecordLabel.Map.intersectWith #1 (tuple, nestedField)
      fun folder (R.RECORD tuple, 
                  (NONE, nestTermListRev, nestedRecordListRev)) =
          let
            val currentFlatTerm = R.RECORD (flatField tuple)
            val currentNestTerm = R.RECORD (nestField tuple)
          in
            (SOME currentFlatTerm, currentNestTerm::nestTermListRev, 
             nestedRecordListRev)
          end
        | folder (R.RECORD tuple, 
                  (SOME (currentFlatTerm as R.RECORD currentFlatField), 
                          nestTermListRev, nestedRecordListRev)) =
          let
            val newFlatField = flatField tuple
            val newNestField = nestField tuple
          in
            if RecordLabel.Map.eq 
                 eqBaseTerm
                 (currentFlatField, newFlatField) then
              (SOME (R.RECORD currentFlatField), 
               R.RECORD newNestField::nestTermListRev, nestedRecordListRev)
            else
              let
                val nestedRecordItem = 
                    R.RECORD 
                      (RecordLabel.Map.insert
                         (currentFlatField, label, 
                          R.LIST (rev nestTermListRev)))
              in
                (SOME (R.RECORD newFlatField), 
                 [R.RECORD newNestField], 
                 nestedRecordItem::nestedRecordListRev)
              end
          end
        | folder _ = raise RuntimeTypeError
      val (flatTerm, nestTermListRev, nestedRecordListRev) =
          foldl folder (NONE, nil, nil) recordTupleList
      val nestTermListRev =
          case flatTerm of
            SOME (R.RECORD flatField) => 
            R.RECORD (RecordLabel.Map.insert
                        (flatField, label, R.LIST (rev nestTermListRev)))
            :: nestedRecordListRev
          | SOME _ => raise RuntimeTypeError
          | NONE => nestedRecordListRev
      val nestedTerm = R.LIST (rev nestTermListRev)
    in
      ReifiedTermToML.reifiedTermToMLWithTy nestedTerm nestedRelTyRep 
      : 'nestedRel
    end
end
end
