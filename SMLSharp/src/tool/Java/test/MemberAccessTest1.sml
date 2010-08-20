use "./MemberAccessTestee1.sml";

(**
 * TestCases for JavaArray structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure MemberAccessTest1 =
struct

  structure A = AssertJavaValue
  structure Test = SMLUnit.Test

  structure T = MemberAccessTestee1
  structure JA = Java.Array
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun testInstanceField () =
      let
        val obj = MemberAccessTestee1.new ()
        
        val z = true
        val () = $obj#set'z z
        val _ = A.assertEqualBoolean z ($obj#get'z ())

        val b = 0w12 : JV.byte
        val () = $obj#set'b b
        val _ = A.assertEqualByte b ($obj#get'b ())

        val c = 0w12 : JV.char
        val () = $obj#set'c c
        val _ = A.assertEqualChar c ($obj#get'c ())

        val s = 12 : JV.short
        val () = $obj#set's s
        val _ = A.assertEqualShort s ($obj#get's ())

        val i = 12 : JV.int
        val () = $obj#set'i i
        val _ = A.assertEqualInt i ($obj#get'i ())
(*
        val j = 12 : JV.long
        val () = $obj#set'j j
        val _ = A.assertEqualLong j ($obj#get'j ())
*)
(*
        val f = 1.23 : JV.float
        val () = $obj#set'f f
        val _ = A.assertEqualFloat f ($obj#get'f ())
*)
        val d = 1.23 : JV.double
        val () = $obj#set'd d
        val _ = A.assertEqualDouble d ($obj#get'd ())

        val t = SOME "abc" : JV.String
        val () = $obj#set't t
        val _ = A.assertEqualString t ($obj#get't ())

        val l = $$(JDK.java.lang.Object.new ()) : JV.Object
        val () = $obj#set'l l
        val _ = A.assertEqualObject l ($obj#get'l ())
      in
        ()
      end

  (**********)

  fun testInstanceMethod () =
      let
        val obj = MemberAccessTestee1.new ()
        
        val z = true
        val _ = A.assertEqualBoolean z ($obj#zz z)

        val b = 0w12 : JV.byte
        val _ = A.assertEqualByte b ($obj#bb b)

        val c = 0w12 : JV.char
        val _ = A.assertEqualChar c ($obj#cc c)

        val s = 12 : JV.short
        val _ = A.assertEqualShort s ($obj#ss s)

        val i = 12 : JV.int
        val _ = A.assertEqualInt i ($obj#ii i)
(*
        val j = 12 : JV.long
        val _ = A.assertEqualLong j ($obj#jj j)
*)
(*
        val f = 1.23 : JV.float
        val _ = A.assertEqualFloat f ($obj#ff f)
*)
        val d = 1.23 : JV.double
        val _ = A.assertEqualDouble d ($obj#dd d)

        val t = SOME "abc" : JV.String
        val _ = A.assertEqualString t ($obj#tt t)

        val l = $$(JDK.java.lang.Object.new ()) : JV.Object
        val _ = A.assertEqualObject l ($obj#ll l)

        val v = () : JV.void
        val _ = A.assertEqualVoid v ($obj#vv v)
      in
        ()
      end

  (**********)

  fun testStaticField () =
      let
        val z = true
        val () = T.set's_z z
        val _ = A.assertEqualBoolean z (T.get's_z ())

        val b = 0w12 : JV.byte
        val () = T.set's_b b
        val _ = A.assertEqualByte b (T.get's_b ())

        val c = 0w12 : JV.char
        val () = T.set's_c c
        val _ = A.assertEqualChar c (T.get's_c ())

        val s = 12 : JV.short
        val () = T.set's_s s
        val _ = A.assertEqualShort s (T.get's_s ())

        val i = 12 : JV.int
        val () = T.set's_i i
        val _ = A.assertEqualInt i (T.get's_i ())
(*
        val j = 12 : JV.long
        val () = T.set's_j j
        val _ = A.assertEqualLong j (T.get's_j ())
*)
(*
        val f = 1.23 : JV.float
        val () = T.set's_f f
        val _ = A.assertEqualFloat f (T.get's_f ())
*)
        val d = 1.23 : JV.double
        val () = T.set's_d d
        val _ = A.assertEqualDouble d (T.get's_d ())

        val t = SOME "abc" : JV.String
        val () = T.set's_t t
        val _ = A.assertEqualString t (T.get's_t ())

        val l = $$(JDK.java.lang.Object.new ()) : JV.Object
        val () = T.set's_l l
        val _ = A.assertEqualObject l (T.get's_l ())
      in
        ()
      end

  (**********)

  fun testStaticMethod () =
      let
        val z = true
        val _ = A.assertEqualBoolean z (T.s_zz z)

        val b = 0w12 : JV.byte
        val _ = A.assertEqualByte b (T.s_bb b)

        val c = 0w12 : JV.char
        val _ = A.assertEqualChar c (T.s_cc c)

        val s = 12 : JV.short
        val _ = A.assertEqualShort s (T.s_ss s)

        val i = 12 : JV.int
        val _ = A.assertEqualInt i (T.s_ii i)
(*
        val j = 12 : JV.long
        val _ = A.assertEqualLong j (T.s_jj j)
*)
(*
        val f = 1.23 : JV.float
        val _ = A.assertEqualFloat f (T.s_ff f)
*)
        val d = 1.23 : JV.double
        val _ = A.assertEqualDouble d (T.s_dd d)

        val t = SOME "abc" : JV.String
        val _ = A.assertEqualString t (T.s_tt t)

        val l = $$(JDK.java.lang.Object.new ()) : JV.Object
        val _ = A.assertEqualObject l (T.s_ll l)

        val v = ()
        val _ = A.assertEqualVoid v (T.s_vv v)
      in
        ()
      end

  (**********)

  (******************************************)

  fun init () =
      let
        val _ = MemberAccessTestee1.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testInstanceField", testInstanceField),
        ("testInstanceMethod", testInstanceMethod),
        ("testStaticField", testStaticField),
        ("testStaticMethod", testStaticMethod)
      ]

end;
