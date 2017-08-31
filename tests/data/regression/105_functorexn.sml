_interface "105_functorexn.smi"
functor F (
  A : sig
    exception E
  end
) =
struct
  exception E2 = A.E
end

(*
2011-09-02 katsu

This causes an unexpected name error.

105_functorexn.sml:8.13-8.18 Error: (name evaluation 016) exception undefined: E
105_functorexn.smi:7.13-7.18 Error:
  (name evaluation 110) exception id expected in exception replication : E
*)

(*
2011-09-02 ohori

Fixed.

This example shows that local exn replication sometimes need to be exported.
Another example would be
functor F()  = 
struct
  local
     exception foo 
  in
   exception bar = foo
  end
end

So the nameevaluator need to maintain the set of exnInfo that has been
already exported and when it encounters an exception replication declaration
it checks whether it has already been exported or not.

*)
