structure ScopeRule =
struct
open SMLUnit.Test SMLUnit.Assert

  structure S1 = struct
      val A = 1
      type A = int
      structure S2 = struct
          val A = 2
      end
  end

  structure S1 = struct
      val A = 3
      type A = string
      structure S2 = struct
          val A = 4
          datatype d1 = B
          exception E1
          datatype A1 = A1 of A
      end
      val d1B = S2.B
      val E2 = S2.E1
      val A = 5
      type A = bool
      structure S3 = S1
  end
  structure S1 = S1

  type A = word

  fun testVID () =
      let
        val A = "A"
        datatype A = B
        val _ = assertEqualString "A" A

        datatype A = A
                   | C
        val _ = assertTrue (A <> C)
      in
        ()
      end

  fun testVIDFun () =
      let
        val A = 1
        fun f1 (0, _) = A
          | f1 (A, 0) = A + 1
          | f1 (_, B) = A + B + 2
        val _ = assertEqualInt 1 (f1 (0, 2))
        val _ = assertEqualInt 3 (f1 (2, 0))
        val _ = assertEqualInt 6 (f1 (2, 3))
      in
        ()
      end

  fun testVIDFunSameName () =
      let
        fun A A = A
        val _ = assertEqualInt 2 (A 2)
      in
        ()
      end

  fun testVIDFunRec () =
      let
        fun A x = if true then 1 else A x
        val _ = assertEqualInt 1 (A 2)
      in
        ()
      end

  fun testVIDFunLet () =
      let
        fun A x =
            let
              fun A x = if true then x else A x
            in
              A
            end
        val _ = assertEqualInt 2 (A 1 2)
      in
        ()
      end

  fun testVIDFn1 () =
      let
        val A = 1
        val f1 = fn (0, _) => A
                  | (A, 0) => A + 1
                  | (_, B) => A + B + 2
        val _ = assertEqualInt 1 (f1 (0, 2))
        val _ = assertEqualInt 3 (f1 (2, 0))
        val _ = assertEqualInt 6 (f1 (2, 3))
      in
        ()
      end

  fun testVIDFn2 () =
      let
        val A = 1
        val _ = assertEqualInt 3 ((fn A => (fn A => A)) 2 3)
      in
        ()
      end

  fun testVIDFnDatatype () =
      let
        datatype d1 = A
        val _ = assertTrue (A = ((fn A => A) A))
      in
        ()
      end

  fun testVIDCase () =
      let
        val A = 1
        val v1 = case (0, 2) of
                      (0, _) => A
                    | (A, 0) => A + 1
                    | (_, B) => A + B + 2

        val v2 = case (2, 0) of
                      (0, _) => A
                    | (A, 0) => A + 1
                    | (_, B) => A + B + 2

        val v3 = case (2, 3) of
                      (0, _) => A
                    | (A, 0) => A + 1
                    | (_, B) => A + B + 2

        val _ = assertEqualInt 1 v1
        val _ = assertEqualInt 3 v2
        val _ = assertEqualInt 6 v3
      in
        ()
      end

  fun testVIDCaseDatatype () =
      let
        datatype d1 = A
        val v1 = case A of
                      A => A
        val _ = assertTrue (v1 = A)
      in
        ()
      end

  fun testVIDStruct () =
      let
        val A = 1
        val _ = assertEqualInt 1 S1.S3.A
        val _ = assertEqualInt 2 S1.S3.S2.A
        val _ = assertEqualInt 4 S1.S2.A
        val _ = assertEqualInt 5 S1.A
        val _ = assertTrue (S1.S2.B = S1.d1B)
        val _ = case S1.E2 of
                     S1.S2.E1 => ()
                   | _ => fail "NG"
      in
        ()
      end

  fun testVIDLocal () =
      let
        val A = 1
        val B = 2
        val C = 3
        local
          val _ = assertEqualInt 1 A
          val A = 4 
          val _ = assertEqualInt 4 A
          datatype d1 = C
        in
          val _ = assertEqualInt 4 A
          val _ = assertEqualInt 2 B
          val B = 5
          val _ = assertEqualInt 5 B
        end

        val _ = assertEqualInt 1 A
        val _ = assertEqualInt 5 B
        val _ = assertEqualInt 3 C
      in
        ()
      end

  fun testVIDLet () =
      let
        val A = 1
        val B = 2
        val C = 3
        val _ = 
            let 
              val _ = assertEqualInt 1 A
              val A = 4 
              val _ = assertEqualInt 4 A
              datatype d1 = C
            in
              assertEqualInt 4 A;
              assertEqualInt 2 B
            end

        val _ = assertEqualInt 1 A
        val _ = assertEqualInt 3 C
      in
        ()
      end

  fun testVIDExn () =
      let
        datatype A = A
        exception A of int
        val B = 1
        val v1 = (raise A 2; B) handle A B => B
        val _ = assertEqualInt 2 v1

        val v2 = (raise A 2) handle A B => (raise A 3) handle A B => B
        val _ = assertEqualInt 3 v2
      in
        ()
      end

  fun testTycon () =
      let
        type A = int
        type A = A
        datatype B = A of A
        type A = string
        val _ = A 1

        datatype A = A1 of A 
                   | A2
        val _ = A1 (A1 A2)
      in
        ()
      end

  fun testTyconStruct () =
      let
        val _ = S1.S2.A1 "A"
      in
        ()
      end

  fun testTyconLocal () =
      let
        type A = int
        local
          datatype A1 = A1 of A
          type A = string
        in
          val A2 = A1
          type A = A
          datatype A3 = A3 of A
        end

        datatype A4 = A4 of A
        val _ = A2 1
        val _ = A3 "A"
        val _ = A4 "A"
      in
        ()
      end

  fun testTyconLet () =
      let
        type A = int
        val _ = 
           let 
             datatype A1 = A1 of A
             type A = string
             val A2 = A1
             type A = A
             datatype A3 = A3 of A
           in
             A2 1;
             A3 "A"
           end
        datatype A4 = A4 of A
        val _ = A4 1
      in
        ()
      end

  fun testTyvar () =
      let
        datatype ('a, 'b) A = A1 of 'a * 'b
        type ('b, 'a) A = ('a, 'b) A
        datatype ('a, 'b) B = A2 of ('a, 'b) A
        val v1 : (string, int) B = A2 (A1 (1, "A"))
      in
        ()
      end

  val tests = TestList [
    Test ("testVID", testVID),
    Test ("testVIDFun", testVIDFun),
    Test ("testVIDFunSameName", testVIDFunSameName),
    Test ("testVIDFunRec", testVIDFunRec),
    Test ("testVIDFunLet", testVIDFunLet),
    Test ("testVIDFn1", testVIDFn1),
    Test ("testVIDFn2", testVIDFn2),
    Test ("testVIDFnDatatype", testVIDFnDatatype),
    Test ("testVIDCase", testVIDCase),
    Test ("testVIDCaseDatatype", testVIDCaseDatatype),
    Test ("testVIDStruct", testVIDStruct),
    Test ("testVIDLocal", testVIDLocal),
    Test ("testVIDLet", testVIDLet),
    Test ("testVIDExn", testVIDExn),
    Test ("testTycon", testTycon),
    Test ("testTyconStruct", testTyconStruct),
    Test ("testTyconLocal", testTyconLocal),
    Test ("testTyconLet", testTyconLet),
    Test ("testTyvar", testTyvar)
  ]

end
