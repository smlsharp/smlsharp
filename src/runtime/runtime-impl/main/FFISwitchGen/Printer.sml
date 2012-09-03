structure PrintFFISwitch = struct

  val printWidth = ref 80
  fun prettyPrint expressions =
      let
        val ppgenParameter = [SMLFormat.Columns (!printWidth)]
      in
        SMLFormat.prettyPrint ppgenParameter expressions
      end

    fun caseTagToString x = 
      prettyPrint (FFIGenItem.format_caseTag x)

    fun funBodyToString x = 
      prettyPrint (FFIGenItem.format_funBody x)

    fun breakToString x = 
      prettyPrint (FFIGenItem.format_break x)

    fun returnToString x = 
      prettyPrint (FFIGenItem.format_return x)

    fun resultTypeToString x = 
      prettyPrint (FFIGenItem.format_resultTy  x)

    fun argTyToString x = 
      prettyPrint (FFIGenItem.format_argTy x)

    fun funBodyToString x =
      prettyPrint (FFIGenItem.format_funBody x)

    fun funArgsToString x =
      prettyPrint (FFIGenItem.format_funArgs x)

    fun returnStatementToString x =
      prettyPrint (FFIGenItem.format_returnStatement x)

    fun ffiEntryToString x =
      prettyPrint (FFIGenItem.format_ffiEntry x)

    fun ffiSwitchFuncToString x =
      prettyPrint (FFIGenItem.format_ffiSwitchFunc x)

end
