(**
 * predefined type constructors and their data constructors.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @version $Id: PREDEFINED_TYPES.sig,v 1.2 2009/06/18 07:10:49 katsu Exp $
 *)
signature PREDEFINED_TYPES =
sig

  val boolTyCon : Types.tyCon
  val intTyCon : Types.tyCon
  val wordTyCon : Types.tyCon
  val charTyCon : Types.tyCon
  val stringTyCon : Types.tyCon
  val realTyCon : Types.tyCon
  val floatTyCon : Types.tyCon
  val exnTyCon : Types.tyCon
  val exntagTyCon : Types.tyCon
  val refTyCon : Types.tyCon
  val listTyCon : Types.tyCon
  val arrayTyCon : Types.tyCon
  val largeIntTyCon : Types.tyCon
  val byteTyCon : Types.tyCon
(*
  val byteArrayTyCon : Types.tyCon
*)
  val optionTyCon : Types.tyCon
  val unitTyCon : Types.tyCon
  val ptrTyCon : Types.tyCon
  val assocDirectionTyCon : Types.tyCon
  val priorityTyCon : Types.tyCon
  val expressionTyCon : Types.tyCon

  val sqlServerConPathInfo : Types.conPathInfo
  val sqlValueConPathInfo : Types.conPathInfo
  val sqlDBIConPathInfo : Types.conPathInfo
  val sqlServerTyCon : Types.tyCon
  val sqlValueTyCon : Types.tyCon
  val sqlDBITyCon : Types.tyCon
  val toSQLOPrimInfo : Types.oprimInfo

  val boolty : Types.ty
  val exnty : Types.ty
  val exntagty : Types.ty
  val intty : Types.ty
  val wordty : Types.ty
  val charty : Types.ty
  val stringty : Types.ty
  val realty : Types.ty
  val floatty : Types.ty
  val largeIntty : Types.ty
  val bytety : Types.ty
(*
  val byteArrayty : Types.ty
*)
  val unitty : Types.ty
  val ptrty :  Types.ty
  val expressionTy :  Types.ty
  val assocDirectionTy : Types.ty
  val priorityTy : Types.ty

  val nilConPathInfo : Types.conPathInfo
  val consConPathInfo : Types.conPathInfo

  val trueConPathInfo : Types.conPathInfo
  val falseConPathInfo : Types.conPathInfo

  val someConPathInfo : Types.conPathInfo
  val noneConPathInfo : Types.conPathInfo

  val neutralConPathInfo  : Types.conPathInfo
  val leftConPathInfo  : Types.conPathInfo
  val rightConPathInfo  : Types.conPathInfo

  val preferredConPathInfo : Types.conPathInfo
  val deferredConPathInfo : Types.conPathInfo

  val termConPathInfo : Types.conPathInfo
  val guardConPathInfo: Types.conPathInfo
  val indicatorConPathInfo: Types.conPathInfo
  val startOfIndentConPathInfo: Types.conPathInfo
  val endOfIndentConPathInfo: Types.conPathInfo
  val newlineConPathInfo: Types.conPathInfo

  val refConPathInfo : Types.conPathInfo

  val BindExnPathInfo : Types.exnPathInfo
  val MatchExnPathInfo : Types.exnPathInfo
  val MatchCompBugExnPathInfo : Types.exnPathInfo
  val FormatterExnPathInfo : Types.exnPathInfo
  val SubscriptExnPathInfo : Types.exnPathInfo
  val BootstrapExnPathInfo : Types.exnPathInfo

  val assignPrimInfo : Types.primInfo
  val wordMulPrimInfo : Types.primInfo
  val stringArrayPrimInfo : Types.primInfo
  val stringCopyUnsafePrimInfo : Types.primInfo
  val stringSizePrimInfo : Types.primInfo
  val intAddPrimInfo : Types.primInfo

end
