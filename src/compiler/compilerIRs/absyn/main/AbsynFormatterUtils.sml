structure AbsynFormatterUtils =
struct
  open SMLFormat.FormatExpression

  fun N0 x = [Guard (SOME {cut = true, strength = 0, direction = Neutral}, x)]

  fun iftrue (x, y) true = x
    | iftrue (x, y) false = y

  fun ifsome (x, y) (SOME _) = x
    | ifsome (x, y) NONE = y

  fun ifcons (x, y) (_::_) = x
    | ifcons (x, y) nil = y

  fun ifcons2 (x, y) (_::_::_) = x
    | ifcons2 (x, y) _ = y

  fun ifsingle (x, y) [_] = x
    | ifsingle (x, y) _ = y

  fun N0ifnotsingle x [_] = x
    | N0ifnotsingle x _ = N0 x

  fun N0ifcons x (_::_) = N0 x
    | N0ifcons x _ = x

  fun N0ifcons2 x (_::_::_) = N0 x
    | N0ifcons2 x _ = x

  fun N0ifsome x (SOME _) = N0 x
    | N0ifsome x NONE = x

  fun decs (formatter, first, sep, next) nil = nil
    | decs (formatter, first, sep, next) [x] = formatter first x
    | decs (formatter, first, sep, next) (h :: t) =
      List.concat (formatter first h :: map (fn i => sep @ formatter next i) t)

  fun decs2 (formatter, first1, first2, sep, next1, next2) items =
      decs (formatter, (first1, first2), sep, (next1, next2)) items

end
