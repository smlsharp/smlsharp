(*
test case for recursive function call.

<ul>
  <li>type of argument
    <ul>
      <li>int</li>
      <li>real</li>
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
fun intSelfTail 0 = 0
  | intSelfTail n = intSelfTail (n - 1);
val intSelfTail_x = intSelfTail 3;

fun intSelfNonTail 0 = 0
  | intSelfNonTail 1 = 1
  | intSelfNonTail n = intSelfNonTail (n - 1) + intSelfNonTail (n - 2);
val intSelfNonTail_x = intSelfNonTail 3;

fun intNonSelfTail_f 0 = 0
  | intNonSelfTail_f n = intNonSelfTail_g (n - 1)
and intNonSelfTail_g 0 = 1
  | intNonSelfTail_g n = intNonSelfTail_f (n - 1);
val intNonSelfTail_x = intNonSelfTail_f 3;

fun intNonSelfNonTail_f 0 = 0
  | intNonSelfNonTail_f n = 1 + intNonSelfNonTail_g (n - 1)
and intNonSelfNonTail_g 0 = 1
  | intNonSelfNonTail_g n = 1 + intNonSelfNonTail_f (n - 1);
val intNonSelfNonTail_x = intNonSelfNonTail_f 3;

(********************)
fun realSelfTail n = if n < 0.0 then 0.0 else realSelfTail (n - 1.0);
val realSelfTail_x = realSelfTail 3.0;

fun realSelfNonTail n = 
    if n <= 0.0
    then 1.0
    else
      if n <= 1.0
      then 1.0
      else realSelfNonTail (n - 1.0) + realSelfNonTail (n - 2.0);
val realSelfNonTail_x = realSelfNonTail 3.0;

fun realNonSelfTail_f n = if n < 0.0 then 0.0 else realNonSelfTail_g (n - 1.0)
and realNonSelfTail_g n = if n < 0.0 then 1.0 else realNonSelfTail_f (n - 1.0);
val realNonSelfTail_x = realNonSelfTail_f 3.0;

fun realNonSelfNonTail_f n =
    if n < 0.0 then 0.0 else 1.0 + realNonSelfNonTail_g (n - 1.0)
and realNonSelfNonTail_g n =
    if n < 0.0 then 0.0 else 1.0 + realNonSelfNonTail_f (n - 1.0);
val realNonSelfNonTail_x = realNonSelfNonTail_f 3.0;

(********************)
fun polySelfTail (isEnd, next, n) =
    if isEnd n then n else polySelfTail (isEnd, next, (next n));
val polySelfTail_int = polySelfTail (fn n => n = 0, fn n => n - 1, 3);
val polySelfTail_real = polySelfTail (fn n => n < 0.0, fn n => n - 1.0, 3.0);

fun polySelfNonTail (isEnd, next, n) =
    if isEnd n then n else next (polySelfNonTail (isEnd, next, (next n)));
val polySelfNonTail_int = polySelfNonTail (fn n => n = 0, fn n => n - 1, 3);
val polySelfNonTail_real =
    polySelfNonTail (fn n => n < 0.0, fn n => n - 1.0, 3.0);

fun polyNonSelfTail_f (isEnd, next, n) =
    if isEnd n then n else polyNonSelfTail_g (isEnd, next, (next n))
and polyNonSelfTail_g (isEnd, next, n) =
    if isEnd n then n else polyNonSelfTail_f (isEnd, next, (next (next n)));
val polyNonSelfTail_int = polyNonSelfTail_f (fn n => n = 0, fn n => n - 1, 3);
val polyNonSelfTail_real =
    polyNonSelfTail_f (fn n => n < 0.0, fn n => n - 1.0, 3.0);

fun polyNonSelfNonTail_f (isEnd, next, n) =
    if isEnd n then n else next (polyNonSelfNonTail_g (isEnd, next, next n))
and polyNonSelfNonTail_g (isEnd, next, n) =
    if isEnd n
    then n
    else next (polyNonSelfNonTail_f (isEnd, next, next (next n)));
val polyNonSelfNonTail_int =
    polyNonSelfNonTail_f (fn n => n = 0, fn n => n - 1, 3);
val polyNonSelfNonTail_real =
    polyNonSelfNonTail_f (fn n => n < 0.0, fn n => n - 1.0, 3.0);
