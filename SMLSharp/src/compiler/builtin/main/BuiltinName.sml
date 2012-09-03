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
  val wordTyName : path
  val word8TyName : path
  val charTyName : path
  val stringTyName : path
  val realTyName : path
  val real32TyName : path
  val unitTyName : path
  val ptrTyName : path
  val arrayTyName : path
  val exnTyName : path
  val exntagTyName : path
  val intInfTyName : path
  val boxedTyName : path

  val intTyPath : string list
  val wordTyPath : string list
  val word8TyPath : string list
  val charTyPath : string list
  val stringTyPath : string list
  val realTyPath : string list
  val real32TyPath : string list
  val unitTyPath : string list
  val ptrTyPath : string list
  val arrayTyPath : string list
  val exnTyPath : string list
  val exntagTyPath : string list
  val intInfTyPath : string list
  val boxedTyPath : string list

  val boolTyName : path
  val listTyName : path
  val optionTyName : path
  val refTyName : path

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
  val wordTyName = ["word"]
  val word8TyName = ["SMLSharp","Word8","word"]
  val charTyName = ["char"]
  val stringTyName = ["string"]
  val realTyName = ["real"]
  val real32TyName = ["SMLSharp","Real32","real"]
  val unitTyName = ["unit"]
  val ptrTyName = ["ptr"]
  val arrayTyName = ["array"]
  val exnTyName = ["exn"]
  val exntagTyName = ["exnTag"]
  val intInfTyName = ["SMLSharp","IntInf","int"]
  val boxedTyName = ["SMLSharp","boxed"]

  val intTyPath = intTyName
  val wordTyPath = wordTyName
  val word8TyPath = word8TyName
  val charTyPath = charTyName
  val stringTyPath = stringTyName
  val realTyPath = realTyName
  val real32TyPath = real32TyName
  val unitTyPath = unitTyName
  val ptrTyPath = ptrTyName
  val arrayTyPath = arrayTyName
  val exnTyPath = exnTyName
  val exntagTyPath = exntagTyName
  val intInfTyPath = intInfTyName
  val boxedTyPath = boxedTyName

  (* datatypes *)
  val boolTyName = ["bool"]
  val listTyName = ["list"]
  val optionTyName = ["option"]
  val refTyName = ["ref"]

  (* constructors of datatypes *)
  val falseConName = ["false"]
  val trueConName = ["true"]
  val consConName = ["::"]
  val nilConName = ["nil"]
  val someConName = ["SOME"]
  val noneConName = ["NONE"]
  val refConName = ["ref"]

  (* exceptions *)
  val matchExnName = ["Match"]
  val bindExnName = ["Bind"]
  val subscriptExnName = ["Subscript"]
  val divExnName = ["Div"]

  val sqlServerTyName = ["SQL","server"]
  val sqlServerConName = ["SQL","SERVER"]
  val sqlDBITyName = ["SQL","dbi"]
  val sqlDBIConName = ["SQL","DBI"]
  val sqlValueTyName = ["SQL","value"]
  val sqlValueConName = ["SQL","VALUE"]

  fun toString path = String.concatWith "." path

  datatype 'a env = ENV of {env: 'a, strEnv: 'a env SEnv.map}

  fun find selector (env, nil) = NONE
    | find selector (ENV {env,...}, [name]) = SEnv.find (selector env, name)
    | find selector (ENV {strEnv,...}, strname::path) =
      case SEnv.find (strEnv, strname) of
        NONE => NONE
      | SOME env => find selector (env, path)

end
