(*
 * combination of transparency of constraint and constraining signature
 * expression.
*)

(* transparent constraint by signature name *)
signature SIG = sig structure T : sig type t val x : t end end;
structure S = struct type t = int val x = 1 end;
structure STR : SIG = struct structure T = S end;
structure S = STR.T;
S.x;

(* opaque constraint by signature name *)
signature SIG = sig structure T : sig type t val x : t end end;
structure S = struct type t = int val x = 1 end;
structure STR :> SIG = struct structure T = S end;
structure S = STR.T;
S.x;

(* transparent constraint by inline signature *)
structure S = struct type t = int val x = 1 end;
structure STR : sig structure T : sig type t val x : t end end = 
struct structure T = S end;
structure S = STR.T;
S.x;

(* opaque constraint by inline signature *)
structure S = struct type t = int val x = 1 end;
structure STR :> sig structure T : sig type t val x : t end end = 
struct structure T = S end;
structure S = STR.T;
S.x;