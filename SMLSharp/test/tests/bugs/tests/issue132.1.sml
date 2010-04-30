signature SUBSTRING =
sig
  type substring
  eqtype string
  val all : string -> substring
end;
structure Substring =
struct
  type string = string
  type substring = string
  fun all string = string : substring
end;

(* OK *)
val x = Substring.all "abc";

(* OK *)
structure Strans = Substring : SUBSTRING;
val y = Strans.all "abc";

(* NG *)
structure Sopaq =
          Substring :> SUBSTRING
                         where type string = string;
val z = Sopaq.all "abc";
