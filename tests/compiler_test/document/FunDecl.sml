structure FunDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testFunDecl () =
      let
        exception Exn1
        fun f1 x = x
        fun f2 x:int = 1
        fun f3 x:'a = x
        fun f4 x:''a = x
        fun f5 (x:int) = x:int
        fun f6 (x:'a) = x
        fun f7 (x:''a) = x
        fun (f8:int -> int) x = x
        fun (f9:'a -> 'a) x = x
        fun (f10:''a -> ''a) x = x
        fun (f11:'a -> 'a) x:'a = x
        fun (f12:'a -> 'a) x:'a = x:'a
        fun (f13:'a -> int) x = 1
        fun (f14:'a -> 'b) x = raise Exn1

        val _ = assertEqualInt 1 (f1 1)
        val _ = assertEqualInt 1 (f2 1)
        val _ = assertEqualInt 1 (f3 1)
        val _ = assertEqualInt 1 (f4 1)
        val _ = assertEqualInt 1 (f5 1)
        val _ = assertEqualInt 1 (f6 1)
        val _ = assertEqualInt 1 (f7 1)
        val _ = assertEqualInt 1 (f8 1)
        val _ = assertEqualInt 1 (f9 1)
        val _ = assertEqualInt 1 (f10 1)
        val _ = assertEqualInt 1 (f11 1)
        val _ = assertEqualInt 1 (f12 1)
        val _ = assertEqualInt 1 (f13 1)
        val _ = assertEqualInt 1 ((f14 1) handle Exn => 1)
      in
        ()
      end

  fun testFunDeclRec () =
      let
        fun f1 x = if x < 3 then x + f1 (x + 1) else x
        val _ = assertEqualInt 6 (f1 1)
      in
        ()
      end

  fun testFunDeclTailRec () =
      let
        fun f1 (x, y) = if x < 3 then f1 (x + 1, x + y) else x + y
        val _ = assertEqualInt 6 (f1 (1, 0))
      in
        ()
      end

  fun testFunDeclRecType () =
      let
        fun f x = f 1
        fun f x = f x
        fun f x : 'a = f x
        fun f x : ''a = f x
        fun f (x:int) = f 1
        fun f (x:'a) = f x
        fun f (x:''a) = f x
        fun f (x:'a) : 'a = f x
        fun f (x:''a) : ''a = f x
        fun f (x:'a) : 'b = f x
        fun f (x:''a) : ''b = f x
      in
        ()
      end

  fun testFunDeclPatInt () =
      let
        fun f1 1 = "A"
          | f1 2 = "B"
          | f1 ~1 = "C"
          | f1 _ = "D"

        val _ = assertEqualString "A" (f1 1)
        val _ = assertEqualString "B" (f1 2)
        val _ = assertEqualString "C" (f1 ~1)
        val _ = assertEqualString "D" (f1 3)
      in
        ()
      end

  fun testFunDeclPatWord () =
      let
        fun f1 0w1 = "A"
          | f1 0w2 = "B"
          | f1 _ = "C"

        val _ = assertEqualString "A" (f1 0w1)
        val _ = assertEqualString "B" (f1 0w2)
        val _ = assertEqualString "C" (f1 0w3)
      in
        ()
      end

  fun testFunDeclPatString () =
      let
        fun f1 "A" = 1
          | f1 "B" = 2
          | f1 _ = 3

        val _ = assertEqualInt 1 (f1 "A")
        val _ = assertEqualInt 2 (f1 "B")
        val _ = assertEqualInt 3 (f1 "C")
      in
        ()
      end

  fun testFunDeclPatExn () =
      let
        exception Exn1
        exception Exn2 of int
        exception Exn3
        fun f1 Exn1 = 1
          | f1 (Exn2 n) = n
          | f1 _ = 3

        val _ = assertEqualInt 1 (f1 Exn1)
        val _ = assertEqualInt 2 (f1 (Exn2 2))
        val _ = assertEqualInt 3 (f1 Exn3)
      in
        ()
      end

  fun testFunDeclPatTuple () =
      let
        fun f1  (x, y)                       = x
        fun f2  (x:'a, y:'b)                 = x
        fun f3  (x:'a, y:'b)                 = x : 'a
        fun f4  (x:''a, y:''b)               = x
        fun f5  (x:''a, y:''b)               = x : ''a
        fun f6  ((x, y)         :  'a *  'b) = x
        fun f7  ((x, y)         :  'a *  'b) = x : 'a
        fun f8  ((x:'a, y:'b)   :  'a *  'b) = x
        fun f9  ((x, y)         : ''a * ''b) = x
        fun f10 ((x, y)         : ''a * ''b) = x : ''a
        fun f11 ((x:''a, y:''b) : ''a * ''b) = x

        val _ = assertEqualInt 1 (f1  (1, "A"))
        val _ = assertEqualInt 1 (f2  (1, "A"))
        val _ = assertEqualInt 1 (f3  (1, "A"))
        val _ = assertEqualInt 1 (f4  (1, "A"))
        val _ = assertEqualInt 1 (f5  (1, "A"))
        val _ = assertEqualInt 1 (f6  (1, "A"))
        val _ = assertEqualInt 1 (f7  (1, "A"))
        val _ = assertEqualInt 1 (f8  (1, "A"))
        val _ = assertEqualInt 1 (f9  (1, "A"))
        val _ = assertEqualInt 1 (f10 (1, "A"))
        val _ = assertEqualInt 1 (f11 (1, "A"))
      in
        ()
      end

  fun testFunDeclPatRecord () =
      let
        fun f1 {A = v1, B = v2} = v1
        fun f2 {A = _, B = _} = 2
        fun f3 {...} = 3
        fun f4 _ = 4
        fun f5 {A, B} = A
        fun f6 {A = v1, ...} = v1

        val _ = assertEqualInt 1 (f1 {A=1, B="A"})
        val _ = assertEqualInt 2 (f2 {A=1, B="A"})
        val _ = assertEqualInt 3 (f3 {A=1, B="A"})
        val _ = assertEqualInt 4 (f4 {A=1, B="A"})
        val _ = assertEqualInt 1 (f5 {A=1, B="A"})
        val _ = assertEqualInt 1 (f6 {A=1, B="A"})
      in
        ()
      end

  fun testFunDeclPatDatatype() =
      let
        datatype d1 = A 
                    | B
        datatype d2 = C of int
                    | D of string

        fun f1 A = 1
          | f1 B = 2
        fun f2 (C n) = n
          | f2 (D "A") = 4
          | f2 (D _) = 5

        val _ = assertEqualInt 1 (f1 A)
        val _ = assertEqualInt 2 (f1 B)
        val _ = assertEqualInt 3 (f2 (C 3))
        val _ = assertEqualInt 4 (f2 (D "A"))
        val _ = assertEqualInt 5 (f2 (D "B"))
      in
        ()
      end

  fun testFunDeclTyvar () =
      let
        exception Exn1
        fun 'a f1 x:'a = x
        fun ''a f2 x:''a = x
        fun 'a f3 (x:'a) = x
        fun ''a f4 (x:''a) = x
        fun 'a (f5:'a -> 'a) x = x
        fun ''a (f6:''a -> ''a) x = x
        fun 'a (f7:'a -> 'a) x:'a = x
        fun 'a (f8:'a -> 'a) x:'a = x:'a
        fun 'a (f9:'a -> int) x = 1
        fun 'a (f10:'a -> 'b) x = raise Exn1

        val _ = assertEqualInt 1 (f1 1)
        val _ = assertEqualInt 1 (f2 1)
        val _ = assertEqualInt 1 (f3 1)
        val _ = assertEqualInt 1 (f4 1)
        val _ = assertEqualInt 1 (f5 1)
        val _ = assertEqualInt 1 (f6 1)
        val _ = assertEqualInt 1 (f7 1)
        val _ = assertEqualInt 1 (f8 1)
        val _ = assertEqualInt 1 (f9 1)
        val _ = assertEqualInt 1 ((f10 1) handle Exn => 1)
      in
        ()
      end

  fun testFunDeclTyvarSeq () =
      let
        fun ('a, 'b) f1 x:'a * 'b = x
        fun ('a, 'b) f2 (x:'a) y =
            let
              fun g z:'b = z
            in
              g y
            end
        fun (''a, ''b) f3 (x1:''a) (x2:''a) (y1:''b) (y2:''b) = 
            ((x1 = x2), (y1 = y2))

        val _ = assertTrue ((1, "A") = (f1 (1, "A")))
        val _ = assertEqualInt 1 (f2 "A" 1)
        val _ = assertTrue ((true, false) = (f3 1 1 "A" "B"))
      in
        ()
      end

  fun testFunDeclAnd () =
      let
        fun f1 x = x
        and f2 x = x + 1

        fun f3 x = fail "NG"
        fun f4 x = fail "NG"
        fun f3 x = if 3 <= x then "A" else f4 x
        and f4 x = f3 (x + 1)

        fun f5 x = if 3 <= x then "A" else f6 x
        and f6 x = 
            let
              fun f5 x = "B"
            in
              f5 (x + 1)
            end

        val _ = assertEqualString "A" (f1 "A")
        val _ = assertEqualInt 2 (f2 1)
        val _ = assertEqualString "A" (f3 1)
        val _ = assertEqualString "A" (f4 1)
        val _ = assertEqualString "B" (f5 1)
        val _ = assertEqualString "B" (f6 1)
      in
        ()
      end

  fun testFunDeclAndTyvar () =
      let
        fun 'a f1 (x:'a) = x
        and    f2 (x:'a) = x

        val _ = assertEqualString "A" (f1 "A")
        val _ = assertEqualString "A" (f2 "A")
        val _ = assertEqualInt 1 (f1 1)
        val _ = assertEqualInt 1 (f2 1)
      in
        ()
      end

  val tests = TestList [
    Test ("testFunDecl", testFunDecl),
    Test ("testFunDeclTailRec", testFunDeclTailRec),
    Test ("testFunDeclRecType", testFunDeclRecType),
    Test ("testFunDeclRec", testFunDeclRec),
    Test ("testFunDeclPatInt", testFunDeclPatInt),
    Test ("testFunDeclPatWord", testFunDeclPatWord),
    Test ("testFunDeclPatString", testFunDeclPatString),
    Test ("testFunDeclPatExn", testFunDeclPatExn),
    Test ("testFunDeclPatTuple", testFunDeclPatTuple),
    Test ("testFunDeclPatRecord", testFunDeclPatRecord),
    Test ("testFunDeclPatDatatype", testFunDeclPatDatatype),
    Test ("testFunDeclTyvar", testFunDeclTyvar),
    Test ("testFunDeclTyvarSeq", testFunDeclTyvarSeq),
    Test ("testFunDeclAnd", testFunDeclAnd),
    Test ("testFunDeclAndTyvar", testFunDeclAndTyvar)
  ]

end
