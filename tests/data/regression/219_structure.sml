structure S1 = struct datatype dt = D val x = D : dt end

(*
2012-07-09 endom

本来、型は全て展開されたものがprintされるはずだが、ユーザーが型を指定すると下記のように展開されてない形のものがprintされる。
structure S1 =
  struct
    datatype dt (S1.dt) = D
    val x = _ : dt
  end
*)

(* 
2012--7-19 ohori
This is the essentially the same as 207_printer.sml and was fixed
by 4309:6422c6afb889.
*)
