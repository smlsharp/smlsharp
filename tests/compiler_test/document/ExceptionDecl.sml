structure ExceptionDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testExceptionDecl () =
      let
        exception Exn1
        exception Exn2 of int
        val _ = (raise Exn1)
                handle Exn1 => () 
                     | _ => fail "NG"
        val _ = (raise Exn2 1)
                handle Exn2 1 => () 
                     | _ => fail "NG"
      in
        ()
      end

  fun testExceptionDeclEq () =
      let
        exception Exn1 of int
        exception Exn2 = Exn1
        val _ = (raise Exn1 1)
                handle Exn2 1 => () 
                     | _ => fail "NG"
      in
        ()
      end

  structure S1 = struct
      exception Exn1 of int
  end

  fun testExceptionDeclEqLongVID () =
      let
        exception Exn1 of int
        exception Exn2 = S1.Exn1
        val _ = (raise S1.Exn1 1)
                handle Exn1 _ => fail "NG"
                     | Exn2 1 => ()
                     | _ => fail "NG"
      in
        ()
      end

  fun testExceptionDeclAnd () =
      let
        exception Exn1
        fun f1 x = (raise x)
                   handle Exn1 => true
                        | _ => false
        exception Exn1
              and Exn2 = Exn1
        val _ = assertFalse (f1 Exn1)
        val _ = assertTrue (f1 Exn2)
      in
        ()
      end


  fun testExceptionDeclCaseOf () =
      let
        exception Exn1
        exception Exn2 of int
        val _ = case Exn1 of
                     Exn1 => ()
                   | _ => fail "NG"
        val _ = case Exn2 1 of
                     Exn2 2 => fail "NG"
                   | Exn2 1 => ()
                   | _ => fail "NG"
      in
        ()
      end

  val tests = TestList [
    Test ("testExceptionDecl", testExceptionDecl),
    Test ("testExceptionDeclEq", testExceptionDeclEq),
    Test ("testExceptionDeclEqLongVID", testExceptionDeclEqLongVID),
    Test ("testExceptionDeclAnd", testExceptionDeclAnd),
    Test ("testExceptionDeclCaseOf", testExceptionDeclCaseOf)
  ]

end
