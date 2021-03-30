(*
 * SHA-3 hashing algorithm
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *
 * See the following for details of the algorithm:
 * - National Institute of Standards and Technology (NIST),
 *   SHA-3 Standard: Permutation-Based Hash and Extendable-Output Functions,
 *   Federal Information Processing Standards Publication 202, 2015.
 *   http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf
 * - The Keccak sponge function family.
 *   http://keccak.noekeon.org
 *)

structure SHA3 : sig

  type digest = Word8Vector.vector
  val shake128 : Word8Vector.vector * int -> digest
  val shake256 : Word8Vector.vector * int -> digest
  val sha3_224 : Word8Vector.vector -> digest
  val sha3_256 : Word8Vector.vector -> digest
  val sha3_384 : Word8Vector.vector -> digest
  val sha3_512 : Word8Vector.vector -> digest
  val hex : digest -> string

end =
struct

  infix << >> ^^ && ||
  val op << = Word64.<<
  val op >> = Word64.>>
  val op ^^ = Word64.xorb
  val op && = Word64.andb
  val op || = Word64.orb
  val notb = Word64.notb

  fun rol (x, y) = (x << y) || (x >> (0w64 - y))

  val fromWord8 = SMLSharp_Builtin.Word8.toWord64
  val toWord8 = SMLSharp_Builtin.Word64.toWord8

  val zero = 0w0 : Word64.word

  fun sub (a, i) =
      fromWord8 (Word8Array.sub (a, i))

  fun update (a, i, w) =
      Word8Array.update (a, i, toWord8 w)

  fun read64 (a, i, 0) = zero
    | read64 (a, i, j) = sub (a, i) || (read64 (a, i+1, j-1) << 0w8)

  fun write64 (a, i, w, 0) = ()
    | write64 (a, i, w, j) =
      (update (a, i, w); write64 (a, i+1, w >> 0w8, j-1))

  val roundConstants =
      [0wx0000000000000001, 0wx0000000000008082,
       0wx800000000000808a, 0wx8000000080008000,
       0wx000000000000808b, 0wx0000000080000001,
       0wx8000000080008081, 0wx8000000000008009,
       0wx000000000000008a, 0wx0000000000000088,
       0wx0000000080008009, 0wx000000008000000a,
       0wx000000008000808b, 0wx800000000000008b,
       0wx8000000000008089, 0wx8000000000008003,
       0wx8000000000008002, 0wx8000000000000080,
       0wx000000000000800a, 0wx800000008000000a,
       0wx8000000080008081, 0wx8000000000008080,
       0wx0000000080000001, 0wx8000000080008008]
      : Word64.word list

  val initialState =
      {a00 = zero, a01 = zero, a02 = zero, a03 = zero, a04 = zero,
       a10 = zero, a11 = zero, a12 = zero, a13 = zero, a14 = zero,
       a20 = zero, a21 = zero, a22 = zero, a23 = zero, a24 = zero,
       a30 = zero, a31 = zero, a32 = zero, a33 = zero, a34 = zero,
       a40 = zero, a41 = zero, a42 = zero, a43 = zero, a44 = zero}

  fun round (rc, {a00, a01, a02, a03, a04,
                  a10, a11, a12, a13, a14,
                  a20, a21, a22, a23, a24,
                  a30, a31, a32, a33, a34,
                  a40, a41, a42, a43, a44}) =
      let
        (* theta *)
        val c0 = a00 ^^ a10 ^^ a20 ^^ a30 ^^ a40
        val c1 = a01 ^^ a11 ^^ a21 ^^ a31 ^^ a41
        val c2 = a02 ^^ a12 ^^ a22 ^^ a32 ^^ a42
        val c3 = a03 ^^ a13 ^^ a23 ^^ a33 ^^ a43
        val c4 = a04 ^^ a14 ^^ a24 ^^ a34 ^^ a44
        val d0 = c4 ^^ rol (c1, 0w1)
        val d1 = c0 ^^ rol (c2, 0w1)
        val d2 = c1 ^^ rol (c3, 0w1)
        val d3 = c2 ^^ rol (c4, 0w1)
        val d4 = c3 ^^ rol (c0, 0w1)
        fun th d (v, w, x, y, z) = (v ^^ d, w ^^ d, x ^^ d, y ^^ d, z ^^ d)
        val (a00, a10, a20, a30, a40) = th d0 (a00, a10, a20, a30, a40)
        val (a01, a11, a21, a31, a41) = th d1 (a01, a11, a21, a31, a41)
        val (a02, a12, a22, a32, a42) = th d2 (a02, a12, a22, a32, a42)
        val (a03, a13, a23, a33, a43) = th d3 (a03, a13, a23, a33, a43)
        val (a04, a14, a24, a34, a44) = th d4 (a04, a14, a24, a34, a44)
        (* rho *)
        val a01 = rol (a01, 0w1)
        val a02 = rol (a02, 0w62)
        val a03 = rol (a03, 0w28)
        val a04 = rol (a04, 0w27)
        val a10 = rol (a10, 0w36)
        val a11 = rol (a11, 0w44)
        val a12 = rol (a12, 0w6)
        val a13 = rol (a13, 0w55)
        val a14 = rol (a14, 0w20)
        val a20 = rol (a20, 0w3)
        val a21 = rol (a21, 0w10)
        val a22 = rol (a22, 0w43)
        val a23 = rol (a23, 0w25)
        val a24 = rol (a24, 0w39)
        val a30 = rol (a30, 0w41)
        val a31 = rol (a31, 0w45)
        val a32 = rol (a32, 0w15)
        val a33 = rol (a33, 0w21)
        val a34 = rol (a34, 0w8)
        val a40 = rol (a40, 0w18)
        val a41 = rol (a41, 0w2)
        val a42 = rol (a42, 0w61)
        val a43 = rol (a43, 0w56)
        val a44 = rol (a44, 0w14)
        (* pi *)
        val (a00, a01, a02, a03, a04,
             a10, a11, a12, a13, a14,
             a20, a21, a22, a23, a24,
             a30, a31, a32, a33, a34,
             a40, a41, a42, a43, a44) =
            (a00, a11, a22, a33, a44,
             a03, a14, a20, a31, a42,
             a01, a12, a23, a34, a40,
             a04, a10, a21, a32, a43,
             a02, a13, a24, a30, a41)
        (* xi *)
        fun xe (x,y,z) = x ^^ (notb y && z)
        fun xi (v,w,x,y,z) =
            (xe (v,w,x), xe (w,x,y), xe (x,y,z), xe (y,z,v), xe (z,v,w))
        val (a00, a01, a02, a03, a04) = xi (a00, a01, a02, a03, a04)
        val (a10, a11, a12, a13, a14) = xi (a10, a11, a12, a13, a14)
        val (a20, a21, a22, a23, a24) = xi (a20, a21, a22, a23, a24)
        val (a30, a31, a32, a33, a34) = xi (a30, a31, a32, a33, a34)
        val (a40, a41, a42, a43, a44) = xi (a40, a41, a42, a43, a44)
        (* iota *)
        val a00 = a00 ^^ rc
      in
        {a00 = a00, a01 = a01, a02 = a02, a03 = a03, a04 = a04,
         a10 = a10, a11 = a11, a12 = a12, a13 = a13, a14 = a14,
         a20 = a20, a21 = a21, a22 = a22, a23 = a23, a24 = a24,
         a30 = a30, a31 = a31, a32 = a32, a33 = a33, a34 = a34,
         a40 = a40, a41 = a41, a42 = a42, a43 = a43, a44 = a44}
      end

  fun permute state =
      let
        fun foldl z nil = z
          | foldl z (h::t) = foldl (round (h, z)) t
      in
        foldl state roundConstants
      end

  fun absorbBlock b {a00, a01, a02, a03, a04,
                     a10, a11, a12, a13, a14,
                     a20, a21, a22, a23, a24,
                     a30, a31, a32, a33, a34,
                     a40, a41, a42, a43, a44} =
      {a00 = a00 ^^ read64 (b, 0, 8),
       a01 = a01 ^^ read64 (b, 8, 8),
       a02 = a02 ^^ read64 (b, 16, 8),
       a03 = a03 ^^ read64 (b, 24, 8),
       a04 = a04 ^^ read64 (b, 32, 8),
       a10 = a10 ^^ read64 (b, 40, 8),
       a11 = a11 ^^ read64 (b, 48, 8),
       a12 = a12 ^^ read64 (b, 56, 8),
       a13 = a13 ^^ read64 (b, 64, 8),
       a14 = a14 ^^ read64 (b, 72, 8),
       a20 = a20 ^^ read64 (b, 80, 8),
       a21 = a21 ^^ read64 (b, 88, 8),
       a22 = a22 ^^ read64 (b, 96, 8),
       a23 = a23 ^^ read64 (b, 104, 8),
       a24 = a24 ^^ read64 (b, 112, 8),
       a30 = a30 ^^ read64 (b, 120, 8),
       a31 = a31 ^^ read64 (b, 128, 8),
       a32 = a32 ^^ read64 (b, 136, 8),
       a33 = a33 ^^ read64 (b, 144, 8),
       a34 = a34 ^^ read64 (b, 152, 8),
       a40 = a40 ^^ read64 (b, 160, 8),
       a41 = a41 ^^ read64 (b, 168, 8),
       a42 = a42 ^^ read64 (b, 176, 8),
       a43 = a43 ^^ read64 (b, 184, 8),
       a44 = a44 ^^ read64 (b, 192, 8)}

  fun serialize (a,i,l) {a00, a01, a02, a03, a04,
                         a10, a11, a12, a13, a14,
                         a20, a21, a22, a23, a24,
                         a30, a31, a32, a33, a34,
                         a40, a41, a42, a43, a44} =
      let
        fun loop (a,i,l) nil = ()
          | loop (a,i,l) (h::t) =
            if l > 8 then (write64 (a, i, h, 8); loop (a,i+8,l-8) t)
            else write64 (a, i, h, l)
      in
        loop (a,i,l) [a00, a01, a02, a03, a04,
                      a10, a11, a12, a13, a14,
                      a20, a21, a22, a23, a24,
                      a30, a31, a32, a33, a34,
                      a40, a41, a42, a43, a44]
      end

  datatype input =
      INPUT of Word8Vector.vector * int * int
    | EOF

  val padL = 0wx80 : Word8.word

  fun readBlock {rate, padH} (w, i, l) =
        let
          val a = Word8Array.array (200, 0w0)
          val n = if l < rate then l else rate
          val s = Word8VectorSlice.slice (w, i, SOME n)
        in
          Word8ArraySlice.copyVec {dst = a, di = 0, src = s};
          if l >= rate
          then (a, INPUT (w, i+rate, l-rate))
          else (if l = rate - 1
                then Word8Array.update (a, l, Word8.orb (padH, padL))
                else (Word8Array.update (a, l, padH);
                      Word8Array.update (a, rate - 1, padL));
                (a, EOF))
        end

  fun absorb setting src =
      let
        fun loop m EOF = m
          | loop m (INPUT src) =
            let
              val (b, next) = readBlock setting src
            in
              loop (permute (absorbBlock b m)) next
            end
      in
        loop initialState (INPUT (src, 0, Word8Vector.length src))
      end

  fun squeeze rate output state =
      let
        fun loop state i l =
            if l <= rate
            then serialize (output,i,l) state
            else (serialize (output,i,rate) state;
                  loop (permute state) (i+rate) (l-rate))
      in
        loop state 0 (Word8Array.length output)
      end

  fun keccak {rate, padH, outputLen} input =
      let
        val state = absorb {rate = rate, padH = padH} input
        val out = Word8Array.array (outputLen, 0w0)
      in
        squeeze rate out state;
        Word8Array.vector out
      end

  type digest = Word8Vector.vector

  fun shake128 (x, l) =
      keccak {rate = 168, padH = 0wx1f, outputLen = l} x
  fun shake256 (x, l) =
      keccak {rate = 136, padH = 0wx1f, outputLen = l} x
  fun sha3_224 x =
      keccak {rate = 144, padH = 0wx06, outputLen = 28} x
  fun sha3_256 x =
      keccak {rate = 136, padH = 0wx06, outputLen = 32} x
  fun sha3_384 x =
      keccak {rate = 104, padH = 0wx06, outputLen = 48} x
  fun sha3_512 x =
      keccak {rate = 72, padH = 0wx06, outputLen = 64} x

  fun hex digest =
      CharVector.map
        Char.toLower
        (String.concat
           (Word8Vector.foldr
              (fn (w,z) => (if w < 0wx10
                            then "0" ^ Word8.fmt StringCvt.HEX w
                            else Word8.fmt StringCvt.HEX w) :: z)
              nil
              digest))

