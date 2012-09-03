signature MODULE_COMPILER = sig
  val compile : 
      NameMap.topNameMap
        -> PatternCalc.pltopdec list
           -> NameMap.currentNameMap * 
              PatternCalcFlattened.plftopdec list
end
