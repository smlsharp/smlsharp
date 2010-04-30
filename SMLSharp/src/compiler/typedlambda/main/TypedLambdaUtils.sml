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
     | TLGLOBALSYMBOL {loc,...} => loc
     | TLEXCEPTIONTAG {loc,...} => loc
     | TLSIZEOF {loc,...} => loc
     | TLVAR {loc,...} => loc
     | TLGETFIELD {loc,...} => loc
     | TLSETFIELD {loc,...} => loc
     | TLSETTAIL {loc,...} => loc
     | TLARRAY {loc,...} => loc
     | TLCOPYARRAY {loc,...} => loc
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

end
end
