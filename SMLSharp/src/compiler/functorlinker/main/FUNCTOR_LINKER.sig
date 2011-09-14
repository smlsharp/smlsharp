signature FUNCTOR_LINKER = sig
  type functorEnv
  val initialFunctorEnv : functorEnv 
  val emptyFunctorEnv : functorEnv 
  val extendFunctorEnv : functorEnv * functorEnv -> functorEnv
  val pu_functorEnv : functorEnv Pickle.pu
  val link : 
    functorEnv
    -> MultipleValueCalc.topBlock list
       -> functorEnv
          * MultipleValueCalc.mvdecl list
end 
