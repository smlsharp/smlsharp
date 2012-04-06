(*
scope of polymorphic in Rank-1 type system.

<ul>
  <li>the number of nesting of abstractions
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
  <li>argument type
    <ul>
      <li>polytype</li>
      <li>monotype</li>
    </ul>
  </li>
  <li>argument type occurs in the range type of function.
    <ul>
      <li>(1)yes</li>
      <li>(2)no</li>
    </ul>
  </li>
</ul>
*)
val fPP11 = fn x => fn y => (x, y);
val xPP111 = (fPP11 1 "a", fPP11 "a" 2);
val xPP112 = let val f = fPP11 1 in (f "a", f (1, 2)) end;

val fPP12 = fn x => fn y => (x, x);
val xPP121 = (fPP12 1 "a", fPP12 "a" 2);
val xPP122 = let val f = fPP12 1 in (f "a", f (1, 2)) end;

val fPP21 = fn x => fn y => (y, y);
val xPP211 = (fPP21 1 "a", fPP21 "a" 2);
val xPP212 = let val f = fPP21 1 in (f "a", f (1, 2)) end;

val fPP22 = fn x => fn y => true;
val xPP221 = (fPP22 1 "a", fPP22 "a" 2);
val xPP222 = let val f = fPP22 1 in (f "a", f (1, 2)) end;

(**********)

val fMP11 = fn (x : int) => fn y => (x, y);
val xMP111 = (fMP11 1 "a", fMP11 2 1.23);
val xMP112 = let val f = fMP11 1 in (f "a", f (1, 2)) end;

val fMP12 = fn (x : int) => fn y => (x, x);
val xMP121 = (fMP12 1 "a", fMP12 2 1.23);
val xMP122 = let val f = fMP12 1 in (f "a", f (1, 2)) end;

val fMP21 = fn x => fn y => (y, y);
val xMP211 = (fMP21 1 "a", fMP21 2 1.23);
val xMP212 = let val f = fMP21 1 in (f "a", f (1, 2)) end;

val fMP22 = fn (x : int) => fn y => true;
val xMP221 = (fMP22 1 "a", fMP22 2 1.23);
val xMP222 = let val f = fMP22 1 in (f "a", f (1, 2)) end;

(**********)

val fPM11 = fn x => fn (y : int) => (x, y);
val xPM111 = (fPM11 "a" 1, fPM11 true 2);

val fPM12 = fn x => fn (y : int) => (x, x);
val xPM121 = (fPM12 "a" 1, fPM12 true 2);

val fPM21 = fn x => fn (y : int) => (y, y);
val xPM211 = (fPM21 "a" 1, fPM21 true 2);

val fPM22 = fn x => fn (y : int) => 1.23;
val xPM221 = (fPM22 "a" 1, fPM22 true 2);

(********************)

val fPPP111 = fn x => fn y => fn z => (x, y, z);
val xPPP1111 = (fPPP111 1 "a" true, fPPP111 1.23 2 "c");
val xPPP1112 =
    let
      val f1 = fPPP111 1 val f2 = fPPP111 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP112 = fn x => fn y => fn z => (x, y);
val xPPP1121 = (fPPP112 1 "a" true, fPPP112 1.23 2 "c");
val xPPP1122 =
    let
      val f1 = fPPP112 1 val f2 = fPPP112 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP121 = fn x => fn y => fn z => (x, z);
val xPPP1211 = (fPPP121 1 "a" true, fPPP121 1.23 2 "c");
val xPPP1212 =
    let
      val f1 = fPPP121 1 val f2 = fPPP121 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP122 = fn x => fn y => fn z => (x, x);
val xPPP1221 = (fPPP122 1 "a" true, fPPP122 1.23 2 "c");
val xPPP1222 =
    let
      val f1 = fPPP122 1 val f2 = fPPP122 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP211 = fn x => fn y => fn z => (y, z);
val xPPP2111 = (fPPP211 1 "a" true, fPPP211 1.23 2 "c");
val xPPP2112 =
    let
      val f1 = fPPP211 1 val f2 = fPPP211 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP212 = fn x => fn y => fn z => (y, y);
val xPPP2121 = (fPPP212 1 "a" true, fPPP212 1.23 2 "c");
val xPPP2122 =
    let
      val f1 = fPPP212 1 val f2 = fPPP212 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP221 = fn x => fn y => fn z => (z, z);
val xPPP2211 = (fPPP221 1 "a" true, fPPP221 1.23 2 "c");
val xPPP2212 =
    let
      val f1 = fPPP221 1 val f2 = fPPP221 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

val fPPP222 = fn x => fn y => fn z => 1.23;
val xPPP2221 = (fPPP222 1 "a" true, fPPP222 1.23 2 "c");
val xPPP2222 =
    let
      val f1 = fPPP222 1 val f2 = fPPP222 1.23
      val g11 = f1 1 val g12 = f1 true
      val g21 = f2 true val g22 = f2 1
    in (g11 "a", g12 (1, 2), g21 "a", g22 (1, 2)) end;

(**********)

val fMMP111 = fn (x : int) => fn (y : int) => fn z => (x + 1, y + 1, z);
val xMMP1111 = (fMMP111 1 2 true, fMMP111 2 3 "c");

