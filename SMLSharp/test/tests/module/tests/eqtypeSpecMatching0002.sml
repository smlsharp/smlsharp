(*
type equality check in matching of eqtype specification.
Only equality type in a structure can be matched with a "type" specification 
in a signature.
Non-equality type in a structure should be rejected.

<ul>
  <li>actual type expression bound to the type name in a structure
    <ul>
      <li>equality type
        <ul>
          <li>record type</li>
          <li>constructed type</li>
          <li>ref type</li>
          <li>datatype which admits equality</li>
        </ul>
      </li>
      <li>non equality type
        <ul>
          <li>record type</li>
          <li>constructed type
            <ul>
              <li>some argument type is not equality type.</li>
              <li>the type constructor does not admit equality.</li>
            </ul>
          </li>
          <li>function type</li>
          <li>datatype which does not admit equality</li>
        </ul>
      </li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature S =
sig
  eqtype t
end;

structure SEqRecordTrans : S =
struct
  type t = {a : int, b : int ref}
end;
structure SEqRecordOpaque :> S =
struct
  type t = {a : int, b : int ref}
end;

structure SEqConstructedTrans : S =
struct
  datatype ('a, 'b) dt = D of 'a * 'b
  type t = (int, int ref) dt
end;
structure SEqConstructedOpaque :> S =
struct
  datatype ('a, 'b) dt = D of 'a * 'b
  type t = (int, int ref) dt
end;

structure SEqRefTrans : S =
struct
  type t = (real ref * real) ref
end;
structure SEqRefOpaque :> S =
struct
  type t = (real ref * real) ref
end;

structure SEqDatatypeTrans : S =
struct
  datatype t = D of int | E
end;
structure SEqDatatypeOpaque :> S =
struct
  datatype t = D of int | E
end;

(****************************************)

structure SNonEqRecordTrans : S =
struct
  type t = {a : int -> int, b : int ref}
end;
structure SNonEqRecordOpaque :> S =
struct
  type t = {a : int -> int, b : int ref}
end;

(* some argument type is not equality type. *)
structure SNonEqConstructedTrans1 : S =
struct
  datatype ('a, 'b) dt = D of 'a * 'b
  type t = (int, real) dt
end;
structure SNonEqConstructedOpaque1 :> S =
struct
  datatype ('a, 'b) dt = D of 'a * 'b
  type t = (int, real) dt
end;

(* type constructor does not admit equality. *)
structure SNonEqConstructedTrans2 : S =
struct
  datatype ('a, 'b) dt = D of 'a * 'b * real
  type t = (int, bool) dt
end;
structure SNonEqConstructedOpaque2 :> S =
struct
  datatype ('a, 'b) dt = D of 'a * 'b * real
  type t = (int, bool) dt
end;

structure SNonEqFunctionTrans : S =
struct 
  type t = int -> int
end;
structure SNonEqFunctionOpaque :> S =
struct 
  type t = int -> int
end;

structure SNonEqDatatypeTrans : S =
struct
  datatype t = D of int | E of real
end;
structure SNonEqDatatypeOpaque :> S =
struct
  datatype t = D of int | E of real
end;
