functor FException(S : sig exception E end) =
struct exception F = S.E end;
structure TException = FException(struct exception E end);
