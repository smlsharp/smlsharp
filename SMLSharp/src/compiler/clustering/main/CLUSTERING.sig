signature CLUSTERING = sig

  val transform : Counters.stamp -> MultipleValueCalc.mvdecl list -> 
                  (Counters.stamp * ClusterCalc.ccdecl list)

end
