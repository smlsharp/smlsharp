(**
 * information about platform on which SML# is running.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_PLATFORM.sig,v 1.2 2007/05/09 14:38:38 kiyoshiy Exp $
 *)
signature SMLSHARP_PLATFORM =
sig

  datatype byteOrder = LittleEndian | BigEndian
  val byteOrder : byteOrder
  
  val host : string

  structure Arch :
  sig

    datatype arch =
             Alpha
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
           | Unknown
             
    val fromString : string -> arch option
    val host : arch
    val toString : arch -> string
  end
         
  structure OS :
  sig

    datatype OS =
             Cygwin
           | Darwin
           | FreeBSD
           | Linux 
           | MinGW
           | NetBSD
           | OpenBSD
           | Solaris
           | Unknown

    val fromString : string -> OS option
    val host : OS
    val toString : OS -> string
  end

end
