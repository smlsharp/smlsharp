(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: BUCUTILS.sig,v 1.4 2007/02/25 03:36:57 ducnh Exp $
 *)

signature BUCUTILS = sig

  val BLOCK_HEADER_SIZE : int

  val getLocOfExp : BUCCalc.bucexp -> BUCCalc.loc

  val newVar: Types.ty * BUCCalc.varKind -> BUCCalc.varInfo
  val newTLVar : Types.ty -> TypedLambda.varIdInfo

  val rootTy :  Types.ty -> Types.ty
  val convertTy : Types.ty -> Types.ty
  val convertVarInfo : BUCCalc.varKind -> TypedLambda.varIdInfo -> BUCCalc.varInfo

  val constantBitmap : Types.ty list -> Word32.word option
  val constantOffset : Types.ty list -> Word32.word option

  val arrayElementTy : Types.ty -> Types.ty
  val argTys : Types.ty -> Types.ty list
  val primArgTys : Types.ty -> Types.ty list

  val tvsTy : Types.ty -> ISet.set
  val tvsTyList : Types.ty list -> ISet.set
  val tvsExp : BUCCalc.bucexp -> ISet.set
  val tvsTypedExp : BUCCalc.bucexp * Types.ty -> ISet.set
  val tvsExpList : BUCCalc.bucexp list * Types.ty list -> ISet.set
  val tvsDecl : BUCCalc.bucdecl -> ISet.set
  val tvsDeclList : BUCCalc.bucdecl list -> ISet.set
  val tvsVarInfo : BUCCalc.varInfo -> ISet.set
  val tvsVarInfoList : BUCCalc.varInfo list -> ISet.set
  val tvsOffsetVarInfoList : BUCCalc.varInfo list -> ISet.set
  val tvsBitmapVarInfoList : BUCCalc.varInfo list -> ISet.set

  val word_constant : Word32.word * BUCCalc.loc -> BUCCalc.bucexp 
  val word_leftShift : BUCCalc.bucexp * BUCCalc.bucexp * BUCCalc.loc -> BUCCalc.bucexp 
  val word_logicalRightShift : BUCCalc.bucexp * BUCCalc.bucexp * BUCCalc.loc -> BUCCalc.bucexp 
  val word_fromInt : BUCCalc.bucexp * BUCCalc.loc -> BUCCalc.bucexp 
  val word_andb : BUCCalc.bucexp * BUCCalc.bucexp * BUCCalc.loc -> BUCCalc.bucexp 
  val word_orb : BUCCalc.bucexp * BUCCalc.bucexp * BUCCalc.loc -> BUCCalc.bucexp 
  val word_add : BUCCalc.bucexp * BUCCalc.bucexp * BUCCalc.loc -> BUCCalc.bucexp 

  val decomposeEnvRecord : Types.ty list * 'a list -> (Types.ty list * 'a list) list
  val decomposeOrdinaryRecord : bool * 'a * Types.ty list * 'a list -> (Types.ty list * 'a list) list

  val formatType : Types.ty -> string
  val formatTypeList : Types.ty list -> string

end