end


(*
(* test code *)
val _ = let
  fun assert (s,t) =
      if s = t then () else print ("expect: " ^ s ^ " but\nactual: " ^ t ^ "\n")
  fun rep n = Word8Vector.tabulate (n, Word8.fromInt)
in
  app (fn (s,n) => assert (s, SHA3.hex (SHA3.sha3_256 (rep n))))
    [("a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a", 0),
     ("5d53469f20fef4f8eab52b88044ede69c77a6a68a60728609fc4a65ff531e7d0", 1),
     ("76ab70dc46775b641a8e71507b07145aed11ae5efc0baa94ac06876af2b3bf5c", 2),
     ("1186d49a4ad620618f760f29da2c593b2ec2cc2ced69dc16817390d861e62253", 3),
     ("33bad5430899ed6f8beaf3e732b2a2cad1d40b7c9de0cfcdc7e0bc0756803a10", 4),
     ("8305d46643f04116ddc816f91544b7dcdc2a2cd34a0255498befce0795e21205", 5),
     ("ed2479f84980d846cd12447f241059ac1679ac30584443d40222fb7e1639414c", 6),
     ("59b1add388b7d625d2797894a4d88c7554a796a5a3d8ae232bf5f86bd72d5756", 7),
     ("eb4d0f2add0f6d0b26f0c65dbe71fe617cc6b43fb403649e82cc8bab41195f4e", 8),
     ("5257e34d7bb964f59ae4a46b3ba5921e04a550c2b1e04f268b297e358eab1362", 9),
     ("605a0514059192e26dbf06cfab86f3e9bbb9a69363d4be925b2246dcd8659a95", 10),
     ("4585ae166873f94a8930881014ffd14ebcdac1a0d599dc57efb4989b44472095", 11),
     ("4acbd92d310fc38697084c1bc7a79516a9be20701dae8eb36c643f07f45edbd6", 12),
     ("154e8759089d17dda455f74bbf702be99f678d58ae442ebe16264a7822a8a048", 13),
     ("85a3d4e61229da1490e64093e6118a733e3021b4678256335f437251f7d222c5", 14),
     ("89c25ecfdaea85b2f360c15a2ecf31f0bd59a0ce821a1aac31e2f73093dc4cd8", 15),
     ("39462d2a2320f8da572a97b0b39473d4312e0228b23e2c2fe0ae9b6c67f2343c", 16),
     ("6a37657a32560869154eaa9ca59fb648f3a96b62f5bdadd604bdfe0133783048", 17),
     ("636e904c72670ef3d78d9f0e121bb2b5eae69e806fa02314688d65600424349d", 18),
     ("6ad0db215fbd30e7ae5e22c2841357624d5605b1fc9fdb96882bd42529e6a994", 19),
     ("db32380abe23ef51f0547ac0fc4d095a2a16445a00fd8ce2e52628e189ba562d", 20),
     ("331cc1c851df863eb365860b2bc76e7e1e928261bac6f1a4ec0a25ed00d0e2c9", 21),
     ("9f5577ba75324007cd66f9d7f16ba6e74313d853e791fc865aacfcf63c561799", 22),
     ("f0e872c81033e67efc37dc258435966a0d1504bd14c2750276092abd0f9b0169", 23),
     ("2aade36ceb570d6d3a92fe79dcd612cfcd3226f020f205a74fb1213244ec4857", 24),
     ("5be74aa323cc1092d1a73a574496658cbb4809f4125ad275fc112e990bb8c1c8", 25),
     ("b6fe46e0dcab352bd9d4dca77cdc88b733001adcb089596330769cc6befc1bce", 26),
     ("5e080231cf3a92393c287ef7b5950d0394774700f82f2a0baff7ea82524223f6", 27),
     ("646dada5a492b9eb649e576f976a0cc76280111f767a63921dd29c09cd4ab434", 28),
     ("2022202e664ae6b9e468706b45cbea851cd7a352d6378236ac6e0da2924e9ab2", 29),
     ("7909bbd61ff6c4d0552562e3a57e61f23fb82aea99c9b2e004d94fc21a3f49cf", 30),
     ("be29b022732a2e397fe039ec17766da33a16d25555502775b0577bacbca40625", 31),
     ("050a48733bd5c2756ba95c5828cc83ee16fabcd3c086885b7744f84a0f9e0d94", 32),
     ("f7b83039ff915ee67c8586ba2d4b9c348733d9c75863056efa4581e80a09b66e", 33),
     ("bd6d450c1e2072e614152d5e6344a0cf14ffb16ac8658d68176e3af0f737c9a3", 34),
     ("89c2c6a69690335f7b475c47c62f930c8bc58f6ae92a99afd4d9743cb23a832c", 35),
     ("50b5d09f74a3fb9b07edc08a62bf546a143a1ad234fcfef0a386b78a4869191f", 36),
     ("8e17112c6cb1399a06443509ccc95366c29cd72dad72198c2395685c56fd5f1f", 37),
     ("4910e2311e19d30748f38e265a1aad54e0acc89111572ea548c1b71e28c74b29", 38),
     ("850103b8d08d566159d0bbfc175987f991790fec8d2905f9ee38796301cc8ff9", 39),
     ("02ba324d30ac854791579bef4d356a6ca0b7729905d241058b8e5a726e74b0f3", 40),
     ("1bf232e67ba8ed72f1bbb4903b2589cbdfa880292aadeb416b30093439ff2477", 41),
     ("5d5a49de3537a39cfc5f67716608a5012a003d5ece5416a37def8e663110106d", 42),
     ("2d3bb57730b167157eb825f3853971583f182456b91fbdd75014dc271887397f", 43),
     ("40ed8d3d40dced5dde358163f73a2b4be35c609522620830880cf6381eaedd23", 44),
     ("c7b82c4199a88162d5b04a4279f9a59dfcf97239d5bbbf4cdeecf3b475cc4a8b", 45),
     ("f338292a6f44f97546774ee97c578815f2a7bed5afe036952da0677f92f3fe1a", 46),
     ("b2e6c01e2d03b78bd71c3e246a85fb076b30f83159aa43ac18e33ed9cc232982", 47),
     ("8e7a856365f79e42004aa1a47a3b83e8e6d0ebdbb602f62793e574139b9f2a17", 48),
     ("a25b6ad8226fa9a9318cb86cc7714cb0bebfde6c20572bad7b89925f0d09a7e1", 49),
     ("57fa0a179b510246b3f8d195acb103cdc86d8315588325ef536c47fff2772658", 50),
     ("5cf520297c9b06aad67483986d4c018a70c67173059b9ec20de0c4f58278ffd3", 51),
     ("667e55fa3d3d6afd3ca3af6a60016598ebf2b1e98b59c702209c247b3360394b", 52),
     ("5233028f23b5bab4005cb86ea31b16435ec1f6c8fcf357580f6789dd795f1e29", 53),
     ("81eb9dbff576e3236776d43b5cac9dba10685ca4febdb0dba8160d5468f109da", 54),
     ("a91a138e3374d2d8fa4791b83a93a311a06a2926ef70153428cf6e1b239c10d4", 55),
     ("d192f5964dc70118fcac64bf0eb838009b816d344f67b04e8e78d5bde783e54a", 56),
     ("6adc19a25346d39409c264466ac7ef7efe4a88e765a8beaa191266791a906064", 57),
     ("275aa07ce6d62f62fd66e479f300c00544f697250b6d773f91bf06e206f88925", 58),
     ("15876b15fb6b696f89e78a040ac70bacf0ef0ec18389a5c4ca5d6d2406c22454", 59),
     ("3cb8d033ad71b9951ac09797b306540af9ba7819cfed6793e9dda6c93a0d3458", 60),
     ("829824766edd820e8947845c98130d19db0e286fb465344936326b6da5633a44", 61),
     ("8ffd849312cf58640b1df47ae8fee5f438ccc3de342e92a87a4f6e69ec27087a", 62),
     ("ba7af58d214bb604bcaad40ad55cca7d9815e7535f1c9837be8fb8fee2519560", 63),
     ("c8ad478f4e1dd9d47dfc3b985708d92db1f8db48fe9cddd459e63c321f490402", 64),
     ("9a11f135d2231be8ee824d1e9d3204018870defc2f469f34ef5969b4815cec3c", 65),
     ("0bbeca7b5bf86d84e697c0e52da482b9f0b8bb90c74c59c6358da5458527355f", 66),
     ("cd0e763f87c88cd162fe971f2f07ac888362ccc33272c2e79e4db84c891e7123", 67),
     ("ad93c686dbea416e5069cad1ca9d627b2a040e9c3d9cd148c93df58dd01b1e03", 68),
     ("ed379e9012f1d3a4fef5096688a2557b3ceb68c619245bffcf05a14a5a846fd9", 69),
     ("97a26b0e8066f35d400b7f12a6ae62a290bc1ca68660b4da8bf17afad6b8c948", 70),
     ("881ad9ffbd7f090efa51cbdfe93da23a0401f4446f7adf150d1c226851cbfff2", 71),
     ("fe58866b2893c6c40ee832ce40fb6eb4c70ff7c4794380d95c2ebeec62decd31", 72),
     ("797061b3aad8e724740c79dc697ef3de4c96c4db4483dba4e56f852222c72474", 73),
     ("6a3543b82c9a14d8597b2bb3916159cf54a4f3332ae55ec9706979babc206752", 74),
     ("d46dbeedd389bec862ef7431f929cedf81bd0a20573b539e11c8be957d6b286f", 75),
     ("64430afb89b5d3b944ff085d344a96f514441962e2b2808943e8159378fde2fa", 76),
     ("98fb8ac5ef7a58f079d41815484b19650084e4ca68d1540d90cddf536fa470bc", 77),
     ("e939ba431c6e703f7d26fd0eb511ef41a37f6eb386e80848eaba2c3d5be01f62", 78),
     ("80aac0531bf27d1b0e3e746c34a86db09503636e211e59c54f9952bb4e43684e", 79),
     ("0e34ae32d043275b50e9a9e0dd024ab024213f096ca6e5b7f16b524f0b37c271", 80),
     ("ceaa5666fc5bd015360a31eff0499d2aa8e7fa8391a0c490e806d785a9f80c5a", 81),
     ("6e85589621fe2abc1214a841b22ff667e0b797c04ee736da819adaccf4176cb1", 82),
     ("0259b91e342828924911db5071c10d890fd65c28703a000ce2eab3485d5caec5", 83),
     ("1711b6b8e196b2bd188b71b3207ae2b03d9b2ce42d6593f816d7127567b31d3d", 84),
     ("63f7bd481657a2c0da9b8c5d4bc37952aa568362cd27055049c1b43bc3bde48c", 85),
     ("9f8d2b19ab069cafa57faa67d3a7796f880f35e95ac71ef4663123616f585242", 86),
     ("d95375ff4e6be80944afda92819794259c7da31b1a952a309d7ebada4a78eac1", 87),
     ("9fd373552c93a6d904bfb67d45f7b174530c3ef7b9e71e84cbfb32dfed34831e", 88),
     ("832bf41e6c3a51c07b9e21c17056587d07a45012cdb5ff21a9ed7f5777e2a3e6", 89),
     ("8f35adf849b78a97a5f71ebf17c102521dcd86d9d20246b6eb47f78bf577809e", 90),
     ("f4c82daf9218f14c37ecfb50fe222644fae96f439998e990b1a8492e7bdef13b", 91),
     ("60b070c296cc64968ee5e4f65617d00be43f2e77af4994a12d6a28110c586c16", 92),
     ("f94996d82141af533f903be6f0611d2dea7584a895be7096b2dc35097b18e2a0", 93),
     ("805e1f47d06244283d88f32b046ca95554ad4018076c7480ded3ce7dd393bc82", 94),
     ("7804af4e51e0c1cdaf0f0a6fac6671b260434081f7ce05070beda63bdac9baca", 95),
     ("2be0af9221bfcdacb4b88321d8ccc9cebcc53188ecdb4e97813cd1d4c775c541", 96),
     ("e500bb02ab9ff69f068e9ccad41f0bf7a5c176f41119fa700791db12092ab7c4", 97),
     ("0f50c9f3538f0e35645720bb51d9191138a6cac64d9f83660957d4412abcec83", 98),
     ("05186deba22777fe7652d51f24ade28f18493b809236dbd60976d213575e2f86", 99),
     ("8c46d8901ae6919eb001cd4a9907a22aaa47954630099a473d2d5336ea7689e1", 100),
     ("af504dd36feb666b16fe553116adbdd604e449ca783e54a83171aee7ddc7e7b1", 101),
     ("986b81944604ef3a1f26032a04537777c0ecd1cb66b37e3ca6e9b108befaf56c", 102),
     ("120a055c592d237c0f535eebfc05673374fe4a50e1330293ef2c1ab611e0d0ba", 103),
     ("22892ec826b20680c8462ed416e15d402e567ff4e084b08274d702fd2411f40a", 104),
     ("1d867e60b657511e28c15c100b07b62af37cb4240c67354ca29373029b55babd", 105),
     ("30e02de534005d7f3064e57ac79ebaad483adfbdc1cb227b889f0bd66751adbe", 106),
     ("ba6b3eb9ea0cf9247b596e0bfb1129789046fa539c068b6255f21920a14672de", 107),
     ("9581220d4d55c622420719224da4d72ed27c5a9083fcc6c9754e0b45e89263ff", 108),
     ("d2082a60f6efe8b4de35e6956db4772cc74007a3c1588d6a1475de5ec6079388", 109),
     ("607ca9672e3c4692e094257ce00b332962ee247541d187b6135498a2f61b6d59", 110),
     ("b08646567d09c477939ea7f417fa307ec0d522a41d4f8e7aab4d9a889ec67fef", 111),
     ("575f18078b5874147ecd662f4260cdb3548756081ec3d2e7bed2397f67888622", 112),
     ("9213ee952527591e3c10fe51de916c10b72d90b234bd366bf2d3da89c660678e", 113),
     ("80e7dd3d16b56c9038b9a7f078199cf3ba76841e9b8264ac3e103c24d3c8871c", 114),
     ("fc9bf0a78cf7bc1407ade5d07995ce2ece2467482bc5d04f27bee116e33b26ad", 115),
     ("0cb94a64118ca106b5d62b7b0323085551b7688abb99fc47ad6f46aef79ad0e7", 116),
     ("20b54ebf368456150152f2181e5cce7fadd18c41cd4764236c68e4fe0d49f775", 117),
     ("398f0cbe7fbbdc6e5c88f5a6e58da25968705d4704fe9b16bff7bebf39f7838f", 118),
     ("a226deff22f92e994b1818026d923b9c93a72f8d5b4f2cc3cf622d6492373db3", 119),
     ("de05697a0743d511b0049e4055a7618cef7a3f54ab2ed031ec6d2f75c5416ad9", 120),
     ("6f2dc08e4a30ce8c74d175bb4d8f7a32f88aa145f190ba863d146d3047e01cee", 121),
     ("b722090b50928b07b1fa3d457cffdaf70d04fdbf3efa1d7ed4067dbe925b4f7a", 122),
     ("6c278930b0dfb48e7d9bd095c01dfd5dff859760cb5aaffff939907673f44448", 123),
     ("35c6c370972bf0f42ebd123b4fdceaaac4557689037249b3d64b67f034b74774", 124),
     ("4a36e7baeee661bf9e8750c48abdaadf969a83e22a91cf7d299496367ca7ebbe", 125),
     ("ee257791809ca409757bc9a21f81cbd85ada03d6edbb5cf4171cff2cec87dd7b", 126),
     ("c66018e60c774d770cc6539d42c023fa974c29e3fe2db5925f226b9cc5cf8b05", 127),
     ("bec3ebfba06834f224543cca2a427cb9329147be93e19aeb0e33a7119c7f63ef", 128),
     ("0f41a20921bcbc39ee382dfb54daf2db373ce6b178833111e22f45266124f3cc", 129),
     ("1cef9a7d66905e25ec17517db9ffd91ea71f05c11ba66d9ab11e6a46753ed617", 130),
     ("99ec5eb5856241c7aefbff8ef9e245d32fba82e5a99610549c41cf27f3ac0d53", 131),
     ("c89b4aabf8e4d1c37ca932f488ddc2803334bcdcc76953900ad630af70511761", 132),
     ("721f0e936b3b93c0384f970c07680a8a6293e5012295e83615ea4657ed5d7e17", 133),
     ("644e15224f5597351aef5c4bdd22b27ca0c19db2244431534c2a4a0bebfdf39c", 134),
     ("fded8fd9d6551c601eeb3b7c6bc5e5cfd8aad1d015b7e9aaa9c9b9475231d5e2", 135),
     ("cf3ccff92480a29160c2d38317c430e14749bfee1788106957dfe73f8c4930e5", 136),
     ("ce9d7dc90913ee5d92745019479a5352c6d6279bef18ed07dc0a83ee8084daca", 137),
     ("14914e322770698e090b44531062424057b3dcb0fbdfa93229d21788caa29a6c", 138),
     ("d0af074a51ab3138db0581170b2f4e02f464095e9ad62cbe68a48c6938f34b47", 139),
     ("3a81a47ee2720f109e7d1cb54a36f77b64dd465803f9717264a5e5f131df5e12", 140),
     ("4134fa637cc87ac52320f311f4a681ef740b58da8ce2c09c721eedd720179c4f", 141),
     ("4996d371abd506e72178b4cbea8e9f5ad781a5a566543d97f89a4efb13d5bb5f", 142),
     ("295fef4d46110ee21fba0d1798a1bb7c1bbc88306bc9b7661b18ace7170f02ae", 143),
     ("a32aeb728cd50069f906559158f1d0a9df3a8c6795e5cbafde00c632f08bade3", 144),
     ("93657342bb49bc9e242c4f5573ef621d6cd90f4a2082b14fef85bc9884d00ac9", 145),
     ("34462e1b472269bc270a6dbf09d9075fe9cb5350cc4b74380d17ac19d580d125", 146),
     ("c1bbbc82e8512bbbdfbcb9d9a68552bd4ef3b7953541451c82f3bc92ac8c4bf9", 147),
     ("962cf8107df385b4e1b1b3fe3694bbc731d21faaafbc2b48ea1504ce07f19173", 148),
     ("078748dde5fe38cf8af48260cb531bf8ef68f2700437c1db3e210decb757417b", 149),
     ("adaa23ca1ed892ad1cf028cd40ba8ae2bfd3d7df1289c3f2319072106f587a98", 150),
     ("ec656cde6abc81a8c85c5f682d392737c495dc871303dc3d11fc651765ad99bc", 151),
     ("bc744e374fd83cdf6edd709689c4f3bcde56ba612469f331789ac4e738f804b4", 152),
     ("4cd9a50e3f427a64e312a1acd8bc39d47030ee1eac173e84c75c481d3cf13911", 153),
     ("ef5a980e76e92c94bc43c5db34ae25b990b1b8a4cc28e834eb4ca4a27757fe6f", 154),
     ("a59526ae178aaa3cd3d1849f9aeeb914fc555ca790c18ec1ea63814e45480189", 155),
     ("92915b3078da2ec31978123691517835af47eec12d9162d269900d0dda0ec58e", 156),
     ("81b7076d3ec489393a1752f4b72c51c9cad0bde0f2aec6f402739e9c20359674", 157),
     ("3bccd5439fc7c4bd3025675f7a9c39ff87c8cfdbeada0b6dd29eb179629a689c", 158),
     ("764bf722daf72e8f04ae830b10313c836667676dd9e8a072e4a1c0482ea682f4", 159),
     ("3bdee46e603bc40a719e84a9913468d790ee33157195217c1a723596a9708a9b", 160),
     ("e55aaaf6f51d43a5336ba4d29af2128c3dc3bc3d9d70b3e41950f445beb1e5a9", 161),
     ("f071be09184e4849ed48f3f71cb254a9d792c1a37ba8f61119be4ae5f5c5e9be", 162),
     ("b9f6e53ff9892db0a04805270e5d60b3c62f72bcccf2052cbaba2ae2cb732c78", 163),
     ("576e9dd4f7ce4e9432d456d02c5ab77e15a1dbf74e60f4632f80061a756bc201", 164),
     ("67d11a37491421224c1ed64b3d2af9c3b45c413fa0fbedb0ed1bed26126703dd", 165),
     ("4fee7968e68b1dc75c14e23c16c4cddb9fba10ae7edaef32345d7d9450f05cd8", 166),
     ("cac5458d48e6163cc843d5f18e263e3ce03290cbd5a866bd3b7d02dff2da413e", 167),
     ("369a33badfa618d58d16aaddeaff98d66b30a70c2deee42fc809b9721dc1c524", 168),
     ("6d9ef22b871f8518d91fe5fd48baf514f1165eca0a145f8975eb4b40898dab7c", 169),
     ("92e47248a9591f77d39067359b91fba0f011f1c753e9284c50ba10fa436cade1", 170),
     ("98ac409c2e9fa2daa81a36ebd188ceba0b1997f9c8776c73af360a5c9d6b89d7", 171),
     ("a9317975e935a13c8e86e5c2dbd9c829936a7a222a28b52d6607e99faa362aa4", 172),
     ("b8c8d53bccf1f1b65dca8f701853e6fb575a0929c9dd7c0bcdc3381ec4e8bc80", 173),
     ("8eb9f83dbcdb9cb9fefaa713ea6bd300389bd5f85fb63aeb60bbf39f0072a115", 174),
     ("c913434c625fb9b9969ecdd5fc622b53152b812f605c1274a7554ee18bc26bbd", 175),
     ("2a3c05080e904eacb025774d56d60c44e7716b90ed705d8640975a1c752d6eac", 176),
     ("d4c19d7ecd62c298fc6fcfb4256ed7208d4cbb01f81ca1c1f7c36c9a55667f80", 177),
     ("bb5f95132bec7c4da72bc38c221cb8be458f90233cf7a5da470a89aaff8057bd", 178),
     ("87f6f39cc3fca24ce71440cf4ef792c8fca0d72291044849a256bc7bf7a59950", 179),
     ("e05aa3289774e9c934ba4b6a621a1602bc8d52d2aaa88411aadfac36e259dedf", 180),
     ("a104b60ca8e7b09aa4b21625a6ffcd60560889736a368ded1f4ba8ead8ee732a", 181),
     ("07f03cb0615479fa964632e84a12a7aafdf2b0b6e76c9aa1fabcaeb0fd89fce0", 182),
     ("7580655a0445669030ccec133cb73e83a628b8e1f50c3b933c889e7cb3f83aa7", 183),
     ("a0c0169ea227cbc67d8e5942118b4a3a7b4654668e86f4c332013067dd0f2014", 184),
     ("33bd57010692128148b62e21a1a435097f01bdd21739e1231d6e79b227ae8287", 185),
     ("4c5a425adf6ec2cf5b50b443e014d9043659304da510bb841fd014f04fb955bf", 186),
     ("1aff2039cd670ef2ed07e69858cde39bcb0890a98725d1fb2d1dfc4cd2dc545a", 187),
     ("a3007f2155e2b7314b3685e848f249cf3f32f17e0cae736f8515f1ee8468b06b", 188),
     ("d4569f3356c8b426421b2f15f6dce14c406216a1cdf2aae78e99ae765003d53c", 189),
     ("69aa9378f0a17e0b88cf85171af22f569c321f66caf3193c8de130b007ac561e", 190),
     ("8658173321b8e1a1db6c55192851cb681b17f0b89b10d4d5766ac0efe389db62", 191),
     ("b86bfbea7e3f8d0aa23a1d1f6e38de98c0a1046274664ad1863cf2ff9a7f9565", 192),
     ("961450e75313537fa23b0e3ea10a231cce0df3ed2e5ff4ef0f73c26776cfd7b4", 193),
     ("c72220672365514b8d738d9849a029bbf0b14c4d18e7a3b27aa7e90a5da015e3", 194),
     ("947a1bd610a6c54d7df166ec235ecc3a686a0ab8143ec49bea754f12c03461c8", 195),
     ("9f40c233c2d868926ff9016820db5e6244028b1a041a62bae105affc85a643c6", 196),
     ("30726efcfc02addd0f812300be33adc6d64df47aea20c0aa09197a80ddb24dcd", 197),
     ("e3cb59a416ceb3811ef17978d65b57c16705f205d21bdb7f5b958eb09d21b758", 198),
     ("f1b4bc516891c3fa44f1070adc05e1164080fba3f7a17840c25b1e3584c11540", 199),
     ("5f728f63bf5ee48c77f453c0490398fa645b8d4c4e56be9a41cfec344d6ca899", 200)]
end
*)
