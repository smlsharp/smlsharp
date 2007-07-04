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

    datatype caseKind = BIND | MATCH | HANDLE

    datatype path = datatype Path.path

    type varIdInfo
    type id = ID.id

    datatype sizeTagExp =
             ST_CONST of int
           | ST_VAR of id
           | ST_BDVAR of int
           | ST_APP of {stfun: sizeTagExp, args: sizeTagExp list}
           | ST_FUN of {args : int list, body : sizeTagExp}

    eqtype tid
    val initialTid : tid
    val tidToString : tid -> string
    val tidToInt : tid -> int
    val intToTid : int -> tid
    val tidCompare : tid * tid -> order

    type tvKind
    type btvKind
    type varEnv
    type tyConEnv
    type tyFun
    type tyCon
    type tySpec
    type conPathInfo
    type conPathInfoNameType
    type varPathInfo
    type primInfo
    type oprimInfo
    type tyConIdSet
    type exnTagSet

    datatype recKind = OVERLOADED of ty list | REC of ty SEnv.map | UNIV
    and tvState = SUBSTITUTED of ty | TVAR of tvKind
    and ty =
        ERRORty
      | DUMMYty of int                  
      | TYVARty of tvState ref                  
      | BOUNDVARty of int
      | FUNMty of ty list * ty
      | RECORDty of ty SEnv.map                          
      | CONty of {tyCon : tyCon, args : ty list}
      | POLYty of {boundtvars : btvKind IEnv.map, body : ty}
      | BOXEDty (* generic boxed type *)
      | ATOMty (* generic unboxed type *)
      | GENERICty (* generic type *)
      | INDEXty of ty * string
      | BMABSty of ty list * ty
      | BITMAPty of ty list 
      | ALIASty of ty * ty
      | BITty of int
      | UNBOXEDty
      | DBLUNBOXEDty
      | OFFSETty of ty list 
      | TAGty of int
      | SIZEty of int
      | DOUBLEty
      | PADty of ty list
      | PADCONDty of ty list * int
      | FRAMEBITMAPty of int list
      | ABSSPECty of ty * ty 
      | SPECty of ty
      | ABSTRACTty
    and idState
      = CONID of conPathInfo
      | OPRIM of oprimInfo
      | PRIM of primInfo
      | VARID of varPathInfo
      | RECFUNID of varPathInfo * int
    and tyBindInfo
      = TYCON of tyCon
      | TYFUN of tyFun
      | TYSPEC of {impl:tyBindInfo option, spec:tySpec}

    type Env
    type strPathInfo 
    datatype strEnv = 
      STRUCTURE of {id : id, name : string, strpath : path, env : Env} SEnv.map
    datatype sigBindInfo = SIGNATURE of tyConIdSet * strPathInfo

    type utvEnv = (tvState ref) SEnv.map
    type conInfo =  {displayName : string, funtyCon : bool, ty : ty, tag: int, tyCon : tyCon}
    type subst = ty IEnv.map
    type funBindInfo = {func : {name:string, id : id},
                        argument : {name:string,id :id},
                        functorSig: {
				     exnTagSet : exnTagSet,
				     tyConIdSet : tyConIdSet, 
                                     func : {arg : Env, 
                                             body : {constrained:(tyConIdSet * Env),
                                                     unConstrained: Env}}
                                     }
                        }
  type strInfo = {id : id, name : string, env : Env}
  type funEnv = funBindInfo SEnv.map
  type sigEnv = sigBindInfo SEnv.map 
  type btvEnv = btvKind IEnv.map
  type tvarNameSet = bool SEnv.map 

  datatype valId  = VALIDVAR of {name:string, ty:ty} | VALIDWILD of ty
  datatype valIdent = VALIDENT of {displayName:string, id:id, ty:ty} | VALIDENTWILD of ty

  val createBtvKindMap : (int * 'a IEnv.map) list
                           -> 'a IEnv.map -> (int * 'a IEnv.map) list
  val formatBoundtvar : 'a
                          * (int
                             * {eqKind:eqKind, index:int, recKind:'b} IEnv.map)
                              list
                          -> Iord.ord_key
                             -> SMLFormat.FormatExpression.expression list
    val format_Env : (int
                      * {eqKind:eqKind, index:int, recKind:recKind} IEnv.map) 
                       list
                       -> Env
                        -> SMLFormat.FormatExpression.expression list
    val format_bmap_int : ('a -> SMLFormat.FormatExpression.expression list)
                          * SMLFormat.FormatExpression.expression list
                          * SMLFormat.FormatExpression.expression list
                          -> 'a IEnv.map
                             -> SMLFormat.FormatExpression.expression list
    val format_btvKind : (int
                          * {eqKind:eqKind, index:int, recKind:recKind} 
                              IEnv.map) list
                         -> {eqKind:eqKind, index:int, recKind:recKind}
                            -> SMLFormat.FormatExpression.expression list
    val format_btvKindWithoutKindInfo : (int * 'a) list
                                        -> {eqKind:eqKind, index:int,
                                            recKind:'b}
                                           -> 
                                                SMLFormat.FormatExpression.expression
                                                list
    val format_btvKind_index : (int * 'a) list
                               -> int
                                  -> SMLFormat.FormatExpression.expression list
    val format_conInfo : (int
                            * {eqKind:eqKind, index:int, recKind:recKind} 
                                IEnv.map) list
                           -> {displayName:string, funtyCon:'a, tag:'c,
                               ty:ty, tyCon:'d}
                              -> SMLFormat.FormatExpression.expression list
    val format_conInfoName : {displayName:string, funtyCon:'a, tag:'c,
                                ty:'d, tyCon:'e}
                               -> SMLFormat.FormatExpression.expression list
    val format_conInfoNameType : (int
                                  * {eqKind:eqKind, index:int,
                                       recKind:recKind} IEnv.map) list
                                   -> {displayName:string, funtyCon:'a,
                                       tag:'c, ty:ty, tyCon:'d}
                                      -> SMLFormat.FormatExpression.expression 
                                           list
    val format_conPathInfo : (int
                              * {eqKind:eqKind, index:int, recKind:recKind} 
                                  IEnv.map) list
                             -> conPathInfoNameType
                                -> SMLFormat.FormatExpression.expression list
    val format_conPathInfoName : {funtyCon:'a, name:string, strpath:path,
                                  tag:'b, ty:'c, tyCon:'d}
                                 -> SMLFormat.FormatExpression.expression list
    val format_conPathInfoNameType : (int
                                      * {eqKind:eqKind, index:int,
                                         recKind:recKind} IEnv.map) list
                                     -> {funtyCon:'a, name:string, strpath:'b,
                                         tag:'c, ty:ty, tyCon:'d}
                                        -> SMLFormat.FormatExpression.expression 
                                             list
    val format_dummyTyId : int -> SMLFormat.FormatExpression.expression list
    val format_eqKind : eqKind -> SMLFormat.FormatExpression.expression list
    val format_caseKind : caseKind -> SMLFormat.FormatExpression.expression list
    val format_freeTyId : int -> SMLFormat.FormatExpression.expression list
    val format_funBindInfo : {argument:'a, func:{id:'b, name:string},
                              functorSig:'c}
                             -> SMLFormat.FormatExpression.expression list
    val format_funEnv : {argument:'a, func:{id:'b, name:string}, functorSig:'c}
                          SEnv.map
                        -> SMLFormat.FormatExpression.expression list
    val format_id : id -> SMLFormat.FormatExpression.expression list
    val format_idState : (int
                          * {eqKind:eqKind, index:int, recKind:recKind} 
                              IEnv.map) list
                         -> idState -> SMLFormat.FormatExpression.expression list
    val format_oprimInfo : (int
                            * {eqKind:eqKind, index:int, recKind:recKind} 
                                IEnv.map) list
                           -> oprimInfo
                              -> SMLFormat.FormatExpression.expression list
    val format_primInfo : (int
                           * {eqKind:eqKind, index:int, recKind:recKind} 
                               IEnv.map) list
                          -> primInfo
                             -> SMLFormat.FormatExpression.expression list
    val format_recKind : (int
                          * {eqKind:eqKind, index:int, recKind:recKind} 
                              IEnv.map) list
                         -> recKind -> SMLFormat.FormatExpression.expression list
    val format_sigBindInfo : (int
                              * {eqKind:eqKind, index:int, recKind:recKind} 
                                  IEnv.map) list
                             -> sigBindInfo
                                -> SMLFormat.FormatExpression.expression list
    val format_sigEnv : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> sigBindInfo SEnv.map
                           -> SMLFormat.FormatExpression.expression list
    val format_strEnv : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> strEnv
                           -> SMLFormat.FormatExpression.expression list
    val format_strInfo : 'a
                         -> {env:'b, id:'c, name:string}
                            -> SMLFormat.FormatExpression.expression list 
    val format_strPathInfo : (int
                              * {eqKind:eqKind, index:int, recKind:recKind} 
                                  IEnv.map) list
                             -> strPathInfo
                                -> SMLFormat.FormatExpression.expression list
   val format_tvKind : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> tvKind -> SMLFormat.FormatExpression.expression list
    val format_tvState : (int
                          * {eqKind:eqKind, index:int, recKind:recKind} 
                              IEnv.map) list
                         -> tvState -> SMLFormat.FormatExpression.expression list
    val format_tvarNameSet : bool SEnv.map
                             -> SMLFormat.FormatExpression.expression list
    val format_ty : (int
                     * {eqKind:eqKind, index:int, recKind:recKind} IEnv.map) 
                      list
                    -> ty -> SMLFormat.FormatExpression.expression list
    val format_tyBindInfo : (int
                             * {eqKind:eqKind, index:int, recKind:recKind} 
                                 IEnv.map) list
                            -> tyBindInfo
                               -> SMLFormat.FormatExpression.expression list
    val format_tyCon : (int
                        * {eqKind:eqKind, index:int, recKind:recKind} IEnv.map)
                         list
                       -> tyCon -> SMLFormat.FormatExpression.expression list
    val format_tyConEnv : (int
                           * {eqKind:eqKind, index:int, recKind:recKind} 
                               IEnv.map) list
                          -> tyConEnv
                             -> SMLFormat.FormatExpression.expression list
    val format_tyFun : (int
                        * {eqKind:eqKind, index:int, recKind:recKind} IEnv.map)
                         list
                       -> tyFun -> SMLFormat.FormatExpression.expression list
    val format_tyId : int -> SMLFormat.FormatExpression.expression list
    val format_tySpec : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> tySpec -> SMLFormat.FormatExpression.expression list
    val format_utvEnv : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> tvState ref SEnv.map
                           -> SMLFormat.FormatExpression.expression list
    val format_valId : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> valId -> SMLFormat.FormatExpression.expression list
    val format_valIdent : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> valIdent -> SMLFormat.FormatExpression.expression list
    val format_varEnv : (int
                         * {eqKind:eqKind, index:int, recKind:recKind} 
                             IEnv.map) list
                        -> idState SEnv.map
                           -> SMLFormat.FormatExpression.expression list
    val format_varIdInfo : (int
                            * {eqKind:eqKind, index:int, recKind:recKind} 
                                IEnv.map) list
                           -> {displayName:string, id:'a, ty:ty}
                              -> SMLFormat.FormatExpression.expression list
    val format_varIdInfoWithoutType : (int
                            * {eqKind:eqKind, index:int, recKind:recKind} 
                                IEnv.map) list
                           -> {displayName:string, id:'a, ty:ty}
                              -> SMLFormat.FormatExpression.expression list
    val format_varPathInfo : (int
                              * {eqKind:eqKind, index:int, recKind:recKind} 
                                  IEnv.map) list
                             -> varPathInfo
                                -> SMLFormat.FormatExpression.expression list
    val format_tyConIdSet : tyConIdSet -> SMLFormat.FormatExpression.expression list
    val format_exnTagSet : exnTagSet -> SMLFormat.FormatExpression.expression list
    val emptyVarEnv : varEnv
    val emptyTyfield : ty SEnv.map
    val emptyTyConEnv : tyConEnv 
    val emptyStrEnv : strEnv
    val emptySigEnv :sigEnv
    val emptyFunEnv :funEnv
    val emptyE : Env
    val emptySubst : subst

    val emptyExnTagSet : exnTagSet
    val freeTyIdName : int -> string
    val freeTyIdToDoc : {eqKind:eqKind, id:int, recKind:'a} -> string
    val init : unit -> unit
    val newVarId : unit -> id
    val nextVarId : unit -> id
    val newTyConId : unit -> id
    val nextTyConId : unit -> id
    val newExnTag : unit -> int
    val nextExnTag : unit -> int
    val maxSystemExnTag : int
    val dummyStructureId : id
    val newStructureId : unit -> id
    val eqTyCon : tyCon * tyCon -> bool
    val conPathInfoToConInfo : conPathInfo -> conInfo
    val kindedTyvarList : tvState ref list ref
    val newUtvar : lambdaDepth * eqKind * string -> tvState ref
    val newty : {eqKind:eqKind, recKind:recKind, tyvarName:string option} -> ty
    val newtyWithLambdaDepth : lambdaDepth * {eqKind:eqKind, recKind:recKind, tyvarName:string option} -> ty
    val newtyRaw : {lambdaDepth:lambdaDepth, eqKind:eqKind, recKind:recKind, tyvarName:string option} -> ty
    val nextBTid : unit -> int
    val peekBTid : unit -> int
    val advanceBTid : int -> unit
    val initTid : unit -> unit
    val nextTid : unit -> tid
    val peekTid : unit -> tid
    val tyIdName : int -> string
    val univKind : {eqKind:eqKind, recKind:recKind, tyvarName:'a option}

    type moduleState
    val getModuleState : unit -> moduleState
    val restoreModuleState : moduleState -> unit
  end
