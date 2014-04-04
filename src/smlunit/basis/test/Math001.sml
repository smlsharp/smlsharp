(**
 * test cases for Math structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Math001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  val error = 0.00000000001
  fun almostEq (x, y) =
      if x < y
      then y - x < error
      else x - y < error
  val assertEqReal = assertEqual almostEq Real.toString 

  (************************************************************)

  fun pi001 () =
      let
        val () = assertEqReal 3.14159265359 Math.pi
      in
        ()
      end

  fun e001 () =
      let
        val () = assertEqReal 2.71828182846 Math.e
      in
        ()
      end

  fun sqrt001 () = 
      let
        val sqrt001 = Math.sqrt 1.23
        val () = assertEqReal 1.10905365064 sqrt001
      in
        ()
      end

  fun sin001 () = 
      let
        val sin001 = Math.sin 1.23
        val () = assertEqReal 0.942488801932 sin001
      in
        ()
      end

  fun cos001 () = 
      let
        val cos001 = Math.cos 1.23
        val () = assertEqReal 0.334237727125 cos001
      in
        ()
      end

  fun tan001 () = 
      let
        val tan001 = Math.tan 1.23
        val () = assertEqReal 2.81981573427 tan001
      in
        ()
      end

  fun asin001 () = 
      let
        val asin001 = Math.asin 0.123
        val () = assertEqReal 0.123312275192 asin001
      in
        ()
      end

  fun acos001 () = 
      let
        val acos001 = Math.acos 0.123
        val () = assertEqReal 1.4474840516 acos001
      in
        ()
      end

  fun atan001 () = 
      let
        val atan001 = Math.atan 1.23
        val () = assertEqReal 0.888173774378 atan001
      in
        ()
      end

  fun atan2001 () = 
      let
        val atan2001 = Math.atan2 (1.23, 2.34)
        val () = assertEqReal 0.48394938786 atan2001
      in
        ()
      end

  fun exp001 () = 
      let
        val exp001 = Math.exp 1.23
        val () = assertEqReal 3.42122953629 exp001
      in
        ()
      end

  fun pow001 () = 
      let
        val pow001 = Math.pow (1.23, 2.34)
        val () = assertEqReal 1.62322215169 pow001
      in
        ()
      end

  fun ln001 () = 
      let
        val ln001 = Math.ln 1.23
        val () = assertEqReal 0.207014169384 ln001
      in
        ()
      end

  fun log10001 () = 
      let
        val log10001 = Math.log10 1.23
        val () = assertEqReal 0.0899051114394 log10001
      in
        ()
      end

  fun sinh001 () = 
      let
        val sinh001 = Math.sinh 1.23
        val () = assertEqReal 1.5644684793 sinh001
      in
        ()
      end

  fun cosh001 () = 
      let
        val cosh001 = Math.cosh 1.23
        val () = assertEqReal 1.85676105699 cosh001
      in
        ()
      end

  fun tanh001 () = 
      let
        val tanh001 = Math.tanh 1.23
        val () = assertEqReal 0.842579325659 tanh001
      in
        ()
      end

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("pi001", pi001),
        ("e001", e001),
        ("sqrt001", sqrt001),
        ("sin001", sin001),
        ("cos001", cos001),
        ("tan001", tan001),
        ("asin001", asin001),
        ("acos001", acos001),
        ("atan001", atan001),
        ("atan2001", atan2001),
        ("exp001", exp001),
        ("pow001", pow001),
        ("ln001", ln001),
        ("log10001", log10001),
        ("sinh001", sinh001),
        ("cosh001", cosh001),
        ("tanh001", tanh001)
      ]

  (************************************************************)

end