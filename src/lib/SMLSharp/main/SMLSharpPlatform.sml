(**
 * information about platform on which SML# is running.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpPlatform.sml,v 1.2 2007/05/09 14:38:38 kiyoshiy Exp $
 *)
structure SMLSharpPlatform : SMLSHARP_PLATFORM =
struct

  datatype byteOrder = LittleEndian | BigEndian
  val byteOrder = if Platform_isBigEndian () then BigEndian else LittleEndian

  val host = Platform_getPlatform ()

  val (cpu, os) = Substring.splitl (fn c => c <> #"-") (Substring.full host)
  val cpu = Substring.string cpu
  val os = Substring.string (Substring.triml 1 os)

  structure Arch =
  struct

    datatype arch =
             Unknown
           | Alpha
           | AMD64
           | ARM
           | HPPA
           | IA64
           | m68k
           | MIPS
           | PowerPC
           | S390
           | Sparc
           | X86

    fun fromString string =
        case String.map Char.toUpper string of
             "ALPHA" => SOME Alpha
           | "AMD64" => SOME AMD64
           | "ARM" => SOME ARM
           | "HPPA" => SOME HPPA
           | "IA64" => SOME IA64
           | "M68K" => SOME m68k
           | "MIPS" => SOME MIPS
           | "POWERPC" => SOME PowerPC
           | "S390" => SOME S390
           | "SPARC" => SOME Sparc
           | "X86" => SOME X86
           | _ => NONE

    fun toString Alpha = "Alpha"
      | toString AMD64 = "AMD64"
      | toString ARM = "ARM"
      | toString HPPA = "HPPA"
      | toString IA64 = "IA64"
      | toString m68k = "m68k"
      | toString MIPS = "MIPS"
      | toString PowerPC = "PowerPC"
      | toString S390 = "S390"
      | toString Sparc = "Sparc"
      | toString X86 = "X86"
      | toString Unknown = "Unknown"

    val host =
        case cpu of
          "amd64" => AMD64
        | "ia64" => IA64
        | "m68k" => m68k
        | _ =>
          if String.isPrefix "alpha" cpu then Alpha
          else if String.isPrefix "arm" cpu then ARM
          else if String.isPrefix "hppa" cpu then HPPA
          else if String.isPrefix "mips" cpu then MIPS
          else if String.isPrefix "powerpc" cpu then PowerPC
          else if String.isPrefix "s390" cpu then S390
          else if String.isPrefix "sparc" cpu then Sparc
          else if String.isPrefix "x86" cpu then X86
          else if ((String.isPrefix "i" cpu
                    andalso Char.isDigit (String.sub (cpu, 1))
                    andalso String.substring (cpu, 2, 2) = "86")
                   handle _ => false) then X86
          else Unknown

  end

  structure OS =
  struct

  datatype OS =
           Unknown
         | Cygwin
         | Darwin
         | FreeBSD
         | Linux
         | MinGW
         | NetBSD
         | OpenBSD
         | Solaris

  fun fromString string =
      case String.map Char.toUpper string of
        "CYGWIN" => SOME Cygwin
      | "DARWIN" => SOME Darwin
      | "FREEBSD" => SOME FreeBSD
      | "LINUX" => SOME Linux
      | "MINGW" => SOME MinGW
      | "NETBSD" => SOME NetBSD
      | "OPENBSD" => SOME OpenBSD
      | "SOLARIS" => SOME Solaris
      | _ => NONE

  fun toString Cygwin = "Cygwin"
    | toString Darwin = "Darwin"
    | toString FreeBSD = "FreeBSD"
    | toString Linux = "Linux"
    | toString MinGW = "MinGW"
    | toString NetBSD = "NetBSD"
    | toString OpenBSD = "OpenBSD"
    | toString Solaris = "Solaris"
    | toString Unknown = "Unknown"

  val host =
      if String.isPrefix "cygwin" os then Cygwin
      else if String.isPrefix "darwin" os then Darwin
      else if String.isPrefix "freebsd" os then FreeBSD
      else if String.isPrefix "kfreebsd" os then FreeBSD (* FIXME *)
      else if String.isPrefix "linux" os then Linux
      else if String.isPrefix "mingw" os then MinGW
      else if String.isPrefix "netbsd" os then NetBSD
      else if String.isPrefix "openbsd" os then OpenBSD
      else if String.isPrefix "solaris" os then Solaris
      else if String.isPrefix "sunos" os then Solaris  (* FIXME *)
      else Unknown

  end

end;
