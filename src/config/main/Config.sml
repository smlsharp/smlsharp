(**
 * config file parser
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure SMLSharp_Config : sig

  exception Load
  val loadConfig : Filename.filename -> unit

  exception Unset
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

  val r_CC = ref NONE : string option ref
  val r_LD = ref NONE : string option ref
  val r_AR = ref NONE : string option ref
  val r_RANLIB = ref NONE : string option ref
  val r_LDFLAGS = ref NONE : string option ref
  val r_LIBS = ref NONE : string option ref
  val r_DLLEXT = ref NONE : string option ref
  val r_LIBEXT = ref NONE : string option ref
  val r_ASMEXT = ref NONE : string option ref
  val r_OBJEXT = ref NONE : string option ref
  val r_NATIVE_TARGET = ref NONE : string option ref
  val r_A_OUT = ref NONE : string option ref
  val r_RUNLOOP_DLDFLAGS = ref NONE : string option ref

  val parameters =
      [("CC", r_CC),
       ("LD", r_LD),
       ("AR", r_AR),
       ("RANLIB", r_RANLIB),
       ("LDFLAGS", r_LDFLAGS),
       ("LIBS", r_LIBS),
       ("DLLEXT", r_DLLEXT),
       ("LIBEXT", r_LIBEXT),
       ("ASMEXT", r_ASMEXT),
       ("OBJEXT", r_OBJEXT),
       ("NATIVE_TARGET", r_NATIVE_TARGET),
       ("A_OUT", r_A_OUT),
       ("RUNLOOP_DLDFLAGS", r_RUNLOOP_DLDFLAGS)]

  exception Unset

  local
    fun get (ref (SOME x)) = x
      | get (ref NONE) = raise Unset
  in
  fun CC () = get r_CC
  fun LD () = get r_LD
  fun AR () = get r_AR
  fun RANLIB () = get r_RANLIB
  fun LDFLAGS () = get r_LDFLAGS
  fun LIBS () = get r_LIBS
  fun DLLEXT () = get r_DLLEXT
  fun LIBEXT () = get r_LIBEXT
  fun ASMEXT () = get r_ASMEXT
  fun OBJEXT () = get r_OBJEXT
  fun NATIVE_TARGET () = get r_NATIVE_TARGET
  fun A_OUT () = get r_A_OUT
  fun RUNLOOP_DLDFLAGS () = get r_RUNLOOP_DLDFLAGS
  end

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

  exception Load

  fun loadConfig systemBaseDir =
      let
        val filename = Filename.fromString "config.mk"
        val filename = Filename.concatPath (systemBaseDir, filename)
        val conf = parse filename handle _ => raise Load
        val conf = case conf of SOME conf => conf | NONE => raise Load
      in
        app (fn (key, r) => r := SEnv.find (conf, key)) parameters;
        case SEnv.find (conf, "OS_TYPE") of
          SOME "Windows" => SMLSharp_Version.HostOS := SMLSharp_Version.Windows
        | SOME "Unix" => SMLSharp_Version.HostOS := SMLSharp_Version.Unix
        | SOME _ => raise Load
        | NONE => ()
      end

end
