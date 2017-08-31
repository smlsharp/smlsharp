(**
 * DynamicPrinter
 * @copyright (c) 2015 Tohoku University.
 * @author UENO Katsuhiro
 *)

structure DynamicPrinter =
struct

  structure D = Dynamic
  structure R = ReifiedTerm

  fun formatDyn depth dynamic =
      formatValue depth (Dynamic.read dynamic)

  and formatValue depth value = 
      raise Bug.Bug "function \"DynamicPrinter.formatValue\" called."
(*
     (case value of
        D.INT8 n => R.INT8tyRep n
      | D.INT16 n => R.INT16tyRep n
      | D.INT32 n => R.INT32tyRep n
      | D.INT64 n => R.INT64tyRep n
      | D.WORD8 n => R.WORD8tyRep n
      | D.WORD16 n => R.WORD16tyRep n
      | D.WORD32 n => R.WORD32tyRep n
      | D.WORD64 n => R.WORD64tyRep n
      | D.REAL64 r => R.REAL64tyRep r
      | D.REAL32 r => R.REAL32tyRep r
      | D.INTINF n => R.INTINFtyRep n
      | D.STRING s => R.STRINGtyRep s
      | D.EXN e => R.EXNtyRep
      | D.UNIT => R.UNITtyRep
      | D.FUN => R.FUNtyRep
      | D.OTHER => R.UNPRINTABLERep
      | D.OPAQUE _ => R.UNPRINTABLERep
      | D.CHAR c => R.CHARtyRep c
      | D.PTR p => R.PTRtyRep
      | D.RECORD fields =>
        if RecordLabel.isTupleList fields
        then R.TUPLE (map (fn (_,v) => formatDyn (depth+1) v) fields)
        else R.RECORD (map (fn (l,v) => (RecordLabel.toString l, formatDyn (depth+1) v)) fields)
      | D.ARRAY {length, sub} =>
        R.ARRAY
          {dummyPrinter = R.UNPRINTABLE,
           contentsFn = 
            fn SOME len => {contents = List.tabulate 
                                        (Int.min (len, length),
                                      fn i => formatDyn (depth + 1) (sub i)),
                           hasEllipsis=len < length}
             | NONE => {contents = List.tabulate (length, fn i => formatDyn (depth + 1) (sub i)),
                       hasEllipsis = false}
          }
      | D.VECTOR {length, sub} =>
        R.VECTOR
          {dummyPrinter = R.UNPRINTABLE,
           contentsFn =
             fn SOME len => {contents = List.tabulate
                                        (Int.min (len, length),
                                      fn i => formatDyn (depth + 1) (sub i)),
                           hasEllipsis = len < length}
              | NONE => {contents = List.tabulate (length, fn i => formatDyn (depth + 1) (sub i)),
                       hasEllipsis = false}
          }
      | D.LIST l =>
        R.LIST (map (formatDyn (depth + 1)) (Dynamic.readList l))
      | D.OPTION_SOME v =>
        R.OPTIONSOME (formatValue depth v)
      | D.OPTION_NONE =>
        R.OPTIONNONE
      | D.BOOL b =>
        R.BOOL b
      | D.REF v =>
        R.DATATYPE ("ref", SOME (formatValue depth v))
      | D.VARIANT (typId, conName, arg) =>
        if TypID.eq (typId, #id (UserLevelPrimitive.JSON_dyn_tyCon())) then
          R.UNPRINTABLE
        else if TypID.eq (typId, IDCalc.tfunId (#tfun BuiltinTypes.optionTstrInfo)) then
          (case arg of
             NONE => R.OPTIONNONE
           | SOME v =>  R.OPTIONSOME (formatValue depth v))
        else
          case arg of
            NONE => R.DATATYPE (Symbol.symbolToString conName, NONE)
          | SOME arg => R.DATATYPE (Symbol.symbolToString conName,
                                         SOME (formatValue depth arg))
     )
      handle UserLevelPrimitive.IDNotFound name =>
             raise Bug.Bug ("UserlevelPrimitive Error Handling (DynamicPrinter.fromatValue):" ^ name)
*)

  fun dynamicToReifiedTerm dynamic =
      formatDyn 1 dynamic

  fun format dynamic =
      ReifiedTerm.format_reifiedTerm (dynamicToReifiedTerm dynamic)

  fun prettyPrint dynamic =
      print (SMLFormat.prettyPrint [SMLFormat.Columns 80] (format dynamic))

end
