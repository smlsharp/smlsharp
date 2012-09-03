signature SIG = sig type t end;
functor FUN(type s) : SIG where type t = s = struct type t = s end;
