(**
 * names of builtin stuffs in BuiltinContext.smi.
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *
 * Edit this file with respect to BuiltinContextCore.smi and
 * BuiltinContextSQL.smi.
 *)
structure BuiltinName :> sig

  type path

  datatype 'a env = ENV of {env: 'a, strEnv: 'a env SEnv.map}
  val find : ('a -> 'b SEnv.map) -> 'a env * path -> 'b option
  val toString : path -> string

  val intTyName : path
  val int32TyName : path
  val largeIntTyName : path
  val intInfTyName : path
  val positionTyName : path
  val wordTyName : path
  val word8TyName : path
  val word32TyName : path
  val largeWordTyName : path
  val charTyName : path
  val stringTyName : path
  val realTyName : path
  val real32TyName : path
  val real64TyName : path
  val largeRealTyName : path
  val unitTyName : path
  val ptrTyName : path
  val arrayTyName : path
  val vectorTyName : path
  val exnTyName : path
  val exntagTyName : path
  val boxedTyName : path

  val boolTyName : path
  val listTyName : path
  val optionTyName : path
  val orderTyName : path
  val refTyName : path

  val intTyPath : string list
  val int32TyPath : string list
  val largeIntTyPath : string list
  val intInfTyPath : string list
  val positionTyPath : string list
  val wordTyPath : string list
  val word8TyPath : string list
  val word32TyPath : string list
  val largeWordTyPath : string list
  val charTyPath : string list
  val stringTyPath : string list
  val realTyPath : string list
  val real32TyPath : string list
  val real64TyPath : string list
  val largeRealTyPath : string list
  val unitTyPath : string list
  val ptrTyPath : string list
  val arrayTyPath : string list
  val listTyPath : string list
  val vectorTyPath : string list
  val exnTyPath : string list
  val exntagTyPath : string list
  val boxedTyPath : string list
  val refTyPath : string list

  val falseConName : path
  val trueConName : path
  val consConName : path
  val nilConName : path
  val someConName : path
  val noneConName : path
  val refConName : path

  val matchExnName : path
  val bindExnName : path
  val subscriptExnName : path
  val divExnName : path

  val sqlServerTyName : path
  val sqlServerConName : path
  val sqlDBITyName : path
  val sqlDBIConName : path
  val sqlValueTyName : path
  val sqlValueConName : path

end =
struct

  type path = string list

  (* builtin types *)
  val intTyName = ["int"]
  val int32TyName = ["Int32", "int32"]
  val largeIntTyName = ["LargeInt", "int"]
  val intInfTyName = ["SMLSharp","IntInf","int"]
  val positionTyName = ["SMLSharp","Position","int"]
  val wordTyName = ["word"]
  val word8TyName = ["SMLSharp","Word8","word"]
  val word32TyName = ["SMLSharp","Word32","word"]
  val largeWordTyName = ["SMLSharp","LargeWord","word"]
  val charTyName = ["char"]
  val stringTyName = ["string"]
  val realTyName = ["real"]
  val real32TyName = ["SMLSharp","Real32","real"]
  val real64TyName = ["SMLSharp","Real64","real"]
  val largeRealTyName = ["SMLSharp","LargeReal","real"]
  val unitTyName = ["unit"]
  val ptrTyName = ["ptr"]
  val arrayTyName = ["array"]
  val vectorTyName = ["vector"]
  val exnTyName = ["exn"]
  val exntagTyName = ["exnTag"]
  val boxedTyName = ["SMLSharp","boxed"]

  (* datatypes *)
  val boolTyName = ["bool"]
  val listTyName = ["list"]
  val optionTyName = ["option"]
  val orderTyName = ["order"]
  val refTyName = ["ref"]

  val intTyPath = intTyName
  val int32TyPath = int32TyName
  val largeIntTyPath = largeIntTyName
  val intInfTyPath = intInfTyName
  val positionTyPath = positionTyName
  val wordTyPath = wordTyName
  val word8TyPath = word8TyName
  val word32TyPath = word32TyName
  val largeWordTyPath = largeWordTyName
  val charTyPath = charTyName
  val stringTyPath = stringTyName
  val realTyPath = realTyName
  val real32TyPath = real32TyName
  val real64TyPath = real64TyName
  val largeRealTyPath = largeRealTyName
  val unitTyPath = unitTyName
  val ptrTyPath = ptrTyName
  val arrayTyPath = arrayTyName
  val listTyPath = listTyName
  val vectorTyPath = vectorTyName
  val refTyPath = refTyName
  val exnTyPath = exnTyName
  val exntagTyPath = exntagTyName
  val boxedTyPath = boxedTyName

  (* constructors of datatypes *)
  val falseConName = ["false"]
  val trueConName = ["true"]
  val consConName = ["::"]
  val nilConName = ["nil"]
  val someConName = ["SOME"]
  val noneConName = ["NONE"]
  val refConName = ["ref"]
  val lessConName = ["LESS"]
  val equalConName = ["EQUAL"]
  val greaterConName = ["GREATER"]


  (* exceptions *)
  val bindExnName = ["Bind"]
  val matchExnName = ["Match"]
  val subscriptExnName = ["Subscript"]
  val sizeExnName = ["Size"]
  val overflowExnName = ["Overflow"]
(* 2012-1-8 ohori: added the following to match BuiltinContextCore *)
  val divExnName = ["Div"]
  val domainExnName = ["Domain"]
  val failExnName = ["Fail"]
  val chrExnName = ["Chr"]
  val spanExnName = ["Span"]
  val emptyExnName = ["Empty"]
  val optionExnName = ["Option"]

  val sqlServerTyName = ["SMLSharp","SQL","server"]
  val sqlServerConName = ["SMLSharp","SQL","SERVER"]
  val sqlDBITyName = ["SMLSharp","SQL","dbi"]
  val sqlDBIConName = ["SMLSharp","SQL","DBI"]
  val sqlValueTyName = ["SMLSharp","SQL","value"]
  val sqlValueConName = ["SMLSharp","SQL","VALUE"]

  fun toString path = String.concatWith "." path

  datatype 'a env = ENV of {env: 'a, strEnv: 'a env SEnv.map}

  fun find selector (env, nil) = NONE
    | find selector (ENV {env,...}, [name]) = SEnv.find (selector env, name)
    | find selector (ENV {strEnv,...}, strname::path) =
      case SEnv.find (strEnv, strname) of
        NONE => NONE

      | SOME env => find selector (env, path)

end
