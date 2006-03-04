(**
 * @copyright (c) 2006, Tohoku University.
 *)
structure TypeContextPickler
          : sig
              val topTypeContext : InitialTypeContext.topTypeContext Pickle.pu
              val typeEnv : TypeContext.typeEnv Pickle.pu
              val staticTypeEnv : TypeContext.staticTypeEnv Pickle.pu
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

  val typeEnv =
      P.conv
      ((fn (tyConSizeTagEnv, varEnv, strSizeTagEnv) =>
           {tyConSizeTagEnv = tyConSizeTagEnv, 
            varEnv = varEnv,
            strSizeTagEnv = strSizeTagEnv}),
       (fn {tyConSizeTagEnv, varEnv, strSizeTagEnv} =>
           (tyConSizeTagEnv, varEnv, strSizeTagEnv)))
      (P.tuple3
         (TypesPickler.tyConSizeTagEnv, TypesPickler.varEnv, TypesPickler.strSizeTagEnv))

  val staticTypeEnv = 
      P.conv
          ((fn (importTyConIdSet, importTypeEnv, exportTypeEnv) =>
               {importTyConIdSet = importTyConIdSet, 
                importTypeEnv = importTypeEnv,
                exportTypeEnv = exportTypeEnv}),
           (fn {importTyConIdSet, importTypeEnv, exportTypeEnv} =>
               (importTyConIdSet, importTypeEnv, exportTypeEnv)))
          (P.tuple3
               (TypesPickler.tyConIdSet, typeEnv, typeEnv))

end
