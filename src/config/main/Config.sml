(**
 * config file parser
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure SMLSharp_Config : sig

  exception Load
  val loadConfig : Filename.filename -> unit

  datatype host_os = datatype SMLSharp_Version.host_os

  val CC : unit -> string
  val CXX : unit -> string
  val LD : unit -> string
  val AR : unit -> string
  val RANLIB : unit -> string
  val LDFLAGS : unit -> string
  val LIBS : unit -> string
  val DLLEXT : unit -> string
  val LIBEXT : unit -> string
  val ASMEXT : unit -> string
  val OBJEXT : unit -> string
  val TARGET_TRIPLE : unit -> string
  val A_OUT : unit -> string
  val HOST_OS_TYPE : unit -> host_os
  val CMDLINE_MAXLEN : unit -> int option
  val PIC_DEFAULT : unit -> bool
  val RUNLOOP_DLDFLAGS : unit -> string
  val EXTRA_OPTIONS : unit -> string list

end =
struct

  exception Load
  datatype host_os = datatype SMLSharp_Version.host_os

  val r_CC = ref SMLSharp_Version.DefaultConfig.CC
  val r_CXX = ref SMLSharp_Version.DefaultConfig.CXX
  val r_LD = ref SMLSharp_Version.DefaultConfig.LD
  val r_AR = ref SMLSharp_Version.DefaultConfig.AR
  val r_RANLIB = ref SMLSharp_Version.DefaultConfig.RANLIB
  val r_LDFLAGS = ref SMLSharp_Version.DefaultConfig.LDFLAGS
  val r_LIBS = ref SMLSharp_Version.DefaultConfig.LIBS
  val r_DLLEXT = ref SMLSharp_Version.DefaultConfig.DLLEXT
  val r_LIBEXT = ref SMLSharp_Version.DefaultConfig.LIBEXT
  val r_ASMEXT = ref SMLSharp_Version.DefaultConfig.ASMEXT
  val r_OBJEXT = ref SMLSharp_Version.DefaultConfig.OBJEXT
  val r_TARGET_TRIPLE = ref SMLSharp_Version.DefaultConfig.TARGET_TRIPLE
  val r_A_OUT = ref SMLSharp_Version.DefaultConfig.A_OUT
  val r_HOST_OS_TYPE = ref SMLSharp_Version.DefaultConfig.HOST_OS_TYPE
  val r_CMDLINE_MAXLEN = ref SMLSharp_Version.DefaultConfig.CMDLINE_MAXLEN
  val r_PIC_DEFAULT = ref SMLSharp_Version.DefaultConfig.PIC_DEFAULT
  val r_RUNLOOP_DLDFLAGS = ref SMLSharp_Version.DefaultConfig.RUNLOOP_DLDFLAGS
  val r_EXTRA_OPTIONS = ref nil

  fun stringToHostOS "Mingw" = Mingw
    | stringToHostOS "Unix" = Unix
    | stringToHostOS "Cygwin" = Cygwin
    | stringToHostOS _ = raise Load

  fun stringToMaxLen "NONE" = NONE
    | stringToMaxLen x =
      let
        val _ = if String.isPrefix "SOME " x then () else raise Load
        val ss = Substring.extract (x, 5, NONE)
      in
        case Int.scan StringCvt.DEC Substring.getc ss of
          NONE => raise Load
        | SOME (n, ss) => SOME n
      end

  val parameters =
      [("CC", fn x => r_CC := x),
       ("CXX", fn x => r_CXX := x),
       ("LD", fn x => r_LD := x),
       ("AR", fn x => r_AR := x),
       ("RANLIB", fn x => r_RANLIB := x),
       ("LDFLAGS", fn x => r_LDFLAGS := x),
       ("LIBS", fn x => r_LIBS := x),
       ("DLLEXT", fn x => r_DLLEXT := x),
       ("LIBEXT", fn x => r_LIBEXT := x),
       ("ASMEXT", fn x => r_ASMEXT := x),
       ("OBJEXT", fn x => r_OBJEXT := x),
       ("TARGET_TRIPLE", fn x => r_TARGET_TRIPLE := x),
       ("A_OUT", fn x => r_A_OUT := x),
       ("HOST_OS_TYPE", fn x => r_HOST_OS_TYPE := stringToHostOS x),
       ("CMDLINE_MAXLEN", fn x => r_CMDLINE_MAXLEN := stringToMaxLen x),
       ("PIC_DEFAULT", fn x => case StringCvt.scanString Bool.scan x of
                                 SOME x => r_PIC_DEFAULT := x
                               | NONE => raise Load),
       ("RUNLOOP_DLDFLAGS", fn x => r_RUNLOOP_DLDFLAGS := x),
       ("EXTRA_OPTIONS",
        fn x => r_EXTRA_OPTIONS := String.tokens Char.isSpace x)]

  fun CC () = !r_CC
  fun CXX () = !r_CXX
  fun LD () = !r_LD
  fun AR () = !r_AR
  fun RANLIB () = !r_RANLIB
  fun LDFLAGS () = !r_LDFLAGS
  fun LIBS () = !r_LIBS
  fun DLLEXT () = !r_DLLEXT
  fun LIBEXT () = !r_LIBEXT
  fun ASMEXT () = !r_ASMEXT
  fun OBJEXT () = !r_OBJEXT
  fun TARGET_TRIPLE () = !r_TARGET_TRIPLE
  fun A_OUT () = !r_A_OUT
  fun HOST_OS_TYPE () = !r_HOST_OS_TYPE
  fun CMDLINE_MAXLEN () = !r_CMDLINE_MAXLEN
  fun PIC_DEFAULT () = !r_PIC_DEFAULT
  fun RUNLOOP_DLDFLAGS () = !r_RUNLOOP_DLDFLAGS
  fun EXTRA_OPTIONS () = !r_EXTRA_OPTIONS

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

  fun loadConfig systemBaseDir =
      let
        val filename = Filename.fromString "config.mk"
        val filename = Filename.concatPath (systemBaseDir, filename)
        val conf = parse filename handle _ => raise Load
        val conf = case conf of SOME conf => conf | NONE => raise Load
      in
        app (fn (key, set) =>
                case SEnv.find (conf, key) of
                  NONE => raise Load
                | SOME s => set s)
            parameters
      end

end
