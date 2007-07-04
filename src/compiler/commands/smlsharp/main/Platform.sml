(**
 * information about platform on which SML# is running.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: Platform.sml,v 1.1 2007/04/12 09:39:00 kiyoshiy Exp $
 *)
structure Platform : sig val ArchName : string val OSName : string end = 
struct

  local
  val host = Configuration.Platform
  val (cpu, os) = Substring.splitl (fn c => c <> #"-") (Substring.all host)
  val cpu = Substring.string cpu
  val os = Substring.string (Substring.triml 1 os)
  in
  val ArchName = 
        case cpu of
          "amd64" => "AMD64"
        | "ia64" => "IA64"
        | "m68k" => "m68k"
        | _ =>
          if String.isPrefix "alpha" cpu then "Alpha"
          else if String.isPrefix "arm" cpu then "ARM"
          else if String.isPrefix "hppa" cpu then "HPPA"
          else if String.isPrefix "mips" cpu then "MIPS"
          else if String.isPrefix "powerpc" cpu then "PowerPC"
          else if String.isPrefix "s390" cpu then "S390"
          else if String.isPrefix "sparc" cpu then "Sparc"
          else if String.isPrefix "x86" cpu then "X86"
          else if ((String.isPrefix "i" cpu
                    andalso Char.isDigit (String.sub (cpu, 1))
                    andalso String.substring (cpu, 2, 2) = "86")
                   handle _ => false) then "X86"
          else "Unknown"

  val OSName =
      if String.isPrefix "cygwin" os then "Cygwin"
      else if String.isPrefix "darwin" os then "Darwin"
      else if String.isPrefix "freebsd" os then "FreeBSD"
      else if String.isPrefix "kfreebsd" os then "FreeBSD" (* FIXME *)
      else if String.isPrefix "linux" os then "Linux"
      else if String.isPrefix "mingw" os then "MinGW"
      else if String.isPrefix "netbsd" os then "NetBSD"
      else if String.isPrefix "openbsd" os then "OpenBSD"
      else if String.isPrefix "solaris" os then "Solaris"
      else if String.isPrefix "sunos" os then "Solaris"  (* FIXME *)
      else "Unknown"

  end

end;
