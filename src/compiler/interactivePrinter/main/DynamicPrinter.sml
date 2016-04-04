(**
 * DynamicPrinter
 * @copyright (c) 2015 Tohoku University.
 * @author UENO Katsuhiro
 *)

structure DynamicPrinter =
struct

  structure D = Dynamic
  structure R = ReifiedTerm

  fun isTupleFields fields =
      let
        fun check i nil = true
          | check i ((l,_)::t) = Int.toString i = l andalso check (i+1) t
      in
        check 1 fields
      end

  fun formatDyn depth dyn =
      formatValue depth (Dynamic.read dyn)

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
        if isTupleFields fields
        then R.TUPLEtyRep (map (fn (_,v) => formatDyn (depth+1) v) fields)
        else R.RECORDtyRep (map (fn (l,v) => (l, formatDyn (depth+1) v)) fields)
      | D.ARRAY {length, sub} =>
        R.ARRAYtyRep
          (R.UNPRINTABLERep,
           fn len => (List.tabulate (Int.min (len, length),
                                     fn i => formatDyn (depth + 1) (sub i)),
                      len < length))
      | D.VECTOR {length, sub} =>
        R.VECTORtyRep
          (R.UNPRINTABLERep,
           fn len => (List.tabulate (Int.min (len, length),
                                     fn i => formatDyn (depth + 1) (sub i)),
                      len < length))
      | D.LIST l =>
        R.LISTtyRep (map (formatDyn (depth + 1)) (Dynamic.readList l))
      | D.REF v =>
        R.DATATYPEtyRepWITHARG ("ref", formatValue depth v)
      | D.VARIANT (conName, NONE) =>
        R.DATATYPEtyRepNOARG conName
      | D.VARIANT (conName, SOME arg) =>
        R.DATATYPEtyRepWITHARG (conName, formatValue depth arg)

  fun dynToReifiedTerm dyn =
      formatDyn 1 dyn

  fun format dyn =
      ReifiedTerm.format_reifiedTerm (dynToReifiedTerm dyn)

  fun prettyPrint dyn =
      print (SMLFormat.prettyPrint [SMLFormat.Columns 80] (format dyn))

end
