(*  built-in types. *)
structure BuiltinTypes =
struct
local
  structure I = IDCalc
  structure T = Types
  structure Ity = EvalIty
  datatype bty = datatype BuiltinTypeNames.bty
  fun bug s = Control.Bug ("BuiltinTypes: " ^ s)

  fun printBty bty =
      case bty of
      INTty => print "INTty"
    | INTINFty => print "INTINFty"
    | WORDty => print "WORDty"
    | WORD8ty => print "WORD8ty"
    | CHARty => print "CHARty"
    | STRINGty => print "STRINGty"
    | REALty => print "REALty"
    | REAL32ty => print "REAL32ty"
    | UNITty => print "UNITty"
    | PTRty => print "PTRty"
    | ARRAYty => print "ARRAYty"
    | VECTORty => print "VECTORty"
    | EXNty => print "EXNty"
    | BOXEDty => print "BOXEDty"
    | EXNTAGty => print "EXNTAGty"
    | REFty => print "REFty"
    | BOOLty => print "BOOLty"
    | LISTty => print "LISTty"
    | OPTIONty => print "OPTIONty"
    | ORDERty => print "ORDERty"
    (* the following are for SQL *)
    | SERVERty => print "SERVERty"
    | DBIty => print "DBIty"
    | VALUEty => print "VALUEty"
    | CONNty => print "CONNty"
    | DBty => print "DBty"
    | TABLEty => print "TABLEty"
    | ROWty => print "ROWty"
    | RESULTty => print "RESULTty"
    | RELty => print "RELty"
    | QUERYty => print "QUERYty"
    | COMMANDty  => print "COMMANDty"

  datatype ty
    = TVAR of string 
    | CON of (bty * ty list)
    | TUPLE of ty list 
    | RECORD of (string * ty) list
    | FUN of ty * ty

  type btyDef = {path:string list,
                 iseq:bool,
                 dtyKind:I.dtyKind,
                 formals:(string*Absyn.eq) list,
                 conSpec: (string * ty option) list}
  type tstrInfo = {tfun:I.tfun, varE:I.varE, formals:I.formals, conSpec:I.conSpec} 
  type btyInfo = 
       {tstrInfo:tstrInfo,
        tyCon: T.tyCon,
        findCon: string -> I.conInfo,
        mkTys: I.ty list -> I.ty * T.ty
       }

  type btyMap = bty -> btyInfo
  type tvarMap = I.tvar SEnv.map
  val emptyContext = Ity.emptyContext

  fun evalTy (btyMap:btyMap, tvarMap:tvarMap) ty =
      case ty of
        TVAR s => (case SEnv.find(tvarMap, s) of
                     SOME tv => I.TYVAR tv
                   | NONE => 
                     (print "bug tvar not found\n";
                     raise bug "tvar not found")
                  )
      | RECORD fields =>
        I.TYRECORD
          (foldl
             (fn ((label, ty), fields) =>
                 LabelEnv.insert(fields, label, evalTy (btyMap, tvarMap) ty))
             LabelEnv.empty
             fields)
      | TUPLE tys => 
        evalTy (btyMap, tvarMap) (RECORD (Utils.listToTuple tys))
      | CON (bty, args) => 
        let
          val {tstrInfo={tfun,...},...} = 
              btyMap bty
              handle e => 
                     (print "bug evalTy btyMap failed:";
                      printBty bty;
                      print "\n";
                      raise e)
          val args = map (evalTy (btyMap, tvarMap)) args
        in
          I.TYCONSTRUCT {tfun=tfun, args=args}
        end
      | FUN(bty1, bty2) => 
        I.TYFUNM([evalTy (btyMap, tvarMap) bty1], evalTy (btyMap, tvarMap) bty2)

  fun makeTfun
        (btyMap:btyMap)
        (bty:bty, {path, iseq, formals, conSpec, dtyKind}:btyDef) =
      let
        val id = TypID.generate()
        val (tvarEnv, formals) =
            foldl
            (fn ((name, eq), (tvarEnv, formals)) =>
                let
                  val tvar = 
                      {name=name, eq=eq, id=TvarID.generate(), lifted=false}
                in
                  (SEnv.insert(tvarEnv, name, tvar),
                   formals@[tvar])
                end
            )
            (SEnv.empty, nil)
            formals
        val tfv =
            I.mkTfv
              (I.TFUN_DTY {id = id,
                           iseq=iseq,
                           formals=formals,
			   runtimeTy = I.BUILTINty bty,
                           conSpec = SEnv.empty,
                           originalPath = path,
                           liftedTys = I.emptyLiftedTys,
                           dtyKind = dtyKind
                          }
              )
        val tfun = I.TFUN_VAR tfv
        val tyCon = Ity.evalTfun emptyContext tfun 
            handle e => 
                   (print "bug: evalTfun failed\n";
                    raise bug "evalTfun in evalBuiltin" 
                   )
        val bummyBtyInfo = {tstrInfo = {tfun=tfun, formals=formals, conSpec=SEnv.empty, varE=SEnv.empty},
                            tyCon=tyCon,
                            findCon= fn x => raise bug "dummy btyInfo",
                            mkTys = fn x => raise bug "dummy btyInfo"
                           }
        val newBtyMap = fn x => 
                           if x = bty then bummyBtyInfo
                           else btyMap x
        val conSpec =
            foldl
              (fn ((name, tyopt), conSpec) =>
                  let
                    val tyOption = Option.map (evalTy (newBtyMap, tvarEnv)) tyopt
                  in
                     SEnv.insert(conSpec, name, tyOption)
                  end
              )
              SEnv.empty
              conSpec
        val runtimeTy = 
            case dtyKind of 
              I.DTY => if SEnv.isEmpty (SEnv.filter (fn SOME _ => true | NONE => false) conSpec)
	               then I.BUILTINty WORDty else I.BUILTINty  BOXEDty
            | _ => I.BUILTINty bty
        val _ = 
            tfv :=
            I.TFUN_DTY {id = id,
                        iseq=iseq,
                        formals=formals,
			runtimeTy = runtimeTy,
                        conSpec= conSpec,
                        originalPath = path,
                        liftedTys=I.emptyLiftedTys,
                        dtyKind=dtyKind
                       }
        val returnTy = 
            I.TYCONSTRUCT {tfun=tfun, args= map (fn tv=>I.TYVAR tv) formals}
        val varE = 
            SEnv.mapi
              (fn (name, tyopt) =>
                  let
                    val conId = ConID.generate()
                    val conBodyTy = 
                        case tyopt of
                          NONE => returnTy
                        | SOME ty =>I.TYFUNM([ty], returnTy)
                    val conTy =
                        case formals of
                          nil => conBodyTy
                        | _ => I.TYPOLY
                                 (map (fn tv =>(tv, I.UNIV)) formals,
                                  conBodyTy)
                  in
                    I.IDCON {id=conId, ty=conTy}
                  end
              )
              conSpec
        val tyCon = Ity.evalTfun emptyContext tfun 
            handle e => 
                   (print "bug evalTfun failed";
                    raise bug "evalTfun in evalBuiltin" 
                   )
        fun findConInfo name =
            case SEnv.find(varE, name) of
              SOME (I.IDCON{id,ty}) => {id=id, ty=ty, path=[name]}
            | _ => (print "bug findConInfo\n";
                    raise bug "con not found"
                   )
        fun mkTys args =
            let
              val ity = I.TYCONSTRUCT {tfun=tfun, args=args}
            in
              (ity, Ity.evalIty Ity.emptyContext ity)
            end
      in
        {tstrInfo = {tfun=tfun, varE=varE, formals=formals,conSpec=conSpec},
         tyCon = tyCon,
         findCon = findConInfo,
         mkTys = mkTys
        }
      end

  val EQ = Absyn.EQ
  val NONEQ = Absyn.NONEQ

  val btyInfoList : (bty*btyDef) list = 
      [
       (INTty, 
        {path=["int"], 
         dtyKind=I.BUILTIN INTty, iseq=true, formals=nil, conSpec=nil}),
       (INTINFty, 
        {path=["intInf"], 
         dtyKind=I.BUILTIN INTINFty, iseq=true, formals=nil, conSpec=nil}),
       (WORDty, 
        {path=["word"], 
         dtyKind=I.BUILTIN WORDty, iseq=true, formals=nil, conSpec=nil}),
       (WORD8ty, 
        {path=["word8"], 
         dtyKind=I.BUILTIN WORD8ty, iseq=true, formals=nil, conSpec=nil}),
       (CHARty, 
        {path=["char"], 
         dtyKind=I.BUILTIN CHARty, iseq=true, formals=nil, conSpec=nil}),
       (STRINGty, 
        {path=["string"], 
         dtyKind=I.BUILTIN STRINGty, iseq=true, formals=nil, conSpec=nil}),
       (REALty, 
        {path=["real"], 
         dtyKind=I.BUILTIN REALty, iseq=false, formals=nil, conSpec=nil}),
       (REAL32ty, 
        {path=["real32"], 
         dtyKind=I.BUILTIN REAL32ty, iseq=false, formals=nil, conSpec=nil}),
       (UNITty, 
        {path=["unit"], 
         dtyKind=I.BUILTIN UNITty, iseq=true, formals=nil, conSpec=nil}),
       (PTRty, 
        {path=["ptr"], 
         dtyKind=I.BUILTIN PTRty, iseq=true, formals=[("a",NONEQ)], conSpec=nil}),
       (ARRAYty, 
        {path=["array"], 
         dtyKind=I.BUILTIN ARRAYty, iseq=true, formals=[("a",NONEQ)], conSpec=nil}),
       (VECTORty, 
        {path=["vector"], 
         dtyKind=I.BUILTIN VECTORty, iseq=true, formals=[("a",NONEQ)], conSpec=nil}),
       (EXNty, 
        {path=["exn"], 
         dtyKind=I.BUILTIN EXNty, iseq=false, formals=nil, conSpec=nil}),
       (BOXEDty, 
        {path=["boxed"], 
         dtyKind=I.BUILTIN BOXEDty, iseq=false, formals=nil, conSpec=nil}),
       (EXNTAGty, 
        {path=["exntag"], 
         dtyKind=I.BUILTIN EXNTAGty, iseq=false, formals=nil, conSpec=nil}),
       (REFty, 
        {path=["ref"], 
         iseq=true,
         dtyKind=I.DTY,
         formals=[("a",NONEQ)], 
         conSpec=[("ref", SOME(TVAR "a"))]
        }
       ),
       (BOOLty, 
        {path=["bool"], 
         iseq=true, 
         dtyKind=I.DTY,
         formals=nil, 
         conSpec=[("false",NONE), ("true", NONE)]
        }
       ),
       (LISTty, 
        {path=["list"], 
         iseq=true, 
         dtyKind=I.DTY,
         formals=[("a",NONEQ)], 
         conSpec=[("::", SOME(TUPLE [TVAR "a", CON(LISTty, [TVAR "a"])])),
                  ("nil", NONE)]
        }
       ),
       (OPTIONty, 
        {path=["option"], 
         dtyKind=I.DTY, 
         iseq=true, 
         formals=[("a",NONEQ)], 
         conSpec=[("NONE", NONE), 
                  ("SOME", SOME (TVAR "a"))
                 ]
        }
       ),
       (ORDERty, 
        {path=["order"], 
         dtyKind=I.DTY, 
         iseq=true, 
         formals=nil, 
         conSpec=[("EQUAL", NONE),
                  ("LESS", NONE),
                  ("GREATER", NONE)
                  ]
        }
       ),
(*
  datatype 'a server 
    = SERVER of
        string
        * (string * {colname: string, typename: string, isnull: bool} list) list
        * 'a
*)
       (SERVERty, 
        {path=["SQL", "server"], 
         dtyKind=I.DTY, 
         iseq=true, 
         formals=[("a",NONEQ)], 
         conSpec=[("SERVER", 
                   SOME(TUPLE[CON(STRINGty,nil), 
                              CON(LISTty,
                                  [
                                   TUPLE
                                     [
                                      CON(STRINGty, nil),
                                      CON(LISTty,
                                          [
                                           RECORD[("colname", CON(STRINGty,nil)),
                                                  ("typename", CON(STRINGty,nil)),
                                                  ("isnull", CON(BOOLty,nil))]
                                          ]
                                         )
                                     ]
                                  ]
                                 ),
                              TVAR "a"
                             ]
                       )
                  )
                 ]
        }
       ),
       (* datatype 'a dbi = DBI  *)
       (DBIty, 
        {path=["SQL", "dbi"], 
         dtyKind=I.DTY, 
         iseq=true, 
         formals=[("a",NONEQ)], 
         conSpec=[("DBI", NONE)]
        }
       ),
       (* datatype ('a,'b) value = VALUE of (string * 'b dbi) * 'a *)
       (VALUEty, 
        {path=["SQL", "value"], 
         dtyKind=I.DTY, 
         iseq=true, 
         formals=[("a",NONEQ), ("b", NONEQ)], 
         conSpec=[("VALUE", SOME (TUPLE[TUPLE[CON(STRINGty, nil),
                                              CON(DBIty, [TVAR "b"])
                                              ],
                                        TVAR "a"
                                        ]
                                  )
                  )
                  ]
        }
       ),
       (*  datatype 'a conn = CONN of unit ptr * 'a *)
       (CONNty,
        {path=["SQL", "conn"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=[("a",NONEQ)], 
         conSpec=[("CONN", 
                   SOME 
                     (TUPLE
                        [CON(PTRty, [CON(UNITty, nil)]),
                         TVAR "a"]
                     )
                  )
                 ]
        }
       ),
      (* datatype ('a,'b) db = DB of 'a * 'b dbi *)
       (DBty,
        {path=["SQL", "db"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=[("a",NONEQ), ("b", NONEQ)], 
         conSpec=[("DB", 
                   SOME 
                     (TUPLE
                        [TVAR "a",
                         CON(DBIty, [TVAR "b"])
                        ]
                     )
                  )
                 ]
        }
       ),
      (* datatype ('a,'b) table = TABLE of (string * 'b dbi) * 'a *)
       (TABLEty,
        {path=["SQL", "table"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=[("a",NONEQ), ("b", NONEQ)], 
         conSpec=[("TABLE", 
                   SOME 
                     (TUPLE
                        [TUPLE [ CON(STRINGty, nil),
                                 CON(DBIty, [TVAR "b"])
                               ],
                         TVAR "a"
                        ]
                     )
                  )
                 ]
        }
       ),
      (* datatype ('a,'b) row = ROW of (string * 'b dbi) * 'a *)
       (ROWty,
        {path=["SQL", "row"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=[("a",NONEQ), ("b", NONEQ)], 
         conSpec=[("ROW", 
                   SOME 
                     (TUPLE
                        [TUPLE [ CON(STRINGty, nil),
                                 CON(DBIty, [TVAR "b"])
                               ],
                         TVAR "a"
                        ]
                     )
                  )
                 ]
        }
       ),
      (* datatype result = RESULT of unit ptr * int *)
       (RESULTty,
        {path=["SQL", "result"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=nil, 
         conSpec=[("RESULT", 
                   SOME 
                     (TUPLE
                        [ CON(PTRty, [CON(UNITty, nil)]),
                          CON(INTty, nil)
                        ]
                     )
                  )
                 ]
        }
       ),
      (* datatype 'a rel = REL of result * (result -> 'a) *)
       (RELty,
        {path=["SQL", "rel"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=[("a",NONEQ)], 
         conSpec=[("REL", 
                   SOME 
                     (TUPLE
                        [CON(RESULTty, nil),
                         FUN(CON(RESULTty,nil), TVAR "a")
                        ]
                     )
                  )
                 ]
        }
       ),
      (* datatype 'a query = QUERY of string * 'a * (result -> 'a) *)
       (QUERYty,
        {path=["SQL", "query"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=[("a",NONEQ)], 
         conSpec=[("QUERY", 
                   SOME 
                     (TUPLE
                        [CON(STRINGty, nil),
                         TVAR "a",
                         FUN(CON(RESULTty,nil), TVAR "a")
                        ]
                     )
                  )
                 ]
        }
       ),
      (* datatype command = COMMAND of string *)
       (COMMANDty,
        {path=["SQL", "command"], 
         dtyKind=I.DTY,
         iseq=true,
         formals=nil, 
         conSpec=[("COMMAND", SOME (CON(STRINGty, nil)))]
        }
       )
      ]

  val btyMap : btyMap =
      foldl
      (fn ((bty, info:btyDef), btyMap) =>
          let
            val btyInfo:btyInfo = makeTfun (btyMap:btyMap) (bty, info:btyDef)
          in
            fn x => if x = bty then btyInfo else btyMap x
          end
      )
      (fn x => 
          (print "bug btyinfo not defined:";
           printBty x;
           print "\n";
           raise bug "btyinfo not defined")
      )
      btyInfoList

  fun typedConInfo {id, ty, path} = 
      {id = id, ty = Ity.evalIty Ity.emptyContext ty, path = path}
  fun typedExnInfo {id, ty, path} = 
      {ty = Ity.evalIty Ity.emptyContext ty, path = path}

in
  type tstrInfo = tstrInfo
  type btyInfo = btyInfo
  
  val {tstrInfo=intTstrInfo, tyCon=intTyCon, mkTys=intMkTys, findCon=intFindCon} 
      = btyMap INTty
  val (intITy, intTy) = intMkTys nil

  val {tstrInfo=intInfTstrInfo, tyCon=intInfTyCon, mkTys=intInfMkTys, findCon=intInfFindCon} 
      = btyMap INTINFty
  val (intInfITy, intInfTy) = intInfMkTys nil

  val {tstrInfo=wordTstrInfo, tyCon=wordTyCon, mkTys=wordMkTys, findCon=wordFindCon} 
      = btyMap WORDty
  val (wordITy, wordTy) = wordMkTys nil

  val {tstrInfo=word8TstrInfo, tyCon=word8TyCon, mkTys=word8MkTys, findCon=word8FindCon} 
      = btyMap WORD8ty
  val (word8ITy, word8Ty) = word8MkTys nil

  val {tstrInfo=charTstrInfo, tyCon=charTyCon, mkTys=charMkTys, findCon=charFindCon} 
      = btyMap CHARty
  val (charITy, charTy) = charMkTys nil

  val {tstrInfo=stringTstrInfo, tyCon=stringTyCon, mkTys=stringMkTys, findCon=stringFindCon} 
      = btyMap STRINGty
  val (stringITy, stringTy) = stringMkTys nil

  val {tstrInfo=realTstrInfo, tyCon=realTyCon, mkTys=realMkTys, findCon=realFindCon} 
      = btyMap REALty
  val (realITy, realTy) = realMkTys nil

  val {tstrInfo=real32TstrInfo, tyCon=real32TyCon, mkTys=real32MkTys, findCon=real32FindCon} 
      = btyMap REAL32ty
  val (real32ITy, real32Ty) = real32MkTys nil

  val {tstrInfo=unitTstrInfo, tyCon=unitTyCon, mkTys=unitMkTys, findCon=unitFindCon} 
      = btyMap UNITty
  val (unitITy, unitTy) = unitMkTys nil

  val {tstrInfo=ptrTstrInfo, tyCon=ptrTyCon, mkTys=ptrMkTys, findCon=ptrFindCon} 
      = btyMap PTRty
  val (ptrITy, ptrTy) = ptrMkTys [unitITy]

  val {tstrInfo=arrayTstrInfo, tyCon=arrayTyCon, mkTys=arrayMkTys, findCon=arrayFindCon} 
      = btyMap ARRAYty
  val (arrayITy, arrayTy) = arrayMkTys nil

  val {tstrInfo=vectorTstrInfo, tyCon=vectorTyCon, mkTys=vectorMkTys, findCon=vectorFindCon} 
      = btyMap VECTORty
  val (vectorITy, vectorTy) = vectorMkTys nil

  val {tstrInfo=exnTstrInfo, tyCon=exnTyCon, mkTys=exnMkTys, findCon=exnFindCon} 
      = btyMap EXNty
  val (exnITy, exnTy) = exnMkTys nil

  val {tstrInfo=boxedTstrInfo, tyCon=boxedTyCon, mkTys=boxedMkTys, findCon=boxedFindCon} 
      = btyMap BOXEDty
  val (boxedITy, boxedTy) = boxedMkTys nil

  val {tstrInfo=exntagTstrInfo, tyCon=exntagTyCon, mkTys=exntagMkTys, findCon=exntagFindCon} 
      = btyMap EXNTAGty
  val (exntagITy, exntagTy) = exntagMkTys nil

  val {tstrInfo=refTstrInfo, tyCon=refTyCon, mkTys=refMkTys, findCon=refFindCon} 
      = btyMap REFty
  val (refITy, refTy) = refMkTys nil
  val refICConInfo = refFindCon "ref"
  val refTPConInfo = typedConInfo refICConInfo

  val {tstrInfo=boolTstrInfo, tyCon=boolTyCon, mkTys=boolMkTys, findCon=boolFindCon} 
      = btyMap BOOLty
  val (boolITy, boolTy) = boolMkTys nil
  val trueICConInfo = boolFindCon "true"
  val trueTPConInfo = typedConInfo trueICConInfo
  val falseICConInfo = boolFindCon "false"
  val falseTPConInfo = typedConInfo falseICConInfo

  val {tstrInfo=listTstrInfo, tyCon=listTyCon, mkTys=listMkTys, findCon=listFindCon} 
      = btyMap LISTty
  val (listITy, listTy) = listMkTys nil
  val consICConInfo = listFindCon "::"
  val consTPConInfo = typedConInfo consICConInfo
  val nilICConInfo = listFindCon "nil"
  val nilTPConInfo = typedConInfo nilICConInfo

  val {tstrInfo=optionTstrInfo, tyCon=optionTyCon, mkTys=optionMkTys, findCon=optionFindCon} 
      = btyMap OPTIONty
  val (optionITy, optionTy) = optionMkTys nil
  val SOMEICConInfo = optionFindCon "SOME"
  val SOMETPConInfo = typedConInfo SOMEICConInfo
  val NONEICConInfo = optionFindCon "NONE"
  val NONETPConInfo = typedConInfo NONEICConInfo

  val {tstrInfo=orderTstrInfo, tyCon=orderTyCon, mkTys=orderMkTys, findCon=orderFindCon} 
      = btyMap ORDERty
  val (orderITy, orderTy) = orderMkTys nil
  val EQUALICConInfo = orderFindCon "EQUAL"
  val EQUALTPConInfo = typedConInfo EQUALICConInfo
  val LESSICConInfo = orderFindCon "LESS"
  val LESSTPConInfo = typedConInfo LESSICConInfo
  val GREATERICConInfo = orderFindCon "GREATER"
  val GREATERTPConInfo = typedConInfo GREATERICConInfo

  val {tstrInfo=serverTstrInfo, tyCon=serverTyCon, mkTys=serverMkTys, findCon=serverFindCon} 
      = btyMap SERVERty
  val (serverITy, serverTy) = serverMkTys nil
  val SERVERICConInfo = serverFindCon "SERVER"
  val SERVERTPConInfo = typedConInfo SERVERICConInfo

  val {tstrInfo=dbiTstrInfo, tyCon=dbiTyCon, mkTys=dbiMkTys, findCon=dbiFindCon} 
      = btyMap DBIty
  val (dbiITy, dbiTy) = dbiMkTys nil
  val DBIICConInfo = dbiFindCon "DBI"
  val DBITPConInfo = typedConInfo DBIICConInfo

  val {tstrInfo=valueTstrInfo, tyCon=valueTyCon, mkTys=valueMkTys, findCon=valueFindCon} 
      = btyMap VALUEty
  val (valueITy, valueTy) = valueMkTys nil
  val VALUEICConInfo = valueFindCon "VALUE"
  val VALUETPConInfo = typedConInfo VALUEICConInfo

  val {tstrInfo=connTstrInfo, tyCon=connTyCon, mkTys=connMkTys, findCon=connFindCon} 
      = btyMap CONNty
  val (connITy, connTy) = connMkTys nil

  val {tstrInfo=dbTstrInfo, tyCon=dbTyCon, mkTys=dbMkTys, findCon=dbFindCon} 
      = btyMap DBty
  val (dbITy, dbTy) = dbMkTys nil

  val {tstrInfo=tableTstrInfo, tyCon=tableTyCon, mkTys=tableMkTys, findCon=tableFindCon} 
      = btyMap TABLEty
  val (tableITy, tableTy) = tableMkTys nil

  val {tstrInfo=rowTstrInfo, tyCon=rowTyCon, mkTys=rowMkTys, findCon=rowFindCon} 
      = btyMap ROWty
  val (rowITy, rowTy) = rowMkTys nil

  val {tstrInfo=resultTstrInfo, tyCon=resultTyCon, mkTys=resultMkTys, findCon=resultFindCon} 
      = btyMap RESULTty
  val (resultITy, resultTy) = resultMkTys nil

  val {tstrInfo=relTstrInfo, tyCon=relTyCon, mkTys=relMkTys, findCon=relFindCon} 
      = btyMap RELty
  val (relITy, relTy) = relMkTys nil

  val {tstrInfo=queryTstrInfo, tyCon=queryTyCon, mkTys=queryMkTys, findCon=queryFindCon} 
      = btyMap QUERYty
  val (queryITy, queryTy) = queryMkTys nil

  val {tstrInfo=commandTstrInfo, tyCon=commandTyCon, mkTys=commandMkTys, findCon=commandFindCon} 
      = btyMap COMMANDty
  val (commandITy, commandTy) = commandMkTys nil

  fun evalExn {path, tyopt} =
      let
        val ty =
            case tyopt of
              NONE => exnTy
            | SOME ty => T.FUNMty([ty], exnTy)
      in
        {path=path, ty=ty}
      end

  val BindExExn = evalExn {path=["Bind"], tyopt=NONE}
  val MatchExExn = evalExn {path=["Match"], tyopt=NONE}
  val SubscriptExExn = evalExn {path=["Subscript"], tyopt=NONE}
  val SizeExExn = evalExn {path=["Size"], tyopt=NONE}
  val OverflowExExn = evalExn {path=["Overflow"], tyopt=NONE}
  val DivExExn = evalExn {path=["Div"], tyopt=NONE}
  val DomainExExn = evalExn {path=["Domain"], tyopt=NONE}
  val FailExExn = evalExn {path=["Fail"], tyopt=SOME (stringTy)}
  val ChrExExn = evalExn {path=["Chr"], tyopt=NONE}
  val SpanExExn = evalExn {path=["Span"], tyopt=NONE}
  val EmptyExExn = evalExn {path=["Empty"], tyopt=NONE}
  val OptionExExn = evalExn {path=["Option"], tyopt=NONE}

  (* for unification *)
  fun equalTy (ty1:bty, ty2:bty) = ty1 = ty2

  fun findTstrInfo name =
      case name of
        "int" => SOME intTstrInfo
      | "intInf" => SOME intInfTstrInfo
      | "word" => SOME wordTstrInfo
      | "word8" => SOME word8TstrInfo
      | "char" => SOME charTstrInfo
      | "string" => SOME stringTstrInfo
      | "real" => SOME realTstrInfo
      | "real32" => SOME real32TstrInfo
      | "unit" => SOME unitTstrInfo
      | "ptr" => SOME ptrTstrInfo
      | "array" => SOME arrayTstrInfo
      | "vector" => SOME vectorTstrInfo
      | "exn" => SOME exnTstrInfo
      | "boxed" => SOME boxedTstrInfo
      | "exntag" => SOME exntagTstrInfo
      | "ref" => SOME refTstrInfo
      | "bool" => SOME boolTstrInfo
      | "list" => SOME listTstrInfo
      | "option" => SOME optionTstrInfo
      | "order" => SOME orderTstrInfo
      | "server" => SOME serverTstrInfo
      | "dbi" => SOME dbiTstrInfo
      | "value" => SOME valueTstrInfo
      | "conn" => SOME connTstrInfo
      | "db" => SOME dbTstrInfo
      | "table" => SOME tableTstrInfo
      | "row" => SOME rowTstrInfo
      | "result" => SOME resultTstrInfo
      | "rel" => SOME relTstrInfo
      | "query" => SOME queryTstrInfo
      | "command" => SOME commandTstrInfo
      | _ => NONE


 (* Ohori: This is used to check the compatibility of runtimeTy of TFV_DTY against 
   that of TFUN_DTY at signature checking *)
  fun compatTy {absTy, implTy} =
      absTy = implTy orelse 
      case (absTy, implTy) of
      (BOXEDty,INTINFty) => true
    | (BOXEDty,STRINGty) => true
    | (BOXEDty,ARRAYty) => true
    | (BOXEDty,VECTORty) => true
    | (BOXEDty,EXNty) => true
    | _ => false

end
end
