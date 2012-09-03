signature RBUTRANSFORMATION = sig

    val transform : Counters.stamp -> 
                    (ClusterCalc.ccdecl list) -> 
                    (Counters.stamp * (RBUCalc.rbudecl list))

end
