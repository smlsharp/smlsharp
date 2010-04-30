(**
 * type structures.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 *)
signature TYPES  =
  sig

    type lambdaDepth
    val infiniteDepth : lambdaDepth
    val toplevelDepth : lambdaDepth
    val youngerDepth : {contextDepth:lambdaDepth, tyvarDepth:lambdaDepth} -> bool
    val strictlyYoungerDepth : lambdaDepth * lambdaDepth -> bool

    datatype eqKind = EQ | NONEQ

(*
    datatype caseKind = BIND | MATCH | HANDLE
*)

    datatype path = datatype Path.path

    type varIdInfo

    type varid = LocalVarID.id

(*
    datatype sizeTagExp =
             ST_CONST of int
           | ST_VAR of GlobalID.globalID
           | ST_BDVAR of int
           | ST_APP of {stfun: sizeTagExp, args: sizeTagExp list}
           | ST_FUN of {args : int list, body : sizeTagExp}
*)

(*
    eqtype tid
    val initialTid : tid
    val tidToString : tid -> string
    val tidToInt : tid -> int
    val intToTid : int -> tid
    val tidCompare : tid * tid -> order
*)

    type tvKind
    type btvKind
    type varEnv
    type topVarEnv
    type tyConEnv
    type topTyConEnv
    type tyFun
    type tyCon
(*
    type tyName
    type tySpec
*)
    type conPathInfo
    type conPathInfoNameType
    type exnPathInfo
    type exnPathInfoNameType
    type varPathInfo
    type primInfo
    type oprimInfo
    type tyConIdSet
    type exnTagSet
    type dataTyInfo

    datatype recordKind = OVERLOADED of ty list | REC of ty SEnv.map | UNIV
    and tvState = SUBSTITUTED of ty | TVAR of tvKind
    and ty =
        ERRORty
      | DUMMYty of int
      | TYVARty of tvState ref
      | BOUNDVARty of int
      | FUNMty of ty list * ty
      | RECORDty of ty SEnv.map
      | RAWty of {tyCon : tyCon, args : ty list}
(*
      | PREDEFINEDty of {tyCon : tyCon, args : ty list}
*)
      | POLYty of {boundtvars : btvKind IEnv.map, body : ty}
      | ALIASty of ty * ty
(*
      | ABSSPECty of ty * ty
      | SPECty of ty
*)
      | OPAQUEty of {spec: {tyCon : tyCon, args : ty list}, implTy: ty}
      | SPECty of {tyCon : tyCon, args : ty list}
(*
    and boxedKind =
        BOXEDty (* generic boxed type *)
      | ATOMty (* generic unboxed type *)
      | DOUBLEty
      | GENERICty (* generic type *)
*)
    and idState
      = CONID of conPathInfo
      | EXNID of exnPathInfo
      | OPRIM of oprimInfo
      | PRIM of primInfo
      | VARID of varPathInfo
      | RECFUNID of varPathInfo * int
    and tyBindInfo
      = TYCON of dataTyInfo
(*
      | PREDEFINEDTYCON of dataTyInfo
*)
      | TYFUN of tyFun
      | TYSPEC of tyCon   (* abstract type declaration in signature *)
      | TYOPAQUE of {spec: tyCon, impl: tyBindInfo}   (* opaque type specification after signature matching *)
(*
      | TYSPEC of {impl:tyBindInfo option, spec:tySpec}
*)

    type Env
    type topEnv
    type strPathInfo
    datatype sigBindInfo = SIGNATURE of tyConIdSet * {name:string, env:Env}

    type utvEnv = (tvState ref) SEnv.map
    type conInfo
    type exnInfo
    type subst = ty IEnv.map
    type funBindInfo
