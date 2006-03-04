(*
 * loads modules of Basis library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: basis.sml,v 1.69 2006/03/03 14:18:40 kiyoshiy Exp $
 *)

(* NOTE : Prefix "../main/" is specified in order to enable SML/NJ to load
 * Basis from "test" directory. *)

(*****************************************************************************)

(* infixes specified in the SML Definition are hard-coded in staticevn.sml *)
infix 6 ^;
infixr 5 @;
infix 4 <>;
infix 3 o;
infix 0 before;

(*****************************************************************************)

(* bindings used by basic formatters definition. *)

fun not true = false
  | not fasle = true;

fun x <> y = not(x = y);

fun rev list =
    let
      fun accum [] result = result
        | accum (head :: tail) result = accum tail (head :: result)
    in accum list [] end;

fun map f list =
    let
      fun accum [] result = rev result
        | accum (hd :: tl) result = accum tl ((f hd) :: result)
    in accum list []
    end;

fun foldl f initial list =
    let
      fun accum [] result = result
        | accum (hd :: tl) result = accum tl (f (hd, result))
    in accum list initial end;

fun foldr f initial list =
    let
      fun accum [] result  = result
        | accum (hd :: tl) result = f (hd, accum tl result)
    in accum list initial end;

val sub = String_sub

val size = String_size

val op ^ = String_concat2

fun explode string =
    let
      fun accum 0 chars = chars
        | accum n chars = accum (n - 1) (sub (string, n - 1) :: chars)
    in accum (size string) [] end;

fun implode chars =
    let
      fun scan [] accum = accum
        | scan (char :: chars) accum =
          scan chars (accum ^ (Char_toString char))
    in scan chars ""
    end;

use "./BasicFormatters.sml";

exception Unimplemented of string;

(* for FFI *)

type void = int;

(*****************************************************************************)

use "./GENERAL.sig";
use "./General.sml";
type unit = General.unit;
datatype order = datatype General.order;
(*
type exn = General.exn;
*)
exception Bind = General.Bind;
exception Chr = General.Chr;
exception Div = General.Div;
exception Domain = General.Domain;
exception Fail = General.Fail;
exception Match = General.Match;
exception Overflow = General.Overflow;
exception Size = General.Size;
exception Span = General.Span;
exception Subscript = General.Subscript;
val ! = General.!;
val op := = General.:=;
val op before = General.before;
val exnMessage = General.exnMessage;
val exnName = General.exnName;
val ignore = General.ignore;
val op o = General.o;

use "./OPTION.sig";
use "./Option.sml";
datatype option = datatype Option.option;
exception Option = Option.Option
val getOpt = Option.getOpt;
val isSome = Option.isSome;
val valOf = Option.valOf;

use "./LIST.sig";
use "./List.sml";
(*
structure List = List : LIST;
*)
exception Empty = List.Empty;
datatype list = datatype List.list;
val op @ = List.@;
val app = List.app;
val foldl = List.foldl;
val foldr = List.foldr;
val hd = List.hd;
val length = List.length;
val map = List.map;
val null = List.null;
val rev = List.rev;
val tl = List.tl;

use "./LIST_PAIR.sig";
use "./ListPair.sml";
structure ListPair = ListPair : LIST_PAIR;

use "./SUBSTRING.sig";
use "./Substring.sml";

use "./STRING_CVT.sig";
use "./StringCvt.sml";
structure StringCvt = StringCvt : STRING_CVT;

use "./PARSER_COMB.sig";
use "./ParserComb.sml";

use "./Int.sml";
structure LargeInt = Int;
structure Int32 = Int;
structure Position = Int;
use "./INTEGER.sig";
structure Int = Int : INTEGER;

(* Char is referred by String and STRING. *)
use "./Char.sml";

(* Because our implementation of the String.fromCString uses the scanCString
 * in the Char, which is not specified in the CHAR signature, we define the
 * String before constraining the Char by the CHAR. *)
use "./String.sml";

(* CHAR is referred by STRING *)
use "./CHAR.sig";
structure Char =
          Char :> CHAR
                      where type char = char
                      where type string = String.string;
val chr = Char.chr;
val ord = Char.ord;

use "./STRING.sig";
structure String =
          String :> STRING
              where type string = string
(*
              where type string = CharVector.vector
*)
              where type char = Char.char;
