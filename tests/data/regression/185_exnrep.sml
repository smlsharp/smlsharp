structure T =
struct
  structure S =
  struct
    exception E = S.E
  end
  exception E = S.E
end


(*
2011-12-15 katsu

This causes an unexpected name error at link time.

$ smlsharp -c 185_exnrep.sml      // OK
$ smlsharp -c 185_exnrep2.sml     // OK
$ smlsharp 185_exnrep.smi         // FAIL
185_exnrep.smi:8.13-8.19 Error:
  (name evaluation EI-150) undefined exception id : S.E

*)

(*
2011-12-15 ohori

Fixed.
This is due to the missing case for the addition of
IDEXEXNREP construct for eliminating  duplicated 
extern exception declarations. 
*)
