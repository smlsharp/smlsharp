signature FUNCTOR_LINKER = sig
  type functorEnv
  val initialFunctorEnv : functorEnv
  val pu_functorEnv : MultipleValueCalc.mvdecl list SEnv.map Pickle.pu
  val link : 
    MultipleValueCalc.mvdecl list SEnv.map
    -> Counters.stamp
       -> MultipleValueCalc.topBlock list
          -> MultipleValueCalc.mvdecl list SEnv.map 
             * Counters.stamp
             * MultipleValueCalc.mvdecl list
end 
