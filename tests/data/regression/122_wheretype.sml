_interface "122_wheretype.smi"
(*
122_wheretype.smi
  structure T =
  struct
    structure S =
    struct
      type t (= int)
      type t2 = t
    end
  end
*)

signature SIG = 
 sig
    structure S :
       sig
        type t
        include sig type t2 end where type t2 = t
      end
 end
structure T :> SIG
=
struct
  structure S =
  struct
    type t = int
    type t2 = t
  end
end

(*
2011-09-06 katsu

This causes an unexpected name error.

122_wheretype.smi:6.10-6.15 Error:
  (name evaluation CP-200) Provide check fails (type definition) : T.S.t2
*)

(*
2011-09-06 ohori

Fixed.
This is due to a suble bug in refreshing a signature in PLSPECINCLUDE.
To cope with this, I temporarly duplicate TfunVars to TfunVarsRefresh
and adjust this situation. This is pretty much haking and need to review and
rewrite.

*)
