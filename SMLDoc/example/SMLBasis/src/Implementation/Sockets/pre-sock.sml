(* pre-sock.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * These are some common type definitions used in the sockets library.  This
 * structure is called Sock, so that the signatures will compile.
 *
 *)

local
    structure SysWord = SysWordImp
    structure Word8 = Word8Imp
    structure Word = WordImp
in
structure PreSock =
  struct

  (* the raw representation address data *)
    type addr = Word8Vector.vector

  (* the raw representation of an address family *)
    type af = CInterface.system_const

  (* the raw representation of a socket (a file descriptor for now) *)
    type socket = int

  (* an internet address; this is here because it is abstract in the
   * NetHostDB and IP structures.
   *)
    datatype in_addr = INADDR of addr

  (* an address family *)
    datatype addr_family = AF of af

  (* socket types *)
    datatype sock_type = SOCKTY of CInterface.system_const

  (* sockets are polymorphic; the instantiation of the type variables
   * provides a way to distinguish between different kinds of sockets.
   *)
    datatype ('sock, 'af) sock = SOCK of socket
    datatype 'af sock_addr = ADDR of addr

  (** Utility functions for parsing/unparsing network addresses **)
    local
      structure SysW = SysWord
      structure SCvt = StringCvt
      fun toW (getc, strm) = let
	    fun scan radix strm = (case (SysW.scan radix getc strm)
		   of NONE => NONE
		    | (SOME(w, strm)) => SOME(w, strm)
		  (* end case *))
	    in
	      case (getc strm)
	       of NONE => NONE
		| (SOME(#"0", strm')) => (case (getc strm')
		     of NONE => SOME(0w0, strm')
		      | (SOME((#"x" | #"X"), strm'')) => scan SCvt.HEX strm''
		      | _ => scan SCvt.OCT strm
		    (* end case *))
		| _ => scan SCvt.DEC strm
	      (* end case *)
	    end
  (* check that the word is representable in the given number of bits; raise
   * Overflow if not.
   *)
    fun chk (w, bits) =
	  if (SysW.>= (SysW.>>(0wxffffffff, Word.-(0w32, bits)), w))
	    then w
	    else raise General.Overflow
  (* Scan a sequence of numbers separated by #"." *)
    fun scan getc strm = (case toW (getc, strm)
	   of NONE => NONE
	    | SOME(w, strm') => scanRest getc ([w], strm')
	  (* end case *))
    and scanRest getc (l, strm) = (case getc strm
	   of SOME(#".", strm') => (case toW (getc, strm')
		 of NONE => SOME(List.rev l, strm)
		  | SOME(w, strm'') => scanRest getc (w::l, strm'')
		(* end case *))
	    | _ => SOME(List.rev l, strm)
	  (* end case *))
    in
    fun toWords getc strm = (case (scan getc strm)
	   of SOME([a, b, c, d], strm) => 
		SOME([chk(a, 0w8), chk(b, 0w8), chk(c, 0w8), chk(d, 0w8)], strm)
	    | SOME([a, b, c], strm) =>
		SOME([chk(a, 0w8), chk(b, 0w8), chk(c, 0w16)], strm)
	    | SOME([a, b], strm) =>
		SOME([chk(a, 0w8), chk(b, 0w24)], strm)
	    | SOME([a], strm) =>
		SOME([chk(a, 0w32)], strm)
	    | _ => NONE
	  (* end case *))
    fun fromBytes (a, b, c, d) = let
	  val fmt = Word8.fmt StringCvt.DEC
	  in
	    concat [fmt a, ".", fmt b, ".", fmt c, ".", fmt d]
	  end
    end

  end (* PreSock *)
end

(* We alias this structure to Socket so that the signature files will compile.
 * We also need to keep the PreSock structure visible, so that structures
 * compiled after the real Sock structure still have access to the representation
 * types.
 *)
structure Socket = PreSock;


