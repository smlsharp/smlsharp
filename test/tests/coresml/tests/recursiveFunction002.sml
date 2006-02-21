(*
test case for free variable access from inside of recursive called function.

<ul>
  <li>type of referred free variable
    <ul>
      <li>polytype</li>
    </ul>
  </li>
  <li>type of argument
    <ul>
      <li>polytype</li>
    </ul>
  </li>
  <li>relation between caller and callee of recursive call
    <ul>
      <li>self recursive</li>
      <li>non self recursive</li>
    </ul>
  </li>
  <li>position of recursive call
    <ul>
      <li>tail position</li>
      <li>non tail position</li>
    </ul>
  </li>
</ul>
*)
(********************)
fun polySelfTail isEnd next arg =
    let
      fun inner n =
          if isEnd n then (arg, n) else inner (next n)
    in inner end;
val polySelfTail_int_int = polySelfTail (fn n => n = 0) (fn n => n - 1) 1 3;
val polySelfTail_real_real =
    polySelfTail (fn n => n < 0.0) (fn n => n - 1.0) 1.0 3.0;

fun dummy x = x;

fun polySelfNonTail isEnd next arg =
    let
      fun inner n =
          if isEnd n
          then (dummy arg; n)
          else next (inner (next n))
    in
      inner
    end;
val polySelfNonTail_int_int =
    polySelfNonTail (fn n => n = 0) (fn n => n - 1) 1 3;
val polySelfNonTail_real_real =
    polySelfNonTail (fn n => n < 0.0) (fn n => n - 1.0) 1.2 3.0;

fun polyNonSelfTail isEnd next arg =
    let
      fun f n =
          if isEnd n then (arg, n) else g (next n)
      and g n =
          if isEnd n then (arg, n) else f (next (next n))
    in
      f
    end;
val polyNonSelfTail_int_int =
    polyNonSelfTail (fn n => n = 0) (fn n => n - 1) 1 3;
val polyNonSelfTail_real_real =
    polyNonSelfTail (fn n => n < 0.0) (fn n => n - 1.0) 1.2 3.0;

fun polyNonSelfNonTail isEnd next arg =
    let
      fun f n =
          if isEnd n
          then (dummy arg; n)
          else next (g (next n))
      and g n =
          if isEnd n
          then (dummy arg; n)
          else next (f (next (next n)))
    in
      f
    end;
val polyNonSelfNonTail_int_int =
    polyNonSelfNonTail (fn n => n = 0) (fn n => n - 1) 1 3;
val polyNonSelfNonTail_real_real =
    polyNonSelfNonTail (fn n => n < 0.0) (fn n => n - 1.0) 1.2 3.0;
