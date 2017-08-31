signature S21 = sig type t datatype dt = D val x : t * dt end
      and S22 = sig type t datatype dt = D val x : t * dt end

(*
2012-07-13 ymukade

signature ~ and ~ で定義すると、
endsignature とプリントされ、改行が無い

signature S21 =
  sig
    datatype dt = D type t
    val x : t * dt
  endsignature S22 =
  sig
    datatype dt = D type t
    val x : t * dt
  end
*)

(*
2012-07-19 ohori
Fixed by 4318:6eed60f691bc
*)