val op ^ = String.^;
val concat = String.concat;
val explode = String.explode;
val implode = String.implode;
val size = String.size;
val str = String.str;
val substring = String.substring;

structure Substring =
          Substring :> SUBSTRING
(*
                           where type substring = CharVectorSlice.slice
*)
                           where type string = String.string
                           where type char = Char.char;
type substring = Substring.substring;

use "./BOOL.sig";
use "./Bool.sml";
val not = Bool.not;

use "./Word.sml";
structure LargeWord = Word;

use "./WORD.sig";
structure Word32 = Word :> WORD where type word = word;
structure LargeWord = Word :> WORD where type word = word;
structure Word = Word :> WORD where type word = word;
structure SysWord = Word;

use "./Word8.sml";
structure Word8 = Word8 :> WORD where type word = byte;

(****************************************)

use "./Vector.sml";
use "./Array.sml";
use "./VectorSlice.sml";
use "./ArraySlice.sml";

use "./VECTOR.sig";
use "./ARRAY.sig";
use "./VECTOR_SLICE.sig";
use "./ARRAY_SLICE.sig";

signature S = 
sig
  structure V : VECTOR
  structure A : ARRAY
  structure VS : VECTOR_SLICE
  structure AS : ARRAY_SLICE
  sharing type V.vector = A.vector
  sharing type VS.vector = V.vector
  sharing type AS.array = A.array
  sharing type AS.vector = V.vector
  sharing type AS.vector_slice = VS.slice
end;
local
  structure S :> S =
  struct
    structure V = Vector
    structure A = Array
    structure VS = VectorSlice
    structure AS = ArraySlice
  end
in
structure Vector = S.V;
structure Array = S.A;
structure VectorSlice = S.VS;
structure ArraySlice = S.AS;
end;

type 'a vector = 'a Vector.vector;
type 'a array = 'a Array.array;
val vector = Vector.fromList;

(****************************************)

use "./IEEE_REAL.sig";
use "./IEEEReal.sml";

use "./MATH.sig";
use "./Math.sml";

use "./Real.sml";
structure LargeReal = Real;
use "./REAL.sig";
structure Real = Real :> REAL 
          where type Math.real = real;
val ceil = Real.ceil;
val floor = Real.floor;
val real = Real.fromInt;
val round = Real.round;
val trunc = Real.trunc;

structure Math = Math :> MATH where type real = Real.real;

(****************************************)

use "./MONO_VECTOR.sig";
use "./MONO_ARRAY.sig";
use "./MONO_VECTOR_SLICE.sig";
use "./MONO_ARRAY_SLICE.sig";

use "./MonoVectorBase.sml";
use "./MonoArrayBase.sml";

use "./MonoVectorSliceBase.sml";
use "./MonoArraySliceBase.sml";

(********************)

use "./CharVector.sml";
use "./CharArray.sml";
use "./CharVectorSlice.sml";
use "./CharArraySlice.sml";
local
  structure S :>
  sig
    structure V : MONO_VECTOR
                      where type vector = String.string
                      where type elem = char
    structure A : MONO_ARRAY
                      where type vector = String.string
                      where type elem = char
    structure VS : MONO_VECTOR_SLICE
                      where type vector = String.string
                      where type elem = char
    structure AS : MONO_ARRAY_SLICE
                      where type vector = String.string
                      where type elem = char
    sharing type AS.array = A.array
    sharing type AS.vector_slice = VS.slice
  end =
  struct
    structure V = CharVector
    structure A = CharArray
    structure VS = CharVectorSlice
    structure AS = CharArraySlice
  end
in
structure CharVector = S.V;
structure CharArray = S.A;
structure CharVectorSlice = S.VS;
structure CharArraySlice = S.AS;
end;

(********************)

use "./IntVector.sml";
use "./IntArray.sml";
use "./IntVectorSlice.sml";
use "./IntArraySlice.sml";
local
  structure S :>
  sig
    structure V : MONO_VECTOR where type elem = int
    structure A : MONO_ARRAY where type elem = int
    structure VS : MONO_VECTOR_SLICE where type elem = int
    structure AS : MONO_ARRAY_SLICE where type elem = int
    sharing type V.vector = A.vector;
    sharing type V.vector = VS.vector;
    sharing type AS.vector = V.vector;
    sharing type AS.array = A.array;
    sharing type AS.vector_slice = VS.slice
  end =
  struct
    structure V = IntVector
    structure A = IntArray
    structure VS = IntVectorSlice
    structure AS = IntArraySlice
  end
