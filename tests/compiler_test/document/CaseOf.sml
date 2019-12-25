structure CaseOf =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testCaseOfInt () =
      let
        val _ = case 1 of
                     1 => ()
                   | _ => fail "NG"

        val _ = case 1 of
                     ~1 => fail "NG"
                   | _ => () 

        val _ = case ~1 of
                     ~1 => ()
                   | _ => fail "NG"

        val _ = case 3 of
                     1 => fail "NG"
                   | 2 => fail "NG"
                   | 3 => ()
                   | _ => fail "NG"

        val _ = case 0 of
                     ~0 => ()
                   | _ => fail "NG"
                   
        val _ = case 127 : int8 of
                     127 => ()
                   | _ => fail "NG"

        val _ = case 32767 : int16 of
                     32767 => ()
                   | _ => fail "NG"

        val _ = case 2147483647 : int32 of
                     2147483647 => ()
                   | _ => fail "NG"

        val _ = case 9223372036854775807 : int64 of
                     9223372036854775807 => ()
                   | _ => fail "NG"

        val _ = case 9223372036854775808 : intInf of
                     9223372036854775808 => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfIntFunction () =
      let
        fun f1 x = case x of
                        1 => ()
                      | _ => fail "NG"
        val v1 = f1 (1 : int)

        fun f2 x = case x of
                        127 => ()
                      | _ => fail "NG"
        val v2 = f2 (127 : int8)

        fun f3 x = case x of
                        32767 => ()
                      | _ => fail "NG"
        val v3 = f3 (32767 : int16)

        fun f4 x = case x of
                        2147483647 => ()
                      | _ => fail "NG"
        val v4 = f4 (2147483647 : int32)

        fun f5 x = case x of
                        9223372036854775807 => ()
                      | _ => fail "NG"
        val v5 = f5 (9223372036854775807 : int64)

        fun f6 x = case x of
                        9223372036854775808 => ()
                      | _ => fail "NG"
        val v6 = f6 (9223372036854775808 : intInf)
      in
        ()
      end

  fun testCaseOfWord () =
      let
        val _ = case 0w1 of
                     0w1 => ()
                   | _ => fail "NG"

        val _ = case 0w1 of
                     0w2 => fail "NG"
                   | _ => ()

        val _ = case 0wxFF : word8 of
                     0w255 => ()
                   | _ => fail "NG"

        val _ = case 0wxFFFF : word16 of
                     0w65535 => ()
                   | _ => fail "NG"

        val _ = case 0wxFFFFFFFF : word32 of
                     0w4294967295 => ()
                   | _ => fail "NG"

        val _ = case 0wxFFFFFFFFFFFFFFFF : word64 of
                     0w18446744073709551615 => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfWordFunction() =
      let
        fun f1 x = case x of
                        0w1 => ()
                      | _ => fail "NG"
        val v1 = f1 (0w1 : word)

        fun f2 x = case x of
                        0w255 => ()
                      | _ => fail "NG"
        val v2 = f2 (0wxFF : word8)

        fun f3 x = case x of
                        0w65535 => ()
                      | _ => fail "NG"
        val v3 = f3 (0wxFFFF : word16)

        fun f4 x = case x of
                        0w4294967295 => ()
                      | _ => fail "NG"
        val v4 = f4 (0wxFFFFFFFF : word32)

        fun f5 x = case x of
                        0w18446744073709551615 => ()
                      | _ => fail "NG"
        val v5 = f5 (0wxFFFFFFFFFFFFFFFF : word64)

      in
        ()
      end

  fun testCaseOfReal () =
      let
        val _ = case 1.0 of
                     n => ()

        val _ = case 1.0 : real32 of
                     n => ()
      in
        ()
      end

  fun testCaseOfRealFunction () =
      let
        fun f1 x = case x + 1.0 of
                        _ => ()
        val v1 = f1 (1.0 : real)

        fun f2 x = case x + 1.0 of
                        _ => ()
        val v2 = f2 (1.0 : real32)
      in
        ()
      end

  fun testCaseOfChar () =
      let
        val _ = case #"A" of
                     #"A" => ()
                   | _ => fail "NG"

        val _ = case #"a" of
                     #"A" => fail "NG"
                   | _ => ()

        val _ = case #"A" of
                     #"\065" => ()
                   | _ => fail "NG"

        val _ = case #"C" of
                     #"A" => fail "NG"
                   | #"B" => fail "NG"
                   | #"C" => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfCharFunction () =
      let
        fun f1 x = case x of
                        #"A" => ()
                      | _ => fail "NG"
        val v1 = f1 #"A"
      in
        ()
      end

  fun testCaseOfString () =
      let
        val _ = case "" of
                     "" => ()
                   | _ => fail "NG"

        val _ = case "ABC" of
                     "ABC" => ()
                   | _ => fail "NG"

        val _ = case "F" of
                     "ABC" => fail "NG"
                   | "DE" => fail "NG"
                   | "F" => ()
                   | _ => fail "NG"

        val _ = case "\255" of
                     "\u00FF" => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfStringFunction() =
      let
        fun f1 x = case x of
                        "ABC" => ()
                      | _ => fail "NG"
        val v1 = f1 "ABC"
      in
        ()
      end

  fun testCaseOfConstructor () =
      let
        datatype dt1 = DT1
                     | DT2
        fun f1 x = case x of
                        DT1 => ()
                      | DT2 => fail "NG"
        val v1 = f1 DT1

        fun f2 x = case x of
                        DT1 => ()
                      | _ => fail "NG"
        val v2 = f2 DT1

        fun f4 x = case x of
                        x as DT1 => x
                      | x : dt1 as DT2 => x
        val v4 = f4 DT1
        val v5 = f4 DT2
        val _ = assertTrue (v4 = DT1)
        val _ = assertTrue (v5 = DT2)
      in
        ()
      end

  fun testCaseOfRecord () =
      let
        val _ = case {} of
                     {} => ()

        val _ = case {} of
                     {...} => ()

        val _ = case {A=1} of
                     {A=1} => ()
                   | {A=n} => fail "NG"

        val _ = case {A=1, B="A"} of
                     {A=1, B="B"} => fail "NG"
                   | {A=2, B="A"} => fail "NG"
                   | {A=1, B="A"} => ()
                   | _ => fail "NG"

        val _ = case {A=1, B="A"} of
                     {A : int as 2, B="A"} => fail "NG"
                   | {A : int as x, B="A"} => (assertEqualInt 1 A;
                                               assertEqualInt 1 x)
                   | _ => fail "NG"

        val _ = case {A=1, B="A"} of
                     v as {A : int as 2, ...} => fail "NG"
                   | v as {A : int as 1, ...} => (assertTrue ({A=1, B="A"} = v);
                                                  assertEqualInt 1 A)
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfRecordFunction () =
      let
        fun f1 x = case x of
                        {...} => x
        val v1 = f1 {}
        val v2 = f1 {A=1}
        val v3 = f1 {A=1, B="A"}
        val v4 = f1 {A=fn x => x}

        fun f2 x = case {A=1} of
                        {A as x} => x
        val v5 = f2 ()
        val _ = assertEqualInt 1 v5

        fun f3 x = case x of
                        {...}:{A:'a} => x
        val v6 = f3 {A=1}
        val v7 = f3 {A="A"}
        val _ = assertTrue ({A=1} = v6)
        val _ = assertTrue ({A="A"} = v7)

        fun f4 x = case x of
                        {A=x, ...} => x
        val v8 = f4 {A=1, B="A"}
        val v9 = f4 {A="A", C=1}
        val _ = assertEqualInt 1 v8
        val _ = assertEqualString "A" v9
      in
        ()
      end

  fun testCaseOfTuple () =
      let
        val _ = case () of
                     () => ()

        val _ = case (1, "A") of
                     (1, "A") => ()
                   | _ => fail "NG"

        val _ = case (1, "A") of
                     {1 = 1, 2 = "A"} => ()
                   | _ => fail "NG"

        val _ = case (1, "A") of
                     {1 = 1, ...} => ()
                   | _ => fail "NG"

        val _ = case (1, "A") of
                     (x as 1, y as "B") => fail "NG"
                   | (x as 2, y as "A") => fail "NG"
                   | (x as 1, y as "A") => (assertEqualInt 1 x;
                                            assertEqualString "A" y)
                   | _ => fail "NG"

        val _ = case (1, 2, 3) of
                     (1, 1, _) => fail "NG"
                   | (_, 2, 2) => fail "NG"
                   | (3, _, 3) => fail "NG"
                   | (1, 2, 3) => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfTupleFunction () =
      let
        fun f1 x = case x of
                        (n, m) => ()
        val v1 = f1 (1, 2)
        val v2 = f1 ("A", "B")
        val v3 = f1 (1, "A")

        fun f2 x = case x of
                        (n, m) : 'a * 'a => ()
        val v4 = f2 (1, 2)
        val v5 = f2 ("A", "B")

        fun f3 x = case x of
                        (1, m) => ()
                      | _ => fail "NG"
        val v6 = f3 (1, 2)
        val v7 = f3 (1, "A")
      in
        ()
      end

  fun testCaseOfList () =
      let
        val _ = case [] of
                     [] => ()
                   | _ => fail "NG"

        val _ = case [1] of
                     [1] => ()
                   | _ => fail "NG"

        val _ = case [1,2,3] of
                     [1] => fail "NG"
                   | [1,2] => fail "NG"
                   | [1,2,3] => ()
                   | _ => fail "NG"

        val _ = case [1,2,3] of
                     [1] => fail "NG"
                   | [1,2] => fail "NG"
                   | (1::2::[3]) => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfListFunction () =
      let
        fun f1 x = case [x] of
                        [x] => x
                      | _ => fail "NG"
        val v1 = f1 1
        val v2 = f1 "A"
        val _ = assertEqualInt 1 v1
        val _ = assertEqualString "A" v2

        fun f2 x = case x of
                        [x:'a] => x
                      | _ => fail "NG"
        val v3 = f2 [1]
        val v4 = f2 ["A"]
        val _ = assertEqualInt 1 v3
        val _ = assertEqualString "A" v4
      in
        ()
      end


  fun testCaseOfInfix () =
      let
        datatype dt1 = OP1 of dt1 * dt1
                     | V1
                     | V2
                     | V3
        val v1 = OP1 (V1, V2)
        infix OP1
        val _ = case v1 of
                     V1 OP1 V2 => ()
                   | _ => fail "NG"

        val v2 = V1 OP1 V2 OP1 V3
        val (v3, v4) = case v2 of
                            x OP1 y => (x, y)
                          | _ => fail "NG"
        val _ = assertTrue (op OP1 (V1, V2) = v3)
        val _ = assertTrue (V3 = v4)
      in
        ()
      end

  fun testCaseOfInfixr () =
      let
        datatype dt1 = OP1 of dt1 * dt1
                     | V1
                     | V2
                     | V3
        val v1 = OP1 (V1, V2)
        infixr OP1
        val _ = case v1 of
                     V1 OP1 V2 => ()
                   | _ => fail "NG"

        val v2 = V1 OP1 V2 OP1 V3
        val (v3, v4) = case v2 of
                            x OP1 y => (x, y)
                          | _ => fail "NG"
        val _ = assertTrue (V1 = v3)
        val _ = assertTrue (op OP1 (V2, V3) = v4)
      in
        ()
      end

  fun testCaseOfInfixLevel () =
      let
        datatype dt1 = OP1 of int * dt1
                     | OP2 of dt1 * string
                     | V1

        val v1 = OP2 (OP1 (1, V1), "A")
        infix 3 OP1
        infix 2 OP2
        val _ = case v1 of
                     1 OP1 (V1 OP2 "A") => fail "NG"
                   | 1 OP1 V1 OP2 "A" => ()
                   | _ => fail "NG"

        infix 4 OP2
        val _ = case v1 of
                     1 OP1 V1 OP2 "A" => fail "NG"
                   | (1 OP1 V1) OP2 "A" => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testCaseOfLayeredPattern () =
      let
        val _ = case 1 of 
                     x as 2 => fail "NG"
                   | x as 1 => ()
                   | _ => fail "NG"
                   
        fun f1 x = case x of 
                     x : {A:int, B:string} as {A=2, ...} => fail "NG"
                   | x as {A=1, ...} => x
                   | _ => fail "NG"
        val v1 = f1 {A=1, B="A"}
        val _ = assertTrue ({A=1, B="A"} = v1)
      in
        ()
      end

  fun testCaseOfPolymorphicFunction() =
      let
        fun f1 x = case x of
                        v => v
        val v1 = f1 1
        val v2 = f1 "ABC"
        val v3 = f1 (1, 2)
        val v4 = f1 {A = 1, B = "A"}
        val v5 = f1 [1, 2]

        val _ = assertEqualInt 1 v1
        val _ = assertEqualString "ABC" v2
        val _ = assertTrue ((1, 2) = v3)
        val _ = assertTrue ({A = 1, B = "A"} = v4)
        val _ = assertTrue ([1, 2] = v5)

        fun f2 x = case x of
                        v : 'a => v
        val v6 = f2 1
        val v7 = f2 "ABC"
        val _ = assertEqualInt 1 v6
        val _ = assertEqualString "ABC" v7

        fun f3 x = case x of
                        v : 'a as y => v
        val v8 = f3 1
        val v9 = f3 "ABC"
        val _ = assertEqualInt 1 v8
        val _ = assertEqualString "ABC" v9
      in
        ()
      end


  val tests = TestList [
    Test ("testCaseOfInt", testCaseOfInt),
    Test ("testCaseOfIntFunction", testCaseOfIntFunction),
    Test ("testCaseOfWord", testCaseOfWord),
    Test ("testCaseOfWordFunction", testCaseOfWordFunction),
    Test ("testCaseOfReal", testCaseOfReal),
    Test ("testCaseOfRealFunction", testCaseOfRealFunction),
    Test ("testCaseOfChar", testCaseOfChar),
    Test ("testCaseOfCharFunction", testCaseOfCharFunction),
    Test ("testCaseOfString", testCaseOfString),
    Test ("testCaseOfStringFunction", testCaseOfStringFunction),
    Test ("testCaseOfConstructor", testCaseOfConstructor),
    Test ("testCaseOfRecord", testCaseOfRecord),
    Test ("testCaseOfRecordFunction", testCaseOfRecordFunction),
    Test ("testCaseOfTuple", testCaseOfTuple),
    Test ("testCaseOfTupleFunction", testCaseOfTupleFunction),
    Test ("testCaseOfList", testCaseOfList),
    Test ("testCaseOfListFunction", testCaseOfListFunction),
    Test ("testCaseOfInfix", testCaseOfInfix),
    Test ("testCaseOfInfixr", testCaseOfInfixr),
    Test ("testCaseOfInfixLevel", testCaseOfInfixLevel),
    Test ("testCaseOfLayeredPattern", testCaseOfLayeredPattern),
    Test ("testCaseOfPolymorphicFunction", testCaseOfPolymorphicFunction)
  ]

end
