(* locale-sig.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *)

signature LOCALE =
  sig

    eqtype  category

    val collate : category

    val ctype : category

    val monetary : category

    val numeric : category

    val time : category

    val messages : category

    exception NoSuchLocale

    val getCategory : category -> string

    val setCategory : (category * string) -> unit
    val setLocale : string -> unit

    type  locale_state

    val saveLocale : unit -> locale_state

    val restoreLocale : locale_state -> unit

    datatype sign_posn
      = PAREN
      | PREC_ALL
      | PREC_CUR
      | FOLLOW_ALL
      | FOLLOW_CURR

    type  lconv

    val conventions : unit -> lconv

    val decimalPoint : lconv -> char

    val thousandsSep : lconv -> char option

    val grouping : lconv -> int list

    val currencySymbol : lconv -> string

    val intCurrSymbol : lconv -> string

    val monDecimalPoint : lconv -> char option

    val monThousandsSep : lconv -> char option

    val monGrouping : lconv -> int list

    val positiveSign : lconv -> string

    val negativeSign : lconv -> string

    val intFracDigits : lconv -> int option

    val fracDigits : lconv -> int option

    val posCSPrecedes : lconv -> bool option

    val posSepBySpace : lconv -> bool option

    val negCSPrecedes : lconv -> bool option

    val negSepBySpace : lconv -> bool option

    val posSignPosn : lconv -> sign_posn option

    val negSignPosn : lconv -> sign_posn option

    exception NoSuchClass

    eqtype  char_class

    val charClass : string -> char_class

    val isClass : (WideChar.char * char_class) -> bool

  end;
