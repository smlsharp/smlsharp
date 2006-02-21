(***** top level global *****)
val x : int = raise Fail "foo";
local val x : int = raise Fail "foo"
in val y = 1
end;

(***** top level in structure *****)
(* in global structure *)
structure S = struct val x : int = raise Fail "foo" end;
(* in local structure *)
local
  structure S = struct val x : int = raise Fail "foo" end
in
  val y = 1;
end;
(* in nested structure *)
structure S =
struct structure P = struct val x : int = raise Fail "foo" end end;

(***** top level in functor *****)
functor F(S : sig end) = struct val x : int = raise Fail "foo" end;
structure FS = F(struct end);
local
  structure FS = F(struct end)
in
  val y = 1
end;

