structure P = struct type t = real end;
datatype 'a dt = D of 'a;

(* OK *)
functor F1(S : sig type t end) =
struct
  type t = S.t
end;
structure S1 = F1(P);

(* OK *)
functor F2(S : sig type t end) = 
struct 
  type t = int dt * S.t 
end;
structure S2 = F2(P);

(* OK *)
functor F3(S : sig type t end) =
struct
  datatype 'a dt = D of 'a 
  type t = S.t dt 
end;
structure S3 = F3(P);

(* NG *)
functor F4(S : sig type t end) = 
struct 
  type t = S.t dt 
end;
structure S4 = F4(P);
