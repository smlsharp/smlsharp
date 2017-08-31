(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
signature NAME_EVAL_ENV =
sig

  datatype tstr 
    =  TSTR of IDCalc.tfun
    |  TSTR_DTY of {tfun:IDCalc.tfun, varE:IDCalc.varE, formals:IDCalc.formals, conSpec:IDCalc.conSpec}
  type tyE
  type strEntryWithSymbol
  type strEntry
  datatype strKind 
    = SIGENV 
    | STRENV of StructureID.id
    | FUNAPP of {id:StructureID.id, funId:FunctorID.id, argId:StructureID.id}

  datatype strE
    = STR of strEntryWithSymbol SEnv.map
  and env
    = ENV of {varE: IDCalc.varE, tyE: tyE, strE: strE}
  type funEEntryWithSymbol
  type funEEntry
  type funE
  type sigE
  type sigEEntry
  type sigEList
  type topEnv

  val format_tstr : tstr -> SMLFormat.FormatExpression.expression list
  val format_tyE : tyE -> SMLFormat.FormatExpression.expression list
  val format_strE : strE -> SMLFormat.FormatExpression.expression list
  val format_env : env -> TermFormat.format
  val printTy_env : env -> TermFormat.format
  val printTy_sigE : sigE -> TermFormat.format
  val printTy_sigEList : sigEList -> TermFormat.format
  val format_strEntryWithSymbol : strEntryWithSymbol -> TermFormat.format
  val format_funEEntry : funEEntry -> SMLFormat.FormatExpression.expression list
  val printTy_funEEntry : funEEntry -> SMLFormat.FormatExpression.expression list
  val format_funE : funE -> SMLFormat.FormatExpression.expression list
  val format_sigE : sigE -> SMLFormat.FormatExpression.expression list
  val format_topEnv : topEnv -> SMLFormat.FormatExpression.expression list
  val tstrFormals : tstr -> IDCalc.formals
  val tstrLiftedTys : tstr -> IDCalc.liftedTys
  val tstrArity : tstr -> int
  val tstrToString : tstr -> string
  val tyEToString : tyE -> string
  val envToString : env -> string
  val topEnvToString : topEnv -> string
  val funEToString : funE -> string

  exception LookupTstr
  exception LookupId
  exception LookupStr

  val emptyTyE : tyE
  val emptyEnv : env
  val emptyTopEnv : topEnv

  val findTstr : env * string list -> tstr option
  val lookupTstr : env -> string list -> tstr
  val findId : env * string list -> IDCalc.idstatus option
  val lookupId : env -> string list -> IDCalc.idstatus
  val findStr : env * Symbol.longsymbol -> strEntryWithSymbol option
  val lookupStr : env -> Symbol.longsymbol -> strEntryWithSymbol
  val rebindIdLongid : env * string list * IDCalc.idstatus -> env
  val rebindTstr : env * string * tstr -> env
  val rebindTstrLongid : env * string list * tstr -> env
  val rebindId : env * string * IDCalc.idstatus -> env
  val bindStr : Loc.loc -> env * Symbol.symbol * strEntry -> env
  val rebindStr : env * Symbol.symbol * strEntry -> env
  val singletonStr : Symbol.symbol * strEntry -> env
  val varEWithVarE : IDCalc.varE * IDCalc.varE -> IDCalc.varE
  val tyEWithTyE : tyE * tyE -> tyE
  val strEWithStrE : strE * strE -> strE
  val envWithVarE : env * IDCalc.varE -> env
  val envWithEnv : env * env -> env
  val updateStrE : strE * strE -> strE
  val updateEnv : env * env -> env
  val unionVarE : string -> Loc.loc -> IDCalc.varE * IDCalc.varE -> IDCalc.varE
  val unionTyE : string -> Loc.loc -> tyE * tyE -> tyE
  val unionStrE : string -> Loc.loc -> strE * strE -> strE
  val unionEnv : string -> Loc.loc -> env * env -> env
  val bindId : Loc.loc -> env * string * IDCalc.idstatus -> env
  val bindTstr : Loc.loc -> env * string * tstr -> env
  val sigEWithSigE : sigE * sigE -> sigE
  val funEWithFunE : funE * funE -> funE
  val unionSigE : string -> Loc.loc -> sigE * sigE -> sigE
  val unionFunE : string -> Loc.loc -> funE * funE -> funE
  val topEnvWithSigE : topEnv * sigE -> topEnv
  val topEnvWithFunE : topEnv * funE -> topEnv
  val topEnvWithEnv : topEnv * env -> topEnv
  val topEnvWithTopEnv : topEnv * topEnv -> topEnv
  val unionTopEnv : string -> Loc.loc -> topEnv * topEnv -> topEnv

end
