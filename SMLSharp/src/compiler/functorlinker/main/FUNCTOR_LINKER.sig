signature FUNCTOR_LINKER = sig
  type functorEnv
  val initialFunctorEnv : functorEnv
  val pu_functorEnv : MultipleValueCalc.mvdecl list SEnv.map Pickle.pu
  val link : 
    MultipleValueCalc.mvdecl list SEnv.map
    -> MultipleValueCalc.topBlock list
       -> MultipleValueCalc.mvdecl list SEnv.map 
          * MultipleValueCalc.mvdecl list
end 
