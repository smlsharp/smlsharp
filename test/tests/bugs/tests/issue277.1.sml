fun f x =
    case x of
      Bind => 1
    | Formatter _ => 2
    | Match => 3
    | MatchCompBug _ => 4
    | SysErr _ => 5
    | Fail _ => 6;
exception E;
val x = f E;
