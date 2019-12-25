structure Expression =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testAndAlso () =
      let
        val _ = assertTrue (true andalso true)
        val _ = assertFalse (true andalso false)
        val _ = assertFalse (false andalso true)
        val _ = assertFalse (false andalso false)

        val v1 = ref "Before1"
        val _ = assertFalse (false andalso (v1 := "After1"; true))
        val _ = assertEqualString (!v1) "Before1"
        
        val v2 = ref "Before2"
        val _ = assertTrue (true andalso (v2 := "After2"; true))
        val _ = assertEqualString (!v2) "After2"

        fun f1 x y = x andalso y
        val f2 = f1 true
        val v3 = f2 false
        val _ = assertFalse v3

        fun f4 x y z = x y z
        val f5 = f4 (fn x => (fn y => x andalso y))
        val _ = assertFalse (f5 true false)
      in
        ()
      end

  fun testOrElse () =
      let
        val _ = assertTrue (true orelse true)
        val _ = assertTrue (true orelse false)
        val _ = assertTrue (false orelse true)
        val _ = assertFalse (false orelse false)

        val v1 = ref "Before1"
        val _ = assertTrue (true orelse (v1 := "After1"; false))
        val _ = assertEqualString (!v1) "Before1"
        
        val v2 = ref "Before2"
        val _ = assertFalse (false orelse (v2 := "After2"; false))
        val _ = assertEqualString (!v2) "After2"

        fun f1 x y = x orelse y
        val f2 = f1 false
        val v3 = f2 true
        val _ = assertTrue v3

        fun f4 x y z = x y z
        val f5 = f4 (fn x => (fn y => x orelse y))
        val _ = assertTrue (f5 false true)
      in
        ()
      end

  fun testIf () =
      let
        exception Exn1
        exception Exn2
        val _ = assertTrue (if true then true else raise Exn1)
        val _ = assertTrue (if false then raise Exn1 else true)

        val _ = assertTrue ((if raise Exn1 then raise Exn2 else raise Exn2)
                            handle Exn1 => true)
      in
        ()
      end

  fun testIfEvalOrder () =
      let
        exception Exn1

        val ref1 = ref false
        val _ = assertTrue ((if (ref1 := true; true) then raise Exn1 else false)
                            handle Exn1 => true)
        val _ = assertTrue (!ref1)

        val ref2 = ref false
        val _ = assertTrue ((if (ref2 := true; false) then false else raise Exn1)
                            handle Exn1 => true)
        val _ = assertTrue (!ref2)
      in
        ()
      end

  fun testIfDummyType () =
      let
        val f1 = fn a => fn x => fn y => fn z => a x y z
        val f2 = f1 (fn x => fn y => fn z => if z then x else y)
      in
        ()
      end

  fun testIfFunction () =
      let
        val f1 = fn a => fn x => fn y => fn z => a x y z
        val f2 = f1 (fn x => fn y => fn z => if z then x else y)
        val f3 = f2 1
        val f4 = f3 2
        val v1 = f4 true
        val _ = assertEqualInt 1 v1

        val f5 = f1 (fn x => fn y => fn z => if z then x else y)
        val f6 = f5 "A"
        val f7 = f6 "B"
        val v2 = f7 false
        val _ = assertEqualString "B" v2
      in
        ()
      end

  fun testWhile () =
      let
        val v1 = while false do 1
        val _ = assertEqualUnit () v1

        val ref1 = ref 0
        val v1 = while !ref1 < 5 do (ref1 := (!ref1 + 1))
        val _ = assertEqualUnit () v1
        val _ = assertEqualInt 5 (!ref1)
      in
        ()
      end

  fun testWhileEvalOrder () =
      let
        val ref1 = ref false
        val ref2 = ref false

        val v1 = while (ref1 := true; false) do (ref2 := true)
        val _ = assertEqualUnit () v1
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
      in
        ()
      end

  fun testRecord () =
      let
        val v1 = {A = 1, B = 2, C = "A"}
        val _ = assertTrue ({A = 1, B = 2, C = "A"} = v1)
        val _ = assertTrue ({A = 2, B = 2, C = "A"} <> v1)
        val _ = assertTrue ({A = 1, B = 2, C = "B"} <> v1)

        val _ = assertTrue ({} = {})
      in
        ()
      end

  fun testRecordEvalOrder() =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val v1 = {A = (ref1 := true; 1), C = raise Exn1, B = (ref2 := true; 2)}
                 handle Exn1 => {A = 4, B = 5, C = "B"}
        val _ = assertTrue ({A = 4, B = 5, C = "B"} = v1)
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
      in
        ()
      end

  fun testRecordRank1 () =
      let
        fun f1 x y = {A = x, B = y}
        val f2 = f1 1
        val v1 = f2 0x2
        val v2 = f2 "A"
        
        val _ = assertTrue ({A = 1, B = 0x2} = v1)
        val _ = assertTrue ({A = 1, B = "A"} = v2)
      in
        ()
      end

  fun testRecordDummyType () =
      let
        val v1 = {A = 1, B = fn x => x}
        val f1 = #B v1
      in
        ()
      end

  fun testRecordFunction () =
      let
        val v1 = {A = 1, B = fn x => x}
        val f1 = #B v1
        val f2 = #B v1
        val _ = assertEqualInt 1 (f1 1)
        val _ = assertEqualString "A" (f2 "A")
      in
        ()
      end

  fun testTuple () =
      let
        val v1 = (1, 2, "A")
        val _ = assertTrue ((1, 2, "A") = v1)
        val _ = assertTrue ((2, 2, "A") <> v1)
        val _ = assertTrue ((1, 2, "B") <> v1)
        val _ = assertTrue ({1 = 1, 2 = 2, 3 = "A"} = v1)

        val _ = assertTrue (() = ())
      in
        ()
      end

  fun testTupleEvalOrder () =
      let
        exception Exn1
        val ref1 = ref false
        val ref2 = ref false
        val v1 = ((ref1 := true; 1),
                  raise Exn1,
                  (ref2 := true; 3))
                 handle Exn1 => (4, 5, 6)
        val _ = assertTrue ((4, 5, 6) = v1)
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
      in
        ()
      end

  fun testTupleRank1 () =
      let
        fun f1 x y = (x, y)
        val f2 = f1 1
        val v1 = f2 0w2
        val v2 = f2 "A"

        val _ = assertTrue ((1, 0w2) = v1)
        val _ = assertTrue ((1, "A") = v2)
      in
        ()
      end

  fun testFieldSelector () =
      let
        val v1 = (1, 2, "A")
        val _ = assertEqualInt 1 (#1 v1)
        val _ = assertEqualInt 2 (#2 v1)
        val _ = assertEqualString "A" (#3 v1)

        val v2 = {A = 1, B = 2, C = "A"}
        val _ = assertEqualInt 1 (#A v2)
        val _ = assertEqualInt 2 (#B v2)
        val _ = assertEqualString "A" (#C v2)
      in
        ()
      end

  fun testFieldSelectorFunction () =
      let
        fun f1 x y = x y
        val f2 = f1 #2
        val f3 = f1 #2
        val v1 = f2 (1, 2)
        val v2 = f3 (1, "A")

        val _ = assertEqualInt 2 v1
        val _ = assertEqualString "A" v2
      in
        ()
      end

  fun testList () =
      let
        fun f1 x y = [x, y]
        val f2 = f1 1
        val v1 = f2 2
        val f3 = f1 "A"
        val v2 = f3 "B"

        val _ = assertEqualIntList [1, 2] v1
        val _ = assertEqualStringList ["A", "B"] v2
      in
        ()
      end

  fun testListEvalOrder () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val v1 = [(ref1 := true; 1),
                  raise Exn1,
                  (ref2 := true; 1)]
                 handle Exn1 => [1, 2, 3, 4]
        val _ = assertEqualIntList [1, 2, 3, 4] v1
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
      in
        ()
      end


  fun testSequentialExecution () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val v1 = ((ref1 := true; 1); raise Exn1; (ref2 := true; 1))
                 handle Exn1 => 4
        val _ = assertEqualInt 4 v1
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)

        val f1 = (fn x => fn y => fn z => (x y; z))
        val ref3 = ref 1
        val f2 = f1 (fn x => ref3 := x)
        val f3 = f2 2 
        val v2 = f3 3
        val _ = assertEqualInt 3 v2
        val _ = assertEqualInt 2 (!ref3)

        val ref4 = ref "A"
        val f4 = f1 (fn x => ref4 := x)
        val f5 = f4 "B"
        val v3 = f5 "C"
        val _ = assertEqualString "C" v3
        val _ = assertEqualString "B" (!ref4)
      in
        ()
      end

  fun testLocalDeclarationShadowing () =
      let

        val v1 = 1
        val v2 = 2
        val v3 = let
                   val v1 = 3
                 in
                   assertEqualInt 3 v1;
                   v2
                 end
        val _ = assertEqualInt 1 v1
        val _ = assertEqualInt 2 v3
      in
        ()
      end

  fun testLocalDeclarationEvalOrder1 () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val v1 = let
                   val _ = ref1 := true
                   val _ = raise Exn1
                   val _ = ref2 := false
                 in
                   false
                 end 
                 handle Exn1 => true

        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
        val _ = assertTrue v1
      in
        ()
      end

  fun testLocalDeclarationEvalOrder2 () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val v1 = let
                 in
                   ref1 := true;
                   raise Exn1;
                   ref2 := true;
                   false
                 end 
                 handle Exn1 => true

        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
        val _ = assertTrue v1
      in
        ()
      end

  fun testFunctionApplicationEvalOrder1 () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val v1 = (ref1 := true; fn x => (ref2 := true; x))
                 (raise Exn1; false)
                 handle Exn1 => true

        val _ = assertTrue v1
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref2)
      in
        ()
      end

  fun testFunctionApplicationEvalOrder2 () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val ref3 = ref false
        val ref4 = ref false
        val v1 = (ref1 := true; 
                  fn x => (ref2 := true; fn y => (ref3 := true; false)))
                 (ref4 := true; 1)
                 (raise Exn1; 1)
                 handle Exn1 => true

        val _ = assertTrue v1
        val _ = assertTrue (!ref1)
        val _ = assertTrue (!ref2)
        val _ = assertFalse (!ref3)
        val _ = assertTrue (!ref4)
      in
        ()
      end

  fun testFieldUpdate () =
      let
        val v1 = {A = 1, C = 2, B = "A"} # {}
        val _ = assertTrue ({A = 1, B = "A", C = 2} = v1)

        val v2 = {A = 1, C = 2, B = "A"} # {A = 3}
        val _ = assertTrue ({A = 3, B = "A", C = 2} = v2)

        val v3 = {A = 1, C = 2, B = "A"} # {B = "B", C = 3}
        val _ = assertTrue ({A = 1, B = "B", C = 3} = v3)

        val v4 = {A = 1, C = 2, B = "A"}
        val v5 = v4 # {B = "B", C = 3}
        val _ = assertTrue ({A = 1, B = "B", C = 3} = v5)

        val v6 = {A = 1, C = 2, B = (fn x => x)}
        val _ = v6 # {B = (fn x => 1)}
      in
        ()
      end

  fun testFieldUpdateDummyType () =
      let
        fun f1 x y = x y # {A = 2}
        val f2 = f1 (fn x => x # {B = "B"})
      in
        ()
      end

  fun testFieldUpdateFunction () =
      let
        val f1 = fn x => fn y => x y # {A = 2}
        val f2 = f1 (fn x => x # {B = "B"})
        val f3 = f1 (fn x => x # {B = "B"})
        val v1 = f2 {A = 1, C = 2, B = "A"}
        val v2 = f3 {A = 1, D = 0w1, B = "A"}

        val _ = assertTrue ({A = 2, B = "B", C = 2} = v1)
        val _ = assertTrue ({A = 2, B = "B", D = 0w1} = v2)
      in
        ()
      end

  fun testFieldUpdateEvalOrder1 () =
      let
        exception Exn1

        val ref1 = ref false
        val ref2 = ref false
        val ref3 = ref false
        val ref4 = ref false
        val ref6 = ref false
        val v1 = {A = (ref1 := true; 1), 
                  B = (ref2 := true; 2),
                  C = (ref3 := true; 3)}
                 # {B = (ref4 := true; 4), 
                    A = (raise Exn1; 5), 
                    C = (ref6 := true; 6)}
                 handle Exn1 => {A = 7, B = 8, C = 9}

        val _ = assertTrue ({A = 7, B = 8, C = 9} = v1)
        val _ = assertTrue (!ref1)
        val _ = assertTrue (!ref2)
        val _ = assertTrue (!ref3)
        val _ = assertTrue (!ref4)
        val _ = assertFalse (!ref6)
      in
        ()
      end

  fun testFieldUpdateEvalOrder2 () =
      let
        exception Exn1

        val ref1 = ref false
        val ref3 = ref false
        val ref4 = ref false
        val ref5 = ref false
        val ref6 = ref false
        val v1 = {A = (ref1 := true; 1), 
                  C = (raise Exn1; 2),
                  B = (ref3 := true; 3)}
                 # {B = (ref4 := true; 4), 
                    A = (ref5 := true; 5), 
                    C = (ref6 := true; 6)}
                 handle Exn1 => {A = 7, B = 8, C = 9}

        val _ = assertTrue ({A = 7, B = 8, C = 9} = v1)
        val _ = assertTrue (!ref1)
        val _ = assertFalse (!ref3)
        val _ = assertFalse (!ref4)
        val _ = assertFalse (!ref5)
        val _ = assertFalse (!ref6)
      in
        ()
      end

  fun testFieldUpdateRank1 () =
      let
        fun f1 x y z = {A = y} # {A = z}
        val f2 = f1 1
        val f3 = f2 2
        val v1 = f3 3

        val _ = assertTrue ({A = 3} = v1)
      in
        ()
      end

  fun testRaise () =
      let
        exception Exn1
        val _ = assertTrue (true handle x => false)
        val _ = assertTrue ((raise Exn1) handle x => true)
        val _ = assertTrue ((raise raise Exn1) handle x => true)
        val f1 = (fn exn1 => assertTrue ((raise exn1) handle Exn1 => true))
        val _ = f1 Exn1
      in
        ()
      end

  fun testException () =
      let
        exception Exn1
        exception Exn2
        exception Exn3 of int
        exception Exn4 of exn
        datatype d1 = A of exn
        val E1 = Exn1
        val E3 = Exn3 1
        val E4 = Exn4 E3
        val A1 = A E3

        val _ = case E1 of 
                     Exn2 => fail "NG E1"
                   | Exn3 _ => fail "NG E1"
                   | Exn1 => ()
                   | _ => fail "NG E1"

        val _ = case E3 of
                     Exn3 0 => fail "NG E3"
                   | Exn3 1 => ()
                   | Exn3 _ => fail "NG E3"
                   | _ => fail "NG E3"

        val _ = case E4 of
                     Exn4 Exn1 => fail "NG E4"
                   | Exn4 Exn2 => fail "NG E4"
                   | Exn4 (Exn3 0) => fail "NG E4"
                   | Exn4 (Exn3 1) => ()
                   | _ => fail "NG E4"

        val _ = case A1 of
                     A Exn1 => fail "NG A1"
                   | A Exn2 => fail "NG A1"
                   | A (Exn3 0) => fail "NG A1"
                   | A (Exn3 1) => ()
                   | A _ => fail "NG A1"
      in
        ()
      end

  fun testIntOverflow () =
      let
        val _ = (valOf Int.maxInt + 1; fail "fail IntOverflow")
                handle Overflow => ()
        val _ = (valOf Int8.maxInt + 1; fail "fail Int8Overflow")
                handle Overflow => ()
        val _ = (valOf Int16.maxInt + 1; fail "fail Int16Overflow")
                handle Overflow => ()
        val _ = (valOf Int32.maxInt + 1; fail "fail Int32Overflow")
                handle Overflow => ()
        val _ = (valOf Int64.maxInt + 1; fail "fail Int64Overflow")
                handle Overflow => ()
      in
        ()
      end
  
  fun testWordOverflow () =
      let
        open Word
        val _ = assertEqualWord 0w0 (<< (0w1, Word.fromInt wordSize))

        open Word8
        val _ = assertEqualWord8 0w0 (<< (0w1, Word.fromInt wordSize))

        open Word16
        fun assertEqualWord16 expected actual =
            assertEqualByCompare compare toString expected actual
        val _ = assertEqualWord16 0w0 (<< (0w1, Word.fromInt wordSize))

        open Word32
        val _ = assertEqualWord32 0w0 (<< (0w1, Word.fromInt wordSize))

        open Word64
        fun assertEqualWord64 expected actual =
            assertEqualByCompare compare toString expected actual
        val _ = assertEqualWord64 0w0 (<< (0w1, Word.fromInt wordSize))
      in
        ()
      end
  
  val tests = TestList [
    Test ("testAndAlso", testAndAlso),
    Test ("testOrElse", testOrElse),
    Test ("testIf", testIf),
    Test ("testIfEvalOrder", testIfEvalOrder),
    Test ("testIfDummyType", testIfDummyType),
    Test ("testWhile", testWhile),
    Test ("testWhileEvalOrder", testWhileEvalOrder),
    Test ("testIfFunction", testIfFunction),
    Test ("testRecord", testRecord),
    Test ("testRecordEvalOrder", testRecordEvalOrder),
    Test ("testRecordRank1", testRecordRank1),
    Test ("testRecordFunction", testRecordFunction),
    Test ("testTuple", testTuple),
    Test ("testTupleEvalOrder", testTupleEvalOrder),
    Test ("testTupleRank1", testTupleRank1),
    Test ("testFieldSelector", testFieldSelector),
    Test ("testFieldSelectorFunction", testFieldSelectorFunction),
    Test ("testList", testList),
    Test ("testListEvalOrder", testListEvalOrder),
    Test ("testSequentialExecution", testSequentialExecution),
    Test ("testLocalDeclarationShadowing", testLocalDeclarationShadowing),
    Test ("testLocalDeclarationEvalOrder1", testLocalDeclarationEvalOrder1),
    Test ("testLocalDeclarationEvalOrder2", testLocalDeclarationEvalOrder2),
    Test ("testFunctionApplicationEvalOrder1", testFunctionApplicationEvalOrder1),
    Test ("testFunctionApplicationEvalOrder2", testFunctionApplicationEvalOrder2),
    Test ("testFieldUpdate", testFieldUpdate),
    Test ("testFieldUpdateDummyType", testFieldUpdateDummyType),
    Test ("testFieldUpdateFunction", testFieldUpdateFunction),
    Test ("testFieldUpdateEvalOrder1", testFieldUpdateEvalOrder1),
    Test ("testFieldUpdateEvalOrder2", testFieldUpdateEvalOrder2),
    Test ("testFieldUpdateRank1", testFieldUpdateRank1),
    Test ("testRaise", testRaise),
    Test ("testException", testException),
    Test ("testIntOverflow", testIntOverflow),
    Test ("testWordOverflow", testWordOverflow)
  ]

end
