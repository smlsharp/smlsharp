(**
 * environment for bultin stuffs.
 * @copyright (c) 2011 Tohoku University.
 * @author UENO Katsuhiro
 *)
(*
2011-12-24 Ohori:
This needs rewrite.

The environment that need to be built in consists of
the environment for name evaluation and that for 
type inference.

This module only abstract the latter. The fomer is more basic and 
the latter should be constructed based on the former.

This structure complicates initialization and builin environments.
Example is the bug 190.

*)
(*
  2012-1-7 ohori 
  * vector is added
  * removed INT32ty, LARGEINTty, POSITIONty, WORD32ty, LARGEWORDty
    REAL64ty, LARGEREALty
*)

structure BuiltinEnv : sig

  type env
  val init : env -> unit

  val exnTy : IDCalc.ty
  val unitTy : IDCalc.ty
  val exntagTy : IDCalc.ty
  val findTfun : string -> IDCalc.tfun option

  val INTty : Types.ty
  val INTINFty : Types.ty
  val WORDty : Types.ty
  val WORD8ty : Types.ty
  val CHARty : Types.ty
  val STRINGty : Types.ty
  val REALty : Types.ty
  val REAL32ty : Types.ty
  val UNITty : Types.ty
  val PTRty : Types.ty
  val ARRAYtyCon : Types.tyCon
  val VECTORtyCon : Types.tyCon
  val EXNty : Types.ty
  val BOXEDty : Types.ty
  val EXNTAGty : Types.ty
  val REFtyCon : unit -> Types.tyCon
  val LISTtyCon : unit -> Types.tyCon

  val INTtyCon : Types.tyCon
  val INTINFtyCon : Types.tyCon
  val WORDtyCon : Types.tyCon
  val WORD8tyCon : Types.tyCon
  val CHARtyCon : Types.tyCon
  val PTRtyCon : Types.tyCon
  val REALtyCon : Types.tyCon
  val REAL32tyCon : Types.tyCon
  val STRINGtyCon : Types.tyCon
  val UNITtyCon : Types.tyCon
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
  structure I = IDCalc
  structure ITy = EvalIty
                 
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
  fun makeTfun primitiveTy path = 
      let
        val id = TypID.generate()
        val iseq = B.isAdmitEquality primitiveTy
        val arity = B.arity primitiveTy
	val runtimeTy = primitiveTy
        val formals =
            case arity of
              0 => nil
            | 1 => [genTvar ("a", false)]
            | _ => raise bug "arity more than 1"
      in
        I.TFUN_VAR
          (I.mkTfv(I.TFUN_DTY {id = id,
                               iseq=iseq,
                               formals=formals,
			       runtimeTy = runtimeTy,
                               conSpec=SEnv.empty,
                               originalPath = path,
                               liftedTys=I.emptyLiftedTys,
                               dtyKind=I.BUILTIN primitiveTy
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

  val INTtfun = makeTfun B.INTty BN.intTyPath
  val INTINFtfun = makeTfun B.INTINFty BN.intInfTyPath
  val WORDtfun = makeTfun B.WORDty BN.wordTyPath
  val WORD8tfun = makeTfun B.WORD8ty BN.word8TyPath
  val CHARtfun = makeTfun B.CHARty BN.charTyPath
  val STRINGtfun = makeTfun B.STRINGty BN.stringTyPath
  val REALtfun = makeTfun B.REALty BN.realTyPath
  val REAL32tfun = makeTfun B.REAL32ty BN.real32TyPath
  val UNITtfun = makeTfun B.UNITty BN.unitTyPath
  val PTRtfun = makeTfun B.PTRty BN.ptrTyPath
  val ARRAYtfun = makeTfun B.ARRAYty BN.arrayTyPath
  val VECTORtfun = makeTfun B.VECTORty BN.vectorTyPath
  val EXNtfun = makeTfun B.EXNty BN.exnTyPath
  val BOXEDtfun = makeTfun B.BOXEDty BN.boxedTyPath
  val EXNTAGtfun = makeTfun B.EXNTAGty BN.exntagTyPath
(*
  val INT32tfun = makeTfun B.INT32ty
  val LARGEINTtfun = makeTfun B.LARGEINTty
  val POSITIONtfun = makeTfun B.POSITIONty
  val WORD32tfun = makeTfun B.WORD32ty
  val LARGEWORDtfun = makeTfun B.LARGEWORDty
  val REAL64tfun = makeTfun B.REAL64ty
  val LARGEREALtfun = makeTfun B.LARGEREALty
*)

  val INTtyCon       = ITy.evalTfun emptyContext BN.intTyPath INTtfun handle e => raise e
  val INTINFtyCon    = ITy.evalTfun emptyContext BN.intInfTyPath INTINFtfun handle e => raise e
  val WORDtyCon      = ITy.evalTfun emptyContext BN.wordTyPath WORDtfun handle e => raise e
  val WORD8tyCon     = ITy.evalTfun emptyContext BN.word8TyPath WORD8tfun handle e => raise e
  val CHARtyCon      = ITy.evalTfun emptyContext BN.charTyPath CHARtfun  handle e => raise e
  val STRINGtyCon    = ITy.evalTfun emptyContext BN.stringTyPath STRINGtfun handle e => raise e
  val REALtyCon      = ITy.evalTfun emptyContext BN.realTyPath REALtfun handle e => raise e
  val REAL32tyCon    = ITy.evalTfun emptyContext BN.real32TyPath REAL32tfun handle e => raise e
  val UNITtyCon      = ITy.evalTfun emptyContext BN.unitTyPath UNITtfun handle e => raise e
  val PTRtyCon       = ITy.evalTfun emptyContext BN.ptrTyPath PTRtfun handle e => raise e
  val ARRAYtyCon     = ITy.evalTfun emptyContext BN.arrayTyPath ARRAYtfun handle e => raise e
  val VECTORtyCon    = ITy.evalTfun emptyContext BN.vectorTyPath VECTORtfun handle e => raise e
  val EXNtyCon       = ITy.evalTfun emptyContext BN.exnTyPath EXNtfun handle e => raise e
  val BOXEDtyCon     = ITy.evalTfun emptyContext BN.boxedTyPath BOXEDtfun handle e => raise e
  val EXNTAGtyCon    = ITy.evalTfun emptyContext BN.exntagTyPath EXNTAGtfun handle e => raise e

  val INTty = T.CONSTRUCTty{tyCon=INTtyCon, args=nil}
  val INTINFty = T.CONSTRUCTty{tyCon=INTINFtyCon, args=nil}
  val WORDty = T.CONSTRUCTty{tyCon=WORDtyCon, args=nil}
  val WORD8ty = T.CONSTRUCTty{tyCon=WORD8tyCon, args=nil}
  val CHARty = T.CONSTRUCTty{tyCon=CHARtyCon, args=nil}
  val STRINGty = T.CONSTRUCTty{tyCon=STRINGtyCon, args=nil}
  val REALty = T.CONSTRUCTty{tyCon=REALtyCon, args=nil}
  val REAL32ty = T.CONSTRUCTty{tyCon=REAL32tyCon, args=nil}
  val UNITty = T.CONSTRUCTty{tyCon=UNITtyCon, args=nil}
  val EXNty = T.CONSTRUCTty{tyCon=EXNtyCon, args=nil}
  val PTRty = T.CONSTRUCTty{tyCon=PTRtyCon, args=[UNITty]}
  val BOXEDty = T.CONSTRUCTty{tyCon=BOXEDtyCon, args=nil}
  val EXNTAGty = T.CONSTRUCTty{tyCon=EXNTAGtyCon, args=nil}

  val exnTy = 
      I.TYCONSTRUCT
        {typ={path=BN.exnTyPath,tfun=EXNtfun},
         args= nil}

  val unitTy = 
      I.TYCONSTRUCT
        {typ={path=BN.unitTyPath,tfun=UNITtfun},
         args= nil}

  val exntagTy = 
      I.TYCONSTRUCT
        {typ={path=BN.exntagTyPath,tfun=EXNTAGtfun},
         args= nil}

  fun findTfun name =
      case B.findType name of
        SOME primitiveTy => 
        (case primitiveTy of
           B.INTty => SOME INTtfun
         | B.INTINFty => SOME INTINFtfun
         | B.WORDty => SOME WORDtfun
         | B.WORD8ty => SOME WORD8tfun
         | B.CHARty => SOME CHARtfun
         | B.STRINGty => SOME STRINGtfun
         | B.REALty => SOME REALtfun
         | B.REAL32ty => SOME REAL32tfun
         | B.UNITty => SOME UNITtfun
         | B.PTRty => SOME PTRtfun
         | B.ARRAYty => SOME ARRAYtfun
         | B.VECTORty => SOME VECTORtfun
         | B.EXNty => SOME EXNtfun
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

  fun LISTtyCon () = 
      lookupTyCon BuiltinName.listTyName


end
