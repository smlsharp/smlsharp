(**
 * LinkageUnitPickler
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: LinkageUnitPickler.sml,v 1.5 2006/03/25 11:34:41 bochao Exp $
 *)
structure LinkageUnitPickler =
struct
      
   structure P = Pickle
   val linkageUnit : LinkageUnit.linkageUnit P.pu =
       P.conv
           ((fn (fileName, 
                 staticTypeEnv, 
                 staticModuleEnv, 
                 hiddenValIndexList, 
                 code) =>
                {fileName = fileName,
                 staticTypeEnv = staticTypeEnv, 
                 staticModuleEnv = staticModuleEnv, 
                 hiddenValIndexList = hiddenValIndexList,
                 code = code}),
            (fn {fileName, 
                 staticTypeEnv, 
                 staticModuleEnv, 
                 hiddenValIndexList, 
                 code} =>
                (fileName, 
                 staticTypeEnv, 
                 staticModuleEnv, 
                 hiddenValIndexList, 
                 code)))
           (P.tuple5 (P.string, 
                      StaticTypeEnvPickler.staticTypeEnv, 
                      ModuleCompilationPickler.staticModuleEnv, 
                      (P.list (ModuleCompilationPickler.pathVar_globalIndex_ty)),
                      (P.list TypedLambdaPickler.tldecl)))
end
           