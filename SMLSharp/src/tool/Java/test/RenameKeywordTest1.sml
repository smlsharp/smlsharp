use "./ClassBasicsTestee1.sml";
use "./RenameKeywordTestee1.sml";

(**
 * TestCases for renaming SML keywords used as Java entity names.
 *)
structure RenameKeywordTest1 =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure JA = AssertJavaValue

  structure T = RenameKeywordTestee1

  structure J = Java
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun testMethod () =
      let
        val obj = T.new()
        val _ = JA.assertEqualInt 1 ($obj#abstype'())
        val _ = JA.assertEqualInt 1 ($obj#and'())
        val _ = JA.assertEqualInt 1 ($obj#andalso'())
        val _ = JA.assertEqualInt 1 ($obj#as'())
(*
        val _ = JA.assertEqualInt 1 ($obj#case'())
*)
        val _ = JA.assertEqualInt 1 ($obj#datatype'())
(*
        val _ = JA.assertEqualInt 1 ($obj#do'())
*)
(*
        val _ = JA.assertEqualInt 1 ($obj#else'())
*)
        val _ = JA.assertEqualInt 1 ($obj#end'())
        val _ = JA.assertEqualInt 1 ($obj#exception'())
        val _ = JA.assertEqualInt 1 ($obj#fn'())
        val _ = JA.assertEqualInt 1 ($obj#fun'())
        val _ = JA.assertEqualInt 1 ($obj#handle'())
(*
        val _ = JA.assertEqualInt 1 ($obj#if'())
*)
        val _ = JA.assertEqualInt 1 ($obj#in'())
        val _ = JA.assertEqualInt 1 ($obj#infix'())
        val _ = JA.assertEqualInt 1 ($obj#infixr'())
        val _ = JA.assertEqualInt 1 ($obj#let'())
        val _ = JA.assertEqualInt 1 ($obj#local'())
        val _ = JA.assertEqualInt 1 ($obj#nonfix'())
        val _ = JA.assertEqualInt 1 ($obj#of'())
        val _ = JA.assertEqualInt 1 ($obj#op'())
        val _ = JA.assertEqualInt 1 ($obj#open'())
        val _ = JA.assertEqualInt 1 ($obj#orelse'())
        val _ = JA.assertEqualInt 1 ($obj#raise'())
        val _ = JA.assertEqualInt 1 ($obj#rec'())
        val _ = JA.assertEqualInt 1 ($obj#then'())
        val _ = JA.assertEqualInt 1 ($obj#type'())
        val _ = JA.assertEqualInt 1 ($obj#val'())
        val _ = JA.assertEqualInt 1 ($obj#with'())
        val _ = JA.assertEqualInt 1 ($obj#withtype'())
(*
        val _ = JA.assertEqualInt 1 ($obj#while'())
*)
        val _ = JA.assertEqualInt 1 ($obj#eqtype'())
        val _ = JA.assertEqualInt 1 ($obj#functor'())
        val _ = JA.assertEqualInt 1 ($obj#include'())
        val _ = JA.assertEqualInt 1 ($obj#sharing'())
        val _ = JA.assertEqualInt 1 ($obj#sig'())
        val _ = JA.assertEqualInt 1 ($obj#signature'())
        val _ = JA.assertEqualInt 1 ($obj#struct'())
        val _ = JA.assertEqualInt 1 ($obj#structure'())
        val _ = JA.assertEqualInt 1 ($obj#where'())
      in
        ()
      end

  fun testField () =
      let
        val obj = T.new()
        val _ = $obj#set'abstype'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'abstype'())
        val _ = $obj#set'and'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'and'())
        val _ = $obj#set'andalso'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'andalso'())
        val _ = $obj#set'as'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'as'())
(*
        val _ = $obj#set'case'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'case'())
*)
        val _ = $obj#set'datatype'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'datatype'())
(*
        val _ = $obj#set'do'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'do'())
*)
(*
        val _ = $obj#set'else'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'else'())
*)
        val _ = $obj#set'end'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'end'())
        val _ = $obj#set'exception'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'exception'())
        val _ = $obj#set'fn'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'fn'())
        val _ = $obj#set'fun'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'fun'())
        val _ = $obj#set'handle'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'handle'())
(*
        val _ = $obj#set'if'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'if'())
*)
        val _ = $obj#set'in'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'in'())
        val _ = $obj#set'infix'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'infix'())
        val _ = $obj#set'infixr'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'infixr'())
        val _ = $obj#set'let'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'let'())
        val _ = $obj#set'local'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'local'())
        val _ = $obj#set'nonfix'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'nonfix'())
        val _ = $obj#set'of'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'of'())
        val _ = $obj#set'op'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'op'())
        val _ = $obj#set'open'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'open'())
        val _ = $obj#set'orelse'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'orelse'())
        val _ = $obj#set'raise'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'raise'())
        val _ = $obj#set'rec'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'rec'())
        val _ = $obj#set'then'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'then'())
        val _ = $obj#set'type'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'type'())
        val _ = $obj#set'val'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'val'())
        val _ = $obj#set'with'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'with'())
        val _ = $obj#set'withtype'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'withtype'())
(*
        val _ = $obj#set'while'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'while'())
*)
        val _ = $obj#set'eqtype'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'eqtype'())
        val _ = $obj#set'functor'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'functor'())
        val _ = $obj#set'include'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'include'())
        val _ = $obj#set'sharing'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'sharing'())
        val _ = $obj#set'sig'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'sig'())
        val _ = $obj#set'signature'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'signature'())
        val _ = $obj#set'struct'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'struct'())
        val _ = $obj#set'structure'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'structure'())
        val _ = $obj#set'where'(1)
        val _ = JA.assertEqualInt 1 ($obj#get'where'())
      in
        ()
      end

  fun testChildClass () =
      let
        val T = T.new()
        val _ = JA.assertNotNull ($$(T.abstype'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.and'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.andalso'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.as'.new ($$T)))
(*
        val _ = JA.assertNotNull ($$(T.case'.new ($$T)))
*)
        val _ = JA.assertNotNull ($$(T.datatype'.new ($$T)))
(*
        val _ = JA.assertNotNull ($$(T.do'.new ($$T)))
*)
(*
        val _ = JA.assertNotNull ($$(T.else'.new ($$T)))
*)
        val _ = JA.assertNotNull ($$(T.end'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.exception'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.fn'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.fun'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.handle'.new ($$T)))
(*
        val _ = JA.assertNotNull ($$(T.if'.new ($$T)))
*)
        val _ = JA.assertNotNull ($$(T.in'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.infix'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.infixr'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.let'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.local'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.nonfix'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.of'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.op'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.open'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.orelse'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.raise'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.rec'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.then'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.type'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.val'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.with'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.withtype'.new ($$T)))
(*
        val _ = JA.assertNotNull ($$(T.while'.new ($$T)))
*)
        val _ = JA.assertNotNull ($$(T.eqtype'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.functor'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.include'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.sharing'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.sig'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.signature'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.struct'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.structure'.new ($$T)))
        val _ = JA.assertNotNull ($$(T.where'.new ($$T)))
      in
        ()
      end

  (******************************************)

  fun init () =
      let
        val _ = RenameKeywordTestee1.static()

        val _ = T.abstype'.static()
        val _ = T.and'.static()
        val _ = T.andalso'.static()
        val _ = T.as'.static()
(*
        val _ = T.case'.static()
*)
        val _ = T.datatype'.static()
(*
        val _ = T.do'.static()
*)
(*
        val _ = T.else'.static()
*)
        val _ = T.end'.static()
        val _ = T.exception'.static()
        val _ = T.fn'.static()
        val _ = T.fun'.static()
        val _ = T.handle'.static()
(*
        val _ = T.if'.static()
*)
        val _ = T.in'.static()
        val _ = T.infix'.static()
        val _ = T.infixr'.static()
        val _ = T.let'.static()
        val _ = T.local'.static()
        val _ = T.nonfix'.static()
        val _ = T.of'.static()
        val _ = T.op'.static()
        val _ = T.open'.static()
        val _ = T.orelse'.static()
        val _ = T.raise'.static()
        val _ = T.rec'.static()
        val _ = T.then'.static()
        val _ = T.type'.static()
        val _ = T.val'.static()
        val _ = T.with'.static()
        val _ = T.withtype'.static()
(*
        val _ = T.while'.static()
*)
        val _ = T.eqtype'.static()
        val _ = T.functor'.static()
        val _ = T.include'.static()
        val _ = T.sharing'.static()
        val _ = T.sig'.static()
        val _ = T.signature'.static()
        val _ = T.struct'.static()
        val _ = T.structure'.static()
        val _ = T.where'.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testMethod", testMethod),
        ("testField", testField),
        ("testChildClass", testChildClass)
      ]

end;
