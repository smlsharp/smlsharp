(* object.sig
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *)

signature UNSAFE_OBJECT =
  sig
    type object

  (* information about the memory representation of an object.
   * NOTE: some of these are not supported yet, but will be once the new
   * array representation is available.
   *)
    datatype representation
      = Unboxed
      | Word32
      | Real
      | Pair
      | Record
      | Ref
      | PolyVector
      | PolyArray	(* includes ref *)
      | ByteVector	(* includes Word8Vector.vector and CharVector.vector *)
      | ByteArray	(* includes Word8Array.array and CharArray.array *)
(*      | RealVector	use PolyVector for now *)
      | RealArray
      | Susp
      | WeakPtr

    val toObject : 'a -> object

    val mkTuple : object list -> object

    val boxed : object -> bool
    val unboxed : object -> bool
    val rep : object -> representation

    val length : object -> int
	(* returns length part of descriptor (untagged pairs return 2);
	 * raises Representation on unboxed values.
	 *)

    exception Representation
    val toTuple  : object -> object list
    val toString : object -> string
    val toRef    : object -> object ref
    val toArray  : object -> object array
    val toRealArray  : object -> Real64Array.array
    val toByteArray  : object -> Word8Array.array
    val toVector : object -> object vector
    val toByteVector : object -> Word8Vector.vector
    val toExn    : object -> exn
    val toReal   : object -> real
    val toInt    : object -> int
    val toInt32  : object -> Int32.int
    val toWord   : object -> Word.word
    val toWord8  : object -> Word8.word
    val toWord32 : object -> Word32.word

  (* fetch nth element of tuple *)
    val nth	 : (object * int) -> object

  end;


