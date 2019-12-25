structure TypeDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testTypeDecl () =
      let
        type t1 = int
        val v1 : t1 = 1
      in
        ()
      end

  fun testTypeDeclTyvar () =
      let
        datatype 'a d1 = D1 of 'a
        type 'a t1 = 'a d1
        val v1 : int t1 = D1 1
        val v2 : string t1 = D1 "A"
      in
        ()
      end

  fun testTypeDeclTyvarSeq () =
      let
        datatype ('a, 'b) d1 = D1 of 'a 
                             | D2 of 'b
        type ('a, 'b) t1 = ('a, 'b) d1
        val v1 : (int, string) t1 = D1 1
        val v2 : (string, int) t1 = D2 1
      in
        ()
      end

  fun testTypeDeclAnd () =
      let
        datatype ('a, 'b) d1 = D11 of 'a 
                             | D12 of 'b
        datatype ('a, 'b) d2 = D21 of 'a 
                             | D22 of 'b
        type ('a, 'b) t1 = ('a, 'b) d1
         and ('a, 'b) t2 = ('b, 'a) d2
        val v1 : (int, string) t1 = D11 1
        val v2 : (string, int) t2 = D21 1
      in
        ()
      end

  fun testTypeDeclEqKind () =
      let
        type ''a t1 = ''a -> ''a
        val f1 : real t1 = fn x => x
        val _ = assertTrue (Real.== (1.0, f1 1.0))
      in
        ()
      end

  val tests = TestList [
    Test ("testTypeDecl", testTypeDecl),
    Test ("testTypeDeclTyvar", testTypeDeclTyvar),
    Test ("testTypeDeclTyvarSeq", testTypeDeclTyvarSeq),
    Test ("testTypeDeclAnd", testTypeDeclAnd),
    Test ("testTypeDeclEqKind", testTypeDeclEqKind)
  ]

end
