(*
 * loads modules of Basis library.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: basis.sml,v 1.91 2008/03/11 08:53:57 katsu Exp $
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

val sub = SMLSharp.PrimString.sub_unsafe;

val size = SMLSharp.PrimString.size;

val op ^ = SMLSharp.Runtime.String_concat2;

fun explode string =
    let
      fun accum 0 chars = chars
        | accum n chars = accum (n - 1) (sub (string, n - 1) :: chars)
    in accum (size string) [] end;

fun implode chars =
    let
      fun scan [] accum = accum
        | scan (char :: chars) accum =
          scan chars (accum ^ (SMLSharp.Runtime.Char_toString char))
    in scan chars ""
    end;

use "./BasicFormatters.sml";

exception Unimplemented of string;

(* for FFI *)

type void = unit;
val NULL = _NULL;

(*****************************************************************************)

use "./GENERAL.sig";
use "./General.sml";
(*
type unit = General.unit;
*)
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
local
  open Option
in
val getOpt = getOpt
val isSome = isSome
val valOf = valOf
end;

use "./LIST.sig";
use "./List.sml";

structure List = List : LIST;
local
  open List
in
  exception Empty = List.Empty;
  val op @ = op @;
  val app = app;
  val foldl = foldl;
  val foldr = foldr;
  val hd = hd;
  val length = length;
  val map = map;
  val null = null;
  val rev = rev;
  val tl = tl;
end;

use "./LIST_PAIR.sig";
use "./ListPair.sml";
structure ListPair = ListPair : LIST_PAIR;

(*
use "./SubstringBase.sml";
*)
use "./SUBSTRING.sig";
(*
use "./Substring.sml";
*)
use "./SubstringDefun.sml";

use "./STRING_CVT.sig";
use "./StringCvt.sml";
structure StringCvt = StringCvt : STRING_CVT;

use "./PARSER_COMB.sig";
use "./ParserComb.sml";

use "./Int.sml";
use "./IntInf.sml";
structure IntInf = struct open IntInf
fun '_format_int' arg =
    let val string = toString arg
    in SMLSharp.SMLFormat.Term(size string, string) end;
end;

use "./Word.sml";

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
(*
val op ^ = String.^;
val concat = String.concat;
val explode = String.explode;
val implode = String.implode;
val size = String.size;
val str = String.str;
val substring = String.substring;
*)
local
  open String
in
  val op ^ = op ^;
  val concat = concat;
  val explode = explode;
  val implode = implode;
  val size = size;
  val str = str;
  val substring = substring;
end;

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

(****************************************)

use "./Vector.sml";
use "./Array.sml";
use "./VectorSlice.sml";
use "./ArraySlice.sml";

use "./VECTOR.sig";
use "./ARRAY.sig";
use "./VECTOR_SLICE.sig";
use "./ARRAY_SLICE.sig";

(****************************************)

use "./MONO_VECTOR.sig";
use "./MONO_ARRAY.sig";
use "./MONO_VECTOR_SLICE.sig";
use "./MONO_ARRAY_SLICE.sig";

use "./MonoVectorBase.sml";
use "./MonoArrayBase.sml";

use "./MonoVectorSliceBase.sml";
use "./MonoArraySliceBase.sml";

signature MONO_VECTOR_ARRAY =
sig
  type vector
  type elem
  structure V : MONO_VECTOR
                    where type vector = vector
                    where type elem = elem
  structure A : MONO_ARRAY
                    where type vector = vector
                    where type elem = elem
  structure VS : MONO_VECTOR_SLICE
                    where type vector = vector
                    where type elem = elem
  structure AS : MONO_ARRAY_SLICE
                    where type vector = vector
                    where type elem = elem
  sharing type AS.array = A.array
  sharing type AS.vector_slice = VS.slice
end;

(********************)

use "./IntVector.sml";
use "./IntArray.sml";
use "./IntVectorSlice.sml";
use "./IntArraySlice.sml";

local
  structure S :> MONO_VECTOR_ARRAY
                     where type elem = int
                     where type vector = IntVector.vector
  =
  struct
    type vector = IntVector.vector
    type elem = int
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

(****************************************)

structure Int32 = Int;
structure Word32 = Word;

structure LargeInt = IntInf;

use "./INTEGER.sig";
structure Int = 
struct
  open Int
  val fromLarge = IntInf.toInt
  val toLarge = IntInf.fromInt
end;
structure Int32 = Int :> INTEGER where type int = int;
structure LargeInt = LargeInt :> INTEGER where type int = LargeInt.int;
structure Int = Int :> INTEGER where type int = int;
structure FixedInt = Int;
structure Position = Int;

use "./INT_INF.sig";
structure IntInf = IntInf :> INT_INF where type int = IntInf.int;

structure LargeWord = Word;
use "./WORD.sig";
structure Word32 = Word :> WORD where type word = word;
structure LargeWord = Word :> WORD where type word = word;
structure Word = Word :> WORD where type word = word;
structure SysWord = Word;

(********************)

(* NOTE: Word8{Vector,Array} depends on copySlice in Char{Vector,Array},
 * which is hidden by MONO_{VECTOR, ARRAY}. *)

use "./CharVector.sml";
use "./CharArray.sml";
use "./CharVectorSlice.sml";
use "./CharArraySlice.sml";

use "./Word8.sml";
structure Word8 :> WORD where type word = Word8.word =
struct open Word8
fun '_format_word' (arg : word) =
    let val string = "0wx" ^ (toString arg)
    in SMLSharp.SMLFormat.Term(size string, string) end;
end;


use "./Word8Vector.sml";
 use "./Word8Array.sml";
use "./Word8VectorSlice.sml";
use "./Word8ArraySlice.sml";

local
  structure S :> MONO_VECTOR_ARRAY
                     where type vector = String.string 
                     where type elem = char
  =
  struct
    type vector = CharVector.vector
    type elem = char
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

local
  structure S :> MONO_VECTOR_ARRAY
                     where type elem = Word8.word
                     where type vector = Word8Vector.vector
  =
  struct
    type vector = Word8Vector.vector
    type elem = Word8.word
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

use "./TEXT.sig";
structure Text : TEXT =
struct
  structure Char = Char
  structure String = String
  structure Substring = Substring
  structure CharVector = CharVector
  structure CharArray = CharArray
  structure CharVectorSlice = CharVectorSlice
  structure CharArraySlice = CharArraySlice
end;

(****************************************)

use "./IEEE_REAL.sig";
use "./IEEEReal.sml";

use "./MATH.sig";
use "./Math.sml";

use "./RealBase.sml";
use "./Real64.sml";
structure LargeReal = Real64;
use "./REAL.sig";
structure Real64 = Real64 :> REAL
          where type real = real;
use "./Real.sml";
structure Real = Real :> REAL 
          where type real = real;

val ceil = Real.ceil;
val floor = Real.floor;
val real = Real.fromInt;
val round = Real.round;
val trunc = Real.trunc;
fun '_format_real' arg =
    let val string = Real.toString arg
    in SMLSharp.SMLFormat.Term(size string, string) end;

structure Math = Math :> MATH where type real = Real.real;

use "./Real32.sml";
structure Real32 = struct open Real32
fun '_format_real' arg =
    let val string = toString arg
    in SMLSharp.SMLFormat.Term(size string, string) end;
end;
structure Real32 = Real32 :> REAL where type real = Real32.real;

(********************)

use "./RealVector.sml";
use "./RealArray.sml";
use "./RealVectorSlice.sml";
use "./RealArraySlice.sml";

local
  structure S :> MONO_VECTOR_ARRAY
                     where type elem = real
  =
  struct
    type vector = RealVector.vector
    type elem = real
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
(* Because instances of MonoVectors and MonoArrays depends on functions in
 * Vector and Array, which are hidden by VECTOR and ARRAY, constraining Vector
 * and Array are postponed til here. *)

signature S = 
sig
  structure Vector : VECTOR
  structure Array : ARRAY
  structure VectorSlice : VECTOR_SLICE
  structure ArraySlice : ARRAY_SLICE
  sharing type Vector.vector = Array.vector
  sharing type Vector.vector = VectorSlice.vector
  sharing type Array.array = ArraySlice.array
  sharing type Vector.vector = ArraySlice.vector
  sharing type VectorSlice.slice = ArraySlice.vector_slice
end
  where type 'a Array.array = 'a array;
local
  structure S :> S =
  struct
    structure Vector = Vector
    structure Array = Array
    structure VectorSlice = VectorSlice
    structure ArraySlice = ArraySlice
  end
in
open S
end;

type 'a vector = 'a Vector.vector;
type 'a array = 'a Array.array;
val vector = Vector.fromList;

(****************************************)

use "./BYTE.sig";
use "./Byte.sml";

use "./ARRAY2.sig";
use "./Array2.sml";

use "./MONO_ARRAY2.sig";
use "./CharArray2.sml";
use "./Word8Array2.sml";

(*
use "./MULTIBYTE.sig";
*)
use "./PACK_WORD.sig";
use "./PackWord32Base.sml";
use "./PackWord32Big.sml";
use "./PackWord32Little.sml";
use "./PackWordBig.sml";
use "./PackWordLittle.sml";

use "./PACK_REAL.sig";
use "./PackReal64Base.sml";
use "./PackReal64Big.sml";
use "./PackReal64Little.sml";
use "./PackRealBig.sml";
use "./PackRealLittle.sml";
use "./PackReal32Base.sml";
use "./PackReal32Big.sml";
use "./PackReal32Little.sml";

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

use "./BIT_FLAGS.sig";
use "./Posix/POSIX_ERROR.sig";
use "./Posix/POSIX_FLAGS.sig";
use "./Posix/POSIX_FILE_SYS.sig";
use "./Posix/POSIX_IO.sig";
use "./Posix/POSIX_PROCESS.sig";
use "./Posix/POSIX_PROC_ENV.sig";
use "./Posix/POSIX_SIGNAL.sig";
use "./Posix/POSIX_SYS_DB.sig";
use "./Posix/POSIX_TTY.sig";
use "./Posix/POSIX.sig";

use "./UNIX.sig";
