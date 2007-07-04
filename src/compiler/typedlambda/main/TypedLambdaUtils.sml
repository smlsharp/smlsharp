(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc NGUYEN
 *)
structure TypedLambdaUtils = struct
local 
    open TypedLambda
in
   fun getLocOfExp exp =
     case exp of
       TLFOREIGNAPPLY {loc,...} => loc
     | TLEXPORTCALLBACK {loc,...} => loc
     | TLCONSTANT {loc,...} => loc
     | TLEXCEPTIONTAG {loc,...} => loc
     | TLSIZEOF {loc,...} => loc
     | TLVAR {loc,...} => loc
     | TLGETFIELD {loc,...} => loc
     | TLSETFIELD {loc,...} => loc
     | TLSETTAIL {loc,...} => loc
     | TLGETGLOBAL{loc,...} => loc
     | TLSETGLOBAL{loc,...} => loc
     | TLINITARRAY{loc,...} => loc
     | TLARRAY {loc,...} => loc
     | TLPRIMAPPLY {loc,...} => loc
     | TLAPPM {loc,...} => loc
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
     | TLCAST {loc,...} => loc

   fun getLocOfDec dec =
       case dec of
           TLVAL {loc,...} => loc
         | TLVALREC {loc,...} => loc
         | TLVALPOLYREC {loc,...} => loc
end
end