val fMMP112 = fn (x : int) => fn (y : int) => fn z => (x + 1, y + 1);
val xMMP1121 = (fMMP112 1 2 true, fMMP112 2 3 "c");

val fMMP121 = fn (x : int) => fn (y : int) => fn z => (x + 1, z);
val xMMP1211 = (fMMP121 1 2 true, fMMP121 2 3 "c");

val fMMP122 = fn (x : int) => fn (y : int) => fn z => (x + 1);
val xMMP1221 = (fMMP122 1 2 true, fMMP122 2 3 "c");

val fMMP211 = fn (x : int) => fn (y : int) => fn z => (y + 1, z);
val xMMP2111 = (fMMP211 1 2 true, fMMP211 2 3 "c");

val fMMP212 = fn (x : int) => fn (y : int) => fn z => (y + 1);
val xMMP2121 = (fMMP212 1 2 true, fMMP212 2 3 "c");

val fMMP221 = fn (x : int) => fn (y : int) => fn z => z;
val xMMP2211 = (fMMP221 1 2 true, fMMP221 2 3 "c");

val fMMP222 = fn (x : int) => fn (y : int) => fn z => true;
val xMMP2221 = (fMMP222 1 2 true, fMMP222 2 3 "c");

(**********)

val fMPP111 = fn (x : int) => fn y => fn z => (x + 1, y, z);
val xMPP1111 = (fMPP111 1 2 true, fMPP111 2 1.23 "c");
val xMPP1112 =
    let val f = fMPP111 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP112 = fn (x : int) => fn y => fn z => (x + 1, y);
val xMPP1121 = (fMPP112 1 2 true, fMPP112 2 1.23 "c");
val xMPP1122 =
    let val f = fMPP112 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP121 = fn (x : int) => fn y => fn z => (x + 1, z);
val xMPP1211 = (fMPP121 1 2 true, fMPP121 2 1.23 "c");
val xMPP1212 =
    let val f = fMPP121 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP122 = fn (x : int) => fn y => fn z => (x + 1);
val xMPP1221 = (fMPP122 1 2 true, fMPP122 2 1.23 "c");
val xMPP1222 =
    let val f = fMPP122 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP211 = fn (x : int) => fn y => fn z => (y, z);
val xMPP2111 = (fMPP211 1 2 true, fMPP211 2 1.23 "c");
val xMPP2112 =
    let val f = fMPP211 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP212 = fn (x : int) => fn y => fn z => y;
val xMPP2121 = (fMPP212 1 2 true, fMPP212 2 1.23 "c");
val xMPP2122 =
    let val f = fMPP212 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP221 = fn (x : int) => fn y => fn z => z;
val xMPP2211 = (fMPP221 1 2 true, fMPP221 2 1.23 "c");
val xMPP2212 =
    let val f = fMPP221 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

val fMPP222 = fn (x : int) => fn y => fn z => true;
val xMPP2221 = (fMPP222 1 2 true, fMPP222 2 1.23 "c");
val xMPP2222 =
    let val f = fMPP222 1 val g1 = f "a" val g2 = f true
    in (g1 1.23, g1 false, g2 1.23, g2 false) end;

(**********)

val fPMP111 = fn x => fn (y : int) => fn z => (x, y + 1, z);
val xPMP1111 = (fPMP111 1 2 true, fPMP111 1.23 3 "c");
val xPMP1112 =
    let val f1 = fPMP111 1 2 val f2 = fPMP111 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP112 = fn x => fn (y : int) => fn z => (x, y + 1);
val xPMP1121 = (fPMP112 1 2 true, fPMP112 1.23 3 "c");
val xPMP1122 =
    let val f1 = fPMP112 1 2 val f2 = fPMP112 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP121 = fn x => fn (y : int) => fn z => (x, z);
val xPMP1211 = (fPMP121 1 2 true, fPMP121 1.23 3 "c");
val xPMP1212 =
    let val f1 = fPMP121 1 2 val f2 = fPMP121 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP122 = fn x => fn (y : int) => fn z => x;
val xPMP1221 = (fPMP122 1 2 true, fPMP122 1.23 3 "c");
val xPMP1222 =
    let val f1 = fPMP122 1 2 val f2 = fPMP122 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP211 = fn x => fn (y : int) => fn z => (y + 1, z);
val xPMP2111 = (fPMP211 1 2 true, fPMP211 1.23 3 "c");
val xPMP2112 =
    let val f1 = fPMP211 1 2 val f2 = fPMP211 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP212 = fn x => fn (y : int) => fn z => (y + 1);
val xPMP2121 = (fPMP212 1 2 true, fPMP212 1.23 3 "c");
val xPMP2122 =
    let val f1 = fPMP212 1 2 val f2 = fPMP212 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP221 = fn x => fn (y : int) => fn z => z;
val xPMP2211 = (fPMP221 1 2 true, fPMP221 1.23 3 "c");
val xPMP2212 =
    let val f1 = fPMP221 1 2 val f2 = fPMP221 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;

val fPMP222 = fn x => fn (y : int) => fn z => true;
val xPMP2221 = (fPMP222 1 2 true, fPMP222 1.23 3 "c");
val xPMP2222 =
    let val f1 = fPMP222 1 2 val f2 = fPMP222 1.23 2
    in (f1 1.23, f1 false, f2 1.23, f2 false) end;
