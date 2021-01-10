structure PrintUtils =
struct
local
  structure B = BuiltinPrimitive
  structure I = IDCalc
  fun sname envList =
      {env = envList,
       tfunName = NameEvalUtils.staticTfunName,
       tyConName = NameEvalUtils.staticTyConName}
in
  fun primitiveToString p = 
      Bug.prettyPrint (B.format_primitive p)
  fun tyToString envlist ty =
      Bug.prettyPrint (I.print_ty (sname envlist, nil,nil) ty)
end
end
