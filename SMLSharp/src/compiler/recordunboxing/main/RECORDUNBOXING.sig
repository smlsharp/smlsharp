signature RECORDUNBOXING = sig

    val transform : 
      Counters.stamp
      -> AnnotatedCalc.topBlock list
         -> Counters.stamp * MultipleValueCalc.topBlock list

end
