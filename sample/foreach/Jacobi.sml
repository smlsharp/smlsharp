fun Jacobi epsilon (a, b) =
    let
      val count = ref 0
      fun inc id = if id = 0 then count := !count + 1 else ()
      val size = Array.length a
      val x = Array.array(size, 0.0)
      fun A (i,j) = Array.sub(Array.sub(a,i), j)
      fun Ai i = Array.sub(a,i)
      fun B i = Array.sub(b,i) fun sumAX X i =
          let
            fun sum j n X R =
                if j >= n then R
                else if Real.== (A(i,j), 0.0) then sum (j+1) n X R
                else sum (j+1) n X (A(i,j) * X(j) + R)
          in
            sum 0 i X 0.0 + sum (i+1) size X 0.0
          end
      val result =
          _foreach i in x with {value=X, newValue=newX, size}
          do (inc i; (B(i) - sumAX X i) / A(i,i))
          while Real.abs(newX(i) - X(i)) > epsilon
          end
    in
      {result = result, parallelSteps = !count}
    end
(*
val A = Array.fromList
          [Array.fromList [3.0, 1.0, 1.0],
           Array.fromList [1.0, 3.0, 1.0],
           Array.fromList [1.0, 1.0, 3.0]
          ];
val B = Array.fromList  [0.0, 4.0, 6.0];
*)

(* 要素数 *)
val numPoints = valOf (Int.fromString (valOf (OS.Process.getEnv "SIZE")))

val m = 178.49  (* 原子量 [g/mol] *)
val k = 23.0  (* 熱伝導率 [W/m/K] *)
val c = 25.73 / m   (* 比熱 [J/g/K] *)
val p = 13.31 * 1000000.0  (* 密度 [g/m^3] *)
val dx = 0.0001  (* 空間標本化間隔 [m] *)
val dt = 0.01    (* 時間標本化間隔 [s] *)
val r = dt / dx / dx  (* 拡散数 *)
val a = k / c / p (* 温度拡散率 [m^2/s] *)
val t0 = 15.0     (* 初期温度 [K] *)
val h = 36.0      (* 加熱側温度 [K] *)

(* 以上の物性を持つ物質でできた，温度 h ℃，長さ dx * (numPoints+1) メート
 * ルの一様な棒があり，その片側が h ℃に加熱され，反対側が断熱されているとき，
 * 熱がその棒を伝わる様子を dt 秒刻みで計算する．計算は陰解法で行う．
 * 現在の温度tから次の時間の温度t'を求めるには，以下の方程式を解く．
  | 1                |   | t'[0]   |   | t[0]   |
  | u v u            |   | t'[1]   |   | t[1]   |
  |   u v u          |   | t'[2]   |   | t[2]   |
  |     u v u        | × | t'[3]   | = | t[3]   |
  |        ...       |   |  :      |   |  :     |
  |            u v u |   | t'[n-1] |   | t[n-1] |
  |              1 1 |   | t'[n]   |   | 0      |
*)
val u = ~a * r
val v = 1.0 + 2.0 * a * r
val A =
  _foreach i in Array.array (numPoints + 1, Array.array (0, 0.0))
  with _
  do Array.tabulate
       (numPoints + 1,
        fn j =>
           if i = 0 then if j = 0 then 1.0 else 0.0
           else if i < numPoints
           then if j = i then v
                else if j = i - 1 orelse j = i + 1 then u
                else 0.0
           else if j = numPoints - 1 then ~1.0
                else if j = numPoints then 1.0
                else 0.0)
  while false
  end;
val B =
  Array.tabulate
    (numPoints + 1,
     fn i => if i = 0 then h else t0)

fun repeat 0 x f = x
  | repeat n x f = repeat (n - 1) (f x) f

val _ =
(*
  repeat 100 B
*)
  repeat 1 B
    (fn B =>
        let
          val _ = Array.update (B, numPoints, 0.0)
          val {parallelSteps, result=B} = Jacobi 0.000000000001 (A,B)
        in
(*
          print "---\n";
          print (Int.toString parallelSteps ^ "\n");
          Array.app (fn x => print (Real.toString x ^ "\n")) B;
*)
          B
        end)
