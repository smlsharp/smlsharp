(**
 * predefined type constructors and their data constructors.
 *
 * @copyright (c) 2006-2008, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @version $Id: PredefinedTypes.sml,v 1.2 2009/06/18 07:10:49 katsu Exp $
 *)
structure PredefinedTypes : PREDEFINED_TYPES =
struct

  val getTyCon = BuiltinContext.getTyCon
  val getConPathInfo = BuiltinContext.getConPathInfo
  val getExnPathInfo = BuiltinContext.getExnPathInfo

  val boolTyCon = getTyCon "bool"
  val intTyCon = getTyCon "int"
  val wordTyCon = getTyCon "word"
  val charTyCon = getTyCon "char"
  val stringTyCon = getTyCon "string"
  val realTyCon = getTyCon "real"
  val floatTyCon = getTyCon "Real32.real"
  val refTyCon = getTyCon "ref"
  val listTyCon = getTyCon "list"
  val arrayTyCon = getTyCon "array"
  val largeIntTyCon = getTyCon "IntInf.int"
  val byteTyCon = getTyCon "Word8.word"
(*
  val byteArrayTyCon = getTyCon "Word8Array.array"
*)
  val unitTyCon = getTyCon "unit"
  val ptrTyCon = getTyCon "ptr"
  val optionTyCon = getTyCon "option"
  val assocDirectionTyCon = getTyCon "SMLSharp.SMLFormat.assocDirection"
  val priorityTyCon = getTyCon "SMLSharp.SMLFormat.priority"
  val expressionTyCon = getTyCon "SMLSharp.SMLFormat.expression"
  val exnTyCon = getTyCon "exn"
  val exntagTyCon = getTyCon "SMLSharp.exntag"

  (********* for convenience ********)

  val boolty = Types.RAWty {tyCon = boolTyCon, args = nil}
  val exnty = Types.RAWty {tyCon = exnTyCon, args = nil}
  val exntagty = Types.RAWty {tyCon = exntagTyCon, args = nil}
  val intty = Types.RAWty {tyCon = intTyCon, args = nil}
  val wordty = Types.RAWty {tyCon = wordTyCon, args = nil}
  val charty = Types.RAWty {tyCon = charTyCon, args = nil}
  val stringty = Types.RAWty {tyCon = stringTyCon, args = nil}
  val realty = Types.RAWty {tyCon = realTyCon, args = nil}
  val floatty = Types.RAWty {tyCon = floatTyCon, args = nil}
  val largeIntty = Types.RAWty {tyCon = largeIntTyCon, args = nil}
  val bytety = Types.RAWty {tyCon = byteTyCon, args = nil}
(*
  val byteArrayty = Types.RAWty {tyCon = byteArrayTyCon, args = nil}
*)
  val unitty = Types.RAWty {tyCon = unitTyCon, args = nil}
  val ptrty = Types.RAWty {tyCon = ptrTyCon, args = [unitty]}
  val exnty = Types.RAWty {tyCon = exnTyCon, args = nil}
  val expressionTy = Types.RAWty {tyCon = expressionTyCon, args = nil}
  val assocDirectionTy = Types.RAWty {tyCon = assocDirectionTyCon, args = nil}
  val priorityTy = Types.RAWty {tyCon = priorityTyCon, args = nil}

  val nilConPathInfo = getConPathInfo "nil"
  val consConPathInfo = getConPathInfo "::"
  val trueConPathInfo = getConPathInfo "true"
  val falseConPathInfo = getConPathInfo "false"
  val refConPathInfo = getConPathInfo "ref"
  val someConPathInfo = getConPathInfo "SOME"
  val noneConPathInfo = getConPathInfo "NONE"
  val BindExnPathInfo = getExnPathInfo "Bind"
  val MatchExnPathInfo = getExnPathInfo "Match"
  val MatchCompBugExnPathInfo = getExnPathInfo "SMLSharp.MatchCompBug"
  val FormatterExnPathInfo = getExnPathInfo "SMLSharp.SMLFormat.Formatter"
  val SubscriptExnPathInfo = getExnPathInfo "Subscript"
  val BootstrapExnPathInfo = getExnPathInfo "SMLSharp.Bootstrap"
  val neutralConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Neutral"
  val leftConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Left"
  val rightConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Right"
  val preferredConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Preferred"
  val deferredConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Deferred"
  val termConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Term"
  val guardConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Guard"
  val indicatorConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Indicator"
  val startOfIndentConPathInfo = getConPathInfo "SMLSharp.SMLFormat.StartOfIndent"
  val endOfIndentConPathInfo = getConPathInfo "SMLSharp.SMLFormat.EndOfIndent"
  val newlineConPathInfo = getConPathInfo "SMLSharp.SMLFormat.Newline"

  val assignPrimInfo =
      BuiltinPrimitiveType.primInfo
          (#topTyConEnv BuiltinContext.builtinContext)
          (BuiltinPrimitive.S BuiltinPrimitive.Assign)

  val wordMulPrimInfo =
      BuiltinPrimitiveType.primInfo
          (#topTyConEnv BuiltinContext.builtinContext)
          (BuiltinPrimitive.P BuiltinPrimitive.Word_mul)

end
