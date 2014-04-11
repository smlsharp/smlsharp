signature CHAR =
sig
  eqtype char
  eqtype string
  val minChar : char
  val maxChar : char
  val maxOrd : int
  val ord : char -> int
  val chr : int -> char
  val succ : char -> char
  val pred : char -> char
  val compare : char * char -> order
  val < : char * char -> bool
  val <= : char * char -> bool
  val > : char * char -> bool
  val >= : char * char -> bool
  val contains : string -> char -> bool
  val notContains : string -> char -> bool
  val isAscii : char -> bool
  val toLower : char -> char
  val toUpper : char -> char
  val isAlpha : char -> bool
  val isAlphaNum : char -> bool
  val isCntrl : char -> bool
  val isDigit : char -> bool
  val isGraph : char -> bool
  val isHexDigit : char -> bool
  val isLower : char -> bool
  val isPrint : char -> bool
  val isSpace : char -> bool
  val isPunct : char -> bool
  val isUpper : char -> bool
  val toString : char -> string
  val scan : (Char.char, 'a) StringCvt.reader -> (char, 'a) StringCvt.reader
  val fromString : string -> char option
  val toCString : char -> string
  val fromCString : string -> char option
end
