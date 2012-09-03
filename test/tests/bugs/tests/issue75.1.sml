(* true, false, nil, ::, ref, it may not be bound in exnbind and datbind. *)

exception true;
exception false of int;
exception nil;
exception ::;
exception ref;
exception it;

datatype dt = true;
datatype dt = false;
datatype dt = nil;
datatype dt = ::;
datatype dt = ref;
datatype dt = it;

(* true, false, nil, ::, ref may not be bound in valbind. *)

val true : int as x = 1;
val false : int as x = 1;
val nil : int as x = 1;
val :: : int as x = 1;
val ref : int as x = 1;

val {true} = 1;
val {false} = 1;
val {nil} = 1;
val {::} = 1;
val {ref} = 1;

val {true : int as x} = 1;
val {false : int as x} = 1;
val {nil : int as x} = 1;
val {:: : int as x} = 1;
val {ref : int as x} = 1;

