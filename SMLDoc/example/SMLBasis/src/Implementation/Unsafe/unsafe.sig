(* unsafe.sig
 *
 * Copyright (c) 1997 Bell Labs, Lucent Technologies.
 *
 * Unsafe operations on ML values.
 *)

signature UNSAFE =
  sig

    structure CInterface : CINTERFACE
    structure Object : UNSAFE_OBJECT
    structure Poll : POLL

    structure Vector : UNSAFE_VECTOR
    structure Array  : UNSAFE_ARRAY

    structure CharVector : UNSAFE_MONO_VECTOR
      where type vector = CharVector.vector
      where type elem = CharVector.elem
    structure CharArray : UNSAFE_MONO_ARRAY
      where type array = CharArray.array
      where type elem = CharArray.elem

    structure Word8Vector : UNSAFE_MONO_VECTOR
      where type vector = Word8Vector.vector
      where type elem = Word8Vector.elem
    structure Word8Array : UNSAFE_MONO_ARRAY
      where type array = Word8Array.array
      where type elem = Word8Array.elem

(** once we have flat real vectors, we can include this substructure
    structure Real64Vector : UNSAFE_MONO_VECTOR
      where type vector = Real64Vector.vector
      where type elem = Real64Vector.elem
**)
    structure Real64Array : UNSAFE_MONO_ARRAY
      where type array = Real64Array.array
      where type elem = Real64Array.elem

    val getHdlr : unit -> 'a Cont.cont
    val setHdlr : 'a Cont.cont -> unit

    val getVar : unit -> 'a
    val setVar : 'a -> unit

    val getPseudo : int -> 'a
    val setPseudo : ('a * int) -> unit

    val blastRead : Word8Vector.vector -> 'a
    val blastWrite : 'a -> Word8Vector.vector

    val boxed : 'a -> bool

    val cast : 'a -> 'b

    datatype runDynEnv
      = NILrde
      | CONSrde of Word8Vector.vector * Object.object * runDynEnv

    val pStruct : runDynEnv ref

    val topLevelCont : unit Cont.cont ref

    val sigHandler : ((int * int * unit Cont.cont) -> unit Cont.cont) ref

  end;


