(**
 * Copyright (c) 2006, Tohoku University.
 *)
structure TypeContextPickler
          : sig
              val topTypeContext : InitialTypeContext.topTypeContext Pickle.pu
            end =
struct

  structure P = Pickle

  val topTypeContext =
      P.conv
          (
            fn (strEnv, sigEnv, funEnv) =>
               {strEnv = strEnv, sigEnv = sigEnv, funEnv = funEnv},
            fn {strEnv, sigEnv, funEnv} => (strEnv, sigEnv, funEnv)
          )
          (P.tuple3
               (TypesPickler.strEnv, TypesPickler.sigEnv, TypesPickler.funEnv))

end
