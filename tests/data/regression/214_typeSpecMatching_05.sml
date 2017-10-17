signature S0 = sig type t end;
signature S1 = sig type 'a t end;
signature S2 = sig type ('a, 'b) t end;

(*
structure S0typeTrans : S0 = struct type 'a t = int * 'a end;
structure S0typeOpaque :> S0 = struct type 'a t = int * 'a end;

structure S1typeTrans : S1 = struct type t = int end;
structure S1typeOpaque :> S1 = struct type t = int end;
*)

structure S2typeTrans : S2 = struct type ('a, 'b, 'c) t = int end;
(*
structure S2typeOpaque :> S2 = struct type ('a, 'b, 'c) t = int end;

structure S0datatypeTrans : S0 = struct datatype 'a t = D of int * 'a end;
structure S0datatypeOpaque :> S0 = struct datatype 'a t = D of int * 'a end;

structure S1datatypeTrans : S1 = struct datatype t = D of int end;
structure S1datatypeOpaque :> S1 = struct datatype t = D of int end;

structure S2datatypeTrans : S2 = struct datatype 'a t = D of int * 'a end;
structure S2datatypeOpaque :> S2 = struct datatype 'a t = D of int * 'a end;
*)

(*
2012-07-13 ymukade

すべて型パラメータの個数が違うので
Signature mismatch が出るはずだがすべて通る
*)
