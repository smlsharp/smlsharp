local
 structure P = PolyDynamic
 fun printSize obj = (print (Word.toString (P.size obj)); print "\n")
in
  val a = P.dynamic 99
  val b = P.objOf a
  val c = P.size b
  val d = P.getInt b
  val e = P.dynamic "SML#"
  val f = P.objOf e
  val g = P.size f
  val h = P.getString f
  val i = P.dynamic 3.14
  val j = P.objOf i
  val k = P.size j
  val l = P.getReal j
  val m = P.dynamic true
  val n = P.objOf m
  val p = P.size n
  val q = P.getBool n
  val r = P.dynamic [1,2,3,4,5]
  val s = P.objOf r
  val t = P.size s
  val u = P.getList (JSON.INTty, P.getInt) s
  val v = P.dynamic ["S", "M", "L", "#"]
  val w = P.objOf v
  val x = P.size w
  val y = P.getList (JSON.STRINGty, P.getString) w
  val z = P.dynamic [3.0, 3.1, 3.14]
  val za = P.objOf z
  val zb = P.size za
  val zc = P.getList (JSON.REALty, P.getReal) za

end
