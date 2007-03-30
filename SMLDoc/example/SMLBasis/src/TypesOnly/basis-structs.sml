(* basis-structs.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * These are basis structures with only types, so that the basis signatures
 * can compile.
 *
 *)

structure Int31 : INTEGER =
  struct
    type int = PrimTypes.int
  end;

structure Int32 : INTEGER =
  struct
    type int = PrimTypes.int32
  end;

structure IntInf : INT_INF =
  struct
    type int = PrimTypes.intinf
  end;

structure Word8 : WORD =
  struct
    type word = PrimTypes.word8
  end;

structure Word31 : WORD =
  struct
    type word = PrimTypes.word
  end;

structure Word32 : WORD =
  struct
    type word = PrimTypes.word32
  end;

structure Real64 : REAL =
  struct
    type real = PrimTypes.real
  end;

structure String : STRING =
  struct
    type string = PrimTypes.string
  end
