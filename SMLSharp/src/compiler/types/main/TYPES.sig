(**
 * type structures.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 *)
signature TYPES =
sig

  type lambdaDepth
  val infiniteDepth : lambdaDepth
  val toplevelDepth : lambdaDepth
  val youngerDepth : {contextDepth: lambdaDepth, tyvarDepth: lambdaDepth}
                     -> bool
  val strictlyYoungerDepth : lambdaDepth * lambdaDepth -> bool

  type tyConID
  type exnTagID
  type dummyTyID
  type freeTypeVarID
  type boundTypeVarID
  datatype eqKind = EQ | NONEQ
  type tyCon
  type tvKind
  type btvKind
  type btvEnv
  type operator

  val format_dummyTyID
      : dummyTyID -> SMLFormat.FormatExpression.expression list
  val format_tyCon
      : tyCon -> SMLFormat.FormatExpression.expression list
  val format_eqKind
      : SMLFormat.FormatExpression.expression list
        -> eqKind -> SMLFormat.FormatExpression.expression list

  datatype recordKind =
      OCONSTkind of ty list
    | OPRIMkind of {instances : ty list, operators : operator list}
    | UNIV
    | REC of ty SEnv.map
  and tvState =
      TVAR of tvKind
    | SUBSTITUTED of ty
  and ty =
      INSTCODEty of operator
    | ERRORty
    | DUMMYty of dummyTyID
    | TYVARty of tvState ref
    | BOUNDVARty of boundTypeVarID
    | FUNMty of ty list * ty
    | RECORDty of ty SEnv.map
    | RAWty of {tyCon : tyCon, args : ty list}
    | POLYty of {boundtvars : btvEnv, body : ty}
    | ALIASty of ty * ty
    | OPAQUEty of {spec : {tyCon : tyCon, args : ty list}, implTy: ty}
    | SPECty of {tyCon : tyCon, args : ty list}

  type formatBtvEnv

  val format_ty
      : formatBtvEnv -> ty -> SMLFormat.FormatExpression.expression list
  val format_btvEnv
      : formatBtvEnv -> btvEnv -> SMLFormat.FormatExpression.expression list

  type varPathInfo
  type primInfo
  type oprimInfo
  type conPathInfo
  type exnPathInfo

  datatype idState =
      VARID of varPathInfo
    | CONID of conPathInfo
    | EXNID of exnPathInfo
    | PRIM of primInfo
    | OPRIM of oprimInfo
    | RECFUNID of varPathInfo * int

  val format_varPathInfo
      : formatBtvEnv -> varPathInfo
        -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_varPathInfo
      : varPathInfo -> SMLFormat.FormatExpression.expression list
  val format_primInfo
      : formatBtvEnv -> primInfo -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_primInfo
      : primInfo -> SMLFormat.FormatExpression.expression list
  val format_oprimInfo
      : formatBtvEnv -> oprimInfo -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_oprimInfo
      : oprimInfo -> SMLFormat.FormatExpression.expression list
  val format_conPathInfo
      : formatBtvEnv -> conPathInfo
        -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_conPathInfo
      : conPathInfo -> SMLFormat.FormatExpression.expression list
  val format_exnPathInfo
      : formatBtvEnv -> exnPathInfo
        -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_exnPathInfo
      : exnPathInfo -> SMLFormat.FormatExpression.expression list
  val format_idState
      : formatBtvEnv -> idState -> SMLFormat.FormatExpression.expression list

  type dataTyInfo
  type tyFun
  datatype tyBindInfo =
      TYCON of dataTyInfo
    | TYFUN of tyFun
    | TYSPEC of tyCon
    | TYOPAQUE of {spec: tyCon, impl: tyBindInfo}

  val format_dataTyInfo
      : formatBtvEnv -> dataTyInfo
        -> SMLFormat.FormatExpression.expression list
  val format_tyBindInfo
      : formatBtvEnv -> tyBindInfo
        -> SMLFormat.FormatExpression.expression list

  type tyConEnv
  type topTyConEnv
  type utvEnv
  type varEnv
  type topVarEnv
  type Env
  type topEnv

  val format_tyConEnv
      : formatBtvEnv -> tyConEnv -> SMLFormat.FormatExpression.expression list
  val format_topTyConEnv
      : formatBtvEnv -> topTyConEnv
        -> SMLFormat.FormatExpression.expression list
  val format_utvEnv
      : formatBtvEnv -> utvEnv -> SMLFormat.FormatExpression.expression list
  val format_varEnv
      : formatBtvEnv -> varEnv -> SMLFormat.FormatExpression.expression list
  val format_topVarEnv
      : formatBtvEnv -> topVarEnv -> SMLFormat.FormatExpression.expression list
  val format_Env
      : formatBtvEnv -> Env -> SMLFormat.FormatExpression.expression list
  val format_topEnv
      : formatBtvEnv -> topEnv -> SMLFormat.FormatExpression.expression list

  datatype varId =
      EXTERNAL of ExVarID.id
    | INTERNAL of VarID.id

  type varIdInfo

  datatype valId =
      VALIDVAR of {namePath : NameMap.namePath, ty : ty}
    | VALIDWILD of ty

  datatype valIdent =
      VALIDENT of varIdInfo
    | VALIDENTWILD of ty

  type conInfo
  type exnInfo

  val format_varId
      : varId -> SMLFormat.FormatExpression.expression list
  val format_varIdInfo
      : formatBtvEnv -> varIdInfo -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_varIdInfo
      : varIdInfo -> SMLFormat.FormatExpression.expression list
  val format_valId
      : formatBtvEnv -> valId -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_valId
      : valId -> SMLFormat.FormatExpression.expression list
  val format_valIdent
      : formatBtvEnv -> valIdent -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_valIdent
      : valIdent -> SMLFormat.FormatExpression.expression list
  val format_conInfo
      : formatBtvEnv -> conInfo -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_conInfo
      : conInfo -> SMLFormat.FormatExpression.expression list
  val format_exnInfo
      : formatBtvEnv -> exnInfo -> SMLFormat.FormatExpression.expression list
  val formatWithoutType_exnInfo
      : exnInfo -> SMLFormat.FormatExpression.expression list

  val univKind : {eqKind:eqKind, recordKind:recordKind, tyvarName:'a option}

  datatype strEntry =
      STRUCTURE of
      {
        name : string,
        strpath : Path.path,
        wrapperSysStructure : string option,
        env : (tyConEnv * varEnv * strEntry SEnv.map)
      }
  type strEnv
  datatype sigBindInfo =
      SIGNATURE of TyConID.Set.set * {name : string, env : Env}
  type sigEnv
  type funBindInfo
  type funEnv
  type interfaceEnv
  type basicInterfaceSig

  val format_funBindInfo
      : funBindInfo -> SMLFormat.FormatExpression.expression list
  val format_sigBindInfo
      : formatBtvEnv -> sigBindInfo
        -> SMLFormat.FormatExpression.expression list
  val format_funEnv
      : funEnv -> SMLFormat.FormatExpression.expression list
  val format_sigEnv
      : formatBtvEnv -> sigEnv -> SMLFormat.FormatExpression.expression list
  val format_interfaceEnv
      : formatBtvEnv -> interfaceEnv
        -> SMLFormat.FormatExpression.expression list

  val emptyTopEnv : topEnv
  val emptyVarEnv : varEnv
  val emptyTyfield : ty SEnv.map
  val emptyTyConEnv : tyConEnv
  val emptySigEnv : sigEnv
  val emptyFunEnv : funEnv
  val emptyInterfaceEnv : interfaceEnv
  val emptyE : Env

  val conPathInfoToConInfo : conPathInfo -> conInfo
  val exnPathInfoToExnInfo : exnPathInfo -> exnInfo
  val kindedTyvarList : tvState ref list ref

  val newty : {eqKind: eqKind,
               recordKind: recordKind,
               tyvarName: string option} -> ty
  val newUtvar : lambdaDepth * eqKind * string -> tvState ref
  val newtyRaw : {lambdaDepth: lambdaDepth,
                  eqKind: eqKind,
                  recordKind: recordKind,
                  tyvarName: string option} -> ty
  val newtyWithLambdaDepth : lambdaDepth
                             * {eqKind: eqKind,
                                recordKind: recordKind,
                                tyvarName: string option}
                             -> ty

end
