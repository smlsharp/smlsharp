structure ValDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testValDecl () =
      let
        val v1 = 1
        val v2 = "A"
        val v3 = fn x => x
        val v4 : int = 1
        val v5 : string = "A"

        val _ = assertEqualInt 1 (v3 1)
        val _ = assertEqualString "A" (v3 "A")
      in
        ()
      end

  fun testValDeclTuple () =
      let
        val (v1, v2)         = (1, "A")
        val (_, _)           = (1, "A")
        val (v3, v4, v5)     = (2, "B", #"a")
        val {1 = v6, 2 = v7} = (3, "C")
        val {1 = v8, ...}    = (4, "D")

        val _ = assertEqualInt 1 v1
        val _ = assertEqualString "A" v2
        val _ = assertEqualInt 2 v3
        val _ = assertEqualString "B" v4
        val _ = assertEqualChar #"a" v5
        val _ = assertEqualInt 3 v6
        val _ = assertEqualString "C" v7
        val _ = assertEqualInt 4 v8
      in
        ()
      end

  fun testValDeclRecord () =
      let
        val {A = v1, B = v2} = {A = 1, B = "A"}
        val {A = _, B = _}   = {A = 1, B = "A"}
        val {...}            = {A = 1, B = "A"}
        val _                = {A = 1, B = "A"}
        val {A, B}           = {A = 2, B = "B"}
        val {A = v3, ...}    = {A = 3, B = "C"}

        val _ = assertEqualInt 1 v1
        val _ = assertEqualString "A" v2
        val _ = assertEqualInt 3 v3
        val _ = assertEqualInt 2 A
        val _ = assertEqualString "B" B

        val {A, ...}         = {A = 4, B = "D"}
        val _ = assertEqualInt 4 A
      in
        ()
      end


  fun testValDeclTyvar () =
      let
        exception Exn1
        val 'a v1 = fn x => 1
        val 'a v2 = fn x : 'a => 1
        val 'a v3 = fn x => (raise Exn1) : 'a

        val _ = assertEqualInt (v1 "A") 1
        val _ = assertEqualInt (v2 "A") 1
        val _ = assertTrue (v3 "A" handle Exn1 => true)
        val _ = assertTrue ((v3 "A") : bool handle Exn1 => true)
      in
        ()
      end

  fun testValDeclTyvarSeq () =
      let
        val ('a, 'b) v1 = fn x : 'a => fn y : 'b => (x, y)

        val          v2 : 'a -> 'b -> 'a * 'b = v1
        val 'a       v3 : 'a -> 'b -> 'a * 'b = v1
        val 'a       v4 : 'a -> 'a -> 'a * 'a = v1
        val ('a, 'b) v5 : 'a -> 'b -> 'a * 'b = v1
        val          v6 = v1 : 'a -> 'b -> 'a * 'b 
        val 'a       v7 = v1 : 'a -> 'b -> 'a * 'b
        val 'a       v8 = v1 : 'a -> 'a -> 'a * 'a 
        val ('a, 'b) v9 = v1  : 'a -> 'b -> 'a * 'b

        val _ = assertTrue ((1, "A") = v1 1 "A")
        val _ = assertTrue ((1, "A") = v2 1 "A")
        val _ = assertTrue ((1, "A") = v3 1 "A")
        val _ = assertTrue ((1, 2) = v4 1 2)
        val _ = assertTrue ((1, "A") = v5 1 "A")
        val _ = assertTrue ((1, "A") = v6 1 "A")
        val _ = assertTrue ((1, "A") = v7 1 "A")
        val _ = assertTrue ((1, 2) = v8 1 2)
        val _ = assertTrue ((1, "A") = v9 1 "A")
      in
        ()
      end

  fun testValDeclEqTyvar () =
      let
        exception Exn1
        val ''a v1 = fn x : ''a => x = x
        val ''a v2 = fn x : ''a => 1
        val ''a v3 = fn x => (raise Exn1) : ''a
        val 'a  v4 = fn x : 'a => x
        val ''a v5 = v4 : (''a -> ''a)
        val     v6 = v4 : (''a -> ''a)
        val ''a v7 : ''a -> ''a = v4
        val     v8 : ''a -> ''a = v4
        val     v9 = fn x => (v5 x = v6 x)

        val _ = assertTrue (v1 1)
        val _ = assertTrue (v1 "A")
        val _ = assertEqualInt (v2 "A") 1
        val _ = assertTrue (v3 "A" handle Exn1 => true)
        val _ = assertTrue ((v3 "A") : bool handle Exn1 => true)
        val _ = assertTrue ("A" = (v5 "A"))
        val _ = assertTrue ("A" = (v6 "A"))
        val _ = assertTrue ("A" = (v7 "A"))
        val _ = assertTrue ("A" = (v8 "A"))
        val _ = assertTrue (v9 "A")
      in
        ()
      end

  fun testValDeclEqTyvarSeq1 () =
      let
        val ('a, 'b) v1 = fn x : 'a => fn y : 'b => (x, y)

        val            v2 : ''a -> ''b -> ''a * ''b = v1
        val ''a        v3 : ''a -> ''b -> ''a * ''b = v1
        val ''a        v4 : ''a -> ''a -> ''a * ''a = v1
        val (''a, ''b) v5 : ''a -> ''b -> ''a * ''b = v1

        val _ = assertTrue ((1, "A") = v1 1 "A")
        val _ = assertTrue ((1, "A") = v2 1 "A")
        val _ = assertTrue ((1, "A") = v3 1 "A")
        val _ = assertTrue ((1, 2) = v4 1 2)
        val _ = assertTrue ((1, "A") = v5 1 "A")
      in
        ()
      end

  fun testValDeclEqTyvarSeq2 () =
      let
        val ('a, 'b) v1 = fn x : 'a => fn y : 'b => (x, y)

        val            v2 = v1 : ''a -> ''b -> ''a * ''b 
        val ''a        v3 = v1 : ''a -> ''b -> ''a * ''b
        val ''a        v4 = v1 : ''a -> ''a -> ''a * ''a 
        val (''a, ''b) v5 = v1 : ''a -> ''b -> ''a * ''b

        val _ = assertTrue ((1, "A") = v1 1 "A")
        val _ = assertTrue ((1, "A") = v2 1 "A")
        val _ = assertTrue ((1, "A") = v3 1 "A")
        val _ = assertTrue ((1, 2) = v4 1 2)
        val _ = assertTrue ((1, "A") = v5 1 "A")
      in
        ()
      end

  fun testValDeclEqTyvarSeq3 () =
      let
        val (''a, ''b) v1 = fn x : ''a => fn y : ''b => (x, y) = (x, y)

        val ''a        v2 = v1 : ''a -> ''a -> bool
        val            v3 = v1 : ''a -> ''a -> bool
        val ''a        v4 : ''a -> ''a -> bool = v1
        val            v5 : ''a -> ''a -> bool = v1

        val _ = assertTrue (v1 1 "A")
        val _ = assertTrue (v2 1 2)
        val _ = assertTrue (v3 1 2)
        val _ = assertTrue (v4 1 2)
        val _ = assertTrue (v5 1 2)
      in
        ()
      end

  fun testValDeclPatternDatatype1 () =
      let
        datatype d1 = A1

        val A1            = A1
        val v1 : d1       = A1
        val v2 as A1      = A1
        val v3 as A1 : d1 = A1

        val _ = assertTrue (A1 = v1)
        val _ = assertTrue (A1 = v2)
        val _ = assertTrue (A1 = v3)

      in
        ()
      end

  fun testValDeclPatternDatatype2 () =
      let
        datatype d1 = A1 of int

        val v1 as A1 v2      = A1 1
        val v3 : d1 as A1 v4 = A1 1
        val A1 v5            = A1 1
        val A1 (v6 : int)    = A1 1
        val A1 v7 : d1       = A1 1
        val A1 _             = A1 1

        val _ = assertTrue (A1 1 = v1)
        val _ = assertEqualInt 1 v2
        val _ = assertTrue (A1 1 = v3)
        val _ = assertEqualInt 1 v4
        val _ = assertEqualInt 1 v5
        val _ = assertEqualInt 1 v6
        val _ = assertEqualInt 1 v7
      in
        ()
      end

  fun testValDeclPatternDatatype3 () =
      let
        datatype d1 = A1 of int * string

        val A1 (v1, v2) = A1 (1, "A")
        val A1 (_, _)   = A1 (1, "A")
        val A1 _        = A1 (1, "A")
        val A1 {...}    = A1 (1, "A")

        val _ = assertEqualInt 1 v1
        val _ = assertEqualString "A" v2
      in
        ()
      end

  fun testValDeclPatternDatatype4 () =
      let
        datatype d4 = A1 of {A:int, B:string}

        val A1 {A = v1, B = v2} = A1 {B = "A", A = 4}
        val A1 {A, B}           = A1 {B = "A", A = 4}
        val A1 {...}            = A1 {B = "A", A = 4}
        val A1 _                = A1 {B = "A", A = 4}

        val _ = assertEqualInt 4 v1
        val _ = assertEqualString "A" v2
        val _ = assertEqualInt 4 A
        val _ = assertEqualString "A" B
      in
        ()
      end

  fun testValDeclPatternDatatype5 () =
      let
        datatype ('a, 'b) d1 = A1 of 'a * 'b

        val ('a, 'b) v1 = fn x : 'a => fn y : 'b => A1 (x, y)
        val ('a, 'b) v2 = fn x => fn y => A1 (x, y) : ('a, 'b) d1
        val 'a       v3 = fn x => fn y => A1 (x, y) : ('a, 'b) d1
        val 'a       v4 = fn x => fn y => A1 (x, y) : ('a, 'a) d1
        val          v5 = fn x => fn y => A1 (x, y) : ('a, 'b) d1
        val ('a, 'b) v6 : 'a -> 'b -> ('a, 'b) d1 = fn x => fn y => A1 (x, y)

        val _ = assertTrue (A1 (1, "A") = v1 1 "A")
        val _ = assertTrue (A1 (1, "A") = v2 1 "A")
        val _ = assertTrue (A1 (1, "A") = v3 1 "A")
        val _ = assertTrue (A1 (1, 2) = v4 1 2)
        val _ = assertTrue (A1 (1, "A") = v5 1 "A")
        val _ = assertTrue (A1 (1, "A") = v6 1 "A")
      in
        ()
      end

  fun testValDeclPatternTuple () =
      let
        val (v1, v2) = (1, 2)
        val (v3, v4) = {2 = 3, 1 = 4}
        val 'a (v5, v6) = (fn x : 'a => x, 6)
        val ('a, 'b) (v7, v8) = (fn x : 'a => x, fn x : 'b => x)

        val _ = assertEqualInt 1 v1
        val _ = assertEqualInt 2 v2
        val _ = assertEqualInt 4 v3
        val _ = assertEqualInt 3 v4
        val _ = assertEqualInt 5 (v5 5)
        val _ = assertEqualInt 6 v6
        val _ = assertEqualInt 7 (v7 7)
        val _ = assertEqualInt 8 (v8 8)
      in
        ()
      end

  fun testValDeclRank1Ref () =
      let
        val v1 = fn x => fn y => (ref x, ref y)
        val v2 = v1 1
        val v3 = v2 2
        val v4 = v2 "A"

        val _ = assertTrue (ref 1 <> #1 v3)
        val _ = assertTrue (ref 2 <> #2 v3)
        val _ = assertTrue (ref 1 <> #1 v4)
        val _ = assertTrue (ref "A" <> #2 v4)
        val _ = assertTrue (#1 v3 <> #1 v4)
      in
        ()
      end

  val tests = TestList [
    Test ("testValDecl", testValDecl),
    Test ("testValDeclTuple", testValDeclTuple),
    Test ("testValDeclRecord", testValDeclRecord),
    Test ("testValDeclTyvar", testValDeclTyvar),
    Test ("testValDeclTyvarSeq", testValDeclTyvarSeq),
    Test ("testValDeclEqTyvar", testValDeclEqTyvar),
    Test ("testValDeclEqTyvarSeq1", testValDeclEqTyvarSeq1),
    Test ("testValDeclEqTyvarSeq2", testValDeclEqTyvarSeq2),
    Test ("testValDeclEqTyvarSeq3", testValDeclEqTyvarSeq3),
    Test ("testValDeclPatternDatatype1", testValDeclPatternDatatype1),
    Test ("testValDeclPatternDatatype2", testValDeclPatternDatatype2),
    Test ("testValDeclPatternDatatype3", testValDeclPatternDatatype3),
    Test ("testValDeclPatternDatatype4", testValDeclPatternDatatype4),
    Test ("testValDeclPatternDatatype5", testValDeclPatternDatatype5),
    Test ("testValDeclPatternTuple", testValDeclPatternTuple),
    Test ("testValDeclRank1Ref", testValDeclRank1Ref)
  ]

end