(*
    type strInfo = {id : id, name : string, env : Env}
*)
    type funEnv
    type interfaceEnv
    type basicInterfaceSig
    type sigEnv
    datatype strEntry =
             STRUCTURE of {name : string,
                           strpath : Path.path,
                           wrapperSysStructure : string option,
                           env : (tyConEnv * varEnv * strEntry SEnv.map)}
    type strEnv = strEntry SEnv.map
    type btvEnv = btvKind IEnv.map
    type tvarNameSet = eqKind SEnv.map

  datatype varId =
           EXTERNAL of ExternalVarID.id
         | INTERNAL of LocalVarID.id

  datatype valId  = VALIDVAR of {namePath:NameMap.namePath, ty:ty} | VALIDWILD of ty
  datatype valIdent = VALIDENT of varIdInfo
                    | VALIDENTWILD of ty

  val createBtvKindMap : (int * 'a IEnv.map) list
                         -> 'a IEnv.map -> (int * 'a IEnv.map) list
  val formatBoundtvar : 'a
                        * (int
                           * {eqKind:eqKind, index:int, recordKind:'b} IEnv.map)
                              list
                              -> int
                              -> SMLFormat.FormatExpression.expression list
  val format_Env : (int * btvEnv) list
                   -> Env
                   -> SMLFormat.FormatExpression.expression list
  val format_bmap_int : ('a -> SMLFormat.FormatExpression.expression list)
                        * SMLFormat.FormatExpression.expression list
                        * SMLFormat.FormatExpression.expression list
                        -> 'a IEnv.map
                        -> SMLFormat.FormatExpression.expression list
  val format_btvKind :  (int * btvEnv) list
                        -> {eqKind:eqKind, index:int, recordKind:recordKind}
                        -> SMLFormat.FormatExpression.expression list

  val format_btvKindWithoutKindInfo : (int * btvEnv) list
                                      -> {eqKind:eqKind, index:int, recordKind:'b}
                                      -> SMLFormat.FormatExpression.expression list

  val format_btvKind_index : (int * 'a) list -> int -> SMLFormat.FormatExpression.expression list

  val format_conInfo : (int * btvEnv) list
                       -> conInfo
                       -> SMLFormat.FormatExpression.expression list
  val format_conInfoName : conInfo
                           -> SMLFormat.FormatExpression.expression list
  val format_conInfoNameType : (int * btvEnv) list
                               -> conInfo
                               -> SMLFormat.FormatExpression.expression
                                      list
  val format_exnInfo : (int * btvEnv) list
                       -> exnInfo
                       -> SMLFormat.FormatExpression.expression list
  val format_exnInfoName : exnInfo
                           -> SMLFormat.FormatExpression.expression list
  val format_exnInfoNameType : (int * btvEnv) list
                               -> exnInfo
                               -> SMLFormat.FormatExpression.expression
                                      list
  val format_conPathInfo : (int * btvEnv) list
                           -> conPathInfo
                           -> SMLFormat.FormatExpression.expression list
  val format_conPathInfoName : conPathInfo
                               -> SMLFormat.FormatExpression.expression list
  val format_conPathInfoNameType : (int * btvEnv) list
                                   -> conPathInfo
                                   -> SMLFormat.FormatExpression.expression list
  val format_exnPathInfo : (int * btvEnv) list
                           -> exnPathInfo
                           -> SMLFormat.FormatExpression.expression list
  val format_exnPathInfoName : exnPathInfo
                               -> SMLFormat.FormatExpression.expression list
  val format_exnPathInfoNameType : (int * btvEnv) list
                                   -> exnPathInfo
                                   -> SMLFormat.FormatExpression.expression list
  val format_dummyTyId : int -> SMLFormat.FormatExpression.expression list
  val format_eqKind : eqKind -> SMLFormat.FormatExpression.expression list
(*
  val format_caseKind : caseKind -> SMLFormat.FormatExpression.expression list
*)
  val format_freeTyId : 
   FreeTypeVarID.id -> SMLFormat.FormatExpression.expression list
  val format_funBindInfo : funBindInfo -> SMLFormat.FormatExpression.expression list
  val format_funEnv : funEnv -> SMLFormat.FormatExpression.expression list
(*
  val format_id : id -> SMLFormat.FormatExpression.expression list
*)
  val format_idState : (int * btvEnv) list
                       -> idState
                       -> SMLFormat.FormatExpression.expression list
  val format_oprimInfo : (int * btvEnv) list
                         -> oprimInfo
                         -> SMLFormat.FormatExpression.expression list
  val format_primInfo : (int * btvEnv) list
                        -> primInfo
                        -> SMLFormat.FormatExpression.expression list
  val format_recordKind : (int * btvEnv) list
                       -> recordKind
                       -> SMLFormat.FormatExpression.expression list
  val format_sigBindInfo : (int * btvEnv) list
                           -> sigBindInfo
                           -> SMLFormat.FormatExpression.expression list
  val format_sigEnv : (int * btvEnv) list
                      -> sigEnv
                      -> SMLFormat.FormatExpression.expression list
(*
  val format_strInfo : {env:'b, id:'c, name:string}
                       -> SMLFormat.FormatExpression.expression list
*)

  val format_strPathInfo : (int * btvEnv) list
                           -> strPathInfo
                           -> SMLFormat.FormatExpression.expression list

  val format_tvKind : (int * btvEnv) list
                      -> tvKind
                      -> SMLFormat.FormatExpression.expression list

  val format_tvState : (int * btvEnv) list
                       -> tvState
                       -> SMLFormat.FormatExpression.expression list

  val format_tvarNameSet : eqKind SEnv.map
                           -> SMLFormat.FormatExpression.expression list
  val format_ty : (int * btvEnv) list
                  -> ty
                  -> SMLFormat.FormatExpression.expression list

  val format_tyBindInfo : (int * btvEnv) list
                          -> tyBindInfo
                          -> SMLFormat.FormatExpression.expression list

  val format_tyCon : (int * btvEnv) list
                     -> tyCon
                     -> SMLFormat.FormatExpression.expression list

(*
  val format_tyName : (int * btvEnv) list
                      -> tyName
                      -> SMLFormat.FormatExpression.expression list
*)

  val format_tyConEnv : (int * btvEnv) list
                        -> tyConEnv
                        -> SMLFormat.FormatExpression.expression list

  val format_topTyConEnv : (int * btvEnv) list
                           -> topTyConEnv
                           -> SMLFormat.FormatExpression.expression list

  val format_topEnv : (int * btvEnv) list
                      -> topEnv
                      -> SMLFormat.FormatExpression.expression list

  val format_interfaceEnv : (int * btvEnv) list
                         -> interfaceEnv
                         -> SMLFormat.FormatExpression.expression list

  val format_basicInterfaceSig : (int * btvEnv) list
                                 -> basicInterfaceSig
                                 -> SMLFormat.FormatExpression.expression list
                                    
  val format_tyFun : (int * btvEnv) list
                     -> tyFun
                     -> SMLFormat.FormatExpression.expression list

  val format_tyId : int -> SMLFormat.FormatExpression.expression list

(*
  val format_tySpec : tySpec -> SMLFormat.FormatExpression.expression list
*)

  val format_utvEnv : (int * btvEnv) list
                      -> tvState ref SEnv.map
                      -> SMLFormat.FormatExpression.expression list
  val format_valId : (int * btvEnv) list
                     -> valId
                     -> SMLFormat.FormatExpression.expression list
  val format_valIdent : (int * btvEnv) list
                        -> valIdent -> SMLFormat.FormatExpression.expression list
  val format_varEnv : (int * btvEnv) list
                      -> varEnv
                      -> SMLFormat.FormatExpression.expression list
  val format_topVarEnv : (int * btvEnv) list
                         -> topVarEnv
                         -> SMLFormat.FormatExpression.expression list
  val format_varIdInfo : (int * btvEnv) list
                         -> varIdInfo
                         -> SMLFormat.FormatExpression.expression list

  val format_varIdInfoWithoutType : (int * btvEnv) list
                                    -> varIdInfo
                                    -> SMLFormat.FormatExpression.expression list
  val format_varPathInfo : ((int * btvEnv) list )
                           -> varPathInfo
                           -> SMLFormat.FormatExpression.expression list
  val format_dataTyInfo : ((int * btvEnv) list ) ->
                          dataTyInfo -> 
                          SMLFormat.FormatExpression.expression list
  val format_varId : varId -> SMLFormat.FormatExpression.expression list
  val format_tyConIdSet : tyConIdSet -> SMLFormat.FormatExpression.expression list
  val format_exnTagSet : exnTagSet -> SMLFormat.FormatExpression.expression list


  val emptyVarEnv : varEnv
  val emptyTyfield : ty SEnv.map
  val emptyTyConEnv : tyConEnv
  val emptySigEnv : sigEnv
  val emptyFunEnv : funEnv
  val emptyInterfaceEnv : interfaceEnv
  val emptyE : Env
  val emptySubst : subst

  val emptyExnTagSet : exnTagSet
  val freeTyIdName : FreeTypeVarID.id -> string
  val freeTyIdToDoc : {eqKind:eqKind, id:FreeTypeVarID.id, recordKind:'a} -> string
(*
  val init : unit -> unit
  val newVarId : unit -> id
  val nextVarId : unit -> id
  val newTyConId : Namespace.namespace -> GlobalID.globalID
  val nextTyConId : Namespace.namespace -> GlobalID.globalID
  val dummyStructureId : id
  val newStructureId : unit -> id
*)
  val eqTyCon : tyCon * tyCon -> bool
(*
  val eqTyConWithTyName : tyCon * tyName -> bool
*)
  val conPathInfoToConInfo : conPathInfo -> conInfo
  val exnPathInfoToExnInfo : exnPathInfo -> exnInfo
  val kindedTyvarList : tvState ref list ref

  val newty : {eqKind:eqKind, recordKind:recordKind, tyvarName:string option} ->
              ty

  val newUtvar : lambdaDepth * eqKind * string -> tvState ref

  val newtyRaw : {lambdaDepth:lambdaDepth, eqKind:eqKind, recordKind:recordKind, tyvarName:string option} ->
                 ty

  val newtyWithLambdaDepth : lambdaDepth * {eqKind:eqKind, recordKind:recordKind, tyvarName:string option} ->
                             ty

  val tyIdName : int -> string
  val univKind : {eqKind:eqKind, recordKind:recordKind, tyvarName:'a option}
  val compareVarId : varId * varId -> order
  val emptyTopEnv : topEnv

  end
