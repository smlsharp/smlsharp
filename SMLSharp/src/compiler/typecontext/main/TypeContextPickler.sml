(**
 * @copyright (c) 2006, Tohoku University.
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
            fn (varEnv, tyConEnv, sigEnv, funEnv) =>
               {varEnv = varEnv, tyConEnv = tyConEnv, sigEnv = sigEnv, funEnv = funEnv},
            fn {varEnv, tyConEnv, sigEnv, funEnv} => 
               (varEnv, tyConEnv, sigEnv, funEnv)
          )
          (P.tuple4
               (TypesPickler.topVarEnv, 
                TypesPickler.topTyConEnv, 
                TypesPickler.sigEnv, 
                TypesPickler.funEnv))

  val typeEnv =
      P.conv
          ((fn (tyConEnv, varEnv) =>
               {tyConEnv = tyConEnv, 
                varEnv = varEnv}),
           (fn {tyConEnv, varEnv} =>
               (tyConEnv, varEnv)))
          (P.tuple2
               (TypesPickler.tyConEnv, TypesPickler.varEnv))

  val staticTypeEnv = 
      P.conv
          ((fn (importTyConIdSet, importTypeEnv, exportTypeEnv) =>
               {importTyConIdSet = importTyConIdSet, 
                importTypeEnv = importTypeEnv,
                exportTypeEnv = exportTypeEnv}),
           (fn {importTyConIdSet, importTypeEnv, exportTypeEnv} =>
               (importTyConIdSet, importTypeEnv, exportTypeEnv)))
          (P.tuple3
               (NamePickler.TyConIDSet, typeEnv, typeEnv))

end
