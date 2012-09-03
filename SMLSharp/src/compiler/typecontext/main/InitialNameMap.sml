structure InitialNameMap =
struct
(*
   fun convertVarEnvToVarNameMap varEnv =
       SEnv.mapi (fn (name, idstate) =>
                     let
                         val namePath = (name, Path.externPath)
                     in
                         case idstate of
                             Types.VARID _ => NameMap.VARID namePath
                           | Types.CONID _ => NameMap.CONID namePath
                           | Types.EXNID _ => NameMap.EXNID namePath
                           | Types.PRIM _ =>  NameMap.VARID namePath
                           | Types.OPRIM _ => NameMap.VARID namePath
                           | Types.RECFUNID _ => NameMap.VARID namePath
                     end)
                 varEnv

   fun convertTyConEnvToTyNameMap tyConEnv =
       SEnv.mapi (fn (tyName, tyBindInfo) =>
                     let
                         val namePath = (tyName, Path.externPath)
                     in
                         case tyBindInfo of
                             Types.TYCON {datacon = varEnv,...} =>
                             NameMap.DATATY (namePath, convertVarEnvToVarNameMap (varEnv))
                           | Types.TYFUN _ =>
                             NameMap.NONDATATY namePath
                           | Types.TYSPEC _ =>
                             NameMap.NONDATATY namePath
                           | Types.TYOPAQUE _ =>
                             NameMap.NONDATATY namePath
                     end)
                 tyConEnv

   fun initialVarNameMap () = convertVarEnvToVarNameMap (InitialTypeContext.initialVarEnv ())
   val initialTyConNameMap = convertTyConEnvToTyNameMap PredefinedTypes.initialTopTyConEnv
*)
   val initialTopNameMap = 
       {
        tyNameMap = #1 (#basicNameMap BuiltinContext.builtinContext),
        varNameMap = #2 (#basicNameMap BuiltinContext.builtinContext),
        strNameMap = #3 (#basicNameMap BuiltinContext.builtinContext),
        funNameMap = SEnv.empty,
        sigNameMap = SEnv.empty
        } : NameMap.topNameMap

end
