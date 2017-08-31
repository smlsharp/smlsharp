signature S1 =
sig
  datatype s = S
  datatype a = T of s
end
signature S =
sig
  structure T1 : S1
  structure T2 : sig
    structure T1 : S1
  end
  sharing T1 = T2.T1
end

(*
2011-11-28 katsu

This causes an unexpected name error.

base.sml:12.3-12.20 Error:
  (name evaluation Sig-050) Signature mismatch in sharing type clause:T2.T1.a

*)

(*
2011-11-28 ohori

Fixed.

In the definition of Standard ML, 
  sharing strPath1 = ... = strPathi
is just a shorthand for the set of 
   sharing type strPath1.typId = ... = strPathi.typId 
for all possibe typeId. This is due to the "sloppy" nature of SML
signature; SML allows inconsistent signatures, i.e. those that do 
not have any instance. This is problematic in separate compilation 
of SML# since it need to generate a structure instance for signature
in functor compilation.

So SML# adopt a stricter semantics of signatures, requiring that any
signature must be consistent. This require to check signature
consistency at name evaluation, which we do. Since
 sharing strPath1 = strPath2
denotes a set of sharing type constraint, type consistency cheking for
the set must be donw under the assumption that all the ids in each set 
be equilvalent. 

The bug fix extends the consistency checking function with those
required equivalence relations.

*)
