(**
 * environment with module hierarchy.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ENVSet.sml,v 1.3 2004/10/20 03:18:39 kiyoshiy Exp $
 *)
structure ENVSet =
struct

  (***************************************************************************)

  structure AA = AnnotatedAst
  structure EA = ElaboratedAst

  (***************************************************************************)

  datatype ENVSet =
           ENVSet of
           {
             structureENV : (string * EA.moduleReference * ENVSet) list,
             signatureENV : (string * EA.moduleReference * ENVSet) list,
             functorENV : (string * EA.moduleReference * ENVSet) list,
             functorSignatureENV : (string * EA.moduleReference * ENVSet) list,
             typeENV : (string * EA.moduleReference) list,
             exceptionENV : (string * EA.moduleReference) list,
             valENV : (string * AA.ty option) list
           }

  (***************************************************************************)

  val emptyENVSet = 
      ENVSet
      {
        valENV = [],
        typeENV = [],
        exceptionENV = [],
        structureENV = [],
        signatureENV = [],
        functorENV = [],
        functorSignatureENV = []
      }

  fun appendENVSet(ENVSet newENVSet, ENVSet parentENVSet) =
      ENVSet
      {
        typeENV = #typeENV newENVSet @ #typeENV parentENVSet,
        valENV = #valENV newENVSet @ #valENV parentENVSet,
        exceptionENV = #exceptionENV newENVSet @ #exceptionENV parentENVSet,
        structureENV = #structureENV newENVSet @ #structureENV parentENVSet,
        signatureENV = #signatureENV newENVSet @ #signatureENV parentENVSet,
        functorENV = #functorENV newENVSet @ #functorENV parentENVSet,
        functorSignatureENV =
        #functorSignatureENV newENVSet @ #functorSignatureENV parentENVSet
      }

  fun bindVal baseENVSet binding = 
      appendENVSet
      (
        ENVSet
        {
          typeENV = [],
          valENV = [binding],
          exceptionENV = [],
          structureENV = [],
          signatureENV = [],
          functorENV = [],
          functorSignatureENV = []
        },
        baseENVSet
      )

  fun bindType baseENVSet binding =
      appendENVSet
      (
        ENVSet
        {
          typeENV = [binding],
          valENV = [],
          exceptionENV = [],
          structureENV = [],
          signatureENV = [],
          functorENV = [],
          functorSignatureENV = []
        },
        baseENVSet
      )

  fun bindException baseENVSet binding =
      appendENVSet
      (
        ENVSet
        {
          typeENV = [],
          valENV = [],
          exceptionENV = [binding],
          structureENV = [],
          signatureENV = [],
          functorENV = [],
          functorSignatureENV = []
        },
        baseENVSet
      )

  fun bindStructure baseENVSet binding =
      appendENVSet
      (
        ENVSet
        {
          typeENV = [],
          valENV = [],
          exceptionENV = [],
          structureENV = [binding],
          signatureENV = [],
          functorENV = [],
          functorSignatureENV = []
        },
        baseENVSet
      )

  fun bindSignature baseENVSet binding =
      appendENVSet
      (
        ENVSet
        {
          typeENV = [],
          valENV = [],
          exceptionENV = [],
          structureENV = [],
          signatureENV = [binding],
          functorENV = [],
          functorSignatureENV = []
        },
        baseENVSet
      )

  fun bindFunctor baseENVSet binding =
      appendENVSet
      (
        ENVSet
        {
          typeENV = [],
          valENV = [],
          exceptionENV = [],
          structureENV = [],
          signatureENV = [],
          functorENV = [binding],
          functorSignatureENV = []
        },
        baseENVSet
      )

  fun bindFunctorSignature baseENVSet binding =
      appendENVSet
      (
        ENVSet
        {
          typeENV = [],
          valENV = [],
          exceptionENV = [],
          structureENV = [],
          signatureENV = [],
          functorENV = [],
          functorSignatureENV = [binding]
        },
        baseENVSet
      )

  fun bindModule baseENVSet moduleType bind =
      (case moduleType of
         EA.STRUCTURE => bindStructure
       | EA.SIGNATURE => bindSignature
       | EA.FUNCTOR => bindFunctor
       | EA.FUNCTORSIGNATURE => bindFunctorSignature
       | _ => raise Fail "BUG: ENVSet.bindModule receive unknown moduleType.")
      baseENVSet
      bind

  (***************************************************************************)

end