signature ANORMALIZATION = sig

  val normalize : Counters.stamp -> 
                  (RBUCalc.rbudecl list) -> 
                  (Counters.stamp * (ANormal.andecl list))

end
