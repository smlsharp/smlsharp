signature MODULE_COMPILER = sig
  val compile : 
    NameMap.topNameMap
      -> VarNameID.id
             -> PatternCalc.pltopdec list
                -> NameMap.currentNameMap * VarNameID.id * 
                   PatternCalcFlattened.plftopdec list
end
