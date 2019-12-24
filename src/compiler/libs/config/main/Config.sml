(**
 * config file parser
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Config : sig

  exception Load of exn
  exception Config
  exception Parse
  val loadConfig : Filename.filename -> unit

  datatype host_os = Mingw | Cygwin | Unix

  val CC : unit -> string
  val CXX : unit -> string
  val LD : unit -> string
  val AR : unit -> string
  val RANLIB : unit -> string
  val LLC : unit -> string
  val OPT : unit -> string
  val LLVM_AS : unit -> string
  val LLVM_DIS : unit -> string
  val LDFLAGS : unit -> string
  val LIBS : unit -> string
  val DLLEXT : unit -> string
  val LIBEXT : unit -> string
  val ASMEXT : unit -> string
  val OBJEXT : unit -> string
  val A_OUT : unit -> string
  val HOST_OS_TYPE : unit -> host_os
  val CMDLINE_MAXLEN : unit -> int option
  val PIC_DEFAULT : unit -> bool
  val RUNLOOP_DLDFLAGS : unit -> string
  val EXTRA_OPTIONS : unit -> string list

end =
struct

  exception Load of exn
  exception Config
  exception Parse
  datatype host_os = Mingw | Cygwin | Unix

  fun notInit () = raise Config

  val r_CC = ref notInit
  val r_CXX = ref notInit
  val r_LD = ref notInit
  val r_AR = ref notInit
  val r_RANLIB = ref notInit
  val r_LLC = ref notInit
  val r_OPT = ref notInit
  val r_LLVM_AS = ref notInit
  val r_LLVM_DIS = ref notInit
  val r_LDFLAGS = ref notInit
  val r_LIBS = ref notInit
  val r_DLLEXT = ref notInit
  val r_LIBEXT = ref notInit
  val r_ASMEXT = ref notInit
  val r_OBJEXT = ref notInit
  val r_A_OUT = ref notInit
  val r_HOST_OS_TYPE = ref notInit
  val r_CMDLINE_MAXLEN = ref notInit
  val r_PIC_DEFAULT = ref notInit
  val r_RUNLOOP_DLDFLAGS = ref notInit
  val r_EXTRA_OPTIONS = ref notInit

  fun stringToHostOS "Mingw" = Mingw
    | stringToHostOS "Unix" = Unix
    | stringToHostOS "Cygwin" = Cygwin
    | stringToHostOS _ = raise Parse

  fun stringToMaxLen "NONE" = NONE
    | stringToMaxLen x =
      let
        val _ = if String.isPrefix "SOME " x then () else raise Parse
        val ss = Substring.extract (x, 5, NONE)
      in
        case Int.scan StringCvt.DEC Substring.getc ss of
          NONE => raise Parse
        | SOME (n, ss) => SOME n
      end

  fun k x () = x

  val parameters =
      [("CC", fn x => r_CC := k x),
       ("CXX", fn x => r_CXX := k x),
       ("LD", fn x => r_LD := k x),
       ("AR", fn x => r_AR := k x),
       ("RANLIB", fn x => r_RANLIB := k x),
       ("LLC", fn x => r_LLC := k x),
       ("OPT", fn x => r_OPT := k x),
       ("LLVM_AS", fn x => r_LLVM_AS := k x),
       ("LLVM_DIS", fn x => r_LLVM_DIS := k x),
       ("LDFLAGS", fn x => r_LDFLAGS := k x),
       ("LIBS", fn x => r_LIBS := k x),
       ("DLLEXT", fn x => r_DLLEXT := k x),
       ("LIBEXT", fn x => r_LIBEXT := k x),
       ("ASMEXT", fn x => r_ASMEXT := k x),
       ("OBJEXT", fn x => r_OBJEXT := k x),
       ("A_OUT", fn x => r_A_OUT := k x),
       ("HOST_OS_TYPE", fn x => r_HOST_OS_TYPE := k (stringToHostOS x)),
       ("CMDLINE_MAXLEN", fn x => r_CMDLINE_MAXLEN := k (stringToMaxLen x)),
       ("PIC_DEFAULT", fn x => case StringCvt.scanString Bool.scan x of
                                 SOME x => r_PIC_DEFAULT := k x
                               | NONE => raise Parse),
       ("RUNLOOP_DLDFLAGS", fn x => r_RUNLOOP_DLDFLAGS := k x),
       ("EXTRA_OPTIONS",
        fn x => r_EXTRA_OPTIONS := k (String.tokens Char.isSpace x))]

  fun CC () = !r_CC ()
  fun CXX () = !r_CXX ()
  fun LD () = !r_LD ()
  fun AR () = !r_AR ()
  fun RANLIB () = !r_RANLIB ()
  fun LLC () = !r_LLC ()
  fun OPT () = !r_OPT ()
  fun LLVM_AS () = !r_LLVM_AS ()
  fun LLVM_DIS () = !r_LLVM_DIS ()
  fun LDFLAGS () = !r_LDFLAGS ()
  fun LIBS () = !r_LIBS ()
  fun DLLEXT () = !r_DLLEXT ()
  fun LIBEXT () = !r_LIBEXT ()
  fun ASMEXT () = !r_ASMEXT ()
  fun OBJEXT () = !r_OBJEXT ()
  fun A_OUT () = !r_A_OUT ()
  fun HOST_OS_TYPE () = !r_HOST_OS_TYPE ()
  fun CMDLINE_MAXLEN () = !r_CMDLINE_MAXLEN ()
  fun PIC_DEFAULT () = !r_PIC_DEFAULT ()
  fun RUNLOOP_DLDFLAGS () = !r_RUNLOOP_DLDFLAGS ()
  fun EXTRA_OPTIONS () = !r_EXTRA_OPTIONS ()

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
        SOME (c, src') => if Char.isSpace c then skipSpace getc src' else src
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
      case getc src of
        SOME (#"#", _) => SOME NONE
      | _ =>
        case scanName getc src of
          NONE => NONE
        | SOME (name, src) =>
          case scanEq getc src of
            NONE => NONE
          | SOME src =>
            case scanValue getc src of
              (value, src) => SOME (SOME (name, value))

  fun parse filename =
      let
        val input = Filename.TextIO.openIn filename
        fun loop z =
            case TextIO.inputLine input of
              NONE => z
            | SOME line =>
              case scanLine Substring.getc (Substring.full line) of
                NONE => raise Parse
              | SOME (SOME (key, value)) =>
                loop (SEnv.insert (z, key, value))
              | SOME NONE => loop z
        val values = loop SEnv.empty
                     handle e => (TextIO.closeIn input; raise e)
      in
        TextIO.closeIn input;
        values
      end

  fun loadConfig filename =
      let
        val conf = parse filename handle e => raise Load e
      in
        app (fn (key, set) =>
                case SEnv.find (conf, key) of
                  NONE => raise Load Parse
                | SOME s => set s)
            parameters;
        SMLSharp_SQL_Config.DLLEXT := DLLEXT ()
      end

end
