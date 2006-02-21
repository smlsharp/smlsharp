(**
 * Copyright (c) 2006, Tohoku University.
 *)

structure TypedLambdaUtils = struct
local 
    open TypedLambda
in
   fun getLocOfExp exp =
     case exp of
       TLFOREIGNAPPLY {loc,...} => loc
     | TLCONSTANT {loc,...} => loc
     | TLVAR {loc,...} => loc
     | TLGETGLOBAL (string, ty, loc) => loc
     | TLGETFIELD {loc,...} => loc
     | TLSETFIELD {loc,...} => loc
     | TLGETGLOBALVALUE{loc,...} => loc
     | TLSETGLOBALVALUE{loc,...} => loc
     | TLINITARRAY{loc,...} => loc
     | TLARRAY {loc,...} => loc
     | TLPRIMAPPLY {loc,...} => loc
     | TLAPPM {loc,...} => loc
     | TLMONOLET {loc,...} => loc
     | TLLET {loc,...} => loc
     | TLRECORD {loc=loc,...} => loc
     | TLSELECT {loc,...} => loc
     | TLMODIFY {loc,...} => loc
     | TLRAISE {loc,...} => loc
     | TLHANDLE {loc,...} => loc
     | TLFNM {loc,...} => loc
     | TLPOLY {loc,...} => loc
     | TLTAPP {loc,...} => loc
     | TLSWITCH {loc,...} => loc
     | TLSEQ {loc,...} => loc
     | TLCAST {loc,...} => loc
     | TLOFFSET {loc,...} => loc
     | TLFFIVAL {loc,...} => loc

end
end

