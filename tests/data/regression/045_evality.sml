_interface "045_evality.smi"
structure S =
struct
  fun f x = x
end

(*
2011-08-21 katsu

This causes BUG at InferTypes.

evalIty
exn(dt10)
evalIty
exn(dt10)
evalIty
exn(dt10)
evalIty
exn(dt10)
evalIty
exn(dt10)
evalIty
exn(dt10)
evalIty
exn(dt10)
evalIty
string(dt4) -> exn(dt10)
evalIty
string(dt4)
evalIty
exn(dt10)
evalIty
string(dt4) -> exn(dt10)
evalIty
string(dt4)
evalIty
exn(dt10)
evalIty
string(dt4) * int(dt0) option(dt15) -> exn(dt10)
evalIty
string(dt4) * int(dt0) option(dt15)
evalIty
string(dt4)
evalIty
int(dt0) option(dt15)
evalIty
int(dt0)
evalIty
exn(dt10)
evalIty
'a(tv29) -> 'a(tv29)
evalIty
'a(tv29)
evalIty tvar not found
'a(tv29)[BUG] EvalITy: free tvar: 'a(tv29)
    raised at: ../types/main/EvalIty.sml:72.20-72.82
   handled at: ../typeinference2/main/InferTypes.sml:3440.33
                ../toplevel2/main/Top.sml:762.65-762.68
                ../toplevel2/main/Top.sml:864.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-22 ohori

Fixed. 
Note: for the case of providing poly type variable, we need to instantiate;
generalize and rebinding.  This is another source of Array.sub problem. 

*)