in
structure IntVector = S.V;
structure IntArray = S.A;
structure IntVectorSlice = S.VS;
structure IntArraySlice = S.AS;
end;

(********************)

use "./Word8Vector.sml";
use "./Word8Array.sml";
use "./Word8VectorSlice.sml";
use "./Word8ArraySlice.sml";
local
  structure S :>
  sig
    structure V : MONO_VECTOR where type elem = Word8.word
    structure A : MONO_ARRAY where type elem = Word8.word
    structure VS : MONO_VECTOR_SLICE where type elem = Word8.word
    structure AS : MONO_ARRAY_SLICE where type elem = Word8.word
    sharing type V.vector = A.vector
    sharing type VS.vector = V.vector
    sharing type AS.vector = V.vector
    sharing type AS.array = A.array
    sharing type AS.vector_slice = VS.slice
  end =
  struct
    structure V = Word8Vector
    structure A = Word8Array
    structure VS = Word8VectorSlice
    structure AS = Word8ArraySlice
  end
in
structure Word8Vector = S.V;
structure Word8Array = S.A;
structure Word8VectorSlice = S.VS;
structure Word8ArraySlice = S.AS;
end;

(********************)

use "./RealVector.sml";
use "./RealArray.sml";
use "./RealVectorSlice.sml";
use "./RealArraySlice.sml";
local
  structure S :>
  sig
    structure V : MONO_VECTOR where type elem = real
    structure A : MONO_ARRAY where type elem = real
    structure VS : MONO_VECTOR_SLICE where type elem = real
    structure AS : MONO_ARRAY_SLICE where type elem = real
    sharing type V.vector = A.vector;
    sharing type V.vector = VS.vector;
    sharing type AS.vector = V.vector;
    sharing type AS.array = A.array;
    sharing type AS.vector_slice = VS.slice
  end =
  struct
    structure V = RealVector
    structure A = RealArray
    structure VS = RealVectorSlice
    structure AS = RealArraySlice
  end
in
structure RealVector = S.V;
structure RealArray = S.A;
structure RealVectorSlice = S.VS;
structure RealArraySlice = S.AS;
end;

(****************************************)

use "./INT_INF.sig";
use "./IntInf.sml";

use "./BYTE.sig";
use "./Byte.sml";

(*
use "./ARRAY2.sig";
use "./MONO_ARRAY2.sig";
use "./MULTIBYTE.sig";
use "./PACK_REAL.sig";
use "./PACK_WORD.sig";
*)

use "./TIME.sig";
use "./Time.sml";

use "./COMMAND_LINE.sig";
use "./CommandLine.sml";

use "./DATE.sig";
use "./Date.sml";

use "./TIMER.sig";
use "./Timer.sml";

(*
use "./LOCALE.sig";

use "./SML90.sig";
*)

(****************************************)

use "./NJ/load.sml";

use "./OS_FILE_SYS.sig";
use "./OS_IO.sig";
use "./OS_PATH.sig";
use "./OS_PROCESS.sig";
use "./OS.sig";

use "./IO.sig";
use "./IO.sml";

use "./OS_PathFn.sml";
use "./GenericOS/load.sml";

use "./STREAM_IO.sig";
use "./IMPERATIVE_IO.sig";
use "./PRIM_IO.sig";
use "./PrimIO.sml";
use "./BinPrimIO.sml";
use "./TextPrimIO.sml";

use "./BIN_IO.sig";

use "./TEXT_STREAM_IO.sig";
use "./TEXT_IO.sig";

use "./CleanIO.sml";
use "./OS_PRIM_IO.sig";
use "./BinIOFn.sml";
use "./TextIOFn.sml";

use "./GenericOS/loadio.sml";

val print = TextIO.print;

(*
use "./POSIX_ERROR.sig";
use "./POSIX_FLAGS.sig";
use "./POSIX_FILE_SYS.sig";
use "./POSIX_IO.sig";
use "./POSIX_PROCESS.sig";
use "./POSIX_PROC_ENV.sig";
use "./POSIX_SIGNAL.sig";
use "./POSIX_SYS_DB.sig";
use "./POSIX_TTY.sig";
use "./POSIX.sig";

use "./UNIX.sig";
*)
