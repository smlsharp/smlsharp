structure ValRecDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testValRecDecl () =
      let
        val rec v1 = fn x => x
        val _ = assertEqualInt 1 (v1 1)
        val _ = assertEqualString "A" (v1 "A")
      in
        ()
      end

  fun testValRecDeclRec () =
      let
        val rec v1 = fn x => if x < 3 then x + v1 (x + 1) else x
        val _ = assertEqualInt 6 (v1 1)
      in
        ()
      end

  fun testValRecDeclTyvar () =
      let
        val rec 'a v1 = fn x:'a => x
        val _ = assertEqualInt 1 (v1 1)
        val _ = assertEqualString "A" (v1 "A")
      in
        ()
      end

  fun testValRecDeclTyvarSeq () =
      let
        val rec ('a, 'b) v1 = fn x:'a => (fn y:'b => x)
        val _ = assertEqualInt 1 (v1 1 "A")
        val _ = assertEqualString "A" (v1 "A" 1)
      in
        ()
      end

  val tests = TestList [
    Test ("testValRecDecl", testValRecDecl),
    Test ("testValRecDeclRec", testValRecDeclRec),
    Test ("testValRecDeclTyvar", testValRecDeclTyvar),
    Test ("testValRecDeclTyvarSeq", testValRecDeclTyvarSeq)
  ]

end

