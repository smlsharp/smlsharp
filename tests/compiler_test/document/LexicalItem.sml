structure LexicalItem =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testIdentifier () =
      let
        val a  = 1
        val z  = 1
        val A  = 1
        val Z  = 1
        val a0  = 1
        val a9  = 1
        val a'  = 1
        val   = 1
      in
        ()
      end

  fun testConstantLiteral () =
      let
        val _ = assertEqualInt 2147483647 0x7FFFFFFF
        val _ = assertEqualInt ~2147483648 ~0x80000000
        val _ = assertEqualInt 0xabcdef 11259375
        val _ = assertEqualInt 0xABCDEF 11259375
        val _ = assertEqualWord 0w2147483647 0wx7FFFFFFF
        val _ = assertEqualWord 0wxabcdef 0w11259375
        val _ = assertEqualWord 0wxABCDEF 0w11259375
        val _ = assertEqualReal 1.1E3 1100.0
        val _ = assertEqualReal 1.1E~3 0.0011
        val _ = assertEqualReal 1.1e~3 0.0011
        val _ = assertEqualChar #"a" #"\097"
        val _ = assertEqualChar #"\a" #"\007"
        val _ = assertEqualChar #"\b" #"\008"
        val _ = assertEqualChar #"\t" #"\009"
        val _ = assertEqualChar #"\n" #"\010"
        val _ = assertEqualChar #"\v" #"\011"
        val _ = assertEqualChar #"\f" #"\012"
        val _ = assertEqualChar #"\r" #"\013"
        val _ = assertEqualChar #"\^A" #"\001"
        val _ = assertEqualChar #"\\" #"\092"
        val _ = assertEqualChar #"\"" #"\034"
        val _ = assertEqualString "abc" "\   \abc"
      in
        ()
      end
  
  val tests = TestList [
    Test ("testLexicalItem", testIdentifier),
    Test ("testConstantLiteral", testConstantLiteral)
  ]

end
