(**
 * LinkageUnitPickler
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: LinkageUnitPickler.sml,v 1.1 2006/03/02 12:46:18 bochao Exp $
 *)
structure LinkageUnitPickler =
struct
      
   structure P = Pickle
   val linkageUnit : LinkageUnit.linkageUnit P.pu =
       P.conv
           ((fn (fileName, staticTypeEnv, staticModuleEnv, code) =>
                {fileName = fileName,
                 staticTypeEnv = staticTypeEnv, 
                 staticModuleEnv = staticModuleEnv, 
                 code = code}),
            (fn {fileName, staticTypeEnv, staticModuleEnv, code} =>
                (fileName, staticTypeEnv, staticModuleEnv,code)))
           (P.tuple4(P.string, 
                     TypeContextPickler.staticTypeEnv, 
                     ModuleCompilationPickler.staticModuleEnv, 
                     (P.list TypedLambdaPickler.tldecl)))
end
           