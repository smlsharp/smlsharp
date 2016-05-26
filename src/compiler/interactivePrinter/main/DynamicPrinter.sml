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
      case value of
        D.WORD8 n => R.WORD8tyRep n
      | D.INT32 n => R.INTtyRep n
      | D.INT64 n => R.INT64tyRep n
      | D.WORD32 n => R.WORDtyRep n
      | D.WORD64 n => R.WORD64tyRep n
      | D.REAL r => R.REALtyRep r
      | D.REAL32 r => R.REAL32tyRep r
      | D.INTINF n => R.INTINFtyRep n
      | D.STRING s => R.STRINGtyRep s
      | D.EXN e => R.EXNtyRep
      | D.UNIT => R.UNITtyRep
      | D.FUN => R.FUNtyRep
      | D.OTHER => R.UNPRINTABLERep
      | D.CHAR c => R.CHARtyRep c
      | D.PTR p => R.PTRtyRep
      | D.RECORD fields =>
        if RecordLabel.isTupleList fields
        then R.TUPLEtyRep (map (fn (_,v) => formatDyn (depth+1) v) fields)
        else R.RECORDtyRep (map (fn (l,v) => (RecordLabel.toString l, formatDyn (depth+1) v)) fields)
      | D.ARRAY {length, sub} =>
        R.ARRAYtyRep
          {dummyPrinter = R.UNPRINTABLERep,
           contentsFn = 
            fn SOME len => {contents = List.tabulate 
                                        (Int.min (len, length),
                                      fn i => formatDyn (depth + 1) (sub i)),
                           hasEllipsis=len < length}
             | NONE => {contents = List.tabulate (length, fn i => formatDyn (depth + 1) (sub i)),
                       hasEllipsis = false}
          }
      | D.VECTOR {length, sub} =>
        R.VECTORtyRep
          {dummyPrinter = R.UNPRINTABLERep,
           contentsFn =
             fn SOME len => {contents = List.tabulate
                                        (Int.min (len, length),
                                      fn i => formatDyn (depth + 1) (sub i)),
                           hasEllipsis = len < length}
              | NONE => {contents = List.tabulate (length, fn i => formatDyn (depth + 1) (sub i)),
                       hasEllipsis = false}
          }
      | D.LIST l =>
        R.LISTtyRep (map (formatDyn (depth + 1)) (Dynamic.readList l))
      | D.REF v =>
        R.DATATYPEtyRep ("ref", SOME (formatValue depth v))
      | D.VARIANT (typId, conName, arg) =>
        if TypID.eq (typId, IDCalc.tfunId (JSONData.dynTfun()))
        then R.UNPRINTABLERep
        else
          case arg of
            NONE => R.DATATYPEtyRep (conName, NONE)
          | SOME arg => R.DATATYPEtyRep (conName, SOME (formatValue depth arg))

  fun dynamicToReifiedTerm dynamic =
      formatDyn 1 dynamic

  fun format dynamic =
      ReifiedTerm.format_reifiedTerm (dynamicToReifiedTerm dynamic)

  fun prettyPrint dynamic =
      print (SMLFormat.prettyPrint [SMLFormat.Columns 80] (format dynamic))

end
