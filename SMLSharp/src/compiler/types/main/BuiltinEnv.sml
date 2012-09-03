(**
 * environment for bultin stuffs.
 * @copyright (c) 2011 Tohoku University.
 * @author UENO Katsuhiro
 *)
structure BuiltinEnv : sig

  type env
  val init : env -> unit

  val exnTy : IDTypes.ty
  val unitTy : IDTypes.ty
  val exntagTy : IDTypes.ty
  val findTfun : string -> IDTypes.tfun option

  val CHARty : Types.ty
  val INTty : Types.ty
  val INTINFty : Types.ty
  val PTRty : Types.ty
  val REALty : Types.ty
  val REAL32ty : Types.ty
  val STRINGty : Types.ty
  val UNITty : Types.ty
  val WORD8ty : Types.ty
  val WORDty : Types.ty
  val ARRAYtyCon : Types.tyCon
  val REFtyCon : unit -> Types.tyCon
  val EXNty : Types.ty
  val BOXEDty : Types.ty
  val EXNTAGty : Types.ty

  val CHARtyCon : Types.tyCon
  val INTtyCon : Types.tyCon
  val INTINFtyCon : Types.tyCon
  val PTRtyCon : Types.tyCon
  val REALtyCon : Types.tyCon
  val REAL32tyCon : Types.tyCon
  val STRINGtyCon : Types.tyCon
  val UNITtyCon : Types.tyCon
  val WORD8tyCon : Types.tyCon
  val WORDtyCon : Types.tyCon
  val EXNtyCon : Types.tyCon
  val BOXEDtyCon : Types.tyCon
  val EXNTAGtyCon : Types.tyCon

  val lookupTyCon : BuiltinName.path -> Types.tyCon
  val lookupCon : BuiltinName.path -> Types.conInfo
  val lookupExn : BuiltinName.path -> Types.exExnInfo
  val findExn : BuiltinName.path -> Types.exExnInfo option

