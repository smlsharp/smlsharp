(**
 * semantic actions to go with the grammar for CM description files
 *
 * @author (C) 1999 Lucent Technologies, Bell Laboratories
 * @author Matthias Blume (blume@kurims.kyoto-u.ac.jp)
 * @version $Id: CMSemantic.sml,v 1.4 2004/10/20 03:41:39 kiyoshiy Exp $
 *)
signature CM_SEMANTIC =
sig

    (* groups of operator symbols (to make grammar smaller) *)
    type addsym
    val PLUS : addsym
    val MINUS : addsym
    
    type mulsym
    val TIMES : mulsym
    val DIV : mulsym
    val MOD : mulsym

    type eqsym
    val EQ : eqsym
    val NE : eqsym

    type ineqsym
    val GT : ineqsym
    val GE : ineqsym
    val LT : ineqsym
    val LE : ineqsym

    datatype pathName =
             StandardPathName of string
           | NativePathName of string
    datatype description =
             Group of (pathName * string option) list
           | Alias of pathName
end

(**
 * @author (C) 1999 Lucent Technologies, Bell Laboratories
 * @author Matthias Blume (blume@kurims.kyoto-u.ac.jp)
 * @version $Id: CMSemantic.sml,v 1.4 2004/10/20 03:41:39 kiyoshiy Exp $
 *)
structure CMSemantic :> CM_SEMANTIC =
struct
    datatype addsym = PLUS | MINUS
    datatype mulsym = TIMES | DIV | MOD
    datatype eqsym = EQ | NE
    datatype ineqsym = GT | GE | LT | LE
    datatype pathName =
             StandardPathName of string
           | NativePathName of string
    datatype description =
             Group of (pathName * string option) list
           | Alias of pathName
end
