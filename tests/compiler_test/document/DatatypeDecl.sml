structure DatatypeDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testDatatypeDecl () =
      let
        datatype d1 = D1
        datatype d2 = D2 
                    | D3
        datatype d3 = D4 of d2
        datatype d4 = D5 of d4
                    | D6

        val _ = assertTrue (D1 = D1)
        val _ = assertTrue (D2 <> D3)
        val _ = assertTrue (D4 D2 = D4 D2)
        val _ = assertTrue (D4 D2 <> D4 D3)
        val _ = assertTrue (D5 D6 = D5 D6)
        val _ = assertTrue (D5 (D5 D6) <> D5 D6)
      in
        ()
      end

  fun testDatatypeDeclTyvar () =
      let
        exception Exn1
        datatype 'a d1 = D1
        datatype 'a d2 = D2 of 'a * 'a
        datatype 'a d3 = D3 of 'a d1
                       | D4 of 'a d2
        datatype 'a d4 = D5 of 'a
                       | D6

        val v1 = D6 : int d4
        val 'a v2 = D6 : 'a d4
        fun 'a f1 (x:'a) = (x, D6 : 'a d4)
        val v3 = D2 (Exn1, Exn1)
        val v4 = D4 (D2 (Exn1, Exn1))

        val _ = assertTrue (D1 = D1)
        val _ = assertTrue (D2 (1, 2) = D2 (1, 2))
        val _ = assertTrue ((D3 D1) <> D4 (D2 (1, 2)))
      in
        ()
      end

  fun testDatatypeDeclAnd () =
      let
        datatype d1 = D11 of int 
        datatype d2 = D21 of int
        datatype d1 = D11
                    | D12 of d2
             and d2 = D21
                    | D22 of d1

        val _ = assertTrue (D12 D21 = D12 D21)
        val _ = assertTrue (D22 D11 = D22 D11)
      in
        ()
      end

  fun testDatatypeDeclAndTyvar () =
      let
        datatype 'a d1 = D11 of 'a
                       | D12 of 'a d2
                       | D13
             and 'a d2 = D21 of 'a
                       | D22 of 'a d1
                       | D23 of 'a * 'a d1

        val v1 = D13
        val v2 = D23 (1, v1)
        val v3 = D23 ("A", v1)

        val _ = assertTrue (D12 (D21 1) = D12 (D21 1))
        val _ = assertTrue (D22 (D11 1) = D22 (D11 1))
        val _ = assertTrue (D22 (D11 1) <> D22 (D12 (D22 (D11 1))))
      in
        ()
      end

  fun testDatatypeDeclAndTyvarSeq () =
      let
        datatype ('a, 'b) d1 = D11 of 'a
                             | D12 of ('a, 'b) d2
             and ('b, 'a) d2 = D21 of 'a
                             | D22 of ('b, 'a) d1

        val _ = assertTrue (D12 (D21 1) = D12 (D21 1))
        val _ = assertTrue (D22 (D11 1) = D22 (D11 1))
        val _ = assertTrue (D22 (D11 1) <> D22 (D12 (D22 (D11 1))))
      in
        ()
      end

  fun testDatatypeDeclWithType1 () =
      let
        type t1 = string
        datatype d1 = D1 of t1
        withtype t1 = int

        val v1 = 1 : t1
        val _ = assertTrue (D1 1 = D1 1)
      in
        ()
      end

  fun testDatatypeDeclWithType2 () =
      let
        type t1 = string
        datatype d1 = D1 of int
        withtype t1 = d1 * d1

        val v1 = (D1 1, D1 1) : t1
      in
        ()
      end

  val tests = TestList [
    Test ("testDatatypeDecl", testDatatypeDecl),
    Test ("testDatatypeDeclTyvar", testDatatypeDeclTyvar),
    Test ("testDatatypeDeclAnd", testDatatypeDeclAnd),
    Test ("testDatatypeDeclAndTyvar", testDatatypeDeclAndTyvar),
    Test ("testDatatypeDeclAndTyvarSeq", testDatatypeDeclAndTyvarSeq),
    Test ("testDatatypeDeclWithType", testDatatypeDeclWithType1),
    Test ("testDatatypeDeclWithType", testDatatypeDeclWithType2)
  ]

end
