(*
 * SHA-1 hashing algorithm
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *
 * See the following for details of the algorithm:
 * National Institute of Standards and Technology (NIST).
 * SECURE HASH STANDARD.
 * Federal Information Processing Standards Publication 180-2, 2002.
 * http://csrc.nist.gov/publications/fips/fips180-2/fips180-2.pdf
 *)

structure SHA1 :> sig

  type digest

  val digest : Word8Vector.vector -> digest
  val toString : digest -> string
  val toBase32 : digest -> string

end =
struct
  val andb = Word32.andb
  val orb = Word32.orb
  val xorb = Word32.xorb
  val notb = Word32.notb
  val << = Word32.<<
  val >> = Word32.>>
  infix andb orb xorb << >>

  fun rotl (n, X) = (X << n) orb (X >> (0w32 - n))

  fun word8to32 w =
      Word32.fromInt (Word8.toInt w)

  fun readWord vec =
      let
        fun loop (vec, 0, z) = (vec, z)
          | loop (vec, n, z) =
            case Word8VectorSlice.getItem vec of
              NONE => (vec, z)
            | SOME (w, vec) => loop (vec, n-1, (z << 0w8) orb word8to32 w)
      in
        loop (vec, 4, 0w0)
      end

  fun readWordsAccum (vec, dst) =
      let
        val rest = Word8VectorSlice.length vec
        val (vec, w) = readWord vec
      in
        if rest < 4
        then (((w << 0w8) orb 0wx80) << (Word.fromInt ((4 - rest - 1) * 8)))
             :: dst
        else readWordsAccum (vec, w::dst)
      end

  fun readWords vec =
      rev (readWordsAccum (vec, nil))

  fun readWordsAndPad src =
      let
        val words = readWords (Word8VectorSlice.full src)
        val numBytes = Word8Vector.length src
        val numBits = numBytes * 8
        val numWords = (numBytes + 4) div 4
        val numPads = 16 - (numWords + 1) mod 16
        val words = words @ List.tabulate (numPads, fn _ => 0w0)
      in
        words @ [Word32.fromInt numBits]
      end

  fun f0 (B,C,D) = (B andb C) orb ((notb B) andb D)
  fun f1 (B,C,D) = B xorb C xorb D
  fun f2 (B,C,D) = (B andb C) orb (B andb D) orb (C andb D)
  val f3 = f1

  val k0 = 0wx5A827999 : Word32.word
  val k1 = 0wx6ED9EBA1 : Word32.word
  val k2 = 0wx8F1BBCDC : Word32.word
  val k3 = 0wxCA62C1D6 : Word32.word

  fun makeBlocks words =
      case words of
        w0::w1::w2::w3::w4::w5::w6::w7::w8::w9::wA::wB::wC::wD::wE::wF::t =>
        (w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,wA,wB,wC,wD,wE,wF) :: makeBlocks t
      | _ => nil

  fun wordSeq 0 _ = nil
    | wordSeq n (w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,wA,wB,wC,wD,wE,wF) =
      let
        val w = rotl (0w1, wD xorb w8 xorb w2 xorb w0)
      in
        w :: wordSeq (n-1) (w1,w2,w3,w4,w5,w6,w7,w8,w9,wA,wB,wC,wD,wE,wF,w)
      end

  fun makeWordSeq (ws as (w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,wA,wB,wC,wD,wE,wF)) =
      w0::w1::w2::w3::w4::w5::w6::w7::w8::w9::wA::wB::wC::wD::wE::wF
      :: wordSeq 64 ws

  type digest =
      Word32.word * Word32.word * Word32.word * Word32.word * Word32.word

  val initialDigest =
      (0wx67452301, 0wxEFCDAB89, 0wx98BADCFE, 0wx10325476, 0wxC3D2E1F0)
      : digest

  fun accumDigest ((H0, H1, H2, H3, H4), (A, B, C, D, E)) =
      (H0 + A, H1 + B, H2 + C, H3 + D, H4 + E) : digest

  fun step f k (nil, regs) = (nil, regs)
    | step f k (h::t, (A, B, C, D, E)) =
      (t, (rotl (0w5,A) + f (B,C,D) + E + h + k, A, rotl (0w30,B), C, D))

  fun repeat f (z:Word32.word list * digest) n =
      let
        fun loop (i, z) = if i < n then loop (i+1, f z) else z
      in
        loop (0, z)
      end

  fun digestBlock (block, digest as (H0, H1, H2, H3, H4)) =
      let
        val work = (makeWordSeq block, digest)
        val work = repeat (step f0 k0) work 20
        val work = repeat (step f1 k1) work 20
        val work = repeat (step f2 k2) work 20
        val work = repeat (step f3 k3) work 20
      in
        accumDigest (digest, #2 work)
      end

  fun digest msg =
      foldl digestBlock initialDigest (makeBlocks (readWordsAndPad msg))

  fun fmt8 w =
      StringCvt.padLeft #"0" 8 (Word32.fmt StringCvt.HEX w)

  fun toString ((A, B, C, D, E):digest) =
      String.map Char.toLower
                 (fmt8 A ^ fmt8 B ^ fmt8 C ^ fmt8 D ^ fmt8 E)

  local
    fun split5 (carry, bits, nil) = if bits = 0w32 then nil else [carry]
      | split5 (carry, bits, w::ws) =
        if bits >= 0w5
        then ((carry orb (w >> (bits - 0w5))) andb 0wx1f)
             :: split5 (0w0, bits - 0w5, w::ws)
        else split5 ((w << (0w5 - bits)) andb 0wx1f, 0w32 + bits, ws)

    fun split32 words =
        map Word32.toInt (split5 (0w0, 0w32, words))

    fun digit32 n =
        chr (if n <= 9 then ord #"0" + n else ord #"A" + n - 10)
  in

  fun toBase32 ((A, B, C, D, E):digest) =
      String.implode (map digit32 (split32 [A, B, C, D, E]))

  end (* local *)
end


(*
(* test code *)
local
  fun rep (n,c) = Word8Vector.tabulate (n, fn _ => Word8.fromInt (ord c))
  fun assert (s,t) =
      if s = t then ()
      else (print ("expect: " ^ s ^ " but actual: " ^ t ^ "\n");
            raise Fail "assert")
  fun test (expect, src) =
      assert (expect, SHA1.toString (SHA1.digest src))
  val _ = test ("da39a3ee5e6b4b0d3255bfef95601890afd80709", rep (0, #"a"))
  val _ = test ("86f7e437faa5a7fce15d1ddcb9eaeaea377667b8", rep (1, #"a"))
  val _ = test ("e0c9035898dd52fc65c41454cec9c4d2611bfb37", rep (2, #"a"))
  val _ = test ("7e240de74fb1ed08fa08d38063f6a6a91462a815", rep (3, #"a"))
  val _ = test ("70c881d4a26984ddce795f6f71817c9cf4480e79", rep (4, #"a"))
  val _ = test ("df51e37c269aa94d38f93e537bf6e2020b21406c", rep (5, #"a"))
  val _ = test ("c1c8bbdc22796e28c0e15163d20899b65621d65a", rep (55, #"a"))
  val _ = test ("c2db330f6083854c99d4b5bfb6e8f29f201be699", rep (56, #"a"))
  val _ = test ("f08f24908d682555111be7ff6f004e78283d989a", rep (57, #"a"))
  val _ = test ("5ee0f8895f4e1aae6a6661de5c432e34188a5a2d", rep (58, #"a"))
  val _ = test ("dbc8b8f59ff85a2b1448ed873484b14bf0507246", rep (59, #"a"))
  val _ = test ("13d956033d9af449bfe2c4ef78c17c20469c4bf1", rep (60, #"a"))
  val _ = test ("aeab141db28af3353283b5ccb2a322df0b9b5f56", rep (61, #"a"))
  val _ = test ("67b4b3923fa178d788a9611b76446c96431071f2", rep (62, #"a"))
  val _ = test ("03f09f5b158a7a8cdad920bddc29b81c18a551f5", rep (63, #"a"))
  val _ = test ("0098ba824b5c16427bd7a1122a5a442a25ec644d", rep (64, #"a"))
  val _ = test ("11655326c708d70319be2610e8a57d9a5b959d3b", rep (65, #"a"))
  val _ = test ("ee971065aaa017e0632a8ca6c77bb3bf8b1dfc56", rep (119, #"a"))
  val _ = test ("f34c1488385346a55709ba056ddd08280dd4c6d6", rep (120, #"a"))
  val _ = test ("fa6b5a6f8ac27182f838fe7841ec6d2aef3ade29", rep (121, #"a"))
  val _ = test ("05f805d3faea526f0d347b023b22042c89f63bf5", rep (122, #"a"))
  val _ = test ("c78e6ef1050c8626772a175c11d0acc5ebc33326", rep (123, #"a"))
  val _ = test ("29d2b14f43c797d078249ea7968fd19ea2a3608c", rep (124, #"a"))
  val _ = test ("3ec5ca1d740852128d4ef51e3f881f7af5c233f2", rep (125, #"a"))
  val _ = test ("1af933b8607e22788537e7350785c1a44c075512", rep (126, #"a"))
  val _ = test ("89d95fa32ed44a7c610b7ee38517ddf57e0bb975", rep (127, #"a"))
  val _ = test ("ad5b3fdbcb526778c2839d2f151ea753995e26a0", rep (128, #"a"))
in
end
*)
