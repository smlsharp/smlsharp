fun f21 x =
    case x of
      {n1 = 1, n2, ...} => n2 + (f22 x)
    | {n2, n3, ...} => n3
and f22 x =
    case x of
      {n1 = 1, n2, ...} => n2
    | {n2, n3, ...} => n3 + (f21 x);
