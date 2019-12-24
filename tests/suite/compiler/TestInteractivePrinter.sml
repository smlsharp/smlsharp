(**
 * tests for the value printer of interactive mode
 *
 * @copyright (c) 2017, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure TestInteractivePrinter =
struct
open SMLUnit.Test SMLUnit.Assert Compiler

fun testPrinter input expect =
    assertEqualStringList
      expect
      (#prints (interactive' input))

val tests = TestList [

  Test
    ("int8 zero",
     fn () =>
        testPrinter
          "0 : Int8.int"
          ["val it = 0 : int8\n"]),
  Test
    ("int8 max/10",
     fn () =>
        testPrinter
          "12 : Int8.int"
          ["val it = 12 : int8\n"]),
  Test
    ("int8 max/10+1",
     fn () =>
        testPrinter
          "13 : Int8.int"
          ["val it = 13 : int8\n"]),
  Test
    ("int8 max",
     fn () =>
        testPrinter
          "127 : Int8.int"
          ["val it = 127 : int8\n"]),
  Test
    ("int8 min/10",
     fn () =>
        testPrinter
          "~12 : Int8.int"
          ["val it = ~12 : int8\n"]),
  Test
    ("int8 min/10-1",
     fn () =>
        testPrinter
          "~13 : Int8.int"
          ["val it = ~13 : int8\n"]),
  Test
    ("int8 min",
     fn () =>
        testPrinter
          "~128 : Int8.int"
          ["val it = ~128 : int8\n"]),
  Test
    ("int16 zero",
     fn () =>
        testPrinter
          "0 : Int16.int"
          ["val it = 0 : int16\n"]),
  Test
    ("int16 max/10",
     fn () =>
        testPrinter
          "3276 : Int16.int"
          ["val it = 3276 : int16\n"]),
  Test
    ("int16 max/10+1",
     fn () =>
        testPrinter
          "3277 : Int16.int"
          ["val it = 3277 : int16\n"]),
  Test
    ("int16 max",
     fn () =>
        testPrinter
          "32767 : Int16.int"
          ["val it = 32767 : int16\n"]),
  Test
    ("int16 min/10",
     fn () =>
        testPrinter
          "~3276 : Int16.int"
          ["val it = ~3276 : int16\n"]),
  Test
    ("int16 min/10-1",
     fn () =>
        testPrinter
          "~3277 : Int16.int"
          ["val it = ~3277 : int16\n"]),
  Test
    ("int16 min",
     fn () =>
        testPrinter
          "~32767 : Int16.int"
          ["val it = ~32767 : int16\n"]),
  Test
    ("int32 zero",
     fn () =>
        testPrinter
          "0 : int"
          ["val it = 0 : int\n"]),
  Test
    ("int32 max/10",
     fn () =>
        testPrinter
          "214748364 : int"
          ["val it = 214748364 : int\n"]),
  Test
    ("int32 max/10+1",
     fn () =>
        testPrinter
          "214748365 : int"
          ["val it = 214748365 : int\n"]),
  Test
    ("int32 max",
     fn () =>
        testPrinter
          "2147483647 : int"
          ["val it = 2147483647 : int\n"]),
  Test
    ("int32 min/10",
     fn () =>
        testPrinter
          "~214748364 : int"
          ["val it = ~214748364 : int\n"]),
  Test
    ("int32 min/10-1",
     fn () =>
        testPrinter
          "~214748365 : int"
          ["val it = ~214748365 : int\n"]),
  Test
    ("int32 min",
     fn () =>
        testPrinter
          "~2147483648 : int"
          ["val it = ~2147483648 : int\n"]),
  Test
    ("int64 zero",
     fn () =>
        testPrinter
          "0 : Int64.int"
          ["val it = 0 : int64\n"]),
  Test
    ("int64 max/10",
     fn () =>
        testPrinter
          "922337203685477580 : Int64.int"
          ["val it = 922337203685477580 : int64\n"]),
  Test
    ("int64 max/10+1",
     fn () =>
        testPrinter
          "922337203685477581 : Int64.int"
          ["val it = 922337203685477581 : int64\n"]),
  Test
    ("int64 max",
     fn () =>
        testPrinter
          "9223372036854775807 : Int64.int"
          ["val it = 9223372036854775807 : int64\n"]),
  Test
    ("int64 min/10",
     fn () =>
        testPrinter
          "~922337203685477580 : Int64.int"
          ["val it = ~922337203685477580 : int64\n"]),
  Test
    ("int64 min/10-1",
     fn () =>
        testPrinter
          "~922337203685477581 : Int64.int"
          ["val it = ~922337203685477581 : int64\n"]),
  Test
    ("int64 min",
     fn () =>
        testPrinter
          "~9223372036854775808 : Int64.int"
          ["val it = ~9223372036854775808 : int64\n"]),
  Test
    ("intinf zero",
     fn () =>
        testPrinter
          "0 : IntInf.int"
          ["val it = 0 : intInf\n"]),
  Test
    ("intinf positive",
     fn () =>
        testPrinter
          "123456789012345678901234567890 : IntInf.int"
          ["val it = 123456789012345678901234567890 : intInf\n"]),
  Test
    ("intinf negative",
     fn () =>
        testPrinter
          "~123456789012345678901234567890 : IntInf.int"
          ["val it = ~123456789012345678901234567890 : intInf\n"]),
  Test
    ("word8 zero",
     fn () =>
        testPrinter
          "0w0 : Word8.word"
          ["val it = 0wx0 : word8\n"]),
  Test
    ("word8 max/10",
     fn () =>
        testPrinter
          "0w12 : Word8.word"
          ["val it = 0wxc : word8\n"]),
  Test
    ("word8 max/10+1",
     fn () =>
        testPrinter
          "0w13 : Word8.word"
          ["val it = 0wxd : word8\n"]),
  Test
    ("word8 max",
     fn () =>
        testPrinter
          "0w127 : Word8.word"
          ["val it = 0wx7f : word8\n"]),
  Test
    ("word16 zero",
     fn () =>
        testPrinter
          "0w0 : Word16.word"
          ["val it = 0wx0 : word16\n"]),
  Test
    ("word16 max/10",
     fn () =>
        testPrinter
          "0w3276 : Word16.word"
          ["val it = 0wxccc : word16\n"]),
  Test
    ("word16 max/10+1",
     fn () =>
        testPrinter
          "0w3277 : Word16.word"
          ["val it = 0wxccd : word16\n"]),
  Test
    ("word16 max",
     fn () =>
        testPrinter
          "0w32767 : Word16.word"
          ["val it = 0wx7fff : word16\n"]),
  Test
    ("word32 zero",
     fn () =>
        testPrinter
          "0w0 : word"
          ["val it = 0wx0 : word\n"]),
  Test
    ("word32 max/10",
     fn () =>
        testPrinter
          "0w214748364 : word"
          ["val it = 0wxccccccc : word\n"]),
  Test
    ("word32 max/10+1",
     fn () =>
        testPrinter
          "0w214748365 : word"
          ["val it = 0wxccccccd : word\n"]),
  Test
    ("word32 max",
     fn () =>
        testPrinter
          "0w2147483647 : word"
          ["val it = 0wx7fffffff : word\n"]),
  Test
    ("word64 zero",
     fn () =>
        testPrinter
          "0w0 : Word64.word"
          ["val it = 0wx0 : word64\n"]),
  Test
    ("word64 max/10",
     fn () =>
        testPrinter
          "0w922337203685477580 : Word64.word"
          ["val it = 0wxccccccccccccccc : word64\n"]),
  Test
    ("word64 max/10+1",
     fn () =>
        testPrinter
          "0w922337203685477581 : Word64.word"
          ["val it = 0wxccccccccccccccd : word64\n"]),
  Test
    ("word64 max",
     fn () =>
        testPrinter
          "0w9223372036854775807 : Word64.word"
          ["val it = 0wx7fffffffffffffff : word64\n"]),
  Test
    ("char zero",
     fn () =>
        testPrinter
          "#\"\\000\""
          ["val it = #\"\\^@\" : char\n"]),
  Test
    ("char a",
     fn () =>
        testPrinter
          "#\"a\""
          ["val it = #\"a\" : char\n"]),
  Test
    ("char max",
     fn () =>
        testPrinter
          "#\"\\255\""
          ["val it = #\"\\255\" : char\n"]),
  Test
    ("string empty",
     fn () =>
        testPrinter
          "\"\""
          ["val it = \"\" : string\n"]),
  Test
    ("string adc",
     fn () =>
        testPrinter
          "\"abc\\n\""
          ["val it = \"abc\\n\" : string\n"]),
  Test
    ("string escape",
     fn () =>
        testPrinter
          "\"!\\000!\""
          ["val it = \"!\\^@!\" : string\n"]),
  Test
    ("string utf8",
     fn () =>
        testPrinter
          "\"これは試行デス\""
          ["val it = \"これは試行デス\" : string\n"]),
  Test
    ("real64 zero",
     fn () =>
        testPrinter
          "0.0 : real"
          ["val it = 0.0 : real\n"]),
  Test
    ("real64 ~zero",
     fn () =>
        testPrinter
          "~0.0 : real"
          ["val it = ~0.0 : real\n"]),
  Test
    ("real64 normal",
     fn () =>
        testPrinter
          "255.9999847412109375"
          ["val it = 255.999984741 : real\n"]),
  Test
    ("real64 1e~4",
     fn () =>
        testPrinter
          "1e~4 : real"
          ["val it = 0.0001 : real\n"]),
  Test
    ("real64 1e~5",
     fn () =>
        testPrinter
          "1e~5 : real"
          ["val it = 1E~5 : real\n"]),
  Test
    ("real64 inf",
     fn () =>
        testPrinter
          "1.0 / 0.0 : real"
          ["val it = inf : real\n"]),
  Test
    ("real64 ~inf",
     fn () =>
        testPrinter
          "~1.0 / 0.0 : real"
          ["val it = ~inf : real\n"]),
  Test
    ("real64 nan",
     fn () =>
        testPrinter
          "0.0 / 0.0 : real"
          ["val it = nan : real\n"]),
  Test
    ("real32 zero",
     fn () =>
        testPrinter
          "0.0 : Real32.real"
          ["val it = 0.0 : real32\n"]),
  Test
    ("real32 ~zero",
     fn () =>
        testPrinter
          "~0.0 : Real32.real"
          ["val it = ~0.0 : real32\n"]),
  Test
    ("real32 normal",
     fn () =>
        testPrinter
          "255.9999847412109375 : Real32.real"
          ["val it = 255.999984741 : real32\n"]),
  Test
    ("real32 1e~4",
     fn () =>
        testPrinter
          "1e~4 : Real32.real"
          ["val it = 9.99999974738E~5 : real32\n"]),
  Test
    ("real32 1e~5",
     fn () =>
        testPrinter
          "1e~5 : Real32.real"
          ["val it = 9.99999974738E~6 : real32\n"]),
  Test
    ("real32 inf",
     fn () =>
        testPrinter
          "1.0 / 0.0 : Real32.real"
          ["val it = inf : real32\n"]),
  Test
    ("real32 ~inf",
     fn () =>
        testPrinter
          "~1.0 / 0.0 : Real32.real"
          ["val it = ~inf : real32\n"]),
  Test
    ("real32 nan",
     fn () =>
        testPrinter
          "0.0 / 0.0 : Real32.real"
          ["val it = nan : real32\n"]),
  Test
    ("polyfn id",
     fn () =>
        testPrinter
          "fn x => x"
          ["val it = fn : ['a. 'a -> 'a]\n"]),
  Test
    ("polyfn reckind",
     fn () =>
        testPrinter
          "#a"
          ["val it = fn : ['a#{a: 'b}, 'b. 'a -> 'b]\n"]),
  Test
    ("polyfn record",
     fn () =>
        testPrinter
          "#a o #b : {b:{a:int}} -> int"
          ["val it = fn : {b: {a: int}} -> int\n"]),
  Test
    ("polyfn reckind nested",
     fn () =>
        testPrinter
          "fn x => #a (#b x)"
          ["val it = fn : ['a#{b: 'b}, 'b#{a: 'c}, 'c. 'a -> 'c]\n"]),
  Test
    ("unit",
     fn () =>
        testPrinter
          "()"
          ["val it = () : unit\n"]),
  Test
    ("bool true",
     fn () =>
        testPrinter
          "true"
          ["val it = true : bool\n"]),
  Test
    ("bool false",
     fn () =>
        testPrinter
          "false"
          ["val it = false : bool\n"]),
  Test
    ("exn bind",
     fn () =>
        testPrinter
          "Bind"
          ["val it = Bind : exn\n"]),
  Test
    ("exn match",
     fn () =>
        testPrinter
          "Match"
          ["val it = Match : exn\n"]),
  Test
    ("exn fail",
     fn () =>
        testPrinter
          "Fail \"hello\""
          ["val it = Fail ... : exn\n"]),
(*
          ["val it = Fail \"hello\" : exn\n"]),
*)
  Test
    ("exn io",
     fn () =>
        testPrinter
          "IO.Io {cause = Match, function = \"hoge\", name = \"fuga\"}"
          ["val it = IO.Io ... : exn\n"]),
(*
          ["val it = IO.Io {cause = Match, function = \"hoge\", name = \"fuga\"} : exn\n"]),
*)
  Test
    ("option none",
     fn () =>
        testPrinter
          "NONE"
          ["val it = NONE : ['a. 'a option]\n"]),
  Test
    ("option some 4",
     fn () =>
        testPrinter
          "SOME 123"
          ["val it = SOME 123 : int option\n"]),
  Test
    ("option some 8",
     fn () =>
        testPrinter
          "SOME 123.456"
          ["val it = SOME 123.456 : real option\n"]),
  Test
    ("option some p",
     fn () =>
        testPrinter
          "SOME (123, 456)"
          ["val it = SOME (123, 456) : (int * int) option\n"]),
  Test
    ("option some none",
     fn () =>
        testPrinter
          "SOME NONE"
          ["val it = SOME NONE : ['a. 'a option option]\n"]),
  Test
    ("option some some none",
     fn () =>
        testPrinter
          "SOME (SOME NONE)"
          ["val it = SOME (SOME NONE) : ['a. 'a option option option]\n"]),
  Test
    ("option some some 8",
     fn () =>
        testPrinter
          "SOME (SOME 123.45)"
          ["val it = SOME (SOME 123.45) : real option option\n"]),
  Test
    ("option some some p",
     fn () =>
        testPrinter
          "SOME (SOME (123, 456))"
          ["val it = SOME (SOME (123, 456)) : (int * int) option option\n"]),
  Test
    ("list nil",
     fn () =>
        testPrinter
          "nil"
          ["val it = [] : ['a. 'a list]\n"]),
  Test
    ("list 4",
     fn () =>
        testPrinter
          "1 :: 2 :: 3 :: nil"
          ["val it = [1, 2, 3] : int list\n"]),
  Test
    ("list 8",
     fn () =>
        testPrinter
          "[1.2, 3.4, 5.6]"
          ["val it = [1.2, 3.4, 5.6] : real list\n"]),
  Test
    ("list list nil",
     fn () =>
        testPrinter
          "[nil]"
          ["val it = [[]] : ['a. 'a list list]\n"]),
  Test
    ("list nested",
     fn () =>
        testPrinter
          "[[[[]]],[[[]]]]"
          ["val it = [[[[]]], [[[]]]] : ['a. 'a list list list list]\n"]),
  Test
    ("list list 4",
     fn () =>
        testPrinter
          "[[1, 2, 3], [4], [], [5, 6]]"
          ["val it = [[1, 2, 3], [4], [], [5, 6]] : int list list\n"]),
  Test
    ("list option list 4",
     fn () =>
        testPrinter
          "[SOME [1, 2, 3]]"
          ["val it = [SOME [1, 2, 3]] : int list option list\n"]),

  Test
    ("array empty",
     fn () =>
        testPrinter
          "Array.array (0, 0)"
          ["val it = <> : int array\n"]),
  Test
    ("array 1",
     fn () =>
        testPrinter
          "Array.tabulate (3, Int8.fromInt)"
          ["val it = <0, 1, 2> : int8 array\n"]),
  Test
    ("array 2",
     fn () =>
        testPrinter
          "Array.tabulate (3, Int16.fromInt)"
          ["val it = <0, 1, 2> : int16 array\n"]),
  Test
    ("array 4",
     fn () =>
        testPrinter
          "Array.tabulate (3, Int32.fromInt)"
          ["val it = <0, 1, 2> : int array\n"]),
  Test
    ("array 8",
     fn () =>
        testPrinter
          "Array.tabulate (3, Int64.fromInt)"
          ["val it = <0, 1, 2> : int64 array\n"]),
  Test
    ("array 4 calc",
     fn () =>
        testPrinter
          "Array.tabulate (3, fn x => x)"
          ["val it = <0, 1, 2> : int array\n"]),
  Test
    ("array 8 calc",
     fn () =>
        testPrinter
          "Array.tabulate (3, real)"
          ["val it = <0.0, 1.0, 2.0> : real array\n"]),
  Test
    ("array 1 calc",
     fn () =>
        testPrinter
          "Array.tabulate (3, chr)"
          ["val it = <#\"\\^@\", #\"\\^A\", #\"\\^B\"> : char array\n"]),
  Test
    ("array p calc",
     fn () =>
        testPrinter
          "Array.tabulate (3, str o chr)"
          ["val it = <\"\\^@\", \"\\^A\", \"\\^B\"> : string array\n"]),
  Test
    ("array nest calc",
     fn () =>
        testPrinter
          "Array.tabulate (3, fn x => Array.tabulate (x, fn x => x))"
          ["val it = <<>, <0>, <0, 1>> : int array array\n"]),
  Test
    ("vector empty",
     fn () =>
        testPrinter
          "Vector.fromList nil : int vector"
          ["val it = <||> : int vector\n"]),
  Test
    ("vector 1",
     fn () =>
        testPrinter
          "Vector.tabulate (3, Int8.fromInt)"
          ["val it = <|0, 1, 2|> : int8 vector\n"]),
  Test
    ("vector 2",
     fn () =>
        testPrinter
          "Vector.tabulate (3, Int16.fromInt)"
          ["val it = <|0, 1, 2|> : int16 vector\n"]),
  Test
    ("vector 4",
     fn () =>
        testPrinter
          "Vector.tabulate (3, Int32.fromInt)"
          ["val it = <|0, 1, 2|> : int vector\n"]),
  Test
    ("vector 8",
     fn () =>
        testPrinter
          "Vector.tabulate (3, Int64.fromInt)"
          ["val it = <|0, 1, 2|> : int64 vector\n"]),
  Test
    ("vector 4 calc",
     fn () =>
        testPrinter
          "Vector.tabulate (3, fn x => x)"
          ["val it = <|0, 1, 2|> : int vector\n"]),
  Test
    ("vector 8 calc",
     fn () =>
        testPrinter
          "Vector.tabulate (3, real)"
          ["val it = <|0.0, 1.0, 2.0|> : real vector\n"]),
  Test
    ("vector 1 calc",
     fn () =>
        testPrinter
          "Vector.tabulate (3, chr)"
          ["val it = <|#\"\\^@\", #\"\\^A\", #\"\\^B\"|> : char vector\n"]),
  Test
    ("vector p calc",
     fn () =>
        testPrinter
          "Vector.tabulate (3, str o chr)"
          ["val it = <|\"\\^@\", \"\\^A\", \"\\^B\"|> : string vector\n"]),
  Test
    ("vector nest calc",
     fn () =>
        testPrinter
          "Vector.tabulate (3, fn x => Vector.tabulate (x, fn x => x))"
          ["val it = <|<||>, <|0|>, <|0, 1|>|> : int vector vector\n"]),
  Test
    ("ref 4",
     fn () =>
        testPrinter
          "ref 123"
          ["val it = ref 123 : int ref\n"]),
  Test
    ("ref 8",
     fn () =>
        testPrinter
          "ref 123.45"
          ["val it = ref 123.45 : real ref\n"]),
  Test
    ("ref 1",
     fn () =>
        testPrinter
          "ref #\"a\""
          ["val it = ref #\"a\" : char ref\n"]),
  Test
    ("ref p",
     fn () =>
        testPrinter
          "ref \"a\""
          ["val it = ref \"a\" : string ref\n"]),
  Test
    ("ref nest",
     fn () =>
        testPrinter
          "ref (ref (ref 123))"
          ["val it = ref (ref (ref 123)) : int ref ref ref\n"]),
  Test
    ("ref option 4",
     fn () =>
        testPrinter
          "ref (SOME 123)"
          ["val it = ref (SOME 123) : int option ref\n"]),
  Test
    ("substring",
     fn () =>
        testPrinter
          "Substring.full \"abc\""
          ["val it = _ : substring\n"]),
  Test
    ("tuple 444",
     fn () =>
        testPrinter
          "(1, 2, 3)"
          ["val it = (1, 2, 3) : int * int * int\n"]),
  Test
    ("tuple 484",
     fn () =>
        testPrinter
          "(1, 2.3, 4)"
          ["val it = (1, 2.3, 4) : int * real * int\n"]),
  Test
    ("tuple 448",
     fn () =>
        testPrinter
          "(1, 2, 3.4)"
          ["val it = (1, 2, 3.4) : int * int * real\n"]),
  Test
    ("tuple 4p4",
     fn () =>
        testPrinter
          "(1, (2, 3), 4)"
          ["val it = (1, (2, 3), 4) : int * (int * int) * int\n"]),
  Test
    ("tuple (44)4p",
     fn () =>
        testPrinter
          "((1, 2), 3, \"4\")"
          ["val it = ((1, 2), 3, \"4\") : (int * int) * int * string\n"]),
  Test
    ("tuple 144",
     fn () =>
        testPrinter
          "(#\"1\", 2, 3)"
          ["val it = (#\"1\", 2, 3) : char * int * int\n"]),
  Test
    ("tuple 414",
     fn () =>
        testPrinter
          "(1, #\"2\", 3)"
          ["val it = (1, #\"2\", 3) : int * char * int\n"]),
  Test
    ("tuple 211(44)",
     fn () =>
        testPrinter
          "(1 : Int16.int, #\"2\", #\"3\", (4, 5))"
          ["val it = (1, #\"2\", #\"3\", (4, 5)) : int16 * char * char * (int * int)\n"]),
  Test
    ("record tuple",
     fn () =>
        testPrinter
          "{1 = 123, 2 = 456}"
          ["val it = (123, 456) : int * int\n"]),
  Test
    ("record 444",
     fn () =>
        testPrinter
          "{A = 1, B = 2, C = 3}"
          ["val it = {A = 1, B = 2, C = 3} : {A: int, B: int, C: int}\n"]),
  Test
    ("record 444 unsorted",
     fn () =>
        testPrinter
          "{C = 1, B = 2, A = 3}"
          ["val it = {A = 3, B = 2, C = 1} : {A: int, B: int, C: int}\n"]),
  Test
    ("record 484",
     fn () =>
        testPrinter
          "{A = 1, B = 2.3, C = 4}"
          ["val it = {A = 1, B = 2.3, C = 4} : {A: int, B: real, C: int}\n"]),
  Test
    ("record 4(44)4",
     fn () =>
        testPrinter
          "{A = 1, B = {a = 2, b = 3}, C = 4}"
          ["val it =\n\
           \  {A = 1, B = {a = 2, b = 3}, C = 4} : {A: int, B: {a: int, b: int}, C: int}\n"]),
  Test
    ("record 4(44)4p",
     fn () =>
        testPrinter
          "{A = 1, B = {a = 1, b = 2}, C = 3, D = \"4\"}"
          ["val it =\n\
           \  {A = 1, B = {a = 1, b = 2}, C = 3, D = \"4\"}\n\
           \  : {A: int, B: {a: int, b: int}, C: int, D: string}\n"]),
  Test
    ("record 144",
     fn () =>
        testPrinter
          "{A = #\"1\", B = 2, C = 3}\n"
          ["val it = {A = #\"1\", B = 2, C = 3} : {A: char, B: int, C: int}\n"]),
  Test
    ("record 414",
     fn () =>
        testPrinter
          "{A = 1, B = #\"2\", C = 3}"
          ["val it = {A = 1, B = #\"2\", C = 3} : {A: int, B: char, C: int}\n"]),
  Test
    ("record 211(44)",
     fn () =>
        testPrinter
          "{A = 1 : Int16.int, B = #\"2\", C = #\"3\", D = (4, 5)}"
          ["val it =\n\
           \  {A = 1, B = #\"2\", C = #\"3\", D = (4, 5)}\n\
           \  : {A: int16, B: char, C: char, D: int * int}\n"]),
  Test
    ("record stringLabel",
     fn () =>
        testPrinter
          "{\"ABC\" = 1, \"foo bar\" = 2, \"hoge:fuga,piyo\" = 3}"
          ["val it =\n\
           \  {ABC = 1, \"foo bar\" = 2, \"hoge:fuga,piyo\" = 3}\n\
           \  : {ABC: int, \"foo bar\": int, \"hoge:fuga,piyo\": int}\n"]),
  Test
    ("record stringLabel escape",
     fn () =>
        testPrinter
          "{\"A\\nB\" = 1}"
          ["val it = {\"A\\nB\" = 1} : {\"A\\nB\": int}\n"]),
  Test
    ("record utf8 label",
     fn () =>
        testPrinter
          "{あいうえお = \"かきくけこ\", さしすせそ = \"たちつてと\"}"
          ["val it =\n\
           \  {あいうえお = \"かきくけこ\", さしすせそ = \"たちつてと\"}\n\
           \  : {あいうえお: string, さしすせそ: string}\n"]),
  Test
    ("record nested",
     fn () =>
        testPrinter
          "let fun f x = {A = x, B = x} in f (f (f (f 1))) end"
          ["val it =\n\
           \  {\n\
           \    A =\n\
           \      {\n\
           \        A = {A = {A = 1, B = 1}, B = {A = 1, B = 1}},\n\
           \        B = {A = {A = 1, B = 1}, B = {A = 1, B = 1}}\n\
           \      },\n\
           \    B =\n\
           \      {\n\
           \        A = {A = {A = 1, B = 1}, B = {A = 1, B = 1}},\n\
           \        B = {A = {A = 1, B = 1}, B = {A = 1, B = 1}}\n\
           \      }\n\
           \  }\n\
           \  : {A:\n\
           \       {A: {A: {A: int, B: int}, B: {A: int, B: int}},\n\
           \        B: {A: {A: int, B: int}, B: {A: int, B: int}}},\n\
           \     B:\n\
           \       {A: {A: {A: int, B: int}, B: {A: int, B: int}},\n\
           \        B: {A: {A: int, B: int}, B: {A: int, B: int}}}}\n"]),
  Test
    ("datatype tagged_record f",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \F (1, 2)"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = F (1, 2) : ['a. 'a t1]\n"]),
  Test
    ("datatype tagged_record bh",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \B H"
          ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = B H : ['a. 'a t1]\n"]),
  Test
    ("datatype tagged_record bz",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \B (Z 1)"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = B (Z 1) : ['a. 'a t1]\n"]),
  Test
    ("datatype tagged_record h",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \H"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = H : ['a. 'a t1]\n"]),
  Test
    ("datatype tagged_record t",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \T"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = T : ['a. 'a t1]\n"]),
  Test
    ("datatype tagged_record z4",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \Z 123"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = Z 123 : int t1\n"]),
  Test
    ("datatype tagged_record z8",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \Z 123.45"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = Z 123.45 : real t1\n"]),
  Test
    ("datatype tagged_record zh",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \Z H"
         ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = Z H : ['a. 'a t1 t1]\n"]),
  Test
    ("datatype tagged_record nested",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \Z (Z (Z (Z 123)))"
          ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = Z (Z (Z (Z 123))) : int t1 t1 t1 t1\n"]),
  Test
    ("datatype tagged_record turn",
     fn () =>
        testPrinter
          "datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T;\n\
          \Z (B (Z 123))"
          ["datatype 'a t1 = F of int * int | B of int t1 | Z of 'a | H | T\n",
           "val it = Z (B (Z 123)) : ['a. 'a t1 t1]\n"]),
  Test
    ("datatype tagged_or_null f",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \F (1, 2)"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = F (1, 2) : ['a. 'a t2]\n"]),
  Test
    ("datatype tagged_or_null bh",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \B H"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = B H : ['a. 'a t2]\n"]),
  Test
    ("datatype tagged_or_null bz",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \B (Z 1)"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = B (Z 1) : ['a. 'a t2]\n"]),
  Test
    ("datatype tagged_or_null h",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \H"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = H : ['a. 'a t2]\n"]),
  Test
    ("datatype tagged_or_null z4",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \Z 123"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = Z 123 : int t2\n"]),
  Test
    ("datatype tagged_or_null z8",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \Z 123.45"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = Z 123.45 : real t2\n"]),
  Test
    ("datatype tagged_or_null zh",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \Z H"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = Z H : ['a. 'a t2 t2]\n"]),
  Test
    ("datatype tagged_or_null nested",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \Z (Z (Z (Z 123)))"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = Z (Z (Z (Z 123))) : int t2 t2 t2 t2\n"]),
  Test
    ("datatype tagged_or_null turn",
     fn () =>
        testPrinter
          "datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H;\n\
          \Z (B (Z 123))"
          ["datatype 'a t2 = F of int * int | B of int t2 | Z of 'a | H\n",
           "val it = Z (B (Z 123)) : ['a. 'a t2 t2]\n"]),
  Test
    ("datatype arg_or_null(nowrap) b",
     fn () =>
        testPrinter
          "datatype t3 = F of int * t3 | B;\n\
          \B"
          ["datatype t3 = F of int * t3 | B\n",
           "val it = B : t3\n"]),
  Test
    ("datatype arg_or_null(nowrap) f",
     fn () =>
        testPrinter
          "datatype t3 = F of int * t3 | B;\n\
          \F (1, B)"
          ["datatype t3 = F of int * t3 | B\n",
           "val it = F (1, B) : t3\n"]),
  Test
    ("datatype arg_or_null(nowrap) nested",
     fn () =>
        testPrinter
          "datatype t3 = F of int * t3 | B;\n\
          \F (1, F (2, B))"
          ["datatype t3 = F of int * t3 | B\n",
           "val it = F (1, F (2, B)) : t3\n"]),
  Test
    ("datatype arg_or_null(wrap) n",
     fn () =>
        testPrinter
          "datatype t4 = I of int | N;\n\
          \N"
          ["datatype t4 = I of int | N\n",
           "val it = N : t4\n"]),
  Test
    ("datatype arg_or_null(wrap) i",
     fn () =>
        testPrinter
          "datatype t4 = I of int | N;\n\
          \I 123"
          ["datatype t4 = I of int | N\n",
           "val it = I 123 : t4\n"]),
  Test
    ("datatype arg_or_null(wrap) poly x",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X;\n\
          \X"
          ["datatype 'a t5 = M of 'a | X\n",
           "val it = X : ['a. 'a t5]\n"]),
  Test
    ("datatype arg_or_null(wrap) poly mx",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X;\n\
          \M X"
          ["datatype 'a t5 = M of 'a | X\n",
           "val it = M X : ['a. 'a t5 t5]\n"]),
  Test
    ("datatype arg_or_null(wrap) poly nested",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X;\n\
          \M (M (M 123))"
          ["datatype 'a t5 = M of 'a | X\n",
           "val it = M (M (M 123)) : int t5 t5 t5\n"]),
  Test
    ("datatype arg_or_null(wrap) rec z",
     fn () =>
        testPrinter
          "datatype t6 = S of t6 | Z;\n\
          \Z"
          ["datatype t6 = S of t6 | Z\n",
           "val it = Z : t6\n"]),
  Test
    ("datatype arg_or_null(wrap) rec sz",
     fn () =>
        testPrinter
          "datatype t6 = S of t6 | Z;\n\
          \S Z"
          ["datatype t6 = S of t6 | Z\n",
           "val it = S Z : t6\n"]),
  Test
    ("datatype arg_or_null(wrap) rec ssz",
     fn () =>
        testPrinter
          "datatype t6 = S of t6 | Z;\n\
          \S (S Z)"
          ["datatype t6 = S of t6 | Z\n",
           "val it = S (S Z) : t6\n"]),
  Test
    ("datatype arg_or_null(wrap) recnest b",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X\n\
          \datatype t7 = A of t7 t5 | B;\n\
          \B"
          ["datatype 'a t5 = M of 'a | X\n\
           \datatype t7 = A of t7 t5 | B\n",
           "val it = B : t7\n"]),
  Test
    ("datatype arg_or_null(wrap) recnest ax",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X\n\
          \datatype t7 = A of t7 t5 | B;\n\
          \A X"
          ["datatype 'a t5 = M of 'a | X\n\
           \datatype t7 = A of t7 t5 | B\n",
           "val it = A X : t7\n"]),
  Test
    ("datatype arg_or_null(wrap) recnest amb",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X\n\
          \datatype t7 = A of t7 t5 | B;\n\
          \A (M B)"
          ["datatype 'a t5 = M of 'a | X\n\
           \datatype t7 = A of t7 t5 | B\n",
           "val it = A (M B) : t7\n"]),
  Test
    ("datatype arg_or_null(wrap) recnest amax",
     fn () =>
        testPrinter
          "datatype 'a t5 = M of 'a | X\n\
          \datatype t7 = A of t7 t5 | B;\n\
          \A (M (A X))"
          ["datatype 'a t5 = M of 'a | X\n\
           \datatype t7 = A of t7 t5 | B\n",
           "val it = A (M (A X)) : t7\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual b",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \B"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = B : t8\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual ad",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \A D"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = A D : t8\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual acb",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \A (C B)"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = A (C B) : t8\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual acad",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \A (C (A D))"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = A (C (A D)) : t8\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual d",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \D"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = D : t9\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual cb",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \C B"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = C B : t9\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual cad",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \C (A D)"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = C (A D) : t9\n"]),
  Test
    ("datatype arg_or_null(wrap) mutual cacb",
     fn () =>
        testPrinter
          "datatype t8 = A of t9 | B and t9 = C of t8 | D;\n\
          \C (A (C B))"
          ["datatype t8 = A of t9 | B\n\
           \datatype t9 = C of t8 | D\n",
           "val it = C (A (C B)) : t9\n"]),
  Test
    ("datatype single_arg(nowrap)",
     fn () =>
        testPrinter
          "datatype tA = F of int * int;\n\
          \F (123, 456)"
          ["datatype tA = F of int * int\n",
           "val it = F (123, 456) : tA\n"]),
  Test
    ("datatype single_arg(nowrap) nested",
     fn () =>
        testPrinter
          "datatype tA = F of int * int\n\
          \datatype tB = G of tA;\n\
          \G (F (123, 456))"
          ["datatype tA = F of int * int\n\
           \datatype tB = G of tA\n",
           "val it = G (F (123, 456)) : tB\n"]),
  Test
    ("datatype single_arg(nowrap) rec",
     fn () =>
        testPrinter
          "datatype tC = V of unit -> tC;\n\
          \V (fn _ => raise Match)"
          ["datatype tC = V of unit -> tC\n",
           "val it = V fn : tC\n"]),
  Test
    ("datatype single_arg(wrap) poly",
     fn () =>
        testPrinter
          "datatype 'a tD = F of 'a;\n\
          \F 1"
          ["datatype 'a tD = F of 'a\n",
           "val it = F 1 : int tD\n"]),
  Test
    ("datatype single_arg(wrap) poly nest",
     fn () =>
        testPrinter
          "datatype 'a tD = F of 'a;\n\
          \F (F (F 1))"
          ["datatype 'a tD = F of 'a\n",
           "val it = F (F (F 1)) : int tD tD tD\n"]),
  Test
    ("datatype single_arg(wrap) int",
     fn () =>
        testPrinter
          "datatype tE = F of int;\n\
          \F 1"
          ["datatype tE = F of int\n",
           "val it = F 1 : tE\n"]),
  Test
    ("datatype tagonly f",
     fn () =>
        testPrinter
          "datatype tF = F | B | Z;\n\
          \F"
          ["datatype tF = F | B | Z\n",
           "val it = F : tF\n"]),
  Test
    ("datatype tagonly b",
     fn () =>
        testPrinter
          "datatype tF = F | B | Z;\n\
          \B"
          ["datatype tF = F | B | Z\n",
           "val it = B : tF\n"]),
  Test
    ("datatype tagonly z",
     fn () =>
        testPrinter
          "datatype tF = F | B | Z;\n\
          \Z"
          ["datatype tF = F | B | Z\n",
           "val it = Z : tF\n"]),
  Test
    ("datatype choice f",
     fn () =>
        testPrinter
          "datatype tG = F | B;\n\
          \F"
          ["datatype tG = F | B\n",
           "val it = F : tG\n"]),
  Test
    ("datatype choice b",
     fn () =>
        testPrinter
          "datatype tG = F | B;\n\
          \B"
          ["datatype tG = F | B\n",
           "val it = B : tG\n"]),
  Test
    ("datatype single",
     fn () =>
        testPrinter
          "datatype tH = F;\n\
          \F"
          ["datatype tH = F\n",
           "val it = F : tH\n"]),
  Test
    ("datatype phantom",
     fn () =>
        testPrinter
          "datatype ('a,'b) p = X of 'a;\n\
          \X 1"
          ["datatype ('a, 'b) p = X of 'a\n",
           "val it = X 1 : ['a. (int, 'a) p]\n"]),
  Test
    ("datatype polyrecmutual p",
     fn () =>
        testPrinter
          "datatype ('a,'b) t = F of ('a,'b) s | R of ('b,'a) s\n\
          \and ('a,'b) s = W of ('a,'b) t | P of 'a * 'b;\n\
          \P (1, #\"2\")"
          ["datatype ('a, 'b) t = F of ('a, 'b) s | R of ('b, 'a) s\n\
           \datatype ('a, 'b) s = W of ('a, 'b) t | P of 'a * 'b\n",
           "val it = P (1, #\"2\") : (int, char) s\n"]),
  Test
    ("datatype polyrecmutual wfp",
     fn () =>
        testPrinter
          "datatype ('a,'b) t = F of ('a,'b) s | R of ('b,'a) s\n\
          \and ('a,'b) s = W of ('a,'b) t | P of 'a * 'b;\n\
          \W (F (P (1, #\"2\")))"
          ["datatype ('a, 'b) t = F of ('a, 'b) s | R of ('b, 'a) s\n\
           \datatype ('a, 'b) s = W of ('a, 'b) t | P of 'a * 'b\n",
           "val it = W (F (P (1, #\"2\"))) : (int, char) s\n"]),
  Test
    ("datatype polyrecmutual wrp",
     fn () =>
        testPrinter
          "datatype ('a,'b) t = F of ('a,'b) s | R of ('b,'a) s\n\
          \and ('a,'b) s = W of ('a,'b) t | P of 'a * 'b;\n\
          \W (R (P (#\"2\", 1)))"
          ["datatype ('a, 'b) t = F of ('a, 'b) s | R of ('b, 'a) s\n\
           \datatype ('a, 'b) s = W of ('a, 'b) t | P of 'a * 'b\n",
           "val it = W (R (P (#\"2\", 1))) : (int, char) s\n"]),
  Test
    ("datatype polyrecmutual wfwrwfp",
     fn () =>
        testPrinter
          "datatype ('a,'b) t = F of ('a,'b) s | R of ('b,'a) s\n\
          \and ('a,'b) s = W of ('a,'b) t | P of 'a * 'b;\n\
          \W (F (W (R (W (F (P (1, #\"2\")))))))"
          ["datatype ('a, 'b) t = F of ('a, 'b) s | R of ('b, 'a) s\n\
           \datatype ('a, 'b) s = W of ('a, 'b) t | P of 'a * 'b\n",
           "val it = W (F (W (R (W (F (P (1, #\"2\"))))))) : (char, int) s\n"]),
  Test
    ("ptr null",
     fn () =>
        testPrinter
          "Pointer.NULL () : int ptr"
          ["val it = 0wx0 : int ptr\n"]),
  Test
    ("ptr nonnull",
     fn () =>
        testPrinter
          "SMLSharp_Builtin.Pointer.fromWord64 0wx12345678abcdef : int ptr"
          ["val it = 0wx12345678abcdef : int ptr\n"]),
  Test
    ("codeptr null",
     fn () =>
        testPrinter
          "SMLSharp_Builtin.Pointer.toCodeptr (Pointer.NULL ())"
          ["val it = 0wx0 : codeptr\n"]),
  Test
    ("codeptr nonnull",
     fn () =>
        testPrinter
          "SMLSharp_Builtin.Pointer.toCodeptr (SMLSharp_Builtin.Pointer.fromWord64 0wx12345678abcdef)"
          ["val it = 0wx12345678abcdef : codeptr\n"]),
  Test
    ("boxed",
     fn () =>
        testPrinter
          "SMLSharp_Builtin.Pointer.castToBoxed \"a\""
          ["val it = _ : boxed\n"]),
  Test
    ("structure transparent",
     fn () =>
        testPrinter
          "structure T1 : sig type t val x : t end = struct datatype t = x end;\n\
          \T1.x"
          ["structure T1 =\n\
           \  struct\n\
           \    type t = t\n\
           \    val x = x : t\n\
           \  end\n",
           "val it = x : T1.t\n"]),
  Test
    ("structure opaque",
     fn () =>
        testPrinter
          "structure T2 :> sig type t val x : t end = struct datatype t = x end;\n\
          \T2.x"
          ["structure T2 =\n\
           \  struct\n\
           \    type t  <hidden>\n\
           \    val x = _ : t\n\
           \  end\n",
           "val it = _ : T2.t\n"]),
  Test
    ("structure opaque poly",
     fn () =>
        testPrinter
          "structure T3 :> sig type 'a t val x : 'a t end = struct datatype 'a t = x end;\n\
          \T3.x"
          ["structure T3 =\n\
           \  struct\n\
           \    type 'a t  <hidden>\n\
           \    val x = _ : ['a. 'a t]\n\
           \  end\n",
           "val it = _ : ['a. 'a T3.t]\n"]),
  Test
    ("dummytype opaque",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.succ (DummyTyID.peek ()))
        in
          testPrinter
            "structure T3 :> sig type 'a t val x : 'a t end = struct datatype 'a t = x end;\n\
            \(fn x => x) T3.x"
            ["structure T3 =\n\
             \  struct\n\
             \    type 'a t  <hidden>\n\
             \    val x = _ : ['a. 'a t]\n\
             \  end\n",
             "val it = _ : ?X"^d^" T3.t\n"]
        end),
  Test
    ("datatype hidden",
     fn () =>
        testPrinter
          "datatype t1 = X;\n\
          \datatype t1 = Y;\n\
          \X;\n\
          \Y"
          ["datatype t1 = X\n",
           "datatype t1 = Y\n",
           "val it = X : ?.t1\n",
           "val it = Y : t1\n"]),
  Test
    ("dummytype idid",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) (fn x => x)"
            ["val it = fn : ?X"^d^" -> ?X"^d^"\n"]
        end),
  Test
    ("dummytype idsomenone",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) (SOME NONE)"
            ["val it = SOME NONE : ?X"^d^" option option\n"]
        end),
  Test
    ("dummytype listnil",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) [[]]"
            ["val it = [[]] : ?X"^d^" list list\n"]
        end),
  Test
    ("dummytype array",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "Array.array (0, nil)"
            ["val it = <> : ?X"^d^" list array\n"]
        end),
  Test
    ("dummytype vector",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "Vector.fromList nil"
            ["val it = <||> : ?X"^d^" vector\n"]
        end),
  Test
    ("dummytype ref",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "ref (ref nil)"
            ["val it = ref (ref []) : ?X"^d^" list ref ref\n"]
        end),
  Test
    ("dummytype select",
     fn () =>
        let
          val d1 = DummyTyID.snapToString (DummyTyID.peek ())
          val d2 = DummyTyID.snapToString (DummyTyID.succ (DummyTyID.peek ()))
        in
          testPrinter
            "(fn x => x) #a"
            ["val it = fn : ?X"^d1^" -> ?X"^d2^"\n"]
        end),
  Test
    ("dummytype eq",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) (op =)"
            ["val it = fn : ?X"^d^" * ?X"^d^" -> bool\n"]
        end),
  Test
    ("dummytype overloadkind",
     fn () =>
        testPrinter
          "(fn x => x) (op +)"
          ["val it = fn : int * int -> int\n"]),
  Test
    ("dummytype boxedkind",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) SMLSharp_Builtin.Pointer.castToBoxed"
            ["val it = fn : ?X"^d^" -> boxed\n"]
        end),
  Test
    ("dummytype reifykind",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) ReifyTerm.toReifiedTerm"
            ["val it = fn : ?X"^d^" -> Dynamic.term\n"]
        end),
(*
  (* json kind has been removed *)
  Test
    ("dummytype jsonkind",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) JSON.toJson"
            ["val it = fn : ?X"^d^" -> JSON.json\n"]
        end),
*)
  Test
    ("dummytype unboxed kind",
     fn () =>
        let
          val d = DummyTyID.snapToString (DummyTyID.peek ())
        in
          testPrinter
            "(fn x => x) (let fun 'a#unboxed f x = x :'a in f end)"
            ["val it = fn : ?X"^d^" -> ?X"^d^"\n"]
        end),

  TestList nil
]
end
