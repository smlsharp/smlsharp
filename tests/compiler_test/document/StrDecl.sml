structure StrDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  structure StrDt = struct
    datatype d1 = D1
  end

  structure Str1 = struct
    type t1 = int
    type 'a t2 = 'a -> 'a
    val v1 = 1
    fun f1 x = x
    fun f2 x = x + x - x
    datatype d1 = D1
    datatype d2 = datatype StrDt.d1
    datatype 'a d3 = D3 of 'a
    abstype at1 = D1
      with 
        val v2 = D1
      end
    exception Exn1 
    fun f3 () = raise Exn1
    val v3 = f1 f1

    fun op1 (x, y) = x + y
    fun op2 (x, y) = x - y
    fun op3 (x, y) = x * y
    infix op1
    infixr op2
    fun opf1 () = (2 op1 1)
    fun opf2 () = (2 op2 1)
    infix op3
    nonfix op3
    structure Str1 = struct
      val v1 = 4
    end
  end

  fun testStrDecl () =
      let
        val _ = assertEqualInt 1 Str1.v1
        val _ = assertEqualInt 1 (Str1.f1 1)
        val _ = assertEqualString "A" (Str1.f1 "A")
        val _ = assertEqualInt 1 (Str1.f2 1)
        val v1 : Str1.t1 = 1
        val _ = assertTrue (Str1.D1 = Str1.D1)
        val v2 : Str1.d2 = Str1.D1
        val v3 : int Str1.d3 = Str1.D3 1
        val _ = assertTrue (Str1.D3 "A" = Str1.D3 "A")
        val v4 : Str1.at1 = Str1.v2
        val _ = Str1.f3 () handle Str1.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 1 (Str1.v3 1)
        val _ = assertEqualInt 3 (Str1.opf1 ())
        val _ = assertEqualInt 1 (Str1.opf2 ())
        val _ = assertEqualInt 4 Str1.Str1.v1
      in
        ()
      end


  structure Str2 = Str1

  fun testStrDeclStrID () =
      let
        val _ = assertEqualInt 1 Str2.v1
        val _ = assertEqualInt 1 (Str2.f1 1)
        val _ = assertEqualString "A" (Str2.f1 "A")
        val _ = assertEqualInt 1 (Str2.f2 1)
        val v1 : Str2.t1 = 1
        val _ = assertTrue (Str2.D1 = Str1.D1)
        val v2 : Str2.d2 = Str1.D1
        val v3 : int Str2.d3 = Str1.D3 1
        val _ = assertTrue (Str2.D3 "A" = Str2.D3 "A")
        val v4 : Str2.at1 = Str1.v2
        val _ = Str1.f3 () handle Str2.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 3 (Str2.opf1 ())
        val _ = assertEqualInt 1 (Str2.opf2 ())
        val _ = assertEqualInt 4 Str2.Str1.v1
      in
        ()
      end


  structure Str3 = Str1.Str1

  fun testStrDeclLongStrID () =
      let
        val _ = assertEqualInt 4 Str3.v1
      in
        ()
      end


  structure Str4 : sig
    type t1
    type 'a t2
    val v1 : t1
    val f1 : 'a t2
    val f2 : t1 t2
    datatype d2 = datatype StrDt.d1
    datatype 'a d3 = D3 of 'a
    type at1
    val v2 : at1
    exception Exn1
    val f3 : unit -> 'a
    val v3 : t1 t2
    structure Str1 : sig
      val v1 : int
    end
  end = Str1

  fun testStrDeclSigTransparent1 () =
      let
        val _ = assertEqualInt 1 Str4.v1
        val _ = assertEqualInt 1 (Str4.f1 1)
        val _ = assertEqualString "A" (Str4.f1 "A")
        val _ = assertEqualInt 1 (Str4.f2 1)
        val v1 : Str4.t1 = 1
        val _ = assertTrue (Str4.D1 = Str4.D1)
        val v2 : Str4.d2 = Str4.D1
        val v3 : int Str2.d3 = Str1.D3 1
        val _ = assertTrue (Str2.D3 "A" = Str2.D3 "A")
        val v4 : Str4.at1 = Str4.v2
        val _ = Str4.f3 () handle Str4.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 4 Str4.Str1.v1
      in
        ()
      end

  structure Str4 = Str1 : sig
    type t1
    type 'a t2
    val v1 : t1
    val f1 : 'a t2
    val f2 : t1 t2
    datatype d2 = datatype StrDt.d1
    datatype 'a d3 = D3 of 'a
    type at1
    val v2 : at1
    exception Exn1
    val f3 : unit -> 'a
    structure Str1 : sig
      val v1 : int
    end
  end

  fun testStrDeclSigTransparent2 () =
      let
        val _ = assertEqualInt 1 Str4.v1
        val _ = assertEqualInt 1 (Str4.f1 1)
        val _ = assertEqualString "A" (Str4.f1 "A")
        val _ = assertEqualInt 1 (Str4.f2 1)
        val v1 : Str4.t1 = 1
        val _ = assertTrue (Str4.D1 = Str4.D1)
        val v2 : Str4.d2 = Str4.D1
        val v3 : int Str4.d3 = Str4.D3 1
        val _ = assertTrue (Str4.D3 "A" = Str4.D3 "A")
        val v4 : Str4.at1 = Str4.v2
        val _ = Str4.f3 () handle Str4.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 4 Str4.Str1.v1
      in
        ()
      end


  structure Str5 :> sig
    type t1
    type 'a t2
    val v1 : t1
    val f1 : 'a t2
    val f2 : t1 t2
    datatype d2 = datatype StrDt.d1
    datatype 'a d3 = D3 of 'a
    type at1
    val v2 : at1
    exception Exn1
    val f3 : unit -> 'a
    structure Str1 : sig
      val v1 : int
    end
  end = Str1

  fun testStrDeclSigOpaque1 () =
      let
        val v1 : Str5.t1 =  Str5.v1
        val f1 : 'a Str5.t2 =  Str5.f1
        val f2 : Str5.t1 Str5.t2 =  Str5.f2
        val _ = assertTrue (Str5.D1 = Str5.D1)
        val v2 : Str5.d2 = Str5.D1
        val v3 : int Str5.d3 = Str5.D3 1
        val _ = assertTrue (Str5.D3 "A" = Str5.D3 "A")
        val v4 : Str5.at1 = Str5.v2
        val _ = Str5.f3 () handle Str5.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 4 Str5.Str1.v1
      in
        ()
      end


  structure Str5 = Str1 :> sig
    type t1
    type 'a t2
    val v1 : t1
    val f1 : 'a t2
    val f2 : t1 t2
    datatype d2 = datatype StrDt.d1
    datatype 'a d3 = D3 of 'a 
    type at1
    val v2 : at1
    exception Exn1
    val f3 : unit -> 'a
    structure Str1 : sig
      val v1 : int
    end
  end

  fun testStrDeclSigOpaque2 () =
      let
        val v1 : Str5.t1 =  Str5.v1
        val f1 : 'a Str5.t2 =  Str5.f1
        val f2 : Str5.t1 Str5.t2 =  Str5.f2
        val _ = assertTrue (Str5.D1 = Str5.D1)
        val v2 : Str5.d2 = Str5.D1
        val v3 : int Str5.d3 = Str5.D3 1
        val _ = assertTrue (Str5.D3 "A" = Str5.D3 "A")
        val v4 : Str5.at1 = Str5.v2
        val _ = Str5.f3 () handle Str5.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 4 Str5.Str1.v1
      in
        ()
      end


  structure Str6 :> sig
    type t1 = int
    val v1 : int
    val f1 : 'a -> 'a
    val f2 : word -> word
    datatype d2 = datatype StrDt.d1
    datatype 'a d3 = D3 of 'a
    type at1
    val v2 : at1
    exception Exn1
    val f3 : unit -> 'a
    structure Str1 : sig
      val v1 : int
    end
  end = Str1

  fun testStrDeclSigOpaque3 () =
      let
        val _ = assertEqualInt 1 Str6.v1
        val _ = assertEqualInt 1 (Str6.f1 1)
        val _ = assertEqualString "A" (Str6.f1 "A")
        val _ = assertEqualWord 0w1 (Str6.f2 0w1)
        val v1 : Str6.t1 = 1
        val _ = assertTrue (Str6.D1 = Str6.D1)
        val v2 : Str6.d2 = Str6.D1
        val v3 : int Str6.d3 = Str6.D3 1
        val _ = assertTrue (Str6.D3 "A" = Str6.D3 "A")
        val v4 : Str6.at1 = Str6.v2
        val _ = Str6.f3 () handle Str6.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 4 Str6.Str1.v1
      in
        ()
      end


  structure Str7 = struct
    open Str1.Str1
    val v5 = v1
    open Str1
    val v6 = v1
    open Str1
  end

  fun testStrDeclOpen () =
      let
        val _ = assertEqualInt 4 Str7.v1
        val _ = assertEqualInt 1 (Str7.f1 1)
        val _ = assertEqualString "A" (Str7.f1 "A")
        val _ = assertEqualInt 1 (Str7.f2 1)
        val v1 : Str7.t1 = 1
        val _ = assertTrue (Str7.D1 = Str7.D1)
        val v2 : Str7.d2 = Str7.D1
        val v3 : int Str7.d3 = Str7.D3 1
        val _ = assertTrue (Str7.D3 "A" = Str7.D3 "A")
        val v4 : Str7.at1 = Str7.v2
        val _ = Str7.f3 () handle Str7.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 3 (Str7.opf1 ())
        val _ = assertEqualInt 1 (Str7.opf2 ())
        val _ = assertEqualInt 4 Str7.Str1.v1
        val _ = assertEqualInt 4 Str7.v5
        val _ = assertEqualInt 1 Str7.v6
      in
        ()
      end


  structure Str8 = struct
    val v1 = 1
  end
  structure Str9 = struct
    val v1 = 2
  end

  structure Str8 = Str9
        and Str9 = Str8

  fun testStrDeclAnd () =
      let
        val _ = assertEqualInt 2 Str8.v1
        val _ = assertEqualInt 1 Str9.v1
      in
        ()
      end


  structure Str10 = 
    let
      structure Str10 = Str1
      structure Str1 = struct
        val v1 = 10
      end
    in
      struct
        val v5 = Str1.v1
        open Str10
      end
    end

  fun testStrDeclLet () =
      let
        val _ = assertEqualInt 1 Str10.v1
        val _ = assertEqualInt 1 (Str10.f1 1)
        val _ = assertEqualString "A" (Str10.f1 "A")
        val _ = assertEqualInt 1 (Str10.f2 1)
        val v1 : Str10.t1 = 1
        val _ = assertTrue (Str10.D1 = Str10.D1)
        val v2 : Str10.d2 = Str10.D1
        val v3 : int Str10.d3 = Str10.D3 1
        val _ = assertTrue (Str10.D3 "A" = Str10.D3 "A")
        val v4 : Str10.at1 = Str10.v2
        val _ = Str10.f3 () handle Str10.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 3 (Str10.opf1 ())
        val _ = assertEqualInt 1 (Str10.opf2 ())
        val _ = assertEqualInt 4 Str10.Str1.v1
        val _ = assertEqualInt 10 Str10.v5
      in
        ()
      end


    local
      structure Str11 = Str1
      structure Str1 = struct
        val v1 = 10
      end
    in
      structure Str11 = struct
        open Str11
      end
    end

  fun testStrDeclLocal () =
      let
        val _ = assertEqualInt 1 Str11.v1
        val _ = assertEqualInt 1 (Str11.f1 1)
        val _ = assertEqualString "A" (Str11.f1 "A")
        val _ = assertEqualInt 1 (Str11.f2 1)
        val v1 : Str11.t1 = 1
        val _ = assertTrue (Str11.D1 = Str11.D1)
        val v2 : Str11.d2 = Str11.D1
        val v3 : int Str11.d3 = Str11.D3 1
        val _ = assertTrue (Str11.D3 "A" = Str11.D3 "A")
        val v4 : Str11.at1 = Str11.v2
        val _ = Str11.f3 () handle Str11.Exn1 => ()
                                | _ => fail "NG"
        val _ = assertEqualInt 3 (Str11.opf1 ())
        val _ = assertEqualInt 1 (Str11.opf2 ())
        val _ = assertEqualInt 4 Str11.Str1.v1
        val _ = assertEqualInt 1 Str1.v1
      in
        ()
      end



  val tests = TestList [
    Test ("testStrDecl", testStrDecl),
    Test ("testStrDeclStrID", testStrDeclLongStrID),
    Test ("testStrDeclLongStrID", testStrDeclLongStrID),
    Test ("testStrDeclSigTransparent1", testStrDeclSigTransparent1),
    Test ("testStrDeclSigTransparent2", testStrDeclSigTransparent2),
    Test ("testStrDeclSigOpaque1", testStrDeclSigOpaque1),
    Test ("testStrDeclSigOpaque2", testStrDeclSigOpaque2),
    Test ("testStrDeclSigOpaque3", testStrDeclSigOpaque3),
    Test ("testStrDeclOpen", testStrDeclOpen),
    Test ("testStrDeclAnd", testStrDeclAnd),
    Test ("testStrDeclLet", testStrDeclLet),
    Test ("testStrDeclLocal", testStrDeclLocal)
  ]

end
