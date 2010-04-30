structure FunIDMapData = struct
local
  structure AT = AnnotatedTypes
  type funStatus  = AT.funStatus

  structure funStatusOrd : ordsig = 
    struct
      type ord_key = funStatus
      val compare =
        fn (
	    {
             functionId = fid1,
             ...
             }, 
	    {
             functionId = fid2,
             ...
             } : funStatus
	    ) => Int.compare(fid1,fid2)
    end
  structure FidSet = BinarySetFn(funStatusOrd) 
  structure FidEnv = BinaryMapFn(funStatusOrd)

  fun formatFidSet (separator, prefix, suffix) Fidset = 
    let 
      val L = 
        map 
        (fn ({codeStatus = ref AT.CLOSURE, functionId = fid, ...} : AT.funStatus)
            => " cls(" ^  Int.toString fid ^ ")"
          | {codeStatus = ref AT.LOCAL, functionId = fid, ...}
            => "code(" ^  Int.toString fid ^ ")"
         ) 
        (FidSet.listItems Fidset)
    in
      prefix @
      (SMLFormat.BasicFormatters.format_list
       (SMLFormat.BasicFormatters.format_string,
        separator) L) 
      @ suffix
    end

  fun formatFidMap (elementFormatter, bindsep, itemsepRecord) fmap =
    let
      val L = 
        map 
        (fn ({codeStatus = ref AT.CLOSURE, functionId = fid, ...} : AT.funStatus, s) 
            => (" cls(" ^  Int.toString fid ^ ")", s)
          | ({codeStatus = ref AT.LOCAL, functionId = fid, ...}, s) 
            => ("code(" ^  Int.toString fid ^ ")", s)
         )
        (FidEnv.listItemsi fmap)
    in
      SmlppgUtil.format_record(elementFormatter, bindsep, itemsepRecord) L
    end

in

  (*%
   * @formatter(formatFidMap) formatFidMap
   * @formatter(formatFidSet) formatFidSet
   *)
  type funIdMap =  
    (*%
     * @format(set:formatFidSet map:formatFidMap) map(set()(","+1, "{", "}"))(+"->"+, ","+2)
     *)
    FidSet.set FidEnv.map

  val gotoMap = ref FidEnv.empty : funIdMap ref
  val callMap = ref FidEnv.empty : funIdMap ref

end
end