end =
struct

  structure B = BuiltinType
  structure BN = BuiltinName
  structure T = Types
  structure IT = IDTypes
  structure ET = EvalIty
                 
  type path = string list
  type primInfo = T.primInfo
  type conInfo = T.conInfo
  fun bug s = Control.Bug ("BuiltinEnv: " ^ s)
  fun genTvar (name, eq) =
      let
        val id = TvarID.generate()
        val eq = if eq then Absyn.EQ else Absyn.NONEQ
      in
        {name=name,eq=eq,id=id,lifted=false}
      end
  fun makeTfun primitiveTy = 
      let
        val id = TypID.generate()
        val iseq = B.isAdmitEquality primitiveTy
        val arity = B.arity primitiveTy
        val formals =
            case arity of
              0 => nil
            | 1 => [genTvar ("a", iseq)]
            | _ => raise bug "arity more than 1"
      in
        IT.TFUN_VAR
          (IT.mkTfv(IT.TFUN_DTY {id = id,
                                 iseq=iseq,
                                 formals=formals,
                                 conSpec=SEnv.empty,
                                 liftedTys=IT.emptyLiftedTys,
                                 dtyKind=IT.BUILTIN primitiveTy
                                }
                  )
          )
      end
  val emptyContext = 
      {
       tvarEnv = TvarMap.empty,
       varEnv = VarMap.empty,
       oprimEnv = OPrimMap.empty
       } 

  val INTtfun = makeTfun B.INTty
  val WORDtfun = makeTfun B.WORDty
  val WORD8tfun = makeTfun B.WORD8ty
  val CHARtfun = makeTfun B.CHARty
  val STRINGtfun = makeTfun B.STRINGty
  val REALtfun = makeTfun B.REALty
  val REAL32tfun = makeTfun B.REAL32ty
  val UNITtfun = makeTfun B.UNITty
  val PTRtfun = makeTfun B.PTRty
  val ARRAYtfun = makeTfun B.ARRAYty 
  val EXNtfun = makeTfun B.EXNty
  val INTINFtfun = makeTfun B.INTINFty
  val BOXEDtfun = makeTfun B.BOXEDty
  val EXNTAGtfun = makeTfun B.EXNTAGty

  val INTtyCon = ET.evalTfun emptyContext BN.intTyPath INTtfun
  val WORDtyCon = ET.evalTfun emptyContext BN.wordTyPath WORDtfun
  val WORD8tyCon = ET.evalTfun emptyContext BN.word8TyPath WORD8tfun
  val CHARtyCon = ET.evalTfun emptyContext BN.charTyPath CHARtfun 
  val STRINGtyCon = ET.evalTfun emptyContext BN.stringTyPath STRINGtfun 
  val REALtyCon = ET.evalTfun emptyContext BN.realTyPath REALtfun 
  val REAL32tyCon = ET.evalTfun emptyContext BN.real32TyPath REAL32tfun 
  val UNITtyCon = ET.evalTfun emptyContext BN.unitTyPath UNITtfun 
  val PTRtyCon = ET.evalTfun emptyContext BN.ptrTyPath PTRtfun 
  val ARRAYtyCon = ET.evalTfun emptyContext BN.arrayTyPath ARRAYtfun 
  val EXNtyCon = ET.evalTfun emptyContext BN.exnTyPath EXNtfun 
  val INTINFtyCon = ET.evalTfun emptyContext BN.intInfTyPath INTINFtfun 
  val BOXEDtyCon = ET.evalTfun emptyContext BN.boxedTyPath BOXEDtfun 
  val EXNTAGtyCon = ET.evalTfun emptyContext BN.exntagTyPath EXNTAGtfun 

  val INTty = T.CONSTRUCTty{tyCon=INTtyCon, args=nil}
  val WORDty = T.CONSTRUCTty{tyCon=WORDtyCon, args=nil}
  val WORD8ty = T.CONSTRUCTty{tyCon=WORD8tyCon, args=nil}
  val CHARty = T.CONSTRUCTty{tyCon=CHARtyCon, args=nil}
  val STRINGty = T.CONSTRUCTty{tyCon=STRINGtyCon, args=nil}
  val REALty = T.CONSTRUCTty{tyCon=REALtyCon, args=nil}
  val REAL32ty = T.CONSTRUCTty{tyCon=REAL32tyCon, args=nil}
  val UNITty = T.CONSTRUCTty{tyCon=UNITtyCon, args=nil}
  val EXNty = T.CONSTRUCTty{tyCon=EXNtyCon, args=nil}
  val PTRty = T.CONSTRUCTty{tyCon=PTRtyCon, args=[UNITty]}
  val INTINFty = T.CONSTRUCTty{tyCon=INTINFtyCon, args=nil}
  val BOXEDty = T.CONSTRUCTty{tyCon=BOXEDtyCon, args=nil}
  val EXNTAGty = T.CONSTRUCTty{tyCon=EXNTAGtyCon, args=nil}


  val exnTy = 
      IT.TYCONSTRUCT
        {typ={path=BN.exnTyPath,tfun=EXNtfun},
         args= nil}

  val unitTy = 
      IT.TYCONSTRUCT
        {typ={path=BN.unitTyPath,tfun=UNITtfun},
         args= nil}

  val exntagTy = 
      IT.TYCONSTRUCT
        {typ={path=BN.exntagTyPath,tfun=EXNTAGtfun},
         args= nil}

  fun findTfun name =
      case B.findType name of
        SOME primitiveTy => 
        (case primitiveTy of
           B.INTty => SOME INTtfun
         | B.WORDty => SOME WORDtfun
         | B.WORD8ty => SOME WORD8tfun
         | B.CHARty => SOME CHARtfun
         | B.STRINGty => SOME STRINGtfun
         | B.REALty => SOME REALtfun
         | B.REAL32ty => SOME REAL32tfun
         | B.UNITty => SOME UNITtfun
         | B.PTRty => SOME PTRtfun
         | B.ARRAYty => SOME ARRAYtfun
         | B.EXNty => SOME EXNtfun
         | B.INTINFty => SOME INTINFtfun
         | B.BOXEDty => SOME BOXEDtfun
         | B.EXNTAGty => SOME EXNTAGtfun
        )
      | _ => NONE

  type env =
      {
        tyConEnv : Types.tyCon SEnv.map,
        conEnv : conInfo SEnv.map,
        exnEnv : Types.exExnInfo SEnv.map,
        primEnv : primInfo SEnv.map
      }
      BuiltinName.env

  val globalBuiltinEnv = ref NONE : env option ref

  fun builtinEnv ()  =
      case !globalBuiltinEnv of
        SOME env => env
      | NONE => raise Control.Bug "BuiltinEnv: uninitialized"

  fun init env =
      case !globalBuiltinEnv of
        NONE => globalBuiltinEnv := SOME env
      | SOME _ => raise Control.Bug "BuiltinEnv.init: already initialized"

  fun findTyCon path =
      BuiltinName.find #tyConEnv (builtinEnv (), path)
  fun findCon path =
      BuiltinName.find #conEnv (builtinEnv (), path)
  fun findExn path =
      BuiltinName.find #exnEnv (builtinEnv (), path)
  fun findPrim path =
      BuiltinName.find #primEnv (builtinEnv (), path)

  fun lookupTyCon path =
      case findTyCon path of
        SOME x => x
      | NONE => raise Control.Bug ("BuiltinEnv.lookupTyCon: " ^
                                   BuiltinName.toString path)
  fun lookupCon path =
      case findCon path of
        SOME x => x
      | NONE => raise Control.Bug ("BuiltinEnv.lookupCon: " ^
                                   BuiltinName.toString path)
  fun lookupExn path =
      case findExn path of
        SOME x => x
      | NONE => raise Control.Bug ("BuiltinEnv.lookupExn: " ^
                                   BuiltinName.toString path)
  fun lookupPrim path =
      case findPrim path of
        SOME x => x
      | NONE => raise Control.Bug ("BuiltinEnv.lookupPrim: " ^
                                   BuiltinName.toString path)

  fun REFtyCon () = 
      lookupTyCon BuiltinName.refTyName

end
