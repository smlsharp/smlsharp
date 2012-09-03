(**
 * config file parser
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure SMLSharp_Config : sig

  exception Load
  val loadConfig : Filename.filename -> unit

  val CC : unit -> string
  val LD : unit -> string
  val AR : unit -> string
  val RANLIB : unit -> string
  val LDFLAGS : unit -> string
  val LIBS : unit -> string
  val DLLEXT : unit -> string
  val LIBEXT : unit -> string
  val ASMEXT : unit -> string
  val OBJEXT : unit -> string
  val NATIVE_TARGET : unit -> string
  val A_OUT : unit -> string
  val RUNLOOP_DLDFLAGS : unit -> string

end =
struct

  fun isSpace #" " = true
    | isSpace #"\t" = true
    | isSpace c = false

  fun isNameChar #"=" = false
    | isNameChar #" " = false
    | isNameChar #"\t" = false
    | isNameChar #"\r" = false
    | isNameChar #"\n" = false
    | isNameChar c = true

  fun isValueChar #"\r" = false
    | isValueChar #"\n" = false
    | isValueChar c = true

  fun skipSpace getc src =
      case getc src of
        SOME (c, src') => if isSpace c then skipSpace getc src' else src
      | NONE => src

  fun scanName getc src =
      case StringCvt.splitl isNameChar getc (StringCvt.skipWS getc src) of
        ("", src) => NONE
      | x => SOME x

  fun scanEq getc src =
      case getc (skipSpace getc src) of
        SOME (#"=", src) => SOME src
      | _ => NONE

  fun scanValue getc src =
      StringCvt.splitl isValueChar getc (skipSpace getc src)

  fun scanLine getc src =
      case scanName getc src of
        NONE => NONE
      | SOME (name, src) =>
        case scanEq getc src of
          NONE => NONE
        | SOME src =>
          case scanValue getc src of
            (value, src) => SOME (name, value, src)

  fun scanFile getc src =
      let
        fun loop (src, ret) =
            case scanLine getc src of
              SOME (name, value, src) =>
              loop (src, SEnv.insert (ret, name, value))
            | NONE =>
              case getc (StringCvt.skipWS getc src) of
                SOME _ => NONE
              | NONE => SOME (ret, src)
      in
        loop (src, SEnv.empty)
      end

  fun parse filename =
      let
        val input = Filename.TextIO.openIn filename
        val src = TextIO.inputAll input
                  handle e => (TextIO.closeIn input; raise e)
        val _ = TextIO.closeIn input
      in
        StringCvt.scanString scanFile src
      end

  val currentConfig = ref NONE : string SEnv.map option ref

  exception Load

  fun load systemBaseDir =
      let
        val filename = Filename.fromString "config.mk"
        val filename = Filename.concatPath (systemBaseDir, filename)
        val conf = parse filename handle _ => raise Load
        val conf = case conf of SOME conf => conf | NONE => raise Load
      in
        currentConfig := SOME conf;
        conf
      end

  fun loadConfig systemBaseDir =
      (load systemBaseDir; ())

  fun get (key, default) =
      let
        val conf =
            case !currentConfig of
              SOME c => c
            | NONE =>
              load (Filename.fromString SMLSharp_Version.DefaultSystemBaseDir)
      in
        case SEnv.find (conf, key) of
          NONE => default
        | SOME x => x
      end

  fun CC () = get ("CC", "cc")
  fun LD () = get ("LD", "ld")
  fun AR () = get ("AR", "ar")
  fun RANLIB () = get ("RANLIB", "ranlib")
  fun LDFLAGS () = get ("LDFLAGS", "")
  fun LIBS () = get ("LIBS", "")
  fun DLLEXT () = get ("DLLEXT", SMLSharp_Version.DefaultDLLEXT)
  fun LIBEXT () = get ("LIBEXT", SMLSharp_Version.DefaultLIBEXT)
  fun ASMEXT () = get ("ASMEXT", SMLSharp_Version.DefaultASMEXT)
  fun OBJEXT () = get ("OBJEXT", SMLSharp_Version.DefaultOBJEXT)
  fun NATIVE_TARGET () =
      get ("NATIVE_TARGET", SMLSharp_Version.DefaultNativeTarget)
  fun A_OUT () = get ("A_OUT", "a.out")
  fun RUNLOOP_DLDFLAGS () = get ("RUNLOOP_DLDFLAGS", "")

end
