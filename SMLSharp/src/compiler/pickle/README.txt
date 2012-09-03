How to define pickler for your defined type/datatype.

$Id: README.txt,v 1.3 2007/07/05 13:23:58 kiyoshiy Exp $
$Author: kiyoshiy $

 Pickle structure defines 'a pu, which is combinator to Pickle and Unpickle values of 'a types.

  signature PICKLE =
  sig
    type 'a pu
  end

This memo describes how to define pickler for your defined type/datatype using this Pickle structure.

----------
basic types

 Pickle defines pickle combinators for basic types.

  val word : Word.word pu
  val word32 : Word32.word pu
  val int : int pu
  val int32 : Int32.int pu
  val byte : Word8.word pu
  val bool : bool pu
  val string : string pu
  val char : char pu

For tuple types.

  val tuple2 : 'a pu * 'b pu -> ('a * 'b) pu
         :
  val tuple8
      : 'a pu * 'b pu * 'c pu * 'd pu * 'e pu * 'f pu * 'g pu * 'h pu
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h) pu

For some common datatypes.

  val list : 'a pu -> 'a list pu
  val option : 'a pu -> 'a option pu
  val vector : 'a pu -> 'a vector pu

Utility combinator.

  val conv : ('a -> 'b) * ('b -> 'a) -> 'a pu -> 'b pu

----------
tuple and record type

 Combinator for a tuple type is simply constructed using tupleN combinators of Pickle.

  structure P = Pickle

  type t = int * bool

  val pu_t : t P.pu = P.tuple2 (P.int, P.bool)

A record is converted to a tuple before pickled, vice versa after unpickled, using the 'conv' combinator.

  type r = {x : int, y : bool}

  val pu_r = 
           P.conv 
               (fn (x, y) => {x = x, y = y}, fn {x, y} => (x, y)) 
               (P.tuple2 (P.int, P.bool))

----------
- non recursive datatype, self recursive datatype

 For user defined datatypes, Pickle provides following combinators.

  val data : ('a -> int) * ('a pu -> 'a pu) list -> 'a pu
  val con0 : 'a -> 'b -> 'a pu
  val con1 : ('a -> 'b) -> ('b -> 'a) -> 'a pu -> 'b pu

With these combinators, you can define combinator for your datatype.
First, define a function to convert a value constructor into an integer.
Then, define combinators for each value constructors in your datatype, using con0 and con1. For a value constructor with no argument, use con0. For a value constructor with an argument, use con1.
Last, compose them by using 'data' to define a combinator for the datatype.

  datatype dt = D | E of int | F of dt

  local
    fun dtToInt D = 0
      | dtToInt (E _) = 1
      | dtToInt (F _) = 2
    fun pu_D pu_dt = P.con0 D pu_dt
    fun pu_E pu_dt = P.con1 (fn n => E n) (fn (E n) => n) P.int
    fun pu_F pu_dt = P.con1 (fn dt => F dt) (fn (F dt) => dt) pu_dt
  in
  val pu_dt = P.data (dtToInt, [pu_D, pu_E, pu_F])
  end

Each function pu_d for a value constructor d takes an argument, which is a pickle combinator for the datatype for which pu is defined now. As seen in body of pu_F, this passed pickle combinator is used to construct pu for recursively defined datatype.

It is a point to notice that if dtToInt returns n for a constructor d, pu_d must be the n-th element of the combinators list.
You have to take care to match two arguments for 'Pickle.data' consistent.
In this example, the first argument 'dtToInt' returns integer between 0 and 2, so, the second argument should have 3 elements. It has 3 elements [pu_D, pu_E, pu_F] actually.
If there is inconsistency in your defined pickler, you will encounter an Subscript error in unpickling as follows

  $ smlsharp
  Error:subscript out of bounds
  Main.sml:656.58-656.61
  ../../../pickle/main/Pickle.sml:421.27-421.37

----------
- mutual-recursive datatypes

In order to define pickle combinator for mutual recursive datatypes, we have to build recursive connection between those combinators manually.

First, create a pu, by using 'makeNullPu'. 
At this time, It is empty. Its members do nothing.
Then, define actual combinators for each datatype, using these empty pu.
Last, update empty pu with actual combinators by 'updateNullPu'.

  type 'a functionRefs =
  val makeNullPu : 'a -> ('a functionRefs * 'a pu)
  val updateNullPu : 'a functionRefs -> 'a pu -> unit

For example, assume two recursively defined datatypes.

  datatype dt1 = D | E of dt2
       and dt2 = F of dt1

Combinators for them are defined as follows.

  val (functions_dt1, pu_dt1) = P.makeNullPu D
  val (functions_dt2, pu_dt2) = P.makeNullPu (F D)

  val newPu_dt1 : dt1 P.pu =
      let
        fun dt1ToInt D = 0
          | dt1ToInt (E _) = 1
        fun pu_D pu_dt1 = P.con0 D pu_dt1
        fun pu_E pu_dt1 = P.con1 (fn n => E n) (fn (E n) => n) pu_dt2
      in
        P.data (dt1ToInt, [pu_D, pu_E])
      end

  val newPu_dt2 : dt2 P.pu =
      let
        fun dt2ToInt (F _) = 0
        fun pu_F pu_dt2 = P.con1 (fn dt1 => F dt1) (fn (F dt1) => dt1) pu_dt1
      in
        P.data (dt2ToInt, [pu_F])
      end
        
  val _ = P.updateNullPu functions_dt1 newPu_dt1
  val _ = P.updateNullPu functions_dt2 newPu_dt2

Then, we obtain true combinators pu_dt1 and pu_dt2.

