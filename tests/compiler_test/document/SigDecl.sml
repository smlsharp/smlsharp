type t1 = int
signature Sig1 = sig
  val v1 : t1
  type t1
  type t2 = t1
  type t3 = string
  val v2 : t2
  val v3 : t3
end

signature Sig2 = sig
  eqtype eqt1
  type t1 = eqt1
  val v1 : eqt1
  val v2 : t1
end

signature Sig3 = sig
  eqtype eqt1
  type t1
  val v1 : eqt1
  val v2 : t1
end

signature Sig4 = sig
  type 'a t1
  type ('a, 'b) t2
  val v1 : int t1
  val v2 : (int, string) t2
end

signature Sig5 = sig
  type ('a, 'b) t1
  val v1 : (int, string) t1
  structure Str1 : sig
    val v2 : (int, string) t1
    type ('a, 'b) t1
    val v3 : (int, string) t1
  end
end

signature Sig6 = sig
  type t4 = t1
  include Sig1
  type t5 = t1
end

signature Sig7 = sig
  type t1
  eqtype t2
  datatype d1 = D1
  structure Str1 : sig
    type t1
  end
  sharing type t1 = t2 = d1 = Str1.t1
  val v1 : t1
  val v2 : t2
  val v3 : d1
  val v4 : Str1.t1
end

signature Sig8 = sig
  type t1 = int
end

signature Sig8 = sig
  type t1 = string
end
and Sig9 = sig
  include Sig8
  val v1 : t1
end


structure Str1 = struct
  type t1 = int
end

signature Sig10 = sig
  structure Str1 : sig
    type t1 = string
  end
  and Str2 : sig
    type t1 = Str1.t1
    val v1 : t1
  end
end

signature Sig11 = sig
  val v1 : int
  and v2 : string
end

signature Sig12 = sig
  type t1 = string
   and t2 = t1
  val v1 : t1
  val v2 : t2
end

signature Sig13 = sig
  datatype d1 = D11
              | D12 of d2
       and d2 = D21
              | D22 of d1
  val v1 : d1
  val v2 : d2
end

signature Sig14 = sig
  exception Exn1
        and Exn2
  val f1 : unit -> 'a
  val f2 : unit -> 'a
end


