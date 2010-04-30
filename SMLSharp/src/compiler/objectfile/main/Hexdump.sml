(* -*- sml -*- *)
(**
 * Special pretty printer for object files.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: Hexdump.sml,v 1.3 2007/11/19 06:00:02 katsu Exp $
 *)
structure Hexdump =
struct

  local
    structure FE = SMLFormat.FormatExpression

    fun term s = FE.Term (size s, s)
    val break1 =
        FE.Indicator {space = true,
                      newline = SOME {priority = FE.Preferred(1)}}

    fun fmt2 n =
        let
          fun right s = String.extract (s, size s - 2, NONE)
        in
          right ("0" ^ Word8.fmt StringCvt.HEX n)
        end

    fun fmt8 n =
        let
          fun right s = String.extract (s, size s - 8, NONE)
        in
          right ("0000000" ^ Int.fmt StringCvt.HEX n)
        end

    fun fmtchr n =
        if 0wx20 <= n andalso n <= 0wx7e
        then str (chr (Word8.toInt n))
        else "."

    val sub = Word8Array.sub

    datatype format = HEX of Word8.word | SP | SEP

    fun formatHex (SP::t) = "   " ^ formatHex t
      | formatHex (HEX x::t) = " " ^ fmt2 x ^ formatHex t
      | formatHex (SEP::t) = " " ^ formatHex t
      | formatHex nil = ""

    fun formatChr (SP::t) = " " ^ formatChr t
      | formatChr (HEX x::t) = fmtchr x ^ formatChr t
      | formatChr (SEP::t) = formatChr t
      | formatChr nil = ""
  in

  fun hexdump' base buf =
      let
        val addr = base - base mod 16
        val n = 16 - base mod 16
        val m = 16 - n

        fun format i 0 m n = nil
          | format i 9 m n = SEP :: format i 8 m n
          | format i c 0 0 = SP :: format i (c-1) 0 0
          | format i c 0 n = HEX (sub (buf, i)) :: format (i+1) (c-1) 0 (n-1)
          | format i c m n = SP :: format i (c-1) (m-1) n

        fun dumpLine i addr m n =
            if Word8Array.length buf - i <= 0 then nil
            else
              let
                val n = Int.min (Word8Array.length buf - i, n)
                val f = format i 17 m n
                val t = fmt8 addr ^ ":" ^ formatHex f ^ "  " ^ formatChr f
              in
                break1 :: term t :: dumpLine (i+n) (addr+16) 0 16
              end
      in
        case dumpLine 0 addr m n of
          FE.Indicator _ :: t => t
        | l => l
      end

  fun hexdump buf = hexdump' 0 buf

  fun hexdumpList arrays =
      let
        fun loop base nil = nil
          | loop base [buf] = hexdump' base buf
          | loop base (h::t) =
            hexdump' base h @ break1 :: loop (base + Word8Array.length h) t
      in
        loop 0 arrays
      end

  end
end
