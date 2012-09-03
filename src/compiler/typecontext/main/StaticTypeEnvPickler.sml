(**
 * 
 * @author Liu Bochao
 * @version $Id: StaticTypeEnvPickler.sml,v 1.3 2006/06/17 07:36:14 bochao Exp $
 * @copyright (c) 2006, Tohoku University.
 *)
structure StaticTypeEnvPickler 
          : sig
              val typeEnv : StaticTypeEnv.typeEnv Pickle.pu
              val staticTypeEnv : StaticTypeEnv.staticTypeEnv Pickle.pu
            end =
struct

  structure P = Pickle

  val typeEnv =
      P.conv
      ((fn (tyConEnv, varEnv, strEnv) =>
           {tyConEnv = tyConEnv, 
            varEnv = varEnv,
            strEnv = strEnv}),
       (fn {tyConEnv, varEnv, strEnv} =>
           (tyConEnv, varEnv, strEnv)))
      (P.tuple3
         (TypesPickler.tyConEnv, TypesPickler.varEnv, TypesPickler.strEnv))

  val staticTypeEnv = 
      P.conv
          ((fn (importTyConIdSet, importTypeEnv, exportTypeEnv, generativeExnTagSet) =>
               {importTyConIdSet = importTyConIdSet, 
                importTypeEnv = importTypeEnv,
                exportTypeEnv = exportTypeEnv,
                generativeExnTagSet = generativeExnTagSet}),
           (fn {importTyConIdSet, importTypeEnv, exportTypeEnv, generativeExnTagSet} =>
               (importTyConIdSet, importTypeEnv, exportTypeEnv, generativeExnTagSet)))
          (P.tuple4
               (TypesPickler.tyConIdSet, typeEnv, typeEnv, TypesPickler.exnTagSet))

end
