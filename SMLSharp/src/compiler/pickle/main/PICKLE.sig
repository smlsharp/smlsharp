(**
 * serialize combinator based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author YAMATODANI Kiyoshi
 * @version $Id: PICKLE.sig,v 1.11 2008/01/08 03:18:51 bochao Exp $
 *)
signature PICKLE = 
sig

  (***************************************************************************)

  type instream
  type outstream

  type 'a pickler = 'a -> outstream -> unit
  type 'a unpickler = instream -> 'a

  type hash
  type 'a hasher = 'a -> hash -> hash

  type 'a isEqual = 'a * 'a -> bool

  (**
   * abstract type of pickler/unpickler data structure.
   *)
  type 'a pu

  (***************************************************************************)

  val makeInstream
      : {
          getByte : unit -> Word8.word,
          getPos : (unit -> Word32.word) option,
          seek : (Word32.word * int -> unit) option
        }
        -> instream
  val makeOutstream
      : {
          putByte : Word8.word -> unit,
          getPos : (unit -> Word32.word) option,
          seek : (Word32.word * int -> unit) option
        }
        -> outstream

  val pickle : 'a pu -> 'a -> outstream -> unit
  val unpickle : 'a pu -> instream -> 'a
  val hash : 'a pu -> 'a hasher
  val eq : 'a pu -> 'a isEqual

  (**
   * make a new pickler/unpickler.
   *)
  val make : ('a pickler * 'a unpickler * 'a hasher * 'a isEqual) -> 'a pu
(*
  (* utility *)
  (**
   * pickle a value to a string.
   *)
  val toString : 'a pu -> 'a -> string
  (**
   * unpickle a value from a string.
   *)
  val fromString : 'a pu -> string -> 'a
*)
(*
  val hashAdd : word -> hash -> hash
  val hashAddSmall : word -> hash -> hash
  val maybestop : (hash -> hash) -> hash -> hash
  val newHashTag : unit -> word
*)

  (** generate new hasher for a type constructor.
   * @params unit
   * @param unit unit
   * @return a function which generates a hasher for a value constructor of
   *        the type constructor.
   *)
  val newHashCon
      : unit -> ((** hash key of a value constructor *) int -> hash -> hash)

  (****************************************)

  (* base picklers *)
  val word : Word.word pu
  val word32 : Word32.word pu
  val int : int pu
  val int32 : Int32.int pu
  val byte : Word8.word pu
  val bool : bool pu
  val string : string pu
  val char : char pu
(*
  val real : real pu
*)

  (* pickle constructors *)
  val tuple2 : 'a pu * 'b pu -> ('a * 'b) pu
  val tuple3 : 'a pu * 'b pu * 'c pu -> ('a * 'b * 'c) pu
  val tuple4 : 'a pu * 'b pu * 'c pu * 'd pu -> ('a * 'b * 'c * 'd) pu
  val tuple5
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu -> ('a * 'b * 'c * 'd * 'e) pu
  val tuple6
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu
        -> ('a * 'b * 'c * 'd * 'e * 'f) pu
  val tuple7
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g) pu
  val tuple8
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu * 'h pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h) pu
  val tuple10
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu * 'h pu * 'i pu * 'j pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j ) pu

  val tuple11
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu * 'h pu * 'i pu * 'j pu * 'k pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k) pu

  val tuple12
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu
        * 'h pu * 'i pu * 'j pu * 'k pu * 'l pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l) pu

  val tuple13
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu
        * 'h pu * 'i pu * 'j pu * 'k pu * 'l pu * 'm pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm) pu

(*
  val vector : 'a pu -> 'a Vector.vector pu
*)

  (*
   * 'lazy' combinator delays unpickling until the object is required.
   * <p>
   * Laziness is effective only if the stream implements both getPos and seek.
   * If either of them is not implemented, the object is unpickled without
   * delay.
   * </p>
   *)
  val lazy : 'a pu -> (unit -> 'a) pu

  (* reference picklers *)
  val refCycle : 'a -> 'a pu -> 'a ref pu
  val refNonCycle : 'a pu -> 'a ref pu
  val refNonShared : 'a pu -> 'a ref pu

  (* datatype picklers *)
  val enum : ('a -> int) * 'a list -> 'a pu
  val data : ('a -> int) * ('a pu -> 'a pu) list -> 'a pu
(*
  val data2 : (
                ('a -> int) * ('a pu * 'b pu -> 'a pu) list
                * ('b -> int) * ('a pu * 'b pu -> 'b pu) list
              )
              -> 'a pu * 'b pu
*)
  (* for value constructor without argument. *)
  val con0 : 'a -> 'b -> 'a pu
  (* for value constructor with an argument. *)
  val con1 : ('a -> 'b) -> ('b -> 'a) -> 'a pu -> 'b pu

  (* useful predefined picklers *)
  val list : 'a pu -> 'a list pu
  val option : 'a pu -> 'a option pu
  val vector : 'a pu -> 'a vector pu

  (* other useful combinators *)
  val conv : ('a -> 'b) * ('b -> 'a) -> 'a pu -> 'b pu
  val share : 'a pu -> 'a pu
(*
  val reg : 'a list -> 'a pu -> 'a pu
*)

  type 'a functionRefs =
       {
         picklerRef : 'a pickler ref,
         unpicklerRef : 'a unpickler ref,
         hasherRef : 'a hasher ref,
         eqRef : 'a isEqual ref
       }

  (**
   * make a dummy pu.
   * <p>
   * Writing pu for mutual recursive datatypes requires tricky code.
   * Pickler, unpickler, and hasher refer to pu.
   * But making pu requires pickler, unpickler, and hasher.
   * So, we make at first a dummy pu.
   * Pickler, unpickler, and hasher in the dummy pu are dummy functions which
   * raise Fail always.
   * After implemented actual pickler, unpickler, and hasher, contents of the
   * dummy pu are updated to use these actual functions.
   * </p>
   *)
  val makeNullPu : 'a -> ('a functionRefs * 'a pu)

  val updateNullPu : 'a functionRefs -> 'a pu -> unit

  (***************************************************************************)

end
