(**
 * Formatters for Target Platform.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: TargetPlatformFormatter.sml,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)

functor TargetPlatformFormatter(Target : TARGET_PLATFORM) : sig

  eqtype uint
  eqtype sint

  structure Target : sig eqtype uint eqtype sint end
  sharing type uint = Target.uint
  sharing type sint = Target.sint

  val format_uint : uint -> SMLFormat.FormatExpression.expression list
  val format_uint_hex : uint -> SMLFormat.FormatExpression.expression list
  val format_sint : sint -> SMLFormat.FormatExpression.expression list
  val format_string_ML : string -> SMLFormat.FormatExpression.expression list
  val format_string_C : string -> SMLFormat.FormatExpression.expression list
  val format_real : string -> SMLFormat.FormatExpression.expression list

end =
struct

  structure Target = Target
  type uint = Target.uint
  type sint = Target.sint

  structure FE = SMLFormat.FormatExpression

  fun term s =
      FE.Term (size s, s)

  fun break n =
      FE.Indicator {space = true, newline = SOME{priority = FE.Preferred(n)}}

  fun formatSignedNumber s =
      [term (String.translate (fn #"~" => "-" | x => str x) s)]

  fun format_uint n =
      [term (Target.formatUInt (StringCvt.DEC) n)]

  fun format_uint_hex n =
      [term ("0x" ^ Target.formatUInt (StringCvt.HEX) n)]

  fun format_sint n =
      formatSignedNumber (Target.formatSInt (StringCvt.DEC) n)

  fun format_real s =
      formatSignedNumber s

  fun right n s =
      if n < size s then substring (s, size s - n, n) else s

  fun oct x =
      "\\" ^ right 3 ("00" ^ Int.fmt (StringCvt.OCT) (ord x))

  fun dec x =
      "\\" ^ right 3 ("00" ^ Int.fmt (StringCvt.DEC) (ord x))

  fun format_string_ML s =
      [term ("\"" ^ String.translate (fn #"\"" => "\\\""
                                       | #"\n" => "\\n"
                                       | #"\r" => "\\r"
                                       | #"\t" => "\\t"
                                       | #"\\" => "\\\\"
                                       | c => if Char.isPrint c
                                              then str c else dec c)
                                     s ^ "\"")]

  fun format_string_C s =
      [term ("\"" ^ String.translate oct s ^ "\"")]

end