structure SigDecl =
struct
open SMLUnit.Test SMLUnit.Assert

  structure Str1 : Sig1 = struct
    type t1 = string
    type t2 = string
    type t3 = string
    val v1 = 1
    val v2 = "A"
    val v3 = "B"
  end

  fun testSigDeclTransparent () =
      let
        val _ = assertEqualInt 1 Str1.v1
        val _ = assertEqualString "A" Str1.v2
        val _ = assertEqualString "B" Str1.v3
        val v1 : t1 = Str1.v1
        val v2 : Str1.t1 = Str1.v2
        val v3 : Str1.t3 = Str1.v3
      in
        ()
      end


  structure Str2 :> Sig1 = struct
    type t1 = string
    type t2 = string
    type t3 = string
    val v1 = 1
    val v2 = "A"
    val v3 = "B"
  end

  fun testSigDeclOpaque () =
      let
        val _ = assertEqualInt 1 Str2.v1
        val _ = assertEqualString "B" Str1.v3
        val v1 : t1 = Str2.v1
        val v2 : Str2.t1 = Str2.v2
        val v3 : Str2.t3 = Str2.v3
      in
        ()
      end


  structure Str3 : Sig2 = struct
    type eqt1 = string
    type t1 = string
    val v1 = "A"
    val v2 = "B"
  end

  fun testSigDeclEqTypeTransparent () =
      let
        val _ = assertEqualString "A" Str3.v1
        val _ = assertEqualString "B" Str3.v2
        val v1 : Str3.eqt1 = Str3.v1
        val v2 : Str3.t1 = Str3.v2
      in
        ()
      end


  structure Str4 :> Sig2 = struct
    type eqt1 = string
    type t1 = string
    val v1 = "A"
    val v2 = "B"
  end

  fun testSigDeclEqTypeOpaque () =
      let
        val _ = assertTrue (Str4.v1 = Str4.v1)
        val _ = assertTrue (Str4.v2 = Str4.v2)
        val v1 : Str3.eqt1 = Str3.v1
        val v2 : Str3.t1 = Str3.v2
      in
        ()
      end

  structure Str5 :> Sig2 
      where type eqt1 = string = struct
    type eqt1 = string
    type t1 = string
    val v1 = "A"
    val v2 = "B"
  end

  fun testSigDeclWhereType () =
      let
        val _ = assertEqualString "A" Str5.v1
        val _ = assertEqualString "B" Str5.v2
        val v1 : Str5.eqt1 = Str5.v1
        val v2 : Str5.t1 = Str3.v2
      in
        ()
      end

  structure Str6 :> Sig3
    where type eqt1 = string 
      and type t1 = string = struct
    type eqt1 = string
    type t1 = string
    val v1 = "A"
    val v2 = "B"
  end

  fun testSigDeclWhereTypeAnd () =
      let
        val _ = assertEqualString "A" Str6.v1
        val _ = assertEqualString "B" Str6.v2
        val v1 : Str6.eqt1 = Str6.v1
        val v2 : Str6.t1 = Str6.v2
      in
        ()
      end


  datatype 'a d1 = D1 of 'a
  datatype ('a, 'b) d2 = D2 of 'a * 'b
  structure Str6 :> Sig4 
    where type 'a t1 = 'a d1
    where type ('a, 'b) t2 = ('a, 'b) d2 = struct

    type 'a t1 = 'a d1
    type ('a, 'b) t2 = ('a, 'b) d2
    val v1 = D1 1
    val v2 = D2 (1, "A")
  end

  fun testSigDeclWhereTypeTyvar () =
      let
        val _ = assertTrue (D1 1 = Str6.v1)
        val _ = assertTrue (D2 (1, "A") = Str6.v2)
        val v1 : int Str6.t1 = D1 1
        val v2 : string Str6.t1 = D1 "A"
        val v3 : (int, string) Str6.t2 = D2 (1, "A")
      in
        ()
      end

  datatype ('a, 'b) d1 = D1 of 'a * 'b
  datatype ('a, 'b) d2 = D2 of 'a * 'b
  structure Str7 :> Sig5
    where type ('a, 'b) t1 = ('a, 'b) d1
    where type ('a, 'b) Str1.t1 = ('a, 'b) d2 = struct

    type ('a, 'b) t1 = ('a, 'b) d1
    val v1 = D1 (1, "A")
    structure Str1 = struct
      val v2 = D1 (2, "B")
      type ('a, 'b) t1 = ('a, 'b) d2
      val v3 = D2 (1, "A")
    end
  end

  fun testSigDeclWhereTypeLongTycon () =
      let
        val _ = assertTrue (D1 (1, "A") = Str7.v1)
        val _ = assertTrue (D1 (2, "B") = Str7.Str1.v2)
        val _ = assertTrue (D2 (1, "A") = Str7.Str1.v3)
      in
        ()
      end


  structure Str8 : Sig6 = struct
    open Str1
    type t4 = int
    type t5 = string
  end

  fun testSigDeclInclude () =
      let
        val _ = assertEqualInt 1 Str8.v1
        val _ = assertEqualString "A" Str8.v2
        val _ = assertEqualString "B" Str8.v3
        val v1 : Str8.t4 = Str8.v1
        val v2 : Str8.t5 = Str8.v2
        val v3 : Str8.t3 = Str8.v3
      in
        ()
      end


  structure Str8 :> Sig7 = struct
    datatype t1 = D1
    type t2 = t1
    datatype d1 = datatype t1
    structure Str1 = struct
      type t1 = t1
    end
    val v1 = D1
    val v2 = D1
    val v3 = D1
    val v4 = D1
  end

  fun testSigDeclSharing () =
      let
        val _ = assertTrue (Str8.v1 = Str8.v2)
        val _ = assertTrue (Str8.v1 = Str8.v3)
        val _ = assertTrue (Str8.v1 = Str8.v4)
      in
        ()
      end


  structure Str9 : Sig9 = struct
    type t1 = int
    val v1 = 1
  end

  fun testSigDeclAnd () =
      let
        val _ = assertEqualInt 1 Str9.v1
      in
        ()
      end


  structure Str10 : Sig10 = struct
    structure Str1 = struct
      type t1 = string
    end
    structure Str2 = struct
      type t1 = int
      val v1 = 1
    end
  end

  fun testSigDeclStrDescAnd () =
      let
        val _ = assertEqualInt 1 Str10.Str2.v1
      in
        ()
      end


  structure Str11 : Sig11 = struct
    val v1 = 1
    val v2 = "A"
  end

  fun testSigDeclValDescAnd () =
      let
        val _ = assertEqualInt 1 Str11.v1
        val _ = assertEqualString "A" Str11.v2
      in
        ()
      end


  structure Str12 : Sig12 = struct
    type t1 = string
    type t2 = string
    val v1 = "A"
    val v2 = "B"
  end

  fun testSigDeclTypeDescAnd() =
      let
        val _ = assertEqualString "A" Str12.v1
        val _ = assertEqualString "B" Str12.v2
      in
        ()
      end


  structure Str13 : Sig13 = struct
    datatype d1 = D11
                | D12 of d2
         and d2 = D21
                | D22 of d1
    val v1 = D12 D21
    val v2 = D22 D11
  end

  fun testSigDeclDatatypeDescAnd() =
      let
        val _ = assertTrue (Str13.D12 (Str13.D21) = Str13.v1)
        val _ = assertTrue (Str13.D22 (Str13.D11) = Str13.v2)
      in
        ()
      end

  structure Str14 : Sig14 = struct
    exception Exn1
    exception Exn2
    fun f1 () = raise Exn1
    fun f2 () = raise Exn2
  end

  fun testSigDeclExceptionDescAnd () =
      let
        val _ = Str14.f1 () handle Str14.Exn1 => ()
                                 | _ => fail "Exn1 NG"
        val _ = Str14.f2 () handle Str14.Exn2 => ()
                                 | _ => fail "Exn2 NG"
      in
        ()
      end

  val tests = TestList [
    Test ("testSigDeclTransparent", testSigDeclTransparent),
    Test ("testSigDeclOpaque", testSigDeclOpaque),
    Test ("testSigDeclEqTypeTransparent", testSigDeclEqTypeTransparent),
    Test ("testSigDeclEqTypeOpaque", testSigDeclEqTypeOpaque),
    Test ("testSigDeclWhereType", testSigDeclWhereType),
    Test ("testSigDeclWhereTypeAnd", testSigDeclWhereTypeAnd),
    Test ("testSigDeclWhereTypeTyvar", testSigDeclWhereTypeTyvar),
    Test ("testSigDeclWhereTypeLongTycon", testSigDeclWhereTypeLongTycon),
    Test ("testSigDeclInclude", testSigDeclInclude),
    Test ("testSigDeclSharing", testSigDeclSharing),
    Test ("testSigDeclAnd", testSigDeclAnd),
    Test ("testSigDeclStrDescAnd", testSigDeclStrDescAnd),
    Test ("testSigDeclValDescAnd", testSigDeclValDescAnd),
    Test ("testSigDeclTypeDescAnd", testSigDeclTypeDescAnd),
    Test ("testSigDeclDatatypeDescAnd", testSigDeclDatatypeDescAnd),
    Test ("testSigDeclExceptionDescAnd", testSigDeclExceptionDescAnd)
  ]

end
