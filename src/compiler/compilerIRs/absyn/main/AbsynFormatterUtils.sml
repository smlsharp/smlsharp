structure AbsynFormatterUtils =
struct
  open SMLFormat.FormatExpression

  fun iftrue (x, y) true = x
    | iftrue (x, y) false = y

  fun ifsome (x, y) (SOME _) = x
    | ifsome (x, y) NONE = y

  fun ifcons (x, y) (_::_) = x
    | ifcons (x, y) nil = y

  fun ifsingle (x, y) [_] = x
    | ifsingle (x, y) _ = y

  fun decs (formatter, first, sep, next) nil = nil
    | decs (formatter, first, sep, next) [x] = formatter first x
    | decs (formatter, first, sep, next) (h :: t) =
      Sequence (formatter first h)
      :: map (fn i => Sequence (Sequence sep :: formatter next i)) t

  fun decs2 (formatter, first1, first2, sep, next1, next2) items =
      decs (formatter, (first1, first2), sep, (next1, next2)) items

end
