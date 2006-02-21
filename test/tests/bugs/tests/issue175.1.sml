signature DICTIONARY =
sig
  type (''key, 'value) dict
  val create : unit -> (''a, 'b) dict
end;
structure Dictionary :> DICTIONARY =
struct
  datatype (''key, 'value) dict
           = Dict of (''key * 'value) list
  fun create () = Dict [];
end;
open Dictionary;
create ();
